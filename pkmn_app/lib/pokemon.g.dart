// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pokemon.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PokemonAdapter extends TypeAdapter<Pokemon> {
  @override
  final int typeId = 0;

  @override
  Pokemon read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Pokemon(
      number: fields[0] as int,
      name: fields[1] as String,
      type1: fields[2] as String,
      type2: fields[3] as String,
      hp: fields[4] as int,
      attack: fields[5] as int,
      defense: fields[6] as int,
      spAttack: fields[7] as int,
      spDefense: fields[8] as int,
      speed: fields[9] as int,
      found: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Pokemon obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.number)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type1)
      ..writeByte(3)
      ..write(obj.type2)
      ..writeByte(4)
      ..write(obj.hp)
      ..writeByte(5)
      ..write(obj.attack)
      ..writeByte(6)
      ..write(obj.defense)
      ..writeByte(7)
      ..write(obj.spAttack)
      ..writeByte(8)
      ..write(obj.spDefense)
      ..writeByte(9)
      ..write(obj.speed)
      ..writeByte(10)
      ..write(obj.found);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PokemonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
