import 'package:flutter/material.dart';

import '../../data/models/customer_payment_method.dart';

/// Widget for displaying a payment method card
class PaymentMethodCard extends StatelessWidget {
  final CustomerPaymentMethod paymentMethod;
  final VoidCallback? onTap;
  final VoidCallback? onSetDefault;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const PaymentMethodCard({
    super.key,
    required this.paymentMethod,
    this.onTap,
    this.onSetDefault,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: paymentMethod.isDefault
            ? BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with icon and actions
              Row(
                children: [
                  // Payment method icon
                  Container(
                    width: 48,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getCardColor(theme),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Icon(
                        _getPaymentMethodIcon(),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Payment method info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getDisplayName(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getSubtitle(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Actions menu
                  PopupMenuButton<String>(
                    onSelected: _handleMenuAction,
                    itemBuilder: (context) => [
                      if (!paymentMethod.isDefault)
                        const PopupMenuItem(
                          value: 'set_default',
                          child: Row(
                            children: [
                              Icon(Icons.star_outline),
                              SizedBox(width: 8),
                              Text('Set as Default'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 8),
                            Text('Edit Nickname'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              
              // Default badge
              if (paymentMethod.isDefault) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Default',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Additional info
              if (paymentMethod.lastUsedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Last used: ${_formatDate(paymentMethod.lastUsedAt!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'set_default':
        onSetDefault?.call();
        break;
      case 'edit':
        onEdit?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }

  IconData _getPaymentMethodIcon() {
    if (paymentMethod.type == CustomerPaymentMethodType.card) {
      switch (paymentMethod.cardBrand) {
        case CardBrand.visa:
          return Icons.credit_card;
        case CardBrand.mastercard:
          return Icons.credit_card;
        case CardBrand.amex:
          return Icons.credit_card;
        default:
          return Icons.credit_card;
      }
    } else if (paymentMethod.type == CustomerPaymentMethodType.bankAccount) {
      return Icons.account_balance;
    } else {
      return Icons.wallet;
    }
  }

  Color _getCardColor(ThemeData theme) {
    if (paymentMethod.type == CustomerPaymentMethodType.card) {
      switch (paymentMethod.cardBrand) {
        case CardBrand.visa:
          return const Color(0xFF1A1F71); // Visa blue
        case CardBrand.mastercard:
          return const Color(0xFFEB001B); // Mastercard red
        case CardBrand.amex:
          return const Color(0xFF006FCF); // Amex blue
        case CardBrand.discover:
          return const Color(0xFFFF6000); // Discover orange
        default:
          return theme.colorScheme.primary;
      }
    } else if (paymentMethod.type == CustomerPaymentMethodType.bankAccount) {
      return const Color(0xFF2E7D32); // Green for bank
    } else {
      return const Color(0xFF7B1FA2); // Purple for wallet
    }
  }

  String _getDisplayName() {
    if (paymentMethod.nickname != null && paymentMethod.nickname!.isNotEmpty) {
      return paymentMethod.nickname!;
    }

    if (paymentMethod.type == CustomerPaymentMethodType.card) {
      final brand = paymentMethod.cardBrand != null 
          ? _getCardBrandDisplay(paymentMethod.cardBrand!)
          : 'Card';
      return brand;
    } else if (paymentMethod.type == CustomerPaymentMethodType.bankAccount) {
      return paymentMethod.bankName ?? 'Bank Account';
    } else {
      return 'Digital Wallet';
    }
  }

  String _getSubtitle() {
    if (paymentMethod.type == CustomerPaymentMethodType.card) {
      final last4 = paymentMethod.cardLast4 ?? '****';
      final expiry = paymentMethod.cardExpMonth != null && paymentMethod.cardExpYear != null
          ? ' • ${paymentMethod.cardExpMonth!.toString().padLeft(2, '0')}/${paymentMethod.cardExpYear}'
          : '';
      return '•••• •••• •••• $last4$expiry';
    } else if (paymentMethod.type == CustomerPaymentMethodType.bankAccount) {
      final last4 = paymentMethod.bankAccountLast4 ?? '****';
      return '•••• •••• •••• $last4';
    } else {
      return paymentMethod.walletType ?? 'Digital Wallet';
    }
  }

  String _getCardBrandDisplay(CardBrand brand) {
    switch (brand) {
      case CardBrand.visa:
        return 'Visa';
      case CardBrand.mastercard:
        return 'Mastercard';
      case CardBrand.amex:
        return 'American Express';
      case CardBrand.discover:
        return 'Discover';
      case CardBrand.jcb:
        return 'JCB';
      case CardBrand.diners:
        return 'Diners Club';
      case CardBrand.unionpay:
        return 'UnionPay';
      case CardBrand.unknown:
        return 'Card';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
