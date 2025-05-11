import 'package:hive/hive.dart';

part 'plant.g.dart';

@HiveType(typeId: 1) // Cada classe Hive precisa de um 'typeId' único
class Plant extends HiveObject {
  @HiveField(0)
  int? id; // Pode ser nulo porque o id será gerado automaticamente

  @HiveField(1)
  String species; // Alterado de "name" para "species"

  @HiveField(2)
  String pasture;

  @HiveField(3)
  String culture;

  @HiveField(4)
  String condicaoArea;

  @HiveField(5)
  int quantity;

  @HiveField(6)
  DateTime date;

  @HiveField(7)
  double? fresh_weight; // Peso verde (em inglês para consistência)

  @HiveField(8)
  double? dry_weight; // Peso seco

  Plant({
    this.id,
    required this.species, // Alterado de "name" para "species"
    required this.pasture,
    required this.culture,
    required this.condicaoArea,
    required this.quantity,
    required this.date,
    this.fresh_weight,
    this.dry_weight,
  });

  // Converter Plant para Map para armazenar em um banco de dados (se necessário)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'species': species, // Alterado de "name" para "species"
      'pasture': pasture,
      'culture': culture,
      'condicaoArea': condicaoArea,
      'quantity': quantity,
      'date': date.toIso8601String(),
      'fresh_weight': fresh_weight ?? 0.0,
      'dry_weight': dry_weight ?? 0.0,
    };
  }

  // Criar uma Plant a partir de um Map
  factory Plant.fromMap(Map<String, dynamic> map) {
    return Plant(
      id: map['id'],
      species: map['species'] ?? "Espécie não disponível", // Alterado de "name" para "species"
      pasture: map['pasture'] ?? "Pasto não disponível",
      culture: map['culture'] ?? "Cultura não disponível",
      condicaoArea: map['condicaoArea'] ?? "Condição não disponível",
      quantity: map['quantity'] ?? 0,
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      fresh_weight: map['fresh_weight'] ?? 0.0,
      dry_weight: map['dry_weight'] ?? 0.0,
    );
  }
}
