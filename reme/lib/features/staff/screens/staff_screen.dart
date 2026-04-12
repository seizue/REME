import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/staff.dart';
import '../providers/staff_provider.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().loadStaff();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    return Scaffold(
      appBar: AppBar(
        title: const Text('REME'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => _showForm(context, null),
              icon: const Icon(Icons.add, size: 18, color: AppTheme.primary),
              label: const Text('Add',
                  style: TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: Consumer<StaffProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Header subtitle + total
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                color: context.isDark ? AppTheme.darkSurface : Colors.white,
                child: Row(
                  children: [
                    Text('Staff & Labor',
                        style: TextStyle(
                            color: context.onSurfaceMuted, fontSize: 12)),
                    const Spacer(),
                    if (provider.staff.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Monthly: ${fmt.format(provider.totalMonthlySalary)}',
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: provider.staff.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.people_outline_rounded,
                                  size: 48,
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.5)),
                            ),
                            const SizedBox(height: 16),
                            Text('No staff yet',
                                style: TextStyle(
                                    color: context.onSurface,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('Tap Add to add your first staff member',
                                style: TextStyle(
                                    color: context.onSurfaceMuted,
                                    fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: provider.staff.length,
                        itemBuilder: (_, i) {
                          final s = provider.staff[i];
                          return _StaffTile(
                            staff: s,
                            fmt: fmt,
                            onEdit: () => _showForm(context, s),
                            onDelete: () =>
                                _confirmDelete(context, provider, s),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, StaffProvider provider, Staff s) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Staff'),
        content: Text('Remove "${s.name}" from staff?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteStaff(s.id);
              Navigator.pop(context);
            },
            child:
                const Text('Remove', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, Staff? staff) {
    final nameCtrl = TextEditingController(text: staff?.name ?? '');
    final roleCtrl = TextEditingController(text: staff?.role ?? '');
    final salaryCtrl = TextEditingController(
        text: staff != null ? staff.salary.toString() : '');
    PayPeriod period = staff?.payPeriod ?? PayPeriod.monthly;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: sheetCtx.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: sheetCtx.surfaceVariant,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(staff == null ? 'Add Staff' : 'Edit Staff',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: roleCtrl,
                decoration: const InputDecoration(
                    labelText: 'Role (optional)',
                    prefixIcon: Icon(Icons.work_outline)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: salaryCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Salary Amount',
                    prefixIcon: Icon(Icons.payments_outlined)),
              ),
              const SizedBox(height: 12),
              // Pay period selector
              Text('Pay Period',
                  style:
                      TextStyle(color: sheetCtx.onSurfaceMuted, fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                children: PayPeriod.values.map((p) {
                  final selected = period == p;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setSheetState(() => period = p),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.primary
                              : sheetCtx.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          p == PayPeriod.monthly
                              ? 'Monthly'
                              : p == PayPeriod.semiMonthly
                                  ? 'Semi-Mo.'
                                  : 'Weekly',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : sheetCtx.onSurfaceMuted,
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final provider = context.read<StaffProvider>();
                  final name = nameCtrl.text.trim();
                  final salary = double.tryParse(salaryCtrl.text) ?? 0;
                  if (name.isEmpty || salary <= 0) return;
                  final s = Staff(
                    id: staff?.id ?? '',
                    name: name,
                    role: roleCtrl.text.trim(),
                    salary: salary,
                    payPeriod: period,
                  );
                  if (staff == null) {
                    provider.addStaff(s);
                  } else {
                    provider.updateStaff(s);
                  }
                  Navigator.pop(sheetCtx);
                },
                child: Text(staff == null ? 'Add Staff' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffTile extends StatelessWidget {
  final Staff staff;
  final NumberFormat fmt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StaffTile(
      {required this.staff,
      required this.fmt,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border:
            context.isDark ? Border.all(color: context.surfaceVariant) : null,
        boxShadow: context.isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
          child: Text(staff.name[0].toUpperCase(),
              style: const TextStyle(
                  color: AppTheme.primary, fontWeight: FontWeight.w700)),
        ),
        title: Text(staff.name,
            style: TextStyle(
                color: context.onSurface, fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (staff.role.isNotEmpty)
              Text(staff.role,
                  style:
                      TextStyle(color: context.onSurfaceMuted, fontSize: 12)),
            Row(
              children: [
                Text(fmt.format(staff.salary),
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(width: 4),
                Text('/ ${staff.payPeriod.label}',
                    style:
                        TextStyle(color: context.onSurfaceMuted, fontSize: 11)),
              ],
            ),
            Text('≈ ${fmt.format(staff.dailyCost)} / day',
                style: TextStyle(color: context.onSurfaceMuted, fontSize: 11)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: AppTheme.primary, size: 20),
                onPressed: onEdit),
            IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppTheme.error, size: 20),
                onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
