import 'package:flutter/material.dart';

/// Widget displaying withdrawal summary with amount breakdown
class WithdrawalSummaryCard extends StatelessWidget {
  final double amount;
  final String method;
  final String? bankAccountId;
  final double processingFee;

  const WithdrawalSummaryCard({
    super.key,
    required this.amount,
    required this.method,
    this.bankAccountId,
    required this.processingFee,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final netAmount = amount - processingFee;
    
    return Card(
      elevation: 2,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Withdrawal Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Amount breakdown
            _buildSummaryRow(
              context,
              label: 'Withdrawal Amount',
              value: 'RM ${amount.toStringAsFixed(2)}',
              isMainAmount: true,
            ),
            
            if (processingFee > 0) ...[
              const SizedBox(height: 8),
              _buildSummaryRow(
                context,
                label: 'Processing Fee',
                value: '- RM ${processingFee.toStringAsFixed(2)}',
                isNegative: true,
              ),
              
              const SizedBox(height: 8),
              Divider(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
              const SizedBox(height: 8),
            ],
            
            _buildSummaryRow(
              context,
              label: 'You will receive',
              value: 'RM ${netAmount.toStringAsFixed(2)}',
              isFinal: true,
            ),
            
            const SizedBox(height: 16),
            
            // Method and timing info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        _getMethodIcon(method),
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Method: ${_getMethodDisplayName(method)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Processing time: ${_getProcessingTime(method)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            if (method == 'bank_transfer') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Funds will be transferred to your selected bank account within 1-3 business days.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.blue.shade700,
                        ),
                      ),
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

  Widget _buildSummaryRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isMainAmount = false,
    bool isNegative = false,
    bool isFinal = false,
  }) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isFinal ? FontWeight.w600 : FontWeight.normal,
            color: isFinal ? theme.colorScheme.primary : null,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isMainAmount || isFinal ? FontWeight.w600 : FontWeight.normal,
            color: isNegative 
                ? theme.colorScheme.error
                : isFinal 
                    ? theme.colorScheme.primary
                    : null,
            fontSize: isMainAmount || isFinal ? 16 : null,
          ),
        ),
      ],
    );
  }

  IconData _getMethodIcon(String method) {
    switch (method) {
      case 'bank_transfer':
        return Icons.account_balance;
      case 'ewallet':
        return Icons.wallet;
      case 'cash':
        return Icons.local_atm;
      default:
        return Icons.payment;
    }
  }

  String _getMethodDisplayName(String method) {
    switch (method) {
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'ewallet':
        return 'E-Wallet';
      case 'cash':
        return 'Cash Pickup';
      default:
        return method;
    }
  }

  String _getProcessingTime(String method) {
    switch (method) {
      case 'bank_transfer':
        return '1-3 business days';
      case 'ewallet':
        return 'Instant - 24 hours';
      case 'cash':
        return '2-4 hours';
      default:
        return 'Unknown';
    }
  }
}
