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
      yarnPrice: fields[11] as double?,
      lycraPrice: fields[12] as double?,
      manufacturingPrice: fields[13] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, FabricsCmSalesOrder obj) {
    writer
      ..writeByte(14)
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
      ..write(obj.orderTypesList)
      ..writeByte(11)
      ..write(obj.yarnPrice)
      ..writeByte(12)
      ..write(obj.lycraPrice)
      ..writeByte(13)
      ..write(obj.manufacturingPrice);
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
      lycraNumber: fields[2] as String?,
      lycraPercentage: fields[3] as double?,
      fabricType: fields[4] as String?,
      yarnCount: fields[5] as String?,
      yarnType: fields[6] as String?,
      gauge: fields[7] as int?,
      widthInches: fields[8] as double?,
      stitchLength: fields[9] as double?,
      spinningCompany: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FabricsCmLineItem obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.lycraNumber)
      ..writeByte(3)
      ..write(obj.lycraPercentage)
      ..writeByte(4)
      ..write(obj.fabricType)
      ..writeByte(5)
      ..write(obj.yarnCount)
      ..writeByte(6)
      ..write(obj.yarnType)
      ..writeByte(7)
      ..write(obj.gauge)
      ..writeByte(8)
      ..write(obj.widthInches)
      ..writeByte(9)
      ..write(obj.stitchLength)
      ..writeByte(11)
      ..write(obj.spinningCompany);
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
