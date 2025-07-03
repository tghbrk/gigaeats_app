import 'package:flutter/material.dart';

/// Wallet analytics summary cards
class WalletAnalyticsSummaryCards extends StatelessWidget {
  final double totalBalance;
  final double totalTopups;
  final double totalSpent;

  const WalletAnalyticsSummaryCards({
    super.key,
    required this.totalBalance,
    required this.totalTopups,
    required this.totalSpent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AnalyticsCard(
            title: 'Current Balance',
            value: 'RM ${totalBalance.toStringAsFixed(2)}',
            icon: Icons.account_balance_wallet,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _AnalyticsCard(
            title: 'Total Topups',
            value: 'RM ${totalTopups.toStringAsFixed(2)}',
            icon: Icons.add_circle,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _AnalyticsCard(
            title: 'Total Spent',
            value: 'RM ${totalSpent.toStringAsFixed(2)}',
            icon: Icons.remove_circle,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
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
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wallet spending trends chart
class WalletSpendingTrendsChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const WalletSpendingTrendsChart({
    super.key,
    required this.data,
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
              'Spending Trends',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('Line chart placeholder - implement with fl_chart'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wallet balance history chart
class WalletBalanceHistoryChart extends StatelessWidget {
  final List<Map<String, dynamic>> balanceHistory;

  const WalletBalanceHistoryChart({
    super.key,
    required this.balanceHistory,
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
              'Balance History',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('Area chart placeholder - implement with fl_chart'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wallet category spending chart
class WalletCategorySpendingChart extends StatelessWidget {
  final List<Map<String, dynamic>> categoryData;

  const WalletCategorySpendingChart({
    super.key,
    required this.categoryData,
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
              'Category Spending',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('Donut chart placeholder - implement with fl_chart'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wallet top vendors chart
class WalletTopVendorsChart extends StatelessWidget {
  final List<Map<String, dynamic>> vendorData;

  const WalletTopVendorsChart({
    super.key,
    required this.vendorData,
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
              'Top Vendors',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...vendorData.take(5).map((vendor) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    child: Text(
                      vendor['name']?.substring(0, 1).toUpperCase() ?? 'V',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor['name'] ?? 'Unknown Vendor',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${vendor['orders']} orders',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'RM ${(vendor['amount'] ?? 0.0).toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

/// Wallet category breakdown list
class WalletCategoryBreakdownList extends StatelessWidget {
  final List<Map<String, dynamic>> categories;

  const WalletCategoryBreakdownList({
    super.key,
    required this.categories,
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
              'Category Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...categories.map((category) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(category['color'] ?? 0xFF2196F3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category['name'] ?? 'Unknown',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${category['percentage']?.toStringAsFixed(1) ?? '0.0'}% of total',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'RM ${(category['amount'] ?? 0.0).toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

/// Wallet analytics insights widget
class WalletAnalyticsInsightsWidget extends StatelessWidget {
  final List<String> insights;

  const WalletAnalyticsInsightsWidget({
    super.key,
    required this.insights,
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
            Row(
              children: [
                Icon(
                  Icons.insights,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Wallet Insights',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...insights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
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
    );
  }
}

/// Budget overview cards
class BudgetOverviewCards extends StatelessWidget {
  final double monthlyBudget;
  final double spent;
  final double remaining;

  const BudgetOverviewCards({
    super.key,
    required this.monthlyBudget,
    required this.spent,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final spentPercentage = monthlyBudget > 0 ? (spent / monthlyBudget) * 100 : 0.0;
    
    return Row(
      children: [
        Expanded(
          child: _BudgetCard(
            title: 'Monthly Budget',
            value: 'RM ${monthlyBudget.toStringAsFixed(2)}',
            icon: Icons.account_balance,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _BudgetCard(
            title: 'Spent (${spentPercentage.toStringAsFixed(1)}%)',
            value: 'RM ${spent.toStringAsFixed(2)}',
            icon: Icons.trending_down,
            color: spentPercentage > 80 ? Colors.red : Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _BudgetCard(
            title: 'Remaining',
            value: 'RM ${remaining.toStringAsFixed(2)}',
            icon: Icons.savings,
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _BudgetCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
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
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Active budgets list
class ActiveBudgetsList extends StatelessWidget {
  final List<Map<String, dynamic>> budgets;

  const ActiveBudgetsList({
    super.key,
    required this.budgets,
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
              'Active Budgets',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (budgets.isEmpty)
              const Center(
                child: Text('No active budgets'),
              )
            else
              ...budgets.map((budget) {
                final spent = budget['spent'] ?? 0.0;
                final limit = budget['limit'] ?? 1.0;
                final percentage = (spent / limit) * 100;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            budget['category'] ?? 'Unknown',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'RM ${spent.toStringAsFixed(2)} / RM ${limit.toStringAsFixed(2)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentage > 90 ? Colors.red :
                          percentage > 75 ? Colors.orange :
                          Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${percentage.toStringAsFixed(1)}% used',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

/// Financial goals widget
class FinancialGoalsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> goals;

  const FinancialGoalsWidget({
    super.key,
    required this.goals,
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
              'Financial Goals',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (goals.isEmpty)
              const Center(
                child: Text('No financial goals set'),
              )
            else
              ...goals.map((goal) {
                final current = goal['current'] ?? 0.0;
                final target = goal['target'] ?? 1.0;
                final percentage = (current / target) * 100;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            goal['name'] ?? 'Unknown Goal',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'RM ${current.toStringAsFixed(2)} / RM ${target.toStringAsFixed(2)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentage >= 100 ? Colors.green :
                          percentage >= 75 ? Colors.blue :
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${percentage.toStringAsFixed(1)}% complete',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

/// Wallet analytics export dialog
class WalletAnalyticsExportDialog extends StatelessWidget {
  final VoidCallback? onExportPdf;
  final VoidCallback? onExportCsv;

  const WalletAnalyticsExportDialog({
    super.key,
    this.onExportPdf,
    this.onExportCsv,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Analytics'),
      content: const Text('Choose export format:'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onExportCsv?.call();
          },
          child: const Text('CSV'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onExportPdf?.call();
          },
          child: const Text('PDF'),
        ),
      ],
    );
  }
}

/// Export data dialog
class ExportDataDialog extends StatelessWidget {
  final VoidCallback? onExport;

  const ExportDataDialog({
    super.key,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Data'),
      content: const Text('Export your wallet data?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onExport?.call();
          },
          child: const Text('Export'),
        ),
      ],
    );
  }
}

/// Create budget dialog
class CreateBudgetDialog extends StatelessWidget {
  final VoidCallback? onCreate;

  const CreateBudgetDialog({
    super.key,
    this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Budget'),
      content: const Text('Create a new budget category?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onCreate?.call();
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
