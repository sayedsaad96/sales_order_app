import 'package:hive/hive.dart';

part 'customer.g.dart';

@HiveType(typeId: 12)
class Customer extends HiveObject {
  @HiveField(0)
  String? archtype;

  @HiveField(1)
  String? customerType;

  @HiveField(2)
  String? industry;

  @HiveField(3)
  String customerCode;

  @HiveField(4)
  String customerName;

  @HiveField(5)
  String? paymentTerm;

  Customer({
    this.archtype,
    this.customerType,
    this.industry,
    required this.customerCode,
    required this.customerName,
    this.paymentTerm,
  });

  Map<String, dynamic> toJson() => {
        'archtype': archtype,
        'customerType': customerType,
        'industry': industry,
        'customerCode': customerCode,
        'customerName': customerName,
        'paymentTerm': paymentTerm,
      };

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        archtype: json['archtype'],
        customerType: json['customerType'],
        industry: json['industry'],
        customerCode: json['customerCode'] ?? '',
        customerName: json['customerName'] ?? '',
        paymentTerm: json['paymentTerm'],
      );
}
