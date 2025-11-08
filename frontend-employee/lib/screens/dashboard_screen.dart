import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/citizen_request.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  final _api = ApiService();
  List<CitizenRequestDto> _requests = const [];
  List<Marker> _markers = const [];
  Map<String, dynamic>? _aiStats;
  bool _loading = true;
  String _userName = '';
  String _userRole = '';
  bool _hasLoaded = false;
  DateTime? _lastLoadTime;
  static const _minLoadInterval = Duration(seconds: 2);

  final MapController _mapController = MapController();
  static const LatLng _novosibirskCenter = LatLng(55.0302, 82.9204);
  LatLng _mapCenter = _novosibirskCenter;
  double _currentZoom = 11;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserInfo();
    _load();
    _hasLoaded = true;
    _lastLoadTime = DateTime.now();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Загружаем данные только при первой инициализации
    // Для перезагрузки при возвращении используем кнопку обновления
    if (!_hasLoaded && !_loading) {
      _hasLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_loading) {
          _load();
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Перезагружаем данные при возвращении приложения в активное состояние
    if (state == AppLifecycleState.resumed && _hasLoaded && mounted) {
      final now = DateTime.now();
      if (_lastLoadTime == null || 
          now.difference(_lastLoadTime!) > _minLoadInterval) {
        _lastLoadTime = now;
        _load();
      }
    }
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      try {
        final Map<String, dynamic> j = jsonDecode(userJson);
        setState(() {
          final employee = j['employee'] ?? j['Employee'];
          if (employee != null) {
            _userName = employee['fullName']?.toString() ?? 'Сотрудник';
          }
          _userRole = (j['role'] ?? j['Role'])?.toString() ?? 'Operator';
        });
      } catch (_) {}
    }
  }

  Future<void> _load() async {
    try {
      setState(() => _loading = true);
      
      // Загружаем данные независимо, чтобы при ошибке одного запроса другой все равно загрузился
      List<CitizenRequestDto> requests = [];
      Map<String, dynamic> aiStats = {};
      
      try {
        requests = await _api.getCitizenRequests();
      } catch (e) {
        debugPrint('Error loading requests: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка загрузки обращений: ${e.toString().split('\n').first}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
      
      try {
        aiStats = await _api.getAiStats();
      } catch (e) {
        debugPrint('Error loading AI stats: $e');
        // Не показываем ошибку для AI stats, так как это не критично
      }
      
      if (!mounted) return;
      
      setState(() {
        _requests = requests;
        _aiStats = aiStats;
        _loading = false;
        _lastLoadTime = DateTime.now();
      });
      
      _buildMarkers();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      // Показываем ошибку пользователю только если оба запроса упали
      if (mounted && _requests.isEmpty && (_aiStats?.isEmpty ?? true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки данных: ${e.toString().split('\n').first}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      // Логируем для отладки
      debugPrint('Dashboard load error: $e');
    }
  }

  void _buildMarkers() {
    setState(() {
      _markers = _requests
          .where((e) => e.latitude != null && e.longitude != null)
          .map((e) => Marker(
                point: LatLng(e.latitude!, e.longitude!),
                width: 50,
                height: 50,
                child: GestureDetector(
                  onTap: () => _showRequestPopup(context, e),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 50,
                        color: _getPriorityColor(e.aiPriority),
                        shadows: const [
                          Shadow(
                            blurRadius: 3,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                      Positioned(
                        top: 12,
                        child: Icon(
                          _getCategoryIcon(e.categoryId),
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ))
          .toList();
    });
  }

  Color _getPriorityColor(String? p) {
    switch (p) {
      case 'Высокий':
        return Colors.red;
      case 'Средний':
        return Colors.orange;
      case 'Низкий':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData _getCategoryIcon(int categoryId) {
    switch (categoryId) {
      case 1:
        return Icons.warning;
      case 2:
        return Icons.car_crash;
      case 3:
        return Icons.report_problem;
      case 4:
        return Icons.people;
      case 5:
        return Icons.security;
      default:
        return Icons.help_outline;
    }
  }

  void _zoomMap(double delta) {
    setState(() {
      _currentZoom = (_currentZoom + delta).clamp(3.0, 18.0);
      _mapController.move(_mapCenter, _currentZoom);
    });
  }

  void _centerMap() {
    setState(() {
      _mapCenter = _novosibirskCenter;
      _currentZoom = 11;
      _mapController.move(_mapCenter, _currentZoom);
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Верхняя панель МВД
          _buildHeader(),
          
          // Основной контент
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      // Боковое меню
                      _buildSideMenu(),
                      
                      // Главная область
                      Expanded(
                        child: Column(
                          children: [
                            // KPI панель
                            _buildKPIPanel(),
                            
                            // Карта с данными
                            Expanded(
                              child: _buildMapSection(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Логотип и название
          const Icon(Icons.security, color: Colors.white, size: 36),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'МВД России',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Система учёта обращений граждан',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          
          // Информация о пользователе
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Color(0xFF0D47A1), size: 20),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _userName.isNotEmpty ? _userName : 'Сотрудник',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _getRoleDisplayName(_userRole),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Обновить данные',
                  onPressed: _load,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'logout') _logout();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 20),
                          SizedBox(width: 8),
                          Text('Выход'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideMenu() {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildMenuItem(
            Icons.dashboard,
            'Главная',
            true,
            () {},
          ),
          _buildMenuItem(
            Icons.list_alt,
            'Обращения',
            false,
            () => context.go('/requests'),
          ),
          _buildMenuItem(
            Icons.analytics,
            'Аналитика',
            false,
            () => context.go('/analytics'),
          ),
          const Divider(height: 32),
          
          // ФУНКЦИОНАЛ ПО РОЛЯМ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              _userRole == 'Admin' ? 'АДМИНИСТРАТОР' : 'ОПЕРАТОР',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          
          // Для операторов - создание обращений
          if (_userRole == 'Operator' || _userRole == 'Admin')
            _buildMenuItem(
              Icons.add_box,
              'Создать обращение',
              false,
              () => context.go('/operator/create-request'),
            ),
          
          // Для админов - управление сотрудниками
          if (_userRole == 'Admin')
            _buildMenuItem(
              Icons.manage_accounts,
              'Управление сотрудниками',
              false,
              () => context.go('/admin/employees'),
            ),
          
          // Для админов - администрирование БД
          if (_userRole == 'Admin')
            _buildMenuItem(
              Icons.admin_panel_settings,
              'Администрирование БД',
              false,
              () => context.go('/admin'),
            ),
          
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'СТАТИСТИКА',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          _buildStatTile('Всего обращений', _requests.length.toString(), Icons.inbox, Colors.blue),
          _buildStatTile(
            'Новых',
            _requests.where((r) => r.requestStatusId == 1).length.toString(),
            Icons.fiber_new,
            Colors.green,
          ),
          _buildStatTile(
            'В работе',
            _requests.where((r) => r.requestStatusId == 2).length.toString(),
            Icons.work,
            Colors.orange,
          ),
          _buildStatTile(
            'Закрытых',
            _requests.where((r) => r.requestStatusId == 3).length.toString(),
            Icons.check_circle,
            Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, bool isActive, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF0D47A1).withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? const Color(0xFF0D47A1) : Colors.grey.shade700,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? const Color(0xFF0D47A1) : Colors.grey.shade800,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        dense: true,
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPIPanel() {
    final total = _requests.length;
    // Поддерживаем оба варианта именования (camelCase и PascalCase)
    final analyzed = (_aiStats?['analyzedRequests'] ?? _aiStats?['AnalyzedRequests']) as int? ?? 0;
    final coverage = (_aiStats?['analysisCoveragePercent'] ?? _aiStats?['AnalysisCoveragePercent']) as double? ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildKPICard(
              'Всего обращений',
              total.toString(),
              Icons.inbox,
              Colors.blue,
              'За весь период',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildKPICard(
              'Проанализировано ИИ',
              '$analyzed / $total',
              Icons.auto_awesome,
              Colors.purple,
              '${coverage.toStringAsFixed(1)}% покрытие',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildKPICard(
              'Высокий приоритет',
              _requests.where((r) => r.aiPriority == 'Высокий').length.toString(),
              Icons.priority_high,
              Colors.red,
              'Требуют внимания',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildKPICard(
              'Средний приоритет',
              _requests.where((r) => r.aiPriority == 'Средний').length.toString(),
              Icons.remove,
              Colors.orange,
              'В обработке',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Icon(Icons.trending_up, color: Colors.green.shade400, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _mapCenter,
                initialZoom: _currentZoom,
                onPositionChanged: (pos, _) {
                  if (pos.center != null) _mapCenter = pos.center!;
                  if (pos.zoom != null) _currentZoom = pos.zoom!;
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'mvd.frontend.app',
                ),
                MarkerLayer(markers: _markers),
              ],
            ),
            
            // Элементы управления картой
            Positioned(
              top: 16,
              right: 16,
              child: Column(
                children: [
                  _buildMapControl(Icons.add, () => _zoomMap(1)),
                  const SizedBox(height: 8),
                  _buildMapControl(Icons.remove, () => _zoomMap(-1)),
                  const SizedBox(height: 8),
                  _buildMapControl(Icons.my_location, _centerMap),
                ],
              ),
            ),
            
            // Легенда
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Приоритет',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _legendRow(Colors.red, 'Высокий'),
                    const SizedBox(height: 4),
                    _legendRow(Colors.orange, 'Средний'),
                    const SizedBox(height: 4),
                    _legendRow(Colors.green, 'Низкий'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControl(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: const Color(0xFF0D47A1),
      ),
    );
  }

  Widget _legendRow(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, color: color, size: 16),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      );

  void _showRequestPopup(BuildContext context, CitizenRequestDto e) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getCategoryIcon(e.categoryId),
              color: const Color(0xFF0D47A1),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text('Обращение № ${e.requestNumber}')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _infoRow('Категория', _getCategoryText(e.categoryId)),
              _infoRow('Приоритет', e.aiPriority ?? 'Не определен'),
              _infoRow('Статус', _getStatusName(e.requestStatusId)),
              _infoRow('Адрес', e.incidentLocation),
              const Divider(height: 24),
              const Text(
                'Описание:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(e.description),
              const SizedBox(height: 12),
              _infoRow('Создано', _formatDate(e.createdAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Закрыть'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/requests/${e.id}');
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Подробнее'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                '$label:',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'Admin':
        return 'Администратор';
      case 'Manager':
        return 'Руководитель';
      case 'Operator':
        return 'Оператор';
      default:
        return role;
    }
  }

  String _getStatusName(int? statusId) {
    if (statusId == null) return '—';
    switch (statusId) {
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

  String _getCategoryText(int id) {
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
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
