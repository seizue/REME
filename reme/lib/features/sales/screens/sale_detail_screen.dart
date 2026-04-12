import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/sale.dart';
import 'new_sale_screen.dart';

class SaleDetailScreen extends StatelessWidget {
  final SaleSession session;
  const SaleDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('MMM d, yyyy  h:mm a');
    final profit = session.totalProfit;

    return Scaffold(
      appBar: AppBar(
        title: Text(session.label),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => NewSaleScreen(session: session)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(dateFmt.format(session.date),
              style: TextStyle(color: context.onSurfaceMuted, fontSize: 13)),
          const SizedBox(height: 16),

          // Summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.success.withValues(alpha: 0.12),
                  context.surface
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppTheme.success.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                _Row(
                    label: 'Total Revenue',
                    value: fmt.format(session.totalRevenue),
                    color: AppTheme.success),
                if (session.deliveryFee > 0) ...[
                  const SizedBox(height: 4),
                  _Row(
                      label: '  ↳ Delivery fee',
                      value: '+${fmt.format(session.deliveryFee)}',
                      color: AppTheme.success,
                      small: true),
                ],
                const SizedBox(height: 8),
                _Row(
                    label: 'Recipe Cost',
                    value: fmt.format(session.totalCost),
                    color: AppTheme.warning),
                if (session.totalExpenses > 0) ...[
                  const SizedBox(height: 8),
                  _Row(
                      label: 'Overhead Expenses',
                      value: '-${fmt.format(session.totalExpenses)}',
                      color: AppTheme.error),
                ],
                Divider(height: 20, color: context.surfaceVariant),
                _Row(
                    label: 'Net Profit',
                    value: fmt.format(profit),
                    color: profit >= 0 ? AppTheme.success : AppTheme.error),
                const SizedBox(height: 4),
                _Row(
                    label: 'Profit Margin',
                    value: '${session.profitMargin.toStringAsFixed(1)}%',
                    color: profit >= 0 ? AppTheme.success : AppTheme.error),
                const SizedBox(height: 4),
                _Row(
                    label: 'Items Sold',
                    value: '${session.totalItemsSold} pcs',
                    color: AppTheme.primary),
              ],
            ),
          ),

          // Expenses breakdown
          if (session.expenses.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Overhead Expenses',
                style: TextStyle(
                    color: context.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            const SizedBox(height: 10),
            ...session.expenses.map((exp) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: context.isDark
                        ? Border.all(color: context.surfaceVariant)
                        : null,
                    boxShadow: context.isDark
                        ? []
                        : [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(exp.category,
                            style: const TextStyle(
                                color: AppTheme.error,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(exp.label,
                              style: TextStyle(
                                  color: context.onSurface,
                                  fontWeight: FontWeight.w500))),
                      Text(fmt.format(exp.amount),
                          style: const TextStyle(
                              color: AppTheme.error,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
          ],

          const SizedBox(height: 20),
          Text('Items Breakdown',
              style: TextStyle(
                  color: context.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(height: 10),

          ...session.items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: context.isDark
                      ? Border.all(color: context.surfaceVariant)
                      : null,
                  boxShadow: context.isDark
                      ? []
                      : [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2))
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              AppTheme.primary.withValues(alpha: 0.12),
                          child: Text(item.recipeName[0].toUpperCase(),
                              style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(item.recipeName,
                                style: TextStyle(
                                    color: context.onSurface,
                                    fontWeight: FontWeight.w600))),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('×${item.quantity}',
                              style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(height: 1, color: context.surfaceVariant),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _MiniStat(
                            label: 'Revenue',
                            value: fmt.format(item.totalRevenue),
                            color: AppTheme.success),
                        const SizedBox(width: 16),
                        _MiniStat(
                            label: 'Cost',
                            value: fmt.format(item.totalCost),
                            color: AppTheme.warning),
                        const SizedBox(width: 16),
                        _MiniStat(
                            label: 'Profit',
                            value: fmt.format(item.totalProfit),
                            color: item.totalProfit >= 0
                                ? AppTheme.success
                                : AppTheme.error),
                        const SizedBox(width: 16),
                        _MiniStat(
                            label: 'Margin',
                            value: '${item.profitMargin.toStringAsFixed(1)}%',
                            color: item.totalProfit >= 0
                                ? AppTheme.success
                                : AppTheme.error),
                      ],
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool small;
  const _Row(
      {required this.label,
      required this.value,
      required this.color,
      this.small = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: context.onSurfaceMuted, fontSize: small ? 12 : 14)),
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: small ? 12 : 15)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: context.onSurfaceMuted, fontSize: 10)),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 12)),
      ],
    );
  }
}
