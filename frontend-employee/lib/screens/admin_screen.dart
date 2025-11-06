import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/home_action.dart';
import '../widgets/user_profile_action.dart';
import '../services/api_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tabController;
  
  int _selectedTab = 0;
  
  // Данные для каждой вкладки
  Map<int, List<Map<String, dynamic>>> _data = {};
  Map<int, bool> _loading = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading[0] = true;
      _loading[1] = true;
      _loading[2] = true;
      _loading[3] = true;
      _loading[4] = true;
    });

    try {
      final results = await Future.wait<dynamic>([
        _api.getCategories(),
        _api.getRequestTypes(),
        _api.getRequestStatuses(),
        _api.getEmployees(),
        _api.getDistricts(),
      ]);

      if (!mounted) return;

      setState(() {
        _data[0] = results[0] as List<Map<String, dynamic>>;
        _data[1] = results[1] as List<Map<String, dynamic>>;
        _data[2] = results[2] as List<Map<String, dynamic>>;
        _data[3] = results[3] as List<Map<String, dynamic>>;
        _data[4] = results[4] as List<Map<String, dynamic>>;
        _loading[0] = false;
        _loading[1] = false;
        _loading[2] = false;
        _loading[3] = false;
        _loading[4] = false;
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Ошибка загрузки: $e');
      setState(() {
        for (var i = 0; i < 5; i++) {
          _loading[i] = false;
        }
      });
    }
  }

  String _getEndpoint(int tab) {
    switch (tab) {
      case 0:
        return 'categories';
      case 1:
        return 'requesttypes';
      case 2:
        return 'requeststatuses';
      case 3:
        return 'employees';
      case 4:
        return 'districts';
      default:
        return 'categories';
    }
  }

  String _getTabTitle(int tab) {
    switch (tab) {
      case 0:
        return 'Категории';
      case 1:
        return 'Типы обращений';
      case 2:
        return 'Статусы';
      case 3:
        return 'Сотрудники';
      case 4:
        return 'Районы';
      default:
        return '';
    }
  }

  String _getItemName(Map<String, dynamic> item, int tab) {
    switch (tab) {
      case 0:
      case 1:
      case 2:
      case 4:
        return item['name']?.toString() ?? '';
      case 3:
        return '${item['lastName']} ${item['firstName']} ${item['patronymic'] ?? ''}'.trim();
      default:
        return '';
    }
  }

  Future<void> _createOrEdit(int tab, {Map<String, dynamic>? item}) async {
    final endpoint = _getEndpoint(tab);
    final title = item == null ? 'Добавить' : 'Редактировать';
    
    if (tab == 3) {
      // Сотрудники требуют больше полей
      await _showEmployeeDialog(item: item);
    } else {
      await _showSimpleDialog(endpoint, title, item: item);
    }
  }

  Future<void> _showSimpleDialog(String endpoint, String title, {Map<String, dynamic>? item}) async {
    final controller = TextEditingController(text: item?['name'] as String? ?? '');
    final descriptionController = TextEditingController(
      text: item?['description'] as String? ?? '',
    );
    
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$title ${_getTabTitle(_selectedTab)}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              if (_selectedTab == 4) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (name == null || name.trim().isEmpty) return;

    try {
      final body = <String, dynamic>{
        'id': item?['id'] ?? 0,
        'name': name.trim(),
      };
      
      if (_selectedTab == 4 && descriptionController.text.isNotEmpty) {
        body['description'] = descriptionController.text.trim();
      }

      final nameValue = body['name'] as String;
      
      if (item == null) {
        switch (_selectedTab) {
          case 0:
            await _api.createCategory(nameValue);
            break;
          case 1:
            await _api.createRequestType(nameValue);
            break;
          case 2:
            await _api.createRequestStatus(nameValue);
            break;
          case 4:
            await _api.createDistrict(nameValue);
            break;
        }
      } else {
        switch (_selectedTab) {
          case 0:
            await _api.updateCategory(item['id'] as int, nameValue);
            break;
          case 1:
            await _api.updateRequestType(item['id'] as int, nameValue);
            break;
          case 2:
            await _api.updateRequestStatus(item['id'] as int, nameValue);
            break;
          case 4:
            await _api.updateDistrict(item['id'] as int, nameValue);
            break;
        }
      }

      await _loadAll();
      _showSuccess(item == null ? 'Добавлено' : 'Обновлено');
    } catch (e) {
      _showError('Ошибка: $e');
    }
  }

  Future<void> _showEmployeeDialog({Map<String, dynamic>? item}) async {
    final lastNameController = TextEditingController(text: item?['lastName'] as String? ?? '');
    final firstNameController = TextEditingController(text: item?['firstName'] as String? ?? '');
    final patronymicController = TextEditingController(text: item?['patronymic'] as String? ?? '');
    final phoneController = TextEditingController(text: item?['phone'] as String? ?? '');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item == null ? 'Добавить сотрудника' : 'Редактировать сотрудника'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: 'Фамилия', border: OutlineInputBorder()),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: 'Имя', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: patronymicController,
                decoration: const InputDecoration(labelText: 'Отчество', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Телефон', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (lastNameController.text.trim().isEmpty ||
                  firstNameController.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context, {
                'lastName': lastNameController.text.trim(),
                'firstName': firstNameController.text.trim(),
                'patronymic': patronymicController.text.trim(),
                'phone': phoneController.text.trim(),
              });
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result == null) return;

    try {
      final lastName = result['lastName'] as String;
      final firstName = result['firstName'] as String;
      final patronymic = result['patronymic']?.toString();
      
      if (item == null) {
        await _api.createEmployee(
          lastName,
          firstName,
          patronymic?.isEmpty ?? true ? null : patronymic,
        );
      } else {
        await _api.updateEmployee(
          item['id'] as int,
          lastName,
          firstName,
          patronymic?.isEmpty ?? true ? null : patronymic,
        );
      }

      await _loadAll();
      _showSuccess(item == null ? 'Сотрудник добавлен' : 'Сотрудник обновлён');
    } catch (e) {
      _showError('Ошибка: $e');
    }
  }

  Future<void> _delete(int tab, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: const Text('Вы уверены, что хотите удалить этот элемент?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      switch (tab) {
        case 0:
          await _api.deleteCategory(id);
          break;
        case 1:
          await _api.deleteRequestType(id);
          break;
        case 2:
          await _api.deleteRequestStatus(id);
          break;
        case 3:
          await _api.deleteEmployee(id);
          break;
        case 4:
          await _api.deleteDistrict(id);
          break;
      }

      await _loadAll();
      _showSuccess('Удалено');
    } catch (e) {
      _showError('Ошибка удаления: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
          tooltip: 'Назад',
        ),
        title: const Text('Администрирование справочников'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: const [HomeAction(), UserProfileAction()],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.category), text: 'Категории'),
            Tab(icon: Icon(Icons.description), text: 'Типы'),
            Tab(icon: Icon(Icons.flag), text: 'Статусы'),
            Tab(icon: Icon(Icons.people), text: 'Сотрудники'),
            Tab(icon: Icon(Icons.location_city), text: 'Районы'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(5, (index) => _buildTabContent(index)),
      ),
    );
  }

  Widget _buildTabContent(int tab) {
    if (_loading[tab] == true) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = _data[tab] ?? [];

    return Scaffold(
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Список пуст',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView.separated(
                itemCount: items.length,
                padding: const EdgeInsets.all(8),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Icon(_getIconForTab(tab)),
                    ),
                    title: Text(
                      _getItemName(item, tab),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: tab == 3
                        ? Text(item['phone']?.toString() ?? '')
                        : tab == 4
                            ? Text(item['description']?.toString() ?? '')
                            : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          color: Colors.blue,
                          onPressed: () => _createOrEdit(tab, item: item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          color: Colors.red,
                          onPressed: () => _delete(tab, item['id'] as int),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createOrEdit(tab),
        icon: const Icon(Icons.add),
        label: Text('Добавить ${_getTabTitle(tab).toLowerCase()}'),
      ),
    );
  }

  IconData _getIconForTab(int tab) {
    switch (tab) {
      case 0:
        return Icons.category;
      case 1:
        return Icons.description;
      case 2:
        return Icons.flag;
      case 3:
        return Icons.person;
      case 4:
        return Icons.location_city;
      default:
        return Icons.help_outline;
    }
  }
}



