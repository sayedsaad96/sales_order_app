import 'package:hive_flutter/hive_flutter.dart';
import '../../sales_order/data/models/sales_order.dart';
import '../../sales_order/data/models/yarn_sales_order.dart';
import '../../return_order/data/models/return_order.dart';

class AnalysisMetrics {
  final Map<String, double> salesByRep;
  final Map<String, int> ordersByRep;
  final Map<String, double> salesByCustomer;
  final Map<String, int> ordersByCustomer;
  
  // Breakdown by type
  final Map<String, double> generalSalesByRep;
  final Map<String, double> yarnSalesByRep;
  final Map<String, int> generalOrdersByRep;
  final Map<String, int> yarnOrdersByRep;

  // Time-based aggregation (Key: "yyyy-MM-dd")
  final Map<String, int> generalOrdersByDate;
  final Map<String, int> yarnOrdersByDate;

  final double totalSalesValue;
  final double totalGeneralSales;
  final double totalYarnSales;
  final int totalOrders;
  final int totalGeneralOrders;
  final int totalYarnOrders;
  final int totalReturns;

  AnalysisMetrics({
    required this.salesByRep,
    required this.ordersByRep,
    required this.salesByCustomer,
    required this.ordersByCustomer,
    required this.generalSalesByRep,
    required this.yarnSalesByRep,
    required this.generalOrdersByRep,
    required this.yarnOrdersByRep,
    required this.generalOrdersByDate,
    required this.yarnOrdersByDate,
    required this.totalSalesValue,
    required this.totalGeneralSales,
    required this.totalYarnSales,
    required this.totalOrders,
    required this.totalGeneralOrders,
    required this.totalYarnOrders,
    required this.totalReturns,
  });
}

class AnalysisService {
  static final _cache = <String, AnalysisMetrics>{};
  static final _lastCounts = <String, String>{};

  static String _formatDate(DateTime date) => 
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  static Future<AnalysisMetrics> getMetrics({
    String? salesRepName, 
    String? customerName,
    bool forceRefresh = false
  }) async {
    const salesBoxName = 'invoicesBox';
    const yarnBoxName = 'yarn_invoices';
    const returnsBoxName = 'return_orders';

    if (!Hive.isBoxOpen(salesBoxName)) await Hive.openBox<SalesOrder>(salesBoxName);
    if (!Hive.isBoxOpen(yarnBoxName)) await Hive.openBox<YarnSalesOrder>(yarnBoxName);
    if (!Hive.isBoxOpen(returnsBoxName)) await Hive.openBox<ReturnOrder>(returnsBoxName);

    final salesBox = Hive.box<SalesOrder>(salesBoxName);
    final yarnBox = Hive.box<YarnSalesOrder>(yarnBoxName);
    final returnsBox = Hive.box<ReturnOrder>(returnsBoxName);

    final currentCountsKey = '${salesBox.length}-${yarnBox.length}-${returnsBox.length}';
    final cacheKey = 'rep_${salesRepName ?? 'all'}_cust_${customerName ?? 'all'}';

    if (!forceRefresh && 
        _cache.containsKey(cacheKey) && 
        _lastCounts[cacheKey] == currentCountsKey) {
      return _cache[cacheKey]!;
    }

    final salesByRep = <String, double>{};
    final ordersByRep = <String, int>{};
    final salesByCustomer = <String, double>{};
    final ordersByCustomer = <String, int>{};

    final generalSalesByRep = <String, double>{};
    final yarnSalesByRep = <String, double>{};
    final generalOrdersByRep = <String, int>{};
    final yarnOrdersByRep = <String, int>{};

    final generalOrdersByDate = <String, int>{};
    final yarnOrdersByDate = <String, int>{};

    double totalSalesValue = 0;
    double totalGeneralSales = 0;
    double totalYarnSales = 0;
    int totalOrders = 0;
    int totalGeneralOrders = 0;
    int totalYarnOrders = 0;
    int totalReturns = 0;

    // Process General Sales
    for (var order in salesBox.values) {
      final rep = order.salesResponsible ?? 'غير محدد';
      if (salesRepName != null && rep != salesRepName) continue;

      final customer = order.customerName ?? 'عميل غير معروف';
      if (customerName != null && customer != customerName) continue;
      final val = order.totalValue;
      final dateKey = _formatDate(order.orderDate);

      salesByRep[rep] = (salesByRep[rep] ?? 0) + val;
      ordersByRep[rep] = (ordersByRep[rep] ?? 0) + 1;
      
      generalSalesByRep[rep] = (generalSalesByRep[rep] ?? 0) + val;
      generalOrdersByRep[rep] = (generalOrdersByRep[rep] ?? 0) + 1;

      generalOrdersByDate[dateKey] = (generalOrdersByDate[dateKey] ?? 0) + 1;

      salesByCustomer[customer] = (salesByCustomer[customer] ?? 0) + val;
      ordersByCustomer[customer] = (ordersByCustomer[customer] ?? 0) + 1;
      
      totalSalesValue += val;
      totalGeneralSales += val;
      totalOrders++;
      totalGeneralOrders++;
    }

    // Process Yarn Sales
    for (var order in yarnBox.values) {
      final rep = order.salesResponsible ?? 'غير محدد';
      if (salesRepName != null && rep != salesRepName) continue;

      final customer = order.customerName ?? 'عميل غير معروف';
      if (customerName != null && customer != customerName) continue;
      final val = order.totalValue;
      final dateKey = _formatDate(order.orderDate);

      salesByRep[rep] = (salesByRep[rep] ?? 0) + val;
      ordersByRep[rep] = (ordersByRep[rep] ?? 0) + 1;

      yarnSalesByRep[rep] = (yarnSalesByRep[rep] ?? 0) + val;
      yarnOrdersByRep[rep] = (yarnOrdersByRep[rep] ?? 0) + 1;

      yarnOrdersByDate[dateKey] = (yarnOrdersByDate[dateKey] ?? 0) + 1;

      salesByCustomer[customer] = (salesByCustomer[customer] ?? 0) + val;
      ordersByCustomer[customer] = (ordersByCustomer[customer] ?? 0) + 1;
      
      totalSalesValue += val;
      totalYarnSales += val;
      totalOrders++;
      totalYarnOrders++;
    }

    // Process Returns
    for (var ret in returnsBox.values) {
      final rep = ret.returnResponsible ?? 'غير محدد';
      if (salesRepName != null && rep != salesRepName) continue;
      
      final customer = ret.customerName ?? 'عميل غير معروف';
      if (customerName != null && customer != customerName) continue;

      totalReturns++;
    }

    final metrics = AnalysisMetrics(
      salesByRep: salesByRep,
      ordersByRep: ordersByRep,
      salesByCustomer: salesByCustomer,
      ordersByCustomer: ordersByCustomer,
      generalSalesByRep: generalSalesByRep,
      yarnSalesByRep: yarnSalesByRep,
      generalOrdersByRep: generalOrdersByRep,
      yarnOrdersByRep: yarnOrdersByRep,
      generalOrdersByDate: generalOrdersByDate,
      yarnOrdersByDate: yarnOrdersByDate,
      totalSalesValue: totalSalesValue,
      totalGeneralSales: totalGeneralSales,
      totalYarnSales: totalYarnSales,
      totalOrders: totalOrders,
      totalGeneralOrders: totalGeneralOrders,
      totalYarnOrders: totalYarnOrders,
      totalReturns: totalReturns,
    );

    _cache[cacheKey] = metrics;
    _lastCounts[cacheKey] = currentCountsKey;

    return metrics;
  }

  static void clearCache() {
    _cache.clear();
    _lastCounts.clear();
  }
}
