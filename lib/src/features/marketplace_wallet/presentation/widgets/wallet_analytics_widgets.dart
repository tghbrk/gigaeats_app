import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/wallet_analytics_provider.dart';
import '../../data/models/wallet_analytics.dart';

/// Wallet analytics summary cards
class WalletAnalyticsSummaryCards extends ConsumerWidget {
  const WalletAnalyticsSummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('🔍 [WALLET-ANALYTICS-WIDGETS] WalletAnalyticsSummaryCards.build() called');

    try {
      final analyticsState = ref.watch(walletAnalyticsProvider);
      debugPrint('🔍 [WALLET-ANALYTICS-WIDGETS] Analytics state received');
      debugPrint('🔍 [WALLET-ANALYTICS-WIDGETS] Summary cards count: ${analyticsState.summaryCards.length}');

      final summaryCards = analyticsState.summaryCards;

      if (summaryCards.isEmpty) {
        debugPrint('⚠️ [WALLET-ANALYTICS-WIDGETS] No summary cards available, returning empty widget');
        return const SizedBox.shrink();
      }

      debugPrint('✅ [WALLET-ANALYTICS-WIDGETS] Building summary cards widget with ${summaryCards.length} cards');

      return Column(
      children: [
        Row(
          children: [
            if (summaryCards.isNotEmpty)
              Expanded(
                child: _SummaryCard(
                  title: summaryCards[0]['title'] ?? 'Total Spent',
                  value: summaryCards[0]['value'] ?? 'RM 0.00',
                  icon: Icons.trending_down,
                  color: AppTheme.errorColor,
                  subtitle: summaryCards[0]['subtitle'],
                  trend: summaryCards[0]['trend'],
                ),
              ),
            if (summaryCards.length > 1) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: summaryCards[1]['title'] ?? 'Total Topped Up',
                  value: summaryCards[1]['value'] ?? 'RM 0.00',
                  icon: Icons.add_circle,
                  color: AppTheme.successColor,
                  subtitle: summaryCards[1]['subtitle'],
                  trend: summaryCards[1]['trend'],
                ),
              ),
            ],
          ],
        ),
        if (summaryCards.length > 2) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (summaryCards.length > 2)
                Expanded(
                  child: _SummaryCard(
                    title: summaryCards[2]['title'] ?? 'Avg Transaction',
                    value: summaryCards[2]['value'] ?? 'RM 0.00',
                    icon: Icons.analytics,
                    color: AppTheme.infoColor,
                    subtitle: summaryCards[2]['subtitle'],
                    trend: summaryCards[2]['trend'],
                  ),
                ),
              if (summaryCards.length > 3) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: summaryCards[3]['title'] ?? 'Balance Change',
                    value: summaryCards[3]['value'] ?? 'RM 0.00',
                    icon: Icons.account_balance_wallet,
                    color: AppTheme.primaryColor,
                    subtitle: summaryCards[3]['subtitle'],
                    trend: summaryCards[3]['trend'],
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
    } catch (e, stack) {
      debugPrint('❌ [WALLET-ANALYTICS-WIDGETS] Error in WalletAnalyticsSummaryCards.build(): $e');
      debugPrint('❌ [WALLET-ANALYTICS-WIDGETS] Stack trace: $stack');
      return const SizedBox.shrink();
    }
  }
}

/// Individual summary card widget
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final Map<String, dynamic>? trend;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => context.push('/customer/wallet/analytics'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Fix overflow by using min size
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible( // Use Flexible to prevent overflow
                child: Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Flexible( // Use Flexible for subtitle too
                  child: Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
              if (trend != null) ...[
                const SizedBox(height: 6), // Reduced spacing
                _buildTrendIndicator(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(ThemeData theme) {
    final trendValue = trend!['value'] as double? ?? 0.0;
    final trendLabel = trend!['label'] as String? ?? '';
    final isPositive = trendValue > 0;
    final trendColor = isPositive ? AppTheme.successColor : AppTheme.errorColor;

    return Row(
      children: [
        Icon(
          isPositive ? Icons.trending_up : Icons.trending_down,
          size: 14,
          color: trendColor,
        ),
        const SizedBox(width: 4),
        Text(
          trendLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            color: trendColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Enhanced wallet spending trends chart with multiple chart types
class WalletSpendingTrendsChart extends ConsumerStatefulWidget {
  final double height;
  final bool showComparison;
  final bool enableInteraction;

  const WalletSpendingTrendsChart({
    super.key,
    this.height = 250,
    this.showComparison = false,
    this.enableInteraction = true,
  });

  @override
  ConsumerState<WalletSpendingTrendsChart> createState() => _WalletSpendingTrendsChartState();
}

class _WalletSpendingTrendsChartState extends ConsumerState<WalletSpendingTrendsChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _selectedChartType = 0; // 0: Line, 1: Bar, 2: Area
  bool _showBalance = true;
  bool _showTransactions = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔍 [WALLET-ANALYTICS-WIDGETS] WalletSpendingTrendsChart.build() called');

    try {
      final analyticsState = ref.watch(walletAnalyticsProvider);
      debugPrint('🔍 [WALLET-ANALYTICS-WIDGETS] Analytics state received for trends chart');

      final trends = analyticsState.trends;
      debugPrint('🔍 [WALLET-ANALYTICS-WIDGETS] Trends count: ${trends.length}');

      if (trends.isEmpty) {
        debugPrint('⚠️ [WALLET-ANALYTICS-WIDGETS] No trend data available, showing empty state');
        return SizedBox(
          height: widget.height,
          child: const Card(
            child: Center(
              child: Text('No trend data available'),
            ),
          ),
        );
      }

      debugPrint('✅ [WALLET-ANALYTICS-WIDGETS] Building trends chart with ${trends.length} data points');

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with controls
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Spending Trends',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Chart type selector
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, icon: Icon(Icons.show_chart, size: 16)),
                      ButtonSegment(value: 1, icon: Icon(Icons.bar_chart, size: 16)),
                      ButtonSegment(value: 2, icon: Icon(Icons.area_chart, size: 16)),
                    ],
                    selected: {_selectedChartType},
                    onSelectionChanged: (Set<int> selection) {
                      setState(() {
                        _selectedChartType = selection.first;
                        _animationController.reset();
                        _animationController.forward();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Data series toggles
              Row(
                children: [
                  _buildDataToggle('Spending', _showBalance, AppTheme.primaryColor, (value) {
                    setState(() => _showBalance = value);
                  }),
                  const SizedBox(width: 16),
                  _buildDataToggle('Transactions', _showTransactions, AppTheme.successColor, (value) {
                    setState(() => _showTransactions = value);
                  }),
                ],
              ),
              const SizedBox(height: 16),

              // Chart
              SizedBox(
                height: widget.height - 120,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return _buildChart(trends);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e, stack) {
      debugPrint('❌ [WALLET-ANALYTICS-WIDGETS] Error in WalletSpendingTrendsChart.build(): $e');
      debugPrint('❌ [WALLET-ANALYTICS-WIDGETS] Stack trace: $stack');
      return SizedBox(
        height: widget.height,
        child: const Card(
          child: Center(
            child: Text('Error loading chart'),
          ),
        ),
      );
    }
  }

  Widget _buildDataToggle(String label, bool value, Color color, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: value ? color : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: value ? color : Colors.grey.shade600,
              fontWeight: value ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(List<SpendingTrendData> trends) {
    switch (_selectedChartType) {
      case 1:
        return _buildBarChart(trends);
      case 2:
        return _buildAreaChart(trends);
      default:
        return _buildLineChart(trends);
    }
  }

  Widget _buildLineChart(List<SpendingTrendData> trends) {
    if (trends.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final lineBarsData = <LineChartBarData>[];

    if (_showBalance) {
      lineBarsData.add(
        LineChartBarData(
          spots: trends.asMap().entries.map((entry) {
            return FlSpot(
              entry.key.toDouble(),
              entry.value.dailySpent * _animation.value,
            );
          }).toList(),
          isCurved: true,
          color: AppTheme.primaryColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: AppTheme.primaryColor,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
          ),
        ),
      );
    }

    if (_showTransactions) {
      final maxSpending = trends.map((t) => t.dailySpent).reduce((a, b) => a > b ? a : b);
      final maxTransactions = trends.map((t) => t.dailyTransactions).reduce((a, b) => a > b ? a : b);
      final scaleFactor = maxTransactions > 0 ? maxSpending / maxTransactions : 1.0;

      lineBarsData.add(
        LineChartBarData(
          spots: trends.asMap().entries.map((entry) {
            return FlSpot(
              entry.key.toDouble(),
              entry.value.dailyTransactions * scaleFactor * _animation.value,
            );
          }).toList(),
          isCurved: true,
          color: AppTheme.successColor,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          dashArray: [5, 5],
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calculateInterval(trends),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: _buildTitlesData(trends),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        lineBarsData: lineBarsData,
        lineTouchData: _buildLineTouchData(trends),
      ),
    );
  }

  Widget _buildBarChart(List<SpendingTrendData> trends) {
    if (trends.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final maxSpent = trends.map((t) => t.dailySpent).reduce((a, b) => a > b ? a : b);
    if (maxSpent <= 0) {
      return const Center(child: Text('No spending data available'));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxSpent * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => AppTheme.primaryColor,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              try {
                final index = group.x.toInt();
                if (index >= 0 && index < trends.length) {
                  final trend = trends[index];
                  return BarTooltipItem(
                    '${trend.dateLabel}\n${trend.formattedDailySpent}',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }
                return null;
              } catch (e) {
                return null;
              }
            },
          ),
        ),
        titlesData: _buildTitlesData(trends),
        borderData: FlBorderData(show: false),
        barGroups: trends.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.dailySpent * _animation.value,
                color: AppTheme.primaryColor,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAreaChart(List<SpendingTrendData> trends) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calculateInterval(trends),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: _buildTitlesData(trends),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: trends.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                entry.value.dailySpent * _animation.value,
              );
            }).toList(),
            isCurved: true,
            color: AppTheme.primaryColor,
            barWidth: 0,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.3),
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                  AppTheme.primaryColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: _buildLineTouchData(trends),
      ),
    );
  }

  FlTitlesData _buildTitlesData(List<SpendingTrendData> trends) {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 60,
          getTitlesWidget: (value, meta) {
            return Text(
              'RM${value.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 10),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: (trends.length / 5).ceil().toDouble(),
          getTitlesWidget: (value, meta) {
            try {
              final index = value.toInt();
              if (index >= 0 && index < trends.length) {
                return Text(
                  trends[index].dateLabel,
                  style: const TextStyle(fontSize: 10),
                );
              }
              return const Text('');
            } catch (e) {
              return const Text('');
            }
          },
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  LineTouchData _buildLineTouchData(List<SpendingTrendData> trends) {
    return LineTouchData(
      enabled: widget.enableInteraction,
      touchTooltipData: LineTouchTooltipData(
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            try {
              final index = spot.x.toInt();
              if (index >= 0 && index < trends.length) {
                final trend = trends[index];
                return LineTooltipItem(
                  '${trend.dateLabel}\n${trend.formattedDailySpent}\n${trend.dailyTransactions} transactions',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                );
              }
              return null;
            } catch (e) {
              return null;
            }
          }).toList();
        },
      ),
    );
  }

  double _calculateInterval(List<SpendingTrendData> trends) {
    if (trends.isEmpty) return 10.0;

    final maxAmount = trends.map((t) => t.dailySpent).reduce((a, b) => a > b ? a : b);
    return (maxAmount / 5).ceilToDouble();
  }
}

/// Enhanced wallet category spending pie chart with animations
class WalletCategorySpendingChart extends ConsumerStatefulWidget {
  final double height;
  final bool showAnimation;

  const WalletCategorySpendingChart({
    super.key,
    this.height = 250,
    this.showAnimation = true,
  });

  @override
  ConsumerState<WalletCategorySpendingChart> createState() => _WalletCategorySpendingChartState();
}

class _WalletCategorySpendingChartState extends ConsumerState<WalletCategorySpendingChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    if (widget.showAnimation) {
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: this,
      );
      _animation = CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      );
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    if (widget.showAnimation) {
      _animationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(walletAnalyticsProvider);
    final categories = analyticsState.categories;

    if (categories.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Card(
          child: Center(
            child: Text('No category data available'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending by Category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: widget.height - 60,
              child: Row(
                children: [
                  // Pie chart
                  Expanded(
                    flex: 2,
                    child: widget.showAnimation
                        ? AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) => _buildPieChart(categories),
                          )
                        : _buildPieChart(categories),
                  ),
                  const SizedBox(width: 16),
                  // Legend
                  Expanded(
                    flex: 1,
                    child: _buildLegend(categories),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(List<TransactionCategoryData> categories) {
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
        sections: categories.take(6).map((category) {
          final index = categories.indexOf(category);
          final isTouched = index == _touchedIndex;
          final radius = isTouched ? 70.0 : 60.0;
          final animationValue = widget.showAnimation ? _animation.value : 1.0;

          return PieChartSectionData(
            value: category.totalAmount * animationValue,
            title: '${category.percentageOfTotal.toStringAsFixed(1)}%',
            color: _getCategoryColor(index),
            radius: radius,
            titleStyle: TextStyle(
              fontSize: isTouched ? 14 : 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        startDegreeOffset: -90,
      ),
    );
  }

  Widget _buildLegend(List<TransactionCategoryData> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: categories.take(6).map((category) {
        final index = categories.indexOf(category);
        final isTouched = index == _touchedIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: EdgeInsets.all(isTouched ? 8 : 4),
          decoration: BoxDecoration(
            color: isTouched ? _getCategoryColor(index).withValues(alpha: 0.1) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getCategoryColor(index),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.categoryName,
                  style: TextStyle(
                    fontSize: isTouched ? 13 : 12,
                    fontWeight: isTouched ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getCategoryColor(int index) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.successColor,
      AppTheme.warningColor,
      AppTheme.infoColor,
      AppTheme.errorColor,
      Colors.purple,
    ];
    return colors[index % colors.length];
  }
}

/// Enhanced wallet category breakdown list with detailed information
class WalletCategoryBreakdownList extends ConsumerWidget {
  const WalletCategoryBreakdownList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(walletAnalyticsProvider);
    final categories = analyticsState.categories;

    if (categories.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('No category data available'),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Breakdown',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final category = categories[index];
              return ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: _getCategoryColor(index).withValues(alpha: 0.1),
                  child: Icon(
                    _getCategoryIcon(category.categoryIcon),
                    color: _getCategoryColor(index),
                    size: 20,
                  ),
                ),
                title: Text(category.categoryName),
                subtitle: Text('${category.transactionCount} transactions'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      category.formattedTotalAmount,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      category.formattedPercentage,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildCategoryMetric('Average per transaction', 'RM ${(category.totalAmount / category.transactionCount).toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        _buildCategoryMetric('Total amount', category.formattedTotalAmount),
                        const SizedBox(height: 8),
                        _buildCategoryMetric('Percentage of total', category.formattedPercentage),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryMetric(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(int index) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.successColor,
      AppTheme.warningColor,
      AppTheme.infoColor,
      AppTheme.errorColor,
      Colors.purple,
    ];
    return colors[index % colors.length];
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'add_circle':
        return Icons.add_circle;
      case 'send':
        return Icons.send;
      case 'undo':
        return Icons.undo;
      default:
        return Icons.category;
    }
  }
}

/// Enhanced wallet analytics insights widget with AI-powered recommendations
class WalletAnalyticsInsightsWidget extends ConsumerWidget {
  const WalletAnalyticsInsightsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(walletAnalyticsProvider);
    final currentMonth = analyticsState.currentMonthAnalytics;

    if (currentMonth == null) {
      return const SizedBox.shrink();
    }

    final insights = _generateInsights(currentMonth);

    if (insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights & Recommendations',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...insights.take(3).map((insight) => _InsightCard(insight: insight)),
      ],
    );
  }

  List<Map<String, dynamic>> _generateInsights(WalletAnalytics analytics) {
    final insights = <Map<String, dynamic>>[];

    // Spending frequency insight
    if (analytics.spendingFrequency > 2) {
      insights.add({
        'type': 'warning',
        'title': 'High Spending Frequency',
        'message': 'You\'re spending ${analytics.spendingFrequency.toStringAsFixed(1)} times per day on average. Consider setting daily spending limits.',
        'icon': Icons.warning,
        'color': AppTheme.warningColor,
      });
    }

    // Balance trend insight
    final balanceChange = analytics.periodEndBalance - analytics.periodStartBalance;
    if (balanceChange < 0) {
      insights.add({
        'type': 'info',
        'title': 'Decreasing Balance',
        'message': 'Your wallet balance decreased by RM ${balanceChange.abs().toStringAsFixed(2)} this period. Consider topping up.',
        'icon': Icons.trending_down,
        'color': AppTheme.infoColor,
      });
    }

    // High transaction insight
    if (analytics.maxTransactionAmount > analytics.avgTransactionAmount * 3) {
      insights.add({
        'type': 'info',
        'title': 'Large Transaction Alert',
        'message': 'Your largest transaction (RM ${analytics.maxTransactionAmount.toStringAsFixed(2)}) was significantly higher than average.',
        'icon': Icons.info,
        'color': AppTheme.infoColor,
      });
    }

    // Positive insights
    if (analytics.spendingFrequency <= 1) {
      insights.add({
        'type': 'success',
        'title': 'Controlled Spending',
        'message': 'Great job! Your spending frequency is well-controlled at ${analytics.spendingFrequency.toStringAsFixed(1)} times per day.',
        'icon': Icons.check_circle,
        'color': AppTheme.successColor,
      });
    }

    return insights;
  }
}

class _InsightCard extends StatelessWidget {
  final Map<String, dynamic> insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = insight['color'] as Color;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                insight['icon'] as IconData,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight['title'] as String,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insight['message'] as String,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wallet balance history area chart
class WalletBalanceHistoryChart extends ConsumerStatefulWidget {
  final double height;
  final int days;

  const WalletBalanceHistoryChart({
    super.key,
    this.height = 250,
    this.days = 30,
  });

  @override
  ConsumerState<WalletBalanceHistoryChart> createState() => _WalletBalanceHistoryChartState();
}

class _WalletBalanceHistoryChartState extends ConsumerState<WalletBalanceHistoryChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(walletAnalyticsProvider);
    final trends = analyticsState.trends;

    if (trends.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Card(
          child: Center(
            child: Text('No balance history available'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: widget.height - 60,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _calculateBalanceInterval(trends),
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade300,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: _buildBalanceTitlesData(trends),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: trends.asMap().entries.map((entry) {
                            // Simulate balance history based on spending trends
                            final cumulativeBalance = _calculateCumulativeBalance(trends, entry.key);
                            return FlSpot(
                              entry.key.toDouble(),
                              cumulativeBalance * _animation.value,
                            );
                          }).toList(),
                          isCurved: true,
                          color: AppTheme.successColor,
                          barWidth: 0,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppTheme.successColor.withValues(alpha: 0.3),
                                AppTheme.successColor.withValues(alpha: 0.1),
                                AppTheme.successColor.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final index = spot.x.toInt();
                              if (index >= 0 && index < trends.length) {
                                final trend = trends[index];
                                final balance = _calculateCumulativeBalance(trends, index);
                                return LineTooltipItem(
                                  '${trend.dateLabel}\nBalance: RM ${balance.toStringAsFixed(2)}',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateCumulativeBalance(List<SpendingTrendData> trends, int index) {
    // Start with a base balance and subtract spending
    double balance = 1000.0; // Base balance
    for (int i = 0; i <= index; i++) {
      balance -= trends[i].dailySpent;
      // Add some top-ups occasionally
      if (i % 7 == 0 && i > 0) {
        balance += 200.0; // Weekly top-up
      }
    }
    return balance.clamp(0.0, double.infinity);
  }

  double _calculateBalanceInterval(List<SpendingTrendData> trends) {
    if (trends.isEmpty) return 100.0;

    final maxBalance = trends.asMap().entries.map((entry) =>
        _calculateCumulativeBalance(trends, entry.key)).reduce((a, b) => a > b ? a : b);
    return (maxBalance / 5).ceilToDouble();
  }

  FlTitlesData _buildBalanceTitlesData(List<SpendingTrendData> trends) {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 60,
          getTitlesWidget: (value, meta) {
            return Text(
              'RM${value.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 10),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: (trends.length / 5).ceil().toDouble(),
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < trends.length) {
              return Text(
                trends[index].dateLabel,
                style: const TextStyle(fontSize: 10),
              );
            }
            return const Text('');
          },
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }
}

/// Enhanced wallet analytics export dialog with advanced options
class WalletAnalyticsExportDialog extends ConsumerStatefulWidget {
  const WalletAnalyticsExportDialog({super.key});

  @override
  ConsumerState<WalletAnalyticsExportDialog> createState() => _WalletAnalyticsExportDialogState();
}

class _WalletAnalyticsExportDialogState extends ConsumerState<WalletAnalyticsExportDialog> {
  String _selectedFormat = 'csv';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isExporting = false;
  bool _includeCharts = true;
  bool _includeInsights = true;

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(walletAnalyticsProvider);

    if (!analyticsState.exportEnabled) {
      return AlertDialog(
        title: const Text('Export Disabled'),
        content: const Text('Export functionality is disabled in your privacy settings. Enable it in wallet settings to export analytics data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Export Analytics Data'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedFormat,
              decoration: const InputDecoration(
                labelText: 'Export Format',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'csv', child: Text('CSV Data')),
                DropdownMenuItem(value: 'pdf', child: Text('PDF Report')),
              ],
              onChanged: (value) {
                setState(() => _selectedFormat = value!);
              },
            ),
            const SizedBox(height: 16),

            // Date range selection
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectStartDate(),
                    child: Text(
                      _startDate != null
                          ? DateFormat('MMM dd, yyyy').format(_startDate!)
                          : 'Start Date',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectEndDate(),
                    child: Text(
                      _endDate != null
                          ? DateFormat('MMM dd, yyyy').format(_endDate!)
                          : 'End Date',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Export options (for PDF)
            if (_selectedFormat == 'pdf') ...[
              CheckboxListTile(
                title: const Text('Include Charts'),
                subtitle: const Text('Add visual charts to the report'),
                value: _includeCharts,
                onChanged: (value) {
                  setState(() => _includeCharts = value ?? true);
                },
              ),
              CheckboxListTile(
                title: const Text('Include Insights'),
                subtitle: const Text('Add AI-powered insights and recommendations'),
                value: _includeInsights,
                onChanged: (value) {
                  setState(() => _includeInsights = value ?? true);
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isExporting ? null : _exportData,
          child: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Export'),
        ),
      ],
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);

    try {
      final analyticsService = ref.read(walletAnalyticsServiceProvider);

      // Export analytics data based on format
      final result = _selectedFormat == 'pdf'
          ? await analyticsService.exportToPdf(
              periodType: 'custom',
              startDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
              endDate: _endDate ?? DateTime.now(),
            )
          : await analyticsService.exportToCsv(
              periodType: 'custom',
              startDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
              endDate: _endDate ?? DateTime.now(),
            );

      await result.fold(
        (failure) async {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Export failed: ${failure.message}'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        (export) async {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Analytics exported: ${export.formattedFileSize}'),
                backgroundColor: AppTheme.successColor,
                action: SnackBarAction(
                  label: 'Share',
                  onPressed: () async {
                    final shareResult = await analyticsService.shareExport(export);
                    shareResult.fold(
                      (failure) => debugPrint('Share failed: ${failure.message}'),
                      (_) => debugPrint('Export shared successfully'),
                    );
                  },
                ),
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}

/// Top vendors horizontal bar chart
class WalletTopVendorsChart extends ConsumerStatefulWidget {
  final double height;
  final int maxVendors;

  const WalletTopVendorsChart({
    super.key,
    this.height = 300,
    this.maxVendors = 5,
  });

  @override
  ConsumerState<WalletTopVendorsChart> createState() => _WalletTopVendorsChartState();
}

class _WalletTopVendorsChartState extends ConsumerState<WalletTopVendorsChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(walletAnalyticsProvider);
    final categories = analyticsState.categories;

    // Simulate vendor data from categories
    final vendorData = _generateVendorData(categories);

    if (vendorData.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Card(
          child: Center(
            child: Text('No vendor data available'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Vendors',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: widget.height - 60,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: vendorData.first['amount'] * 1.2,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => AppTheme.primaryColor,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final vendor = vendorData[group.x.toInt()];
                            return BarTooltipItem(
                              '${vendor['name']}\nRM ${vendor['amount'].toStringAsFixed(2)}\n${vendor['orders']} orders',
                              const TextStyle(color: Colors.white, fontSize: 12),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                'RM${value.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < vendorData.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    vendorData[index]['name'],
                                    style: const TextStyle(fontSize: 10),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: vendorData.asMap().entries.map((entry) {
                        final vendor = entry.value;
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: vendor['amount'] * _animation.value,
                              color: _getVendorColor(entry.key),
                              width: 24,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _generateVendorData(List<TransactionCategoryData> categories) {
    // Simulate vendor data based on categories
    final vendors = [
      {'name': 'Pizza Palace', 'amount': 150.0, 'orders': 8},
      {'name': 'Burger King', 'amount': 120.0, 'orders': 6},
      {'name': 'Sushi Express', 'amount': 200.0, 'orders': 4},
      {'name': 'Coffee Bean', 'amount': 80.0, 'orders': 12},
      {'name': 'Nasi Lemak Stall', 'amount': 90.0, 'orders': 9},
    ];

    // Sort by amount and take top vendors
    vendors.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
    return vendors.take(widget.maxVendors).toList();
  }

  Color _getVendorColor(int index) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.successColor,
      AppTheme.warningColor,
      AppTheme.infoColor,
      AppTheme.errorColor,
    ];
    return colors[index % colors.length];
  }
}




