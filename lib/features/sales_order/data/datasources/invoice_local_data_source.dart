import 'package:hive_flutter/hive_flutter.dart';
import '../models/sales_order.dart';

class InvoiceLocalDataSource {
  static const String _boxName = 'invoicesBox';

  Future<void> init() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        await Hive.openBox<SalesOrder>(_boxName);
      }
    } catch (e) {
      throw Exception('Failed to initialize invoice storage: $e');
    }
  }

  Future<void> saveInvoice(SalesOrder invoice) async {
    try {
      final box = Hive.box<SalesOrder>(_boxName);
      if (invoice.isInBox) {
        await invoice.save();
      } else {
        await box.add(invoice);
      }
    } catch (e) {
      throw Exception('Failed to save invoice: $e');
    }
  }

  List<SalesOrder> getAllInvoices() {
    try {
      if (!Hive.isBoxOpen(_boxName)) return [];
      final box = Hive.box<SalesOrder>(_boxName);
      return box.values.toList();
    } catch (e) {
      // Return empty list on error to prevent crash
      return [];
    }
  }

  Future<void> deleteInvoice(SalesOrder invoice) async {
    try {
      if (invoice.isInBox) {
        await invoice.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete invoice: $e');
    }
  }
}
