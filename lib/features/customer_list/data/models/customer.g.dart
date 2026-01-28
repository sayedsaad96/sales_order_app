// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomerAdapter extends TypeAdapter<Customer> {
  @override
  final int typeId = 12;

  @override
  Customer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Customer(
      archtype: fields[0] as String?,
      customerType: fields[1] as String?,
      industry: fields[2] as String?,
      customerCode: fields[3] as String,
      customerName: fields[4] as String,
      paymentTerm: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Customer obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.archtype)
      ..writeByte(1)
      ..write(obj.customerType)
      ..writeByte(2)
      ..write(obj.industry)
      ..writeByte(3)
      ..write(obj.customerCode)
      ..writeByte(4)
      ..write(obj.customerName)
      ..writeByte(5)
      ..write(obj.paymentTerm);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
