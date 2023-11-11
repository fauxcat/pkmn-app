import 'package:hive/hive.dart';

part 'pokemon.g.dart';

@HiveType(typeId: 0)
class Pokemon {
  @HiveField(0)
  late int number;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String type1;

  @HiveField(3)
  late String type2;

  @HiveField(4)
  late int hp;

  @HiveField(5)
  late int attack;

  @HiveField(6)
  late int defense;

  @HiveField(7)
  late int spAttack;

  @HiveField(8)
  late int spDefense;

  @HiveField(9)
  late int speed;

  @HiveField(10)
  late bool found;

  Pokemon({
    required this.number,
    required this.name,
    required this.type1,
    required this.type2,
    required this.hp,
    required this.attack,
    required this.defense,
    required this.spAttack,
    required this.spDefense,
    required this.speed,
    required this.found,
  });
}
