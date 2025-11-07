import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../models/citizen_request.dart';
import 'package:flutter/services.dart';

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

  // Автодополнение
  Timer? _autocompleteTimer;
  List<String> _addressSuggestions = [];
  bool _showSuggestions = false;
  bool _isIncidentField =
      true; // true для адреса инцидента, false для адреса регистрации

  @override
  void initState() {
    super.initState();
    _loadLookups();
    _incidentLocationController.addListener(_onIncidentAddressChanged);
    _citizenLocationController.addListener(_onCitizenAddressChanged);
  }

  void _copyToClipboard(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));

    // Показываем подтверждение копирования
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Номер обращения скопирован: $text'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
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
    _autocompleteTimer?.cancel();
    super.dispose();
  }

  void _onIncidentAddressChanged() {
    _autocompleteTimer?.cancel();
    _autocompleteTimer = Timer(const Duration(milliseconds: 500), () {
      if (_incidentLocationController.text.trim().length >= 3) {
        _loadAddressSuggestions(
          _incidentLocationController.text,
          isIncident: true,
        );
      } else {
        setState(() {
          _showSuggestions = false;
          _addressSuggestions = [];
        });
      }
    });
  }

  void _onCitizenAddressChanged() {
    _autocompleteTimer?.cancel();
    _autocompleteTimer = Timer(const Duration(milliseconds: 500), () {
      if (_citizenLocationController.text.trim().length >= 3) {
        _loadAddressSuggestions(
          _citizenLocationController.text,
          isIncident: false,
        );
      } else {
        setState(() {
          _showSuggestions = false;
          _addressSuggestions = [];
        });
      }
    });
  }

  Future<void> _loadAddressSuggestions(
    String query, {
    required bool isIncident,
  }) async {
    try {
      final suggestions = await _api.autocompleteAddress(query);
      if (!mounted) return;

      setState(() {
        _addressSuggestions = suggestions;
        _showSuggestions = suggestions.isNotEmpty && query.trim().isNotEmpty;
        _isIncidentField = isIncident;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _showSuggestions = false;
        _addressSuggestions = [];
      });
    }
  }

  Future<void> _onAddressSelected(
    String address, {
    required bool isIncident,
  }) async {
    // Геокодируем адрес для получения координат
    setState(() => _loading = true);
    try {
      final results = await _api.searchAddress(address);
      if (!mounted) return;

      if (results.isNotEmpty && isIncident) {
        final first = results.first;
        final lat = double.tryParse(first['lat']?.toString() ?? '');
        final lon = double.tryParse(first['lon']?.toString() ?? '');

        if (lat != null && lon != null) {
          setState(() {
            _selectedLocation = LatLng(lat, lon);
            _showMap = true;
          });
          // Перемещаем карту после рендера
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_selectedLocation != null) {
              try {
                _mapController.move(_selectedLocation!, 15);
              } catch (e) {
                // Карта еще не готова, попробуем еще раз через небольшую задержку
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted && _selectedLocation != null) {
                    try {
                      _mapController.move(_selectedLocation!, 15);
                    } catch (_) {
                      // Игнорируем ошибки
                    }
                  }
                });
              }
            }
          });
        }
      }
    } catch (e) {
      // Игнорируем ошибки геокодирования
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
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

  Future<void> _onMapTap(TapPosition tapPosition, LatLng point) async {
    setState(() {
      _selectedLocation = point;
      _showMap = true;
      _loading = true;
    });

    // Обратное геокодирование для получения адреса
    try {
      final address = await _api.reverseGeocode(
        point.latitude,
        point.longitude,
      );
      if (!mounted) return;

      if (address != null) {
        _incidentLocationController.text = address;
      }
    } catch (e) {
      // Игнорируем ошибки
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _submit() async {
    // Закрываем автодополнение
    FocusScope.of(context).unfocus();
    setState(() {
      _showSuggestions = false;
      _addressSuggestions = [];
    });

    if (!_formKey.currentState!.validate()) {
      _showError('Пожалуйста, заполните все обязательные поля');
      return;
    }

    // Категория теперь опциональна - нейросеть определит её автоматически
    // if (_selectedCategoryId == null) {
    //   _showError('Выберите категорию обращения');
    //   return;
    // }

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
        categoryId: _selectedCategoryId, // Теперь опционально
        description: _descriptionController.text.trim(),
        incidentLocation: _incidentLocationController.text.trim(),
        citizenLocation: _citizenLocationController.text.trim(),
        incidentTime: _incidentTime,
        latitude: _selectedLocation?.latitude,
        longitude: _selectedLocation?.longitude,
      );

      if (!mounted) return;

      // Ждем немного, чтобы AI успел проанализировать
      await Future.delayed(const Duration(seconds: 3));

      // Получаем полные данные обращения с AI-анализом
      CitizenRequestDto? fullRequest;
      try {
        fullRequest = await _api.getRequestByNumber(result.requestNumber);
      } catch (e) {
        // Если не удалось получить, показываем без AI-анализа
      }

      // Показываем диалог с номером обращения и AI-анализом
      _showSuccessDialog(result.requestNumber, fullRequest);
    } catch (e) {
      if (!mounted) return;
      _showError('Ошибка создания обращения: $e');
      setState(() => _loading = false);
    }
  }

  void _showSuccessDialog(
    String requestNumber, [
    CitizenRequestDto? fullRequest,
  ]) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 8),
            Text('✅ Обращение принято'),
          ],
        ),
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
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          requestNumber,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.content_copy, size: 20),
                        onPressed: () {
                          _copyToClipboard(requestNumber, ctx);
                        },
                        tooltip: 'Скопировать номер',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Сохраните этот номер! С его помощью вы сможете отследить статус вашего обращения.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),

            // AI-анализ (если доступен)
            if (fullRequest != null &&
                (fullRequest.aiSummary != null ||
                    fullRequest.aiPriority != null)) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Colors.purple.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'AI-анализ обращения',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (fullRequest.aiCategory != null) ...[
                      _buildAiInfoRow('Категория:', fullRequest.aiCategory!),
                      const SizedBox(height: 8),
                    ],
                    if (fullRequest.aiPriority != null) ...[
                      _buildAiInfoRow(
                        'Приоритет:',
                        fullRequest.aiPriority!,
                        color: _getPriorityColor(fullRequest.aiPriority!),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (fullRequest.aiSummary != null) ...[
                      const Text(
                        'Краткое содержание:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fullRequest.aiSummary!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
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
              // Очищаем форму
              _formKey.currentState?.reset();
              _lastNameController.clear();
              _firstNameController.clear();
              _middleNameController.clear();
              _phoneController.clear();
              _descriptionController.clear();
              _incidentLocationController.clear();
              _citizenLocationController.clear();
              setState(() {
                _selectedCategoryId = null;
                _selectedRequestTypeId = null;
                _selectedLocation = null;
                _showMap = false;
                _incidentTime = DateTime.now();
              });
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
        duration: const Duration(seconds: 4),
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
            label: const Text(
              'Проверить статус',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _loading && !_showMap
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
                        const SizedBox(height: 8),
                        Text(
                          'Поля, отмеченные * являются обязательными',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _lastNameController,
                          label: 'Фамилия *',
                          icon: Icons.person,
                          validator: (v) {
                            if (v?.trim().isEmpty ?? true)
                              return 'Введите фамилию';
                            if (v!.trim().length < 2)
                              return 'Минимум 2 символа';
                            if (v.trim().length > 100)
                              return 'Максимум 100 символов';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _firstNameController,
                          label: 'Имя *',
                          icon: Icons.person_outline,
                          validator: (v) {
                            if (v?.trim().isEmpty ?? true) return 'Введите имя';
                            if (v!.trim().length < 2)
                              return 'Минимум 2 символа';
                            if (v.trim().length > 100)
                              return 'Максимум 100 символов';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _middleNameController,
                          label: 'Отчество',
                          icon: Icons.person_outline,
                          helperText: 'Необязательное поле',
                          validator: (v) {
                            if (v != null &&
                                v.trim().isNotEmpty &&
                                v.trim().length > 100) {
                              return 'Максимум 100 символов';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _phoneController,
                          label: 'Телефон *',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v?.trim().isEmpty ?? true)
                              return 'Введите номер телефона';
                            final phone = v!.trim().replaceAll(
                              RegExp(r'[^\d+]'),
                              '',
                            );
                            if (phone.length < 10)
                              return 'Введите корректный номер';
                            if (phone.length > 20)
                              return 'Номер слишком длинный';
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Данные обращения
                        _buildSectionHeader('Данные обращения'),
                        const SizedBox(height: 16),

                        // Категория (опциональна - нейросеть определит автоматически)
                        DropdownButtonFormField<int>(
                          value: _selectedCategoryId,
                          decoration: InputDecoration(
                            labelText: 'Категория обращения',
                            prefixIcon: const Icon(Icons.category),
                            border: const OutlineInputBorder(),
                            helperText:
                                'Опционально. Нейросеть определит категорию автоматически на основе описания',
                          ),
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text(
                                'Автоматическое определение (рекомендуется)',
                              ),
                            ),
                            ..._categories
                                .map(
                                  (c) => DropdownMenuItem<int>(
                                    value: c['id'] as int,
                                    child: Text(c['name']?.toString() ?? ''),
                                  ),
                                )
                                .toList(),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedCategoryId = v),
                          // validator убран - категория теперь опциональна
                        ),
                        const SizedBox(height: 16),

                        // Тип обращения
                        DropdownButtonFormField<int>(
                          value: _selectedRequestTypeId,
                          decoration: InputDecoration(
                            labelText: 'Тип обращения *',
                            prefixIcon: const Icon(Icons.description),
                            border: const OutlineInputBorder(),
                            helperText: 'Выберите тип из списка',
                          ),
                          items: _requestTypes
                              .map(
                                (t) => DropdownMenuItem<int>(
                                  value: t['id'] as int,
                                  child: Text(t['name']?.toString() ?? ''),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedRequestTypeId = v),
                          validator: (v) => v == null ? 'Выберите тип' : null,
                        ),
                        const SizedBox(height: 16),

                        // Дата и время инцидента
                        Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      color: Color(0xFF0D47A1),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Дата и время инцидента *',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Выбрано:',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDateTime(_incidentTime),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0D47A1),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    FilledButton.icon(
                                      onPressed: _pickDateTime,
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Изменить'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF0D47A1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Нажмите "Изменить" чтобы выбрать другую дату и время',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Адрес инцидента с автодополнением и картой
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField(
                              controller: _incidentLocationController,
                              label: 'Адрес инцидента *',
                              icon: Icons.location_on,
                              helperText:
                                  'Начните вводить адрес или выберите на карте',
                              validator: (v) => v?.trim().isEmpty ?? true
                                  ? 'Введите адрес инцидента'
                                  : null,
                              suffix: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.map),
                                    onPressed: () {
                                      setState(() {
                                        _showMap = !_showMap;
                                        _showSuggestions = false;
                                        if (_showMap &&
                                            _selectedLocation == null) {
                                          _selectedLocation =
                                              _novosibirskCenter;
                                        }
                                      });
                                      // Перемещаем карту после того, как она отрендерится
                                      if (_showMap) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              final location =
                                                  _selectedLocation ??
                                                  _novosibirskCenter;
                                              try {
                                                _mapController.move(
                                                  location,
                                                  11,
                                                );
                                              } catch (e) {
                                                // Карта еще не готова, попробуем еще раз через небольшую задержку
                                                Future.delayed(
                                                  const Duration(
                                                    milliseconds: 100,
                                                  ),
                                                  () {
                                                    if (mounted) {
                                                      try {
                                                        _mapController.move(
                                                          location,
                                                          11,
                                                        );
                                                      } catch (_) {
                                                        // Игнорируем ошибки
                                                      }
                                                    }
                                                  },
                                                );
                                              }
                                            });
                                      }
                                    },
                                    tooltip: 'Показать карту',
                                  ),
                                ],
                              ),
                            ),
                            // Автодополнение для адреса инцидента
                            if (_showSuggestions &&
                                _isIncidentField &&
                                _addressSuggestions.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(
                                  maxHeight: 200,
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _addressSuggestions.length,
                                  itemBuilder: (context, index) {
                                    final suggestion =
                                        _addressSuggestions[index];
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(
                                        Icons.location_on,
                                        size: 20,
                                        color: Color(0xFF0D47A1),
                                      ),
                                      title: Text(
                                        suggestion,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      onTap: () {
                                        _incidentLocationController.text =
                                            suggestion;
                                        _onAddressSelected(
                                          suggestion,
                                          isIncident: true,
                                        );
                                        setState(() {
                                          _showSuggestions = false;
                                          _addressSuggestions = [];
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Карта для выбора места
                        if (_showMap)
                          Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              children: [
                                Container(
                                  height: 400,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: FlutterMap(
                                      mapController: _mapController,
                                      options: MapOptions(
                                        initialCenter:
                                            _selectedLocation ??
                                            _novosibirskCenter,
                                        initialZoom: _selectedLocation != null
                                            ? 15
                                            : 11,
                                        onTap: _onMapTap,
                                      ),
                                      children: [
                                        TileLayer(
                                          urlTemplate:
                                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                          subdomains: const ['a', 'b', 'c'],
                                          userAgentPackageName:
                                              'mvd.frontend.app',
                                        ),
                                        if (_selectedLocation != null)
                                          MarkerLayer(
                                            markers: [
                                              Marker(
                                                point: _selectedLocation!,
                                                width: 50,
                                                height: 50,
                                                child: const Icon(
                                                  Icons.location_pin,
                                                  color: Colors.red,
                                                  size: 50,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Нажмите на карте, чтобы выбрать место происшествия',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setState(() => _showMap = false);
                                        },
                                        child: const Text('Скрыть карту'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Адрес гражданина с автодополнением
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField(
                              controller: _citizenLocationController,
                              label: 'Адрес регистрации',
                              icon: Icons.home,
                              helperText:
                                  'Необязательное поле. Начните вводить адрес для автодополнения',
                              validator: (v) => null, // Необязательное поле
                            ),
                            // Автодополнение для адреса регистрации
                            if (_showSuggestions &&
                                !_isIncidentField &&
                                _addressSuggestions.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(
                                  maxHeight: 200,
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _addressSuggestions.length,
                                  itemBuilder: (context, index) {
                                    final suggestion =
                                        _addressSuggestions[index];
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(
                                        Icons.location_on,
                                        size: 20,
                                        color: Color(0xFF0D47A1),
                                      ),
                                      title: Text(
                                        suggestion,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      onTap: () {
                                        _citizenLocationController.text =
                                            suggestion;
                                        _onAddressSelected(
                                          suggestion,
                                          isIncident: false,
                                        );
                                        setState(() {
                                          _showSuggestions = false;
                                          _addressSuggestions = [];
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Описание
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Описание обращения *',
                          icon: Icons.notes,
                          maxLines: 6,
                          helperText:
                              'Минимум 10 символов. Опишите подробно что произошло',
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
                          onPressed: _loading ? null : _submit,
                          icon: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send),
                          label: Text(
                            _loading ? 'Отправка...' : 'Подать обращение',
                          ),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D47A1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0D47A1),
        ),
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
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        suffixIcon: suffix,
        helperText: helperText,
        helperMaxLines: 2,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    // Сначала выбираем дату
    final date = await showDatePicker(
      context: context,
      initialDate: _incidentTime,
      firstDate: DateTime(2020),
      lastDate: now,
      locale: const Locale('ru', 'RU'), // ДОБАВЬТЕ ЭТУ СТРОКУ
      helpText: 'Выберите дату инцидента',
      cancelText: 'Отмена',
      confirmText: 'Далее',
    );
    if (date == null || !mounted) return;

    // Затем выбираем время
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_incidentTime),
      helpText: 'Выберите время инцидента',
      cancelText: 'Назад',
      confirmText: 'Готово',
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

  Widget _buildAiInfoRow(String label, String value, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: color != null ? FontWeight.bold : null,
            ),
          ),
        ),
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'высокий':
        return Colors.red;
      case 'средний':
        return Colors.orange;
      case 'низкий':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
