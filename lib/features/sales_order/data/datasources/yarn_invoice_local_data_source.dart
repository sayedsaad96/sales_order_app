import 'package:hive_flutter/hive_flutter.dart';
import '../models/yarn_sales_order.dart';

class YarnInvoiceLocalDataSource {
  static const String _boxName = 'yarn_invoices';
  Box<YarnSalesOrder>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<YarnSalesOrder>(_boxName);
  }

  Future<void> saveInvoice(YarnSalesOrder order) async {
    if (_box == null) await init();
    
    // Group invoices by customer name
    final customerName = order.customerName ?? 'Unknown';
    final key = '${customerName}_${order.sn}_${DateTime.now().millisecondsSinceEpoch}';
    
    await _box!.put(key, order);
  }

  List<YarnSalesOrder> getAllInvoices() {
    if (_box == null) return [];
    return _box!.values.toList();
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
    if (_box == null) await init();
    await order.delete();
  }

  Future<void> updateInvoice(YarnSalesOrder order) async {
    if (_box == null) await init();
    await order.save();
  }
}
