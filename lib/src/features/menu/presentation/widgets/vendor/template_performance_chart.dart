import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../providers/template_analytics_provider.dart';

/// Chart widget for displaying template performance metrics
class TemplatePerformanceChart extends ConsumerStatefulWidget {
  final String vendorId;
  final double height;

  const TemplatePerformanceChart({
    super.key,
    required this.vendorId,
    this.height = 300,
  });

  @override
  ConsumerState<TemplatePerformanceChart> createState() => _TemplatePerformanceChartState();
}

class _TemplatePerformanceChartState extends ConsumerState<TemplatePerformanceChart> {
  String _selectedMetric = 'revenue';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analyticsNotifier = ref.read(templateAnalyticsProvider(widget.vendorId).notifier);

    return Column(
      children: [
        // Metric selector
        Row(
          children: [
            Text(
              'Show:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildMetricChip('revenue', 'Revenue', Icons.attach_money),
                    const SizedBox(width: 8),
                    _buildMetricChip('orders', 'Orders', Icons.shopping_cart),
                    const SizedBox(width: 8),
                    _buildMetricChip('usage', 'Usage', Icons.analytics),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Chart
        SizedBox(
          height: widget.height,
          child: _buildChart(analyticsNotifier),
        ),
      ],
    );
  }

  Widget _buildMetricChip(String metric, String label, IconData icon) {
    final theme = Theme.of(context);
    final isSelected = _selectedMetric == metric;

    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedMetric = metric;
          });
        }
      },
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected 
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurfaceVariant,
      ),
      label: Text(label),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      selectedColor: theme.colorScheme.primaryContainer,
    );
  }

  Widget _buildChart(TemplateAnalyticsNotifier analyticsNotifier) {
    final theme = Theme.of(context);

    switch (_selectedMetric) {
      case 'revenue':
        return _buildRevenueChart(analyticsNotifier, theme);
      case 'orders':
        return _buildOrdersChart(analyticsNotifier, theme);
      case 'usage':
        return _buildUsageChart(analyticsNotifier, theme);
      default:
        return _buildRevenueChart(analyticsNotifier, theme);
    }
  }

  Widget _buildRevenueChart(TemplateAnalyticsNotifier analyticsNotifier, ThemeData theme) {
    final trendData = analyticsNotifier.getRevenueTrendData();

    if (trendData.isEmpty) {
      return Center(
        child: Text(
          'No revenue data available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final spots = trendData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value['revenue'].toDouble());
    }).toList();

    final maxY = trendData.isEmpty ? 10.0 : trendData.map((e) => e['revenue'] as double).reduce((a, b) => a > b ? a : b);
    final safeMaxY = maxY <= 0 ? 10.0 : maxY;
    final safeBottomInterval = trendData.isEmpty ? 1.0 : (trendData.length / 5).ceilToDouble();
    final safeLeftInterval = (safeMaxY / 5).ceilToDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: safeLeftInterval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: safeBottomInterval,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < trendData.length) {
                  final date = trendData[index]['date'] as DateTime;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      DateFormat('MMM dd').format(date),
                      style: theme.textTheme.bodySmall,
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
              interval: safeLeftInterval,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    'RM${value.toStringAsFixed(0)}',
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
        minX: 0,
        maxX: trendData.isEmpty ? 4.0 : trendData.length.toDouble() - 1,
        minY: 0,
        maxY: safeMaxY * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: theme.colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: theme.colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index >= 0 && index < trendData.length) {
                  final data = trendData[index];
                  final date = data['date'] as DateTime;
                  final revenue = data['revenue'] as double;
                  
                  return LineTooltipItem(
                    '${DateFormat('MMM dd').format(date)}\nRM${revenue.toStringAsFixed(2)}',
                    TextStyle(
                      color: theme.colorScheme.onInverseSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersChart(TemplateAnalyticsNotifier analyticsNotifier, ThemeData theme) {
    final trendData = analyticsNotifier.getRevenueTrendData();

    if (trendData.isEmpty) {
      return Center(
        child: Text(
          'No orders data available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final spots = trendData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), (entry.value['orders'] as int).toDouble());
    }).toList();

    final maxY = trendData.isEmpty ? 10.0 : trendData.map((e) => (e['orders'] as int).toDouble()).reduce((a, b) => a > b ? a : b);
    final safeMaxY = maxY <= 0 ? 10.0 : maxY;
    final safeBottomInterval = trendData.isEmpty ? 1.0 : (trendData.length / 5).ceilToDouble();
    final safeLeftInterval = (safeMaxY / 5).ceilToDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: safeLeftInterval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: safeBottomInterval,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < trendData.length) {
                  final date = trendData[index]['date'] as DateTime;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      DateFormat('MMM dd').format(date),
                      style: theme.textTheme.bodySmall,
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
              interval: safeLeftInterval,
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
        minX: 0,
        maxX: trendData.isEmpty ? 4.0 : trendData.length.toDouble() - 1,
        minY: 0,
        maxY: safeMaxY * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: theme.colorScheme.secondary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: theme.colorScheme.secondary,
                  strokeWidth: 2,
                  strokeColor: theme.colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.secondary.withValues(alpha: 0.2),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index >= 0 && index < trendData.length) {
                  final data = trendData[index];
                  final date = data['date'] as DateTime;
                  final orders = data['orders'] as int;
                  
                  return LineTooltipItem(
                    '${DateFormat('MMM dd').format(date)}\n$orders orders',
                    TextStyle(
                      color: theme.colorScheme.onInverseSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUsageChart(TemplateAnalyticsNotifier analyticsNotifier, ThemeData theme) {
    final trendData = analyticsNotifier.getUsageTrendData();

    if (trendData.isEmpty) {
      return Center(
        child: Text(
          'No usage data available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final usageSpots = trendData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), (entry.value['usage'] as int).toDouble());
    }).toList();

    final menuItemSpots = trendData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), (entry.value['menu_items'] as int).toDouble());
    }).toList();

    final maxY = trendData.isEmpty ? 10.0 : [
      ...trendData.map((e) => (e['usage'] as int).toDouble()),
      ...trendData.map((e) => (e['menu_items'] as int).toDouble()),
    ].reduce((a, b) => a > b ? a : b);

    final safeMaxY = maxY <= 0 ? 10.0 : maxY;
    final safeBottomInterval = trendData.isEmpty ? 1.0 : (trendData.length / 5).ceilToDouble();
    final safeLeftInterval = (safeMaxY / 5).ceilToDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: safeLeftInterval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: safeBottomInterval,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < trendData.length) {
                  final date = trendData[index]['date'] as DateTime;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      DateFormat('MMM dd').format(date),
                      style: theme.textTheme.bodySmall,
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
              interval: safeLeftInterval,
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
        minX: 0,
        maxX: trendData.isEmpty ? 4.0 : trendData.length.toDouble() - 1,
        minY: 0,
        maxY: safeMaxY * 1.2,
        lineBarsData: [
          // Usage line
          LineChartBarData(
            spots: usageSpots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
          // Menu items line
          LineChartBarData(
            spots: menuItemSpots,
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
