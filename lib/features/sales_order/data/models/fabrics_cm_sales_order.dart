
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

  @HiveField(11)
  double? yarnPrice;
  @HiveField(12)
  double? lycraPrice;
  @HiveField(13)
  double? manufacturingPrice;

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
    this.yarnPrice,
    this.lycraPrice,
    this.manufacturingPrice,
  });

  double get baseTotal {
    bool isFabric = orderTypesList.contains('قماش');
    bool isCm = orderTypesList.contains('CM');
    return items.fold(0.0, (sum, item) => sum + item.calculateBaseValue(
      isFabric, 
      isCm, 
      globalYarnPrice: yarnPrice ?? 0.0,
      globalLycraPrice: lycraPrice ?? 0.0,
      globalMfgPrice: manufacturingPrice ?? 0.0,
    ));
  }

  double get wasteTotal {
    bool isFabric = orderTypesList.contains('قماش');
    bool isCm = orderTypesList.contains('CM');
    return items.fold(0.0, (sum, item) => sum + item.calculateWaste(
      isFabric, 
      isCm, 
      globalYarnPrice: yarnPrice ?? 0.0,
      globalLycraPrice: lycraPrice ?? 0.0,
      globalMfgPrice: manufacturingPrice ?? 0.0,
    ));
  }

  double get totalValue => baseTotal + wasteTotal;
}

@HiveType(typeId: 9)
class FabricsCmLineItem extends HiveObject {
  @HiveField(0)
  double quantity;

  @HiveField(2)
  String? lycraNumber;
  @HiveField(3)
  double? lycraPercentage;
  @HiveField(4)
  String? fabricType;
  @HiveField(5)
  String? yarnCount;
  @HiveField(6)
  String? yarnType;
  @HiveField(7)
  int? gauge;
  @HiveField(8)
  double? widthInches;
  @HiveField(9)
  double? stitchLength;

  @HiveField(11)
  String? spinningCompany;

  FabricsCmLineItem({
    this.quantity = 0.0,
    this.lycraNumber,
    this.lycraPercentage = 0.0,
    this.fabricType,
    this.yarnCount,
    this.yarnType,
    this.gauge = 0,
    this.widthInches = 0.0,
    this.stitchLength = 0.0,
    this.spinningCompany,
  });

  double calculateBaseValue(
    bool isFabric,
    bool isCm, {
    double globalYarnPrice = 0.0,
    double globalLycraPrice = 0.0,
    double globalMfgPrice = 0.0,
  }) {
    if (isFabric) {
      double lycraDecimal = (lycraPercentage ?? 0.0) / 100;
      double yarnQty = quantity * (1 - lycraDecimal);
      double lycraQty = quantity * lycraDecimal;
      return (yarnQty * globalYarnPrice) + (lycraQty * globalLycraPrice) + (globalMfgPrice * quantity);
    } else if (isCm) {
      double lycraDecimal = (lycraPercentage ?? 0.0) / 100;
      return (quantity * lycraDecimal * globalLycraPrice) + (globalMfgPrice * quantity);
    }
    return quantity * globalMfgPrice;
  }

  double calculateWaste(
    bool isFabric,
    bool isCm, {
    double globalYarnPrice = 0.0,
    double globalLycraPrice = 0.0,
    double globalMfgPrice = 0.0,
  }) {
    if (isFabric) {
      return calculateBaseValue(isFabric, isCm,
              globalYarnPrice: globalYarnPrice,
              globalLycraPrice: globalLycraPrice,
              globalMfgPrice: globalMfgPrice) *
          0.02;
    }
    return 0.0;
  }

  double calculateValue(
    bool isFabric,
    bool isCm, {
    double globalYarnPrice = 0.0,
    double globalLycraPrice = 0.0,
    double globalMfgPrice = 0.0,
  }) {
    return calculateBaseValue(isFabric, isCm,
            globalYarnPrice: globalYarnPrice,
            globalLycraPrice: globalLycraPrice,
            globalMfgPrice: globalMfgPrice) +
        calculateWaste(isFabric, isCm,
            globalYarnPrice: globalYarnPrice,
            globalLycraPrice: globalLycraPrice,
            globalMfgPrice: globalMfgPrice);
  }
}
