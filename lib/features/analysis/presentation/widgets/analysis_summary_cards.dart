import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:annex_sales_order/features/analysis/data/analysis_service.dart';

class AnalysisSummaryCards extends StatelessWidget {
  final AnalysisMetrics metrics;
  final BoxConstraints constraints;

  const AnalysisSummaryCards({
    super.key,
    required this.metrics,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final int crossAxisCount = constraints.maxWidth > 1000
        ? 3
        : (constraints.maxWidth > 500 ? 2 : 1);

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: constraints.maxWidth > 1200
            ? 3.0
            : (constraints.maxWidth > 800
                  ? 2.5
                  : (constraints.maxWidth > 500 ? 2.5 : 2.0)),
      ),
      children: [
        _AnalysisStatCard(
          title: 'إجمالي المبيعات',
          value: metrics.totalSalesValue.toStringAsFixed(0),
          icon: CupertinoIcons.money_dollar_circle,
          colors: const [Color(0xFF00B4DB), Color(0xFF0083B0)],
          constraints: constraints,
          index: 0,
          subtitle:
              'مستلزمات: ${metrics.totalGeneralSales.toStringAsFixed(0)} | غزل: ${metrics.totalYarnSales.toStringAsFixed(0)} | قماش: ${metrics.totalFabricSales.toStringAsFixed(0)}',
        ),
        _AnalysisStatCard(
          title: 'عدد الطلبات',
          value: metrics.totalOrders.toString(),
          icon: CupertinoIcons.doc_plaintext,
          colors: const [Color(0xFF6dd5ed), Color(0xFF2193b0)],
          constraints: constraints,
          index: 1,
          subtitle:
              'مستلزمات: ${metrics.totalGeneralOrders} | غزل: ${metrics.totalYarnOrders} | قماش: ${metrics.totalFabricOrders}',
        ),
        _AnalysisStatCard(
          title: 'المرتجعات',
          value: metrics.totalReturns.toString(),
          icon: CupertinoIcons.arrow_2_squarepath,
          colors: const [Color(0xFFff9966), Color(0xFFff5e62)],
          constraints: constraints,
          index: 2,
        ),
      ],
    );
  }
}

class _AnalysisStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> colors;
  final BoxConstraints constraints;
  final int index;
  final String? subtitle;

  const _AnalysisStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.colors,
    required this.constraints,
    required this.index,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, anim, child) {
        return Transform.scale(
          scale: anim,
          child: Opacity(
            opacity: anim.clamp(0.0, 1.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: constraints.maxWidth > 600 ? 13 : 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            value,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: constraints.maxWidth > 600 ? 20 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              subtitle!,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    icon,
                    color: Colors.white24,
                    size: constraints.maxWidth > 600
                        ? (subtitle != null ? 35 : 40)
                        : 30,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
