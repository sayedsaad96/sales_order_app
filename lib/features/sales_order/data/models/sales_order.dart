import 'package:hive/hive.dart';

part 'sales_order.g.dart';

@HiveType(typeId: 1)
class SalesOrder extends HiveObject {
  @HiveField(0)
  String? sn;
  @HiveField(1)
  String? branch;
  @HiveField(2)
  List<String> orderTypes;
  @HiveField(3)
  String? customerName;
  @HiveField(4)
  String? region;
  @HiveField(5)
  bool deliveryIncluded;
  @HiveField(6)
  DateTime? deliveryDate;
  @HiveField(7)
  DateTime orderDate;
  @HiveField(8)
  String? salesResponsible;
  @HiveField(9)
  String? paymentMethod;
  @HiveField(10)
  String? deliveryPlace;
  @HiveField(11)
  List<SalesOrderItem> items;
  @HiveField(12)
  String? category;
  @HiveField(13)
  String? notes;

  SalesOrder({
    this.sn,
    this.branch,
    this.orderTypes = const [],
    this.customerName,
    this.region,
    this.deliveryIncluded = false,
    this.deliveryDate,
    required this.orderDate,
    this.salesResponsible,
    this.paymentMethod,
    this.deliveryPlace,
    this.items = const [],
    this.category,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'sn': sn,
    'branch': branch,
    'orderTypes': orderTypes,
    'customerName': customerName,
    'region': region,
    'deliveryIncluded': deliveryIncluded,
    'deliveryDate': deliveryDate?.toIso8601String(),
    'orderDate': orderDate.toIso8601String(),
    'salesResponsible': salesResponsible,
    'paymentMethod': paymentMethod,
    'deliveryPlace': deliveryPlace,
    'items': items.map((e) => e.toJson()).toList(),
    'category': category,
    'notes': notes,
  };

  factory SalesOrder.fromJson(Map<String, dynamic> json) => SalesOrder(
    sn: json['sn'],
    branch: json['branch'],
    orderTypes: List<String>.from(json['orderTypes'] ?? []),
    customerName: json['customerName'],
    region: json['region'],
    deliveryIncluded: json['deliveryIncluded'] ?? false,
    deliveryDate: json['deliveryDate'] != null ? DateTime.parse(json['deliveryDate']) : null,
    orderDate: DateTime.parse(json['orderDate']),
    salesResponsible: json['salesResponsible'],
    paymentMethod: json['paymentMethod'],
    deliveryPlace: json['deliveryPlace'],
    items: (json['items'] as List?)?.map((e) => SalesOrderItem.fromJson(e)).toList() ?? [],
    category: json['category'],
    notes: json['notes'],
  );

  double get totalValue => items.fold(0, (sum, item) => sum + item.value);

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
}

@HiveType(typeId: 2)
class SalesOrderItem extends HiveObject {
  @HiveField(0)
  String itemName;
  @HiveField(1)
  int quantity;
  @HiveField(2)
  String unit;
  @HiveField(3)
  double price;

  @HiveField(4)
  String? category;

  SalesOrderItem({
    this.itemName = '',
    this.quantity = 0,
    this.unit = '',
    this.price = 0.0,
    this.category,
  });

  Map<String, dynamic> toJson() => {
    'itemName': itemName,
    'quantity': quantity,
    'unit': unit,
    'price': price,
    'category': category,
  };

  factory SalesOrderItem.fromJson(Map<String, dynamic> json) => SalesOrderItem(
    itemName: json['itemName'] ?? '',
    quantity: json['quantity'] ?? 0,
    unit: json['unit'] ?? '',
    price: (json['price'] ?? 0.0).toDouble(),
    category: json['category'],
  );

  double get value => quantity * price;
}
