import 'package:hive_flutter/hive_flutter.dart';
import 'package:annex_sales_order/features/sales_order/data/models/sales_order.dart';
import 'package:annex_sales_order/features/sales_order/data/models/yarn_sales_order.dart';
import 'package:annex_sales_order/features/sales_order/data/models/fabrics_cm_sales_order.dart';
import 'package:annex_sales_order/features/return_order/data/models/return_order.dart';
import 'package:flutter/foundation.dart';

class AnalysisMetrics {
  final Map<String, double> salesByRep;
  final Map<String, int> ordersByRep;
  final Map<String, double> salesByCustomer;
  final Map<String, int> ordersByCustomer;
  
  // Breakdown by type
  final Map<String, double> generalSalesByRep;
  final Map<String, double> yarnSalesByRep;
  final Map<String, double> fabricSalesByRep;
  final Map<String, int> generalOrdersByRep;
  final Map<String, int> yarnOrdersByRep;
  final Map<String, int> fabricOrdersByRep;

  // Time-based aggregation (Key: "yyyy-MM-dd")
  final Map<String, int> generalOrdersByDate;
  final Map<String, int> yarnOrdersByDate;
  final Map<String, int> fabricOrdersByDate;

  final double totalSalesValue;
  final double totalGeneralSales;
  final double totalYarnSales;
  final double totalFabricSales;
  final int totalOrders;
  final int totalGeneralOrders;
  final int totalYarnOrders;
  final int totalFabricOrders;
  final int totalReturns;

  // Raw counts (unfiltered)
  final int rawGeneralCount;
  final int rawYarnCount;
  final int rawFabricCount;

  final Map<String, int> ordersByPaymentMethod;
  final Map<String, int> customerOrdersByPaymentMethod; // Inner map: {Customer: {Method: Count}} -> Simplified storage

  AnalysisMetrics({
    required this.salesByRep,
    required this.ordersByRep,
    required this.salesByCustomer,
    required this.ordersByCustomer,
    required this.generalSalesByRep,
    required this.yarnSalesByRep,
    required this.fabricSalesByRep,
    required this.generalOrdersByRep,
    required this.yarnOrdersByRep,
    required this.fabricOrdersByRep,
    required this.generalOrdersByDate,
    required this.yarnOrdersByDate,
    required this.fabricOrdersByDate,
    required this.totalSalesValue,
    required this.totalGeneralSales,
    required this.totalYarnSales,
    required this.totalFabricSales,
    required this.totalOrders,
    required this.totalGeneralOrders,
    required this.totalYarnOrders,
    required this.totalFabricOrders,
    required this.totalReturns,
    required this.rawGeneralCount,
    required this.rawYarnCount,
    required this.rawFabricCount,
    required this.ordersByPaymentMethod,
    required this.customerOrdersByPaymentMethod,
  });

  Map<String, int> getPaymentMethodsForCustomer(String customerName) {
    final result = <String, int>{};
    final prefix = '$customerName|';
    for (var entry in customerOrdersByPaymentMethod.entries) {
      if (entry.key.startsWith(prefix)) {
        final method = entry.key.substring(prefix.length);
        result[method] = entry.value;
      }
    }
    return result;
  }
}

class AnalysisData {
  final List<SalesOrder> sales;
  final List<YarnSalesOrder> yarnSales;
  final List<FabricsCmSalesOrder> fabricSales;
  final List<ReturnOrder> returns;
  final String? salesRepFilter;
  final String? customerFilter;

  AnalysisData({
    required this.sales,
    required this.yarnSales,
    required this.fabricSales,
    required this.returns,
    this.salesRepFilter,
    this.customerFilter,
  });
}


class AnalysisService {
  static final _cache = <String, AnalysisMetrics>{};
  static final _lastCounts = <String, String>{};

  static String _formatDate(DateTime date) => 
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  static String _normalizePaymentMethod(String? method) {
    if (method == null) return 'غير محدد';
    
    final trimmed = method.trim();
    if (trimmed.isEmpty) return 'غير محدد';

    final mapping = {
      // English to Arabic mapping
      'Cash': 'كاش',
      'Bank transfer': 'كاش',
      'Credit': 'اجل شهر',
      'Cheque': 'كاش',
      'Other': 'كاش',
      'تحويل بنكي': 'كاش',
      
      // Short Arabic to Full Arabic mapping
      'شهر': 'اجل شهر',
      'اسبوعين': 'اجل اسبوعين',
      '3 اسابيع': 'اجل 3 اسابيع',
      'شهرين': 'اجل شهرين',
      '3 شهور': 'اجل 3 شهور',

      // Fix trailing space versions
      'اجل اسبوعين ': 'اجل اسبوعين',
      'اجل 3 اسابيع ': 'اجل 3 اسابيع',
    };

    return mapping[trimmed] ?? trimmed;
  }

  static Future<AnalysisMetrics> getMetrics({
    String? salesRepName, 
    String? customerName,
    bool forceRefresh = false
  }) async {
    const salesBoxName = 'invoicesBox';
    const yarnBoxName = 'yarn_invoices';
    const fabricBoxName = 'fabrics_cm_orders';
    const returnsBoxName = 'return_orders';

    if (!Hive.isBoxOpen(salesBoxName)) await Hive.openBox<SalesOrder>(salesBoxName);
    if (!Hive.isBoxOpen(yarnBoxName)) await Hive.openBox<YarnSalesOrder>(yarnBoxName);
    if (!Hive.isBoxOpen(fabricBoxName)) {
      await Hive.openBox<FabricsCmSalesOrder>(fabricBoxName);
    }
    if (!Hive.isBoxOpen(returnsBoxName)) await Hive.openBox<ReturnOrder>(returnsBoxName);

    final salesBox = Hive.box<SalesOrder>(salesBoxName);
    final yarnBox = Hive.box<YarnSalesOrder>(yarnBoxName);
    final fabricBox = Hive.box<FabricsCmSalesOrder>(fabricBoxName);
    final returnsBox = Hive.box<ReturnOrder>(returnsBoxName);

    // Better cache key including specific filters
    final cacheKey = 'rep_${salesRepName ?? 'all'}_cust_${customerName ?? 'all'}';
    
    // Improved current state key (using lengths and checksum if possible, but lengths are a good start)
    final currentStateKey =
        '${salesBox.length}-${yarnBox.length}-${fabricBox.length}-${returnsBox.length}';

    if (!forceRefresh &&
        _cache.containsKey(cacheKey) &&
        _lastCounts[cacheKey] == currentStateKey) {
      return _cache[cacheKey]!;
    }

    final data = AnalysisData(
      sales: salesBox.values.toList(),
      yarnSales: yarnBox.values.toList(),
      fabricSales: fabricBox.values.toList(),
      returns: returnsBox.values.toList(),
      salesRepFilter: salesRepName,
      customerFilter: customerName,
    );

    final metrics = _processMetrics(data);
    
    debugPrint('AnalysisService: Computed metrics. Total Orders: ${metrics.totalOrders}');
    debugPrint('AnalysisService: Rep Filter: ${salesRepName ?? 'NONE'}');
    debugPrint('AnalysisService: Cust Filter: ${customerName ?? 'NONE'}');
    debugPrint('AnalysisService: Box lengths - Sales: ${salesBox.length}, Yarn: ${yarnBox.length}, Fabric: ${fabricBox.length}');

    _cache[cacheKey] = metrics;
    _lastCounts[cacheKey] = currentStateKey;

    return metrics;
  }

  static AnalysisMetrics _processMetrics(AnalysisData data) {
    final salesByRep = <String, double>{};
    final ordersByRep = <String, int>{};
    final salesByCustomer = <String, double>{};
    final ordersByCustomer = <String, int>{};

    final generalSalesByRep = <String, double>{};
    final yarnSalesByRep = <String, double>{};
    final fabricSalesByRep = <String, double>{};
    final generalOrdersByRep = <String, int>{};
    final yarnOrdersByRep = <String, int>{};
    final fabricOrdersByRep = <String, int>{};

    final generalOrdersByDate = <String, int>{};
    final yarnOrdersByDate = <String, int>{};
    final fabricOrdersByDate = <String, int>{};

    double totalSalesValue = 0;
    double totalGeneralSales = 0;
    double totalYarnSales = 0;
    double totalFabricSales = 0;
    int totalOrders = 0;
    int totalGeneralOrders = 0;
    int totalYarnOrders = 0;
    int totalFabricOrders = 0;
    int totalReturns = 0;

    final ordersByPaymentMethod = <String, int>{};
    final customerOrdersByPaymentMethod = <String, int>{}; // We'll store as "Customer|Method" for simplicity or similar
    // Actually, a better way for the model is to have a structured way or just filter when needed.
    // Given the request is "analysis in each customer", storing as "Customer|Method" count is okay.

    final salesRepName = data.salesRepFilter;
    final customerName = data.customerFilter;

    // Process General Sales
    debugPrint('AnalysisService: Processing ${data.sales.length} general sales');
    for (var order in data.sales) {
      final rep = order.salesResponsible ?? 'غير محدد';
      if (salesRepName != null && rep.trim().toLowerCase() != salesRepName.trim().toLowerCase()) {
        continue;
      }

      final customer = order.customerName ?? 'عميل غير معروف';
      if (customerName != null && customer.trim().toLowerCase() != customerName.trim().toLowerCase()) {
        continue;
      }
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

      final method = _normalizePaymentMethod(order.paymentMethod);
      ordersByPaymentMethod[method] = (ordersByPaymentMethod[method] ?? 0) + 1;
      final custMethodKey = '$customer|$method';
      customerOrdersByPaymentMethod[custMethodKey] = (customerOrdersByPaymentMethod[custMethodKey] ?? 0) + 1;
    }

    // Process Yarn Sales
    debugPrint('AnalysisService: Processing ${data.yarnSales.length} yarn sales');
    for (var order in data.yarnSales) {
      final rep = order.salesResponsible ?? 'غير محدد';
      if (salesRepName != null && rep.trim().toLowerCase() != salesRepName.trim().toLowerCase()) {
        continue;
      }

      final customer = order.customerName ?? 'عميل غير معروف';
      if (customerName != null && customer.trim().toLowerCase() != customerName.trim().toLowerCase()) {
        continue;
      }
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

      final method = _normalizePaymentMethod(order.paymentMethod);
      ordersByPaymentMethod[method] = (ordersByPaymentMethod[method] ?? 0) + 1;
      final custMethodKey = '$customer|$method';
      customerOrdersByPaymentMethod[custMethodKey] = (customerOrdersByPaymentMethod[custMethodKey] ?? 0) + 1;
    }

    // Process Fabric Sales
    debugPrint('AnalysisService: Processing ${data.fabricSales.length} fabric sales');
    for (var order in data.fabricSales) {
      final rep = order.salesResponsible ?? 'غير محدد';
      if (salesRepName != null && rep.trim().toLowerCase() != salesRepName.trim().toLowerCase()) {
        continue;
      }

      final customer = order.customerName ?? 'عميل غير معروف';
      if (customerName != null && customer.trim().toLowerCase() != customerName.trim().toLowerCase()) {
        continue;
      }
      final val = order.totalValue;
      final dateKey = _formatDate(order.orderDate);

      salesByRep[rep] = (salesByRep[rep] ?? 0) + val;
      ordersByRep[rep] = (ordersByRep[rep] ?? 0) + 1;

      fabricSalesByRep[rep] = (fabricSalesByRep[rep] ?? 0) + val;
      fabricOrdersByRep[rep] = (fabricOrdersByRep[rep] ?? 0) + 1;

      fabricOrdersByDate[dateKey] = (fabricOrdersByDate[dateKey] ?? 0) + 1;

      salesByCustomer[customer] = (salesByCustomer[customer] ?? 0) + val;
      ordersByCustomer[customer] = (ordersByCustomer[customer] ?? 0) + 1;

      totalSalesValue += val;
      totalFabricSales += val;
      totalOrders++;
      totalFabricOrders++;

      final method = _normalizePaymentMethod(order.paymentMethod);
      ordersByPaymentMethod[method] = (ordersByPaymentMethod[method] ?? 0) + 1;
      final custMethodKey = '$customer|$method';
      customerOrdersByPaymentMethod[custMethodKey] = (customerOrdersByPaymentMethod[custMethodKey] ?? 0) + 1;
    }

    // Process Returns
    debugPrint('AnalysisService: Processing ${data.returns.length} returns');
    for (var ret in data.returns) {
      final rep = ret.returnResponsible ?? 'غير محدد';
      if (salesRepName != null && rep.trim().toLowerCase() != salesRepName.trim().toLowerCase()) {
        continue;
      }
      
      final customer = ret.customerName ?? 'عميل غير معروف';
      if (customerName != null && customer.trim().toLowerCase() != customerName.trim().toLowerCase()) {
        continue;
      }

      totalReturns++;
    }

    return AnalysisMetrics(
      salesByRep: salesByRep,
      ordersByRep: ordersByRep,
      salesByCustomer: salesByCustomer,
      ordersByCustomer: ordersByCustomer,
      generalSalesByRep: generalSalesByRep,
      yarnSalesByRep: yarnSalesByRep,
      fabricSalesByRep: fabricSalesByRep,
      generalOrdersByRep: generalOrdersByRep,
      yarnOrdersByRep: yarnOrdersByRep,
      fabricOrdersByRep: fabricOrdersByRep,
      generalOrdersByDate: generalOrdersByDate,
      yarnOrdersByDate: yarnOrdersByDate,
      fabricOrdersByDate: fabricOrdersByDate,
      totalSalesValue: totalSalesValue,
      totalGeneralSales: totalGeneralSales,
      totalYarnSales: totalYarnSales,
      totalFabricSales: totalFabricSales,
      totalOrders: totalOrders,
      totalGeneralOrders: totalGeneralOrders,
      totalYarnOrders: totalYarnOrders,
      totalFabricOrders: totalFabricOrders,
      totalReturns: totalReturns,
      rawGeneralCount: data.sales.length,
      rawYarnCount: data.yarnSales.length,
      rawFabricCount: data.fabricSales.length,
      ordersByPaymentMethod: ordersByPaymentMethod,
      customerOrdersByPaymentMethod: customerOrdersByPaymentMethod,
    );
  }

  static void clearCache() {
    _cache.clear();
    _lastCounts.clear();
  }
}
