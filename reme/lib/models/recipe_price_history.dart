class RecipePriceHistory {
  final String id;
  final String recipeId;
  final double oldPrice;
  final double newPrice;
  final double oldCost;
  final double newCost;
  final DateTime changedAt;
  final String? note;

  const RecipePriceHistory({
    required this.id,
    required this.recipeId,
    required this.oldPrice,
    required this.newPrice,
    required this.oldCost,
    required this.newCost,
    required this.changedAt,
    this.note,
  });

  double get priceDiff => newPrice - oldPrice;
  double get costDiff => newCost - oldCost;
  double get priceChangePercent =>
      oldPrice > 0 ? (priceDiff / oldPrice) * 100 : 0;

  Map<String, dynamic> toMap() => {
    'id': id,
    'recipe_id': recipeId,
    'old_price': oldPrice,
    'new_price': newPrice,
    'old_cost': oldCost,
    'new_cost': newCost,
    'changed_at': changedAt.toIso8601String(),
    'note': note,
  };

  factory RecipePriceHistory.fromMap(Map<String, dynamic> m) =>
      RecipePriceHistory(
        id: m['id'],
        recipeId: m['recipe_id'],
        oldPrice: (m['old_price'] as num).toDouble(),
        newPrice: (m['new_price'] as num).toDouble(),
        oldCost: (m['old_cost'] as num).toDouble(),
        newCost: (m['new_cost'] as num).toDouble(),
        changedAt: DateTime.parse(m['changed_at']),
        note: m['note'],
      );
}
