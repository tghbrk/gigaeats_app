import 'package:flutter/material.dart';

/// Reusable category filter tabs widget for menu categorization
/// Displays horizontal scrollable filter chips with item counts
class CategoryFilterTabs extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;
  final Map<String, int>? categoryCounts;
  final bool showCounts;
  final EdgeInsets? padding;
  final double? height;

  const CategoryFilterTabs({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.categoryCounts,
    this.showCounts = true,
    this.padding,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showCounts && categoryCounts != null) ...[
            Row(
              children: [
                Text(
                  'Categories',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_getTotalCount()} items',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            height: height ?? 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;
                final itemCount = categoryCounts?[category] ?? 0;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      showCounts && categoryCounts != null 
                          ? '$category ($itemCount)'
                          : category,
                    ),
                    selected: isSelected,
                    onSelected: (selected) => onCategorySelected(category),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    selectedColor: theme.colorScheme.primaryContainer,
                    checkmarkColor: theme.colorScheme.onPrimaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected 
                          ? theme.colorScheme.onPrimaryContainer 
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _getTotalCount() {
    if (categoryCounts == null) return 0;
    
    // If 'All' category exists, return its count, otherwise sum all categories
    if (categoryCounts!.containsKey('All')) {
      return categoryCounts!['All']!;
    }
    
    return categoryCounts!.values.fold(0, (sum, count) => sum + count);
  }
}

/// Simple category tabs without counts for basic categorization
class SimpleCategoryTabs extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;
  final EdgeInsets? padding;
  final double? height;

  const SimpleCategoryTabs({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.padding,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return CategoryFilterTabs(
      categories: categories,
      selectedCategory: selectedCategory,
      onCategorySelected: onCategorySelected,
      showCounts: false,
      padding: padding,
      height: height,
    );
  }
}

/// Category tabs with Material Design 3 tab bar styling
class MaterialCategoryTabs extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;
  final EdgeInsets? margin;

  const MaterialCategoryTabs({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIndex = categories.indexOf(selectedCategory);
    
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(25),
      ),
      child: DefaultTabController(
        length: categories.length,
        initialIndex: selectedIndex >= 0 ? selectedIndex : 0,
        child: TabBar(
          onTap: (index) => onCategorySelected(categories[index]),
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicator: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(25),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          tabs: categories.map((category) => Tab(
            height: 48,
            child: Text(category),
          )).toList(),
        ),
      ),
    );
  }
}
