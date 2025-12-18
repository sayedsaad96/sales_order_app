import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:annex_sales_order/features/analysis/data/analysis_service.dart';
import '../../../../core/widgets/app_drawer.dart';
import 'dart:ui';

class SalesAnalysisPage extends StatefulWidget {
  const SalesAnalysisPage({super.key});

  @override
  State<SalesAnalysisPage> createState() => _SalesAnalysisPageState();
}

class _SalesAnalysisPageState extends State<SalesAnalysisPage> {
  late Future<AnalysisMetrics> _metricsFuture;

  @override
  void initState() {
    super.initState();
    _metricsFuture = AnalysisService.getMetrics();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: const AppDrawer(),
        body: FutureBuilder<AnalysisMetrics>(
          future: _metricsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.totalOrders == 0) {
              return _buildEmptyState();
            }

            final metrics = snapshot.data!;

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  expandedHeight: 120,
                  floating: true,
                  pinned: true,
                  title: const Text('تحليل المبيعات',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  centerTitle: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor,
                            theme.primaryColor.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                  bottom: TabBar(
                    tabs: const [
                      Tab(text: 'إحصائيات المندوب'),
                      Tab(text: 'إحصائيات العملاء'),
                    ],
                    indicatorColor: Colors.white,
                    indicatorWeight: 4,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    unselectedLabelStyle: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _buildRepTab(metrics, theme, isDark),
                  _buildCustomerTab(metrics, theme, isDark),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('لا توجد بيانات كافية للتحليل حالياً',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildRepTab(AnalysisMetrics metrics, ThemeData theme, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useHorizontalLayout = constraints.maxWidth > 900;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResponsiveSummaryCards(metrics, constraints),
              const SizedBox(height: 30),
              if (useHorizontalLayout)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildGlassCard(
                        title: 'توزيع القيمة حسب المندوب',
                        isDark: isDark,
                        child: _buildPieChart(metrics.salesByRep, theme, isDark),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildGlassCard(
                        title: 'عدد الفواتير لكل مندوب',
                        isDark: isDark,
                        child: _buildBarChart(metrics.ordersByRep, theme, isDark),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildGlassCard(
                      title: 'توزيع القيمة حسب المندوب',
                      isDark: isDark,
                      child: _buildPieChart(metrics.salesByRep, theme, isDark),
                    ),
                    const SizedBox(height: 20),
                    _buildGlassCard(
                      title: 'عدد الفواتير لكل مندوب',
                      isDark: isDark,
                      child: _buildBarChart(metrics.ordersByRep, theme, isDark),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomerTab(
      AnalysisMetrics metrics, ThemeData theme, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useHorizontalLayout = constraints.maxWidth > 900;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (useHorizontalLayout)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildGlassCard(
                        title: 'أعلى 10 عملاء شراءً (بالقيمة)',
                        isDark: isDark,
                        child: _buildCustomerTable(
                            metrics.salesByCustomer, theme, 'القيمة', isDark),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildGlassCard(
                        title: 'أعلى 10 عملاء (بعدد الفواتير)',
                        isDark: isDark,
                        child: _buildCustomerTable(
                            metrics.ordersByCustomer
                                .map((k, v) => MapEntry(k, v.toDouble())),
                            theme,
                            'العدد',
                            isDark),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildGlassCard(
                      title: 'أعلى 10 عملاء شراءً (بالقيمة)',
                      isDark: isDark,
                      child: _buildCustomerTable(
                          metrics.salesByCustomer, theme, 'القيمة', isDark),
                    ),
                    const SizedBox(height: 20),
                    _buildGlassCard(
                      title: 'أعلى 10 عملاء (بعدد الفواتير)',
                      isDark: isDark,
                      child: _buildCustomerTable(
                          metrics.ordersByCustomer
                              .map((k, v) => MapEntry(k, v.toDouble())),
                          theme,
                          'العدد',
                          isDark),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResponsiveSummaryCards(
      AnalysisMetrics metrics, BoxConstraints constraints) {
    final int crossAxisCount = constraints.maxWidth > 1000
        ? 3
        : (constraints.maxWidth > 600 ? 2 : 1);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: constraints.maxWidth > 600 ? 2.5 : 3.5,
      ),
      itemCount: 3,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildModernStatCard(
            'إجمالي المبيعات',
            metrics.totalSalesValue.toStringAsFixed(0),
            Icons.account_balance_wallet,
            [const Color(0xFF00B4DB), const Color(0xFF0083B0)],
          );
        } else if (index == 1) {
          return _buildModernStatCard(
            'عدد الطلبات',
            metrics.totalOrders.toString(),
            Icons.receipt_long,
            [const Color(0xFF6dd5ed), const Color(0xFF2193b0)],
          );
        } else {
          return _buildModernStatCard(
            'المرتجعات',
            metrics.totalReturns.toString(),
            Icons.keyboard_return,
            [const Color(0xFFff9966), const Color(0xFFff5e62)],
          );
        }
      },
    );
  }

  Widget _buildModernStatCard(
      String title, String value, IconData icon, List<Color> colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title,
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Icon(icon, color: Colors.white24, size: 40),
        ],
      ),
    );
  }

  Widget _buildGlassCard(
      {required String title, required Widget child, bool isDark = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal)),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> data, ThemeData theme, bool isDark) {
    final sections = data.entries.map((e) {
      final color = Colors.primaries[
          data.keys.toList().indexOf(e.key) % Colors.primaries.length];
      return PieChartSectionData(
        value: e.value,
        title:
            '${(e.value / data.values.fold(0.0, (s, v) => s + v) * 100).toStringAsFixed(1)}%',
        color: color,
        radius: 60,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return SizedBox(
      height: 300,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(PieChartData(
                    sections: sections, centerSpaceRadius: 50, sectionsSpace: 3)),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('الإجمالي',
                        style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 12)),
                    Text(data.values.fold(0.0, (s, v) => s + v).toStringAsFixed(0),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildLegend(data.keys.toList(), isDark),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> data, ThemeData theme, bool isDark) {
    final labelColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: data.values.isEmpty
              ? 10
              : data.values.reduce((a, b) => a > b ? a : b).toDouble() + 2,
          barGroups: data.entries.toList().asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value.toDouble(),
                  gradient: const LinearGradient(
                    colors: [Colors.tealAccent, Colors.teal],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 22,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: data.values.isEmpty
                        ? 10
                        : data.values.reduce((a, b) => a > b ? a : b).toDouble() +
                            2,
                    color: gridColor,
                  ),
                )
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) => Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(data.keys.elementAt(val.toInt()),
                      style: TextStyle(fontSize: 10, color: labelColor)),
                ),
              ),
            ),
            leftTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 5,
                    getTitlesWidget: (val, meta) => Text(
                          val.toInt().toString(),
                          style: TextStyle(fontSize: 10, color: labelColor),
                        ))),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: gridColor,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildCustomerTable(
      Map<String, double> data, ThemeData theme, String valueLabel, bool isDark) {
    final sortedList = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top10 = sortedList.take(10).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: top10.length,
        separatorBuilder: (context, index) => Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05)),
        itemBuilder: (context, index) {
          final entry = top10[index];
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('${index + 1}',
                    style: const TextStyle(
                        color: Colors.teal, fontWeight: FontWeight.bold)),
              ),
            ),
            title: Text(entry.key,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(entry.value.toStringAsFixed(0),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.teal)),
                Text(valueLabel,
                    style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegend(List<String> names, bool isDark) {
    final labelColor = isDark ? Colors.grey[400] : Colors.grey[600];
    return Wrap(
      spacing: 15,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: names.asMap().entries.map((e) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.primaries[e.key % Colors.primaries.length],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(e.value, style: TextStyle(fontSize: 11, color: labelColor)),
          ],
        );
      }).toList(),
    );
  }
}
