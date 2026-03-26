// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deduction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeductionAdapter extends TypeAdapter<Deduction> {
  @override
  final int typeId = 3;

  @override
  Deduction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Deduction(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: fields[2] as double,
      monthKey: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Deduction obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.monthKey);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeductionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
