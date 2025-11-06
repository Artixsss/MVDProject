import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../models/citizen_request.dart';

/// Экран проверки статуса обращения по номеру (для граждан)
class CheckStatusScreen extends StatefulWidget {
  const CheckStatusScreen({super.key});

  @override
  State<CheckStatusScreen> createState() => _CheckStatusScreenState();
}

class _CheckStatusScreenState extends State<CheckStatusScreen> {
  final _api = ApiService();
  final _requestNumberController = TextEditingController();
  
  bool _loading = false;
  CitizenRequestDto? _request;
  String? _error;
  Timer? _autoRefreshTimer;
  
  List<Map<String, dynamic>> _statuses = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _requestTypes = [];

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  @override
  void dispose() {
    _requestNumberController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    try {
      final results = await Future.wait([
        _api.getRequestStatuses(),
        _api.getCategories(),
        _api.getRequestTypes(),
      ]);
      if (!mounted) return;
      setState(() {
        _statuses = results[0];
        _categories = results[1];
        _requestTypes = results[2];
      });
    } catch (e) {
      // Игнорируем ошибки загрузки справочников
    }
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    if (_request != null) {
      _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _refreshData();
      });
    }
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
  }

  Future<void> _refreshData() async {
    if (_requestNumberController.text.trim().isEmpty || _loading) return;
    await _checkStatus(silent: true);
  }

  Future<void> _checkStatus({bool silent = false}) async {
    final requestNumber = _requestNumberController.text.trim();
    if (requestNumber.isEmpty) {
      setState(() {
        _error = 'Введите номер обращения';
        _request = null;
      });
      _stopAutoRefresh();
      return;
    }

    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final request = await _api.getRequestByNumber(requestNumber);
      if (!mounted) return;
      
      setState(() {
        _request = request;
        _error = null;
        _loading = false;
      });
      
      _startAutoRefresh();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Обращение не найдено. Проверьте номер и попробуйте снова.';
        _request = null;
        _loading = false;
      });
      _stopAutoRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Проверить статус обращения'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/complaint'),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Подать обращение', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Проверка статуса обращения',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0D47A1),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Введите номер обращения, полученный при подаче',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Поле ввода номера
                TextField(
                  controller: _requestNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Номер обращения',
                    hintText: 'ABCD123456',
                    prefixIcon: Icon(Icons.tag),
                    border: OutlineInputBorder(),
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 2,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (_) => _checkStatus(),
                ),
                const SizedBox(height: 16),

                // Кнопка поиска
                FilledButton.icon(
                  onPressed: _loading ? null : _checkStatus,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search),
                  label: Text(_loading ? 'Поиск...' : 'Проверить статус'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(20),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 32),

                // Ошибка
                if (_error != null)
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Результат
                if (_request != null) ...[
                  // Заголовок с кнопкой обновления
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Обращение найдено',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Обновить данные',
                        onPressed: _loading ? null : _refreshData,
                        color: const Color(0xFF0D47A1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Номер обращения
                          _buildInfoRow(
                            'Номер обращения:',
                            _request!.requestNumber,
                            isMono: true,
                          ),
                          const SizedBox(height: 20),
                          
                          // Статус с цветом
                          _buildStatusCard(),
                          const SizedBox(height: 20),
                          
                          // Основная информация
                          _buildSectionHeader('Основная информация'),
                          const SizedBox(height: 16),
                          
                          _buildInfoRow(
                            'Категория:',
                            _getCategoryName(_request!.categoryId),
                          ),
                          const SizedBox(height: 12),
                          
                          _buildInfoRow(
                            'Тип обращения:',
                            _getRequestTypeName(_request!.requestTypeId),
                          ),
                          const SizedBox(height: 12),
                          
                          _buildInfoRow(
                            'Дата создания:',
                            _formatDate(_request!.createdAt),
                          ),
                          const SizedBox(height: 12),
                          
                          _buildInfoRow(
                            'Дата инцидента:',
                            _formatDate(_request!.incidentTime),
                          ),
                          const SizedBox(height: 20),
                          
                          // Адреса
                          _buildSectionHeader('Адреса'),
                          const SizedBox(height: 16),
                          
                          _buildInfoRow(
                            'Адрес инцидента:',
                            _request!.incidentLocation,
                          ),
                          const SizedBox(height: 12),
                          
                          if (_request!.citizenLocation.isNotEmpty && _request!.citizenLocation != 'Не указан')
                            _buildInfoRow(
                              'Адрес регистрации:',
                              _request!.citizenLocation,
                            ),
                          const SizedBox(height: 20),
                          
                          // Описание
                          if (_request!.description.isNotEmpty) ...[
                            _buildSectionHeader('Описание'),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _request!.description,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          
                          // AI-анализ (если есть)
                          if (_request!.aiAnalyzedAt != null || _request!.aiSummary != null || _request!.aiPriority != null) ...[
                            _buildSectionHeader('AI-анализ'),
                            const SizedBox(height: 16),
                            
                            // Категория, определенная AI
                            if (_request!.aiCategory != null)
                              _buildInfoRow(
                                'Категория (AI):',
                                _request!.aiCategory!,
                              ),
                            
                            // Приоритет
                            if (_request!.aiPriority != null) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                'Приоритет:',
                                _request!.aiPriority!,
                                color: _getPriorityColor(_request!.aiPriority!),
                              ),
                            ],
                            
                            // Тональность
                            if (_request!.aiSentiment != null) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                'Тональность:',
                                _request!.aiSentiment!,
                              ),
                            ],
                            
                            // Резюме
                            if (_request!.aiSummary != null) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'Краткое содержание:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Text(
                                  _request!.aiSummary!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                            
                            // Рекомендуемые действия
                            if (_request!.aiSuggestedAction != null) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'Рекомендуемые действия:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Text(
                                  _request!.aiSuggestedAction!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                            
                            // Дата анализа
                            if (_request!.aiAnalyzedAt != null) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                'Проанализировано:',
                                _formatDate(_request!.aiAnalyzedAt!),
                              ),
                            ],
                            
                            const SizedBox(height: 20),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Информационное сообщение
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Данные обновляются автоматически каждые 30 секунд',
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'При изменении статуса вашего обращения, мы свяжемся с вами по указанному телефону.',
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? color,
    bool isMono = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontFamily: isMono ? 'monospace' : null,
              letterSpacing: isMono ? 1.5 : null,
              color: color,
              fontWeight: color != null ? FontWeight.bold : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    final statusName = _getStatusName(_request!.requestStatusId);
    final statusColor = _getStatusColor(_request!.requestStatusId);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(_request!.requestStatusId),
            color: statusColor,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Статус обращения:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D47A1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0D47A1),
        ),
      ),
    );
  }

  String _getStatusName(int statusId) {
    final status = _statuses.firstWhere(
      (s) => s['id'] == statusId,
      orElse: () => {'name': 'Неизвестно'},
    );
    return status['name']?.toString() ?? 'Неизвестно';
  }

  Color _getStatusColor(int statusId) {
    final statusName = _getStatusName(statusId).toLowerCase();
    if (statusName.contains('новое') || statusName.contains('нов')) {
      return Colors.blue;
    } else if (statusName.contains('работа') || statusName.contains('обработ')) {
      return Colors.orange;
    } else if (statusName.contains('проверк')) {
      return Colors.purple;
    } else if (statusName.contains('выполнено') || statusName.contains('закрыт')) {
      return Colors.green;
    } else if (statusName.contains('отклонен')) {
      return Colors.red;
    }
    return Colors.grey;
  }

  IconData _getStatusIcon(int statusId) {
    final statusName = _getStatusName(statusId).toLowerCase();
    if (statusName.contains('новое') || statusName.contains('нов')) {
      return Icons.new_releases;
    } else if (statusName.contains('работа') || statusName.contains('обработ')) {
      return Icons.work;
    } else if (statusName.contains('проверк')) {
      return Icons.verified;
    } else if (statusName.contains('выполнено') || statusName.contains('закрыт')) {
      return Icons.check_circle;
    } else if (statusName.contains('отклонен')) {
      return Icons.cancel;
    }
    return Icons.help_outline;
  }

  String _getCategoryName(int categoryId) {
    final category = _categories.firstWhere(
      (c) => c['id'] == categoryId,
      orElse: () => {'name': 'Неизвестная категория'},
    );
    return category['name']?.toString() ?? 'Неизвестная категория';
  }

  String _getRequestTypeName(int requestTypeId) {
    final requestType = _requestTypes.firstWhere(
      (t) => t['id'] == requestTypeId,
      orElse: () => {'name': 'Неизвестный тип'},
    );
    return requestType['name']?.toString() ?? 'Неизвестный тип';
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

  String _formatDate(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

