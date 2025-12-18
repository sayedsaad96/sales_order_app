import 'package:hive_flutter/hive_flutter.dart';
import '../../sales_order/data/models/sales_order.dart';
import '../../sales_order/data/models/yarn_sales_order.dart';
import '../../return_order/data/models/return_order.dart';

class AnalysisMetrics {
  final Map<String, double> salesByRep;
  final Map<String, int> ordersByRep;
  final Map<String, double> salesByCustomer;
  final Map<String, int> ordersByCustomer;
  final double totalSalesValue;
  final int totalOrders;
  final int totalReturns;

  AnalysisMetrics({
    required this.salesByRep,
    required this.ordersByRep,
    required this.salesByCustomer,
    required this.ordersByCustomer,
    required this.totalSalesValue,
    required this.totalOrders,
    required this.totalReturns,
  });
}

class AnalysisService {
  static Future<AnalysisMetrics> getMetrics() async {
    const salesBoxName = 'invoicesBox';
    const yarnBoxName = 'yarn_invoices';
    const returnsBoxName = 'return_orders';

    if (!Hive.isBoxOpen(salesBoxName)) await Hive.openBox<SalesOrder>(salesBoxName);
    if (!Hive.isBoxOpen(yarnBoxName)) await Hive.openBox<YarnSalesOrder>(yarnBoxName);
    if (!Hive.isBoxOpen(returnsBoxName)) await Hive.openBox<ReturnOrder>(returnsBoxName);

    final salesBox = Hive.box<SalesOrder>(salesBoxName);
    final yarnBox = Hive.box<YarnSalesOrder>(yarnBoxName);
    final returnsBox = Hive.box<ReturnOrder>(returnsBoxName);

    final salesByRep = <String, double>{};
    final ordersByRep = <String, int>{};
    final salesByCustomer = <String, double>{};
    final ordersByCustomer = <String, int>{};
    double totalSalesValue = 0;
    int totalOrders = 0;

    // Process General Sales
    for (var order in salesBox.values) {
      final rep = order.salesResponsible ?? 'غير محدد';
      final customer = order.customerName ?? 'عميل غير معروف';
      final val = order.totalValue;

      salesByRep[rep] = (salesByRep[rep] ?? 0) + val;
      ordersByRep[rep] = (ordersByRep[rep] ?? 0) + 1;
      salesByCustomer[customer] = (salesByCustomer[customer] ?? 0) + val;
      ordersByCustomer[customer] = (ordersByCustomer[customer] ?? 0) + 1;
      totalSalesValue += val;
      totalOrders++;
    }

    // Process Yarn Sales
    for (var order in yarnBox.values) {
      final rep = order.salesResponsible ?? 'غير محدد';
      final customer = order.customerName ?? 'عميل غير معروف';
      final val = order.totalValue;

      salesByRep[rep] = (salesByRep[rep] ?? 0) + val;
      ordersByRep[rep] = (ordersByRep[rep] ?? 0) + 1;
      salesByCustomer[customer] = (salesByCustomer[customer] ?? 0) + val;
      ordersByCustomer[customer] = (ordersByCustomer[customer] ?? 0) + 1;
      totalSalesValue += val;
      totalOrders++;
    }

    return AnalysisMetrics(
      salesByRep: salesByRep,
      ordersByRep: ordersByRep,
      salesByCustomer: salesByCustomer,
      ordersByCustomer: ordersByCustomer,
      totalSalesValue: totalSalesValue,
      totalOrders: totalOrders,
      totalReturns: returnsBox.length,
    );
  }
}
