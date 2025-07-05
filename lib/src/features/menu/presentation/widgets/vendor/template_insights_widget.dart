import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/template_analytics_provider.dart';

/// Widget displaying analytics insights and recommendations
class TemplateInsightsWidget extends ConsumerWidget {
  final String vendorId;

  const TemplateInsightsWidget({
    super.key,
    required this.vendorId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final insights = ref.watch(templateAnalyticsInsightsProvider(vendorId));
    final analyticsState = ref.watch(templateAnalyticsProvider(vendorId));

    return Column(
      children: [
        // Insights Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Analytics Insights',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                if (insights.isEmpty)
                  Text(
                    'No insights available yet. More data is needed to generate meaningful insights.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  ...insights.map((insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            insight,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Performance Summary Card
        _buildPerformanceSummary(analyticsState, theme),
        
        const SizedBox(height: 16),
        
        // Recommendations Card
        _buildRecommendations(analyticsState, theme),
      ],
    );
  }

  Widget _buildPerformanceSummary(TemplateAnalyticsState analyticsState, ThemeData theme) {

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'Performance Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Consumer(
              builder: (context, ref, child) {
                final notifier = ref.read(templateAnalyticsProvider(vendorId).notifier);
                final gradeMap = notifier.getTemplatesByGrade();
                
                return Column(
                  children: [
                    _buildGradeRow('Excellent (A+, A)', (gradeMap['A+']?.length ?? 0) + (gradeMap['A']?.length ?? 0), Colors.green, theme),
                    _buildGradeRow('Good (B)', gradeMap['B']?.length ?? 0, Colors.blue, theme),
                    _buildGradeRow('Average (C)', gradeMap['C']?.length ?? 0, Colors.orange, theme),
                    _buildGradeRow('Poor (D, F)', (gradeMap['D']?.length ?? 0) + (gradeMap['F']?.length ?? 0), Colors.red, theme),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeRow(String label, int count, Color color, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(TemplateAnalyticsState analyticsState, ThemeData theme) {
    final recommendations = _generateRecommendations(analyticsState);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.recommend, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Text(
                  'Recommendations',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (recommendations.isEmpty)
              Text(
                'No specific recommendations at this time. Keep monitoring your template performance.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...recommendations.map((recommendation) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: recommendation['color'].withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: recommendation['color'].withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        recommendation['icon'],
                        color: recommendation['color'],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recommendation['title'],
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: recommendation['color'],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              recommendation['description'],
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _generateRecommendations(TemplateAnalyticsState analyticsState) {
    final recommendations = <Map<String, dynamic>>[];
    final summary = analyticsState.summary;

    if (summary == null) return recommendations;

    // Low utilization recommendation
    if (summary.templateUtilizationRate < 50) {
      recommendations.add({
        'title': 'Improve Template Adoption',
        'description': 'Only ${summary.templateUtilizationRate.toStringAsFixed(1)}% of your templates are being used. Consider promoting unused templates or removing outdated ones.',
        'icon': Icons.trending_up,
        'color': Colors.orange,
      });
    }

    // Low revenue recommendation
    if (summary.averageRevenuePerTemplate < 20) {
      recommendations.add({
        'title': 'Optimize Template Pricing',
        'description': 'Average revenue per template is low. Review your template options and pricing to increase profitability.',
        'icon': Icons.attach_money,
        'color': Colors.red,
      });
    }

    // High performance recommendation
    if (summary.templateUtilizationRate > 80 && summary.averageRevenuePerTemplate > 50) {
      recommendations.add({
        'title': 'Excellent Performance!',
        'description': 'Your templates are performing very well. Consider creating more templates based on your successful patterns.',
        'icon': Icons.star,
        'color': Colors.green,
      });
    }

    // Template diversity recommendation
    if (summary.totalTemplates < 5) {
      recommendations.add({
        'title': 'Expand Template Variety',
        'description': 'You have only ${summary.totalTemplates} templates. Consider creating more templates to offer customers more customization options.',
        'icon': Icons.add_circle,
        'color': Colors.blue,
      });
    }

    // Performance improvement recommendation
    // Note: This would need to be handled differently in a real implementation
    // For now, we'll check if there are any performance metrics with low scores
    final lowPerformingCount = analyticsState.performanceMetrics
        .where((metric) => metric.performanceScore < 50)
        .length;

    if (lowPerformingCount > 0) {
      recommendations.add({
        'title': 'Review Underperforming Templates',
        'description': 'You have $lowPerformingCount templates with low performance scores. Consider updating their options or pricing.',
        'icon': Icons.warning,
        'color': Colors.amber,
      });
    }

    return recommendations;
  }
}
