import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/home_action.dart';
import '../widgets/user_profile_action.dart';
import '../services/api_service.dart';
import '../models/citizen_request.dart';

class RequestListScreen extends StatefulWidget {
  const RequestListScreen({super.key});

  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  final _api = ApiService();
  final _searchController = TextEditingController();
  
  List<CitizenRequestDto> _allItems = [];
  List<CitizenRequestDto> _filteredItems = [];
  bool _loading = true;

  // Справочники
  Map<int, String> _categories = {};
  Map<int, String> _statuses = {};
  Map<int, String> _districts = {};
  Map<int, String> _employees = {};

  // Фильтры
  int? _filterCategoryId;
  int? _filterDistrictId;
  int? _filterStatusId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait<dynamic>([
        _api.getCitizenRequests(),
        _api.getCategories(),
        _api.getRequestStatuses(),
        _api.getDistricts(),
        _api.getEmployees(),
      ]);

      if (!mounted) return;

      setState(() {
        _allItems = results[0] as List<CitizenRequestDto>;
        _categories = {
          for (var c in results[1] as List<Map<String, dynamic>>)
            c['id'] as int: c['name']?.toString() ?? ''
        };
        _statuses = {
          for (var s in results[2] as List<Map<String, dynamic>>)
            s['id'] as int: s['name']?.toString() ?? ''
        };
        _districts = {
          for (var d in results[3] as List<Map<String, dynamic>>)
            d['id'] as int: d['name']?.toString() ?? ''
        };
        // Парсим сотрудников, поддерживая оба варианта именования (camelCase и PascalCase)
        final employeesList = results[4] as List<dynamic>;
        _employees = {
          for (var e in employeesList)
            (e['id'] ?? e['Id']) as int:
                '${e['lastName'] ?? e['LastName'] ?? ''} ${e['firstName'] ?? e['FirstName'] ?? ''} ${e['patronymic'] ?? e['Patronymic'] ?? ''}'.trim()
        };
        _loading = false;
      });
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Ошибка загрузки: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredItems = _allItems.where((item) {
        if (_filterCategoryId != null && item.categoryId != _filterCategoryId) {
          return false;
        }
        if (_filterDistrictId != null && item.districtId != _filterDistrictId) {
          return false;
        }
        if (_filterStatusId != null && item.requestStatusId != _filterStatusId) {
          return false;
        }
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return item.requestNumber.toLowerCase().contains(query) ||
              item.description.toLowerCase().contains(query);
        }
        return true;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _filterCategoryId = null;
      _filterDistrictId = null;
      _filterStatusId = null;
      _searchQuery = '';
      _searchController.clear();
    });
    _applyFilters();
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
    final hasFilters = _filterCategoryId != null ||
        _filterDistrictId != null ||
        _filterStatusId != null ||
        _searchQuery.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
          tooltip: 'Назад',
        ),
        title: const Text('Обращения граждан'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
          ),
          const HomeAction(),
          const UserProfileAction(),
        ],
      ),
      body: Column(
        children: [
          // Панель фильтров
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Поиск
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Поиск по номеру или описанию',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _applyFilters();
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 12),
                
                // Фильтры
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: Text(_filterCategoryId != null
                          ? _categories[_filterCategoryId] ?? 'Категория'
                          : 'Категория'),
                      selected: _filterCategoryId != null,
                      onSelected: (_) => _showCategoryFilter(),
                      avatar: const Icon(Icons.category, size: 18),
                    ),
                    FilterChip(
                      label: Text(_filterDistrictId != null
                          ? _districts[_filterDistrictId] ?? 'Район'
                          : 'Район'),
                      selected: _filterDistrictId != null,
                      onSelected: (_) => _showDistrictFilter(),
                      avatar: const Icon(Icons.location_city, size: 18),
                    ),
                    FilterChip(
                      label: Text(_filterStatusId != null
                          ? _statuses[_filterStatusId] ?? 'Статус'
                          : 'Статус'),
                      selected: _filterStatusId != null,
                      onSelected: (_) => _showStatusFilter(),
                      avatar: const Icon(Icons.flag, size: 18),
                    ),
                    if (hasFilters)
                      ActionChip(
                        label: const Text('Сбросить'),
                        avatar: const Icon(Icons.clear, size: 18),
                        onPressed: _resetFilters,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Счётчик
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.filter_list, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Найдено: ${_filteredItems.length} из ${_allItems.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Список
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 80, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              hasFilters ? 'Ничего не найдено' : 'Обращений пока нет',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (hasFilters) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _resetFilters,
                                icon: const Icon(Icons.clear),
                                label: const Text('Сбросить фильтры'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAll,
                        child: ListView.separated(
                          itemCount: _filteredItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            return _buildRequestCard(item);
                          },
                        ),
                      ),
          ),
        ],
      ),
      // FAB убран - сотрудники не создают обращения, они их обрабатывают
      // Граждане создают обращения через свой интерфейс
    );
  }

  Widget _buildRequestCard(CitizenRequestDto item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (item.id > 0) {
            context.go('/requests/${item.id}');
          } else {
            _showError('Неверный ID обращения');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D47A1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '№ ${item.requestNumber}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: Color(0xFF0D47A1),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildStatusChip(item.requestStatusId),
                ],
              ),
              const SizedBox(height: 12),

              // Описание
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 12),

              // Информация
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.category,
                    _categories[item.categoryId] ?? 'Категория',
                    Colors.blue,
                  ),
                  if (item.districtId != null)
                    _buildInfoChip(
                      Icons.location_city,
                      _districts[item.districtId] ?? 'Район',
                      Colors.purple,
                    ),
                  if (item.aiPriority != null)
                    _buildPriorityChip(item.aiPriority!),
                  _buildInfoChip(
                    Icons.access_time,
                    _formatDate(item.incidentTime),
                    Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Быстрые действия
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _quickChangeStatus(item),
                    icon: const Icon(Icons.flag, size: 18),
                    label: const Text('Статус'),
                  ),
                  TextButton.icon(
                    onPressed: () => _quickAssign(item),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Назначить'),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      if (item.id > 0) {
                        context.go('/requests/${item.id}');
                      } else {
                        _showError('Неверный ID обращения');
                      }
                    },
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Открыть'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(int statusId) {
    final statusName = _statuses[statusId] ?? '—';
    Color color;
    Color textColor;
    switch (statusId) {
      case 1:
        color = Colors.blue;
        textColor = Colors.blue.shade900;
        break;
      case 2:
        color = Colors.orange;
        textColor = Colors.orange.shade900;
        break;
      case 3:
        color = Colors.green;
        textColor = Colors.green.shade900;
        break;
      default:
        color = Colors.grey;
        textColor = Colors.grey.shade900;
    }
    return Chip(
      label: Text(statusName),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(
        color: textColor,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      labelStyle: const TextStyle(fontSize: 12),
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color;
    Color textColor;
    IconData icon;
    switch (priority) {
      case 'Высокий':
        color = Colors.red;
        textColor = Colors.red.shade900;
        icon = Icons.priority_high;
        break;
      case 'Средний':
        color = Colors.orange;
        textColor = Colors.orange.shade900;
        icon = Icons.remove;
        break;
      case 'Низкий':
        color = Colors.green;
        textColor = Colors.green.shade900;
        icon = Icons.arrow_downward;
        break;
      default:
        color = Colors.grey;
        textColor = Colors.grey.shade900;
        icon = Icons.help_outline;
    }
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(priority),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(
        color: textColor,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _showCategoryFilter() async {
    final result = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Фильтр по категории'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<int?>(
              value: null,
              groupValue: _filterCategoryId,
              title: const Text('Все'),
              onChanged: (v) => Navigator.pop(ctx, v),
            ),
            ..._categories.entries.map(
              (e) => RadioListTile<int?>(
                value: e.key,
                groupValue: _filterCategoryId,
                title: Text(e.value),
                onChanged: (v) => Navigator.pop(ctx, v),
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null || result == null) {
      setState(() => _filterCategoryId = result);
      _applyFilters();
    }
  }

  Future<void> _showDistrictFilter() async {
    final result = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Фильтр по району'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<int?>(
              value: null,
              groupValue: _filterDistrictId,
              title: const Text('Все'),
              onChanged: (v) => Navigator.pop(ctx, v),
            ),
            ..._districts.entries.map(
              (e) => RadioListTile<int?>(
                value: e.key,
                groupValue: _filterDistrictId,
                title: Text(e.value),
                onChanged: (v) => Navigator.pop(ctx, v),
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null || result == null) {
      setState(() => _filterDistrictId = result);
      _applyFilters();
    }
  }

  Future<void> _showStatusFilter() async {
    final result = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Фильтр по статусу'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<int?>(
              value: null,
              groupValue: _filterStatusId,
              title: const Text('Все'),
              onChanged: (v) => Navigator.pop(ctx, v),
            ),
            ..._statuses.entries.map(
              (e) => RadioListTile<int?>(
                value: e.key,
                groupValue: _filterStatusId,
                title: Text(e.value),
                onChanged: (v) => Navigator.pop(ctx, v),
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null || result == null) {
      setState(() => _filterStatusId = result);
      _applyFilters();
    }
  }

  Future<void> _quickChangeStatus(CitizenRequestDto item) async {
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Изменить статус обращения ${item.requestNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _statuses.entries
              .map(
                (e) => RadioListTile<int>(
                  value: e.key,
                  groupValue: item.requestStatusId,
                  title: Text(e.value),
                  onChanged: (v) => Navigator.pop(ctx, v),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );

    if (result != null && result != item.requestStatusId) {
      try {
        await _api.updateStatus(item.id, result);
        await _loadAll();
        _showSuccess('Статус обновлён');
      } catch (e) {
        _showError('Ошибка обновления статуса: $e');
      }
    }
  }

  Future<void> _quickAssign(CitizenRequestDto item) async {
    if (_employees.isEmpty) {
      _showError('Список сотрудников не загружен. Попробуйте обновить страницу.');
      return;
    }

    int? selectedEmployeeId = item.assignedToId;
    
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Назначить исполнителя для ${item.requestNumber}'),
          content: SizedBox(
            width: 400,
            height: 300,
            child: _employees.isEmpty
                ? const Center(
                    child: Text('Сотрудники не найдены'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _employees.length,
                    itemBuilder: (context, index) {
                      final entry = _employees.entries.elementAt(index);
                      return RadioListTile<int>(
                        value: entry.key,
                        groupValue: selectedEmployeeId,
                        title: Text(entry.value.isEmpty ? 'Сотрудник #${entry.key}' : entry.value),
                        onChanged: (v) {
                          setDialogState(() {
                            selectedEmployeeId = v;
                          });
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            if (selectedEmployeeId != null)
              FilledButton(
                onPressed: () => Navigator.pop(ctx, selectedEmployeeId),
                child: const Text('Назначить'),
              ),
          ],
        ),
      ),
    );

    if (result != null && result != item.assignedToId) {
      try {
        await _api.assignRequest(item.id, result);
        await _loadAll();
        _showSuccess('Исполнитель назначен');
      } catch (e) {
        _showError('Ошибка назначения: $e');
      }
    }
  }

  String _formatDate(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
