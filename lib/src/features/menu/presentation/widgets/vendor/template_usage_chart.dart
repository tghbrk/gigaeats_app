import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../providers/template_analytics_provider.dart';

/// Chart widget for displaying template usage patterns
class TemplateUsageChart extends ConsumerWidget {
  final String vendorId;
  final double height;

  const TemplateUsageChart({
    super.key,
    required this.vendorId,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final analyticsState = ref.watch(templateAnalyticsProvider(vendorId));

    if (analyticsState.performanceMetrics.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No usage data available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: _buildUsageBarChart(analyticsState.performanceMetrics, theme),
    );
  }

  Widget _buildUsageBarChart(List<dynamic> performanceMetrics, ThemeData theme) {
    // Take top 10 templates for better visualization
    final topTemplates = performanceMetrics.take(10).toList();

    final barGroups = topTemplates.asMap().entries.map((entry) {
      final index = entry.key;
      final template = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: template.usageCount.toDouble(),
            color: _getUsageColor(template.usageCount),
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    final maxY = topTemplates.isEmpty
        ? 10.0
        : topTemplates.map((t) => t.usageCount.toDouble()).reduce((a, b) => a > b ? a : b);

    // Ensure maxY is never 0 to avoid interval calculation issues
    final safeMaxY = maxY <= 0 ? 10.0 : maxY;

    // Calculate safe interval to avoid zero interval error
    final safeInterval = (safeMaxY / 5).ceilToDouble();
    final chartMaxY = safeMaxY * 1.2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: chartMaxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex < topTemplates.length) {
                final template = topTemplates[groupIndex];
                return BarTooltipItem(
                  '${template.templateName}\n${template.usageCount} uses',
                  TextStyle(
                    color: theme.colorScheme.onInverseSurface,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }
              return null;
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < topTemplates.length) {
                  final template = topTemplates[index];
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: Text(
                          template.templateName.length > 15
                              ? '${template.templateName.substring(0, 15)}...'
                              : template.templateName,
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: safeInterval,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    value.toInt().toString(),
                    style: theme.textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        barGroups: barGroups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: safeInterval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  Color _getUsageColor(int usageCount) {
    if (usageCount >= 50) return Colors.green;
    if (usageCount >= 20) return Colors.blue;
    if (usageCount >= 10) return Colors.orange;
    if (usageCount >= 5) return Colors.yellow;
    return Colors.red;
  }
}

/// Pie chart showing template usage distribution
class TemplateUsagePieChart extends ConsumerWidget {
  final String vendorId;
  final double height;

  const TemplateUsagePieChart({
    super.key,
    required this.vendorId,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final analyticsState = ref.watch(templateAnalyticsProvider(vendorId));

    if (analyticsState.performanceMetrics.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No usage data available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: _buildPieChart(analyticsState.performanceMetrics, theme),
    );
  }

  Widget _buildPieChart(List<dynamic> performanceMetrics, ThemeData theme) {
    // Take top 8 templates and group the rest as "Others"
    final sortedTemplates = List.from(performanceMetrics);
    sortedTemplates.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    
    final topTemplates = sortedTemplates.take(8).toList();
    final otherTemplates = sortedTemplates.skip(8).toList();
    
    final totalUsage = performanceMetrics.fold<int>(0, (sum, t) => (sum + t.usageCount.toInt()) as int);
    
    if (totalUsage == 0) {
      return Center(
        child: Text(
          'No usage data available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final sections = <PieChartSectionData>[];
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    // Add top templates
    for (int i = 0; i < topTemplates.length; i++) {
      final template = topTemplates[i];
      final percentage = (template.usageCount / totalUsage) * 100;
      
      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: template.usageCount.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      );
    }

    // Add "Others" section if there are more templates
    if (otherTemplates.isNotEmpty) {
      final othersUsage = otherTemplates.fold<int>(0, (sum, t) => (sum + t.usageCount.toInt()) as int);
      final percentage = (othersUsage / totalUsage) * 100;
      
      sections.add(
        PieChartSectionData(
          color: Colors.grey,
          value: othersUsage.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // Handle touch events if needed
                },
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: _buildLegend(topTemplates, otherTemplates, colors, theme),
        ),
      ],
    );
  }

  Widget _buildLegend(
    List<dynamic> topTemplates,
    List<dynamic> otherTemplates,
    List<Color> colors,
    ThemeData theme,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...topTemplates.asMap().entries.map((entry) {
          final index = entry.key;
          final template = entry.value;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    template.templateName.length > 20
                        ? '${template.templateName.substring(0, 20)}...'
                        : template.templateName,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
        
        if (otherTemplates.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Others (${otherTemplates.length})',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
