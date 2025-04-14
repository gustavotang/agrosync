import 'package:hive/hive.dart';

part 'plant.g.dart';

@HiveType(typeId: 1)  // Cada classe Hive precisa de um 'typeId' único
class Plant extends HiveObject {
  @HiveField(0)
  int? id;  // Pode ser nulo porque o id será gerado automaticamente

  @HiveField(1)
  String name;

  @HiveField(2)
  String species;

  @HiveField(3)
  String pasture;

  @HiveField(4)
  String culture;

  @HiveField(5)
  String condicaoArea;

  @HiveField(6)
  int quantity;

  @HiveField(7)
  DateTime date;

  @HiveField(8)
  double fresh_weight;  // Peso verde (em inglês para consistência)

  @HiveField(9)
  double dry_weight;    // Peso seco

  Plant({
    this.id,
    required this.name,
    required this.species,
    required this.pasture,
    required this.culture,
    required this.condicaoArea,
    required this.quantity,
    required this.date,
    required this.fresh_weight,
    required this.dry_weight,
  });

  // Converter Plant para Map para armazenar em um banco de dados (se necessário)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'pasture': pasture,
      'culture': culture,
      'condicaoArea': condicaoArea,
      'quantity': quantity,
      'date': date.toIso8601String(),
      'fresh_weight': fresh_weight,
      'dry_weight': dry_weight,
    };
  }

  // Criar uma Plant a partir de um Map
  factory Plant.fromMap(Map<String, dynamic> map) {
    return Plant(
      id: map['id'],
      name: map['name'],
      species: map['species'],
      pasture: map['pasture'],
      culture: map['culture'],
      condicaoArea: map['condicaoArea'],
      quantity: map['quantity'],
      date: DateTime.parse(map['date']),
      fresh_weight: map['fresh_weight'],
      dry_weight: map['dry_weight'],
    );
  }
}
