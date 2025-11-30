
class SalesOrder {
  String? sn;
  String? branch;
  List<String> orderTypes;
  String? customerName;
  String? region;
  bool deliveryIncluded;
  DateTime? deliveryDate;
  DateTime orderDate;
  String? salesResponsible;
  String? paymentMethod;
  String? deliveryPlace;
  List<SalesOrderItem> items;

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
  });

  double get totalValue => items.fold(0, (sum, item) => sum + item.value);
}

class SalesOrderItem {
  String itemName;
  int quantity;
  String unit;
  double price;

  SalesOrderItem({
    this.itemName = '',
    this.quantity = 0,
    this.unit = '',
    this.price = 0.0,
  });

  double get value => quantity * price;
}
