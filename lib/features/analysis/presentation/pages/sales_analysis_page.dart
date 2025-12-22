import 'package:flutter/material.dart';
import 'package:annex_sales_order/features/analysis/data/analysis_service.dart';
import 'package:annex_sales_order/features/user/data/datasources/user_local_data_source.dart';
import '../../../../core/widgets/app_drawer.dart';

import '../widgets/analysis_summary_cards.dart';
import '../widgets/analysis_glass_card.dart';
import '../widgets/analysis_pie_chart.dart';
import '../widgets/analysis_bar_chart.dart';
import '../widgets/analysis_customer_table.dart';

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

  void _refreshData({bool force = false}) {
    final user = UserLocalDataSource().getUser();
    setState(() {
      _metricsFuture = AnalysisService.getMetrics(
        salesRepName: user?.fullName,
        forceRefresh: force,
      );
      if (_selectedCustomer != null) {
        _customerDetailFuture = AnalysisService.getMetrics(
          salesRepName: user?.fullName,
          customerName: _selectedCustomer,
          forceRefresh: force,
        );
      }
    });
  }

  void _onCustomerSelected(String customerName) {
    final user = UserLocalDataSource().getUser();
    setState(() {
      _selectedCustomer = customerName;
      _customerDetailFuture = AnalysisService.getMetrics(
        salesRepName: user?.fullName,
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
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.totalOrders == 0) {
              return _buildEmptyState();
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
                        icon: const Icon(Icons.refresh),
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
                        Tab(text: 'إحصائيات المندوب'),
                        Tab(text: 'إحصائيات العملاء'),
                      ],
                      indicatorColor: Colors.white,
                      indicatorWeight: 4,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'لا توجد بيانات كافية للتحليل حالياً',
            style: TextStyle(fontSize: 18, color: Colors.grey),
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
                        child: AnalysisBarChart(metrics: metrics, isDark: isDark),
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
                        metrics: metrics,
                        isDark: isDark,
                      ),
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
                return const Center(child: CircularProgressIndicator());
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
                          avatar: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('كل العملاء'),
                          onPressed: () => setState(() => _selectedCustomer = null),
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
                    AnalysisSummaryCards(metrics: custMetrics, constraints: constraints),
                    const SizedBox(height: 30),
                    if (useHorizontalLayout)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AnalysisGlassCard(
                              title: 'توزيع القيمة حسب النوع',
                              isDark: isDark,
                              child: AnalysisPieChart(metrics: custMetrics, isDark: isDark),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: AnalysisGlassCard(
                              title: 'عدد الفواتير ',
                              isDark: isDark,
                              child: AnalysisBarChart(metrics: custMetrics, isDark: isDark),
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
                            child: AnalysisPieChart(metrics: custMetrics, isDark: isDark),
                          ),
                          const SizedBox(height: 20),
                          AnalysisGlassCard(
                            title: 'عدد الفواتير ',
                            isDark: isDark,
                            child: AnalysisBarChart(metrics: custMetrics, isDark: isDark),
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

