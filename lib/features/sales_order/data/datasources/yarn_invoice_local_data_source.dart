import 'package:hive_flutter/hive_flutter.dart';
import 'package:annex_sales_order/features/sales_order/data/models/yarn_sales_order.dart';

class YarnInvoiceLocalDataSource {
  static const String _boxName = 'yarn_invoices';

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<YarnSalesOrder>(_boxName);
    }
  }

  Box<YarnSalesOrder> _getBox() {
    if (!Hive.isBoxOpen(_boxName)) {
      throw Exception('Yarn invoices box is not open');
    }
    return Hive.box<YarnSalesOrder>(_boxName);
  }

  Future<void> saveInvoice(YarnSalesOrder order) async {
    final box = _getBox();
    
    if (order.isInBox) {
      await order.save();
    } else {
      // Group invoices by customer name
      final customerName = order.customerName ?? 'Unknown';
      final key = '${customerName}_${order.sn}_${DateTime.now().millisecondsSinceEpoch}';
      
      await box.put(key, order);
    }
  }

  List<YarnSalesOrder> getAllInvoices() {
    try {
      if (!Hive.isBoxOpen(_boxName)) return [];
      final box = Hive.box<YarnSalesOrder>(_boxName);
      return box.values.toList();
    } catch (e) {
      return [];
    }
  }

  Map<String, List<YarnSalesOrder>> getInvoicesByCustomer() {
    final invoices = getAllInvoices();
    final Map<String, List<YarnSalesOrder>> grouped = {};
    
    for (var invoice in invoices) {
      final customerName = invoice.customerName ?? 'Unknown';
      grouped.putIfAbsent(customerName, () => []).add(invoice);
    }
    
    // Sort each customer's invoices by date (most recent first)
    grouped.forEach((key, value) {
      value.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    });
    
    return grouped;
  }

  Future<void> deleteInvoice(YarnSalesOrder order) async {
    if (order.isInBox) {
      await order.delete();
    }
  }

  Future<void> updateInvoice(YarnSalesOrder order) async {
    if (order.isInBox) {
      await order.save();
    }
  }
}
