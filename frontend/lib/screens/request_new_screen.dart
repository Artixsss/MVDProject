import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:form_validator/form_validator.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/home_action.dart';
import '../services/api_service.dart';
import '../models/citizen_request.dart';

class RequestNewScreen extends StatefulWidget {
  const RequestNewScreen({super.key});

  @override
  State<RequestNewScreen> createState() => _RequestNewScreenState();
}

class _AddressSearchDialog extends StatefulWidget {
  final ApiService api;
  const _AddressSearchDialog({required this.api});

  @override
  State<_AddressSearchDialog> createState() => _AddressSearchDialogState();
}

class _AddressSearchDialogState extends State<_AddressSearchDialog> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _results = const [];
  bool _loading = false;

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() => _loading = true);
    try {
      final r = await widget.api.searchAddress(q);
      setState(() => _results = r);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Поиск адреса'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Поиск'),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 8),
          _loading
              ? const CircularProgressIndicator()
              : SizedBox(
                  height: 300,
                  width: 400,
                  child: _results.isEmpty
                      ? const Center(child: Text('Нет результатов'))
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final item = _results[index];
                            return Card(
                              child: ListTile(
                                title: Text(item['formatted'] ?? ''),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (item['city']?.isNotEmpty ?? false)
                                      Text('Город: ${item['city']}'),
                                    if (item['region']?.isNotEmpty ?? false)
                                      Text('Область: ${item['region']}'),
                                    if (item['street']?.isNotEmpty ?? false)
                                      Text('Улица: ${item['street']}'),
                                    if (item['house']?.isNotEmpty ?? false)
                                      Text('Дом: ${item['house']}'),
                                  ],
                                ),
                                onTap: () => Navigator.pop(context, item),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () async {
            await _search();
          },
          child: const Text('Поиск'),
        ),
      ],
    );
  }
}

class _CitizenSearchDialog extends StatefulWidget {
  final ApiService api;
  const _CitizenSearchDialog({required this.api});

  @override
  State<_CitizenSearchDialog> createState() => _CitizenSearchDialogState();
}

class _CitizenSearchDialogState extends State<_CitizenSearchDialog> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _results = const [];
  bool _loading = false;

  Future<void> _search() async {
    final q = _controller.text.trim();
    setState(() => _loading = true);
    try {
      final r = await widget.api.searchCitizens(q);
      setState(() => _results = r);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Поиск гражданина'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Фамилия или телефон'),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 8),
          _loading
              ? const CircularProgressIndicator()
              : SizedBox(
                  height: 200,
                  width: 400,
                  child: _results.isEmpty
                      ? const Center(child: Text('Нет результатов'))
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final item = _results[index];
                            final name =
                                '${item['lastName'] ?? item['LastName'] ?? ''} ${item['firstName'] ?? item['FirstName'] ?? ''}';
                            final subtitle =
                                (item['phone'] ?? item['Phone'] ?? '')
                                    .toString();
                            return ListTile(
                              title: Text(name),
                              subtitle: Text(subtitle),
                              onTap: () => Navigator.pop(context, item),
                            );
                          },
                        ),
                ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () async {
            await _search();
          },
          child: const Text('Поиск'),
        ),
      ],
    );
  }
}

class _RequestNewScreenState extends State<RequestNewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();
  int? _citizenId;
  String? _citizenDisplay;
  // manual citizen entry controllers
  final _manualLastName = TextEditingController();
  final _manualFirstName = TextEditingController();
  final _manualMiddleName = TextEditingController();
  final _manualPhone = TextEditingController();
  bool _isManualCitizen = false;
  int? _requestTypeId;
  int? _categoryId;
  int? _assignedToId;
  int _statusId = 1; // Новый
  final _description = TextEditingController();
  final _incidentLocation = TextEditingController();
  final _citizenLocation = TextEditingController();
  double? _latitude;
  double? _longitude;
  DateTime _incidentTime = DateTime.now();
  int? _acceptedById;
  bool _loading = false;
  bool _loadingLookups = true;
  List<Map<String, dynamic>> _categoriesList = const [];
  List<Map<String, dynamic>> _typesList = const [];
  List<Map<String, dynamic>> _statusesList = const [];
  List<Map<String, dynamic>> _employeesList = const [];

  @override
  void initState() {
    super.initState();
    _loadCurrentEmployee();
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    try {
      final results = await Future.wait<dynamic>([
        _api.getCategories(),
        _api.getRequestTypes(),
        _api.getRequestStatuses(),
        _api.getEmployees(),
      ]);
      setState(() {
        _categoriesList = results[0];
        _typesList = results[1];
        _statusesList = results[2];
        _employeesList = results[3];
        // try to set default status id if available
        if (_statusesList.isNotEmpty) {
          final first = _statusesList.first;
          _statusId = (first['id'] ?? first['Id'] ?? _statusId) as int;
        }
        _loadingLookups = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingLookups = false);
    }
  }

  Future<void> _loadCurrentEmployee() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user');
    if (raw != null) {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      setState(() => _acceptedById = json['id'] as int);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _acceptedById == null) return;
    setState(() => _loading = true);
    try {
      CitizenRequestDto created;
      if (_citizenId != null) {
        final dto = CreateCitizenRequestDto(
          citizenId: _citizenId!,
          requestTypeId: _requestTypeId!,
          categoryId: _categoryId!,
          description: _description.text.trim(),
          acceptedById: _acceptedById!,
          assignedToId: _assignedToId,
          incidentTime: _incidentTime.toUtc().toIso8601String(),
          incidentLocation: _incidentLocation.text.trim(),
          citizenLocation: _citizenLocation.text.trim(),
          requestStatusId: _statusId,
        );
        created = await _api.createRequest(dto);
      } else {
        // manual citizen entry: create citizen and create request
        created = await _api.submitNewRequest(
          firstName: _manualFirstName.text.trim(),
          lastName: _manualLastName.text.trim(),
          middleName: _manualMiddleName.text.trim(),
          phone: _manualPhone.text.trim(),
          requestTypeId: _requestTypeId!,
          categoryId: _categoryId!,
          description: _description.text.trim(),
          incidentLocation: _incidentLocation.text.trim(),
          citizenLocation: _citizenLocation.text.trim(),
          incidentTime: _incidentTime,
          latitude: _latitude,
          longitude: _longitude,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Создано. Номер: ${created.requestNumber}')),
        );
        context.go('/requests/${created.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ошибка создания')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/requests'),
          tooltip: 'Назад',
        ),
        title: const Text('Новое обращение'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: const [HomeAction()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _loadingLookups
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showCitizenSearch(),
                            child: AbsorbPointer(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Гражданин',
                                  hintText: 'Выберите гражданина',
                                ),
                                controller: TextEditingController(
                                  text: _citizenDisplay ?? '',
                                ),
                                validator: (v) {
                                  if (_citizenId != null) return null;
                                  // allow manual entry alternative
                                  if (_manualLastName.text.trim().isNotEmpty &&
                                      _manualPhone.text.trim().isNotEmpty)
                                    return null;
                                  return 'Выберите гражданина или введите ФИО и телефон';
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _requestTypeId,
                            items: _typesList
                                .map(
                                  (t) => DropdownMenuItem<int>(
                                    value: (t['id'] ?? t['Id']) as int,
                                    child: Text(
                                      (t['name'] ?? t['Name'] ?? '').toString(),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _requestTypeId = v),
                            validator: (v) => v == null ? 'Выберите тип' : null,
                            decoration: const InputDecoration(
                              labelText: 'Тип обращения',
                            ),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 12),
              // Manual citizen entry toggle / fields
              _isManualCitizen
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Новый заявитель',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _manualLastName,
                                decoration: const InputDecoration(
                                  labelText: 'Фамилия',
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Введите фамилию'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _manualFirstName,
                                decoration: const InputDecoration(
                                  labelText: 'Имя',
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Введите имя'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _manualMiddleName,
                                decoration: const InputDecoration(
                                  labelText: 'Отчество',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _manualPhone,
                                decoration: const InputDecoration(
                                  labelText: 'Телефон',
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Введите телефон'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => setState(() {
                              _isManualCitizen = false;
                              _manualLastName.clear();
                              _manualFirstName.clear();
                              _manualMiddleName.clear();
                              _manualPhone.clear();
                            }),
                            icon: const Icon(Icons.close),
                            label: const Text('Отменить ввод'),
                          ),
                        ),
                      ],
                    )
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setState(() {
                          _isManualCitizen = true;
                          _citizenId = null;
                          _citizenDisplay = null;
                        }),
                        icon: const Icon(Icons.person_add),
                        label: const Text('Ввести заявителя вручную'),
                      ),
                    ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _categoryId,
                      items: _categoriesList
                          .map(
                            (c) => DropdownMenuItem<int>(
                              value: (c['id'] ?? c['Id']) as int,
                              child: Text(
                                (c['name'] ?? c['Name'] ?? '').toString(),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _categoryId = v),
                      validator: (v) => v == null ? 'Выберите категорию' : null,
                      decoration: const InputDecoration(labelText: 'Категория'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _assignedToId,
                      items:
                          [
                                const DropdownMenuItem<int>(
                                  value: null,
                                  child: Text('Не назначено'),
                                ),
                              ]
                              .followedBy(
                                _employeesList.map(
                                  (e) => DropdownMenuItem<int>(
                                    value: (e['id'] ?? e['Id']) as int,
                                    child: Text(
                                      (e['lastName'] ??
                                              e['LastName'] ??
                                              e['fullName'] ??
                                              '')
                                          .toString(),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => _assignedToId = v),
                      decoration: const InputDecoration(
                        labelText: 'Исполнитель (опционально)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Описание'),
                maxLines: 4,
                validator: ValidationBuilder().minLength(5).build(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _addressField('Адрес инцидента', _incidentLocation),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _addressField('Адрес гражданина', _citizenLocation),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InputDatePickerFormField(
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDate: _incidentTime,
                      onDateSubmitted: (d) => _incidentTime = DateTime(
                        d.year,
                        d.month,
                        d.day,
                        _incidentTime.hour,
                        _incidentTime.minute,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _statusId,
                      items: _statusesList
                          .map(
                            (s) => DropdownMenuItem<int>(
                              value: (s['id'] ?? s['Id']) as int,
                              child: Text(
                                (s['name'] ?? s['Name'] ?? '').toString(),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _statusId = v ?? _statusId),
                      decoration: const InputDecoration(labelText: 'Статус'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _loading
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          _submit();
                        }
                      },
                icon: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(_loading ? 'Создание...' : 'Создать обращение'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  padding: const EdgeInsets.all(20),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addressField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _showAddressSearch(controller),
        ),
      ),
      validator: ValidationBuilder().required().build(),
    );
  }

  Future<void> _showAddressSearch(TextEditingController controller) async {
    final value = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _AddressSearchDialog(api: _api),
    );
    if (value != null) {
      setState(() {
        controller.text = (value['formatted'] ?? '').toString();
        if (controller == _incidentLocation) {
          final raw = value['raw'] as Map<String, dynamic>?;
          if (raw != null) {
            _latitude = double.tryParse((raw['lat'] ?? '').toString());
            _longitude = double.tryParse((raw['lon'] ?? '').toString());
          }
        }
      });
    }
  }

  Future<void> _showCitizenSearch() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _CitizenSearchDialog(api: _api),
    );
    if (result != null) {
      setState(() {
        _citizenId = (result['id'] ?? result['Id']) as int;
        final last = (result['lastName'] ?? result['LastName'] ?? '')
            .toString();
        final first = ((result['firstName'] ?? result['FirstName']) ?? '')
            .toString();
        _citizenDisplay = '$last $first';
      });
    }
  }
}
