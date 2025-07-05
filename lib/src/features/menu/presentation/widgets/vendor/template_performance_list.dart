import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/template_analytics_provider.dart';
import '../../../data/models/template_usage_analytics.dart';

/// Widget displaying a list of template performance metrics
class TemplatePerformanceList extends ConsumerStatefulWidget {
  final String vendorId;

  const TemplatePerformanceList({
    super.key,
    required this.vendorId,
  });

  @override
  ConsumerState<TemplatePerformanceList> createState() => _TemplatePerformanceListState();
}

class _TemplatePerformanceListState extends ConsumerState<TemplatePerformanceList> {
  String _sortBy = 'performance'; // 'performance', 'revenue', 'usage', 'name'
  bool _sortAscending = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analyticsState = ref.watch(templateAnalyticsProvider(widget.vendorId));

    if (analyticsState.performanceMetrics.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 48,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 12),
                Text(
                  'No Performance Data',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Template performance data will appear here once you have orders with template customizations.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final sortedMetrics = _getSortedMetrics(analyticsState.performanceMetrics);

    return Card(
      child: Column(
        children: [
          // Header with sorting options
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Template Performance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sort by',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                      ),
                    ],
                  ),
                  onSelected: (value) {
                    setState(() {
                      if (_sortBy == value) {
                        _sortAscending = !_sortAscending;
                      } else {
                        _sortBy = value;
                        _sortAscending = false;
                      }
                    });
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'performance',
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: _sortBy == 'performance' ? theme.colorScheme.primary : null,
                          ),
                          const SizedBox(width: 8),
                          Text('Performance Score'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'revenue',
                      child: Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 16,
                            color: _sortBy == 'revenue' ? theme.colorScheme.primary : null,
                          ),
                          const SizedBox(width: 8),
                          Text('Revenue'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'usage',
                      child: Row(
                        children: [
                          Icon(
                            Icons.analytics,
                            size: 16,
                            color: _sortBy == 'usage' ? theme.colorScheme.primary : null,
                          ),
                          const SizedBox(width: 8),
                          Text('Usage Count'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'name',
                      child: Row(
                        children: [
                          Icon(
                            Icons.sort_by_alpha,
                            size: 16,
                            color: _sortBy == 'name' ? theme.colorScheme.primary : null,
                          ),
                          const SizedBox(width: 8),
                          Text('Name'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Performance list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedMetrics.length,
            itemBuilder: (context, index) {
              final metric = sortedMetrics[index];
              return _buildPerformanceItem(metric, index + 1, theme);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceItem(TemplatePerformanceMetrics metric, int rank, ThemeData theme) {
    final gradeColor = _getGradeColor(metric.performanceGrade);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: gradeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: gradeColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#$rank',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: gradeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                metric.performanceGrade,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: gradeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          metric.templateName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              '${metric.performanceScore.toStringAsFixed(0)}% score',
              style: theme.textTheme.bodySmall?.copyWith(
                color: gradeColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '•',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'RM ${metric.revenueGenerated.toStringAsFixed(2)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${metric.ordersCount}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              'orders',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Detailed metrics
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'Usage Count',
                        '${metric.usageCount}',
                        Icons.layers,
                        theme,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Conversion Rate',
                        '${(metric.conversionRate * 100).toStringAsFixed(1)}%',
                        Icons.trending_up,
                        theme,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'Avg Order Value',
                        'RM ${metric.averageOrderValue.toStringAsFixed(2)}',
                        Icons.attach_money,
                        theme,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Last Used',
                        dateFormat.format(metric.lastUsed),
                        Icons.schedule,
                        theme,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Performance breakdown
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
                        'Performance Breakdown',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPerformanceBar(
                        'Overall Score',
                        metric.performanceScore,
                        100,
                        gradeColor,
                        theme,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceBar(
    String label,
    double value,
    double maxValue,
    Color color,
    ThemeData theme,
  ) {
    final percentage = (value / maxValue).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
            Text(
              '${value.toStringAsFixed(0)}/${maxValue.toStringAsFixed(0)}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  List<TemplatePerformanceMetrics> _getSortedMetrics(List<TemplatePerformanceMetrics> metrics) {
    final sorted = List<TemplatePerformanceMetrics>.from(metrics);

    switch (_sortBy) {
      case 'performance':
        sorted.sort((a, b) => _sortAscending 
            ? a.performanceScore.compareTo(b.performanceScore)
            : b.performanceScore.compareTo(a.performanceScore));
        break;
      case 'revenue':
        sorted.sort((a, b) => _sortAscending 
            ? a.revenueGenerated.compareTo(b.revenueGenerated)
            : b.revenueGenerated.compareTo(a.revenueGenerated));
        break;
      case 'usage':
        sorted.sort((a, b) => _sortAscending 
            ? a.usageCount.compareTo(b.usageCount)
            : b.usageCount.compareTo(a.usageCount));
        break;
      case 'name':
        sorted.sort((a, b) => _sortAscending 
            ? a.templateName.compareTo(b.templateName)
            : b.templateName.compareTo(a.templateName));
        break;
    }

    return sorted;
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.red;
      case 'F':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
