class SaleItem {
  final String id;
  final String saleSessionId;
  final String recipeId;
  final String recipeName;
  final double sellingPrice;
  final double costPrice;
  final int quantity;

  const SaleItem({
    required this.id,
    required this.saleSessionId,
    required this.recipeId,
    required this.recipeName,
    required this.sellingPrice,
    required this.costPrice,
    required this.quantity,
  });

  double get totalRevenue => sellingPrice * quantity;
  double get totalCost => costPrice * quantity;
  double get totalProfit => totalRevenue - totalCost;
  double get profitMargin =>
      totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'sale_session_id': saleSessionId,
        'recipe_id': recipeId,
        'recipe_name': recipeName,
        'selling_price': sellingPrice,
        'cost_price': costPrice,
        'quantity': quantity,
      };

  factory SaleItem.fromMap(Map<String, dynamic> m) => SaleItem(
        id: m['id'],
        saleSessionId: m['sale_session_id'],
        recipeId: m['recipe_id'],
        recipeName: m['recipe_name'],
        sellingPrice: (m['selling_price'] as num).toDouble(),
        costPrice: (m['cost_price'] as num).toDouble(),
        quantity: m['quantity'] as int,
      );
}

class SaleExpense {
  final String id;
  final String saleSessionId;
  final String label; // e.g. "Boxes", "Gasoline", "Disposable utensils"
  final String category; // Packaging, Delivery, Supplies, Other
  final double amount;

  const SaleExpense({
    required this.id,
    required this.saleSessionId,
    required this.label,
    required this.category,
    required this.amount,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'sale_session_id': saleSessionId,
        'label': label,
        'category': category,
        'amount': amount,
      };

  factory SaleExpense.fromMap(Map<String, dynamic> m) => SaleExpense(
        id: m['id'],
        saleSessionId: m['sale_session_id'],
        label: m['label'],
        category: m['category'],
        amount: (m['amount'] as num).toDouble(),
      );
}

class SaleSession {
  final String id;
  final String label;
  final DateTime date;
  final List<SaleItem> items;
  final double deliveryFee;
  final List<SaleExpense> expenses;

  const SaleSession({
    required this.id,
    required this.label,
    required this.date,
    required this.items,
    this.deliveryFee = 0,
    this.expenses = const [],
  });

  double get totalRevenue =>
      items.fold(0.0, (s, i) => s + i.totalRevenue) + deliveryFee;
  double get totalCost => items.fold(0.0, (s, i) => s + i.totalCost);
  double get totalExpenses => expenses.fold(0.0, (s, e) => s + e.amount);
  double get totalProfit => totalRevenue - totalCost - totalExpenses;
  double get profitMargin =>
      totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0;
  int get totalItemsSold => items.fold(0, (s, i) => s + i.quantity);

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'date': date.toIso8601String(),
        'delivery_fee': deliveryFee,
      };

  factory SaleSession.fromMap(
    Map<String, dynamic> m,
    List<SaleItem> items,
    List<SaleExpense> expenses,
  ) =>
      SaleSession(
        id: m['id'],
        label: m['label'],
        date: DateTime.parse(m['date']),
        items: items,
        deliveryFee: (m['delivery_fee'] as num?)?.toDouble() ?? 0,
        expenses: expenses,
      );
}

// Preset expense categories
const kExpenseCategories = [
  'Packaging',
  'Delivery',
  'Supplies',
  'Utilities',
  'Other',
];
