enum PayPeriod { monthly, semiMonthly, weekly }

extension PayPeriodLabel on PayPeriod {
  String get label {
    switch (this) {
      case PayPeriod.monthly:
        return 'Monthly';
      case PayPeriod.semiMonthly:
        return 'Semi-Monthly (15th & 30th)';
      case PayPeriod.weekly:
        return 'Weekly';
    }
  }

  // Working days per period
  double get workingDays {
    switch (this) {
      case PayPeriod.monthly:
        return 26;
      case PayPeriod.semiMonthly:
        return 13;
      case PayPeriod.weekly:
        return 6;
    }
  }
}

class Staff {
  final String id;
  final String name;
  final String role;
  final double salary;
  final PayPeriod payPeriod;

  const Staff({
    required this.id,
    required this.name,
    required this.role,
    required this.salary,
    required this.payPeriod,
  });

  /// Cost per day
  double get dailyCost => salary / payPeriod.workingDays;

  /// Cost for a given number of days
  double costForDays(int days) => dailyCost * days;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'role': role,
        'salary': salary,
        'pay_period': payPeriod.name,
      };

  factory Staff.fromMap(Map<String, dynamic> m) => Staff(
        id: m['id'],
        name: m['name'],
        role: m['role'] ?? '',
        salary: (m['salary'] as num).toDouble(),
        payPeriod: PayPeriod.values.firstWhere(
          (p) => p.name == m['pay_period'],
          orElse: () => PayPeriod.monthly,
        ),
      );

  Staff copyWith(
          {String? name, String? role, double? salary, PayPeriod? payPeriod}) =>
      Staff(
        id: id,
        name: name ?? this.name,
        role: role ?? this.role,
        salary: salary ?? this.salary,
        payPeriod: payPeriod ?? this.payPeriod,
      );
}
