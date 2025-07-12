import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/customization_template.dart';
import '../../providers/customization_template_providers.dart';
import '../../../../../shared/widgets/loading_widget.dart';

/// Enhanced template usage analytics widget
class TemplateUsageAnalytics extends ConsumerStatefulWidget {
  final String vendorId;
  final bool showDetailedMetrics;
  final bool showTrends;

  const TemplateUsageAnalytics({
    super.key,
    required this.vendorId,
    this.showDetailedMetrics = true,
    this.showTrends = true,
  });

  @override
  ConsumerState<TemplateUsageAnalytics> createState() => _TemplateUsageAnalyticsState();
}

class _TemplateUsageAnalyticsState extends ConsumerState<TemplateUsageAnalytics> {
  String _sortBy = 'usage';
  bool _sortAscending = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templatesAsync = ref.watch(vendorTemplatesProvider(VendorTemplatesParams(
      vendorId: widget.vendorId,
      isActive: true,
    )));

    return templatesAsync.when(
      data: (templates) {
        if (templates.isEmpty) {
          return _buildEmptyState(theme);
        }

        final sortedTemplates = _sortTemplates(templates);
        
        return Column(
          children: [
            // Analytics Header
            _buildAnalyticsHeader(theme, templates),
            
            // Sort Controls
            _buildSortControls(theme),
            
            // Analytics List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sortedTemplates.length,
                itemBuilder: (context, index) {
                  final template = sortedTemplates[index];
                  return _buildAnalyticsCard(template, index + 1, theme);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const LoadingWidget(message: 'Loading analytics...'),
      error: (error, stack) => _buildErrorState(error.toString(), theme),
    );
  }

  Widget _buildAnalyticsHeader(ThemeData theme, List<CustomizationTemplate> templates) {
    final totalTemplates = templates.length;
    final activeTemplates = templates.where((t) => t.usageCount > 0).length;
    final totalUsage = templates.fold<int>(0, (sum, t) => sum + t.usageCount);
    final avgUsage = totalTemplates > 0 ? totalUsage / totalTemplates : 0.0;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Template Usage Overview',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Metrics Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    theme,
                    title: 'Total Templates',
                    value: totalTemplates.toString(),
                    icon: Icons.layers,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    theme,
                    title: 'Active Templates',
                    value: activeTemplates.toString(),
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    theme,
                    title: 'Total Usage',
                    value: totalUsage.toString(),
                    icon: Icons.trending_up,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    theme,
                    title: 'Avg Usage',
                    value: avgUsage.toStringAsFixed(1),
                    icon: Icons.analytics,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    ThemeData theme, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortControls(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Sort by:',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          
          DropdownButton<String>(
            value: _sortBy,
            items: const [
              DropdownMenuItem(value: 'usage', child: Text('Usage Count')),
              DropdownMenuItem(value: 'name', child: Text('Name')),
              DropdownMenuItem(value: 'options', child: Text('Options Count')),
              DropdownMenuItem(value: 'type', child: Text('Type')),
            ],
            onChanged: (value) {
              setState(() {
                _sortBy = value!;
              });
            },
          ),
          
          const SizedBox(width: 8),
          
          IconButton(
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending;
              });
            },
            icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
            tooltip: _sortAscending ? 'Sort Ascending' : 'Sort Descending',
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(CustomizationTemplate template, int rank, ThemeData theme) {
    final usageLevel = _getUsageLevel(template.usageCount);
    final usageColor = _getUsageColor(usageLevel, theme);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: usageColor.withValues(alpha: 0.2),
          child: Text(
            '#$rank',
            style: TextStyle(
              color: usageColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          template.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  template.isSingleSelection ? Icons.radio_button_checked : Icons.check_box,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text('${template.options.length} options'),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: usageColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    usageLevel,
                    style: TextStyle(
                      color: usageColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.showDetailedMetrics) ...[
              const SizedBox(height: 4),
              _buildUsageBar(template.usageCount, theme),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${template.usageCount}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: usageColor,
              ),
            ),
            Text(
              'uses',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageBar(int usageCount, ThemeData theme) {
    // Calculate relative usage (assuming max usage of 100 for visualization)
    final maxUsage = 100;
    final percentage = (usageCount / maxUsage).clamp(0.0, 1.0);
    
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: percentage,
        child: Container(
          decoration: BoxDecoration(
            color: _getUsageColor(_getUsageLevel(usageCount), theme),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Analytics Data',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create templates to see usage analytics',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, ThemeData theme) {
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
            'Error Loading Analytics',
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

  // Helper Methods
  List<CustomizationTemplate> _sortTemplates(List<CustomizationTemplate> templates) {
    final sorted = List<CustomizationTemplate>.from(templates);
    
    sorted.sort((a, b) {
      int comparison;
      
      switch (_sortBy) {
        case 'usage':
          comparison = a.usageCount.compareTo(b.usageCount);
          break;
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'options':
          comparison = a.options.length.compareTo(b.options.length);
          break;
        case 'type':
          comparison = a.type.compareTo(b.type);
          break;
        default:
          comparison = 0;
      }
      
      return _sortAscending ? comparison : -comparison;
    });
    
    return sorted;
  }

  String _getUsageLevel(int usageCount) {
    if (usageCount == 0) return 'Unused';
    if (usageCount < 5) return 'Low';
    if (usageCount < 20) return 'Medium';
    if (usageCount < 50) return 'High';
    return 'Very High';
  }

  Color _getUsageColor(String level, ThemeData theme) {
    switch (level) {
      case 'Unused':
        return Colors.grey;
      case 'Low':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.blue;
      case 'Very High':
        return Colors.green;
      default:
        return theme.colorScheme.primary;
    }
  }
}
