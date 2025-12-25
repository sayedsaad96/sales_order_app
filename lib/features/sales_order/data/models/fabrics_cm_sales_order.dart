
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

  double get totalValue => items.fold(0, (sum, item) => sum + item.value);
}

@HiveType(typeId: 9)
class FabricsCmLineItem extends HiveObject {
  @HiveField(0)
  double quantity;

  @HiveField(2)
  String lycraNumber;
  @HiveField(3)
  double lycraPercentage;
  @HiveField(4)
  String fabricType;
  @HiveField(5)
  String yarnCount;
  @HiveField(6)
  String yarnType;
  @HiveField(7)
  int gauge;
  @HiveField(8)
  double widthInches;
  @HiveField(9)
  double stitchLength;

  @HiveField(11)
  String spinningCompany;
  @HiveField(12)
  double price;

  FabricsCmLineItem({
    this.quantity = 0.0,

    this.lycraNumber = '',
    this.lycraPercentage = 0.0,
    this.fabricType = '',
    this.yarnCount = '',
    this.yarnType = '',
    this.gauge = 0,
    this.widthInches = 0.0,
    this.stitchLength = 0.0,

    this.spinningCompany = '',
    this.price = 0.0,
  });

  double get value => quantity * price;
}
