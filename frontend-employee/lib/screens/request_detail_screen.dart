import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../widgets/home_action.dart';
import '../widgets/user_profile_action.dart';
import '../services/api_service.dart';
import '../models/citizen_request.dart';

class RequestDetailScreen extends StatefulWidget {
  final int id;
  const RequestDetailScreen({super.key, required this.id});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  final _api = ApiService();
  CitizenRequestDto? _data;
  bool _loading = true;

  Map<int, String> _categories = {};
  Map<int, String> _requestTypes = {};
  Map<int, String> _statuses = {};
  Map<int, String> _employees = {};
  Map<int, String> _districts = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final results = await Future.wait<dynamic>([
        _api.getRequestById(widget.id),
        _api.getCategories(),
        _api.getRequestTypes(),
        _api.getRequestStatuses(),
        _api.getEmployees(),
        _api.getDistricts(),
      ]);

      if (!mounted) return;

      setState(() {
        _data = results[0] as CitizenRequestDto;
        _categories = {
          for (var c in results[1] as List<Map<String, dynamic>>)
            c['id'] as int: c['name']?.toString() ?? '',
        };
        _requestTypes = {
          for (var t in results[2] as List<Map<String, dynamic>>)
            t['id'] as int: t['name']?.toString() ?? '',
        };
        _statuses = {
          for (var s in results[3] as List<Map<String, dynamic>>)
            s['id'] as int: s['name']?.toString() ?? '',
        };
        _employees = {
          for (var e in results[4] as List<Map<String, dynamic>>)
            e['id'] as int:
                '${e['lastName']} ${e['firstName']} ${e['patronymic'] ?? ''}'
                    .trim(),
        };
        _districts = {
          for (var d in results[5] as List<Map<String, dynamic>>)
            d['id'] as int: d['name']?.toString() ?? '',
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

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final d = await _api.getRequestById(widget.id);
      if (!mounted) return;
      setState(() {
        _data = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Ошибка обновления: $e');
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
          onPressed: () => context.go('/requests'),
          tooltip: 'Назад к списку',
        ),
        title: Text('Обращение №${_data?.requestNumber ?? ''}'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: const [HomeAction(), UserProfileAction()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
          ? const Center(child: Text('Не найдено'))
          : RefreshIndicator(
              onRefresh: _reload,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Основная информация
                    _buildSection('Основная информация', Icons.info_outline, [
                      _buildInfoRow(
                        'Номер обращения',
                        _data!.requestNumber,
                        isMono: true,
                      ),
                      _buildInfoRow(
                        'Тип',
                        _requestTypes[_data!.requestTypeId] ?? '—',
                      ),
                      _buildInfoRow(
                        'Категория',
                        _categories[_data!.categoryId] ?? '—',
                      ),
                      _buildInfoRow(
                        'Статус',
                        _statuses[_data!.requestStatusId] ?? '—',
                        chip: _buildStatusChip(_data!.requestStatusId),
                      ),
                      if (_data!.districtId != null)
                        _buildInfoRow(
                          'Район',
                          _districts[_data!.districtId] ?? '—',
                        ),
                      _buildInfoRow('Создано', _formatDate(_data!.createdAt)),
                      _buildInfoRow(
                        'Время инцидента',
                        _formatDate(_data!.incidentTime),
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // Описание
                    _buildSection('Описание обращения', Icons.description, [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          _data!.description,
                          style: const TextStyle(fontSize: 15, height: 1.5),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // Геолокация
                    _buildSection('Геолокация', Icons.location_on, [
                      _buildInfoRow('Адрес инцидента', _data!.incidentLocation),
                      _buildInfoRow('Адрес гражданина', _data!.citizenLocation),
                      if (_data!.latitude != null &&
                          _data!.longitude != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(
                                _data!.latitude!,
                                _data!.longitude!,
                              ),
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
                                    point: LatLng(
                                      _data!.latitude!,
                                      _data!.longitude!,
                                    ),
                                    width: 50,
                                    height: 50,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 50,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 16),

                    // AI-анализ
                    if (_data!.aiAnalyzedAt != null)
                      _buildSection('AI-анализ', Icons.auto_awesome, [
                        _buildInfoRow(
                          'Категория (AI)',
                          _data!.aiCategory ?? '—',
                          chip: _data!.isAiCorrected == true
                              ? const Chip(
                                  label: Text('Скорректировано'),
                                  backgroundColor: Colors.amber,
                                )
                              : null,
                        ),
                        _buildInfoRow(
                          'Финальная категория',
                          _data!.finalCategory ?? '—',
                        ),
                        _buildInfoRow(
                          'Приоритет',
                          _data!.aiPriority ?? '—',
                          chip: _buildPriorityChip(_data!.aiPriority),
                        ),
                        _buildInfoRow(
                          'Тональность',
                          _data!.aiSentiment ?? '—',
                          chip: _buildSentimentChip(_data!.aiSentiment),
                        ),
                        if (_data!.aiSummary != null) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Резюме:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(_data!.aiSummary!),
                          ),
                        ],
                        if (_data!.aiSuggestedAction != null) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Рекомендуемое действие:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(_data!.aiSuggestedAction!),
                          ),
                        ],
                        _buildInfoRow(
                          'Проанализировано',
                          _formatDate(_data!.aiAnalyzedAt!),
                        ),
                      ]),
                    const SizedBox(height: 16),

                    // Сотрудники
                    _buildSection('Сотрудники', Icons.people, [
                      _buildInfoRow(
                        'Принял',
                        _employees[_data!.acceptedById] ?? '—',
                      ),
                      _buildInfoRow(
                        'Исполнитель',
                        _data!.assignedToId != null
                            ? (_employees[_data!.assignedToId] ?? '—')
                            : 'Не назначен',
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // Действия
                    _buildSection('Действия', Icons.settings, [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: _showStatusDialog,
                            icon: const Icon(Icons.flag),
                            label: const Text('Изменить статус'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: _showAssignDialog,
                            icon: const Icon(Icons.person_add),
                            label: const Text('Назначить исполнителя'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                            ),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: _reclassifyAi,
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('Пересчитать ИИ'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: _correctCategory,
                            icon: const Icon(Icons.edit),
                            label: const Text('Скорректировать категорию'),
                          ),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D47A1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF0D47A1), size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isMono = false,
    Widget? chip,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child:
                chip ??
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: isMono ? 'monospace' : null,
                    letterSpacing: isMono ? 1.5 : null,
                  ),
                ),
          ),
        ],
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
      labelStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPriorityChip(String? priority) {
    if (priority == null) return const Text('—');
    Color color;
    Color textColor;
    switch (priority) {
      case 'Высокий':
        color = Colors.red;
        textColor = Colors.red.shade900;
        break;
      case 'Средний':
        color = Colors.orange;
        textColor = Colors.orange.shade900;
        break;
      case 'Низкий':
        color = Colors.green;
        textColor = Colors.green.shade900;
        break;
      default:
        color = Colors.grey;
        textColor = Colors.grey.shade900;
    }
    return Chip(
      label: Text(priority),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSentimentChip(String? sentiment) {
    if (sentiment == null) return const Text('—');
    Color color;
    Color textColor;
    switch (sentiment) {
      case 'Негативный':
        color = Colors.red;
        textColor = Colors.red.shade900;
        break;
      case 'Нейтральный':
        color = Colors.blue;
        textColor = Colors.blue.shade900;
        break;
      case 'Позитивный':
        color = Colors.green;
        textColor = Colors.green.shade900;
        break;
      default:
        color = Colors.grey;
        textColor = Colors.grey.shade900;
    }
    return Chip(
      label: Text(sentiment),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold),
    );
  }

  Future<void> _showStatusDialog() async {
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Изменить статус'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _statuses.entries
              .map(
                (e) => RadioListTile<int>(
                  value: e.key,
                  groupValue: _data!.requestStatusId,
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

    if (result != null && result != _data!.requestStatusId) {
      try {
        await _api.updateStatus(_data!.id, result);
        await _reload();
        _showSuccess('Статус обновлён');
      } catch (e) {
        _showError('Ошибка обновления статуса: $e');
      }
    }
  }

  Future<void> _showAssignDialog() async {
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Назначить исполнителя'),
        content: SizedBox(
          width: 400,
          child: ListView(
            shrinkWrap: true,
            children: _employees.entries
                .map(
                  (e) => RadioListTile<int>(
                    value: e.key,
                    groupValue: _data!.assignedToId,
                    title: Text(e.value),
                    onChanged: (v) => Navigator.pop(ctx, v),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );

    if (result != null && result != _data!.assignedToId) {
      try {
        await _api.assignRequest(_data!.id, result);
        await _reload();
        _showSuccess('Исполнитель назначен');
      } catch (e) {
        _showError('Ошибка назначения: $e');
      }
    }
  }

  Future<void> _reclassifyAi() async {
    try {
      await _api.reclassifyAi(_data!.id);
      await _reload();
      _showSuccess('AI-анализ пересчитан');
    } catch (e) {
      _showError('Ошибка пересчёта: $e');
    }
  }

  Future<void> _correctCategory() async {
    final currentCategoryId = _data!.categoryId;
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Скорректировать категорию ИИ'),
        content: SizedBox(
          width: 400,
          child: ListView(
            shrinkWrap: true,
            children: _categories.entries
                .map(
                  (e) => RadioListTile<int>(
                    value: e.key,
                    groupValue: currentCategoryId,
                    title: Text(e.value),
                    onChanged: (v) => Navigator.pop(ctx, v),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, currentCategoryId),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result != null && result != currentCategoryId) {
      try {
        await _api.correctAiCategory(_data!.id, _categories[result] ?? '');
        await _reload();
        _showSuccess('Категория скорректирована');
      } catch (e) {
        _showError('Ошибка коррекции: $e');
      }
    }
  }

  String _formatDate(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;

    // Конвертируем в часовой пояс Новосибирска (UTC+7)
    final novosibirskTime = date.toUtc().add(const Duration(hours: 7));

    return '${novosibirskTime.day.toString().padLeft(2, '0')}.${novosibirskTime.month.toString().padLeft(2, '0')}.${novosibirskTime.year} '
        '${novosibirskTime.hour.toString().padLeft(2, '0')}:${novosibirskTime.minute.toString().padLeft(2, '0')}';
  }
}
