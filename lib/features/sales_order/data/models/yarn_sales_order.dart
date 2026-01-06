import 'package:hive/hive.dart';

part 'yarn_sales_order.g.dart';

@HiveType(typeId: 3)
class YarnSalesOrder extends HiveObject {
  @HiveField(0)
  String? sn;
  @HiveField(1)
  String? branch;
  @HiveField(2)
  String deliveryResponsibility;
  @HiveField(3)
  String? customerName;
  @HiveField(4)
  String? region;
  @HiveField(5)
  DateTime? deliveryDate;
  @HiveField(6)
  DateTime orderDate;
  @HiveField(7)
  String? deliveryPlace;
  @HiveField(8)
  String? editQuantity;
  @HiveField(18)
  String? contactName;
  @HiveField(19, defaultValue: false)
  bool specifiedQuantity;
  @HiveField(11)
  String? paymentMethod;
  @HiveField(12)
  String? salesResponsible;
  @HiveField(13, defaultValue: [])
  List<YarnSalesOrderItem> items;
  @HiveField(14, defaultValue: [])
  List<YarnInstallment> installments;
  @HiveField(15)
  String? notes;
  @HiveField(16, defaultValue: [])
  List<String> orderTypes;
  @HiveField(17)
  String? mobileNumber;

  YarnSalesOrder({
    this.sn,
    this.branch,
    this.deliveryResponsibility = 'العميل',
    this.customerName,
    this.contactName,
    this.region,
    this.deliveryDate,
    required this.orderDate,
    this.deliveryPlace,
    this.editQuantity,
    this.mobileNumber,
    this.specifiedQuantity = false,
    this.paymentMethod,
    this.salesResponsible,
    this.items = const [],
    this.installments = const [],
    this.notes,
    this.orderTypes = const [],
  });

  Map<String, dynamic> toJson() => {
    'sn': sn,
    'branch': branch,
    'deliveryResponsibility': deliveryResponsibility,
    'customerName': customerName,
    'contactName': contactName,
    'region': region,
    'deliveryDate': deliveryDate?.toIso8601String(),
    'orderDate': orderDate.toIso8601String(),
    'deliveryPlace': deliveryPlace,
    'editQuantity': editQuantity,
    'mobileNumber': mobileNumber,
    'specifiedQuantity': specifiedQuantity,
    'paymentMethod': paymentMethod,
    'salesResponsible': salesResponsible,
    'items': items.map((e) => e.toJson()).toList(),
    'installments': installments.map((e) => e.toJson()).toList(),
    'notes': notes,
    'orderTypes': orderTypes,
  };

  factory YarnSalesOrder.fromJson(Map<String, dynamic> json) => YarnSalesOrder(
    sn: json['sn'],
    branch: json['branch'],
    deliveryResponsibility: json['deliveryResponsibility'] ?? 'العميل',
    customerName: json['customerName'],
    contactName: json['contactName'],
    region: json['region'],
    deliveryDate: json['deliveryDate'] != null ? DateTime.parse(json['deliveryDate']) : null,
    orderDate: DateTime.parse(json['orderDate']),
    deliveryPlace: json['deliveryPlace'],
    editQuantity: json['editQuantity'],
    mobileNumber: json['mobileNumber'],
    specifiedQuantity: json['specifiedQuantity'] ?? false,
    paymentMethod: json['paymentMethod'],
    salesResponsible: json['salesResponsible'],
    items: (json['items'] as List?)?.map((e) => YarnSalesOrderItem.fromJson(e)).toList() ?? [],
    installments: (json['installments'] as List?)?.map((e) => YarnInstallment.fromJson(e)).toList() ?? [],
    notes: json['notes'],
    orderTypes: List<String>.from(json['orderTypes'] ?? []),
  );

  double get totalValue => items.fold(0, (sum, item) => sum + item.value);
}

@HiveType(typeId: 4)
class YarnSalesOrderItem extends HiveObject {
  @HiveField(0)
  String description;
  @HiveField(1)
  double quantity;
  @HiveField(2)
  String unit;
  @HiveField(3)
  double price;

  YarnSalesOrderItem({
    this.description = '',
    this.quantity = 0.0,
    this.unit = 'KG',
    this.price = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'description': description,
    'quantity': quantity,
    'unit': unit,
    'price': price,
  };

  factory YarnSalesOrderItem.fromJson(Map<String, dynamic> json) => YarnSalesOrderItem(
    description: json['description'] ?? '',
    quantity: (json['quantity'] as num).toDouble(),
    unit: json['unit'] ?? 'KG',
    price: (json['price'] as num).toDouble(),
  );

  double get value => quantity * price;
}

@HiveType(typeId: 5)
class YarnInstallment extends HiveObject {
  @HiveField(0)
  String duration;
  @HiveField(1)
  String value;

  YarnInstallment({
    this.duration = '',
    this.value = '',
  });

  Map<String, dynamic> toJson() => {
    'duration': duration,
    'value': value,
  };

  factory YarnInstallment.fromJson(Map<String, dynamic> json) => YarnInstallment(
    duration: json['duration'] ?? '',
    value: json['value'] ?? '',
  );
}
