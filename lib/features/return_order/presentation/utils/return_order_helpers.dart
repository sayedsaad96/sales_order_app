import 'package:flutter/material.dart';
import '../../data/models/return_order.dart';

class ReturnItemControllers {
  final TextEditingController itemController;
  final TextEditingController quantityController;
  final TextEditingController unitController;

  ReturnItemControllers({
    String item = '',
    String quantity = '',
    String unit = '',
  }) : itemController = TextEditingController(text: item),
       quantityController = TextEditingController(text: quantity),
       unitController = TextEditingController(text: unit);

  void dispose() {
    itemController.dispose();
    quantityController.dispose();
    unitController.dispose();
  }
}

class ReturnOrderSection {
  TextEditingController categoryController;
  TextEditingController defaultUnitController;
  List<ReturnOrderItem> items;
  List<ReturnItemControllers> itemControllers;

  ReturnOrderSection({
    String category = '',
    String defaultUnit = '',
    List<ReturnOrderItem>? items,
    List<ReturnItemControllers>? itemControllers,
  }) : categoryController = TextEditingController(text: category),
       defaultUnitController = TextEditingController(text: defaultUnit),
       items = items ?? [],
       itemControllers = itemControllers ?? [];

  void dispose() {
    categoryController.dispose();
    defaultUnitController.dispose();
    for (var controller in itemControllers) {
      controller.dispose();
    }
  }
}

Future<int?> showBulkAddDialog(BuildContext context) async {
  final controller = TextEditingController(text: '5');
  return showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('إضافة أصناف متعددة', textAlign: TextAlign.right),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('أدخل عدد الأصناف التي تريد إضافتها:', textAlign: TextAlign.right),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            final count = int.tryParse(controller.text);
            if (count != null && count > 0) {
              Navigator.pop(context, count);
            }
          },
          child: const Text('إضافة'),
        ),
      ],
    ),
  );
}
