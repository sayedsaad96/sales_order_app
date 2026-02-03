import 'package:hive/hive.dart';

@HiveType(typeId: 15)
class AuthorizedPerson extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String nationalId;

  AuthorizedPerson({
    required this.name,
    required this.nationalId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthorizedPerson &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          nationalId == other.nationalId;

  @override
  int get hashCode => name.hashCode ^ nationalId.hashCode;
}

class AuthorizedPersonAdapter extends TypeAdapter<AuthorizedPerson> {
  @override
  final int typeId = 15;

  @override
  AuthorizedPerson read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AuthorizedPerson(
      name: fields[0] as String,
      nationalId: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AuthorizedPerson obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.nationalId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      other is AuthorizedPersonAdapter &&
      runtimeType == other.runtimeType &&
      typeId == other.typeId;
}
