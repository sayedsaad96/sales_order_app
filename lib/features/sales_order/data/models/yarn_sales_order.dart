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
  @HiveField(10)
  String? contactName;
  @HiveField(9)
  bool specifiedQuantity;
  @HiveField(11)
  String? paymentMethod;
  @HiveField(12)
  String? salesResponsible;
  @HiveField(13)
  List<YarnSalesOrderItem> items;
  @HiveField(14)
  List<YarnInstallment> installments;
  @HiveField(15)
  String? notes;
  @HiveField(16)
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
}
