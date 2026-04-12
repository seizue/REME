class IngredientPriceHistory {
  final String id;
  final String ingredientId;
  final double oldCost;
  final double newCost;
  final DateTime changedAt;

  const IngredientPriceHistory({
    required this.id,
    required this.ingredientId,
    required this.oldCost,
    required this.newCost,
    required this.changedAt,
  });

  double get diff => newCost - oldCost;
  double get changePercent => oldCost > 0 ? (diff / oldCost) * 100 : 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'ingredient_id': ingredientId,
        'old_cost': oldCost,
        'new_cost': newCost,
        'changed_at': changedAt.toIso8601String(),
      };

  factory IngredientPriceHistory.fromMap(Map<String, dynamic> m) =>
      IngredientPriceHistory(
        id: m['id'],
        ingredientId: m['ingredient_id'],
        oldCost: (m['old_cost'] as num).toDouble(),
        newCost: (m['new_cost'] as num).toDouble(),
        changedAt: DateTime.parse(m['changed_at']),
      );
}
