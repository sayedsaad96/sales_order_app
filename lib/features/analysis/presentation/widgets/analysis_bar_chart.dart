import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../data/analysis_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final metrics = widget.metrics;
    final isDark = widget.isDark;

    // Determine chart data based on toggle and grouping
    final Map<String, int> dailyGeneral = metrics.generalOrdersByDate;
    final Map<String, int> dailyYarn = metrics.yarnOrdersByDate;

    // Get all unique dates and sort them
    final allDates = {...dailyGeneral.keys, ...dailyYarn.keys}.toList()..sort();

    Map<String, int> chartGeneral = {};
    Map<String, int> chartYarn = {};

    if (_isMonthlyBarChart) {
      // Group by month (yyyy-MM)
      for (var date in allDates) {
        final monthKey = date.length >= 7 ? date.substring(0, 7) : date;
        chartGeneral[monthKey] = (chartGeneral[monthKey] ?? 0) + (dailyGeneral[date] ?? 0);
        chartYarn[monthKey] = (chartYarn[monthKey] ?? 0) + (dailyYarn[date] ?? 0);
      }
    } else {
      // Display daily
      for (var date in allDates) {
        chartGeneral[date] = dailyGeneral[date] ?? 0;
        chartYarn[date] = dailyYarn[date] ?? 0;
      }
      
      // Optimization: Limit to last 15 days
      if (allDates.length > 15) {
        final recentDates = allDates.sublist(allDates.length - 15);
        final filteredGeneral = <String, int>{};
        final filteredYarn = <String, int>{};
        for (var d in recentDates) {
          filteredGeneral[d] = chartGeneral[d] ?? 0;
          filteredYarn[d] = chartYarn[d] ?? 0;
        }
        chartGeneral = filteredGeneral;
        chartYarn = filteredYarn;
      }
    }

    final chartKeys = chartGeneral.keys.toList()..sort();
    final labelColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);

    double maxVal = chartKeys.isEmpty
        ? 10.0
        : [
            ...chartGeneral.values,
            ...chartYarn.values
          ].reduce((a, b) => a > b ? a : b).toDouble() + 2;

    return SizedBox(
      height: 300,
      child: Column(
        children: [
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal,
                barGroups: chartKeys.asMap().entries.map((e) {
                  final key = e.value;
                  final generalCount = chartGeneral[key] ?? 0;
                  final yarnCount = chartYarn[key] ?? 0;

                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: generalCount.toDouble(),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 12,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: yarnCount.toDouble(),
                        gradient: const LinearGradient(
                          colors: [Colors.tealAccent, Colors.teal],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 12,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
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
                      getTitlesWidget: (val, meta) {
                        if (val.toInt() >= chartKeys.length) return const SizedBox();
                        final key = chartKeys[val.toInt()];
                        final displayKey = _isMonthlyBarChart 
                            ? key 
                            : (key.length >= 5 ? key.substring(key.length - 5) : key);

                        return Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(
                            displayKey,
                            style: TextStyle(fontSize: 10, color: labelColor),
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
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final type = rodIndex == 0 ? "مستلزمات" : "غزل";
                      return BarTooltipItem(
                        "${chartKeys[groupIndex]}\n$type: ${rod.toY.toInt()}",
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
                    onChanged: (v) => setState(() => _isMonthlyBarChart = v),
                    activeTrackColor: Colors.teal.withValues(alpha: 0.5),
                    activeThumbColor: Colors.teal,
                  ),
                ],
              ),
              const Row(
                children: [
                  _LegendItem(label: 'فواتير مستلزمات', color: Color(0xFF00B4DB)),
                  SizedBox(width: 20),
                  _LegendItem(label: 'فواتير غزل', color: Colors.teal),
                ],
              ),
            ],
          ),
        ],
      ),
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
