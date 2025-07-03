import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../providers/admin_providers_index.dart';

/// Revenue trend line chart
class RevenueChart extends ConsumerWidget {
  final int days;
  final double height;

  const RevenueChart({
    super.key,
    this.days = 30,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revenueData = ref.watch(adminRevenueChartProvider);
    final theme = Theme.of(context);

    if (revenueData.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('No revenue data available'),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 1,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: theme.dividerColor.withValues(alpha: 0.3),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: theme.dividerColor.withValues(alpha: 0.3),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < revenueData.length) {
                    final date = revenueData[value.toInt()].timestamp;
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        DateFormat('MM/dd').format(date),
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
                interval: 1,
                getTitlesWidget: (value, meta) {
                  return Text(
                    'RM${value.toInt()}',
                    style: theme.textTheme.bodySmall,
                  );
                },
                reservedSize: 60,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: theme.dividerColor),
          ),
          minX: 0,
          maxX: revenueData.length.toDouble() - 1,
          minY: 0,
          maxY: revenueData.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
          lineBarsData: [
            LineChartBarData(
              spots: revenueData.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.value);
              }).toList(),
              isCurved: true,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.3),
                ],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.3),
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Orders trend line chart
class OrdersChart extends ConsumerWidget {
  final int days;
  final double height;

  const OrdersChart({
    super.key,
    this.days = 30,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderData = ref.watch(adminOrderChartProvider);
    final theme = Theme.of(context);

    if (orderData.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('No order data available'),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 1,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: theme.dividerColor.withValues(alpha: 0.3),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: theme.dividerColor.withValues(alpha: 0.3),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < orderData.length) {
                    final date = orderData[value.toInt()].timestamp;
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        DateFormat('MM/dd').format(date),
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
                interval: 1,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: theme.textTheme.bodySmall,
                  );
                },
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: theme.dividerColor),
          ),
          minX: 0,
          maxX: orderData.length.toDouble() - 1,
          minY: 0,
          maxY: orderData.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
          lineBarsData: [
            LineChartBarData(
              spots: orderData.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.value);
              }).toList(),
              isCurved: true,
              color: theme.colorScheme.secondary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.secondary.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// User statistics pie chart
class UserStatsChart extends ConsumerWidget {
  final double height;

  const UserStatsChart({
    super.key,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStatsData = ref.watch(adminUserStatsChartProvider);
    final theme = Theme.of(context);

    if (userStatsData.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('No user statistics available'),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              // Handle touch events if needed
            },
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 2,
          centerSpaceRadius: 60,
          sections: userStatsData.asMap().entries.map((entry) {
            final data = entry.value;
            final total = userStatsData.fold<double>(0, (sum, item) => sum + item.value);
            final percentage = (data.value / total * 100);

            return PieChartSectionData(
              color: _parseColor(data.color),
              value: data.value,
              title: '${percentage.toStringAsFixed(1)}%',
              radius: 80,
              titleStyle: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _parseColor(String? colorName) {
    if (colorName == null) return Colors.blue;

    switch (colorName.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'red':
        return Colors.red;
      case 'teal':
        return Colors.teal;
      case 'yellow':
        return Colors.yellow;
      case 'pink':
        return Colors.pink;
      default:
        return Colors.blue;
    }
  }
}

/// Performance metrics dashboard widget
class PerformanceMetricsWidget extends ConsumerWidget {
  const PerformanceMetricsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(adminAnalyticsProvider);
    final theme = Theme.of(context);

    if (analyticsState.performanceMetrics == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final metrics = analyticsState.performanceMetrics!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Metrics Grid - Fixed overflow by adjusting aspect ratio and layout
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 3.0, // Increased from 2.5 to provide more height
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _MetricCard(
                  title: 'Order Fulfillment',
                  value: '${metrics.orderFulfillmentRate.toStringAsFixed(1)}%',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                _MetricCard(
                  title: 'Customer Retention',
                  value: '${metrics.customerRetentionRate.toStringAsFixed(1)}%',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
                _MetricCard(
                  title: 'Avg Delivery Time',
                  value: '${metrics.averageDeliveryTime.toStringAsFixed(1)} min',
                  icon: Icons.delivery_dining,
                  color: Colors.orange,
                ),
                _MetricCard(
                  title: 'Payment Success',
                  value: '${metrics.paymentSuccessRate.toStringAsFixed(1)}%',
                  icon: Icons.payment,
                  color: Colors.purple,
                ),
                _MetricCard(
                  title: 'System Uptime',
                  value: '${metrics.systemUptime.toStringAsFixed(1)}%',
                  icon: Icons.cloud_done,
                  color: Colors.teal,
                ),
                _MetricCard(
                  title: 'Revenue Growth',
                  value: '${metrics.revenueGrowthRate.toStringAsFixed(1)}%',
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual metric card
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(10), // Reduced padding from 12 to 10
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20, // Reduced icon size from 24 to 20
          ),
          const SizedBox(width: 8), // Reduced spacing from 12 to 8
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Added to prevent overflow
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    fontSize: 11, // Slightly smaller font
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1), // Reduced spacing from 2 to 1
                Flexible( // Wrapped in Flexible to prevent overflow
                  child: Text(
                    value,
                    style: theme.textTheme.titleSmall?.copyWith( // Changed from titleMedium to titleSmall
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vendor performance bar chart
class VendorPerformanceChart extends ConsumerWidget {
  final double height;

  const VendorPerformanceChart({
    super.key,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorPerformanceAsync = ref.watch(vendorPerformanceProvider({'limit': 10, 'offset': 0}));
    final theme = Theme.of(context);

    return vendorPerformanceAsync.when(
      data: (vendorData) {
        if (vendorData.isEmpty) {
          return SizedBox(
            height: height,
            child: const Center(
              child: Text('No vendor performance data available'),
            ),
          );
        }

        return SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: vendorData.map((v) => v.revenueLast30Days).reduce((a, b) => a > b ? a : b) * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => theme.colorScheme.surface,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final vendor = vendorData[group.x.toInt()];
                    return BarTooltipItem(
                      '${vendor.businessName}\nRM ${vendor.revenueLast30Days.toStringAsFixed(2)}',
                      theme.textTheme.bodyMedium!,
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < vendorData.length) {
                        final vendor = vendorData[value.toInt()];
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            vendor.businessName.length > 8
                                ? '${vendor.businessName.substring(0, 8)}...'
                                : vendor.businessName,
                            style: theme.textTheme.bodySmall,
                          ),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        'RM${(value / 1000).toStringAsFixed(0)}k',
                        style: theme.textTheme.bodySmall,
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: vendorData.asMap().entries.map((entry) {
                final index = entry.key;
                final vendor = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: vendor.revenueLast30Days,
                      color: theme.colorScheme.primary,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
      loading: () => SizedBox(
        height: height,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => SizedBox(
        height: height,
        child: Center(
          child: Text('Error loading vendor data: $error'),
        ),
      ),
    );
  }
}
