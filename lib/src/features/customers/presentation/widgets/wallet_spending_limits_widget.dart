import 'package:flutter/material.dart';

/// Wallet spending limits widget
class WalletSpendingLimitsWidget extends StatefulWidget {
  final bool dailyLimitEnabled;
  final bool monthlyLimitEnabled;
  final double dailyLimit;
  final double monthlyLimit;
  final double dailySpent;
  final double monthlySpent;
  final Function(bool)? onDailyLimitToggle;
  final Function(bool)? onMonthlyLimitToggle;
  final Function(double)? onDailyLimitChanged;
  final Function(double)? onMonthlyLimitChanged;

  const WalletSpendingLimitsWidget({
    super.key,
    required this.dailyLimitEnabled,
    required this.monthlyLimitEnabled,
    required this.dailyLimit,
    required this.monthlyLimit,
    required this.dailySpent,
    required this.monthlySpent,
    this.onDailyLimitToggle,
    this.onMonthlyLimitToggle,
    this.onDailyLimitChanged,
    this.onMonthlyLimitChanged,
  });

  @override
  State<WalletSpendingLimitsWidget> createState() => _WalletSpendingLimitsWidgetState();
}

class _WalletSpendingLimitsWidgetState extends State<WalletSpendingLimitsWidget> {
  late TextEditingController _dailyLimitController;
  late TextEditingController _monthlyLimitController;

  @override
  void initState() {
    super.initState();
    _dailyLimitController = TextEditingController(
      text: widget.dailyLimit.toStringAsFixed(2),
    );
    _monthlyLimitController = TextEditingController(
      text: widget.monthlyLimit.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _dailyLimitController.dispose();
    _monthlyLimitController.dispose();
    super.dispose();
  }

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
                  Icons.account_balance_wallet,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Spending Limits',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Daily Limit Section
            _buildLimitSection(
              context: context,
              title: 'Daily Spending Limit',
              subtitle: 'Set maximum daily spending amount',
              icon: Icons.today,
              enabled: widget.dailyLimitEnabled,
              limit: widget.dailyLimit,
              spent: widget.dailySpent,
              controller: _dailyLimitController,
              onToggle: widget.onDailyLimitToggle,
              onLimitChanged: widget.onDailyLimitChanged,
              quickAmounts: [50, 100, 200, 500],
            ),
            
            const SizedBox(height: 24),
            
            // Monthly Limit Section
            _buildLimitSection(
              context: context,
              title: 'Monthly Spending Limit',
              subtitle: 'Set maximum monthly spending amount',
              icon: Icons.calendar_month,
              enabled: widget.monthlyLimitEnabled,
              limit: widget.monthlyLimit,
              spent: widget.monthlySpent,
              controller: _monthlyLimitController,
              onToggle: widget.onMonthlyLimitToggle,
              onLimitChanged: widget.onMonthlyLimitChanged,
              quickAmounts: [1000, 2000, 5000, 10000],
            ),
            
            const SizedBox(height: 16),
            
            // Spending Limits Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Spending Limits Information',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Spending limits help you control your expenses\n'
                    '• Transactions will be blocked when limits are reached\n'
                    '• Limits reset automatically (daily at midnight, monthly on 1st)\n'
                    '• You can modify limits at any time',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitSection({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool enabled,
    required double limit,
    required double spent,
    required TextEditingController controller,
    required Function(bool)? onToggle,
    required Function(double)? onLimitChanged,
    required List<int> quickAmounts,
  }) {
    final theme = Theme.of(context);
    final percentage = limit > 0 ? (spent / limit) * 100 : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle Section
        Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: enabled,
              onChanged: onToggle,
            ),
          ],
        ),
        
        if (enabled) ...[
          const SizedBox(height: 16),
          
          // Current Usage
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current Usage',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'RM ${spent.toStringAsFixed(2)} / RM ${limit.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
          ),
          
          const SizedBox(height: 16),
          
          // Limit Amount Input
          Text(
            'Set limit amount:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'RM ',
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(),
                    hintText: '0.00',
                  ),
                  onChanged: (value) {
                    final amount = double.tryParse(value) ?? 0.0;
                    onLimitChanged?.call(amount);
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Quick Amount Buttons
          Text(
            'Quick amounts:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: quickAmounts.map((amount) {
              return OutlinedButton(
                onPressed: () {
                  controller.text = amount.toString();
                  onLimitChanged?.call(amount.toDouble());
                },
                child: Text('RM $amount'),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
