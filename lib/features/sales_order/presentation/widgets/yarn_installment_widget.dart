import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class YarnInstallmentWidget extends StatelessWidget {
  final List<TextEditingController> durationControllers;
  final List<TextEditingController> valueControllers;
  final bool isMobile;
  final VoidCallback onAddInstallment;
  final void Function(int) onRemoveInstallment;

  const YarnInstallmentWidget({
    super.key,
    required this.durationControllers,
    required this.valueControllers,
    required this.isMobile,
    required this.onAddInstallment,
    required this.onRemoveInstallment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'طريقة السداد في حالة تعدد الدفعات',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        ...List.generate(durationControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    'القيمة ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: durationControllers[index],
                    decoration: const InputDecoration(
                      labelText: 'المدة',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: valueControllers[index],
                    decoration: const InputDecoration(
                      labelText: 'القيمة',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                if (durationControllers.length > 1)
                  IconButton(
                    icon: const Icon(CupertinoIcons.delete, color: Colors.red, size: 20),
                    onPressed: () => onRemoveInstallment(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: onAddInstallment,
            icon: const Icon(CupertinoIcons.add),
            label: const Text('إضافة دفعة'),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    final int halfLength = (durationControllers.length / 2).ceil();

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column
            Expanded(
              child: Column(
                children: List.generate(halfLength, (index) {
                  return _buildInstallmentRow(index);
                }),
              ),
            ),
            const SizedBox(width: 16),
            // Right column
            Expanded(
              child: Column(
                children: List.generate(
                  durationControllers.length - halfLength,
                  (index) {
                    return _buildInstallmentRow(index + halfLength);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: onAddInstallment,
            icon: const Icon(CupertinoIcons.add),
            label: const Text('إضافة دفعة'),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
          ),
        ),
      ],
    );
  }

  Widget _buildInstallmentRow(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              'القيمة ${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: valueControllers[index],
              decoration: const InputDecoration(
                labelText: 'المدة',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: durationControllers[index],
              decoration: const InputDecoration(
                labelText: 'القيمة',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (durationControllers.length > 1)
            IconButton(
              icon: const Icon(CupertinoIcons.delete, color: Colors.red, size: 18),
              onPressed: () => onRemoveInstallment(index),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
