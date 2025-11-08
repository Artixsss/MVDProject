import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/home_action.dart';
import '../widgets/user_profile_action.dart';
import '../services/api_service.dart';

/// Экран управления сотрудниками (только для администратора)
class ManageEmployeesScreen extends StatefulWidget {
  const ManageEmployeesScreen({super.key});

  @override
  State<ManageEmployeesScreen> createState() => _ManageEmployeesScreenState();
}

class _ManageEmployeesScreenState extends State<ManageEmployeesScreen> {
  final _api = ApiService();
  List<Map<String, dynamic>> _employees = [];
  Map<int, String> _roles = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait<dynamic>([
        _api.dio.get('/api/admin/employees'),
        _api.dio.get('/api/admin/roles'),
      ]);

      if (!mounted) return;

      setState(() {
        _employees = List<Map<String, dynamic>>.from(results[0].data as List);
        _roles = {
          for (var r in results[1].data as List)
            r['id'] as int: r['name'] as String
        };
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError('Ошибка загрузки: $e');
      }
    }
  }

  Future<void> _deleteEmployee(int id, String fullName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Удалить сотрудника "$fullName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _api.dio.delete('/api/admin/employees/$id');
      _showSuccess('Сотрудник удален');
      await _loadData();
    } catch (e) {
      _showError('Ошибка удаления: $e');
    }
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _CreateEmployeeDialog(
        roles: _roles,
        onSuccess: () {
          Navigator.pop(ctx);
          _showSuccess('Сотрудник создан');
          _loadData();
        },
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF388E3C),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> employee) {
    showDialog(
      context: context,
      builder: (ctx) => _EditEmployeeDialog(
        employee: employee,
        roles: _roles,
        onSuccess: () {
          Navigator.pop(ctx);
          _showSuccess('Сотрудник обновлен');
          _loadData();
        },
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
        title: const Text('Управление сотрудниками'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: const [HomeAction(), UserProfileAction()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // Заголовок секции
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D47A1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.people,
                              size: 32,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Сотрудники',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF212121),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Всего: ${_employees.length}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: _showCreateDialog,
                            icon: const Icon(Icons.person_add, size: 20),
                            label: const Text('Добавить'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Список сотрудников
                  ..._employees.map((emp) => Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Аватар
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: const Color(0xFF0D47A1),
                                child: Text(
                                  (emp['fullName']?.toString().isNotEmpty ?? false)
                                      ? emp['fullName'].toString().substring(0, 1).toUpperCase()
                                      : 'С',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Основная информация
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ФИО
                                    Text(
                                      emp['fullName']?.toString() ?? 'Без имени',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xFF212121),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Username и роль
                                    Row(
                                      children: [
                                        if (emp['username'] != null) ...[
                                          Icon(
                                            Icons.account_circle,
                                            size: 18,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            emp['username'].toString(),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                        ],
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0D47A1).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: const Color(0xFF0D47A1).withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                emp['roleId'] == 3
                                                    ? Icons.admin_panel_settings
                                                    : Icons.headset_mic,
                                                size: 16,
                                                color: const Color(0xFF0D47A1),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                emp['roleName']?.toString() ?? 'Нет роли',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF0D47A1),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Статистика
                                    Text(
                                      'Принято: ${emp['acceptedRequestsCount']} • Назначено: ${emp['assignedRequestsCount']}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Кнопки действий
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Color(0xFF0D47A1),
                                    ),
                                    onPressed: () => _showEditDialog(emp),
                                    tooltip: 'Редактировать',
                                    padding: const EdgeInsets.all(8),
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Color(0xFFD32F2F),
                                    ),
                                    onPressed: () => _deleteEmployee(
                                      emp['id'] as int,
                                      emp['fullName']?.toString() ?? 'Сотрудник',
                                    ),
                                    tooltip: 'Удалить',
                                    padding: const EdgeInsets.all(8),
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            ),
    );
  }
}

// Диалог создания нового сотрудника
class _CreateEmployeeDialog extends StatefulWidget {
  final Map<int, String> roles;
  final VoidCallback onSuccess;

  const _CreateEmployeeDialog({
    required this.roles,
    required this.onSuccess,
  });

  @override
  State<_CreateEmployeeDialog> createState() => _CreateEmployeeDialogState();
}

class _CreateEmployeeDialogState extends State<_CreateEmployeeDialog> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _patronymicController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  int? _selectedRoleId;
  bool _loading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _patronymicController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRoleId == null) {
      _showError('Выберите роль');
      return;
    }

    setState(() => _loading = true);

    try {
      await _api.dio.post('/api/admin/employees', data: {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'patronymic': _patronymicController.text.trim().isEmpty 
            ? null 
            : _patronymicController.text.trim(),
        'phone': null,
        'username': _usernameController.text.trim(),
        'password': _passwordController.text.trim(),
        'roleId': _selectedRoleId,
      });

      if (!mounted) return;
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Ошибка создания: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить сотрудника'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Фамилия *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().length < 2 ? 'Введите фамилию' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Имя *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().length < 2 ? 'Введите имя' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _patronymicController,
                  decoration: const InputDecoration(
                    labelText: 'Отчество',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Имя пользователя *',
                    border: OutlineInputBorder(),
                    hintText: 'operator1',
                  ),
                  validator: (v) =>
                      v == null || v.trim().length < 3 ? 'Минимум 3 символа' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Пароль *',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (v) =>
                      v == null || v.trim().length < 3 ? 'Минимум 3 символа' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _selectedRoleId,
                  decoration: const InputDecoration(
                    labelText: 'Роль *',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.roles.entries
                      .where((e) => e.key == 1 || e.key == 3) // Только Operator и Admin
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Row(
                              children: [
                                Icon(
                                  e.key == 3 ? Icons.admin_panel_settings : Icons.headset_mic,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(e.value),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedRoleId = v),
                  validator: (v) => v == null ? 'Выберите роль' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton.icon(
          onPressed: _loading ? null : _submit,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add),
          label: Text(_loading ? 'Создание...' : 'Создать'),
        ),
      ],
    );
  }
}

// Диалог редактирования существующего сотрудника
class _EditEmployeeDialog extends StatefulWidget {
  final Map<String, dynamic> employee;
  final Map<int, String> roles;
  final VoidCallback onSuccess;

  const _EditEmployeeDialog({
    required this.employee,
    required this.roles,
    required this.onSuccess,
  });

  @override
  State<_EditEmployeeDialog> createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends State<_EditEmployeeDialog> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _patronymicController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  int? _selectedRoleId;
  bool _loading = false;
  bool _passwordChanged = false;

  @override
  void initState() {
    super.initState();
    // Предзаполняем поля данными сотрудника
    _lastNameController.text = widget.employee['lastName']?.toString() ?? '';
    _firstNameController.text = widget.employee['firstName']?.toString() ?? '';
    _patronymicController.text = widget.employee['patronymic']?.toString() ?? '';
    _usernameController.text = widget.employee['username']?.toString() ?? '';
    _selectedRoleId = widget.employee['roleId'] as int?;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _patronymicController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRoleId == null) {
      _showError('Выберите роль');
      return;
    }

    setState(() => _loading = true);

    try {
      final employeeId = widget.employee['id'] as int;
      await _api.dio.put('/api/admin/employees/$employeeId', data: {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'patronymic': _patronymicController.text.trim().isEmpty 
            ? null 
            : _patronymicController.text.trim(),
        'phone': null,
        'username': _usernameController.text.trim(),
        'password': _passwordChanged && _passwordController.text.trim().isNotEmpty
            ? _passwordController.text.trim()
            : null,
        'roleId': _selectedRoleId,
      });

      if (!mounted) return;
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Ошибка обновления: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Редактировать сотрудника'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Фамилия *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().length < 2 ? 'Введите фамилию' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Имя *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().length < 2 ? 'Введите имя' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _patronymicController,
                  decoration: const InputDecoration(
                    labelText: 'Отчество',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Имя пользователя *',
                    border: OutlineInputBorder(),
                    hintText: 'operator1',
                  ),
                  validator: (v) =>
                      v == null || v.trim().length < 3 ? 'Минимум 3 символа' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Новый пароль (оставьте пустым, чтобы не менять)',
                    border: OutlineInputBorder(),
                    helperText: 'Оставьте пустым, если не хотите менять пароль',
                  ),
                  obscureText: true,
                  onChanged: (v) {
                    setState(() => _passwordChanged = v.trim().isNotEmpty);
                  },
                  validator: (v) {
                    if (_passwordChanged && (v == null || v.trim().length < 3)) {
                      return 'Минимум 3 символа';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _selectedRoleId,
                  decoration: const InputDecoration(
                    labelText: 'Роль *',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.roles.entries
                      .where((e) => e.key == 1 || e.key == 3) // Только Operator и Admin
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Row(
                              children: [
                                Icon(
                                  e.key == 3 ? Icons.admin_panel_settings : Icons.headset_mic,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(e.value),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedRoleId = v),
                  validator: (v) => v == null ? 'Выберите роль' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton.icon(
          onPressed: _loading ? null : _submit,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(_loading ? 'Сохранение...' : 'Сохранить'),
        ),
      ],
    );
  }
}

