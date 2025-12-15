import 'package:hive_flutter/hive_flutter.dart';
import '../models/return_order.dart';

class ReturnOrderLocalDataSource {
  static const String boxName = 'return_orders';

  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<ReturnOrder>(boxName);
    }
  }

  Future<void> saveReturnOrder(ReturnOrder returnOrder) async {
    final box = Hive.box<ReturnOrder>(boxName);
    if (returnOrder.isInBox) {
      await returnOrder.save();
    } else {
      await box.add(returnOrder);
    }
  }

  List<ReturnOrder> getReturnOrders() {
    final box = Hive.box<ReturnOrder>(boxName);
    return box.values.toList().cast<ReturnOrder>();
  }

  Future<void> deleteReturnOrder(ReturnOrder returnOrder) async {
    if (returnOrder.isInBox) {
      await returnOrder.delete();
    }
  }

  Future<void> deleteReturnOrderAtIndex(int index) async {
    final box = Hive.box<ReturnOrder>(boxName);
    await box.deleteAt(index);
  }
}
