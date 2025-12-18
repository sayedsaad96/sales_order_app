// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yarn_sales_order.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class YarnSalesOrderAdapter extends TypeAdapter<YarnSalesOrder> {
  @override
  final int typeId = 3;

  @override
  YarnSalesOrder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return YarnSalesOrder(
      sn: fields[0] as String?,
      branch: fields[1] as String?,
      deliveryResponsibility: fields[2] as String,
      customerName: fields[3] as String?,
      contactName: fields[9] is String ? fields[9] as String? : null,
      region: fields[4] as String?,
      deliveryDate: fields[5] as DateTime?,
      orderDate: fields[6] as DateTime,
      deliveryPlace: fields[7] as String?,
      editQuantity: fields[8] is String ? fields[8] as String? : null,
      mobileNumber: fields[17] as String?,
      specifiedQuantity: fields[10] is bool ? fields[10] as bool : false,
      paymentMethod: fields[11] as String?,
      salesResponsible: fields[12] as String?,
      items: (fields[13] as List? ?? []).cast<YarnSalesOrderItem>(),
      installments: (fields[14] as List? ?? []).cast<YarnInstallment>(),
      notes: fields[15] as String?,
      orderTypes: (fields[16] as List? ?? []).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, YarnSalesOrder obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.sn)
      ..writeByte(1)
      ..write(obj.branch)
      ..writeByte(2)
      ..write(obj.deliveryResponsibility)
      ..writeByte(3)
      ..write(obj.customerName)
      ..writeByte(4)
      ..write(obj.region)
      ..writeByte(5)
      ..write(obj.deliveryDate)
      ..writeByte(6)
      ..write(obj.orderDate)
      ..writeByte(7)
      ..write(obj.deliveryPlace)
      ..writeByte(8)
      ..write(obj.editQuantity)
      ..writeByte(9)
      ..write(obj.contactName)
      ..writeByte(10)
      ..write(obj.specifiedQuantity)
      ..writeByte(11)
      ..write(obj.paymentMethod)
      ..writeByte(12)
      ..write(obj.salesResponsible)
      ..writeByte(13)
      ..write(obj.items)
      ..writeByte(14)
      ..write(obj.installments)
      ..writeByte(15)
      ..write(obj.notes)
      ..writeByte(16)
      ..write(obj.orderTypes)
      ..writeByte(17)
      ..write(obj.mobileNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YarnSalesOrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class YarnSalesOrderItemAdapter extends TypeAdapter<YarnSalesOrderItem> {
  @override
  final int typeId = 4;

  @override
  YarnSalesOrderItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return YarnSalesOrderItem(
      description: fields[0] as String,
      quantity: fields[1] as double,
      unit: fields[2] as String,
      price: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, YarnSalesOrderItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.description)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.price);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YarnSalesOrderItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class YarnInstallmentAdapter extends TypeAdapter<YarnInstallment> {
  @override
  final int typeId = 5;

  @override
  YarnInstallment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return YarnInstallment(
      duration: fields[0] as String,
      value: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, YarnInstallment obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.duration)
      ..writeByte(1)
      ..write(obj.value);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YarnInstallmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
