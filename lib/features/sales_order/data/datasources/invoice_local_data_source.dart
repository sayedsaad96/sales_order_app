import 'package:hive_flutter/hive_flutter.dart';
import '../models/sales_order.dart';

class InvoiceLocalDataSource {
  static const String _boxName = 'invoicesBox';

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<SalesOrder>(_boxName);
    }
  }

  Future<void> saveInvoice(SalesOrder invoice) async {
    final box = Hive.box<SalesOrder>(_boxName);
    if (invoice.isInBox) {
      await invoice.save();
    } else {
      await box.add(invoice);
    }
  }

  List<SalesOrder> getAllInvoices() {
    final box = Hive.box<SalesOrder>(_boxName);
    return box.values.toList();
  }

  Future<void> deleteInvoice(SalesOrder invoice) async {
    if (invoice.isInBox) {
      await invoice.delete();
    }
  }
}
