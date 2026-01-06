import 'package:hive/hive.dart';

part 'return_order.g.dart';

@HiveType(typeId: 6)
class ReturnOrder extends HiveObject {
  @HiveField(0)
  String? sn;
  
  @HiveField(1)
  String? category; // 'غزل', 'مستلزمات', 'قماش'
  
  @HiveField(2)
  String? branch; // 'المحله', 'القاهرة'
  
  @HiveField(3)
  String? customerName;
  
  @HiveField(4)
  DateTime returnDate;
  
  @HiveField(5)
  String? region;
  
  @HiveField(6)
  String? returnResponsible;
  
  @HiveField(7)
  String deliveryCostPayer; // 'الشركة', 'العميل' (Checkbox logic: one boolean or string? String is safer for expanded options)
  
  @HiveField(8)
  String? routeFrom;
  
  @HiveField(9)
  String? routeTo;
  
  @HiveField(10)
  String? returnReason;
  
  @HiveField(11)
  DateTime? deliveryDate;
  
  @HiveField(12)
  List<ReturnOrderItem> items;

  @HiveField(13)
  String? notes;

  ReturnOrder({
    this.sn,
    this.category,
    this.branch,
    this.customerName,
    required this.returnDate,
    this.region,
    this.returnResponsible,
    this.deliveryCostPayer = 'الشركة',
    this.routeFrom,
    this.routeTo,
    this.returnReason,
    this.deliveryDate,
    this.items = const [],
    this.notes,
  });
  
  Map<String, dynamic> toJson() => {
    'sn': sn,
    'category': category,
    'branch': branch,
    'customerName': customerName,
    'returnDate': returnDate.toIso8601String(),
    'region': region,
    'returnResponsible': returnResponsible,
    'deliveryCostPayer': deliveryCostPayer,
    'routeFrom': routeFrom,
    'routeTo': routeTo,
    'returnReason': returnReason,
    'deliveryDate': deliveryDate?.toIso8601String(),
    'items': items.map((e) => e.toJson()).toList(),
    'notes': notes,
  };

  factory ReturnOrder.fromJson(Map<String, dynamic> json) => ReturnOrder(
    sn: json['sn'],
    category: json['category'],
    branch: json['branch'],
    customerName: json['customerName'],
    returnDate: DateTime.parse(json['returnDate']),
    region: json['region'],
    returnResponsible: json['returnResponsible'],
    deliveryCostPayer: json['deliveryCostPayer'] ?? 'الشركة',
    routeFrom: json['routeFrom'],
    routeTo: json['routeTo'],
    returnReason: json['returnReason'],
    deliveryDate: json['deliveryDate'] != null ? DateTime.parse(json['deliveryDate']) : null,
    items: (json['items'] as List?)?.map((e) => ReturnOrderItem.fromJson(e)).toList() ?? [],
    notes: json['notes'],
  );

  double get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
}

@HiveType(typeId: 7)
class ReturnOrderItem extends HiveObject {
  @HiveField(0)
  String item;
  
  @HiveField(1)
  double quantity;
  
  @HiveField(2)
  String unit;

  ReturnOrderItem({
    this.item = '',
    this.quantity = 0.0,
    this.unit = '',
  });

  Map<String, dynamic> toJson() => {
    'item': item,
    'quantity': quantity,
    'unit': unit,
  };

  factory ReturnOrderItem.fromJson(Map<String, dynamic> json) => ReturnOrderItem(
    item: json['item'] ?? '',
    quantity: (json['quantity'] as num).toDouble(),
    unit: json['unit'] ?? '',
  );
}
