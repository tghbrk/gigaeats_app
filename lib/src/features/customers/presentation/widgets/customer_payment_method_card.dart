import 'package:flutter/material.dart';

/// Payment method card widget for customer
class CustomerPaymentMethodCard extends StatelessWidget {
  final String? cardNumber;
  final String? cardType;
  final String? expiryDate;
  final bool isDefault;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSetDefault;

  const CustomerPaymentMethodCard({
    super.key,
    this.cardNumber,
    this.cardType,
    this.expiryDate,
    this.isDefault = false,
    this.onEdit,
    this.onDelete,
    this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCardIcon(cardType),
                  size: 32,
                  color: theme.primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cardType ?? 'Credit Card',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        '**** **** **** ${cardNumber?.substring(cardNumber!.length - 4) ?? '0000'}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Default',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Expires: ${expiryDate ?? 'N/A'}',
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                if (onEdit != null)
                  TextButton(
                    onPressed: onEdit,
                    child: const Text('Edit'),
                  ),
                if (onDelete != null)
                  TextButton(
                    onPressed: onDelete,
                    child: const Text('Delete'),
                  ),
                if (!isDefault && onSetDefault != null)
                  TextButton(
                    onPressed: onSetDefault,
                    child: const Text('Set Default'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCardIcon(String? cardType) {
    switch (cardType?.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      case 'amex':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }
}
