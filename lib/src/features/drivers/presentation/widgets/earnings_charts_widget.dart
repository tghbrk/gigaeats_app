import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../data/models/driver_earnings.dart';
import '../providers/driver_earnings_provider.dart';

/// Interactive earnings charts widget with multiple chart types and tooltips
class EarningsChartsWidget extends ConsumerStatefulWidget {
  final String driverId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool showLegend;
  final double height;

  const EarningsChartsWidget({
    super.key,
    required this.driverId,
    this.startDate,
    this.endDate,
    this.showLegend = true,
    this.height = 300,
  });

  @override
  ConsumerState<EarningsChartsWidget> createState() => _EarningsChartsWidgetState();
}

class _EarningsChartsWidgetState extends ConsumerState<EarningsChartsWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedChartIndex = 0;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedChartIndex = _tabController.index;
        _touchedIndex = -1; // Reset touched index when switching charts
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('💰 EarningsChartsWidget: build() called at ${DateTime.now()}');
    debugPrint('💰 EarningsChartsWidget: driverId = ${widget.driverId}');
    debugPrint('💰 EarningsChartsWidget: startDate = ${widget.startDate}');
    debugPrint('💰 EarningsChartsWidget: endDate = ${widget.endDate}');

    final theme = Theme.of(context);

    // Create stable earnings parameters
    final stableKey = 'custom_${widget.startDate?.millisecondsSinceEpoch ?? 0}_${widget.endDate?.millisecondsSinceEpoch ?? 0}';

    final earningsParams = EarningsParams(
      driverId: widget.driverId,
      startDate: widget.startDate,
      endDate: widget.endDate,
      period: 'custom', // Use custom period for charts
      stableKey: stableKey,
    );

    debugPrint('💰 EarningsChartsWidget: earningsParams = $earningsParams');

    final earningsAsync = ref.watch(driverEarningsStreamProvider);
    final summaryAsync = ref.watch(driverEarningsSummaryProvider(earningsParams));

    debugPrint('💰 EarningsChartsWidget: earningsAsync state = ${earningsAsync.runtimeType}');
    debugPrint('💰 EarningsChartsWidget: summaryAsync state = ${summaryAsync.runtimeType}');

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with chart type selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Earnings Analytics',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ref.invalidate(driverEarningsStreamProvider);
                    ref.invalidate(driverEarningsSummaryProvider);
                  },
                  tooltip: 'Refresh charts',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Chart type tabs
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: theme.colorScheme.onPrimary,
                unselectedLabelColor: theme.colorScheme.onSurface,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Breakdown'),
                  Tab(text: 'Trends'),
                  Tab(text: 'Performance'),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Chart content
            SizedBox(
              height: widget.height,
              child: earningsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load chart data',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                data: (earnings) => summaryAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                  data: (summary) => TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBreakdownChart(theme, summary),
                      _buildTrendsChart(theme, earnings),
                      _buildPerformanceChart(theme, earnings, summary),
                    ],
                  ),
                ),
              ),
            ),
            
            // Legend (if enabled)
            if (widget.showLegend) ...[
              const SizedBox(height: 16),
              _buildLegend(theme),
            ],
          ],
        ),
      ),
    );
  }

  /// Build earnings breakdown pie chart
  Widget _buildBreakdownChart(ThemeData theme, Map<String, dynamic> summary) {
    final deliveryFees = (summary['delivery_fees'] as double?) ?? 0.0;
    final tips = (summary['tips'] as double?) ?? 0.0;
    final bonuses = (summary['bonuses'] as double?) ?? 0.0;
    final total = deliveryFees + tips + bonuses;

    if (total <= 0) {
      return _buildEmptyChart(theme, 'No earnings data available');
    }

    final sections = [
      PieChartSectionData(
        color: Colors.green,
        value: deliveryFees,
        title: _touchedIndex == 0 ? 'RM ${deliveryFees.toStringAsFixed(2)}' : '${(deliveryFees / total * 100).toStringAsFixed(1)}%',
        radius: _touchedIndex == 0 ? 110 : 100,
        titleStyle: TextStyle(
          fontSize: _touchedIndex == 0 ? 16 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.blue,
        value: tips,
        title: _touchedIndex == 1 ? 'RM ${tips.toStringAsFixed(2)}' : '${(tips / total * 100).toStringAsFixed(1)}%',
        radius: _touchedIndex == 1 ? 110 : 100,
        titleStyle: TextStyle(
          fontSize: _touchedIndex == 1 ? 16 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.orange,
        value: bonuses,
        title: _touchedIndex == 2 ? 'RM ${bonuses.toStringAsFixed(2)}' : '${(bonuses / total * 100).toStringAsFixed(1)}%',
        radius: _touchedIndex == 2 ? 110 : 100,
        titleStyle: TextStyle(
          fontSize: _touchedIndex == 2 ? 16 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                _touchedIndex = -1;
                return;
              }
              _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: sections,
      ),
    );
  }

  /// Build earnings trends line chart
  Widget _buildTrendsChart(ThemeData theme, List<DriverEarnings> earnings) {
    if (earnings.isEmpty) {
      return _buildEmptyChart(theme, 'No earnings data for trends');
    }

    // Group earnings by date and calculate daily totals
    final Map<DateTime, double> dailyEarnings = {};
    for (final earning in earnings) {
      final date = DateTime(
        earning.createdAt.year,
        earning.createdAt.month,
        earning.createdAt.day,
      );
      dailyEarnings[date] = (dailyEarnings[date] ?? 0) + earning.netAmount;
    }

    // Sort dates and create spots for the line chart
    final sortedDates = dailyEarnings.keys.toList()..sort();
    final spots = <FlSpot>[];
    
    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final amount = dailyEarnings[date]!;
      spots.add(FlSpot(i.toDouble(), amount));
    }

    if (spots.isEmpty) {
      return _buildEmptyChart(theme, 'No trend data available');
    }

    final maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    final minY = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: maxY / 5,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
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
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedDates.length) {
                  final date = sortedDates[index];
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      '${date.day}/${date.month}',
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
              interval: maxY / 5,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  'RM ${value.toStringAsFixed(0)}',
                  style: theme.textTheme.bodySmall,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: minY * 0.9,
        maxY: maxY * 1.1,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.3),
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: theme.colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
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
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final index = barSpot.x.toInt();
                if (index >= 0 && index < sortedDates.length) {
                  final date = sortedDates[index];
                  return LineTooltipItem(
                    '${date.day}/${date.month}/${date.year}\nRM ${barSpot.y.toStringAsFixed(2)}',
                    TextStyle(
                      color: Colors.white,
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

  /// Build performance metrics bar chart
  Widget _buildPerformanceChart(ThemeData theme, List<DriverEarnings> earnings, Map<String, dynamic> summary) {
    if (earnings.isEmpty) {
      return _buildEmptyChart(theme, 'No performance data available');
    }

    final totalDeliveries = (summary['total_deliveries'] as int?) ?? 0;
    final avgEarningsPerDelivery = (summary['average_earnings_per_delivery'] as double?) ?? 0.0;
    final totalEarnings = (summary['total_net_earnings'] as double?) ?? 0.0;

    // Calculate performance metrics
    final deliveriesTarget = 100; // Target deliveries
    final earningsTarget = 1000.0; // Target earnings (RM)
    final avgTarget = 15.0; // Target average per delivery (RM)

    final deliveriesProgress = totalDeliveries / deliveriesTarget;
    final earningsProgress = totalEarnings / earningsTarget;
    final avgProgress = avgEarningsPerDelivery / avgTarget;

    final barGroups = [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: deliveriesProgress * 100,
            color: Colors.blue,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: earningsProgress * 100,
            color: Colors.green,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      ),
      BarChartGroupData(
        x: 2,
        barRods: [
          BarChartRodData(
            toY: avgProgress * 100,
            color: Colors.orange,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      ),
    ];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 120,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String label;
              String value;
              switch (group.x) {
                case 0:
                  label = 'Deliveries';
                  value = '$totalDeliveries / $deliveriesTarget';
                  break;
                case 1:
                  label = 'Total Earnings';
                  value = 'RM ${totalEarnings.toStringAsFixed(2)} / RM ${earningsTarget.toStringAsFixed(2)}';
                  break;
                case 2:
                  label = 'Avg per Delivery';
                  value = 'RM ${avgEarningsPerDelivery.toStringAsFixed(2)} / RM ${avgTarget.toStringAsFixed(2)}';
                  break;
                default:
                  label = '';
                  value = '';
              }
              return BarTooltipItem(
                '$label\n$value\n${rod.toY.toStringAsFixed(1)}%',
                TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
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
              getTitlesWidget: (double value, TitleMeta meta) {
                switch (value.toInt()) {
                  case 0:
                    return Text('Deliveries', style: theme.textTheme.bodySmall);
                  case 1:
                    return Text('Earnings', style: theme.textTheme.bodySmall);
                  case 2:
                    return Text('Average', style: theme.textTheme.bodySmall);
                  default:
                    return const Text('');
                }
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 20,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text('${value.toInt()}%', style: theme.textTheme.bodySmall);
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
        barGroups: barGroups,
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          horizontalInterval: 20,
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

  /// Build empty chart placeholder
  Widget _buildEmptyChart(ThemeData theme, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 48,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build chart legend
  Widget _buildLegend(ThemeData theme) {
    switch (_selectedChartIndex) {
      case 0: // Breakdown chart
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem(theme, Colors.green, 'Delivery Fees'),
            _buildLegendItem(theme, Colors.blue, 'Tips'),
            _buildLegendItem(theme, Colors.orange, 'Bonuses'),
          ],
        );
      case 1: // Trends chart
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(theme, theme.colorScheme.primary, 'Daily Earnings'),
          ],
        );
      case 2: // Performance chart
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem(theme, Colors.blue, 'Deliveries'),
            _buildLegendItem(theme, Colors.green, 'Earnings'),
            _buildLegendItem(theme, Colors.orange, 'Average'),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// Build individual legend item
  Widget _buildLegendItem(ThemeData theme, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
