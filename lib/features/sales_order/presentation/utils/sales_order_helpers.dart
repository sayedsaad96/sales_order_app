import 'package:flutter/material.dart';
import '../../data/models/sales_order.dart';

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
  List<SalesOrderItem> items;
  List<ItemControllers> itemControllers;

  OrderSection({
    String category = '',
    List<SalesOrderItem>? items,
    List<ItemControllers>? itemControllers,
  }) : categoryController = TextEditingController(text: category),
       items = items ?? [],
       itemControllers = itemControllers ?? [];

  void dispose() {
    categoryController.dispose();
    for (var controller in itemControllers) {
      controller.dispose();
    }
  }
}
