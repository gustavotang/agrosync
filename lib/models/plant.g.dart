// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plant.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlantAdapter extends TypeAdapter<Plant> {
  @override
  final int typeId = 1;

  @override
  Plant read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Plant(
      id: fields[0] as int?,
      name: fields[1] as String,
      species: fields[2] as String,
      pasture: fields[3] as String,
      culture: fields[4] as String,
      condicaoArea: fields[5] as String,
      quantity: fields[6] as int,
      date: fields[7] as DateTime,
      fresh_weight: fields[8] as double,
      dry_weight: fields[9] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Plant obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.species)
      ..writeByte(3)
      ..write(obj.pasture)
      ..writeByte(4)
      ..write(obj.culture)
      ..writeByte(5)
      ..write(obj.condicaoArea)
      ..writeByte(6)
      ..write(obj.quantity)
      ..writeByte(7)
      ..write(obj.date)
      ..writeByte(8)
      ..write(obj.fresh_weight)
      ..writeByte(9)
      ..write(obj.dry_weight);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlantAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
