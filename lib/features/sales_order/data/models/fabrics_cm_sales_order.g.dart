// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fabrics_cm_sales_order.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FabricsCmSalesOrderAdapter extends TypeAdapter<FabricsCmSalesOrder> {
  @override
  final int typeId = 8;

  @override
  FabricsCmSalesOrder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FabricsCmSalesOrder(
      sn: fields[0] as String?,
      customerName: fields[1] as String?,
      salesResponsible: fields[2] as String?,
      paymentMethod: fields[3] as String?,
      deliveryDate: fields[4] as DateTime?,
      orderType: fields[5] as String?,
      items: (fields[6] as List).cast<FabricsCmLineItem>(),
      orderDate: fields[7] as DateTime,
      notes: fields[8] as String?,
      branch: fields[9] as String?,
      orderTypesList: (fields[10] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, FabricsCmSalesOrder obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.sn)
      ..writeByte(1)
      ..write(obj.customerName)
      ..writeByte(2)
      ..write(obj.salesResponsible)
      ..writeByte(3)
      ..write(obj.paymentMethod)
      ..writeByte(4)
      ..write(obj.deliveryDate)
      ..writeByte(5)
      ..write(obj.orderType)
      ..writeByte(6)
      ..write(obj.items)
      ..writeByte(7)
      ..write(obj.orderDate)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.branch)
      ..writeByte(10)
      ..write(obj.orderTypesList);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FabricsCmSalesOrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FabricsCmLineItemAdapter extends TypeAdapter<FabricsCmLineItem> {
  @override
  final int typeId = 9;

  @override
  FabricsCmLineItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FabricsCmLineItem(
      quantity: fields[0] as double,
      fabricDetails: fields[1] as String?,
      price: fields[10] as double?,
      spinningCompany: fields[11] as String?,
      gauge: fields[7] as dynamic,
      inch: fields[8] as dynamic,
      stitchLength: fields[9] as dynamic,
    );
  }

  @override
  void write(BinaryWriter writer, FabricsCmLineItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.quantity)
      ..writeByte(1)
      ..write(obj.fabricDetails)
      ..writeByte(10)
      ..write(obj.price)
      ..writeByte(11)
      ..write(obj.spinningCompany)
      ..writeByte(7)
      ..write(obj.gauge)
      ..writeByte(8)
      ..write(obj.inch)
      ..writeByte(9)
      ..write(obj.stitchLength);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FabricsCmLineItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
