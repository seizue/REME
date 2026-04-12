import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import '../../../models/staff.dart';

class StaffProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  List<Staff> _staff = [];

  List<Staff> get staff => _staff;

  double get totalMonthlySalary =>
      _staff.fold(0.0, (s, e) => s + _toMonthly(e));

  double _toMonthly(Staff s) {
    switch (s.payPeriod) {
      case PayPeriod.monthly:
        return s.salary;
      case PayPeriod.semiMonthly:
        return s.salary * 2;
      case PayPeriod.weekly:
        return s.salary * 4.33;
    }
  }

  /// Total labor cost for a date range
  double laborCostForRange(DateTime from, DateTime to) {
    final days = to.difference(from).inDays + 1;
    return _staff.fold(0.0, (s, e) => s + e.costForDays(days));
  }

  Future<void> loadStaff() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('staff', orderBy: 'name ASC');
    _staff = rows.map(Staff.fromMap).toList();
    notifyListeners();
  }

  Future<void> addStaff(Staff s) async {
    final db = await DatabaseHelper.instance.database;
    final staff = Staff(
      id: _uuid.v4(),
      name: s.name,
      role: s.role,
      salary: s.salary,
      payPeriod: s.payPeriod,
    );
    await db.insert('staff', staff.toMap());
    _staff.add(staff);
    notifyListeners();
  }

  Future<void> updateStaff(Staff updated) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('staff', updated.toMap(),
        where: 'id = ?', whereArgs: [updated.id]);
    final idx = _staff.indexWhere((s) => s.id == updated.id);
    if (idx != -1) _staff[idx] = updated;
    notifyListeners();
  }

  Future<void> deleteStaff(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('staff', where: 'id = ?', whereArgs: [id]);
    _staff.removeWhere((s) => s.id == id);
    notifyListeners();
  }
}
