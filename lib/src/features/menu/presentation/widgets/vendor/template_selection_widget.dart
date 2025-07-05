import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/customization_template_providers.dart';
import '../../../data/models/customization_template.dart';
import '../../../../../shared/widgets/loading_widget.dart';

/// Widget for selecting and applying customization templates to menu items
class TemplateSelectionWidget extends ConsumerStatefulWidget {
  final String vendorId;
  final List<String> selectedTemplateIds;
  final Function(List<CustomizationTemplate>) onTemplatesSelected;
  final bool showCreateOption;

  const TemplateSelectionWidget({
    super.key,
    required this.vendorId,
    required this.selectedTemplateIds,
    required this.onTemplatesSelected,
    this.showCreateOption = true,
  });

  @override
  ConsumerState<TemplateSelectionWidget> createState() => _TemplateSelectionWidgetState();
}

class _TemplateSelectionWidgetState extends ConsumerState<TemplateSelectionWidget> {
  String? _searchQuery;
  List<String> _selectedIds = [];

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedTemplateIds);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final templatesAsync = ref.watch(vendorTemplatesProvider(VendorTemplatesParams(
      vendorId: widget.vendorId,
      isActive: true,
      searchQuery: _searchQuery,
    )));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.layers, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Apply Templates',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (widget.showCreateOption)
                  TextButton.icon(
                    onPressed: _navigateToCreateTemplate,
                    icon: const Icon(Icons.add),
                    label: const Text('Create'),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Select existing templates to apply to this menu item. Templates provide pre-configured customization options.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search templates...',
                prefixIcon: const Icon(Icons.search),
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
            
            const SizedBox(height: 16),
            
            // Templates List
            SizedBox(
              height: 300,
              child: templatesAsync.when(
                data: (templates) => _buildTemplatesList(templates),
                loading: () => const LoadingWidget(message: 'Loading templates...'),
                error: (error, stack) => _buildErrorState(error.toString()),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Selected Templates Summary
            if (_selectedIds.isNotEmpty) _buildSelectedSummary(),
            
            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedIds.isNotEmpty ? _applySelectedTemplates : null,
                child: Text(_selectedIds.isEmpty 
                    ? 'Select templates to apply' 
                    : 'Apply ${_selectedIds.length} template${_selectedIds.length == 1 ? '' : 's'}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesList(List<CustomizationTemplate> templates) {
    final theme = Theme.of(context);

    if (templates.isEmpty) {
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
              'No templates found',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create your first template to get started',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        final isSelected = _selectedIds.contains(template.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (selected) => _toggleTemplateSelection(template.id, selected ?? false),
            title: Text(
              template.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (template.description != null && template.description!.isNotEmpty)
                  Text(
                    template.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
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
              ],
            ),
            secondary: Icon(
              template.isSingleSelection ? Icons.radio_button_checked : Icons.check_box,
              color: theme.colorScheme.primary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedSummary() {
    final theme = Theme.of(context);

    return Container(
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
            onPressed: _clearSelection,
            child: const Text('Clear'),
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
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            'Error loading templates',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            error,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleTemplateSelection(String templateId, bool selected) {
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
    setState(() {
      _selectedIds.clear();
    });
  }

  Future<void> _applySelectedTemplates() async {
    try {
      final templates = await ref.read(vendorTemplatesProvider(VendorTemplatesParams(
        vendorId: widget.vendorId,
        isActive: true,
      )).future);

      final selectedTemplates = templates.where((t) => _selectedIds.contains(t.id)).toList();
      widget.onTemplatesSelected(selectedTemplates);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading templates: $e')),
        );
      }
    }
  }

  void _navigateToCreateTemplate() {
    // TODO: Navigate to template creation screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template creation from menu item form coming soon')),
    );
  }
}
