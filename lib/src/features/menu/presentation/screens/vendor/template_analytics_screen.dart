import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/customization_template_providers.dart';
import '../../../../../shared/widgets/loading_widget.dart';

/// Screen for displaying template analytics and usage insights
class TemplateAnalyticsScreen extends ConsumerStatefulWidget {
  final String vendorId;

  const TemplateAnalyticsScreen({
    super.key,
    required this.vendorId,
  });

  @override
  ConsumerState<TemplateAnalyticsScreen> createState() => _TemplateAnalyticsScreenState();
}

class _TemplateAnalyticsScreenState extends ConsumerState<TemplateAnalyticsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(templateAnalyticsSummaryProvider(
      AnalyticsSummaryParams(
        vendorId: widget.vendorId,
        periodStart: _startDate,
        periodEnd: _endDate,
      ),
    ));

    final metricsAsync = ref.watch(templatePerformanceMetricsProvider(
      PerformanceMetricsParams(
        vendorId: widget.vendorId,
        startDate: _startDate,
        endDate: _endDate,
      ),
    ));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Date Range Selector
          _buildDateRangeSelector(),
          
          const SizedBox(height: 16),
          
          // Analytics Summary
          summaryAsync.when(
            data: (summary) => _buildSummaryCard(summary),
            loading: () => const LoadingWidget(message: 'Loading analytics...'),
            error: (error, stack) => _buildErrorCard('Failed to load analytics'),
          ),
          
          const SizedBox(height: 16),
          
          // Performance Metrics
          Expanded(
            child: metricsAsync.when(
              data: (metrics) => _buildMetricsList(metrics),
              loading: () => const LoadingWidget(message: 'Loading metrics...'),
              error: (error, stack) => _buildErrorCard('Failed to load metrics'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.date_range, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Analytics Period',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: _selectDateRange,
              child: Text(
                '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(summary) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildStatItem(
                  'Total Templates',
                  '${summary.totalTemplates}',
                  Icons.layers,
                  theme.colorScheme.primary,
                ),
                _buildStatItem(
                  'Active Templates',
                  '${summary.activeTemplates}',
                  Icons.visibility,
                  theme.colorScheme.secondary,
                ),
                _buildStatItem(
                  'Menu Items Using',
                  '${summary.totalMenuItemsUsingTemplates}',
                  Icons.restaurant_menu,
                  theme.colorScheme.tertiary,
                ),
                _buildStatItem(
                  'Total Revenue',
                  summary.formattedTotalRevenue,
                  Icons.attach_money,
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);

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
              const Spacer(),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsList(List<dynamic> metrics) {
    final theme = Theme.of(context);

    if (metrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Performance Data',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Template performance metrics will appear here once you have order data.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Template Performance',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: metrics.length,
            itemBuilder: (context, index) {
              final metric = metrics[index];
              return _buildMetricCard(metric);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(dynamic metric) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    metric.templateName ?? 'Unknown Template',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPerformanceColor(metric.performanceGrade ?? 'F').withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getPerformanceColor(metric.performanceGrade ?? 'F'),
                    ),
                  ),
                  child: Text(
                    metric.performanceGrade ?? 'F',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _getPerformanceColor(metric.performanceGrade ?? 'F'),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem('Usage', '${metric.usageCount ?? 0}'),
                ),
                Expanded(
                  child: _buildMetricItem('Orders', '${metric.ordersCount ?? 0}'),
                ),
                Expanded(
                  child: _buildMetricItem('Revenue', 'RM ${(metric.revenueGenerated ?? 0.0).toStringAsFixed(2)}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    final theme = Theme.of(context);

    return Column(
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
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(String message) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPerformanceColor(String grade) {
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
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }
}
