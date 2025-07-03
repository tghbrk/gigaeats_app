import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../data/models/spending_limits.dart';

/// Dialog for adding or editing spending limits
class SpendingLimitDialog extends StatefulWidget {
  final SpendingLimit? existingLimit;
  final Function(SpendingLimitPeriod period, double amount, int alertPercentage) onSave;

  const SpendingLimitDialog({
    super.key,
    this.existingLimit,
    required this.onSave,
  });

  @override
  State<SpendingLimitDialog> createState() => _SpendingLimitDialogState();
}

class _SpendingLimitDialogState extends State<SpendingLimitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  SpendingLimitPeriod _selectedPeriod = SpendingLimitPeriod.monthly;
  int _alertPercentage = 80;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingLimit != null) {
      _selectedPeriod = widget.existingLimit!.period;
      _amountController.text = widget.existingLimit!.limitAmount.toStringAsFixed(2);
      _alertPercentage = widget.existingLimit!.alertAtPercentage;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingLimit != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Spending Limit' : 'Add Spending Limit'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period selection
              Text(
                'Period',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<SpendingLimitPeriod>(
                value: _selectedPeriod,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: SpendingLimitPeriod.values.map((period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Text(_getPeriodDisplayName(period)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPeriod = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Amount input
              Text(
                'Limit Amount',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixText: 'RM ',
                  hintText: '0.00',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  if (amount > 10000) {
                    return 'Amount cannot exceed RM 10,000';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Alert percentage
              Text(
                'Alert at $_alertPercentage% of limit',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Slider(
                value: _alertPercentage.toDouble(),
                min: 50,
                max: 95,
                divisions: 9,
                label: '$_alertPercentage%',
                onChanged: (value) {
                  setState(() {
                    _alertPercentage = value.round();
                  });
                },
              ),
              Text(
                'You will be notified when you reach $_alertPercentage% of your spending limit',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),

              if (_isLoading) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveSpendingLimit,
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  void _saveSpendingLimit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final amount = double.parse(_amountController.text);

    // Simulate saving delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSave(_selectedPeriod, amount, _alertPercentage);
      }
    });
  }

  String _getPeriodDisplayName(SpendingLimitPeriod period) {
    switch (period) {
      case SpendingLimitPeriod.daily:
        return 'Daily';
      case SpendingLimitPeriod.weekly:
        return 'Weekly';
      case SpendingLimitPeriod.monthly:
        return 'Monthly';
    }
  }
}

/// Widget for managing wallet spending limits
class WalletSpendingLimitsWidget extends ConsumerStatefulWidget {
  const WalletSpendingLimitsWidget({super.key});

  @override
  ConsumerState<WalletSpendingLimitsWidget> createState() => _WalletSpendingLimitsWidgetState();
}

class _WalletSpendingLimitsWidgetState extends ConsumerState<WalletSpendingLimitsWidget> {
  List<SpendingLimit> _spendingLimits = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSpendingLimits();
  }

  Future<void> _loadSpendingLimits() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Load actual spending limits from provider
      // For now, create default test limits
      _spendingLimits = [
        SpendingLimit.test(
          period: SpendingLimitPeriod.daily,
          limitAmount: 200.0,
          currentSpent: 45.0,
        ),
        SpendingLimit.test(
          period: SpendingLimitPeriod.weekly,
          limitAmount: 1000.0,
          currentSpent: 320.0,
        ),
        SpendingLimit.test(
          period: SpendingLimitPeriod.monthly,
          limitAmount: 3000.0,
          currentSpent: 1250.0,
        ),
      ];

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: LoadingWidget()),
        ),
      );
    }

    if (_errorMessage != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                color: AppTheme.errorColor,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load spending limits',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadSpendingLimits,
                child: const Text('Retry'),
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
          'Spending Limits',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Set limits to control your spending and get alerts when approaching limits',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),

        // Spending limits list
        ..._spendingLimits.map((limit) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildSpendingLimitCard(context, limit),
        )),

        const SizedBox(height: 8),

        // Add new limit button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showAddSpendingLimitDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Spending Limit'),
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingLimitCard(BuildContext context, SpendingLimit limit) {
    final theme = Theme.of(context);
    final usagePercentage = limit.spendingPercentage * 100;
    final isExceeded = limit.isExceeded;
    final shouldAlert = limit.isAlertThresholdReached;

    Color statusColor;
    if (isExceeded) {
      statusColor = AppTheme.errorColor;
    } else if (shouldAlert) {
      statusColor = AppTheme.warningColor;
    } else {
      statusColor = AppTheme.successColor;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getPeriodIcon(limit.period),
                  color: statusColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${limit.periodDisplayName} Limit',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        limit.statusDescription,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: limit.isActive,
                  onChanged: (value) => _toggleSpendingLimit(limit, value),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Spent: ${limit.formattedCurrentSpent}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      'Limit: ${limit.formattedLimitAmount}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (usagePercentage / 100).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
                const SizedBox(height: 4),
                Text(
                  '${usagePercentage.toStringAsFixed(1)}% used',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Period info and actions
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Period',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        _formatPeriodRange(limit),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showEditSpendingLimitDialog(context, limit),
                  child: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _showDeleteSpendingLimitDialog(context, limit),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPeriodIcon(SpendingLimitPeriod period) {
    switch (period) {
      case SpendingLimitPeriod.daily:
        return Icons.today;
      case SpendingLimitPeriod.weekly:
        return Icons.date_range;
      case SpendingLimitPeriod.monthly:
        return Icons.calendar_month;
    }
  }

  String _formatPeriodRange(SpendingLimit limit) {
    final start = limit.currentPeriodStart;
    final end = limit.currentPeriodEnd;
    
    switch (limit.period) {
      case SpendingLimitPeriod.daily:
        return '${start.day}/${start.month}/${start.year}';
      case SpendingLimitPeriod.weekly:
        return '${start.day}/${start.month} - ${end.day}/${end.month}';
      case SpendingLimitPeriod.monthly:
        return '${_getMonthName(start.month)} ${start.year}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  void _toggleSpendingLimit(SpendingLimit limit, bool isActive) {
    setState(() {
      final index = _spendingLimits.indexWhere((l) => l.id == limit.id);
      if (index != -1) {
        _spendingLimits[index] = limit.copyWith(isActive: isActive);
      }
    });
    _saveSpendingLimit(_spendingLimits[_spendingLimits.indexWhere((l) => l.id == limit.id)]);
  }

  void _showAddSpendingLimitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SpendingLimitDialog(
        onSave: (period, amount, alertPercentage) {
          _addSpendingLimit(period, amount, alertPercentage);
        },
      ),
    );
  }

  void _showEditSpendingLimitDialog(BuildContext context, SpendingLimit limit) {
    showDialog(
      context: context,
      builder: (context) => SpendingLimitDialog(
        existingLimit: limit,
        onSave: (period, amount, alertPercentage) {
          _updateSpendingLimit(limit, period, amount, alertPercentage);
        },
      ),
    );
  }

  void _showDeleteSpendingLimitDialog(BuildContext context, SpendingLimit limit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Spending Limit'),
        content: Text('Are you sure you want to delete the ${limit.periodDisplayName.toLowerCase()} spending limit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteSpendingLimit(limit);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addSpendingLimit(SpendingLimitPeriod period, double amount, int alertPercentage) {
    final newLimit = SpendingLimit.test(
      period: period,
      limitAmount: amount,
      currentSpent: 0.0,
    ).copyWith(
      alertAtPercentage: alertPercentage,
    );

    setState(() {
      _spendingLimits.add(newLimit);
    });
    _saveSpendingLimit(newLimit);
  }

  void _updateSpendingLimit(SpendingLimit limit, SpendingLimitPeriod period, double amount, int alertPercentage) {
    setState(() {
      final index = _spendingLimits.indexWhere((l) => l.id == limit.id);
      if (index != -1) {
        _spendingLimits[index] = limit.copyWith(
          period: period,
          limitAmount: amount,
          alertAtPercentage: alertPercentage,
        );
      }
    });
    _saveSpendingLimit(_spendingLimits[_spendingLimits.indexWhere((l) => l.id == limit.id)]);
  }

  void _deleteSpendingLimit(SpendingLimit limit) {
    setState(() {
      _spendingLimits.removeWhere((l) => l.id == limit.id);
    });
    // TODO: Delete from backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Spending limit deleted'),
        backgroundColor: AppTheme.warningColor,
      ),
    );
  }

  Future<void> _saveSpendingLimit(SpendingLimit limit) async {
    try {
      // TODO: Save spending limit to backend
      debugPrint('Saving spending limit: ${limit.periodDisplayName} - RM ${limit.limitAmount}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Spending limit saved'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save spending limit: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
