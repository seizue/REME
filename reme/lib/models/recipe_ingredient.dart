class RecipeIngredient {
  final String ingredientId;
  final String ingredientName;
  final double quantity;
  final String unit;
  final double unitCost;

  const RecipeIngredient({
    required this.ingredientId,
    required this.ingredientName,
    required this.quantity,
    required this.unit,
    required this.unitCost,
  });

  double get totalCost => quantity * unitCost;

  Map<String, dynamic> toMap(String recipeId) => {
    'recipe_id': recipeId,
    'ingredient_id': ingredientId,
    'ingredient_name': ingredientName,
    'quantity': quantity,
    'unit': unit,
    'unit_cost': unitCost,
  };

  factory RecipeIngredient.fromMap(Map<String, dynamic> m) => RecipeIngredient(
    ingredientId: m['ingredient_id'],
    ingredientName: m['ingredient_name'],
    quantity: (m['quantity'] as num).toDouble(),
    unit: m['unit'],
    unitCost: (m['unit_cost'] as num).toDouble(),
  );
}
