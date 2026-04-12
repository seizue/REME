import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/recipe.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final margin = recipe.profitMargin;
    final marginColor = margin >= 30
        ? AppTheme.success
        : margin >= 10
            ? AppTheme.warning
            : AppTheme.error;

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
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 10,
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
                      Text(recipe.name,
                          style: TextStyle(
                              color: context.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      if (recipe.category.isNotEmpty)
                        Text(recipe.category,
                            style: TextStyle(
                                color: context.onSurfaceMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: marginColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${margin.toStringAsFixed(1)}% margin',
                    style: TextStyle(
                        color: marginColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
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
                _InfoChip(
                    label: 'Cost',
                    value: fmt.format(recipe.ingredientCost),
                    color: AppTheme.warning),
                const SizedBox(width: 16),
                _InfoChip(
                    label: 'Sell/batch',
                    value: fmt.format(recipe.sellingPriceBatch),
                    color: AppTheme.secondary),
                const SizedBox(width: 16),
                _InfoChip(
                    label: 'Per piece',
                    value: fmt.format(recipe.sellingPricePerPiece),
                    color: AppTheme.success),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip(
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
                color: color, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
