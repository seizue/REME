import 'recipe_ingredient.dart';

enum WeightUnit { kilo, grams }

extension WeightUnitLabel on WeightUnit {
  String get label => this == WeightUnit.kilo ? 'kg' : 'g';
}

class Recipe {
  final String id;
  final String name;
  final String category;
  final List<RecipeIngredient> ingredients;
  final double laborCost; // fixed labor cost per batch
  final double markupPercent; // e.g. 30 = 30%
  final int pieces; // how many pieces this batch makes
  final double totalWeight; // total weight of batch
  final WeightUnit weightUnit; // kg or g
  final DateTime createdAt;
  final DateTime updatedAt;

  const Recipe({
    required this.id,
    required this.name,
    required this.category,
    required this.ingredients,
    this.laborCost = 0,
    this.markupPercent = 30,
    this.pieces = 1,
    this.totalWeight = 0,
    this.weightUnit = WeightUnit.kilo,
    required this.createdAt,
    required this.updatedAt,
  });

  double get ingredientCost =>
      ingredients.fold(0.0, (sum, i) => sum + i.totalCost);

  /// Ingredient cost after markup
  double get markedUpIngredientCost =>
      ingredientCost * (1 + markupPercent / 100);

  /// Total cost = marked-up ingredients + labor
  double get totalCost => markedUpIngredientCost + laborCost;

  /// Selling price per batch = total cost (already includes markup)
  double get sellingPriceBatch => totalCost;

  /// Selling price per piece
  double get sellingPricePerPiece =>
      pieces > 0 ? sellingPriceBatch / pieces : sellingPriceBatch;

  /// Selling price per kg/g
  double get sellingPricePerWeight {
    if (totalWeight <= 0) return 0;
    final weightInKg =
        weightUnit == WeightUnit.kilo ? totalWeight : totalWeight / 1000;
    return weightInKg > 0 ? sellingPriceBatch / weightInKg : 0;
  }

  double get profitMargin => sellingPriceBatch > 0
      ? (ingredientCost * markupPercent / 100) / sellingPriceBatch * 100
      : 0;

  // Keep sellingPrice for backward compat with sales
  double get sellingPrice => sellingPricePerPiece;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'selling_price': sellingPricePerPiece, // stored for sales reference
        'labor_cost': laborCost,
        'markup_percent': markupPercent,
        'pieces': pieces,
        'total_weight': totalWeight,
        'weight_unit': weightUnit.name,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Recipe.fromMap(
          Map<String, dynamic> m, List<RecipeIngredient> ingredients) =>
      Recipe(
        id: m['id'],
        name: m['name'],
        category: m['category'] ?? '',
        ingredients: ingredients,
        laborCost: (m['labor_cost'] as num?)?.toDouble() ?? 0,
        markupPercent: (m['markup_percent'] as num?)?.toDouble() ?? 30,
        pieces: (m['pieces'] as int?) ?? 1,
        totalWeight: (m['total_weight'] as num?)?.toDouble() ?? 0,
        weightUnit: WeightUnit.values.firstWhere(
          (w) => w.name == (m['weight_unit'] ?? 'kilo'),
          orElse: () => WeightUnit.kilo,
        ),
        createdAt: DateTime.parse(m['created_at']),
        updatedAt: DateTime.parse(m['updated_at']),
      );

  Recipe copyWith({
    String? name,
    String? category,
    List<RecipeIngredient>? ingredients,
    double? laborCost,
    double? markupPercent,
    int? pieces,
    double? totalWeight,
    WeightUnit? weightUnit,
  }) =>
      Recipe(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        ingredients: ingredients ?? this.ingredients,
        laborCost: laborCost ?? this.laborCost,
        markupPercent: markupPercent ?? this.markupPercent,
        pieces: pieces ?? this.pieces,
        totalWeight: totalWeight ?? this.totalWeight,
        weightUnit: weightUnit ?? this.weightUnit,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
