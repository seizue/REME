import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/sales_provider.dart';
import '../../staff/providers/staff_provider.dart';
import '../../../models/sale.dart';
import 'new_sale_screen.dart';
import 'sale_detail_screen.dart';

enum _DateFilter { today, week, month, custom }

class SalesDashboard extends StatefulWidget {
  const SalesDashboard({super.key});

  @override
  State<SalesDashboard> createState() => _SalesDashboardState();
}

class _SalesDashboardState extends State<SalesDashboard> {
  _DateFilter _filter = _DateFilter.month;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesProvider>().loadSessions();
      context.read<StaffProvider>().loadStaff();
    });
  }

  DateTimeRange get _range {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    switch (_filter) {
      case _DateFilter.today:
        return DateTimeRange(
            start: DateTime(now.year, now.month, now.day), end: endOfDay);
      case _DateFilter.week:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
            start: DateTime(start.year, start.month, start.day), end: endOfDay);
      case _DateFilter.month:
        return DateTimeRange(
            start: DateTime(now.year, now.month, 1), end: endOfDay);
      case _DateFilter.custom:
        if (_customRange == null) {
          return DateTimeRange(
              start: DateTime(now.year, now.month, 1), end: endOfDay);
        }
        return DateTimeRange(
          start: _customRange!.start,
          end: DateTime(_customRange!.end.year, _customRange!.end.month,
              _customRange!.end.day, 23, 59, 59),
        );
    }
  }

  List<SaleSession> _filtered(List<SaleSession> sessions) {
    final r = _range;
    return sessions
        .where((s) => !s.date.isBefore(r.start) && !s.date.isAfter(r.end))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('MMM d, yyyy');

    return Consumer2<SalesProvider, StaffProvider>(
      builder: (context, salesProvider, staffProvider, _) {
        if (salesProvider.loading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final filtered = _filtered(salesProvider.sessions);
        final revenue = filtered.fold(0.0, (s, e) => s + e.totalRevenue);
        final cost = filtered.fold(0.0, (s, e) => s + e.totalCost);
        final expenses = filtered.fold(0.0, (s, e) => s + e.totalExpenses);
        final r = _range;
        final laborCost = staffProvider.laborCostForRange(r.start, r.end);
        final netProfit = revenue - cost - expenses - laborCost;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 20,
                    right: 20,
                    bottom: 16,
                  ),
                  decoration: BoxDecoration(
                    color: context.isDark ? AppTheme.darkSurface : Colors.white,
                    boxShadow: context.isDark
                        ? []
                        : [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2))
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.point_of_sale_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('REME',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800)),
                              Text('Sales & Revenue',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: context.onSurfaceMuted)),
                            ],
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const NewSaleScreen())),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(20)),
                              child: const Row(
                                children: [
                                  Icon(Icons.add,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text('New Sale',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Date filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                                label: 'Today',
                                selected: _filter == _DateFilter.today,
                                onTap: () => setState(
                                    () => _filter = _DateFilter.today)),
                            const SizedBox(width: 8),
                            _FilterChip(
                                label: 'This Week',
                                selected: _filter == _DateFilter.week,
                                onTap: () =>
                                    setState(() => _filter = _DateFilter.week)),
                            const SizedBox(width: 8),
                            _FilterChip(
                                label: 'This Month',
                                selected: _filter == _DateFilter.month,
                                onTap: () => setState(
                                    () => _filter = _DateFilter.month)),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: _filter == _DateFilter.custom &&
                                      _customRange != null
                                  ? '${dateFmt.format(_customRange!.start)} – ${dateFmt.format(_customRange!.end)}'
                                  : 'Custom',
                              selected: _filter == _DateFilter.custom,
                              onTap: () async {
                                final picked = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                  initialDateRange: _customRange,
                                  builder: (ctx, child) => Theme(
                                    data: Theme.of(ctx).copyWith(
                                      colorScheme: Theme.of(ctx)
                                          .colorScheme
                                          .copyWith(primary: AppTheme.primary),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _customRange = picked;
                                    _filter = _DateFilter.custom;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Summary cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: _SummaryCard(
                                  label: 'Revenue',
                                  value: fmt.format(revenue),
                                  icon: Icons.trending_up_rounded,
                                  color: AppTheme.success)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _SummaryCard(
                                  label: 'Net Profit',
                                  value: fmt.format(netProfit),
                                  icon: Icons.savings_outlined,
                                  color: netProfit >= 0
                                      ? AppTheme.primary
                                      : AppTheme.error)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: _SummaryCard(
                                  label: 'Recipe Cost',
                                  value: fmt.format(cost),
                                  icon: Icons.restaurant_menu_rounded,
                                  color: AppTheme.warning)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _SummaryCard(
                                  label: 'Overhead',
                                  value: fmt.format(expenses),
                                  icon: Icons.receipt_long_outlined,
                                  color: AppTheme.error)),
                        ],
                      ),
                      if (staffProvider.staff.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _SummaryCard(
                          label:
                              'Labor Cost (${r.end.difference(r.start).inDays + 1} days)',
                          value: fmt.format(laborCost),
                          icon: Icons.people_outline_rounded,
                          color: Colors.purple,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Sessions label
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Text('Sessions',
                          style: TextStyle(
                              color: context.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10)),
                        child: Text('${filtered.length}',
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),

              // Sessions list
              if (filtered.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle),
                          child: Icon(Icons.point_of_sale_rounded,
                              size: 48,
                              color: AppTheme.primary.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(height: 16),
                        Text('No sales in this period',
                            style: TextStyle(
                                color: context.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Try a different date range or add a new sale',
                            style: TextStyle(
                                color: context.onSurfaceMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final session = filtered[i];
                        return _SessionCard(
                          session: session,
                          dateFmt: dateFmt,
                          fmt: fmt,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      SaleDetailScreen(session: session))),
                          onEdit: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      NewSaleScreen(session: session))),
                          onDelete: () =>
                              _confirmDelete(context, salesProvider, session),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context, SalesProvider provider, SaleSession session) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text('Remove "${session.label}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteSession(session.id);
              Navigator.pop(context);
            },
            child:
                const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : context.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : context.onSurfaceMuted,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            context.isDark ? Border.all(color: context.surfaceVariant) : null,
        boxShadow: context.isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(label,
                    style:
                        TextStyle(color: context.onSurfaceMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final SaleSession session;
  final DateFormat dateFmt;
  final NumberFormat fmt;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _SessionCard(
      {required this.session,
      required this.dateFmt,
      required this.fmt,
      required this.onTap,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
          border:
              context.isDark ? Border.all(color: context.surfaceVariant) : null,
          boxShadow: context.isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(session.label,
                          style: TextStyle(
                              color: context.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                      Text(dateFmt.format(session.date),
                          style: TextStyle(
                              color: context.onSurfaceMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('${session.totalItemsSold} sold',
                      style: const TextStyle(
                          color: AppTheme.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      color: AppTheme.primary, size: 20),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: context.onSurfaceMuted, size: 20),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: context.surfaceVariant),
            const SizedBox(height: 12),
            Row(
              children: [
                _Chip(
                    label: 'Revenue',
                    value: fmt.format(session.totalRevenue),
                    color: AppTheme.success),
                const SizedBox(width: 16),
                _Chip(
                    label: 'Cost',
                    value: fmt.format(session.totalCost),
                    color: AppTheme.warning),
                const SizedBox(width: 16),
                _Chip(
                    label: 'Profit',
                    value: fmt.format(session.totalProfit),
                    color: session.totalProfit >= 0
                        ? AppTheme.primary
                        : AppTheme.error),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Chip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: context.onSurfaceMuted, fontSize: 10)),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
