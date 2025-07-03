import 'package:flutter/material.dart';

/// Wallet auto reload settings widget
class WalletAutoReloadSettingsWidget extends StatefulWidget {
  final bool autoReloadEnabled;
  final double reloadAmount;
  final double triggerAmount;
  final String? paymentMethodId;
  final Function(bool)? onAutoReloadToggle;
  final Function(double)? onReloadAmountChanged;
  final Function(double)? onTriggerAmountChanged;
  final Function(String?)? onPaymentMethodChanged;
  final VoidCallback? onSelectPaymentMethod;

  const WalletAutoReloadSettingsWidget({
    super.key,
    required this.autoReloadEnabled,
    required this.reloadAmount,
    required this.triggerAmount,
    this.paymentMethodId,
    this.onAutoReloadToggle,
    this.onReloadAmountChanged,
    this.onTriggerAmountChanged,
    this.onPaymentMethodChanged,
    this.onSelectPaymentMethod,
  });

  @override
  State<WalletAutoReloadSettingsWidget> createState() => _WalletAutoReloadSettingsWidgetState();
}

class _WalletAutoReloadSettingsWidgetState extends State<WalletAutoReloadSettingsWidget> {
  late TextEditingController _reloadAmountController;
  late TextEditingController _triggerAmountController;

  @override
  void initState() {
    super.initState();
    _reloadAmountController = TextEditingController(
      text: widget.reloadAmount.toStringAsFixed(2),
    );
    _triggerAmountController = TextEditingController(
      text: widget.triggerAmount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _reloadAmountController.dispose();
    _triggerAmountController.dispose();
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
                  Icons.autorenew,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Auto Reload Settings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Auto Reload Toggle
            Row(
              children: [
                Icon(
                  Icons.autorenew,
                  size: 24,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enable Auto Reload',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Automatically reload wallet when balance is low',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: widget.autoReloadEnabled,
                  onChanged: widget.onAutoReloadToggle,
                ),
              ],
            ),
            
            if (widget.autoReloadEnabled) ...[
              const SizedBox(height: 24),
              
              // Trigger Amount
              Text(
                'Reload when balance falls below:',
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
                      controller: _triggerAmountController,
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
                        widget.onTriggerAmountChanged?.call(amount);
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Reload Amount
              Text(
                'Reload amount:',
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
                      controller: _reloadAmountController,
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
                        widget.onReloadAmountChanged?.call(amount);
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
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
                children: [50, 100, 200, 500].map((amount) {
                  return OutlinedButton(
                    onPressed: () {
                      _reloadAmountController.text = amount.toString();
                      widget.onReloadAmountChanged?.call(amount.toDouble());
                    },
                    child: Text('RM $amount'),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 16),
              
              // Payment Method Selection
              Text(
                'Payment method:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: widget.onSelectPaymentMethod,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.credit_card,
                        size: 20,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.paymentMethodId != null
                              ? 'Payment method selected'
                              : 'Select payment method',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Auto Reload Info
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
                          'Auto Reload Information',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Auto reload will trigger when your balance falls below the set amount\n'
                      '• You will receive a notification when auto reload occurs\n'
                      '• You can disable auto reload at any time\n'
                      '• Ensure your payment method has sufficient funds',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
