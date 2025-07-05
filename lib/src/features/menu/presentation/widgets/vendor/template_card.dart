import 'package:flutter/material.dart';
import '../../../data/models/customization_template.dart';

/// Card widget for displaying customization template information
class TemplateCard extends StatelessWidget {
  final CustomizationTemplate template;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleActive;

  const TemplateCard({
    super.key,
    required this.template,
    this.onTap,
    this.onEdit,
    this.onDuplicate,
    this.onDelete,
    this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Template Icon and Type
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: template.isActive 
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      template.isSingleSelection ? Icons.radio_button_checked : Icons.check_box,
                      color: template.isActive 
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Template Name and Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                template.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: template.isActive 
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
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
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Template Type and Status
                        Row(
                          children: [
                            Text(
                              template.isSingleSelection ? 'Single Selection' : 'Multiple Selection',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: template.isActive 
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              template.isActive ? 'Active' : 'Inactive',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: template.isActive 
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Actions Menu
                  PopupMenuButton<String>(
                    onSelected: _handleMenuAction,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: ListTile(
                          leading: Icon(Icons.copy),
                          title: Text('Duplicate'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle_active',
                        child: ListTile(
                          leading: Icon(template.isActive ? Icons.visibility_off : Icons.visibility),
                          title: Text(template.isActive ? 'Deactivate' : 'Activate'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Description
              if (template.description != null && template.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  template.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Options Preview
              _buildOptionsPreview(context),
              
              const SizedBox(height: 12),
              
              // Stats Row
              _buildStatsRow(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsPreview(BuildContext context) {
    final theme = Theme.of(context);
    final visibleOptions = template.options.take(3).toList();
    final remainingCount = template.options.length - visibleOptions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Options (${template.options.length})',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            ...visibleOptions.map((option) => _buildOptionChip(context, option)),
            if (remainingCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+$remainingCount more',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionChip(BuildContext context, TemplateOption option) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: option.isDefault 
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: option.isDefault 
            ? Border.all(color: theme.colorScheme.primary, width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            option.name,
            style: theme.textTheme.labelSmall?.copyWith(
              color: option.isDefault 
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: option.isDefault ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          if (option.hasAdditionalCost) ...[
            const SizedBox(width: 4),
            Text(
              option.formattedPrice,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Usage Count
        _buildStatItem(
          context,
          icon: Icons.link,
          label: 'Used by',
          value: '${template.usageCount} items',
          color: theme.colorScheme.primary,
        ),
        
        const SizedBox(width: 16),
        
        // Price Range
        _buildStatItem(
          context,
          icon: Icons.attach_money,
          label: 'Price range',
          value: _getPriceRangeText(),
          color: theme.colorScheme.secondary,
        ),
        
        const Spacer(),
        
        // Last Updated
        Text(
          'Updated ${_getRelativeTime(template.updatedAt)}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getPriceRangeText() {
    if (template.options.isEmpty) return 'Free';
    
    final minCost = template.minimumAdditionalCost;
    final maxCost = template.maximumAdditionalCost;
    
    if (minCost == 0 && maxCost == 0) return 'Free';
    if (minCost == maxCost) return 'RM ${minCost.toStringAsFixed(2)}';
    
    return 'RM ${minCost.toStringAsFixed(2)} - ${maxCost.toStringAsFixed(2)}';
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        onEdit?.call();
        break;
      case 'duplicate':
        onDuplicate?.call();
        break;
      case 'toggle_active':
        onToggleActive?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }
}
