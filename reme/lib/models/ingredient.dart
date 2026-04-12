const kCommonUnits = [
  'kg',
  'g',
  'pcs',
  'ml',
  'L',
  'cup',
  'tbsp',
  'tsp',
  'pack',
  'box'
];

class Ingredient {
  final String id;
  final String name;
  final double unitCost;
  final String unit;
  final bool unitEnabled; // false = no unit tracking

  const Ingredient({
    required this.id,
    required this.name,
    required this.unitCost,
    this.unit = '',
    this.unitEnabled = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'unit_cost': unitCost,
        'unit': unit,
        'unit_enabled': unitEnabled ? 1 : 0,
      };

  factory Ingredient.fromMap(Map<String, dynamic> m) => Ingredient(
        id: m['id'],
        name: m['name'],
        unitCost: (m['unit_cost'] as num).toDouble(),
        unit: m['unit'] ?? '',
        unitEnabled: (m['unit_enabled'] as int?) == 1,
      );

  Ingredient copyWith(
          {String? name, double? unitCost, String? unit, bool? unitEnabled}) =>
      Ingredient(
        id: id,
        name: name ?? this.name,
        unitCost: unitCost ?? this.unitCost,
        unit: unit ?? this.unit,
        unitEnabled: unitEnabled ?? this.unitEnabled,
      );
}
