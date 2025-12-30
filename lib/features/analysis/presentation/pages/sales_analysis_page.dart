import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:annex_sales_order/features/analysis/data/analysis_service.dart';
import 'package:annex_sales_order/features/user/data/datasources/user_local_data_source.dart';
import 'package:annex_sales_order/core/widgets/app_drawer.dart';
import 'package:annex_sales_order/features/analysis/presentation/widgets/analysis_summary_cards.dart';
import 'package:annex_sales_order/features/analysis/presentation/widgets/analysis_glass_card.dart';
import 'package:annex_sales_order/features/analysis/presentation/widgets/analysis_pie_chart.dart';
import 'package:annex_sales_order/features/analysis/presentation/widgets/analysis_bar_chart.dart';
import 'package:annex_sales_order/features/analysis/presentation/widgets/analysis_customer_table.dart';

class SalesAnalysisPage extends StatefulWidget {
  const SalesAnalysisPage({super.key});

  @override
  State<SalesAnalysisPage> createState() => _SalesAnalysisPageState();
}

class _SalesAnalysisPageState extends State<SalesAnalysisPage> {
  late Future<AnalysisMetrics> _metricsFuture;
  String? _selectedCustomer;
  Future<AnalysisMetrics>? _customerDetailFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  String? _currentDebugRep;

  void _refreshData({bool force = false}) {
    _currentDebugRep = UserLocalDataSource().getUser()?.fullName;

    setState(() {
      _metricsFuture = AnalysisService.getMetrics(forceRefresh: force);
      if (_selectedCustomer != null) {
        _customerDetailFuture = AnalysisService.getMetrics(
          customerName: _selectedCustomer,
          forceRefresh: force,
        );
      }
    });
  }

  void _onCustomerSelected(String customerName) {
    setState(() {
      _selectedCustomer = customerName;
      _customerDetailFuture = AnalysisService.getMetrics(
        customerName: customerName,
      );
    });
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
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/logo.png', width: 100),
                    SizedBox(height: 20),
                    CircularProgressIndicator(),
                  ],
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        size: 60,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'حدث خطأ أثناء تحميل البيانات:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _refreshData(force: true),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.totalOrders == 0) {
              return _buildEmptyState(snapshot.data);
            }

            final metrics = snapshot.data!;

            return RefreshIndicator(
              onRefresh: () async {
                _refreshData(force: true);
                await _metricsFuture;
              },
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverAppBar(
                    leading: Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(CupertinoIcons.list_dash),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        tooltip: 'Menu',
                      ),
                    ),
                    expandedHeight: 120,
                    floating: true,
                    pinned: true,
                    title: const Text(
                      'تحليل المبيعات',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    centerTitle: true,
                    actions: [
                      IconButton(
                        icon: const Icon(CupertinoIcons.refresh),
                        onPressed: () => _refreshData(force: true),
                        tooltip: 'تحديث البيانات',
                      ),
                    ],
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
                    bottom: const TabBar(
                      tabs: [
                        Tab(text: 'إحصائياتي '),
                        Tab(text: 'إحصائيات العملاء'),
                      ],
                      indicatorColor: Colors.white,
                      indicatorWeight: 4,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white30,
                      ),
                      unselectedLabelStyle: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
                body: TabBarView(
                  children: [
                    _buildRepTab(metrics, theme, isDark),
                    _buildCustomerTab(metrics, theme, isDark),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(AnalysisMetrics? metrics) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.graph_square, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'لا توجد بيانات كافية للتحليل حالياً',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          if (metrics != null) ...[
            const SizedBox(height: 20),
            Text(
              'Debug Info Raw: S:${metrics.rawGeneralCount}, Y:${metrics.rawYarnCount}, F:${metrics.rawFabricCount}',
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
            Text(
              'Filtered: ${metrics.totalOrders} | User:$_currentDebugRep',
              style: const TextStyle(fontSize: 10, color: Colors.red),
            ),
          ],
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              AnalysisService.clearCache();
              _refreshData(force: true);
            },
            child: const Text('تفريغ الكاش وتحديث'),
          ),
        ],
      ),
    );
  }

  Widget _buildRepTab(AnalysisMetrics metrics, ThemeData theme, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useHorizontalLayout = constraints.maxWidth > 900;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnalysisSummaryCards(metrics: metrics, constraints: constraints),
              const SizedBox(height: 30),
              if (useHorizontalLayout)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AnalysisGlassCard(
                        title: 'توزيع القيمة حسب النوع',
                        isDark: isDark,
                        child: AnalysisPieChart(
                          metrics: metrics,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: AnalysisGlassCard(
                        title: 'عدد الفواتير ',
                        isDark: isDark,
                        child: AnalysisBarChart(
                          metrics: metrics,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    AnalysisGlassCard(
                      title: 'توزيع القيمة حسب النوع',
                      isDark: isDark,
                      child: AnalysisPieChart(metrics: metrics, isDark: isDark),
                    ),
                    const SizedBox(height: 20),
                    AnalysisGlassCard(
                      title: 'عدد الفواتير ',
                      isDark: isDark,
                      child: AnalysisBarChart(metrics: metrics, isDark: isDark),
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
    AnalysisMetrics metrics,
    ThemeData theme,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useHorizontalLayout = constraints.maxWidth > 900;

        if (_selectedCustomer != null) {
          return FutureBuilder<AnalysisMetrics>(
            future: _customerDetailFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/logo.png', width: 100),
                      SizedBox(height: 20),
                      CircularProgressIndicator(),
                    ],
                  ),
                );
              }
              final custMetrics = snapshot.data!;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ActionChip(
                          avatar: const Icon(
                            CupertinoIcons.arrow_right,
                            size: 16,
                          ),
                          label: const Text('كل العملاء'),
                          onPressed: () =>
                              setState(() => _selectedCustomer = null),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedCustomer!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AnalysisSummaryCards(
                      metrics: custMetrics,
                      constraints: constraints,
                    ),
                    const SizedBox(height: 30),
                    if (useHorizontalLayout)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AnalysisGlassCard(
                              title: 'توزيع القيمة حسب النوع',
                              isDark: isDark,
                              child: AnalysisPieChart(
                                metrics: custMetrics,
                                isDark: isDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: AnalysisGlassCard(
                              title: 'عدد الفواتير ',
                              isDark: isDark,
                              child: AnalysisBarChart(
                                metrics: custMetrics,
                                isDark: isDark,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          AnalysisGlassCard(
                            title: 'توزيع القيمة حسب النوع',
                            isDark: isDark,
                            child: AnalysisPieChart(
                              metrics: custMetrics,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(height: 20),
                          AnalysisGlassCard(
                            title: 'عدد الفواتير ',
                            isDark: isDark,
                            child: AnalysisBarChart(
                              metrics: custMetrics,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          );
        }

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (useHorizontalLayout)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AnalysisGlassCard(
                        title: 'أعلى 10 عملاء شراءً (بالقيمة)',
                        isDark: isDark,
                        child: AnalysisCustomerTable(
                          data: metrics.salesByCustomer,
                          valueLabel: 'القيمة',
                          isDark: isDark,
                          onSelect: _onCustomerSelected,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: AnalysisGlassCard(
                        title: 'أعلى 10 عملاء (بعدد الفواتير)',
                        isDark: isDark,
                        child: AnalysisCustomerTable(
                          data: metrics.ordersByCustomer.map(
                            (k, v) => MapEntry(k, v.toDouble()),
                          ),
                          valueLabel: 'العدد',
                          isDark: isDark,
                          onSelect: _onCustomerSelected,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    AnalysisGlassCard(
                      title: 'أعلى 10 عملاء شراءً (بالقيمة)',
                      isDark: isDark,
                      child: AnalysisCustomerTable(
                        data: metrics.salesByCustomer,
                        valueLabel: 'القيمة',
                        isDark: isDark,
                        onSelect: _onCustomerSelected,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnalysisGlassCard(
                      title: 'أعلى 10 عملاء (بعدد الفواتير)',
                      isDark: isDark,
                      child: AnalysisCustomerTable(
                        data: metrics.ordersByCustomer.map(
                          (k, v) => MapEntry(k, v.toDouble()),
                        ),
                        valueLabel: 'العدد',
                        isDark: isDark,
                        onSelect: _onCustomerSelected,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
