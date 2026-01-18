import 'package:flutter/material.dart';
import 'package:annex_sales_order/features/sales_order/data/models/sales_order.dart';

class ItemControllers {
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController unitController;
  final TextEditingController priceController;

  ItemControllers({
    String name = '',
    String quantity = '',
    String unit = '',
    String price = '',
  }) : nameController = TextEditingController(text: name),
       quantityController = TextEditingController(text: quantity),
       unitController = TextEditingController(text: unit),
       priceController = TextEditingController(text: price);

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    unitController.dispose();
    priceController.dispose();
  }
}

class OrderSection {
  TextEditingController categoryController;
  TextEditingController defaultUnitController;
  List<SalesOrderItem> items;
  List<ItemControllers> itemControllers;

  OrderSection({
    String category = '',
    String defaultUnit = '',
    List<SalesOrderItem>? items,
    List<ItemControllers>? itemControllers,
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

