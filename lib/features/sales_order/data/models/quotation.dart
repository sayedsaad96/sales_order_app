
import 'package:hive/hive.dart';

part 'quotation.g.dart';

@HiveType(typeId: 10)
class Quotation extends HiveObject {
  @HiveField(0)
  String? sn;
  @HiveField(1)
  String? customerName;
  @HiveField(2)
  DateTime date;
  @HiveField(3)
  List<QuotationItem> items;
  @HiveField(4)
  String? notes;
  @HiveField(5)
  double? totalValueOverride; // Optional manual override
  @HiveField(6)
  DateTime? validUntil;
  @HiveField(7)
  String? termsAndConditions;

  Quotation({
    this.sn,
    this.customerName,
    required this.date,
    this.items = const [],
    this.notes,
    this.totalValueOverride,
    this.validUntil,
    this.termsAndConditions,
  });

  Map<String, dynamic> toJson() => {
    'sn': sn,
    'customerName': customerName,
    'date': date.toIso8601String(),
    'items': items.map((e) => e.toJson()).toList(),
    'notes': notes,
    'totalValueOverride': totalValueOverride,
    'validUntil': validUntil?.toIso8601String(),
    'termsAndConditions': termsAndConditions,
  };

  factory Quotation.fromJson(Map<String, dynamic> json) => Quotation(
    sn: json['sn'],
    customerName: json['customerName'],
    date: DateTime.parse(json['date']),
    items: (json['items'] as List?)?.map((e) => QuotationItem.fromJson(e)).toList() ?? [],
    notes: json['notes'],
    totalValueOverride: (json['totalValueOverride'] as num?)?.toDouble(),
    validUntil: json['validUntil'] != null ? DateTime.parse(json['validUntil']) : null,
    termsAndConditions: json['termsAndConditions'],
  );

  double get baseTotal => items.fold(0, (sum, item) => sum + (item.quantity * item.calculateBaseUnitPrice));
  double get wasteTotal => items.fold(0, (sum, item) => sum + (item.quantity * item.calculateWasteAmountPerUnit));
  double get totalValue => totalValueOverride ?? (baseTotal + wasteTotal);
}

@HiveType(typeId: 11)
class QuotationItem extends HiveObject {
  @HiveField(0)
  String type; // 'fabric', 'yarn', 'standard'

  @HiveField(1)
  double quantity;
  @HiveField(2)
  double price;
  
  // -- Standard / Yarn Fields --
  @HiveField(3)
  String? itemName; // For Standard
  @HiveField(4)
  String? description; // For Yarn
  @HiveField(5)
  String? unit;

  // -- Fabric Fields --
  @HiveField(6)
  String? spinningCompany;
  @HiveField(7)
  String? yarnCount;
  @HiveField(8)
  String? yarnType;
  @HiveField(9)
  String? fabricType;
  @HiveField(10)
  String? lycraNumber;
  @HiveField(11)
  double? lycraPercentage;
  @HiveField(12)
  double? widthInches;
  @HiveField(13)
  int? gauge;
  @HiveField(14)
  double? stitchLength;
  
  // -- Fabric Costing Fields --
  @HiveField(15)
  double? yarnPrice;
  @HiveField(16)
  double? lycraPrice;
  @HiveField(17)
  double? cmPrice;

  QuotationItem({
    required this.type,
    this.quantity = 0.0,
    this.price = 0.0,
    this.itemName,
    this.description,
    this.unit,
    this.spinningCompany,
    this.yarnCount,
    this.yarnType,
    this.fabricType,
    this.lycraNumber,
    this.lycraPercentage,
    this.widthInches,
    this.gauge,
    this.stitchLength,
    this.yarnPrice,
    this.lycraPrice,
    this.cmPrice,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'quantity': quantity,
    'price': price,
    'itemName': itemName,
    'description': description,
    'unit': unit,
    'spinningCompany': spinningCompany,
    'yarnCount': yarnCount,
    'yarnType': yarnType,
    'fabricType': fabricType,
    'lycraNumber': lycraNumber,
    'lycraPercentage': lycraPercentage,
    'widthInches': widthInches,
    'gauge': gauge,
    'stitchLength': stitchLength,
    'yarnPrice': yarnPrice,
    'lycraPrice': lycraPrice,
    'cmPrice': cmPrice,
  };

  factory QuotationItem.fromJson(Map<String, dynamic> json) => QuotationItem(
    type: json['type'],
    quantity: (json['quantity'] as num).toDouble(),
    price: (json['price'] as num).toDouble(),
    itemName: json['itemName'],
    description: json['description'],
    unit: json['unit'],
    spinningCompany: json['spinningCompany'],
    yarnCount: json['yarnCount'],
    yarnType: json['yarnType'],
    fabricType: json['fabricType'],
    lycraNumber: json['lycraNumber'],
    lycraPercentage: (json['lycraPercentage'] as num?)?.toDouble(),
    widthInches: (json['widthInches'] as num?)?.toDouble(),
    gauge: json['gauge'],
    stitchLength: (json['stitchLength'] as num?)?.toDouble(),
    yarnPrice: (json['yarnPrice'] as num?)?.toDouble(),
    lycraPrice: (json['lycraPrice'] as num?)?.toDouble(),
    cmPrice: (json['cmPrice'] as num?)?.toDouble(),
  );

  double get calculateBaseUnitPrice {
    if (type == 'fabric' && yarnPrice != null && lycraPrice != null && cmPrice != null) {
      double lycraDecimal = (lycraPercentage ?? 0.0) / 100;
      double yarnPart = (1 - lycraDecimal) * yarnPrice!;
      double lycraPart = lycraDecimal * lycraPrice!;
      return yarnPart + lycraPart + cmPrice!;
    }
    return price;
  }

  double get calculateWasteAmountPerUnit {
    if (type == 'fabric' && yarnPrice != null && lycraPrice != null && cmPrice != null) {
      return calculateBaseUnitPrice * 0.02;
    }
    return 0.0;
  }

  double get calculateUnitPrice => calculateBaseUnitPrice + calculateWasteAmountPerUnit;

  double get value => quantity * calculateUnitPrice;
}
