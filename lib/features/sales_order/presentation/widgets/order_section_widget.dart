import 'package:flutter/material.dart';
import '../utils/sales_order_helpers.dart'; // For OrderSection
import 'sales_order_item_row.dart';

class OrderSectionWidget extends StatelessWidget {
  final int sectionIndex;
  final OrderSection section;
  final bool isMobile;
  final bool showDeleteButton;
  final VoidCallback onRemoveSection;
  final VoidCallback onAddItem;
  final Function(int itemIndex) onRemoveItem;
  final VoidCallback onStateChanged;

  const OrderSectionWidget({
    super.key,
    required this.sectionIndex,
    required this.section,
    required this.isMobile,
    required this.showDeleteButton,
    required this.onRemoveSection,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isMobile
                    ? Expanded(
                        child: TextFormField(
                          controller: section.categoryController,
                          decoration: const InputDecoration(
                            labelText: 'التصنيف',
                          ),
                        ),
                      )
                    : SizedBox(
                        width: 250,
                        height: 50,
                        child: TextFormField(
                          controller: section.categoryController,
                          decoration: const InputDecoration(
                            labelText: 'التصنيف',
                          ),
                        ),
                      ),
                if (showDeleteButton)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onRemoveSection,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Header
                  if (!isMobile)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'الصنف',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'الكمية',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'الوحدة',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'السعر',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'القيمة',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 40), // For delete button
                        ],
                      ),
                    ),
                  // Rows
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: section.items.length,
                    itemBuilder: (context, index) {
                      final item = section.items[index];
                      final controllers = section.itemControllers[index];
                      return SalesOrderItemRow(
                        key: ObjectKey(item),
                        index: index,
                        item: item,
                        controllers: controllers,
                        isMobile: isMobile,
                        onDelete: () => onRemoveItem(index),
                        onStateChanged: onStateChanged,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onAddItem,
              icon: const Icon(Icons.add),
              label: const Text('إضافة صنف'),
            ),
          ],
        ),
      ),
    );
  }
}
