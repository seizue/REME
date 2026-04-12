import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/recipe.dart';
import '../../../models/recipe_price_history.dart';
import '../providers/costing_provider.dart';
import 'recipe_form_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CostingProvider>().loadRecipePriceHistory(widget.recipe.id);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('MMM d, yyyy  h:mm a');

    return Consumer<CostingProvider>(
      builder: (context, provider, _) {
        final recipe = provider.recipes.firstWhere(
          (r) => r.id == widget.recipe.id,
          orElse: () => widget.recipe,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(recipe.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => RecipeFormScreen(recipe: recipe)),
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabs,
              indicatorColor: AppTheme.primary,
              labelColor: AppTheme.primary,
              unselectedLabelColor: context.onSurfaceMuted,
              tabs: const [
                Tab(text: 'Cost Breakdown'),
                Tab(text: 'Price History'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabs,
            children: [
              // ── Tab 1: Cost Breakdown ──────────────────────────────────
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.15),
                          context.surface
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: context.isDark
                          ? Border.all(color: context.surfaceVariant)
                          : null,
                    ),
                    child: Column(
                      children: [
                        _SummaryRow(
                            label: 'Ingredient Cost',
                            value: '₱${fmt.format(recipe.ingredientCost)}',
                            color: AppTheme.warning),
                        const SizedBox(height: 4),
                        _SummaryRow(
                            label:
                                '+ Markup (${recipe.markupPercent.toStringAsFixed(0)}%)',
                            value:
                                '₱${fmt.format(recipe.ingredientCost * recipe.markupPercent / 100)}',
                            color: AppTheme.secondary),
                        Divider(height: 16, color: context.surfaceVariant),
                        _SummaryRow(
                            label: 'After Markup',
                            value:
                                '₱${fmt.format(recipe.markedUpIngredientCost)}',
                            color: AppTheme.primary),
                        const SizedBox(height: 6),
                        _SummaryRow(
                            label: '+ Labor Cost',
                            value: '₱${fmt.format(recipe.laborCost)}',
                            color: AppTheme.warning),
                        Divider(height: 16, color: context.surfaceVariant),
                        _SummaryRow(
                            label: 'Selling Price (batch)',
                            value: '₱${fmt.format(recipe.sellingPriceBatch)}',
                            color: AppTheme.success),
                        if (recipe.pieces > 1) ...[
                          const SizedBox(height: 6),
                          _SummaryRow(
                              label: 'Price per piece (÷${recipe.pieces})',
                              value:
                                  '₱${fmt.format(recipe.sellingPricePerPiece)}',
                              color: AppTheme.success),
                        ],
                        if (recipe.totalWeight > 0) ...[
                          const SizedBox(height: 6),
                          _SummaryRow(
                              label: 'Price per ${recipe.weightUnit.label}',
                              value:
                                  '₱${fmt.format(recipe.sellingPricePerWeight)}',
                              color: AppTheme.success),
                        ],
                        Divider(height: 16, color: context.surfaceVariant),
                        _SummaryRow(
                            label: 'Profit Margin',
                            value: '${recipe.profitMargin.toStringAsFixed(1)}%',
                            color: AppTheme.success),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Ingredients',
                      style: TextStyle(
                          color: context.onSurfaceMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  ...recipe.ingredients.map((ri) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: context.surface,
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  AppTheme.primary.withValues(alpha: 0.12),
                              child: Text(ri.ingredientName[0].toUpperCase(),
                                  style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ri.ingredientName,
                                      style: TextStyle(
                                          color: context.onSurface,
                                          fontWeight: FontWeight.w500)),
                                  Text(
                                      '${ri.quantity} ${ri.unit} × ₱${fmt.format(ri.unitCost)}',
                                      style: TextStyle(
                                          color: context.onSurfaceMuted,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            Text('₱${fmt.format(ri.totalCost)}',
                                style: const TextStyle(
                                    color: AppTheme.warning,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )),
                ],
              ),

              // ── Tab 2: Price History ───────────────────────────────────
              provider.priceHistory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history,
                              size: 64, color: context.onSurfaceMuted),
                          const SizedBox(height: 12),
                          Text('No price changes yet',
                              style: TextStyle(color: context.onSurfaceMuted)),
                          const SizedBox(height: 4),
                          Text('History is recorded when you update the recipe',
                              style: TextStyle(
                                  color: context.onSurfaceMuted, fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.priceHistory.length,
                      itemBuilder: (_, i) => _PriceHistoryCard(
                        history: provider.priceHistory[i],
                        dateFmt: dateFmt,
                        fmt: fmt,
                        isCurrent: i == 0,
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }
}

class _PriceHistoryCard extends StatelessWidget {
  final RecipePriceHistory history;
  final DateFormat dateFmt;
  final NumberFormat fmt;
  final bool isCurrent;

  const _PriceHistoryCard(
      {required this.history,
      required this.dateFmt,
      required this.fmt,
      required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final priceUp = history.priceDiff >= 0;
    final costUp = history.costDiff >= 0;
    final priceColor = priceUp ? AppTheme.priceUp : AppTheme.priceDown;
    final costColor = costUp ? AppTheme.priceUp : AppTheme.priceDown;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? AppTheme.primary.withValues(alpha: 0.5)
              : context.surfaceVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(dateFmt.format(history.changedAt),
                  style:
                      TextStyle(color: context.onSurfaceMuted, fontSize: 12)),
              const Spacer(),
              if (isCurrent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Latest',
                      style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _ChangeRow(
            icon: Icons.sell_outlined,
            label: 'Price',
            oldVal: '₱${fmt.format(history.oldPrice)}',
            newVal: '₱${fmt.format(history.newPrice)}',
            isUp: priceUp,
            color: priceColor,
            percent:
                '(${history.priceChangePercent >= 0 ? '+' : ''}${history.priceChangePercent.toStringAsFixed(1)}%)',
          ),
          const SizedBox(height: 8),
          _ChangeRow(
            icon: Icons.calculate_outlined,
            label: 'Cost',
            oldVal: '₱${fmt.format(history.oldCost)}',
            newVal: '₱${fmt.format(history.newCost)}',
            isUp: costUp,
            color: costColor,
          ),
        ],
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String oldVal;
  final String newVal;
  final bool isUp;
  final Color color;
  final String? percent;

  const _ChangeRow({
    required this.icon,
    required this.label,
    required this.oldVal,
    required this.newVal,
    required this.isUp,
    required this.color,
    this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.onSurfaceMuted),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: context.onSurfaceMuted)),
        const Spacer(),
        Text(oldVal,
            style: TextStyle(
                color: context.onSurfaceMuted,
                decoration: TextDecoration.lineThrough,
                fontSize: 13)),
        const SizedBox(width: 8),
        Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14, color: color),
        Text(newVal,
            style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        if (percent != null) ...[
          const SizedBox(width: 4),
          Text(percent!, style: TextStyle(color: color, fontSize: 11)),
        ],
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: context.onSurfaceMuted)),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 15)),
      ],
    );
  }
}
