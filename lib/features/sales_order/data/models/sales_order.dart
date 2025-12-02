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
  });

  double get totalValue => items.fold(0, (sum, item) => sum + item.value);
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

  double get value => quantity * price;
}
