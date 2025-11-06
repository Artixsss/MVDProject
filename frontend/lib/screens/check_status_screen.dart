import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

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
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void dispose() {
    _requestNumberController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final requestNumber = _requestNumberController.text.trim();
    if (requestNumber.isEmpty) {
      setState(() {
        _error = 'Введите номер обращения';
        _result = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final data = await _api.checkRequestStatus(requestNumber);
      if (!mounted) return;
      
      setState(() {
        _result = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Обращение не найдено. Проверьте номер и попробуйте снова.';
        _loading = false;
      });
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
                if (_result != null) ...[
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          const Divider(height: 32),
                          
                          _buildInfoRow(
                            'Номер обращения:',
                            _result!['number']?.toString() ?? '—',
                            isMono: true,
                          ),
                          const SizedBox(height: 16),
                          
                          _buildInfoRow(
                            'Статус:',
                            _getStatusName(_result!['status']),
                            color: _getStatusColor(_result!['status']),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildInfoRow(
                            'Дата создания:',
                            _formatDate(_result!['createdAt']?.toString() ?? ''),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildInfoRow(
                            'Категория:',
                            _getCategoryName(_result!['category']),
                          ),
                          const SizedBox(height: 16),
                          
                          if (_result!['description'] != null) ...[
                            const Text(
                              'Описание:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _result!['description']?.toString() ?? '',
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
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
                          child: Text(
                            'При изменении статуса вашего обращения, мы свяжемся с вами по указанному телефону.',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontSize: 14,
                            ),
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

  String _getStatusName(dynamic statusId) {
    final id = statusId is int ? statusId : int.tryParse(statusId?.toString() ?? '');
    switch (id) {
      case 1:
        return 'Новое';
      case 2:
        return 'В работе';
      case 3:
        return 'Закрыто';
      default:
        return 'Неизвестно';
    }
  }

  Color _getStatusColor(dynamic statusId) {
    final id = statusId is int ? statusId : int.tryParse(statusId?.toString() ?? '');
    switch (id) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryName(dynamic categoryId) {
    final id = categoryId is int ? categoryId : int.tryParse(categoryId?.toString() ?? '');
    switch (id) {
      case 1:
        return 'Правонарушение';
      case 2:
        return 'ДТП';
      case 3:
        return 'Угроза';
      case 4:
        return 'Социальный конфликт';
      case 5:
        return 'Безопасность';
      default:
        return 'Прочее';
    }
  }

  String _formatDate(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

