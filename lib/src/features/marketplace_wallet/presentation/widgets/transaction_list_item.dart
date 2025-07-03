import 'package:flutter/material.dart';

import '../../data/models/customer_wallet.dart';

/// Transaction list item widget for displaying individual transactions
class TransactionListItem extends StatelessWidget {
  final CustomerWalletTransaction transaction;
  final VoidCallback? onTap;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Transaction icon
              _buildTransactionIcon(theme),
              
              const SizedBox(width: 12),
              
              // Transaction details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Transaction type and description
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            transaction.type.displayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Transaction amount
                        Text(
                          _formatAmount(),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: transaction.isCredit 
                                ? theme.colorScheme.primary
                                : theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Description and reference
                    if (transaction.description != null) ...[
                      Text(
                        transaction.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                    ],
                    
                    // Reference ID and timestamp
                    Row(
                      children: [
                        if (transaction.referenceId != null) ...[
                          Icon(
                            Icons.tag,
                            size: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            transaction.referenceId!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        
                        Expanded(
                          child: Text(
                            _formatTimestamp(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Chevron icon
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionIcon(ThemeData theme) {
    IconData iconData;
    Color backgroundColor;
    Color iconColor;

    switch (transaction.type) {
      case CustomerTransactionType.topUp:
        iconData = Icons.add_circle;
        backgroundColor = theme.colorScheme.primaryContainer;
        iconColor = theme.colorScheme.primary;
        break;
      case CustomerTransactionType.orderPayment:
        iconData = Icons.shopping_cart;
        backgroundColor = theme.colorScheme.errorContainer;
        iconColor = theme.colorScheme.error;
        break;
      case CustomerTransactionType.refund:
        iconData = Icons.undo;
        backgroundColor = theme.colorScheme.primaryContainer;
        iconColor = theme.colorScheme.primary;
        break;
      case CustomerTransactionType.transfer:
        iconData = Icons.send;
        backgroundColor = theme.colorScheme.tertiaryContainer;
        iconColor = theme.colorScheme.tertiary;
        break;
      case CustomerTransactionType.adjustment:
        iconData = Icons.tune;
        backgroundColor = theme.colorScheme.secondaryContainer;
        iconColor = theme.colorScheme.secondary;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  String _formatAmount() {
    final prefix = transaction.isCredit ? '+' : '-';
    return '$prefix${transaction.formattedAmount}';
  }

  String _formatTimestamp() {
    final now = DateTime.now();
    final difference = now.difference(transaction.createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      final date = transaction.createdAt;
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
