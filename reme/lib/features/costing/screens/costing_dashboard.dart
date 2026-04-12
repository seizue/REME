import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/costing_provider.dart';
import '../widgets/recipe_card.dart';
import '../widgets/stat_card.dart';
import 'recipe_form_screen.dart';
import 'recipe_detail_screen.dart';

class CostingDashboard extends StatefulWidget {
  const CostingDashboard({super.key});

  @override
  State<CostingDashboard> createState() => _CostingDashboardState();
}

class _CostingDashboardState extends State<CostingDashboard> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CostingProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    return Consumer<CostingProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final filtered = provider.recipes
            .where((r) =>
                r.name.toLowerCase().contains(_search.toLowerCase()) ||
                r.category.toLowerCase().contains(_search.toLowerCase()))
            .toList();

        final avgMargin = provider.recipes.isEmpty
            ? 0.0
            : provider.recipes
                    .map((r) => r.profitMargin)
                    .reduce((a, b) => a + b) /
                provider.recipes.length;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // ── Modern header ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 20,
                    right: 20,
                    bottom: 20,
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
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.restaurant_menu_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('REME',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1)),
                              Text('Costing & Profitability',
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
                                  builder: (_) => const RecipeFormScreen()),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.add,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text('New',
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
                    ],
                  ),
                ),
              ),

              // ── Stats ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.4,
                    children: [
                      StatCard(
                        label: 'Total Recipes',
                        value: '${provider.recipes.length}',
                        icon: Icons.restaurant_menu_rounded,
                        color: AppTheme.primary,
                      ),
                      StatCard(
                        label: 'Grand Total Cost',
                        value: '₱${fmt.format(provider.grandTotalCost)}',
                        icon: Icons.calculate_rounded,
                        color: AppTheme.warning,
                      ),
                      StatCard(
                        label: 'Avg Margin',
                        value: '${avgMargin.toStringAsFixed(1)}%',
                        icon: Icons.trending_up_rounded,
                        color: AppTheme.success,
                      ),
                      StatCard(
                        label: 'Ingredients',
                        value: '${provider.ingredients.length}',
                        icon: Icons.egg_rounded,
                        color: AppTheme.secondary,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Search ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Search recipes...',
                      prefixIcon: Icon(Icons.search_rounded,
                          color: context.onSurfaceMuted),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded,
                                  color: context.onSurfaceMuted, size: 18),
                              onPressed: () => setState(() => _search = ''),
                            )
                          : null,
                    ),
                  ),
                ),
              ),

              // ── Section label ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        'Recipes',
                        style: TextStyle(
                          color: context.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${filtered.length}',
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Recipe list ────────────────────────────────────────────
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
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.restaurant_menu_rounded,
                              size: 48,
                              color: AppTheme.primary.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(height: 16),
                        Text('No recipes yet',
                            style: TextStyle(
                                color: context.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Tap New to add your first recipe',
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
                      (context, index) {
                        final recipe = filtered[index];
                        return RecipeCard(
                          recipe: recipe,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    RecipeDetailScreen(recipe: recipe)),
                          ),
                          onDelete: () =>
                              _confirmDelete(context, provider, recipe.id),
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
      BuildContext context, CostingProvider provider, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: const Text('This will permanently remove the recipe.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteRecipe(id);
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
