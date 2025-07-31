import 'package:flutter/material.dart';

/// Widget for selecting withdrawal method with Material Design 3 styling
class WithdrawalMethodSelector extends StatelessWidget {
  final String selectedMethod;
  final Function(String) onMethodChanged;

  const WithdrawalMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bank Transfer Option
        _buildMethodCard(
          context,
          method: 'bank_transfer',
          title: 'Bank Transfer',
          subtitle: 'Transfer to your bank account',
          icon: Icons.account_balance,
          processingTime: '1-3 business days',
          fee: '1% (max RM 5.00)',
          isRecommended: true,
        ),
        
        const SizedBox(height: 12),
        
        // E-Wallet Option
        _buildMethodCard(
          context,
          method: 'ewallet',
          title: 'E-Wallet',
          subtitle: 'Transfer to your e-wallet',
          icon: Icons.wallet,
          processingTime: 'Instant - 24 hours',
          fee: 'Free',
          isEnabled: false, // Disabled for now
        ),
        
        const SizedBox(height: 12),
        
        // Cash Option
        _buildMethodCard(
          context,
          method: 'cash',
          title: 'Cash Pickup',
          subtitle: 'Collect cash at partner locations',
          icon: Icons.local_atm,
          processingTime: '2-4 hours',
          fee: 'RM 2.00',
          isEnabled: false, // Disabled for now
        ),
      ],
    );
  }

  Widget _buildMethodCard(
    BuildContext context, {
    required String method,
    required String title,
    required String subtitle,
    required IconData icon,
    required String processingTime,
    required String fee,
    bool isRecommended = false,
    bool isEnabled = true,
  }) {
    final theme = Theme.of(context);
    final isSelected = selectedMethod == method;
    
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected 
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: InkWell(
        onTap: isEnabled ? () => onMethodChanged(method) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Method icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Method details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isEnabled 
                                    ? null 
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (isRecommended) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Recommended',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            if (!isEnabled) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Coming Soon',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isEnabled 
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Selection indicator
                  Radio<String>(
                    value: method,
                    groupValue: selectedMethod,
                    onChanged: isEnabled ? (value) => onMethodChanged(value!) : null,
                    activeColor: theme.colorScheme.primary,
                  ),
                ],
              ),
              
              if (isSelected || isRecommended) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Processing Time',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              processingTime,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.payments,
                                  size: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Fee',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fee,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: fee == 'Free' 
                                    ? Colors.green 
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: fee == 'Free' ? FontWeight.w600 : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
