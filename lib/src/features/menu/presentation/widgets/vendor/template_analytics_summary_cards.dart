import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/template_usage_analytics.dart';

/// Widget displaying template analytics summary cards
class TemplateAnalyticsSummaryCards extends StatelessWidget {
  final TemplateAnalyticsSummary summary;

  const TemplateAnalyticsSummaryCards({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // First row
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                'Total Templates',
                '${summary.totalTemplates}',
                Icons.layers,
                Colors.blue,
                subtitle: '${summary.activeTemplates} active',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                context,
                'Menu Items',
                '${summary.totalMenuItemsUsingTemplates}',
                Icons.restaurant_menu,
                Colors.green,
                subtitle: 'Using templates',
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Second row
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                'Total Orders',
                '${summary.totalOrdersWithTemplates}',
                Icons.shopping_cart,
                Colors.orange,
                subtitle: 'With templates',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                context,
                'Revenue',
                'RM ${summary.totalRevenueFromTemplates.toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.purple,
                subtitle: 'From templates',
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Third row - Performance metrics
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                'Utilization Rate',
                '${summary.templateUtilizationRate.toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.teal,
                subtitle: 'Templates in use',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                context,
                'Avg Revenue',
                'RM ${summary.averageRevenuePerTemplate.toStringAsFixed(2)}',
                Icons.analytics,
                Colors.indigo,
                subtitle: 'Per template',
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Fourth row - Time-based metrics
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                'Daily Average',
                'RM ${summary.dailyAverageRevenue.toStringAsFixed(2)}',
                Icons.calendar_today,
                Colors.brown,
                subtitle: 'Revenue per day',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                context,
                'Period',
                '${summary.periodDurationDays} days',
                Icons.date_range,
                Colors.grey,
                subtitle: _formatDateRange(summary.periodStart, summary.periodEnd),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: color,
                    size: 12,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 4),
            
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final formatter = DateFormat('MMM dd');
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }
}

/// Widget for displaying template performance trends
class TemplatePerformanceTrendCard extends StatelessWidget {
  final TemplateAnalyticsSummary summary;
  final TemplateAnalyticsSummary? previousPeriodSummary;

  const TemplatePerformanceTrendCard({
    super.key,
    required this.summary,
    this.previousPeriodSummary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Trends',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (previousPeriodSummary != null) ...[
              _buildTrendItem(
                context,
                'Revenue Growth',
                _calculateGrowthPercentage(
                  summary.totalRevenueFromTemplates,
                  previousPeriodSummary!.totalRevenueFromTemplates,
                ),
                Icons.attach_money,
              ),
              
              const SizedBox(height: 12),
              
              _buildTrendItem(
                context,
                'Order Growth',
                _calculateGrowthPercentage(
                  summary.totalOrdersWithTemplates.toDouble(),
                  previousPeriodSummary!.totalOrdersWithTemplates.toDouble(),
                ),
                Icons.shopping_cart,
              ),
              
              const SizedBox(height: 12),
              
              _buildTrendItem(
                context,
                'Template Adoption',
                _calculateGrowthPercentage(
                  summary.templateUtilizationRate,
                  previousPeriodSummary!.templateUtilizationRate,
                ),
                Icons.trending_up,
              ),
            ] else ...[
              Center(
                child: Text(
                  'Trend data will be available after multiple periods',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrendItem(
    BuildContext context,
    String label,
    double growthPercentage,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isPositive = growthPercentage >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    final trendIcon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(trendIcon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                '${growthPercentage.abs().toStringAsFixed(1)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _calculateGrowthPercentage(double current, double previous) {
    if (previous == 0) return current > 0 ? 100.0 : 0.0;
    return ((current - previous) / previous) * 100;
  }
}
