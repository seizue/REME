import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/ingredient.dart';
import '../providers/costing_provider.dart';

class IngredientsScreen extends StatefulWidget {
  const IngredientsScreen({super.key});

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
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
      body: Consumer<CostingProvider>(
        builder: (context, provider, _) {
          final filtered = provider.ingredients
              .where(
                  (i) => i.name.toLowerCase().contains(_search.toLowerCase()))
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search ingredients...',
                    prefixIcon:
                        Icon(Icons.search, color: context.onSurfaceMuted),
                    isDense: true,
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text('${filtered.length} items',
                        style: TextStyle(
                            color: context.onSurfaceMuted, fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 64, color: context.onSurfaceMuted),
                            const SizedBox(height: 12),
                            Text('No ingredients yet',
                                style:
                                    TextStyle(color: context.onSurfaceMuted)),
                            const SizedBox(height: 4),
                            Text('Tap + to add ingredients',
                                style: TextStyle(
                                    color: context.onSurfaceMuted,
                                    fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final ing = filtered[i];
                          return _IngredientTile(
                            ingredient: ing,
                            onEdit: () => _showForm(context, ing),
                            onDelete: () =>
                                _confirmDelete(context, provider, ing),
                            onViewHistory: () =>
                                _showPriceHistory(context, provider, ing),
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

  void _confirmDelete(
      BuildContext context, CostingProvider provider, Ingredient ing) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Ingredient'),
        content: Text('Remove "${ing.name}" from inventory?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteIngredient(ing.id);
              Navigator.pop(context);
            },
            child:
                const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _showPriceHistory(
      BuildContext context, CostingProvider provider, Ingredient ing) async {
    await provider.loadIngredientPriceHistory(ing.id);
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _IngredientHistorySheet(ingredient: ing),
      ),
    );
  }

  void _showForm(BuildContext context, Ingredient? ingredient) {
    final nameCtrl = TextEditingController(text: ingredient?.name ?? '');
    final costCtrl = TextEditingController(
        text: ingredient != null ? ingredient.unitCost.toString() : '');
    final unitCtrl = TextEditingController(text: ingredient?.unit ?? '');
    bool unitEnabled = ingredient?.unitEnabled ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => Container(
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
          child: SingleChildScrollView(
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
                Text(
                  ingredient == null ? 'Add Ingredient' : 'Edit Ingredient',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                      labelText: 'Ingredient Name',
                      prefixIcon: Icon(Icons.egg_outlined)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: costCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Cost per unit',
                      prefixIcon: Icon(Icons.payments_outlined)),
                ),
                const SizedBox(height: 12),
                // Unit toggle
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                      color: sheetCtx.surfaceVariant,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.straighten,
                          size: 20, color: AppTheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text('Unit tracking',
                              style: TextStyle(
                                  color: sheetCtx.onSurface,
                                  fontWeight: FontWeight.w500))),
                      Text(unitEnabled ? 'On' : 'Off',
                          style: TextStyle(
                              color: sheetCtx.onSurfaceMuted, fontSize: 12)),
                      const SizedBox(width: 8),
                      Switch(
                        value: unitEnabled,
                        activeThumbColor: AppTheme.primary,
                        onChanged: (v) => setSheet(() {
                          unitEnabled = v;
                          if (!v) unitCtrl.clear();
                        }),
                      ),
                    ],
                  ),
                ),
                if (unitEnabled) ...[
                  const SizedBox(height: 12),
                  Text('Select Unit',
                      style: TextStyle(
                          color: sheetCtx.onSurfaceMuted, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...kCommonUnits.map((u) {
                        final isSelected = unitCtrl.text == u;
                        return GestureDetector(
                          onTap: () => setSheet(() => unitCtrl.text = u),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primary
                                  : sheetCtx.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : sheetCtx.surfaceVariant),
                            ),
                            child: Text(u,
                                style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : sheetCtx.onSurface,
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400)),
                          ),
                        );
                      }),
                      GestureDetector(
                        onTap: () => setSheet(() => unitCtrl.clear()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: !kCommonUnits.contains(unitCtrl.text) &&
                                    unitCtrl.text.isNotEmpty
                                ? AppTheme.primary
                                : sheetCtx.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: sheetCtx.surfaceVariant),
                          ),
                          child: Text('Custom',
                              style: TextStyle(
                                  color:
                                      !kCommonUnits.contains(unitCtrl.text) &&
                                              unitCtrl.text.isNotEmpty
                                          ? Colors.white
                                          : sheetCtx.onSurfaceMuted,
                                  fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                  if (!kCommonUnits.contains(unitCtrl.text)) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: unitCtrl,
                      onChanged: (_) => setSheet(() {}),
                      decoration: const InputDecoration(
                          labelText: 'Custom unit (e.g. bottle, sachet)',
                          prefixIcon: Icon(Icons.edit_outlined)),
                    ),
                  ],
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final provider = context.read<CostingProvider>();
                    final name = nameCtrl.text.trim();
                    final cost = double.tryParse(costCtrl.text) ?? 0;
                    final unit = unitEnabled ? unitCtrl.text.trim() : '';
                    if (name.isEmpty) return;
                    if (ingredient == null) {
                      provider.addIngredient(name, cost, unit, unitEnabled);
                    } else {
                      provider.updateIngredient(ingredient.copyWith(
                          name: name,
                          unitCost: cost,
                          unit: unit,
                          unitEnabled: unitEnabled));
                    }
                    Navigator.pop(sheetCtx);
                  },
                  child: Text(ingredient == null ? 'Add Ingredient' : 'Update'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Ingredient Tile ─────────────────────────────────────────────────────────

class _IngredientTile extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewHistory;

  const _IngredientTile({
    required this.ingredient,
    required this.onEdit,
    required this.onDelete,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
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
          child: Text(
            ingredient.name[0].toUpperCase(),
            style: const TextStyle(
                color: AppTheme.primary, fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(ingredient.name,
            style: TextStyle(
                color: context.onSurface, fontWeight: FontWeight.w600)),
        subtitle: Text(
            ingredient.unitEnabled
                ? '${fmt.format(ingredient.unitCost)} / ${ingredient.unit}'
                : fmt.format(ingredient.unitCost),
            style: TextStyle(color: context.onSurfaceMuted, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.history,
                  color: AppTheme.secondary, size: 20),
              onPressed: onViewHistory,
              tooltip: 'Price History',
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: AppTheme.primary, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppTheme.error, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Price History Sheet ──────────────────────────────────────────────────────

class _IngredientHistorySheet extends StatelessWidget {
  final Ingredient ingredient;
  const _IngredientHistorySheet({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('MMM d, yyyy  h:mm a');
    final history = context.watch<CostingProvider>().ingredientPriceHistory;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, ctrl) => Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: context.surfaceVariant,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                  child: Text(ingredient.name[0].toUpperCase(),
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ingredient.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                    Text(
                        'Current: ₱${fmt.format(ingredient.unitCost)} / ${ingredient.unit}',
                        style: TextStyle(
                            color: context.onSurfaceMuted, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: context.surfaceVariant),
          Expanded(
            child: history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history,
                            size: 48, color: context.onSurfaceMuted),
                        const SizedBox(height: 8),
                        Text('No price changes recorded',
                            style: TextStyle(color: context.onSurfaceMuted)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: ctrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: history.length,
                    itemBuilder: (_, i) {
                      final h = history[i];
                      final isUp = h.diff >= 0;
                      final color =
                          isUp ? AppTheme.priceUp : AppTheme.priceDown;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: i == 0
                              ? Border.all(
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.4))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                                isUp
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: color,
                                size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(dateFmt.format(h.changedAt),
                                      style: TextStyle(
                                          color: context.onSurfaceMuted,
                                          fontSize: 11)),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text('₱${fmt.format(h.oldCost)}',
                                          style: TextStyle(
                                              color: context.onSurfaceMuted,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              fontSize: 13)),
                                      const SizedBox(width: 6),
                                      Text('→',
                                          style: TextStyle(
                                              color: context.onSurfaceMuted)),
                                      const SizedBox(width: 6),
                                      Text('₱${fmt.format(h.newCost)}',
                                          style: TextStyle(
                                              color: color,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${isUp ? '+' : ''}${h.changePercent.toStringAsFixed(1)}%',
                                style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
