import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/recipe.dart';
import '../../../models/sale.dart';
import '../../costing/providers/costing_provider.dart';
import '../providers/sales_provider.dart';

class NewSaleScreen extends StatefulWidget {
  final SaleSession? session; // null = new, non-null = edit
  const NewSaleScreen({super.key, this.session});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _deliveryCtrl;
  final Map<String, int> _quantities = {};
  final Map<String, double?> _customPrices = {};
  final List<_ExpenseEntry> _expenses = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.session;
    _labelCtrl = TextEditingController(
      text: s?.label ??
          'Sale ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
    );
    _deliveryCtrl = TextEditingController(
      text: s != null && s.deliveryFee > 0 ? s.deliveryFee.toString() : '',
    );
    if (s != null) {
      for (final item in s.items) {
        _quantities[item.recipeId] = item.quantity;
        // If stored price differs from current recipe price, treat as custom
        _customPrices[item.recipeId] = item.sellingPrice;
      }
      for (final exp in s.expenses) {
        final entry = _ExpenseEntry();
        entry.labelCtrl.text = exp.label;
        entry.amountCtrl.text = exp.amount.toString();
        entry.category = exp.category;
        _expenses.add(entry);
      }
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _deliveryCtrl.dispose();
    super.dispose();
  }

  double get _deliveryFee => double.tryParse(_deliveryCtrl.text) ?? 0;

  double _totalRevenue(List<Recipe> recipes) =>
      recipes.where((r) => (_quantities[r.id] ?? 0) > 0).fold(0.0, (s, r) {
        final price = _customPrices[r.id] ?? r.sellingPricePerPiece;
        return s + price * (_quantities[r.id] ?? 0);
      }) +
      _deliveryFee;

  double _totalCost(List<Recipe> recipes) =>
      recipes.where((r) => (_quantities[r.id] ?? 0) > 0).fold(0.0, (s, r) {
        final qty = _quantities[r.id] ?? 0;
        // cost per piece = ingredientCost / pieces
        final costPerPiece =
            r.pieces > 0 ? r.ingredientCost / r.pieces : r.ingredientCost;
        return s + costPerPiece * qty;
      });

  double get _totalExpenses => _expenses.fold(
      0.0, (s, e) => s + (double.tryParse(e.amountCtrl.text) ?? 0));

  Future<void> _save() async {
    if (_saving) return;
    final hasItems = _quantities.values.any((q) => q > 0);
    if (!hasItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item with quantity')),
      );
      return;
    }
    setState(() => _saving = true);

    final salesProvider = context.read<SalesProvider>();
    final costingProvider = context.read<CostingProvider>();
    final sessionId = widget.session?.id ?? const Uuid().v4();

    final items = _quantities.entries.where((e) => e.value > 0).map((e) {
      final recipe = costingProvider.recipes.firstWhere((r) => r.id == e.key);
      final price = _customPrices[recipe.id] ?? recipe.sellingPricePerPiece;
      return SaleItem(
        id: const Uuid().v4(),
        saleSessionId: sessionId,
        recipeId: recipe.id,
        recipeName: recipe.name,
        sellingPrice: price,
        costPrice: recipe.pieces > 0
            ? recipe.ingredientCost / recipe.pieces
            : recipe.ingredientCost,
        quantity: e.value,
      );
    }).toList();

    final expenses = _expenses
        .where((e) =>
            e.labelCtrl.text.trim().isNotEmpty &&
            (double.tryParse(e.amountCtrl.text) ?? 0) > 0)
        .map((e) => SaleExpense(
              id: const Uuid().v4(),
              saleSessionId: sessionId,
              label: e.labelCtrl.text.trim(),
              category: e.category,
              amount: double.tryParse(e.amountCtrl.text) ?? 0,
            ))
        .toList();

    if (widget.session == null) {
      await salesProvider.createSession(
        label: _labelCtrl.text.trim(),
        items: items,
        deliveryFee: _deliveryFee,
        expenses: expenses,
      );
    } else {
      await salesProvider.updateSession(
        id: sessionId,
        label: _labelCtrl.text.trim(),
        items: items,
        deliveryFee: _deliveryFee,
        expenses: expenses,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final recipes = context.watch<CostingProvider>().recipes;
    final revenue = _totalRevenue(recipes);
    final cost = _totalCost(recipes);
    final profit = revenue - cost - _totalExpenses;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session == null ? 'New Sale' : 'Edit Sale'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save',
                    style: TextStyle(
                        color: AppTheme.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: recipes.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restaurant_menu_outlined,
                      size: 64, color: context.onSurfaceMuted),
                  const SizedBox(height: 12),
                  Text('No recipes found',
                      style: TextStyle(
                          color: context.onSurface,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Add recipes in the Costing tab first',
                      style: TextStyle(
                          color: context.onSurfaceMuted, fontSize: 13)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Session label
                TextField(
                  controller: _labelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Session Label',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 20),

                // Items section
                _SectionHeader(
                    title: 'Menu Items', subtitle: 'Enter quantity sold'),
                const SizedBox(height: 10),
                ...recipes.map((recipe) => _RecipeQtyRow(
                      recipe: recipe,
                      quantity: _quantities[recipe.id] ?? 0,
                      customPrice: _customPrices[recipe.id],
                      onChanged: (qty) =>
                          setState(() => _quantities[recipe.id] = qty),
                      onCustomPrice: (price) =>
                          setState(() => _customPrices[recipe.id] = price),
                    )),

                const SizedBox(height: 20),

                // Delivery fee
                _SectionHeader(title: 'Delivery Fee', subtitle: 'Optional'),
                const SizedBox(height: 10),
                TextField(
                  controller: _deliveryCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixIcon: const Icon(Icons.delivery_dining_outlined),
                    suffixText: _deliveryFee > 0
                        ? '+${_deliveryFee.toStringAsFixed(2)}'
                        : null,
                    suffixStyle: const TextStyle(
                        color: AppTheme.success, fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 20),

                // Expenses section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SectionHeader(
                        title: 'Overhead Expenses',
                        subtitle: 'Packaging, fuel, supplies...'),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _expenses.add(_ExpenseEntry())),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_expenses.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text('No expenses added',
                          style: TextStyle(
                              color: context.onSurfaceMuted, fontSize: 13)),
                    ),
                  )
                else
                  ..._expenses.asMap().entries.map((entry) => _ExpenseRow(
                        entry: entry.value,
                        onRemove: () =>
                            setState(() => _expenses.removeAt(entry.key)),
                        onChanged: () => setState(() {}),
                      )),

                const SizedBox(height: 20),

                // Summary
                if (_quantities.values.any((q) => q > 0))
                  _SummaryCard(
                    revenue: revenue,
                    cost: cost,
                    expenses: _totalExpenses,
                    deliveryFee: _deliveryFee,
                    profit: profit,
                  ),
                const SizedBox(height: 80),
              ],
            ),
    );
  }
}

// ─── Expense Entry Model ──────────────────────────────────────────────────────

class _ExpenseEntry {
  final TextEditingController labelCtrl = TextEditingController();
  final TextEditingController amountCtrl = TextEditingController();
  String category = kExpenseCategories[0];
}

// ─── Expense Row Widget ───────────────────────────────────────────────────────

class _ExpenseRow extends StatelessWidget {
  final _ExpenseEntry entry;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _ExpenseRow(
      {required this.entry, required this.onRemove, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: entry.category,
                    isDense: true,
                    dropdownColor: context.surface,
                    style: TextStyle(color: context.onSurface, fontSize: 13),
                    items: kExpenseCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        entry.category = v;
                        onChanged();
                      }
                    },
                  ),
                ),
              ),
              IconButton(
                icon:
                    Icon(Icons.close, size: 18, color: context.onSurfaceMuted),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: entry.labelCtrl,
                  onChanged: (_) => onChanged(),
                  decoration: InputDecoration(
                    hintText: 'Description (e.g. Boxes)',
                    isDense: true,
                    fillColor: context.surface,
                    filled: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: entry.amountCtrl,
                  onChanged: (_) => onChanged(),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Amount',
                    isDense: true,
                    fillColor: context.surface,
                    filled: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final double revenue;
  final double cost;
  final double expenses;
  final double deliveryFee;
  final double profit;

  const _SummaryCard({
    required this.revenue,
    required this.cost,
    required this.expenses,
    required this.deliveryFee,
    required this.profit,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final margin = revenue > 0 ? (profit / revenue) * 100 : 0.0;

    return Container(
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
        children: [
          _Row(
              label: 'Revenue',
              value: fmt.format(revenue),
              color: AppTheme.success),
          if (deliveryFee > 0) ...[
            const SizedBox(height: 4),
            _Row(
                label: '  ↳ Delivery fee',
                value: '+${fmt.format(deliveryFee)}',
                color: AppTheme.success,
                small: true),
          ],
          const SizedBox(height: 6),
          _Row(
              label: 'Recipe Cost',
              value: fmt.format(cost),
              color: AppTheme.warning),
          if (expenses > 0) ...[
            const SizedBox(height: 6),
            _Row(
                label: 'Overhead Expenses',
                value: fmt.format(expenses),
                color: AppTheme.error),
          ],
          Divider(height: 20, color: context.surfaceVariant),
          _Row(
            label: 'Net Profit',
            value: fmt.format(profit),
            color: profit >= 0 ? AppTheme.success : AppTheme.error,
          ),
          const SizedBox(height: 4),
          _Row(
            label: 'Profit Margin',
            value: '${margin.toStringAsFixed(1)}%',
            color: profit >= 0 ? AppTheme.success : AppTheme.error,
          ),
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

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(title,
            style: TextStyle(
                color: context.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 15)),
        const SizedBox(width: 8),
        Text(subtitle,
            style: TextStyle(color: context.onSurfaceMuted, fontSize: 12)),
      ],
    );
  }
}

class _RecipeQtyRow extends StatefulWidget {
  final Recipe recipe;
  final int quantity;
  final double? customPrice;
  final ValueChanged<int> onChanged;
  final ValueChanged<double?> onCustomPrice;

  const _RecipeQtyRow({
    required this.recipe,
    required this.quantity,
    required this.customPrice,
    required this.onChanged,
    required this.onCustomPrice,
  });

  @override
  State<_RecipeQtyRow> createState() => _RecipeQtyRowState();
}

class _RecipeQtyRowState extends State<_RecipeQtyRow> {
  bool _useCustomPrice = false;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _useCustomPrice = widget.customPrice != null;
    _priceCtrl = TextEditingController(
      text: widget.customPrice?.toStringAsFixed(2) ??
          widget.recipe.sellingPricePerPiece.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasQty = widget.quantity > 0;
    final displayPrice = _useCustomPrice
        ? (double.tryParse(_priceCtrl.text) ??
            widget.recipe.sellingPricePerPiece)
        : widget.recipe.sellingPricePerPiece;
    final costPerPiece = widget.recipe.pieces > 0
        ? widget.recipe.ingredientCost / widget.recipe.pieces
        : widget.recipe.ingredientCost;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            hasQty ? AppTheme.primary.withValues(alpha: 0.06) : context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasQty
              ? AppTheme.primary.withValues(alpha: 0.4)
              : context.surfaceVariant,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: hasQty
                    ? AppTheme.primary.withValues(alpha: 0.15)
                    : AppTheme.primary.withValues(alpha: 0.1),
                child: Text(
                  widget.recipe.name[0].toUpperCase(),
                  style: TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.recipe.name,
                        style: TextStyle(
                            color: context.onSurface,
                            fontWeight: FontWeight.w600)),
                    Text(
                      'Price/pc: ${displayPrice.toStringAsFixed(2)}  •  Cost/pc: ${costPerPiece.toStringAsFixed(2)}',
                      style: TextStyle(
                          color: context.onSurfaceMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _StepBtn(
                      icon: Icons.remove,
                      onTap: widget.quantity > 0
                          ? () => widget.onChanged(widget.quantity - 1)
                          : null),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${widget.quantity}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: hasQty ? AppTheme.primary : context.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _StepBtn(
                      icon: Icons.add,
                      onTap: () => widget.onChanged(widget.quantity + 1)),
                ],
              ),
            ],
          ),
          // Custom price toggle
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.sell_outlined,
                  size: 14, color: context.onSurfaceMuted),
              const SizedBox(width: 6),
              Text('Custom price',
                  style:
                      TextStyle(color: context.onSurfaceMuted, fontSize: 12)),
              const Spacer(),
              Switch(
                value: _useCustomPrice,
                activeThumbColor: AppTheme.primary,
                onChanged: (v) {
                  setState(() => _useCustomPrice = v);
                  if (!v) {
                    widget.onCustomPrice(null);
                  } else {
                    final price = double.tryParse(_priceCtrl.text);
                    widget.onCustomPrice(price);
                  }
                },
              ),
            ],
          ),
          if (_useCustomPrice) ...[
            const SizedBox(height: 6),
            TextField(
              controller: _priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) {
                final price = double.tryParse(v);
                widget.onCustomPrice(price);
              },
              decoration: InputDecoration(
                labelText: 'Selling price per piece',
                isDense: true,
                fillColor: context.surfaceVariant,
                filled: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppTheme.primary.withValues(alpha: 0.12)
              : context.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 16,
            color: onTap != null ? AppTheme.primary : context.onSurfaceMuted),
      ),
    );
  }
}
