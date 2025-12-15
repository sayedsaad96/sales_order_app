// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'return_order.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReturnOrderAdapter extends TypeAdapter<ReturnOrder> {
  @override
  final int typeId = 6;

  @override
  ReturnOrder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReturnOrder(
      sn: fields[0] as String?,
      category: fields[1] as String?,
      branch: fields[2] as String?,
      customerName: fields[3] as String?,
      returnDate: fields[4] as DateTime? ?? DateTime.now(),
      region: fields[5] as String?,
      returnResponsible: fields[6] as String?,
      deliveryCostPayer: fields[7] as String? ?? 'الشركة',
      routeFrom: fields[8] as String?,
      routeTo: fields[9] as String?,
      returnReason: fields[10] as String?,
      deliveryDate: fields[11] as DateTime?,
      items: (fields[12] as List?)?.cast<ReturnOrderItem>().toList() ?? <ReturnOrderItem>[],
    );
  }

  @override
  void write(BinaryWriter writer, ReturnOrder obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.sn)
      ..writeByte(1)
      ..write(obj.category)
      ..writeByte(2)
      ..write(obj.branch)
      ..writeByte(3)
      ..write(obj.customerName)
      ..writeByte(4)
      ..write(obj.returnDate)
      ..writeByte(5)
      ..write(obj.region)
      ..writeByte(6)
      ..write(obj.returnResponsible)
      ..writeByte(7)
      ..write(obj.deliveryCostPayer)
      ..writeByte(8)
      ..write(obj.routeFrom)
      ..writeByte(9)
      ..write(obj.routeTo)
      ..writeByte(10)
      ..write(obj.returnReason)
      ..writeByte(11)
      ..write(obj.deliveryDate)
      ..writeByte(12)
      ..write(obj.items);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReturnOrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReturnOrderItemAdapter extends TypeAdapter<ReturnOrderItem> {
  @override
  final int typeId = 7;

  @override
  ReturnOrderItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReturnOrderItem(
      item: fields[0] as String? ?? '',
      quantity: fields[1] as double? ?? 0.0,
      unit: fields[2] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, ReturnOrderItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.item)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.unit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReturnOrderItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
