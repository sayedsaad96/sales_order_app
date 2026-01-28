
import 'package:hive_flutter/hive_flutter.dart';
import 'package:annex_sales_order/features/sales_order/data/models/fabrics_cm_sales_order.dart';

class FabricsCmInvoiceLocalDataSource {
  static const String _boxName = 'fabrics_cm_orders';

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<FabricsCmSalesOrder>(_boxName);
    }
  }

  Future<void> saveInvoice(FabricsCmSalesOrder order) async {
    final box = Hive.box<FabricsCmSalesOrder>(_boxName);
    if (order.isInBox) {
      await order.save();
    } else {
      await box.add(order);
    }
  }

  List<FabricsCmSalesOrder> getInvoices() {
    if (!Hive.isBoxOpen(_boxName)) return [];
    final box = Hive.box<FabricsCmSalesOrder>(_boxName);
    return box.values.toList();
  }

  bool isSnExists(String sn, {dynamic excludeKey}) {
    try {
      if (!Hive.isBoxOpen(_boxName)) return false;
      final box = Hive.box<FabricsCmSalesOrder>(_boxName);
      return box.values.any((order) => order.sn == sn && order.key != excludeKey);
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteInvoice(int index) async {
    final box = Hive.box<FabricsCmSalesOrder>(_boxName);
    await box.deleteAt(index);
  }
}
