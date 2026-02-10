import 'dart:typed_data';
import 'package:hive/hive.dart';

@HiveType(typeId: 16)
class TaxInvoiceRequest extends HiveObject {
  @HiveField(0)
  final String sapCustomerCode;
  @HiveField(1)
  final String customerNameOnTaxCard;
  @HiveField(2)
  final String? taxCardNumber;
  @HiveField(3)
  final String itemName;
  @HiveField(4)
  final double? quantity;
  @HiveField(5)
  final double? unitPrice;
  @HiveField(6)
  final DateTime? fromDate;
  @HiveField(7)
  final DateTime? toDate;
  @HiveField(8)
  final double? totalBeforeTax;
  @HiveField(9)
  final double? totalAfterTax;
  @HiveField(10)
  final String? additionalInfo;
  @HiveField(11)
  final Uint8List? taxCardImage;
  @HiveField(12)
  final String? unit;

  TaxInvoiceRequest({
    required this.sapCustomerCode,
    required this.customerNameOnTaxCard,
    this.taxCardNumber,
    required this.itemName,
    this.quantity,
    this.unitPrice,
    this.fromDate,
    this.toDate,
    this.totalBeforeTax,
    this.totalAfterTax,
    this.additionalInfo,
    this.taxCardImage,
    this.unit,
  });
}

class TaxInvoiceRequestAdapter extends TypeAdapter<TaxInvoiceRequest> {
  @override
  final int typeId = 16;

  @override
  TaxInvoiceRequest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaxInvoiceRequest(
      sapCustomerCode: fields[0] as String,
      customerNameOnTaxCard: fields[1] as String,
      taxCardNumber: fields[2] as String?,
      itemName: fields[3] as String,
      quantity: fields[4] as double?,
      unitPrice: fields[5] as double?,
      fromDate: fields[6] as DateTime?,
      toDate: fields[7] as DateTime?,
      totalBeforeTax: fields[8] as double?,
      totalAfterTax: fields[9] as double?,
      additionalInfo: fields[10] as String?,
      taxCardImage: fields[11] as Uint8List?,
      unit: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TaxInvoiceRequest obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.sapCustomerCode)
      ..writeByte(1)
      ..write(obj.customerNameOnTaxCard)
      ..writeByte(2)
      ..write(obj.taxCardNumber)
      ..writeByte(3)
      ..write(obj.itemName)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.unitPrice)
      ..writeByte(6)
      ..write(obj.fromDate)
      ..writeByte(7)
      ..write(obj.toDate)
      ..writeByte(8)
      ..write(obj.totalBeforeTax)
      ..writeByte(9)
      ..write(obj.totalAfterTax)
      ..writeByte(10)
      ..write(obj.additionalInfo)
      ..writeByte(11)
      ..write(obj.taxCardImage)
      ..writeByte(12)
      ..write(obj.unit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      other is TaxInvoiceRequestAdapter &&
      runtimeType == other.runtimeType &&
      typeId == other.typeId;
}
