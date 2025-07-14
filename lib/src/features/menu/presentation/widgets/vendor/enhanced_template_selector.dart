import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/customization_template.dart';
import '../../providers/customization_template_providers.dart';
import '../../../../../shared/widgets/loading_widget.dart';
import '../../screens/vendor/template_form_screen.dart';
import '../../utils/template_debug_logger.dart';

/// Enhanced template selection widget with advanced features
class EnhancedTemplateSelector extends ConsumerStatefulWidget {
  final String vendorId;
  final List<String> selectedTemplateIds;
  final Function(List<CustomizationTemplate>) onTemplatesSelected;
  final bool showCreateOption;
  final bool showPreview;
  final bool allowReordering;

  const EnhancedTemplateSelector({
    super.key,
    required this.vendorId,
    required this.selectedTemplateIds,
    required this.onTemplatesSelected,
    this.showCreateOption = true,
    this.showPreview = true,
    this.allowReordering = true,
  });

  @override
  ConsumerState<EnhancedTemplateSelector> createState() => _EnhancedTemplateSelectorState();
}

class _EnhancedTemplateSelectorState extends ConsumerState<EnhancedTemplateSelector>
    with TickerProviderStateMixin {
  String? _searchQuery;
  String? _categoryFilter;
  String? _typeFilter;
  bool _showOnlyRequired = false;
  bool _showOnlyAvailable = true;
  List<String> _selectedIds = [];
  
  late TabController _tabController;
  
  // Categories for filtering
  final List<String> _categories = [
    'All',
    'Size Options',
    'Add-ons',
    'Spice Level',
    'Cooking Style',
    'Dietary',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedTemplateIds);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(theme),
          
          // Filters and Search
          _buildFiltersSection(theme),
          
          // Tab Bar
          Container(
            height: 48, // Standard Material Design tab height
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.grid_view, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Browse Templates',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.checklist, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Selected Templates',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Tab Content
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBrowseTab(),
                _buildSelectedTab(),
              ],
            ),
          ),
          
          // Action Buttons
          _buildActionButtons(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.layers,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Template Selection',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'Choose from existing templates or create new ones',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (widget.showCreateOption)
            FilledButton.icon(
              onPressed: _navigateToCreateTemplate,
              icon: const Icon(Icons.add),
              label: const Text('Create'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search templates by name or description...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = null;
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
            onChanged: (value) {
              final newQuery = value.isEmpty ? null : value;
              TemplateDebugLogger.logUIInteraction(
                component: 'EnhancedTemplateSelector',
                action: 'search',
                target: 'search_field',
                context: {
                  'query': newQuery,
                  'previousQuery': _searchQuery,
                  'vendorId': widget.vendorId,
                },
              );

              setState(() {
                _searchQuery = newQuery;
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Category Filter
                _buildFilterChip(
                  'Category: ${_categoryFilter ?? 'All'}',
                  Icons.category,
                  () => _showCategoryFilter(),
                ),
                const SizedBox(width: 8),
                
                // Type Filter
                _buildFilterChip(
                  'Type: ${_typeFilter ?? 'All'}',
                  Icons.tune,
                  () => _showTypeFilter(),
                ),
                const SizedBox(width: 8),
                
                // Required Filter
                FilterChip(
                  label: const Text('Required Only'),
                  selected: _showOnlyRequired,
                  onSelected: (selected) {
                    TemplateDebugLogger.logUIInteraction(
                      component: 'EnhancedTemplateSelector',
                      action: 'filter_toggle',
                      target: 'required_filter',
                      context: {
                        'selected': selected,
                        'previousValue': _showOnlyRequired,
                      },
                    );

                    setState(() {
                      _showOnlyRequired = selected;
                    });
                  },
                ),
                const SizedBox(width: 8),
                
                // Available Filter
                FilterChip(
                  label: const Text('Available Only'),
                  selected: _showOnlyAvailable,
                  onSelected: (selected) {
                    setState(() {
                      _showOnlyAvailable = selected;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    return ActionChip(
      label: Text(label),
      avatar: Icon(icon, size: 16),
      onPressed: onTap,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
    );
  }

  Widget _buildBrowseTab() {
    final templatesAsync = ref.watch(vendorTemplatesProvider(VendorTemplatesParams(
      vendorId: widget.vendorId,
      isActive: _showOnlyAvailable,
      searchQuery: _searchQuery,
    )));

    return templatesAsync.when(
      data: (templates) {
        final filteredTemplates = _filterTemplates(templates);

        if (filteredTemplates.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            // Selection Summary
            if (_selectedIds.isNotEmpty) _buildSelectionSummary(),

            // Templates Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65, // Reduced from 0.8 to give more height
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: filteredTemplates.length,
                itemBuilder: (context, index) {
                  final template = filteredTemplates[index];
                  final isSelected = _selectedIds.contains(template.id);
                  return _buildTemplateCard(template, isSelected);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const LoadingWidget(message: 'Loading templates...'),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildSelectedTab() {
    if (_selectedIds.isEmpty) {
      return _buildEmptySelectedState();
    }

    final templatesAsync = ref.watch(vendorTemplatesProvider(VendorTemplatesParams(
      vendorId: widget.vendorId,
      isActive: true,
    )));

    return templatesAsync.when(
      data: (allTemplates) {
        final selectedTemplates = allTemplates
            .where((t) => _selectedIds.contains(t.id))
            .toList();

        return Column(
          children: [
            // Reorder Instructions
            if (widget.allowReordering)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.drag_handle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Drag to reorder templates. This affects the order customers see them.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Selected Templates List
            Expanded(
              child: widget.allowReordering
                  ? ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: selectedTemplates.length,
                      onReorder: (oldIndex, newIndex) => _reorderTemplates(oldIndex, newIndex),
                      itemBuilder: (context, index) {
                        final template = selectedTemplates[index];
                        return _buildSelectedTemplateCard(template, index, key: ValueKey(template.id));
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: selectedTemplates.length,
                      itemBuilder: (context, index) {
                        final template = selectedTemplates[index];
                        return _buildSelectedTemplateCard(template, index);
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const LoadingWidget(message: 'Loading selected templates...'),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          // Selection Info
          Expanded(
            child: Text(
              '${_selectedIds.length} template${_selectedIds.length == 1 ? '' : 's'} selected',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Clear Selection
          if (_selectedIds.isNotEmpty)
            TextButton(
              onPressed: _clearSelection,
              child: const Text('Clear All'),
            ),

          const SizedBox(width: 8),

          // Apply Templates
          FilledButton(
            onPressed: _selectedIds.isNotEmpty ? _applySelectedTemplates : null,
            child: const Text('Apply Templates'),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  List<CustomizationTemplate> _filterTemplates(List<CustomizationTemplate> templates) {
    var filtered = templates.where((template) {
      // Search filter
      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        final query = _searchQuery!.toLowerCase();
        if (!template.name.toLowerCase().contains(query) &&
            !(template.description?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      // Category filter
      if (_categoryFilter != null && _categoryFilter != 'All') {
        final category = _getCategoryFromTemplate(template);
        if (category != _categoryFilter) {
          return false;
        }
      }

      // Type filter
      if (_typeFilter != null && _typeFilter != 'All') {
        if (template.type != _typeFilter) {
          return false;
        }
      }

      // Required filter
      if (_showOnlyRequired && !template.isRequired) {
        return false;
      }

      // Available filter
      if (_showOnlyAvailable && !template.isActive) {
        return false;
      }

      return true;
    }).toList();

    // Sort by usage count and name
    filtered.sort((a, b) {
      final usageComparison = b.usageCount.compareTo(a.usageCount);
      if (usageComparison != 0) return usageComparison;
      return a.name.compareTo(b.name);
    });

    return filtered;
  }

  String _getCategoryFromTemplate(CustomizationTemplate template) {
    final name = template.name.toLowerCase();
    if (name.contains('size') || name.contains('portion')) return 'Size Options';
    if (name.contains('add') || name.contains('extra')) return 'Add-ons';
    if (name.contains('spice') || name.contains('level')) return 'Spice Level';
    if (name.contains('cook') || name.contains('style')) return 'Cooking Style';
    if (name.contains('diet') || name.contains('vegan') || name.contains('halal')) return 'Dietary';
    return 'Other';
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.layers_clear,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Templates Found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or create a new template',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.showCreateOption)
            FilledButton.icon(
              onPressed: _navigateToCreateTemplate,
              icon: const Icon(Icons.add),
              label: const Text('Create Template'),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptySelectedState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checklist,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Templates Selected',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse templates and select the ones you want to apply',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _tabController.animateTo(0),
            child: const Text('Browse Templates'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionSummary() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_selectedIds.length} template${_selectedIds.length == 1 ? '' : 's'} selected',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _tabController.animateTo(1),
            child: const Text('View Selected'),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(CustomizationTemplate template, bool isSelected) {
    final theme = Theme.of(context);
    return Card(
      elevation: isSelected ? 4 : 1,
      child: InkWell(
        onTap: () => _toggleTemplateSelection(template.id, !isSelected),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with checkbox
              Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) => _toggleTemplateSelection(template.id, value ?? false),
                  ),
                  Expanded(
                    child: Text(
                      template.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4), // Reduced from 8 to 4

              // Type and Required badges
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        template.isSingleSelection ? 'Single' : 'Multiple',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (template.isRequired)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Required',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 4), // Reduced from 8 to 4

              // Description
              if (template.description != null && template.description!.isNotEmpty) ...[
                Text(
                  template.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],

              // Options count and usage
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${template.options.length} options',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (template.usageCount > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Used ${template.usageCount}x',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTemplateCard(CustomizationTemplate template, int index, {Key? key}) {
    final theme = Theme.of(context);
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: widget.allowReordering
            ? const Icon(Icons.drag_handle)
            : Icon(
                template.isSingleSelection ? Icons.radio_button_checked : Icons.check_box,
                color: theme.colorScheme.primary,
              ),
        title: Text(
          template.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          '${template.options.length} options • ${template.type}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () => _toggleTemplateSelection(template.id, false),
          tooltip: 'Remove Template',
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Templates',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // Action Methods
  void _toggleTemplateSelection(String templateId, bool selected) {
    debugPrint('🔧 [ENHANCED-TEMPLATE-SELECTOR] Toggling template $templateId: $selected');
    setState(() {
      if (selected) {
        if (!_selectedIds.contains(templateId)) {
          _selectedIds.add(templateId);
        }
      } else {
        _selectedIds.remove(templateId);
      }
    });
  }

  void _clearSelection() {
    debugPrint('🔧 [ENHANCED-TEMPLATE-SELECTOR] Clearing all selections');
    setState(() {
      _selectedIds.clear();
    });
  }

  void _reorderTemplates(int oldIndex, int newIndex) {
    debugPrint('🔧 [ENHANCED-TEMPLATE-SELECTOR] Reordering templates: $oldIndex -> $newIndex');
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _selectedIds.removeAt(oldIndex);
      _selectedIds.insert(newIndex, item);
    });
  }

  Future<void> _applySelectedTemplates() async {
    debugPrint('🔧 [ENHANCED-TEMPLATE-SELECTOR] Applying ${_selectedIds.length} selected templates');
    try {
      final templates = await ref.read(vendorTemplatesProvider(VendorTemplatesParams(
        vendorId: widget.vendorId,
        isActive: true,
      )).future);

      final selectedTemplates = templates.where((t) => _selectedIds.contains(t.id)).toList();

      // Maintain the order from _selectedIds
      selectedTemplates.sort((a, b) {
        final aIndex = _selectedIds.indexOf(a.id);
        final bIndex = _selectedIds.indexOf(b.id);
        return aIndex.compareTo(bIndex);
      });

      widget.onTemplatesSelected(selectedTemplates);
    } catch (e) {
      debugPrint('❌ [ENHANCED-TEMPLATE-SELECTOR] Error applying templates: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading templates: $e')),
        );
      }
    }
  }

  Future<void> _navigateToCreateTemplate() async {
    debugPrint('🔧 [ENHANCED-TEMPLATE-SELECTOR] Navigating to create template');
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => TemplateFormScreen(vendorId: widget.vendorId),
      ),
    );

    if (result == true && mounted) {
      // Refresh templates after creation
      ref.invalidate(vendorTemplatesProvider);
    }
  }

  void _showCategoryFilter() {
    debugPrint('🔧 [ENHANCED-TEMPLATE-SELECTOR] Showing category filter');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _categories.map((category) => RadioListTile<String?>(
            title: Text(category),
            value: category == 'All' ? null : category,
            groupValue: _categoryFilter,
            onChanged: (value) {
              setState(() {
                _categoryFilter = value;
              });
              Navigator.of(context).pop();
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showTypeFilter() {
    debugPrint('🔧 [ENHANCED-TEMPLATE-SELECTOR] Showing type filter');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String?>(
              title: const Text('All Types'),
              value: null,
              groupValue: _typeFilter,
              onChanged: (value) {
                setState(() {
                  _typeFilter = value;
                });
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String?>(
              title: const Text('Single Selection'),
              value: 'single',
              groupValue: _typeFilter,
              onChanged: (value) {
                setState(() {
                  _typeFilter = value;
                });
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String?>(
              title: const Text('Multiple Selection'),
              value: 'multiple',
              groupValue: _typeFilter,
              onChanged: (value) {
                setState(() {
                  _typeFilter = value;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
