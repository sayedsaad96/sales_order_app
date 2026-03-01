
import 'package:hive/hive.dart';

part 'fabrics_cm_sales_order.g.dart';

@HiveType(typeId: 8)
class FabricsCmSalesOrder extends HiveObject {
  @HiveField(0)
  String? sn;
  @HiveField(1)
  String? customerName;
  @HiveField(2)
  String? salesResponsible;
  @HiveField(3)
  String? paymentMethod;
  @HiveField(4)
  DateTime? deliveryDate;
  @HiveField(5)
  String? orderType; // Fabrics only, CM only, Fabrics + CM
  @HiveField(6)
  List<FabricsCmLineItem> items;
  @HiveField(7)
  DateTime orderDate;
  @HiveField(8)
  String? notes;
  @HiveField(9)
  String? branch;
  @HiveField(10)
  List<String> orderTypesList; // Replaces orderType string logically

  FabricsCmSalesOrder({
    this.sn,
    this.customerName,
    this.salesResponsible,
    this.paymentMethod,
    this.deliveryDate,
    this.orderType,
    this.items = const [],
    required this.orderDate,
    this.notes,
    this.branch,
    this.orderTypesList = const [],
  });

  Map<String, dynamic> toJson() => {
    'sn': sn,
    'customerName': customerName,
    'salesResponsible': salesResponsible,
    'paymentMethod': paymentMethod,
    'deliveryDate': deliveryDate?.toIso8601String(),
    'orderType': orderType,
    'items': items.map((e) => e.toJson()).toList(),
    'orderDate': orderDate.toIso8601String(),
    'notes': notes,
    'branch': branch,
    'orderTypesList': orderTypesList,
  };

  factory FabricsCmSalesOrder.fromJson(Map<String, dynamic> json) => FabricsCmSalesOrder(
    sn: json['sn'],
    customerName: json['customerName'],
    salesResponsible: json['salesResponsible'],
    paymentMethod: json['paymentMethod'],
    deliveryDate: json['deliveryDate'] != null ? DateTime.parse(json['deliveryDate']) : null,
    orderType: json['orderType'],
    items: (json['items'] as List?)?.map((e) => FabricsCmLineItem.fromJson(e)).toList() ?? [],
    orderDate: DateTime.parse(json['orderDate']),
    notes: json['notes'],
    branch: json['branch'],
    orderTypesList: List<String>.from(json['orderTypesList'] ?? []),
  );

  double get totalValue {
    return items.fold(0.0, (sum, item) => sum + item.calculateTotal());
  }
}

@HiveType(typeId: 9)
class FabricsCmLineItem extends HiveObject {
  @HiveField(0)
  double quantity;

  // New Fields
  @HiveField(1)
  String? fabricDetails; // Replaces detailed specs
  @HiveField(10)
  double? price;

  // Kept Fields
  @HiveField(11)
  String? spinningCompany;

  @HiveField(7)
  dynamic gauge;
  @HiveField(8)
  dynamic inch;
  @HiveField(9)
  dynamic stitchLength;

  FabricsCmLineItem({
    this.quantity = 0.0,
    this.fabricDetails,
    this.price = 0.0,
    this.spinningCompany,
    this.gauge,
    this.inch,
    this.stitchLength,
  });

  Map<String, dynamic> toJson() => {
    'quantity': quantity,
    'fabricDetails': fabricDetails,
    'price': price,
    'spinningCompany': spinningCompany,
    'gauge': gauge,
    'inch': inch,
    'stitchLength': stitchLength,
  };

  factory FabricsCmLineItem.fromJson(Map<String, dynamic> json) => FabricsCmLineItem(
    quantity: (json['quantity'] as num).toDouble(),
    fabricDetails: json['fabricDetails'],
    price: (json['price'] as num?)?.toDouble(),
    spinningCompany: json['spinningCompany'],
    gauge: json['gauge'],
    inch: json['inch'],
    stitchLength: json['stitchLength'],
  );

  double calculateTotal() {
    return quantity * (price ?? 0.0);
  }
}
