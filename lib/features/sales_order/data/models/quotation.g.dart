// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quotation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuotationAdapter extends TypeAdapter<Quotation> {
  @override
  final int typeId = 10;

  @override
  Quotation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Quotation(
      sn: fields[0] as String?,
      customerName: fields[1] as String?,
      date: fields[2] as DateTime,
      items: (fields[3] as List).cast<QuotationItem>(),
      notes: fields[4] as String?,
      totalValueOverride: fields[5] as double?,
      validUntil: fields[6] as DateTime?,
      termsAndConditions: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Quotation obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.sn)
      ..writeByte(1)
      ..write(obj.customerName)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.items)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.totalValueOverride)
      ..writeByte(6)
      ..write(obj.validUntil)
      ..writeByte(7)
      ..write(obj.termsAndConditions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuotationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class QuotationItemAdapter extends TypeAdapter<QuotationItem> {
  @override
  final int typeId = 11;

  @override
  QuotationItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuotationItem(
      type: fields[0] as String,
      quantity: fields[1] as double,
      price: fields[2] as double,
      itemName: fields[3] as String?,
      description: fields[4] as String?,
      unit: fields[5] as String?,
      spinningCompany: fields[6] as String?,
      yarnCount: fields[7] as String?,
      yarnType: fields[8] as String?,
      fabricType: fields[9] as String?,
      lycraNumber: fields[10] as String?,
      lycraPercentage: fields[11] as double?,
      widthInches: fields[12] as double?,
      gauge: fields[13] as int?,
      stitchLength: fields[14] as double?,
      yarnPrice: fields[15] as double?,
      lycraPrice: fields[16] as double?,
      cmPrice: fields[17] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, QuotationItem obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.itemName)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.unit)
      ..writeByte(6)
      ..write(obj.spinningCompany)
      ..writeByte(7)
      ..write(obj.yarnCount)
      ..writeByte(8)
      ..write(obj.yarnType)
      ..writeByte(9)
      ..write(obj.fabricType)
      ..writeByte(10)
      ..write(obj.lycraNumber)
      ..writeByte(11)
      ..write(obj.lycraPercentage)
      ..writeByte(12)
      ..write(obj.widthInches)
      ..writeByte(13)
      ..write(obj.gauge)
      ..writeByte(14)
      ..write(obj.stitchLength)
      ..writeByte(15)
      ..write(obj.yarnPrice)
      ..writeByte(16)
      ..write(obj.lycraPrice)
      ..writeByte(17)
      ..write(obj.cmPrice);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuotationItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
