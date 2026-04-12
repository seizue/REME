import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import '../../../models/ingredient.dart';
import '../../../models/ingredient_price_history.dart';
import '../../../models/recipe.dart';
import '../../../models/recipe_ingredient.dart';
import '../../../models/recipe_price_history.dart';

class CostingProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  List<Ingredient> _ingredients = [];
  List<Recipe> _recipes = [];
  List<RecipePriceHistory> _recipePriceHistory = [];
  List<IngredientPriceHistory> _ingredientPriceHistory = [];
  bool _loading = false;

  List<Ingredient> get ingredients => _ingredients;
  List<Recipe> get recipes => _recipes;
  List<RecipePriceHistory> get priceHistory => _recipePriceHistory;
  List<IngredientPriceHistory> get ingredientPriceHistory =>
      _ingredientPriceHistory;
  bool get loading => _loading;

  double get grandTotalCost =>
      _recipes.fold(0.0, (sum, r) => sum + r.sellingPriceBatch);

  Future<Database> get _db async => DatabaseHelper.instance.database;

  // ─── Load ────────────────────────────────────────────────────────────────

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    await Future.wait([loadIngredients(), loadRecipes()]);
    _loading = false;
    notifyListeners();
  }

  Future<void> loadIngredients() async {
    final db = await _db;
    final rows = await db.query('ingredients', orderBy: 'name ASC');
    _ingredients = rows.map(Ingredient.fromMap).toList();
    notifyListeners();
  }

  Future<void> loadRecipes() async {
    final db = await _db;
    final rows = await db.query('recipes', orderBy: 'name ASC');
    final List<Recipe> loaded = [];
    for (final row in rows) {
      final riRows = await db.query(
        'recipe_ingredients',
        where: 'recipe_id = ?',
        whereArgs: [row['id']],
      );
      loaded.add(
          Recipe.fromMap(row, riRows.map(RecipeIngredient.fromMap).toList()));
    }
    _recipes = loaded;
    notifyListeners();
  }

  Future<void> loadRecipePriceHistory(String recipeId) async {
    final db = await _db;
    final rows = await db.query(
      'recipe_price_history',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
      orderBy: 'changed_at DESC',
    );
    _recipePriceHistory = rows.map(RecipePriceHistory.fromMap).toList();
    notifyListeners();
  }

  Future<void> loadIngredientPriceHistory(String ingredientId) async {
    final db = await _db;
    final rows = await db.query(
      'ingredient_price_history',
      where: 'ingredient_id = ?',
      whereArgs: [ingredientId],
      orderBy: 'changed_at DESC',
    );
    _ingredientPriceHistory = rows.map(IngredientPriceHistory.fromMap).toList();
    notifyListeners();
  }

  // ─── Ingredients ─────────────────────────────────────────────────────────

  Future<void> addIngredient(
      String name, double unitCost, String unit, bool unitEnabled) async {
    final ingredient = Ingredient(
      id: _uuid.v4(),
      name: name,
      unitCost: unitCost,
      unit: unit,
      unitEnabled: unitEnabled,
    );
    final db = await _db;
    await db.insert('ingredients', ingredient.toMap());
    _ingredients.add(ingredient);
    notifyListeners();
  }

  Future<void> updateIngredient(Ingredient updated) async {
    final db = await _db;
    final old = _ingredients.firstWhere((i) => i.id == updated.id);

    // Record price history if cost changed
    if (old.unitCost != updated.unitCost) {
      final history = IngredientPriceHistory(
        id: _uuid.v4(),
        ingredientId: updated.id,
        oldCost: old.unitCost,
        newCost: updated.unitCost,
        changedAt: DateTime.now(),
      );
      await db.insert('ingredient_price_history', history.toMap());
    }

    await db.update('ingredients', updated.toMap(),
        where: 'id = ?', whereArgs: [updated.id]);
    final idx = _ingredients.indexWhere((i) => i.id == updated.id);
    if (idx != -1) _ingredients[idx] = updated;
    notifyListeners();
  }

  Future<void> deleteIngredient(String id) async {
    final db = await _db;
    await db.delete('ingredients', where: 'id = ?', whereArgs: [id]);
    _ingredients.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  // ─── Recipes ─────────────────────────────────────────────────────────────

  Future<void> addRecipe(Recipe recipe) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert('recipes', recipe.toMap());
      for (final ri in recipe.ingredients) {
        await txn.insert('recipe_ingredients', ri.toMap(recipe.id));
      }
    });
    _recipes.add(recipe);
    notifyListeners();
  }

  Future<void> updateRecipe(Recipe updated) async {
    final db = await _db;
    final old = _recipes.firstWhere((r) => r.id == updated.id);

    await db.transaction((txn) async {
      if (old.sellingPriceBatch != updated.sellingPriceBatch ||
          old.ingredientCost != updated.ingredientCost) {
        final history = RecipePriceHistory(
          id: _uuid.v4(),
          recipeId: updated.id,
          oldPrice: old.sellingPriceBatch,
          newPrice: updated.sellingPriceBatch,
          oldCost: old.ingredientCost,
          newCost: updated.ingredientCost,
          changedAt: DateTime.now(),
        );
        await txn.insert('recipe_price_history', history.toMap());
      }
      await txn.update('recipes', updated.toMap(),
          where: 'id = ?', whereArgs: [updated.id]);
      await txn.delete('recipe_ingredients',
          where: 'recipe_id = ?', whereArgs: [updated.id]);
      for (final ri in updated.ingredients) {
        await txn.insert('recipe_ingredients', ri.toMap(updated.id));
      }
    });

    final idx = _recipes.indexWhere((r) => r.id == updated.id);
    if (idx != -1) _recipes[idx] = updated;
    notifyListeners();
  }

  Future<void> deleteRecipe(String id) async {
    final db = await _db;
    await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
    _recipes.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  Recipe buildNewRecipe({
    required String name,
    required String category,
    required List<RecipeIngredient> ingredients,
    double laborCost = 0,
    double markupPercent = 30,
    int pieces = 1,
    double totalWeight = 0,
    WeightUnit weightUnit = WeightUnit.kilo,
  }) {
    final now = DateTime.now();
    return Recipe(
      id: _uuid.v4(),
      name: name,
      category: category,
      ingredients: ingredients,
      laborCost: laborCost,
      markupPercent: markupPercent,
      pieces: pieces,
      totalWeight: totalWeight,
      weightUnit: weightUnit,
      createdAt: now,
      updatedAt: now,
    );
  }
}
