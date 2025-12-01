// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_order.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SalesOrderAdapter extends TypeAdapter<SalesOrder> {
  @override
  final int typeId = 1;

  @override
  SalesOrder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SalesOrder(
      sn: fields[0] as String?,
      branch: fields[1] as String?,
      orderTypes: (fields[2] as List).cast<String>(),
      customerName: fields[3] as String?,
      region: fields[4] as String?,
      deliveryIncluded: fields[5] as bool,
      deliveryDate: fields[6] as DateTime?,
      orderDate: fields[7] as DateTime,
      salesResponsible: fields[8] as String?,
      paymentMethod: fields[9] as String?,
      deliveryPlace: fields[10] as String?,
      items: (fields[11] as List).cast<SalesOrderItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, SalesOrder obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.sn)
      ..writeByte(1)
      ..write(obj.branch)
      ..writeByte(2)
      ..write(obj.orderTypes)
      ..writeByte(3)
      ..write(obj.customerName)
      ..writeByte(4)
      ..write(obj.region)
      ..writeByte(5)
      ..write(obj.deliveryIncluded)
      ..writeByte(6)
      ..write(obj.deliveryDate)
      ..writeByte(7)
      ..write(obj.orderDate)
      ..writeByte(8)
      ..write(obj.salesResponsible)
      ..writeByte(9)
      ..write(obj.paymentMethod)
      ..writeByte(10)
      ..write(obj.deliveryPlace)
      ..writeByte(11)
      ..write(obj.items);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SalesOrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SalesOrderItemAdapter extends TypeAdapter<SalesOrderItem> {
  @override
  final int typeId = 2;

  @override
  SalesOrderItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SalesOrderItem(
      itemName: fields[0] as String,
      quantity: fields[1] as int,
      unit: fields[2] as String,
      price: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, SalesOrderItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.itemName)
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
      other is SalesOrderItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
