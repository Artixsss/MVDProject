import 'package:flutter/material.dart';
import '../widgets/home_action.dart';
import '../widgets/user_profile_action.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../services/api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _api = ApiService();
  List<Map<String, dynamic>> _categoryStats = const [];
  List<Map<String, dynamic>> _districtStats = const [];
  Map<String, dynamic>? _aiStats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait<dynamic>([
        _api.getCategoryStats(),
        _api.getDistrictStats(),
        _api.getAiStats(),
      ]);

      if (!mounted) return;

      setState(() {
        _categoryStats = results[0] as List<Map<String, dynamic>>;
        _districtStats = results[1] as List<Map<String, dynamic>>;
        _aiStats = results[2] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError('Ошибка загрузки: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Назад',
          ),
          title: const Text('Аналитика'),
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _load,
              tooltip: 'Обновить',
            ),
            const HomeAction(),
            const UserProfileAction(),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.analytics), text: 'Общая'),
              Tab(icon: Icon(Icons.category), text: 'Категории'),
              Tab(icon: Icon(Icons.location_city), text: 'Районы'),
              Tab(icon: Icon(Icons.auto_awesome), text: 'AI'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: TabBarView(
                  children: [
                    _buildOverallStats(),
                    _buildCategoryChart(),
                    _buildDistrictChart(),
                    _buildAiStats(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildOverallStats() {
    final totalRequests = _categoryStats.fold<int>(
      0,
      (sum, e) => sum + ((e['requestsCount'] ?? 0) as int),
    );
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // KPI карточки
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  'Всего обращений',
                  totalRequests.toString(),
                  Icons.inbox,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKpiCard(
                  'Категорий',
                  _categoryStats.length.toString(),
                  Icons.category,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKpiCard(
                  'Районов',
                  _districtStats.length.toString(),
                  Icons.location_city,
                  Colors.green,
                ),
              ),
              if (_aiStats != null) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKpiCard(
                    'Проанализировано ИИ',
                    '${(_aiStats!['coveragePercent'] ?? 0).toStringAsFixed(1)}%',
                    Icons.auto_awesome,
                    Colors.orange,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 32),

          // Круговая диаграмма категорий
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Распределение по категориям',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: _categoryStats.isEmpty
                        ? const Center(child: Text('Нет данных'))
                        : SfCircularChart(
                            legend: const Legend(
                              isVisible: true,
                              position: LegendPosition.bottom,
                              overflowMode: LegendItemOverflowMode.wrap,
                            ),
                            series: <PieSeries<ChartData, String>>[
                              PieSeries<ChartData, String>(
                                dataSource: _categoryStats
                                    .map((e) => ChartData(
                                          (e['categoryName'] ?? e['name']).toString(),
                                          (e['requestsCount'] ?? 0) as int,
                                        ))
                                    .toList(),
                                xValueMapper: (ChartData data, _) => data.category,
                                yValueMapper: (ChartData data, _) => data.count,
                                dataLabelSettings: const DataLabelSettings(isVisible: true),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Обращения по категориям',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 400,
                child: _categoryStats.isEmpty
                    ? const Center(child: Text('Нет данных'))
                    : SfCartesianChart(
                        primaryXAxis: CategoryAxis(
                          labelRotation: -45,
                          labelIntersectAction: AxisLabelIntersectAction.wrap,
                        ),
                        primaryYAxis: NumericAxis(
                          title: const AxisTitle(text: 'Количество обращений'),
                        ),
                        series: <CartesianSeries<ChartData, String>>[
                          BarSeries<ChartData, String>(
                            dataSource: _categoryStats
                                .map((e) => ChartData(
                                      (e['categoryName'] ?? e['name']).toString(),
                                      (e['requestsCount'] ?? 0) as int,
                                    ))
                                .toList(),
                            xValueMapper: (ChartData data, _) => data.category,
                            yValueMapper: (ChartData data, _) => data.count,
                            color: const Color(0xFF0D47A1),
                            dataLabelSettings: const DataLabelSettings(isVisible: true),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistrictChart() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Обращения по районам',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 400,
                    child: _districtStats.isEmpty
                        ? const Center(child: Text('Нет данных'))
                        : SfCartesianChart(
                            primaryXAxis: CategoryAxis(
                              labelRotation: -45,
                              labelIntersectAction: AxisLabelIntersectAction.wrap,
                            ),
                            primaryYAxis: NumericAxis(
                              title: const AxisTitle(text: 'Количество обращений'),
                            ),
                            series: <CartesianSeries<ChartData, String>>[
                              ColumnSeries<ChartData, String>(
                                dataSource: _districtStats
                                    .map((e) => ChartData(
                                          (e['districtName'] ?? e['name']).toString(),
                                          (e['requestsCount'] ?? 0) as int,
                                        ))
                                    .toList(),
                                xValueMapper: (ChartData data, _) => data.category,
                                yValueMapper: (ChartData data, _) => data.count,
                                color: Colors.green,
                                dataLabelSettings: const DataLabelSettings(isVisible: true),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Таблица районов
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Детализация по районам',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DataTable(
                    columns: const [
                      DataColumn(label: Text('Район')),
                      DataColumn(label: Text('Обращений')),
                      DataColumn(label: Text('Средний приоритет')),
                    ],
                    rows: _districtStats.map((e) {
                      final priority = (e['averageAiPriorityScore'] ?? 0.0) as double;
                      return DataRow(cells: [
                        DataCell(Text((e['districtName'] ?? e['name']).toString())),
                        DataCell(Text((e['requestsCount'] ?? 0).toString())),
                        DataCell(Text(priority.toStringAsFixed(2))),
                      ]);
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiStats() {
    if (_aiStats == null) {
      return const Center(child: Text('Данные не загружены'));
    }

    final stats = _aiStats!;
    final total = stats['totalRequests'] as int? ?? 0;
    final analyzed = stats['analyzedRequests'] as int? ?? 0;
    final corrected = stats['correctedRequests'] as int? ?? 0;
    final coverage = stats['analysisCoveragePercent'] as double? ?? 0.0;
    final correctionRate = stats['correctionRatePercent'] as double? ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildKpiCard(
                'Всего обращений',
                total.toString(),
                Icons.inbox,
                Colors.blue,
              ),
              _buildKpiCard(
                'Проанализировано',
                analyzed.toString(),
                Icons.auto_awesome,
                Colors.purple,
              ),
              _buildKpiCard(
                'Покрытие анализа',
                '${coverage.toStringAsFixed(1)}%',
                Icons.percent,
                Colors.green,
              ),
              _buildKpiCard(
                'Корректировок',
                corrected.toString(),
                Icons.edit,
                Colors.orange,
              ),
              _buildKpiCard(
                'Процент коррекций',
                '${correctionRate.toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Визуализация покрытия
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Покрытие AI-анализом',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: coverage / 100,
                    minHeight: 24,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      coverage >= 80 ? Colors.green : coverage >= 50 ? Colors.orange : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${analyzed} из ${total} обращений проанализировано',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Визуализация коррекций
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Точность AI (процент коррекций)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: correctionRate / 100,
                    minHeight: 24,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      correctionRate < 10 ? Colors.green : correctionRate < 30 ? Colors.orange : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${corrected} из ${analyzed} проанализированных обращений исправлено',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartData {
  final String category;
  final int count;
  ChartData(this.category, this.count);
}
