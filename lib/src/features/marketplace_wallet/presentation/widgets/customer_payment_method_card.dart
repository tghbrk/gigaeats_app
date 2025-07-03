import 'package:flutter/material.dart';
import '../../data/models/customer_payment_method.dart';
import '../../../../core/theme/app_theme.dart';

/// Card widget for displaying customer payment method information
class CustomerPaymentMethodCard extends StatelessWidget {
  final CustomerPaymentMethod paymentMethod;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSetDefault;

  const CustomerPaymentMethodCard({
    super.key,
    required this.paymentMethod,
    this.onEdit,
    this.onDelete,
    this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: paymentMethod.isDefault ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: paymentMethod.isDefault
            ? BorderSide(color: AppTheme.primaryColor, width: 2)
            : BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildPaymentMethodIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              paymentMethod.displayName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          if (paymentMethod.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'DEFAULT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _buildPaymentMethodDetails(context),
                    ],
                  ),
                ),
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
                          Text('Edit'),
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
                ),
              ],
            ),
            if (paymentMethod.isExpired) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This payment method has expired',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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

  Widget _buildPaymentMethodIcon() {
    IconData iconData;
    Color iconColor = AppTheme.primaryColor;

    switch (paymentMethod.type) {
      case CustomerPaymentMethodType.card:
        switch (paymentMethod.cardBrand) {
          case CardBrand.visa:
            iconData = Icons.credit_card;
            iconColor = const Color(0xFF1A1F71);
            break;
          case CardBrand.mastercard:
            iconData = Icons.credit_card;
            iconColor = const Color(0xFFEB001B);
            break;
          case CardBrand.amex:
            iconData = Icons.credit_card;
            iconColor = const Color(0xFF006FCF);
            break;
          default:
            iconData = Icons.credit_card;
        }
        break;
      case CustomerPaymentMethodType.bankAccount:
        iconData = Icons.account_balance;
        break;
      case CustomerPaymentMethodType.digitalWallet:
        iconData = Icons.account_balance_wallet;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  Widget _buildPaymentMethodDetails(BuildContext context) {
    switch (paymentMethod.type) {
      case CustomerPaymentMethodType.card:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (paymentMethod.formattedExpiry != null)
              Text(
                'Expires ${paymentMethod.formattedExpiry}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: paymentMethod.isExpired ? Colors.red : Colors.grey[600],
                    ),
              ),
            if (paymentMethod.cardFunding != null)
              Text(
                paymentMethod.cardFunding!.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontSize: 10,
                    ),
              ),
          ],
        );
      case CustomerPaymentMethodType.bankAccount:
        return Text(
          paymentMethod.bankAccountType?.toUpperCase() ?? 'BANK ACCOUNT',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        );
      case CustomerPaymentMethodType.digitalWallet:
        return Text(
          'Digital Wallet',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        );
    }
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
}

/// Compact payment method display widget for use in other screens
class CompactPaymentMethodCard extends StatelessWidget {
  final CustomerPaymentMethod paymentMethod;
  final VoidCallback? onTap;
  final bool showDefaultBadge;

  const CompactPaymentMethodCard({
    super.key,
    required this.paymentMethod,
    this.onTap,
    this.showDefaultBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildCompactIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            paymentMethod.displayName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        if (showDefaultBadge && paymentMethod.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'DEFAULT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (paymentMethod.type == CustomerPaymentMethodType.card &&
                        paymentMethod.formattedExpiry != null)
                      Text(
                        'Expires ${paymentMethod.formattedExpiry}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: paymentMethod.isExpired ? Colors.red : Colors.grey[600],
                              fontSize: 11,
                            ),
                      ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactIcon() {
    IconData iconData;
    Color iconColor = AppTheme.primaryColor;

    switch (paymentMethod.type) {
      case CustomerPaymentMethodType.card:
        iconData = Icons.credit_card;
        break;
      case CustomerPaymentMethodType.bankAccount:
        iconData = Icons.account_balance;
        break;
      case CustomerPaymentMethodType.digitalWallet:
        iconData = Icons.account_balance_wallet;
        break;
    }

    return Icon(
      iconData,
      color: iconColor,
      size: 20,
    );
  }
}
