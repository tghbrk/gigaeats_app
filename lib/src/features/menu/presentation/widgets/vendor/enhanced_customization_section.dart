import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/customization_template.dart';
import 'enhanced_template_selector.dart';
import 'customer_preview_component.dart';
import '../../utils/template_debug_logger.dart';

/// Template-only customization section for menu items
class EnhancedCustomizationSection extends ConsumerStatefulWidget {
  final String vendorId;
  final List<CustomizationTemplate> linkedTemplates;
  final Function(List<CustomizationTemplate>) onTemplatesChanged;
  final String menuItemName;
  final double basePrice;

  const EnhancedCustomizationSection({
    super.key,
    required this.vendorId,
    required this.linkedTemplates,
    required this.onTemplatesChanged,
    required this.menuItemName,
    required this.basePrice,
  });

  @override
  ConsumerState<EnhancedCustomizationSection> createState() => _EnhancedCustomizationSectionState();
}

class _EnhancedCustomizationSectionState extends ConsumerState<EnhancedCustomizationSection>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _showTemplateSelector = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    TemplateDebugLogger.logUIInteraction(
      component: 'EnhancedCustomizationSection',
      action: 'initialized',
      context: {
        'vendorId': widget.vendorId,
        'menuItemName': widget.menuItemName,
        'basePrice': widget.basePrice,
        'linkedTemplatesCount': widget.linkedTemplates.length,
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    debugPrint('🔧 [ENHANCED-CUSTOMIZATION-SECTION] Building with ${widget.linkedTemplates.length} linked templates');
    for (int i = 0; i < widget.linkedTemplates.length; i++) {
      final template = widget.linkedTemplates[i];
      debugPrint('🔧 [ENHANCED-CUSTOMIZATION-SECTION] Template $i: ${template.name} (${template.id}) with ${template.options.length} options');
    }

    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(theme),

          // Template Selector (when expanded)
          if (_showTemplateSelector) ...[
            EnhancedTemplateSelector(
              vendorId: widget.vendorId,
              selectedTemplateIds: widget.linkedTemplates.map((t) => t.id).toList(),
              onTemplatesSelected: _onTemplatesSelected,
              showCreateOption: true,
              showPreview: false, // We have a separate preview section
              allowReordering: true,
            ),
            const Divider(height: 1),
          ],

          // Main Content Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(Icons.layers),
                text: 'Applied Templates',
              ),
              Tab(
                icon: Icon(Icons.preview),
                text: 'Customer Preview',
              ),
            ],
          ),

          // Tab Content
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAppliedTemplatesTab(),
                _buildCustomerPreviewTab(),
              ],
            ),
          ),

          // Summary Footer
          _buildSummaryFooter(theme),
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
                  'Template Management',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'Configure customization options using reusable templates',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          // Template count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.linkedTemplates.length}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Template selector toggle
          IconButton(
            onPressed: () {
              debugPrint('🔧 [ENHANCED-CUSTOMIZATION] Toggling template selector: $_showTemplateSelector');
              setState(() {
                _showTemplateSelector = !_showTemplateSelector;
              });
            },
            icon: Icon(_showTemplateSelector ? Icons.close : Icons.add),
            tooltip: _showTemplateSelector ? 'Close Template Selector' : 'Add Templates',
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              foregroundColor: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppliedTemplatesTab() {
    final theme = Theme.of(context);

    debugPrint('🔧 [ENHANCED-CUSTOMIZATION-SECTION] Building applied templates tab with ${widget.linkedTemplates.length} templates');

    if (widget.linkedTemplates.isEmpty) {
      debugPrint('🔧 [ENHANCED-CUSTOMIZATION-SECTION] No templates found, showing empty state');
      return _buildEmptyTemplatesState(theme);
    }

    debugPrint('🔧 [ENHANCED-CUSTOMIZATION-SECTION] Building template list with ${widget.linkedTemplates.length} templates');

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
                  'Templates are applied in the order shown. Drag to reorder how customers see them.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Templates List
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.linkedTemplates.length,
            onReorder: _reorderTemplates,
            itemBuilder: (context, index) {
              final template = widget.linkedTemplates[index];
              return _buildAppliedTemplateCard(template, index, key: ValueKey(template.id));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerPreviewTab() {
    return CustomerPreviewComponent(
      selectedTemplates: widget.linkedTemplates,
      menuItemName: widget.menuItemName,
      basePrice: widget.basePrice,
      showInteractive: true,
    );
  }

  Widget _buildEmptyTemplatesState(ThemeData theme) {
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
            'No Templates Applied',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add templates to provide customization options for customers',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              setState(() {
                _showTemplateSelector = true;
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Templates'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppliedTemplateCard(CustomizationTemplate template, int index, {Key? key}) {
    final theme = Theme.of(context);

    debugPrint('🔧 [ENHANCED-CUSTOMIZATION-SECTION] Building applied template card for: ${template.name} (index: $index) with ${template.options.length} options');

    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.drag_handle, size: 20),
            const SizedBox(width: 8),
            Icon(
              template.isSingleSelection ? Icons.radio_button_checked : Icons.check_box,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
        title: Text(
          template.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
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
            const Spacer(),
            Text(
              '${template.options.length} options',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () => _removeTemplate(index),
          tooltip: 'Remove Template',
          style: IconButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
          ),
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
                  const SizedBox(height: 12),
                ],
                Text(
                  'Options Preview:',
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
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryFooter(ThemeData theme) {
    final templateCount = widget.linkedTemplates.length;
    final totalOptions = widget.linkedTemplates.fold<int>(
      0,
      (sum, template) => sum + template.options.length,
    );

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
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              templateCount == 0
                  ? 'No templates applied. Add templates to provide customization options.'
                  : '$templateCount template${templateCount == 1 ? '' : 's'} applied with $totalOptions total options',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (templateCount > 0) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => _tabController.animateTo(1),
              child: const Text('Preview'),
            ),
          ],
        ],
      ),
    );
  }

  // Action Methods
  void _onTemplatesSelected(List<CustomizationTemplate> templates) {
    final session = TemplateDebugLogger.createSession('template_selection');

    session.addEvent('Templates selection started');
    session.addEvent('Previous templates count: ${widget.linkedTemplates.length}');
    session.addEvent('New templates count: ${templates.length}');

    // Log individual template changes
    final previousIds = widget.linkedTemplates.map((t) => t.id).toSet();
    final newIds = templates.map((t) => t.id).toSet();

    final added = newIds.difference(previousIds);
    final removed = previousIds.difference(newIds);

    for (final templateId in added) {
      final template = templates.firstWhere((t) => t.id == templateId);
      TemplateDebugLogger.logTemplateSelection(
        templateId: templateId,
        templateName: template.name,
        menuItemId: widget.menuItemName,
        action: 'selected',
        metadata: {
          'category': _getCategoryFromTemplate(template),
          'type': template.isSingleSelection ? 'single' : 'multiple',
          'required': template.isRequired,
          'optionsCount': template.options.length,
        },
      );
    }

    for (final templateId in removed) {
      final template = widget.linkedTemplates.firstWhere((t) => t.id == templateId);
      TemplateDebugLogger.logTemplateSelection(
        templateId: templateId,
        templateName: template.name,
        menuItemId: widget.menuItemName,
        action: 'deselected',
      );
    }

    session.addEvent('Template changes processed');

    try {
      widget.onTemplatesChanged(templates);
      session.addEvent('Parent callback executed successfully');

      setState(() {
        _showTemplateSelector = false;
      });
      session.addEvent('UI state updated');

      TemplateDebugLogger.logSuccess(
        operation: 'template_selection',
        message: 'Templates updated successfully',
        data: {
          'totalTemplates': templates.length,
          'addedCount': added.length,
          'removedCount': removed.length,
        },
      );

      session.complete('success');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Applied ${templates.length} template${templates.length == 1 ? '' : 's'}'),
          action: templates.isNotEmpty ? SnackBarAction(
            label: 'Preview',
            onPressed: () => _tabController.animateTo(1),
          ) : null,
        ),
      );
    } catch (error, stackTrace) {
      TemplateDebugLogger.logError(
        operation: 'template_selection',
        error: error,
        stackTrace: stackTrace,
        context: {
          'templatesCount': templates.length,
          'menuItemName': widget.menuItemName,
        },
      );

      session.complete('error: $error');
    }
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

  void _removeTemplate(int index) {
    debugPrint('🔧 [ENHANCED-CUSTOMIZATION] Removing template at index: $index');
    final template = widget.linkedTemplates[index];
    final updatedTemplates = List<CustomizationTemplate>.from(widget.linkedTemplates);
    updatedTemplates.removeAt(index);
    widget.onTemplatesChanged(updatedTemplates);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed template: ${template.name}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            final restoredTemplates = List<CustomizationTemplate>.from(updatedTemplates);
            restoredTemplates.insert(index, template);
            widget.onTemplatesChanged(restoredTemplates);
          },
        ),
      ),
    );
  }

  void _reorderTemplates(int oldIndex, int newIndex) {
    debugPrint('🔧 [ENHANCED-CUSTOMIZATION] Reordering templates: $oldIndex -> $newIndex');
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final updatedTemplates = List<CustomizationTemplate>.from(widget.linkedTemplates);
      final item = updatedTemplates.removeAt(oldIndex);
      updatedTemplates.insert(newIndex, item);
      widget.onTemplatesChanged(updatedTemplates);
    });
  }
}
