// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plant.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlantAdapter extends TypeAdapter<Plant> {
  @override
  final int typeId = 0;

  @override
  Plant read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Plant(
      id: fields[0] as int?,
      species: fields[1] as String, // Atualizado de "name" para "species"
      pasture: fields[2] as String,
      culture: fields[3] as String,
      condicaoArea: fields[4] as String,
      quantity: fields[5] as int,
      date: fields[6] as DateTime,
      fresh_weight: fields[7] as double?,
      dry_weight: fields[8] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Plant obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.species) // Atualizado de "name" para "species"
      ..writeByte(2)
      ..write(obj.pasture)
      ..writeByte(3)
      ..write(obj.culture)
      ..writeByte(4)
      ..write(obj.condicaoArea)
      ..writeByte(5)
      ..write(obj.quantity)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.fresh_weight)
      ..writeByte(8)
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
