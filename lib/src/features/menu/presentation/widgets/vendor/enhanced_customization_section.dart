import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/customization_template.dart';
import '../../../data/models/product.dart' as product_model;
import 'template_selection_widget.dart';

/// Enhanced customization section that supports both templates and direct customizations
class EnhancedCustomizationSection extends ConsumerStatefulWidget {
  final String vendorId;
  final List<product_model.MenuItemCustomization> customizations;
  final List<CustomizationTemplate> linkedTemplates;
  final Function(List<product_model.MenuItemCustomization>) onCustomizationsChanged;
  final Function(List<CustomizationTemplate>) onTemplatesChanged;

  const EnhancedCustomizationSection({
    super.key,
    required this.vendorId,
    required this.customizations,
    required this.linkedTemplates,
    required this.onCustomizationsChanged,
    required this.onTemplatesChanged,
  });

  @override
  ConsumerState<EnhancedCustomizationSection> createState() => _EnhancedCustomizationSectionState();
}

class _EnhancedCustomizationSectionState extends ConsumerState<EnhancedCustomizationSection>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _showTemplateSelection = false;

  @override
  void initState() {
    super.initState();
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.tune, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Customizations',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showTemplateSelection = !_showTemplateSelection;
                    });
                  },
                  icon: Icon(_showTemplateSelection ? Icons.close : Icons.layers),
                  tooltip: _showTemplateSelection ? 'Close Templates' : 'Apply Templates',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Template Selection (when expanded)
            if (_showTemplateSelection) ...[
              TemplateSelectionWidget(
                vendorId: widget.vendorId,
                selectedTemplateIds: widget.linkedTemplates.map((t) => t.id).toList(),
                onTemplatesSelected: _onTemplatesSelected,
              ),
              const SizedBox(height: 16),
            ],
            
            // Tabs for Templates and Direct Customizations
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.layers, size: 16),
                      const SizedBox(width: 4),
                      Text('Templates (${widget.linkedTemplates.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tune, size: 16),
                      const SizedBox(width: 4),
                      Text('Direct (${widget.customizations.length})'),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Tab Content
            SizedBox(
              height: 300,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTemplatesTab(),
                  _buildDirectCustomizationsTab(),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Summary
            _buildSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesTab() {
    final theme = Theme.of(context);

    if (widget.linkedTemplates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.layers_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'No Templates Applied',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Click the templates icon above to apply existing templates',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.linkedTemplates.length,
      itemBuilder: (context, index) {
        final template = widget.linkedTemplates[index];
        return _buildTemplateCard(template, index);
      },
    );
  }

  Widget _buildTemplateCard(CustomizationTemplate template, int index) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(
          template.isSingleSelection ? Icons.radio_button_checked : Icons.check_box,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          template.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
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
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () => _removeTemplate(index),
          tooltip: 'Remove Template',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (template.description != null && template.description!.isNotEmpty) ...[
                  Text(
                    template.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  'Options:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: template.options.map((option) => Chip(
                    label: Text(option.name),
                    avatar: option.hasAdditionalCost 
                        ? Text(option.formattedPrice, style: const TextStyle(fontSize: 10))
                        : null,
                    backgroundColor: option.isDefault 
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectCustomizationsTab() {
    final theme = Theme.of(context);

    if (widget.customizations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tune,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'No Direct Customizations',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add custom options specific to this menu item',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addDirectCustomization,
              icon: const Icon(Icons.add),
              label: const Text('Add Customization'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Direct Customizations',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _addDirectCustomization,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: widget.customizations.length,
            itemBuilder: (context, index) {
              final customization = widget.customizations[index];
              return _buildDirectCustomizationCard(customization, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDirectCustomizationCard(product_model.MenuItemCustomization customization, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(customization.name),
        subtitle: Text('${customization.type}, ${customization.isRequired ? "Required" : "Optional"}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editDirectCustomization(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _removeDirectCustomization(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final theme = Theme.of(context);
    final totalCustomizations = widget.linkedTemplates.length + widget.customizations.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              totalCustomizations == 0
                  ? 'No customizations configured'
                  : '$totalCustomizations customization${totalCustomizations == 1 ? '' : 's'} configured (${widget.linkedTemplates.length} from templates, ${widget.customizations.length} direct)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onTemplatesSelected(List<CustomizationTemplate> templates) {
    widget.onTemplatesChanged(templates);
    setState(() {
      _showTemplateSelection = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied ${templates.length} template${templates.length == 1 ? '' : 's'}'),
      ),
    );
  }

  void _removeTemplate(int index) {
    final updatedTemplates = List<CustomizationTemplate>.from(widget.linkedTemplates);
    updatedTemplates.removeAt(index);
    widget.onTemplatesChanged(updatedTemplates);
  }

  void _addDirectCustomization() {
    // TODO: Show dialog to add direct customization
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Direct customization creation coming soon')),
    );
  }

  void _editDirectCustomization(int index) {
    // TODO: Show dialog to edit direct customization
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Direct customization editing coming soon')),
    );
  }

  void _removeDirectCustomization(int index) {
    final updatedCustomizations = List<product_model.MenuItemCustomization>.from(widget.customizations);
    updatedCustomizations.removeAt(index);
    widget.onCustomizationsChanged(updatedCustomizations);
  }
}
