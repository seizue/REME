import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/ingredient.dart';
import '../../../models/recipe.dart';
import '../../../models/recipe_ingredient.dart';
import '../providers/costing_provider.dart';

class RecipeFormScreen extends StatefulWidget {
  final Recipe? recipe;
  const RecipeFormScreen({super.key, this.recipe});

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _laborCtrl;
  late final TextEditingController _markupCtrl;
  late final TextEditingController _piecesCtrl;
  late final TextEditingController _weightCtrl;
  late WeightUnit _weightUnit;
  final List<_IngredientRow> _rows = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    _nameCtrl = TextEditingController(text: r?.name ?? '');
    _categoryCtrl = TextEditingController(text: r?.category ?? '');
    _laborCtrl =
        TextEditingController(text: r != null ? r.laborCost.toString() : '0');
    _markupCtrl = TextEditingController(
        text: r != null ? r.markupPercent.toString() : '30');
    _piecesCtrl =
        TextEditingController(text: r != null ? r.pieces.toString() : '1');
    _weightCtrl = TextEditingController(
        text: r != null && r.totalWeight > 0 ? r.totalWeight.toString() : '');
    _weightUnit = r?.weightUnit ?? WeightUnit.kilo;
    if (r != null) {
      for (final ri in r.ingredients) {
        _rows.add(_IngredientRow.fromRecipeIngredient(ri));
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _laborCtrl.dispose();
    _markupCtrl.dispose();
    _piecesCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  double get _ingredientCost => _rows.fold(0.0, (s, r) => s + r.totalCost);
  double get _laborCost => double.tryParse(_laborCtrl.text) ?? 0;
  double get _markup => double.tryParse(_markupCtrl.text) ?? 30;
  int get _pieces => int.tryParse(_piecesCtrl.text) ?? 1;
  double get _weight => double.tryParse(_weightCtrl.text) ?? 0;

  double get _markedUpIngredientCost => _ingredientCost * (1 + _markup / 100);
  double get _sellingPriceBatch => _markedUpIngredientCost + _laborCost;
  double get _sellingPricePerPiece =>
      _pieces > 0 ? _sellingPriceBatch / _pieces : _sellingPriceBatch;
  double get _sellingPricePerWeight {
    if (_weight <= 0) return 0;
    final kg = _weightUnit == WeightUnit.kilo ? _weight : _weight / 1000;
    return kg > 0 ? _sellingPriceBatch / kg : 0;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one ingredient')),
      );
      return;
    }
    setState(() => _saving = true);
    final provider = context.read<CostingProvider>();
    final ingredients = _rows
        .where((r) => r.isValid)
        .map((r) => r.toRecipeIngredient())
        .toList();

    if (widget.recipe == null) {
      await provider.addRecipe(provider.buildNewRecipe(
        name: _nameCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        ingredients: ingredients,
        laborCost: _laborCost,
        markupPercent: _markup,
        pieces: _pieces,
        totalWeight: _weight,
        weightUnit: _weightUnit,
      ));
    } else {
      await provider.updateRecipe(widget.recipe!.copyWith(
        name: _nameCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        ingredients: ingredients,
        laborCost: _laborCost,
        markupPercent: _markup,
        pieces: _pieces,
        totalWeight: _weight,
        weightUnit: _weightUnit,
      ));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CostingProvider>();
    final isEdit = widget.recipe != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Recipe' : 'New Recipe'),
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Recipe Info ───────────────────────────────────────────
            _SectionLabel('Recipe Info'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Recipe Name',
                  prefixIcon: Icon(Icons.restaurant_menu_outlined)),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            _CategoryField(
              controller: _categoryCtrl,
              existingCategories: provider.recipes
                  .map((r) => r.category)
                  .where((c) => c.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort(),
            ),
            const SizedBox(height: 24),

            // ── Ingredients ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionLabel('Ingredients'),
                TextButton.icon(
                  onPressed: () =>
                      _showIngredientPicker(context, provider.ingredients),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_rows.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: context.surfaceVariant,
                    borderRadius: BorderRadius.circular(12)),
                child: Center(
                    child: Text('No ingredients added',
                        style: TextStyle(color: context.onSurfaceMuted))),
              )
            else
              ..._rows.asMap().entries.map((entry) => _IngredientRowWidget(
                    row: entry.value,
                    onRemove: () => setState(() => _rows.removeAt(entry.key)),
                    onChanged: () => setState(() {}),
                  )),
            const SizedBox(height: 24),

            // ── Pricing ───────────────────────────────────────────────
            _SectionLabel('Pricing'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _laborCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                        labelText: 'Labor Cost',
                        prefixIcon: Icon(Icons.people_outline)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _markupCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                        labelText: 'Markup %', prefixIcon: Icon(Icons.percent)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pieces + Weight
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _piecesCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                        labelText: 'Pieces per batch',
                        prefixIcon: Icon(Icons.grid_view_rounded)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _weightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Total weight',
                      prefixIcon: const Icon(Icons.scale_outlined),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<WeightUnit>(
                            value: _weightUnit,
                            isDense: true,
                            dropdownColor: context.surface,
                            items: WeightUnit.values
                                .map((u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u.label,
                                          style: const TextStyle(fontSize: 13)),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _weightUnit = v);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Cost & Price Summary ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(16),
                border: context.isDark
                    ? Border.all(color: context.surfaceVariant)
                    : null,
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
                  Text('Cost Breakdown',
                      style: TextStyle(
                          color: context.onSurfaceMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _CalcRow(
                      label: 'Ingredient Cost',
                      value: _ingredientCost,
                      color: AppTheme.warning),
                  const SizedBox(height: 4),
                  _CalcRow(
                      label: '+ Markup (${_markup.toStringAsFixed(0)}%)',
                      value: _ingredientCost * _markup / 100,
                      color: AppTheme.secondary),
                  Divider(height: 16, color: context.surfaceVariant),
                  _CalcRow(
                      label: 'After Markup',
                      value: _markedUpIngredientCost,
                      color: AppTheme.primary,
                      bold: true),
                  const SizedBox(height: 6),
                  _CalcRow(
                      label: '+ Labor Cost',
                      value: _laborCost,
                      color: AppTheme.warning),
                  Divider(height: 16, color: context.surfaceVariant),
                  _CalcRow(
                      label: 'Selling Price (batch)',
                      value: _sellingPriceBatch,
                      color: AppTheme.success,
                      bold: true),
                  if (_pieces > 1) ...[
                    const SizedBox(height: 6),
                    _CalcRow(
                        label: 'Price per piece (÷$_pieces)',
                        value: _sellingPricePerPiece,
                        color: AppTheme.success),
                  ],
                  if (_weight > 0) ...[
                    const SizedBox(height: 6),
                    _CalcRow(
                        label: 'Price per ${_weightUnit.label}',
                        value: _sellingPricePerWeight,
                        color: AppTheme.success),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _showIngredientPicker(
      BuildContext context, List<Ingredient> ingredients) {
    if (ingredients.isEmpty) {
      setState(() => _rows.add(_IngredientRow()));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _IngredientPickerSheet(
        ingredients: ingredients,
        alreadyAdded:
            _rows.map((r) => r.ingredientId).whereType<String>().toSet(),
        onConfirm: (selected) {
          setState(() {
            for (final ing in selected) {
              if (!_rows.any((r) => r.ingredientId == ing.id)) {
                _rows.add(_IngredientRow(ingredient: ing));
              }
            }
          });
        },
        onAddCustom: () => setState(() => _rows.add(_IngredientRow())),
      ),
    );
  }
}

// ─── Category Field ───────────────────────────────────────────────────────────

class _CategoryField extends StatefulWidget {
  final TextEditingController controller;
  final List<String> existingCategories;

  const _CategoryField(
      {required this.controller, required this.existingCategories});

  @override
  State<_CategoryField> createState() => _CategoryFieldState();
}

class _CategoryFieldState extends State<_CategoryField> {
  bool _showSuggestions = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          onTap: () => setState(
              () => _showSuggestions = widget.existingCategories.isNotEmpty),
          onChanged: (_) => setState(
              () => _showSuggestions = widget.existingCategories.isNotEmpty),
          onFieldSubmitted: (_) => setState(() => _showSuggestions = false),
          decoration: const InputDecoration(
            labelText: 'Category (optional)',
            prefixIcon: Icon(Icons.category_outlined),
            suffixIcon: Icon(Icons.expand_more, size: 18),
          ),
        ),
        if (_showSuggestions && widget.existingCategories.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
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
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
            ),
            child: Column(
              children: widget.existingCategories
                  .map((cat) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.label_outline,
                            size: 18, color: AppTheme.primary),
                        title: Text(cat, style: const TextStyle(fontSize: 14)),
                        onTap: () {
                          widget.controller.text = cat;
                          setState(() => _showSuggestions = false);
                        },
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

// ─── Models ──────────────────────────────────────────────────────────────────

class _IngredientRow {
  final TextEditingController nameCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController unitCtrl;
  final TextEditingController costCtrl;
  final String? ingredientId;
  final bool unitEnabled;

  _IngredientRow({Ingredient? ingredient})
      : ingredientId = ingredient?.id,
        unitEnabled = ingredient?.unitEnabled ?? false,
        nameCtrl = TextEditingController(text: ingredient?.name ?? ''),
        qtyCtrl = TextEditingController(),
        unitCtrl = TextEditingController(text: ingredient?.unit ?? ''),
        costCtrl = TextEditingController(
            text: ingredient != null ? ingredient.unitCost.toString() : '');

  factory _IngredientRow.fromRecipeIngredient(RecipeIngredient ri) {
    final row = _IngredientRow();
    row.nameCtrl.text = ri.ingredientName;
    row.qtyCtrl.text = ri.quantity.toString();
    row.unitCtrl.text = ri.unit;
    row.costCtrl.text = ri.unitCost.toString();
    return row;
  }

  double get totalCost =>
      (double.tryParse(qtyCtrl.text) ?? 0) *
      (double.tryParse(costCtrl.text) ?? 0);
  bool get isValid =>
      nameCtrl.text.isNotEmpty && (double.tryParse(qtyCtrl.text) ?? 0) > 0;

  RecipeIngredient toRecipeIngredient() => RecipeIngredient(
        ingredientId: ingredientId ?? const Uuid().v4(),
        ingredientName: nameCtrl.text.trim(),
        quantity: double.tryParse(qtyCtrl.text) ?? 0,
        unit: unitEnabled ? unitCtrl.text.trim() : '',
        unitCost: double.tryParse(costCtrl.text) ?? 0,
      );
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _IngredientRowWidget extends StatelessWidget {
  final _IngredientRow row;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _IngredientRowWidget(
      {required this.row, required this.onRemove, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: context.surfaceVariant,
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: row.nameCtrl,
                  onChanged: (_) => onChanged(),
                  decoration: const InputDecoration(
                      hintText: 'Ingredient name',
                      isDense: true,
                      border: InputBorder.none,
                      fillColor: Colors.transparent),
                  style: TextStyle(
                      color: context.onSurface, fontWeight: FontWeight.w500),
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
                  child: _MiniField(
                      ctrl: row.qtyCtrl, hint: 'Qty', onChanged: onChanged)),
              if (row.unitEnabled) ...[
                const SizedBox(width: 8),
                Expanded(
                    child: _MiniField(
                        ctrl: row.unitCtrl,
                        hint: 'Unit',
                        isNumber: false,
                        onChanged: onChanged)),
              ],
              const SizedBox(width: 8),
              Expanded(
                  child: _MiniField(
                      ctrl: row.costCtrl,
                      hint: 'Cost/unit',
                      onChanged: onChanged)),
              const SizedBox(width: 8),
              Text(row.totalCost.toStringAsFixed(2),
                  style: const TextStyle(
                      color: AppTheme.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final bool isNumber;
  final VoidCallback onChanged;

  const _MiniField(
      {required this.ctrl,
      required this.hint,
      this.isNumber = true,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      onChanged: (_) => onChanged(),
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        fillColor: context.surface,
        filled: true,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.5),
      );
}

class _CalcRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool bold;

  const _CalcRow(
      {required this.label,
      required this.value,
      required this.color,
      this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: context.onSurfaceMuted, fontSize: bold ? 13 : 12)),
        Text(value.toStringAsFixed(2),
            style: TextStyle(
                color: color,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                fontSize: bold ? 15 : 13)),
      ],
    );
  }
}

// ─── Ingredient Picker Sheet ──────────────────────────────────────────────────

class _IngredientPickerSheet extends StatefulWidget {
  final List<Ingredient> ingredients;
  final Set<String> alreadyAdded;
  final ValueChanged<List<Ingredient>> onConfirm;
  final VoidCallback onAddCustom;

  const _IngredientPickerSheet(
      {required this.ingredients,
      required this.alreadyAdded,
      required this.onConfirm,
      required this.onAddCustom});

  @override
  State<_IngredientPickerSheet> createState() => _IngredientPickerSheetState();
}

class _IngredientPickerSheetState extends State<_IngredientPickerSheet> {
  final Set<String> _selected = {};
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.ingredients
        .where((i) => i.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Column(
        children: [
          const SizedBox(height: 12),
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: context.surfaceVariant,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Add Ingredients',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                const Spacer(),
                if (_selected.isNotEmpty)
                  Text('${_selected.length} selected',
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                  hintText: 'Search...',
                  isDense: true,
                  prefixIcon: Icon(Icons.search,
                      color: context.onSurfaceMuted, size: 20)),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                widget.onAddCustom();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.3))),
                child: const Row(children: [
                  Icon(Icons.add_circle_outline,
                      color: AppTheme.primary, size: 18),
                  SizedBox(width: 10),
                  Text('Add custom ingredient',
                      style: TextStyle(
                          color: AppTheme.primary, fontWeight: FontWeight.w600))
                ]),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: context.surfaceVariant),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              padding: EdgeInsets.only(
                  top: 4, bottom: MediaQuery.of(context).padding.bottom + 80),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final ing = filtered[i];
                final isSelected = _selected.contains(ing.id);
                final alreadyIn = widget.alreadyAdded.contains(ing.id);
                return ListTile(
                  enabled: !alreadyIn,
                  leading: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle),
                    child: Center(
                        child: isSelected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : Text(ing.name[0].toUpperCase(),
                                style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w700))),
                  ),
                  title: Text(ing.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: alreadyIn
                              ? context.onSurfaceMuted
                              : context.onSurface)),
                  subtitle: Text(
                      ing.unitEnabled
                          ? '${ing.unitCost} / ${ing.unit}'
                          : '${ing.unitCost}',
                      style: TextStyle(
                          color: context.onSurfaceMuted, fontSize: 12)),
                  trailing: alreadyIn
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: context.surfaceVariant,
                              borderRadius: BorderRadius.circular(8)),
                          child: Text('Added',
                              style: TextStyle(
                                  color: context.onSurfaceMuted, fontSize: 11)))
                      : Checkbox(
                          value: isSelected,
                          activeColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          onChanged: (_) => setState(() {
                                if (isSelected) {
                                  _selected.remove(ing.id);
                                } else {
                                  _selected.add(ing.id);
                                }
                              })),
                  onTap: alreadyIn
                      ? null
                      : () => setState(() {
                            if (isSelected) {
                              _selected.remove(ing.id);
                            } else {
                              _selected.add(ing.id);
                            }
                          }),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selected.isEmpty
                    ? null
                    : () {
                        final picked = widget.ingredients
                            .where((i) => _selected.contains(i.id))
                            .toList();
                        Navigator.pop(context);
                        widget.onConfirm(picked);
                      },
                child: Text(_selected.isEmpty
                    ? 'Select ingredients'
                    : 'Add ${_selected.length} ingredient${_selected.length > 1 ? 's' : ''}'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
