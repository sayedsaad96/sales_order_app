import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:annex_sales_order/features/analysis/data/analysis_service.dart';

class AnalysisPieChart extends StatelessWidget {
  final AnalysisMetrics metrics;
  final bool isDark;

  const AnalysisPieChart({
    super.key,
    required this.metrics,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasGeneral = metrics.totalGeneralSales > 0;
    final hasYarn = metrics.totalYarnSales > 0;
    final hasFabric = metrics.totalFabricSales > 0;

    final sections = <PieChartSectionData>[];

    if (hasGeneral) {
      sections.add(
        PieChartSectionData(
          value: metrics.totalGeneralSales,
          title:
              '${(metrics.totalGeneralSales / metrics.totalSalesValue * 100).toStringAsFixed(1)}%',
          color: const Color(0xFF00B4DB),
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (hasYarn) {
      sections.add(
        PieChartSectionData(
          value: metrics.totalYarnSales,
          title:
              '${(metrics.totalYarnSales / metrics.totalSalesValue * 100).toStringAsFixed(1)}%',
          color: Colors.teal,
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (hasFabric) {
      sections.add(
        PieChartSectionData(
          value: metrics.totalFabricSales,
          title:
              '${(metrics.totalFabricSales / metrics.totalSalesValue * 100).toStringAsFixed(1)}%',
          color: Colors.deepPurpleAccent,
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return SizedBox(
      height: 380,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 50,
                    sectionsSpace: 3,
                  ),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOutBack,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'الإجمالي',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      metrics.totalSalesValue.toStringAsFixed(0),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildMiniStat(
                    'مستلزمات',
                    metrics.totalGeneralSales.toStringAsFixed(0),
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildMiniStat(
                    'غزل',
                    metrics.totalYarnSales.toStringAsFixed(0),
                    Colors.teal,
                  ),
                ),
                Expanded(
                  child: _buildMiniStat(
                    'قماش',
                    metrics.totalFabricSales.toStringAsFixed(0),
                    Colors.deepPurpleAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 12,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              _LegendItem(label: 'مستلزمات', color: Color(0xFF00B4DB)),
              _LegendItem(label: 'غزل', color: Colors.teal),
              _LegendItem(label: 'قماش', color: Colors.deepPurpleAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
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
