import 'package:flutter/material.dart';

class AnalysisCustomerTable extends StatelessWidget {
  final Map<String, double> data;
  final String valueLabel;
  final bool isDark;
  final Function(String)? onSelect;

  const AnalysisCustomerTable({
    super.key,
    required this.data,
    required this.valueLabel,
    required this.isDark,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
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
              : Colors.black.withValues(alpha: 0.05),
        ),
        itemBuilder: (context, index) {
          final entry = top10[index];
          return ListTile(
            onTap: onSelect != null ? () => onSelect!(entry.key) : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: _buildRankBadge(index + 1),
            title: Text(
              entry.key,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: _buildValueColumn(entry.value),
          );
        },
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$rank',
          style: const TextStyle(
            color: Colors.teal,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildValueColumn(double value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value.toStringAsFixed(0),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.teal,
          ),
        ),
        Text(
          valueLabel,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
