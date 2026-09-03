import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:annex_sales_order/features/analysis/data/analysis_service.dart';

class AnalysisBarChart extends StatefulWidget {
  final AnalysisMetrics metrics;
  final bool isDark;

  const AnalysisBarChart({
    super.key,
    required this.metrics,
    required this.isDark,
  });

  @override
  State<AnalysisBarChart> createState() => _AnalysisBarChartState();
}

class _AnalysisBarChartState extends State<AnalysisBarChart> {
  bool _isMonthlyBarChart = false;
  late List<String> _allDates;
  late Map<String, int> _chartGeneral;
  late Map<String, int> _chartYarn;
  late Map<String, int> _chartFabric;
  late List<String> _chartKeys;
  late double _maxVal;

  @override
  void initState() {
    super.initState();
    _processData();
  }

  @override
  void didUpdateWidget(AnalysisBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.metrics != widget.metrics) {
      _processData();
    }
  }

  void _processData() {
    final metrics = widget.metrics;
    final dailyGeneral = metrics.generalOrdersByDate;
    final dailyYarn = metrics.yarnOrdersByDate;
    final dailyFabric = metrics.fabricOrdersByDate;

    _allDates = {
      ...dailyGeneral.keys,
      ...dailyYarn.keys,
      ...dailyFabric.keys,
    }.toList()
      ..sort();

    _chartGeneral = {};
    _chartYarn = {};
    _chartFabric = {};

    if (_isMonthlyBarChart) {
      for (var date in _allDates) {
        final monthKey = date.length >= 7 ? date.substring(0, 7) : date;
        _chartGeneral[monthKey] =
            (_chartGeneral[monthKey] ?? 0) + (dailyGeneral[date] ?? 0);
        _chartYarn[monthKey] =
            (_chartYarn[monthKey] ?? 0) + (dailyYarn[date] ?? 0);
        _chartFabric[monthKey] =
            (_chartFabric[monthKey] ?? 0) + (dailyFabric[date] ?? 0);
      }
    } else {
      for (var date in _allDates) {
        _chartGeneral[date] = dailyGeneral[date] ?? 0;
        _chartYarn[date] = dailyYarn[date] ?? 0;
        _chartFabric[date] = dailyFabric[date] ?? 0;
      }

      if (_allDates.length > 12) {
        final recentDates = _allDates.sublist(_allDates.length - 12);
        final filteredGeneral = <String, int>{};
        final filteredYarn = <String, int>{};
        final filteredFabric = <String, int>{};
        for (var d in recentDates) {
          filteredGeneral[d] = _chartGeneral[d] ?? 0;
          filteredYarn[d] = _chartYarn[d] ?? 0;
          filteredFabric[d] = _chartFabric[d] ?? 0;
        }
        _chartGeneral = filteredGeneral;
        _chartYarn = filteredYarn;
        _chartFabric = filteredFabric;
      }
    }

    _chartKeys = _chartGeneral.keys.toList()..sort();

    _maxVal = _chartKeys.isEmpty
        ? 10.0
        : [
              ..._chartGeneral.values,
              ..._chartYarn.values,
              ..._chartFabric.values,
            ].reduce((a, b) => a > b ? a : b).toDouble() +
            2;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final labelColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);

    return SizedBox(
      height: 350,
      child: Column(
        children: [
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _maxVal,
                barGroups: _chartKeys.asMap().entries.map((e) {
                  final key = e.value;
                  final generalCount = _chartGeneral[key] ?? 0;
                  final yarnCount = _chartYarn[key] ?? 0;
                  final fabricCount = _chartFabric[key] ?? 0;

                  return BarChartGroupData(
                    x: e.key,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: generalCount.toDouble(),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 6,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                      BarChartRodData(
                        toY: yarnCount.toDouble(),
                        gradient: const LinearGradient(
                          colors: [Colors.tealAccent, Colors.teal],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 6,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                      BarChartRodData(
                        toY: fabricCount.toDouble(),
                        gradient: const LinearGradient(
                          colors: [Colors.purpleAccent, Colors.deepPurple],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 6,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 1,
                      getTitlesWidget: (val, meta) {
                        if (val.toInt() >= _chartKeys.length) {
                          return const SizedBox();
                        }
                        final key = _chartKeys[val.toInt()];
                        final displayKey = _isMonthlyBarChart
                            ? key
                            : (key.length >= 5
                                  ? key.substring(key.length - 5)
                                  : key);

                        return SideTitleWidget(
                          meta: meta,
                          space: 10,
                          angle: _isMonthlyBarChart ? 0 : 0.5,
                          child: Text(
                            displayKey,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: labelColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (val, meta) => Text(
                        val.toInt().toString(),
                        style: TextStyle(fontSize: 10, color: labelColor),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: gridColor, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(

                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String type;
                      if (rodIndex == 0) {
                        type = "مستلزمات";
                      } else if (rodIndex == 1) {
                        type = "غزل";
                      } else {
                        type = "قماش";
                      }
                      return BarTooltipItem(
                        "${_chartKeys[groupIndex]}\n$type: ${rod.toY.toInt()}",
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutQuart,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 450;
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'عرض شهري',
                            style: TextStyle(fontSize: 12, color: labelColor),
                          ),
                          Switch.adaptive(
                            value: _isMonthlyBarChart,
                            onChanged: (v) {
                                setState(() {
                                  _isMonthlyBarChart = v;
                                  _processData();
                                });
                              },
                            activeTrackColor: Colors.teal.withValues(
                              alpha: 0.5,
                            ),
                            activeThumbColor: Colors.teal,
                          ),
                        ],
                      ),
                      if (!isSmall) _buildLegend(isSmall),
                    ],
                  ),
                  if (isSmall) const SizedBox(height: 8),
                  if (isSmall) _buildLegend(isSmall),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(bool isSmall) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      alignment: isSmall ? WrapAlignment.center : WrapAlignment.end,
      children: const [
        _LegendItem(label: 'فواتير مستلزمات', color: Color(0xFF00B4DB)),
        _LegendItem(label: 'فواتير غزل', color: Colors.teal),
        _LegendItem(label: 'فواتير قماش', color: Colors.deepPurple),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
