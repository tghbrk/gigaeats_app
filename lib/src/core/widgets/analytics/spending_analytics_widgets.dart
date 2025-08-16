import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../presentation/providers/customer_spending_analytics_provider.dart';
// TODO: Restore when customer_budget_provider is fully implemented
// import '../../../features/user_management/presentation/providers/customer_budget_provider.dart';
import '../../data/models/analytics/customer_spending_analytics.dart';

/// Summary cards showing key spending metrics
class SpendingSummaryCards extends ConsumerWidget {
  const SpendingSummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(customerSpendingAnalyticsProvider);
    final analytics = analyticsState.analytics;

    if (analytics == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Total Spent',
                value: analytics.formattedTotalSpent,
                icon: Icons.payments,
                color: AppTheme.primaryColor,
                subtitle: '${analytics.transactionCount} transactions',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Average Spending',
                value: analytics.formattedAverageSpending,
                icon: Icons.trending_up,
                color: AppTheme.infoColor,
                subtitle: 'per transaction',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Top Category',
                value: analytics.topSpendingCategory?.categoryName ?? 'N/A',
                icon: Icons.category,
                color: AppTheme.successColor,
                subtitle: analytics.topSpendingCategory?.formattedAmount ?? '',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Growth',
                value: analytics.comparison?.formattedGrowthPercentage ?? 'N/A',
                icon: analytics.comparison?.isIncreasing == true 
                    ? Icons.arrow_upward 
                    : Icons.arrow_downward,
                color: analytics.comparison?.isIncreasing == true 
                    ? AppTheme.warningColor 
                    : AppTheme.successColor,
                subtitle: 'vs last period',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
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
}

/// Widget displaying spending insights and recommendations
class SpendingInsightsWidget extends ConsumerWidget {
  const SpendingInsightsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(customerSpendingAnalyticsProvider);
    final insights = analyticsState.insights;

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
}

class _InsightCard extends StatelessWidget {
  final SpendingInsight insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color cardColor;
    IconData cardIcon;
    
    switch (insight.type) {
      case 'tip':
        cardColor = AppTheme.infoColor;
        cardIcon = Icons.lightbulb_outline;
        break;
      case 'warning':
        cardColor = AppTheme.warningColor;
        cardIcon = Icons.warning_outlined;
        break;
      case 'achievement':
        cardColor = AppTheme.successColor;
        cardIcon = Icons.emoji_events_outlined;
        break;
      case 'recommendation':
        cardColor = AppTheme.primaryColor;
        cardIcon = Icons.recommend_outlined;
        break;
      default:
        cardColor = AppTheme.infoColor;
        cardIcon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: cardColor.withValues(alpha: 0.1),
            child: Icon(cardIcon, color: cardColor, size: 20),
          ),
          title: Text(
            insight.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(insight.description),
          trailing: insight.actionText != null
              ? TextButton(
                  onPressed: () {
                    // Handle insight action
                  },
                  child: Text(insight.actionText!),
                )
              : null,
        ),
      ),
    );
  }
}

/// Widget displaying top merchants by spending
class TopMerchantsWidget extends ConsumerWidget {
  const TopMerchantsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(customerSpendingAnalyticsProvider);
    final merchants = analyticsState.topMerchants;

    if (merchants.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Merchants',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: merchants.take(5).map((merchant) => 
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    merchant.merchantName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(merchant.merchantName),
                subtitle: Text('${merchant.orderCount} orders'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      merchant.formattedAmount,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Avg: ${merchant.formattedAverageOrderValue}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ).toList(),
          ),
        ),
      ],
    );
  }
}

/// Spending trends line chart
class SpendingTrendsChart extends ConsumerWidget {
  final double height;

  const SpendingTrendsChart({
    super.key,
    this.height = 250,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(customerSpendingAnalyticsProvider);
    final trends = analyticsState.trends;

    if (trends.isEmpty) {
      return SizedBox(
        height: height,
        child: const Card(
          child: Center(
            child: Text('No trend data available'),
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
              'Spending Trends',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: height - 60,
              child: LineChart(
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
                          final index = value.toInt();
                          if (index >= 0 && index < trends.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                DateFormat('MM/dd').format(trends[index].date),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
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
                        interval: _calculateInterval(trends),
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              'RM${value.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  minX: 0,
                  maxX: trends.length.toDouble() - 1,
                  minY: 0,
                  maxY: trends.map((t) => t.amount).reduce((a, b) => a > b ? a : b) * 1.1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: trends.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.amount);
                      }).toList(),
                      isCurved: true,
                      color: AppTheme.primaryColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateInterval(List trends) {
    if (trends.isEmpty) return 1.0;
    final maxAmount = trends.map((t) => t.amount).reduce((a, b) => a > b ? a : b);
    return maxAmount / 5; // Show 5 horizontal grid lines
  }
}

/// Category spending pie chart
class CategorySpendingChart extends ConsumerWidget {
  final double height;

  const CategorySpendingChart({
    super.key,
    this.height = 250,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(customerSpendingAnalyticsProvider);
    final categories = analyticsState.categories;

    if (categories.isEmpty) {
      return SizedBox(
        height: height,
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
              height: height - 60,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: categories.take(6).map((category) {
                          return PieChartSectionData(
                            color: _getCategoryColor(category.categoryId),
                            value: category.amount,
                            title: '${category.percentage.toStringAsFixed(1)}%',
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: categories.take(6).map((category) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(category.categoryId),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  category.categoryName,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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

  Color _getCategoryColor(String categoryId) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.successColor,
      AppTheme.warningColor,
      AppTheme.infoColor,
      Colors.purple,
      Colors.orange,
    ];
    return colors[categoryId.hashCode % colors.length];
  }
}

/// Category breakdown list
class CategoryBreakdownList extends ConsumerWidget {
  const CategoryBreakdownList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(customerSpendingAnalyticsProvider);
    final categories = analyticsState.categories;

    if (categories.isEmpty) {
      return const SizedBox.shrink();
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
          child: Column(
            children: categories.map((category) =>
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getCategoryColor(category.categoryId).withValues(alpha: 0.1),
                  child: Icon(
                    _getCategoryIcon(category.categoryIcon),
                    color: _getCategoryColor(category.categoryId),
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
                      category.formattedAmount,
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
              ),
            ).toList(),
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String categoryId) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.successColor,
      AppTheme.warningColor,
      AppTheme.infoColor,
      Colors.purple,
      Colors.orange,
    ];
    return colors[categoryId.hashCode % colors.length];
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'movie':
        return Icons.movie;
      case 'fitness_center':
        return Icons.fitness_center;
      default:
        return Icons.category;
    }
  }
}

/// Budget overview cards
class BudgetOverviewCards extends ConsumerWidget {
  const BudgetOverviewCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Restore when budgetStatisticsProvider is implemented
    // final budgetStats = ref.watch(budgetStatisticsProvider);
    final budgetStats = <String, dynamic>{}; // Placeholder

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Active Budgets',
                value: budgetStats['active_budgets'].toString(),
                icon: Icons.account_balance_wallet,
                color: AppTheme.primaryColor,
                subtitle: 'of ${budgetStats['total_budgets']} total',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Budget Utilization',
                value: '${budgetStats['overall_utilization'].toStringAsFixed(1)}%',
                icon: Icons.pie_chart,
                color: _getUtilizationColor(budgetStats['overall_utilization']),
                subtitle: 'overall usage',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Over Budget',
                value: budgetStats['over_budget_count'].toString(),
                icon: Icons.warning,
                color: AppTheme.errorColor,
                subtitle: 'budgets exceeded',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Near Limit',
                value: budgetStats['near_limit_count'].toString(),
                icon: Icons.trending_up,
                color: AppTheme.warningColor,
                subtitle: 'budgets at 80%+',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getUtilizationColor(double utilization) {
    if (utilization >= 100) return AppTheme.errorColor;
    if (utilization >= 80) return AppTheme.warningColor;
    if (utilization >= 60) return AppTheme.infoColor;
    return AppTheme.successColor;
  }
}

/// Active budgets list
class ActiveBudgetsList extends ConsumerWidget {
  const ActiveBudgetsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Restore when activeBudgetsProvider is implemented
    // final activeBudgets = ref.watch(activeBudgetsProvider);
    final activeBudgets = <Map<String, dynamic>>[]; // Placeholder

    if (activeBudgets.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No Active Budgets',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first budget to start tracking your spending goals.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Budgets',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...activeBudgets.map((budget) => _BudgetCard(budget: budget)),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final dynamic budget;

  const _BudgetCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressColor = _getProgressColor(budget.percentageUsed);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    budget.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: progressColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    budget.period.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${budget.formattedSpentAmount} of ${budget.formattedBudgetAmount}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  budget.formattedPercentageUsed,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: budget.percentageUsed / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '${budget.daysRemaining} days remaining',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                if (budget.dailyAllowance > 0) ...[
                  Text(
                    'Daily: ${budget.formattedDailyAllowance}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 100) return AppTheme.errorColor;
    if (percentage >= 80) return AppTheme.warningColor;
    if (percentage >= 60) return AppTheme.infoColor;
    return AppTheme.successColor;
  }
}

/// Financial goals widget
class FinancialGoalsWidget extends ConsumerWidget {
  const FinancialGoalsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Restore when financialGoalsProvider is implemented
    // final goalsAsync = ref.watch(financialGoalsProvider(null));
    final goalsAsync = AsyncValue.data(<Map<String, dynamic>>[]); // Placeholder

    return goalsAsync.when(
      data: (goals) {
        if (goals.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Financial Goals',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set financial goals to track your progress and stay motivated.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Goals',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...goals.take(3).map((goal) => _FinancialGoalCard(goal: goal)),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error loading goals: $error'),
        ),
      ),
    );
  }
}

class _FinancialGoalCard extends StatelessWidget {
  final dynamic goal;

  const _FinancialGoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressColor = goal.isOnTrack ? AppTheme.successColor : AppTheme.warningColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: progressColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    goal.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              goal.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${goal.formattedCurrentAmount} of ${goal.formattedTargetAmount}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  goal.formattedProgressPercentage,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: goal.progressPercentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '${goal.daysRemaining} days remaining',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                Icon(
                  goal.isOnTrack ? Icons.trending_up : Icons.trending_down,
                  size: 14,
                  color: progressColor,
                ),
                const SizedBox(width: 4),
                Text(
                  goal.isOnTrack ? 'On Track' : 'Behind',
                  style: TextStyle(
                    fontSize: 12,
                    color: progressColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder widgets for additional analytics components
class SpendingComparisonWidget extends StatelessWidget {
  const SpendingComparisonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Spending Comparison Widget - Coming Soon'),
      ),
    );
  }
}

class SpendingFrequencyWidget extends StatelessWidget {
  const SpendingFrequencyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Spending Frequency Widget - Coming Soon'),
      ),
    );
  }
}

class CategoryTrendsWidget extends StatelessWidget {
  const CategoryTrendsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Category Trends Widget - Coming Soon'),
      ),
    );
  }
}

/// Export data dialog
class ExportDataDialog extends StatefulWidget {
  const ExportDataDialog({super.key});

  @override
  State<ExportDataDialog> createState() => _ExportDataDialogState();
}

class _ExportDataDialogState extends State<ExportDataDialog> {
  String _selectedFormat = 'csv';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Spending Data'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedFormat,
            decoration: const InputDecoration(
              labelText: 'Export Format',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'csv', child: Text('CSV')),
              DropdownMenuItem(value: 'pdf', child: Text('PDF')),
              DropdownMenuItem(value: 'json', child: Text('JSON')),
            ],
            onChanged: (value) {
              setState(() => _selectedFormat = value!);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(const Duration(days: 30)),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _startDate = date);
                    }
                  },
                  child: Text(_startDate != null
                      ? DateFormat('MMM dd, yyyy').format(_startDate!)
                      : 'Start Date'),
                ),
              ),
              const Text(' - '),
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _endDate = date);
                    }
                  },
                  child: Text(_endDate != null
                      ? DateFormat('MMM dd, yyyy').format(_endDate!)
                      : 'End Date'),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Handle export
            Navigator.of(context).pop();
          },
          child: const Text('Export'),
        ),
      ],
    );
  }
}

/// Create budget dialog
class CreateBudgetDialog extends StatefulWidget {
  const CreateBudgetDialog({super.key});

  @override
  State<CreateBudgetDialog> createState() => _CreateBudgetDialogState();
}

class _CreateBudgetDialogState extends State<CreateBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedPeriod = 'monthly';

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Budget'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Budget Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a budget name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Budget Amount',
                prefixText: 'RM ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a budget amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedPeriod,
              decoration: const InputDecoration(
                labelText: 'Budget Period',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
                DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
              ],
              onChanged: (value) {
                setState(() => _selectedPeriod = value!);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // Handle budget creation
              Navigator.of(context).pop();
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
