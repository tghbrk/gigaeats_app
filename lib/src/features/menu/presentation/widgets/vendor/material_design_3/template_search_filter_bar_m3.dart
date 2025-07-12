import 'package:flutter/material.dart';

import '../../../theme/template_theme_extension.dart';

/// Material Design 3 enhanced search and filter bar for templates
class TemplateSearchFilterBarM3 extends StatefulWidget {
  final String? searchQuery;
  final String? categoryFilter;
  final String? typeFilter;
  final bool showOnlyRequired;
  final bool showOnlyActive;
  final Function(String?) onSearchChanged;
  final Function(String?) onCategoryChanged;
  final Function(String?) onTypeChanged;
  final Function(bool) onRequiredFilterChanged;
  final Function(bool) onActiveFilterChanged;
  final VoidCallback? onClearFilters;

  const TemplateSearchFilterBarM3({
    super.key,
    this.searchQuery,
    this.categoryFilter,
    this.typeFilter,
    this.showOnlyRequired = false,
    this.showOnlyActive = true,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onTypeChanged,
    required this.onRequiredFilterChanged,
    required this.onActiveFilterChanged,
    this.onClearFilters,
  });

  @override
  State<TemplateSearchFilterBarM3> createState() => _TemplateSearchFilterBarM3State();
}

class _TemplateSearchFilterBarM3State extends State<TemplateSearchFilterBarM3>
    with TickerProviderStateMixin {
  late TextEditingController _searchController;
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;
  bool _showFilters = false;

  final List<String> _categories = [
    'All',
    'Size Options',
    'Add-ons',
    'Spice Level',
    'Cooking Style',
    'Dietary',
    'Other',
  ];

  final List<String> _types = [
    'All',
    'Single Selection',
    'Multiple Selection',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templateTheme = context.templateTheme;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Bar Row
            Row(
              children: [
                // Search Field
                Expanded(
                  child: SearchBar(
                    controller: _searchController,
                    hintText: 'Search templates...',
                    leading: Icon(
                      Icons.search,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    trailing: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            widget.onSearchChanged(null);
                          },
                        ),
                    ],
                    onChanged: (value) {
                      widget.onSearchChanged(value.isEmpty ? null : value);
                    },
                    backgroundColor: WidgetStateProperty.all(
                      templateTheme.surfaceContainerHigh,
                    ),
                    elevation: WidgetStateProperty.all(0),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: templateTheme.templateCardBorder,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Filter Toggle Button
                IconButton.filledTonal(
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                    if (_showFilters) {
                      _filterAnimationController.forward();
                    } else {
                      _filterAnimationController.reverse();
                    }
                  },
                  icon: AnimatedRotation(
                    turns: _showFilters ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.tune),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _showFilters 
                        ? theme.colorScheme.primaryContainer
                        : templateTheme.surfaceContainerHigh,
                    foregroundColor: _showFilters
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                
                // Clear Filters Button
                if (_hasActiveFilters())
                  IconButton.outlined(
                    onPressed: widget.onClearFilters,
                    icon: const Icon(Icons.clear_all),
                    tooltip: 'Clear all filters',
                  ),
              ],
            ),
            
            // Animated Filter Section
            SizeTransition(
              sizeFactor: _filterAnimation,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Filter Chips Row 1
                  Row(
                    children: [
                      // Category Filter
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: _categories.map((category) {
                                final isSelected = widget.categoryFilter == category || 
                                    (widget.categoryFilter == null && category == 'All');
                                return FilterChip(
                                  label: Text(category),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    widget.onCategoryChanged(
                                      category == 'All' ? null : category,
                                    );
                                  },
                                  backgroundColor: templateTheme.surfaceContainerLow,
                                  selectedColor: templateTheme.getCategoryColor(category).withValues(alpha: 0.2),
                                  checkmarkColor: templateTheme.getCategoryColor(category),
                                  labelStyle: TextStyle(
                                    color: isSelected 
                                        ? templateTheme.getCategoryColor(category)
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: isSelected 
                                          ? templateTheme.getCategoryColor(category)
                                          : templateTheme.templateCardBorder,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Filter Chips Row 2
                  Row(
                    children: [
                      // Type Filter
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selection Type',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: _types.map((type) {
                                final isSelected = widget.typeFilter == type || 
                                    (widget.typeFilter == null && type == 'All');
                                return FilterChip(
                                  label: Text(type),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    widget.onTypeChanged(
                                      type == 'All' ? null : type,
                                    );
                                  },
                                  backgroundColor: templateTheme.surfaceContainerLow,
                                  selectedColor: theme.colorScheme.primaryContainer,
                                  checkmarkColor: theme.colorScheme.primary,
                                  labelStyle: TextStyle(
                                    color: isSelected 
                                        ? theme.colorScheme.onPrimaryContainer
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: isSelected 
                                          ? theme.colorScheme.primary
                                          : templateTheme.templateCardBorder,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Toggle Filters Row
                  Row(
                    children: [
                      // Required Filter
                      Expanded(
                        child: SwitchListTile.adaptive(
                          title: Text(
                            'Required Only',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            'Show only required templates',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          value: widget.showOnlyRequired,
                          onChanged: widget.onRequiredFilterChanged,
                          activeColor: templateTheme.templateRequiredColor,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Active Filter
                      Expanded(
                        child: SwitchListTile.adaptive(
                          title: Text(
                            'Active Only',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            'Show only active templates',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          value: widget.showOnlyActive,
                          onChanged: widget.onActiveFilterChanged,
                          activeColor: templateTheme.templateActiveColor,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return widget.searchQuery != null ||
        widget.categoryFilter != null ||
        widget.typeFilter != null ||
        widget.showOnlyRequired ||
        !widget.showOnlyActive;
  }
}
