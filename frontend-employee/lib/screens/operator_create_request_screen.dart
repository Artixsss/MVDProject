import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../widgets/home_action.dart';
import '../widgets/user_profile_action.dart';
import '../services/api_service.dart';
import '../models/user_session.dart';
import '../utils/app_theme.dart';

/// Экран для оператора - создание обращения когда гражданин позвонил или пришёл лично
class OperatorCreateRequestScreen extends StatefulWidget {
  final UserSession currentUser;
  
  const OperatorCreateRequestScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<OperatorCreateRequestScreen> createState() => _OperatorCreateRequestScreenState();
}

class _OperatorCreateRequestScreenState extends State<OperatorCreateRequestScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _initialLoading = true;

  // Контроллеры для полей гражданина
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _patronymicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // Контроллеры для обращения
  final _descriptionController = TextEditingController();
  final _incidentLocationController = TextEditingController();
  final _citizenLocationController = TextEditingController();

  // Выбранные значения
  int? _selectedRequestTypeId;
  int? _selectedCategoryId;
  DateTime _incidentTime = DateTime.now();
  String _contactMethod = 'Телефонный звонок';

  // Справочники
  Map<int, String> _requestTypes = {};
  Map<int, String> _categories = {};

  // Определяет, нужно ли показывать email вместо телефона
  bool get _showEmailField {
    if (_selectedRequestTypeId == null) return false;
    final typeName = _requestTypes[_selectedRequestTypeId]?.toLowerCase() ?? '';
    return typeName.contains('почт') || 
           typeName.contains('email') || 
           typeName.contains('электронн') ||
           _contactMethod == 'Электронная почта';
  }

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _patronymicController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _incidentLocationController.dispose();
    _citizenLocationController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    try {
      final results = await Future.wait<dynamic>([
        _api.getRequestTypes(),
        _api.getCategories(),
      ]);

      if (!mounted) return;

      setState(() {
        _requestTypes = {
          for (var t in results[0] as List<Map<String, dynamic>>)
            t['id'] as int: t['name'] as String
        };
        _categories = {
          for (var c in results[1] as List<Map<String, dynamic>>)
            c['id'] as int: c['name'] as String
        };
        _initialLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _initialLoading = false);
        _showError('Ошибка загрузки справочников: $e');
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRequestTypeId == null) {
      _showError('Выберите тип обращения');
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await _api.dio.post(
        '/operator/create-request',
        data: {
          'citizenFirstName': _firstNameController.text.trim(),
          'citizenLastName': _lastNameController.text.trim(),
          'citizenPatronymic': _patronymicController.text.trim().isEmpty 
              ? null 
              : _patronymicController.text.trim(),
          'citizenPhone': _showEmailField 
              ? (_emailController.text.trim().isNotEmpty ? null : _phoneController.text.trim())
              : _phoneController.text.trim(),
          'citizenEmail': _showEmailField ? _emailController.text.trim() : null,
          'requestTypeId': _selectedRequestTypeId,
          'categoryId': _selectedCategoryId,
          'description': _descriptionController.text.trim(),
          'incidentLocation': _incidentLocationController.text.trim(),
          'citizenLocation': _citizenLocationController.text.trim().isEmpty
              ? null
              : _citizenLocationController.text.trim(),
          'incidentTime': _incidentTime.toIso8601String(),
          'operatorId': widget.currentUser.id,
          'contactMethod': _contactMethod,
        },
      );

      if (!mounted) return;

      final requestNumber = response.data['requestNumber'] as String?;
      
      setState(() => _loading = false);
      _showSuccessDialog(requestNumber ?? 'Создано');
    } catch (e) {
      if (!mounted) return;
      _showError('Ошибка создания обращения: $e');
      setState(() => _loading = false);
    }
  }

  void _showSuccessDialog(String requestNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              AppTheme.iconCheckCircle,
              color: AppTheme.successColor,
              size: 32,
            ),
            SizedBox(width: 8),
            Text('✅ Обращение создано'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Обращение успешно зарегистрировано в системе!',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: AppTheme.infoCardDecoration,
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
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(AppTheme.iconCopy, size: 20),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: requestNumber));
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Номер скопирован: $requestNumber'),
                              backgroundColor: AppTheme.successColor,
                              duration: const Duration(seconds: 2),
                            ),
                          );
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
              'Сообщите этот номер гражданину для отслеживания статуса.',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _loading = false);
              _clearForm();
            },
            child: const Text('Создать ещё'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/requests');
            },
            style: AppTheme.primaryButtonStyle.copyWith(
              padding: const MaterialStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            child: const Text('К списку обращений'),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _firstNameController.clear();
    _lastNameController.clear();
    _patronymicController.clear();
    _phoneController.clear();
    _emailController.clear();
    _descriptionController.clear();
    _incidentLocationController.clear();
    _citizenLocationController.clear();
    setState(() {
      _selectedRequestTypeId = null;
      _selectedCategoryId = null;
      _incidentTime = DateTime.now();
      _contactMethod = 'Телефонный звонок';
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Создать обращение'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: const [HomeAction(), UserProfileAction()],
      ),
      body: _initialLoading
          ? const Center(child: CircularProgressIndicator())
          : _loading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF0D47A1)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Анализируется ИИ...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Обращение регистрируется',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
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
                              'Создание обращения',
                              style: AppTheme.headlineStyle.copyWith(
                                fontSize: 24,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Заполните форму для регистрации обращения гражданина',
                              style: AppTheme.hintTextStyle,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

                            // Информация о способе обращения
                            Container(
                              decoration: AppTheme.sectionCardDecoration,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        AppTheme.iconPhoneInTalk,
                                        color: AppTheme.primaryColor,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Способ обращения',
                                        style: AppTheme.sectionHeaderStyle.copyWith(
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SegmentedButton<String>(
                                    style: SegmentedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      selectedBackgroundColor: AppTheme.primaryColor,
                                      selectedForegroundColor: Colors.white,
                                      foregroundColor: AppTheme.primaryColor,
                                      side: BorderSide(
                                        color: AppTheme.primaryColor.withOpacity(0.3),
                                      ),
                                    ),
                                    segments: const [
                                      ButtonSegment(
                                        value: 'Телефонный звонок',
                                        label: Text('Телефон'),
                                        icon: Icon(AppTheme.iconPhone),
                                      ),
                                      ButtonSegment(
                                        value: 'Личное посещение',
                                        label: Text('Личное'),
                                        icon: Icon(AppTheme.iconPerson),
                                      ),
                                      ButtonSegment(
                                        value: 'Электронная почта',
                                        label: Text('Email'),
                                        icon: Icon(AppTheme.iconEmail),
                                      ),
                                    ],
                                    selected: {_contactMethod},
                                    onSelectionChanged: (Set<String> values) {
                                      setState(() => _contactMethod = values.first);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Данные гражданина
                            AppTheme.buildSectionHeader(
                              'Личные данные',
                              icon: AppTheme.iconPerson,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Поля, отмеченные * являются обязательными',
                              style: AppTheme.hintTextStyle.copyWith(fontSize: 12),
                            ),
                            const SizedBox(height: 16),

                            AppTheme.buildTextField(
                              controller: _lastNameController,
                              label: 'Фамилия *',
                              icon: AppTheme.iconPersonOutline,
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

                            AppTheme.buildTextField(
                              controller: _firstNameController,
                              label: 'Имя *',
                              icon: AppTheme.iconPersonOutline,
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

                            AppTheme.buildTextField(
                              controller: _patronymicController,
                              label: 'Отчество',
                              icon: AppTheme.iconPersonOutline,
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

                            // Динамическое поле контакта
                            if (_showEmailField)
                              AppTheme.buildTextField(
                                controller: _emailController,
                                label: 'Электронная почта *',
                                icon: AppTheme.iconEmail,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v?.trim().isEmpty ?? true)
                                    return 'Введите email';
                                  final emailRegex = RegExp(
                                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                  );
                                  if (!emailRegex.hasMatch(v!.trim())) {
                                    return 'Введите корректный email';
                                  }
                                  return null;
                                },
                              )
                            else
                              AppTheme.buildTextField(
                                controller: _phoneController,
                                label: 'Телефон *',
                                icon: AppTheme.iconPhone,
                                keyboardType: TextInputType.phone,
                                hintText: '+7 (999) 123-45-67',
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
                            AppTheme.buildSectionHeader(
                              'Данные обращения',
                              icon: AppTheme.iconAssignment,
                            ),
                            const SizedBox(height: 16),

                            DropdownButtonFormField<int>(
                              value: _selectedRequestTypeId,
                              decoration: AppTheme.inputDecoration.copyWith(
                                labelText: 'Тип обращения *',
                                prefixIcon: const Icon(AppTheme.iconAssignment),
                                helperText: 'Выберите тип из списка',
                              ),
                              items: _requestTypes.entries
                                  .map((e) => DropdownMenuItem(
                                        value: e.key,
                                        child: Text(e.value),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                setState(() {
                                  _selectedRequestTypeId = v;
                                  // Автоматически меняем способ обращения при выборе типа
                                  if (v != null) {
                                    final typeName = _requestTypes[v]?.toLowerCase() ?? '';
                                    if (typeName.contains('почт') || 
                                        typeName.contains('email') || 
                                        typeName.contains('электронн')) {
                                      _contactMethod = 'Электронная почта';
                                    }
                                  }
                                });
                              },
                              validator: (v) => v == null ? 'Выберите тип' : null,
                            ),
                            const SizedBox(height: 16),

                            DropdownButtonFormField<int>(
                              value: _selectedCategoryId,
                              decoration: AppTheme.inputDecoration.copyWith(
                                labelText: 'Категория обращения',
                                prefixIcon: const Icon(AppTheme.iconCategory),
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
                                ..._categories.entries
                                    .map((e) => DropdownMenuItem(
                                          value: e.key,
                                          child: Text(e.value),
                                        ))
                                    .toList(),
                              ],
                              onChanged: (v) => setState(() => _selectedCategoryId = v),
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
                                    Row(
                                      children: [
                                        const Icon(
                                          AppTheme.iconTime,
                                          color: AppTheme.primaryColor,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Дата и время инцидента *',
                                          style: AppTheme.sectionHeaderStyle.copyWith(
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
                                                style: AppTheme.hintTextStyle.copyWith(
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatDateTime(_incidentTime),
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        FilledButton.icon(
                                          onPressed: _selectDateTime,
                                          icon: const Icon(AppTheme.iconEdit),
                                          label: const Text('Изменить'),
                                          style: AppTheme.primaryButtonStyle.copyWith(
                                            padding: const MaterialStatePropertyAll(
                                              EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Нажмите "Изменить" чтобы выбрать другую дату и время',
                                      style: AppTheme.hintTextStyle.copyWith(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            AppTheme.buildTextField(
                              controller: _incidentLocationController,
                              label: 'Адрес инцидента *',
                              icon: AppTheme.iconLocation,
                              hintText: 'Улица, дом, район...',
                              helperText: 'Введите адрес места происшествия',
                              validator: (v) => v?.trim().isEmpty ?? true
                                  ? 'Введите адрес инцидента'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            AppTheme.buildTextField(
                              controller: _citizenLocationController,
                              label: 'Адрес регистрации',
                              icon: AppTheme.iconHome,
                              helperText: 'Необязательное поле',
                            ),
                            const SizedBox(height: 16),

                            AppTheme.buildTextField(
                              controller: _descriptionController,
                              label: 'Описание обращения *',
                              icon: AppTheme.iconNotes,
                              maxLines: 6,
                              hintText: 'Подробно опишите суть обращения...',
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
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(AppTheme.iconSend),
                              label: Text(
                                _loading ? 'Анализируется ИИ...' : 'Создать обращение',
                              ),
                              style: AppTheme.primaryButtonStyle,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Future<void> _selectDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: _incidentTime,
      firstDate: DateTime(2020),
      lastDate: now,
      locale: const Locale('ru', 'RU'),
      helpText: 'Выберите дату инцидента',
      cancelText: 'Отмена',
      confirmText: 'Далее',
    );

    if (date == null || !mounted) return;

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

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

