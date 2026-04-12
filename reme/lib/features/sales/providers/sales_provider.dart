import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import '../../../models/sale.dart';

class SalesProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  List<SaleSession> _sessions = [];
  bool _loading = false;

  List<SaleSession> get sessions => _sessions;
  bool get loading => _loading;

  double get allTimeRevenue =>
      _sessions.fold(0.0, (s, e) => s + e.totalRevenue);
  double get allTimeProfit => _sessions.fold(0.0, (s, e) => s + e.totalProfit);

  Future<void> loadSessions() async {
    _loading = true;
    notifyListeners();
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('sale_sessions', orderBy: 'date DESC');
    final List<SaleSession> loaded = [];
    for (final row in rows) {
      final itemRows = await db.query('sale_items',
          where: 'sale_session_id = ?', whereArgs: [row['id']]);
      final expenseRows = await db.query('sale_expenses',
          where: 'sale_session_id = ?', whereArgs: [row['id']]);
      loaded.add(SaleSession.fromMap(
        row,
        itemRows.map(SaleItem.fromMap).toList(),
        expenseRows.map(SaleExpense.fromMap).toList(),
      ));
    }
    _sessions = loaded;
    _loading = false;
    notifyListeners();
  }

  Future<SaleSession> createSession({
    required String label,
    required List<SaleItem> items,
    required double deliveryFee,
    required List<SaleExpense> expenses,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final session = SaleSession(
      id: _uuid.v4(),
      label: label,
      date: DateTime.now(),
      items: items,
      deliveryFee: deliveryFee,
      expenses: expenses,
    );
    await db.transaction((txn) async {
      await txn.insert('sale_sessions', session.toMap());
      for (final item in items) {
        await txn.insert('sale_items', item.toMap());
      }
      for (final expense in expenses) {
        await txn.insert('sale_expenses', expense.toMap());
      }
    });
    _sessions.insert(0, session);
    notifyListeners();
    return session;
  }

  Future<void> deleteSession(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('sale_sessions', where: 'id = ?', whereArgs: [id]);
    _sessions.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  Future<void> updateSession({
    required String id,
    required String label,
    required List<SaleItem> items,
    required double deliveryFee,
    required List<SaleExpense> expenses,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final idx = _sessions.indexWhere((s) => s.id == id);
    if (idx == -1) return;

    final updated = SaleSession(
      id: id,
      label: label,
      date: _sessions[idx].date,
      items: items,
      deliveryFee: deliveryFee,
      expenses: expenses,
    );

    await db.transaction((txn) async {
      await txn.update('sale_sessions', updated.toMap(),
          where: 'id = ?', whereArgs: [id]);
      await txn
          .delete('sale_items', where: 'sale_session_id = ?', whereArgs: [id]);
      await txn.delete('sale_expenses',
          where: 'sale_session_id = ?', whereArgs: [id]);
      for (final item in items) {
        await txn.insert('sale_items', item.toMap());
      }
      for (final expense in expenses) {
        await txn.insert('sale_expenses', expense.toMap());
      }
    });

    _sessions[idx] = updated;
    notifyListeners();
  }

  SaleItem buildItem({
    required String sessionId,
    required String recipeId,
    required String recipeName,
    required double sellingPrice,
    required double costPrice,
    required int quantity,
  }) =>
      SaleItem(
        id: _uuid.v4(),
        saleSessionId: sessionId,
        recipeId: recipeId,
        recipeName: recipeName,
        sellingPrice: sellingPrice,
        costPrice: costPrice,
        quantity: quantity,
      );

  SaleExpense buildExpense({
    required String sessionId,
    required String label,
    required String category,
    required double amount,
  }) =>
      SaleExpense(
        id: _uuid.v4(),
        saleSessionId: sessionId,
        label: label,
        category: category,
        amount: amount,
      );
}
