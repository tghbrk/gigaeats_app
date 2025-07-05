import 'package:flutter/material.dart';
import '../../../data/models/customization_template.dart';

/// Widget for selecting multiple templates for bulk operations
class BulkTemplateSelector extends StatefulWidget {
  final List<CustomizationTemplate> templates;
  final List<String> selectedTemplateIds;
  final Function(List<String>) onSelectionChanged;

  const BulkTemplateSelector({
    super.key,
    required this.templates,
    required this.selectedTemplateIds,
    required this.onSelectionChanged,
  });

  @override
  State<BulkTemplateSelector> createState() => _BulkTemplateSelectorState();
}

class _BulkTemplateSelectorState extends State<BulkTemplateSelector> {
  String? _searchQuery;
  String? _typeFilter;
  bool _showOnlyRequired = false;

  List<CustomizationTemplate> get _filteredTemplates {
    var templates = widget.templates;

    // Apply search filter
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      templates = templates.where((template) =>
          template.name.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
          (template.description?.toLowerCase().contains(_searchQuery!.toLowerCase()) ?? false)
      ).toList();
    }

    // Apply type filter
    if (_typeFilter != null) {
      templates = templates.where((template) => template.type == _typeFilter).toList();
    }

    // Apply required filter
    if (_showOnlyRequired) {
      templates = templates.where((template) => template.isRequired).toList();
    }

    return templates;
  }

  @override
  Widget build(BuildContext context) {
    final filteredTemplates = _filteredTemplates;

    return Column(
      children: [
        // Filters Section
        _buildFiltersSection(),
        
        // Selection Actions
        _buildSelectionActions(filteredTemplates),
        
        // Templates List
        Expanded(
          child: filteredTemplates.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredTemplates.length,
                  itemBuilder: (context, index) {
                    final template = filteredTemplates[index];
                    final isSelected = widget.selectedTemplateIds.contains(template.id);
                    return _buildTemplateCard(template, isSelected);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search templates...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.isEmpty ? null : value;
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Filter Chips
          Row(
            children: [
              // Type Filter
              DropdownButton<String?>(
                value: _typeFilter,
                hint: const Text('All Types'),
                items: const [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Types'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'single',
                    child: Text('Single Selection'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'multiple',
                    child: Text('Multiple Selection'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _typeFilter = value;
                  });
                },
              ),
              
              const SizedBox(width: 12),
              
              // Required Filter
              FilterChip(
                label: const Text('Required Only'),
                selected: _showOnlyRequired,
                onSelected: (selected) {
                  setState(() {
                    _showOnlyRequired = selected;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionActions(List<CustomizationTemplate> filteredTemplates) {
    final theme = Theme.of(context);
    final selectedCount = widget.selectedTemplateIds.length;
    final totalCount = filteredTemplates.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$selectedCount of ${widget.templates.length} templates selected',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Select All Filtered - Use shorter text and flexible layout
          Flexible(
            child: TextButton(
              onPressed: totalCount > 0 ? () => _selectAllFiltered(filteredTemplates) : null,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Select All',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Clear Selection - Use shorter text and flexible layout
          Flexible(
            child: TextButton(
              onPressed: selectedCount > 0 ? _clearSelection : null,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Clear',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(CustomizationTemplate template, bool isSelected) {
    final theme = Theme.of(context);

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
            if (template.description != null && template.description!.isNotEmpty) ...[
              Text(
                template.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
            ],
            
            // Template Info Row
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
                
                const SizedBox(width: 8),
                
                Text(
                  'Used: ${template.usageCount}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Options Preview
            if (template.options.isNotEmpty) ...[
              Text(
                'Options:',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 2,
                children: template.options.take(3).map((option) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: option.isDefault 
                        ? theme.colorScheme.secondaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    option.name,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: option.isDefault 
                          ? theme.colorScheme.onSecondaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )).toList()
                  ..addAll(template.options.length > 3 ? [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '+${template.options.length - 3} more',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ] : []),
              ),
            ],
          ],
        ),
        secondary: Icon(
          template.isSingleSelection ? Icons.radio_button_checked : Icons.check_box,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.layers_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Templates Found',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filter criteria.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleTemplateSelection(String templateId, bool selected) {
    final updatedSelection = List<String>.from(widget.selectedTemplateIds);
    
    if (selected) {
      if (!updatedSelection.contains(templateId)) {
        updatedSelection.add(templateId);
      }
    } else {
      updatedSelection.remove(templateId);
    }
    
    widget.onSelectionChanged(updatedSelection);
  }

  void _selectAllFiltered(List<CustomizationTemplate> filteredTemplates) {
    final updatedSelection = List<String>.from(widget.selectedTemplateIds);
    
    for (final template in filteredTemplates) {
      if (!updatedSelection.contains(template.id)) {
        updatedSelection.add(template.id);
      }
    }
    
    widget.onSelectionChanged(updatedSelection);
  }

  void _clearSelection() {
    widget.onSelectionChanged([]);
  }
}
