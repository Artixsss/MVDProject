import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

/// Публичный экран для граждан - подача обращений без авторизации
class CitizenComplaintScreen extends StatefulWidget {
  const CitizenComplaintScreen({super.key});

  @override
  State<CitizenComplaintScreen> createState() => _CitizenComplaintScreenState();
}

class _CitizenComplaintScreenState extends State<CitizenComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  // Личные данные
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Данные обращения
  final _descriptionController = TextEditingController();
  final _incidentLocationController = TextEditingController();
  final _citizenLocationController = TextEditingController();

  int? _selectedCategoryId;
  int? _selectedRequestTypeId;
  DateTime _incidentTime = DateTime.now();
  
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _requestTypes = [];
  
  bool _loading = false;
  bool _showMap = false;
  LatLng? _selectedLocation;
  String? _detectedDistrict;
  
  final MapController _mapController = MapController();
  static const LatLng _novosibirskCenter = LatLng(55.0302, 82.9204);

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _incidentLocationController.dispose();
    _citizenLocationController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    try {
      final results = await Future.wait<dynamic>([
        _api.getCategories(),
        _api.getRequestTypes(),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = results[0];
        _requestTypes = results[1];
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Ошибка загрузки справочников: $e');
    }
  }

  Future<void> _searchAddress() async {
    final address = _incidentLocationController.text.trim();
    if (address.isEmpty) {
      _showError('Введите адрес инцидента');
      return;
    }

    setState(() => _loading = true);
    try {
      final results = await _api.searchAddress(address);
      if (!mounted) return;
      
      if (results.isEmpty) {
        _showError('Адрес не найден');
        setState(() => _loading = false);
        return;
      }

      final first = results.first;
      final raw = first['raw'] as Map<String, dynamic>;
      final lat = double.tryParse(raw['lat']?.toString() ?? '');
      final lon = double.tryParse(raw['lon']?.toString() ?? '');

      if (lat != null && lon != null) {
        setState(() {
          _selectedLocation = LatLng(lat, lon);
          _showMap = true;
          _loading = false;
          _mapController.move(_selectedLocation!, 15);
        });
      } else {
        _showError('Не удалось определить координаты');
        setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Ошибка поиска адреса: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Пожалуйста, заполните все обязательные поля');
      return;
    }

    if (_selectedCategoryId == null) {
      _showError('Выберите категорию обращения');
      return;
    }

    if (_selectedRequestTypeId == null) {
      _showError('Выберите тип обращения');
      return;
    }

    // Проверка длины описания
    if (_descriptionController.text.trim().length < 10) {
      _showError('Описание должно содержать минимум 10 символов');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await _api.submitNewRequest(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        middleName: _middleNameController.text.trim(),
        phone: _phoneController.text.trim(),
        requestTypeId: _selectedRequestTypeId!,
        categoryId: _selectedCategoryId!,
        description: _descriptionController.text.trim(),
        incidentLocation: _incidentLocationController.text.trim(),
        citizenLocation: _citizenLocationController.text.trim(),
        incidentTime: _incidentTime,
        latitude: _selectedLocation?.latitude,
        longitude: _selectedLocation?.longitude,
      );

      if (!mounted) return;
      
      // Показываем диалог с номером обращения
      _showSuccessDialog(result.requestNumber);
    } catch (e) {
      if (!mounted) return;
      _showError('Ошибка создания обращения: $e');
      setState(() => _loading = false);
    }
  }

  void _showSuccessDialog(String requestNumber) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('✅ Обращение принято'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ваше обращение успешно зарегистрировано!',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Номер обращения:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    requestNumber,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Сохраните этот номер! С его помощью вы сможете отследить статус вашего обращения.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/check-status');
            },
            child: const Text('Проверить статус'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/complaint');
            },
            child: const Text('Подать ещё'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подать обращение'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/check-status'),
            icon: const Icon(Icons.search, color: Colors.white),
            label: const Text('Проверить статус', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Заголовок
                        Text(
                          'Система приёма обращений граждан',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0D47A1),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Заполните форму ниже для подачи обращения',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Личные данные
                        _buildSectionHeader('Личные данные'),
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _lastNameController,
                          label: 'Фамилия',
                          icon: Icons.person,
                          validator: (v) {
                            if (v?.trim().isEmpty ?? true) return 'Введите фамилию';
                            if (v!.trim().length < 2) return 'Минимум 2 символа';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _firstNameController,
                          label: 'Имя',
                          icon: Icons.person_outline,
                          validator: (v) {
                            if (v?.trim().isEmpty ?? true) return 'Введите имя';
                            if (v!.trim().length < 2) return 'Минимум 2 символа';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _middleNameController,
                          label: 'Отчество',
                          icon: Icons.person_outline,
                          validator: (v) =>
                              v?.trim().isEmpty ?? true ? 'Обязательное поле' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Телефон',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v?.trim().isEmpty ?? true) return 'Введите номер телефона';
                            final phone = v!.trim().replaceAll(RegExp(r'[^\d+]'), '');
                            if (phone.length < 10) return 'Введите корректный номер';
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Данные обращения
                        _buildSectionHeader('Данные обращения'),
                        const SizedBox(height: 16),

                        // Категория
                        DropdownButtonFormField<int>(
                          value: _selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Категория обращения',
                            prefixIcon: Icon(Icons.category),
                            border: OutlineInputBorder(),
                          ),
                          items: _categories
                              .map((c) => DropdownMenuItem<int>(
                                    value: c['id'] as int,
                                    child: Text(c['name']?.toString() ?? ''),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedCategoryId = v),
                        ),
                        const SizedBox(height: 16),

                        // Тип обращения
                        DropdownButtonFormField<int>(
                          value: _selectedRequestTypeId,
                          decoration: const InputDecoration(
                            labelText: 'Тип обращения',
                            prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(),
                          ),
                          items: _requestTypes
                              .map((t) => DropdownMenuItem<int>(
                                    value: t['id'] as int,
                                    child: Text(t['name']?.toString() ?? ''),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedRequestTypeId = v),
                        ),
                        const SizedBox(height: 16),

                        // Дата и время инцидента
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.access_time),
                          title: const Text('Дата и время инцидента'),
                          subtitle: Text(
                            _formatDateTime(_incidentTime),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                          trailing: FilledButton.icon(
                            onPressed: _pickDateTime,
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('Изменить'),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Адрес инцидента с поиском
                        _buildTextField(
                          controller: _incidentLocationController,
                          label: 'Адрес инцидента',
                          icon: Icons.location_on,
                          validator: (v) =>
                              v?.trim().isEmpty ?? true ? 'Обязательное поле' : null,
                          suffix: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: _searchAddress,
                            tooltip: 'Найти на карте',
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Карта (если адрес найден)
                        if (_showMap && _selectedLocation != null)
                          Card(
                            margin: const EdgeInsets.only(top: 8),
                            child: SizedBox(
                              height: 300,
                              child: FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: _selectedLocation!,
                                  initialZoom: 15,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    subdomains: const ['a', 'b', 'c'],
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: _selectedLocation!,
                                        width: 40,
                                        height: 40,
                                        child: const Icon(
                                          Icons.location_pin,
                                          color: Colors.red,
                                          size: 40,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: 16),

                        // Адрес гражданина
                        _buildTextField(
                          controller: _citizenLocationController,
                          label: 'Адрес регистрации',
                          icon: Icons.home,
                          validator: (v) =>
                              v?.trim().isEmpty ?? true ? 'Обязательное поле' : null,
                        ),
                        const SizedBox(height: 16),

                        // Описание
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Описание обращения',
                          icon: Icons.notes,
                          maxLines: 6,
                          validator: (v) {
                            if (v?.trim().isEmpty ?? true) {
                              return 'Опишите обращение';
                            }
                            if (v!.trim().length < 10) {
                              return 'Описание должно содержать минимум 10 символов';
                            }
                            if (v.trim().length > 5000) {
                              return 'Описание слишком длинное (максимум 5000 символов)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Кнопка отправки
                        FilledButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.send),
                          label: const Text('Подать обращение'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.all(20),
                            textStyle: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0D47A1),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        suffixIcon: suffix,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _incidentTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_incidentTime),
    );
    if (time == null || !mounted) return;

    setState(() {
      _incidentTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

