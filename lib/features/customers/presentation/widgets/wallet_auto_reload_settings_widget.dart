import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/customer_payment_methods_provider.dart';
import '../../data/models/customer_payment_method.dart';
import '../widgets/add_payment_method_dialog.dart';

/// Widget for managing wallet auto-reload settings
class WalletAutoReloadSettingsWidget extends ConsumerStatefulWidget {
  const WalletAutoReloadSettingsWidget({super.key});

  @override
  ConsumerState<WalletAutoReloadSettingsWidget> createState() => _WalletAutoReloadSettingsWidgetState();
}

class _WalletAutoReloadSettingsWidgetState extends ConsumerState<WalletAutoReloadSettingsWidget> {
  bool _isAutoReloadEnabled = false;
  double _thresholdAmount = 50.0;
  double _reloadAmount = 100.0;
  String? _selectedPaymentMethodId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAutoReloadSettings();
  }

  Future<void> _loadAutoReloadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Load actual settings from provider
      // For now, use default values
      setState(() {
        _isAutoReloadEnabled = false;
        _thresholdAmount = 50.0;
        _reloadAmount = 100.0;
        _selectedPaymentMethodId = null;
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
    final paymentMethodsAsync = ref.watch(customerValidPaymentMethodsProvider);

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
                'Failed to load auto-reload settings',
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
                onPressed: _loadAutoReloadSettings,
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
          'Auto-reload Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Automatically add money to your wallet when balance is low',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),

        // Auto-reload toggle
        _buildAutoReloadToggleCard(context),
        const SizedBox(height: 16),

        // Auto-reload configuration (only show if enabled)
        if (_isAutoReloadEnabled) ...[
          _buildThresholdAmountCard(context),
          const SizedBox(height: 16),
          _buildReloadAmountCard(context),
          const SizedBox(height: 16),
          _buildPaymentMethodCard(context, paymentMethodsAsync),
          const SizedBox(height: 16),
          _buildAutoReloadSummaryCard(context),
        ],
      ],
    );
  }

  Widget _buildAutoReloadToggleCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.autorenew,
              color: _isAutoReloadEnabled ? AppTheme.primaryColor : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enable Auto-reload',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Automatically top up your wallet when balance is low',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isAutoReloadEnabled,
              onChanged: (value) {
                setState(() {
                  _isAutoReloadEnabled = value;
                });
                _saveAutoReloadSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdAmountCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Threshold Amount',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Auto-reload when balance falls below this amount',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'RM ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _thresholdAmount.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _showThresholdAmountDialog(context),
                  child: const Text('Change'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReloadAmountCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reload Amount',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Amount to add to your wallet when auto-reload is triggered',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'RM ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _reloadAmount.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _showReloadAmountDialog(context),
                  child: const Text('Change'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(BuildContext context, AsyncValue<List<CustomerPaymentMethod>> paymentMethodsAsync) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Method',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose the payment method for auto-reload',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),

            paymentMethodsAsync.when(
              data: (paymentMethods) {
                if (paymentMethods.isEmpty) {
                  return _buildNoPaymentMethodsWidget(context);
                }

                final selectedMethod = paymentMethods.firstWhere(
                  (method) => method.id == _selectedPaymentMethodId,
                  orElse: () => paymentMethods.first,
                );

                return _buildSelectedPaymentMethodWidget(context, selectedMethod, paymentMethods);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildNoPaymentMethodsWidget(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPaymentMethodWidget(
    BuildContext context,
    CustomerPaymentMethod selectedMethod,
    List<CustomerPaymentMethod> allMethods,
  ) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _getPaymentMethodIcon(selectedMethod.type),
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedMethod.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (selectedMethod.cardLast4 != null)
                        Text(
                          '•••• ${selectedMethod.cardLast4}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => _showPaymentMethodSelectionDialog(context, allMethods),
          child: const Text('Change'),
        ),
      ],
    );
  }

  Widget _buildNoPaymentMethodsWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_outlined,
                color: AppTheme.warningColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No payment methods available',
                  style: TextStyle(
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddPaymentMethodDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Payment Method'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoReloadSummaryCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Auto-reload Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Auto-reload Configuration',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'When your wallet balance falls below RM ${_thresholdAmount.toStringAsFixed(2)}, we will automatically add RM ${_reloadAmount.toStringAsFixed(2)} to your wallet.',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 14,
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

  IconData _getPaymentMethodIcon(CustomerPaymentMethodType type) {
    switch (type) {
      case CustomerPaymentMethodType.card:
        return Icons.credit_card;
      case CustomerPaymentMethodType.bankAccount:
        return Icons.account_balance;
      case CustomerPaymentMethodType.digitalWallet:
        return Icons.account_balance_wallet;
    }
  }

  void _showThresholdAmountDialog(BuildContext context) {
    final controller = TextEditingController(text: _thresholdAmount.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Threshold Amount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the minimum balance amount that will trigger auto-reload.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Threshold Amount',
                prefixText: 'RM ',
                suffixText: '.00',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppTheme.infoColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recommended: RM 20.00 - RM 100.00',
                      style: TextStyle(
                        color: AppTheme.infoColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
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
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0 && amount <= 1000) {
                setState(() {
                  _thresholdAmount = amount;
                });
                _saveAutoReloadSettings();
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount between RM 1.00 and RM 1,000.00'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showReloadAmountDialog(BuildContext context) {
    final controller = TextEditingController(text: _reloadAmount.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Reload Amount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the amount to add to your wallet when auto-reload is triggered.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Reload Amount',
                prefixText: 'RM ',
                suffixText: '.00',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppTheme.infoColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recommended: RM 50.00 - RM 500.00',
                      style: TextStyle(
                        color: AppTheme.infoColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
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
              final amount = double.tryParse(controller.text);
              if (amount != null && amount >= 10 && amount <= 2000) {
                setState(() {
                  _reloadAmount = amount;
                });
                _saveAutoReloadSettings();
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount between RM 10.00 and RM 2,000.00'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodSelectionDialog(BuildContext context, List<CustomerPaymentMethod> paymentMethods) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Payment Method'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose a payment method for auto-reload'),
              const SizedBox(height: 16),
              ...paymentMethods.map((method) => RadioListTile<String>(
                title: Text(method.displayName),
                subtitle: method.cardLast4 != null
                    ? Text('•••• ${method.cardLast4}')
                    : null,
                value: method.id,
                groupValue: _selectedPaymentMethodId,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethodId = value;
                  });
                  _saveAutoReloadSettings();
                  Navigator.of(context).pop();
                },
                contentPadding: EdgeInsets.zero,
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentMethodDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddPaymentMethodDialog(
        onPaymentMethodAdded: (stripePaymentMethodId, nickname) async {
          try {
            await ref.read(customerPaymentMethodsProvider.notifier).addPaymentMethod(
              stripePaymentMethodId: stripePaymentMethodId,
              nickname: nickname,
            );

            // Refresh payment methods
            ref.invalidate(customerValidPaymentMethodsProvider);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment method added successfully'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to add payment method: ${e.toString()}'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _saveAutoReloadSettings() async {
    try {
      // TODO: Save auto-reload settings to backend
      debugPrint('Saving auto-reload settings: enabled=$_isAutoReloadEnabled, threshold=$_thresholdAmount, reload=$_reloadAmount, paymentMethod=$_selectedPaymentMethodId');

      // For now, just show a success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auto-reload settings saved'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save auto-reload settings: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
