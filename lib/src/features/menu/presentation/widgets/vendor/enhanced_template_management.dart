import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/customization_template.dart';
import '../../providers/customization_template_providers.dart';
import '../../../../../shared/widgets/loading_widget.dart';
import '../../screens/vendor/template_form_screen.dart';
import 'template_usage_analytics.dart';

/// Enhanced template management widget with advanced features
class EnhancedTemplateManagement extends ConsumerStatefulWidget {
  final String vendorId;
  final bool allowReordering;
  final bool showCategories;
  final bool showQuickCreate;
  final Function(List<CustomizationTemplate>)? onTemplatesReordered;

  const EnhancedTemplateManagement({
    super.key,
    required this.vendorId,
    this.allowReordering = true,
    this.showCategories = true,
    this.showQuickCreate = true,
    this.onTemplatesReordered,
  });

  @override
  ConsumerState<EnhancedTemplateManagement> createState() => _EnhancedTemplateManagementState();
}

class _EnhancedTemplateManagementState extends ConsumerState<EnhancedTemplateManagement>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCategory;
  String? _searchQuery;
  bool _showInactive = false;
  
  // Template categories
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
    _tabController = TabController(length: widget.showCategories ? 3 : 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header with controls
        _buildHeader(theme),
        
        // Tab Bar
        if (widget.showCategories)
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.layers), text: 'All Templates'),
              Tab(icon: Icon(Icons.category), text: 'By Category'),
              Tab(icon: Icon(Icons.analytics), text: 'Usage Analytics'),
            ],
          )
        else
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.layers), text: 'Templates'),
              Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            ],
          ),
        
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: widget.showCategories
                ? [
                    _buildAllTemplatesTab(),
                    _buildCategorizedTemplatesTab(),
                    _buildAnalyticsTab(),
                  ]
                : [
                    _buildAllTemplatesTab(),
                    _buildAnalyticsTab(),
                  ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Title and Quick Create
          Row(
            children: [
              Icon(
                Icons.layers,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Template Management',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.showQuickCreate)
                FilledButton.icon(
                  onPressed: _showQuickCreateDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Quick Create'),
                ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _refreshTemplates,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Search and Filters
          Row(
            children: [
              // Search Bar
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search templates...',
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.isEmpty ? null : value;
                    });
                  },
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Category Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  items: _categories.map((category) => DropdownMenuItem(
                    value: category == 'All' ? null : category,
                    child: Text(category),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Show Inactive Toggle
              FilterChip(
                label: const Text('Show Inactive'),
                selected: _showInactive,
                onSelected: (selected) {
                  setState(() {
                    _showInactive = selected;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllTemplatesTab() {
    final templatesAsync = ref.watch(vendorTemplatesProvider(VendorTemplatesParams(
      vendorId: widget.vendorId,
      isActive: _showInactive ? null : true,
      searchQuery: _searchQuery,
    )));

    return templatesAsync.when(
      data: (templates) {
        final filteredTemplates = _filterTemplates(templates);
        
        if (filteredTemplates.isEmpty) {
          return _buildEmptyState();
        }

        return widget.allowReordering
            ? _buildReorderableTemplateList(filteredTemplates)
            : _buildTemplateList(filteredTemplates);
      },
      loading: () => const LoadingWidget(message: 'Loading templates...'),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildCategorizedTemplatesTab() {
    final templatesAsync = ref.watch(vendorTemplatesProvider(VendorTemplatesParams(
      vendorId: widget.vendorId,
      isActive: _showInactive ? null : true,
    )));

    return templatesAsync.when(
      data: (templates) {
        final categorizedTemplates = _categorizeTemplates(templates);
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categorizedTemplates.keys.length,
          itemBuilder: (context, index) {
            final category = categorizedTemplates.keys.elementAt(index);
            final categoryTemplates = categorizedTemplates[category]!;
            
            return _buildCategorySection(category, categoryTemplates);
          },
        );
      },
      loading: () => const LoadingWidget(message: 'Loading templates...'),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildAnalyticsTab() {
    return TemplateUsageAnalytics(
      vendorId: widget.vendorId,
      showDetailedMetrics: true,
      showTrends: true,
    );
  }

  // Helper methods will be implemented in the next chunk
  List<CustomizationTemplate> _filterTemplates(List<CustomizationTemplate> templates) {
    return templates.where((template) {
      // Search filter
      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        final query = _searchQuery!.toLowerCase();
        if (!template.name.toLowerCase().contains(query) &&
            !(template.description?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      // Category filter
      if (_selectedCategory != null) {
        final category = _getCategoryFromTemplate(template);
        if (category != _selectedCategory) {
          return false;
        }
      }

      return true;
    }).toList();
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

  Map<String, List<CustomizationTemplate>> _categorizeTemplates(List<CustomizationTemplate> templates) {
    final categorized = <String, List<CustomizationTemplate>>{};
    
    for (final template in templates) {
      final category = _getCategoryFromTemplate(template);
      categorized.putIfAbsent(category, () => []).add(template);
    }
    
    return categorized;
  }

  Widget _buildReorderableTemplateList(List<CustomizationTemplate> templates) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Reorder Instructions
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.drag_handle,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Drag templates to reorder them. This affects the order they appear to customers.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Reorderable List
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: templates.length,
            onReorder: (oldIndex, newIndex) => _reorderTemplates(templates, oldIndex, newIndex),
            itemBuilder: (context, index) {
              final template = templates[index];
              return _buildEnhancedTemplateCard(template, index, key: ValueKey(template.id));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateList(List<CustomizationTemplate> templates) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _buildEnhancedTemplateCard(template, index);
      },
    );
  }

  Widget _buildEnhancedTemplateCard(CustomizationTemplate template, int index, {Key? key}) {
    final theme = Theme.of(context);
    final category = _getCategoryFromTemplate(template);

    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.allowReordering) ...[
              const Icon(Icons.drag_handle, size: 20),
              const SizedBox(width: 8),
            ],
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                template.isSingleSelection ? Icons.radio_button_checked : Icons.check_box,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                template.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Category Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                category,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Container(
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
              ),
            ),
            const SizedBox(width: 8),
            if (template.isRequired)
              Container(
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
                ),
              ),
            const Spacer(),
            Text(
              '${template.options.length} options',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Used ${template.usageCount}x',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: _buildTemplateActions(template),
        children: [
          _buildTemplateDetails(template),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String category, List<CustomizationTemplate> templates) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(
              _getCategoryIcon(category),
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              category,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${templates.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        children: templates.map((template) =>
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _buildEnhancedTemplateCard(template, templates.indexOf(template)),
          )
        ).toList(),
      ),
    );
  }

  Widget _buildTemplateActions(CustomizationTemplate template) {
    return PopupMenuButton<String>(
      onSelected: (action) => _handleTemplateAction(action, template),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit'),
            dense: true,
          ),
        ),
        const PopupMenuItem(
          value: 'duplicate',
          child: ListTile(
            leading: Icon(Icons.copy),
            title: Text('Duplicate'),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: 'toggle_active',
          child: ListTile(
            leading: Icon(template.isActive ? Icons.visibility_off : Icons.visibility),
            title: Text(template.isActive ? 'Deactivate' : 'Activate'),
            dense: true,
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Delete', style: TextStyle(color: Colors.red)),
            dense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateDetails(CustomizationTemplate template) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (template.description != null && template.description!.isNotEmpty) ...[
            Text(
              template.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
          ],

          Text(
            'Options:',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: template.options.map((option) => Chip(
              label: Text(option.name),
              avatar: option.additionalPrice > 0
                  ? CircleAvatar(
                      radius: 8,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        '+${option.additionalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 8,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : null,
              backgroundColor: option.isDefault
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
            )).toList(),
          ),
        ],
      ),
    );
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
            'Create your first template to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.showQuickCreate)
            FilledButton.icon(
              onPressed: _showQuickCreateDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Template'),
            ),
        ],
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
          const SizedBox(height: 16),
          TextButton(
            onPressed: _refreshTemplates,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Size Options':
        return Icons.straighten;
      case 'Add-ons':
        return Icons.add_circle_outline;
      case 'Spice Level':
        return Icons.local_fire_department;
      case 'Cooking Style':
        return Icons.restaurant;
      case 'Dietary':
        return Icons.eco;
      default:
        return Icons.category;
    }
  }

  void _reorderTemplates(List<CustomizationTemplate> templates, int oldIndex, int newIndex) {
    debugPrint('🔧 [ENHANCED-TEMPLATE-MGMT] Reordering templates: $oldIndex -> $newIndex');

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final reorderedTemplates = List<CustomizationTemplate>.from(templates);
    final item = reorderedTemplates.removeAt(oldIndex);
    reorderedTemplates.insert(newIndex, item);

    // Notify parent about reordering
    widget.onTemplatesReordered?.call(reorderedTemplates);

    // TODO: Persist the new order to the database
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template order updated')),
    );
  }

  void _handleTemplateAction(String action, CustomizationTemplate template) {
    debugPrint('🔧 [ENHANCED-TEMPLATE-MGMT] Template action: $action for ${template.name}');

    switch (action) {
      case 'edit':
        _navigateToEditTemplate(template.id);
        break;
      case 'duplicate':
        _duplicateTemplate(template);
        break;
      case 'toggle_active':
        _toggleTemplateActive(template);
        break;
      case 'delete':
        _showDeleteConfirmation(template);
        break;
    }
  }

  void _navigateToEditTemplate(String templateId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TemplateFormScreen(
          vendorId: widget.vendorId,
          templateId: templateId,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _refreshTemplates();
      }
    });
  }

  void _duplicateTemplate(CustomizationTemplate template) {
    // TODO: Implement template duplication
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template duplication coming soon')),
    );
  }

  void _toggleTemplateActive(CustomizationTemplate template) {
    // TODO: Implement template activation toggle
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(template.isActive
            ? 'Template deactivated'
            : 'Template activated'),
      ),
    );
  }

  void _showDeleteConfirmation(CustomizationTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Are you sure you want to delete "${template.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTemplate(template);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteTemplate(CustomizationTemplate template) {
    // TODO: Implement template deletion
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template deletion coming soon')),
    );
  }

  void _showQuickCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => _QuickCreateTemplateDialog(vendorId: widget.vendorId),
    ).then((result) {
      if (result == true) {
        _refreshTemplates();
      }
    });
  }

  void _refreshTemplates() {
    debugPrint('🔧 [ENHANCED-TEMPLATE-MGMT] Refreshing templates');
    ref.invalidate(vendorTemplatesProvider);
  }
}

/// Quick create template dialog
class _QuickCreateTemplateDialog extends StatefulWidget {
  final String vendorId;

  const _QuickCreateTemplateDialog({required this.vendorId});

  @override
  State<_QuickCreateTemplateDialog> createState() => _QuickCreateTemplateDialogState();
}

class _QuickCreateTemplateDialogState extends State<_QuickCreateTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedTemplate = 'size_options';

  final Map<String, Map<String, dynamic>> _quickTemplates = {
    'size_options': {
      'name': 'Size Options',
      'type': 'single',
      'options': ['Small', 'Medium', 'Large'],
      'prices': [0.0, 2.0, 4.0],
    },
    'spice_level': {
      'name': 'Spice Level',
      'type': 'single',
      'options': ['Mild', 'Medium', 'Hot', 'Extra Hot'],
      'prices': [0.0, 0.0, 0.0, 0.0],
    },
    'add_ons': {
      'name': 'Add-ons',
      'type': 'multiple',
      'options': ['Extra Cheese', 'Extra Sauce', 'Extra Vegetables'],
      'prices': [2.0, 1.0, 1.5],
    },
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedTemplate = _quickTemplates[_selectedTemplate]!;

    return AlertDialog(
      title: const Text('Quick Create Template'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Template Type Selection
            DropdownButtonFormField<String>(
              initialValue: _selectedTemplate,
              decoration: const InputDecoration(
                labelText: 'Template Type',
                border: OutlineInputBorder(),
              ),
              items: _quickTemplates.entries.map((entry) => DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value['name']),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTemplate = value!;
                  _nameController.text = _quickTemplates[value]!['name'];
                });
              },
            ),

            const SizedBox(height: 16),

            // Template Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Template Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a template name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview:',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(selectedTemplate['options'].length, (index) {
                    final option = selectedTemplate['options'][index];
                    final price = selectedTemplate['prices'][index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            selectedTemplate['type'] == 'single'
                                ? Icons.radio_button_unchecked
                                : Icons.check_box_outline_blank,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(option),
                          if (price > 0) ...[
                            const Spacer(),
                            Text(
                              '+RM${price.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _createQuickTemplate,
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _createQuickTemplate() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement quick template creation
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quick template creation coming soon')),
      );
    }
  }
}
