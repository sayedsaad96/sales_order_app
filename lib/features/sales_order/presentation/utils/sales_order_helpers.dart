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
