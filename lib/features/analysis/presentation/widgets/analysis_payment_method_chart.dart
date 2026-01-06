import 'package:flutter/material.dart';

class AnalysisPaymentMethodChart extends StatelessWidget {
  final Map<String, int> paymentMethods;
  final bool isDark;

  const AnalysisPaymentMethodChart({
    super.key,
    required this.paymentMethods,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (paymentMethods.isEmpty) {
      return const Center(child: Text('لا توجد بيانات سداد'));
    }

    final totalOrders = paymentMethods.values.fold(0, (sum, count) => sum + count);
    final sortedMethods = paymentMethods.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: sortedMethods.map((entry) {
          final percentage = (entry.value / totalOrders * 100).toStringAsFixed(1);
          final progress = entry.value / totalOrders;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${entry.value} فاتورة ($percentage%)',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(_getColorForMethod(entry.key)),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getColorForMethod(String method) {
    if (method.contains('كاش')) return Colors.green;
    if (method.contains('بنكي')) return Colors.blue;
    if (method.contains('اجل')) return Colors.orange;
    return Colors.teal;
  }
}
