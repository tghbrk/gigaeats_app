import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/loyalty_transaction.dart';

/// Loyalty transactions list widget
class LoyaltyTransactionsList extends StatelessWidget {
  final List<LoyaltyTransaction> transactions;
  final VoidCallback? onLoadMore;
  final bool showLoadMore;

  const LoyaltyTransactionsList({
    super.key,
    required this.transactions,
    this.onLoadMore,
    this.showLoadMore = true,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return _buildEmptyState(context);
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          ...transactions.map((transaction) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildTransactionItem(context, transaction),
          )),
          if (showLoadMore && onLoadMore != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton.icon(
                onPressed: onLoadMore,
                icon: const Icon(Icons.refresh),
                label: const Text('Load More'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Transactions Yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your loyalty transactions will appear here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, LoyaltyTransaction transaction) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getTransactionTypeColor(transaction.transactionType).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getTransactionTypeIcon(transaction.transactionType),
                color: _getTransactionTypeColor(transaction.transactionType),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.typeDisplayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _formatDate(transaction.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      if (transaction.hasExpiration && !transaction.isExpired) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            transaction.formattedExpiration ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.warningColor,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction.formattedPointsAmount,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: transaction.isPositive 
                        ? AppTheme.successColor 
                        : AppTheme.errorColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Balance: ${transaction.pointsBalanceAfter}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTransactionTypeColor(LoyaltyTransactionType type) {
    switch (type) {
      case LoyaltyTransactionType.earned:
        return AppTheme.successColor;
      case LoyaltyTransactionType.redeemed:
        return AppTheme.primaryColor;
      case LoyaltyTransactionType.expired:
        return AppTheme.errorColor;
      case LoyaltyTransactionType.bonus:
        return AppTheme.warningColor;
      case LoyaltyTransactionType.cashback:
        return AppTheme.infoColor;
      case LoyaltyTransactionType.referral:
        return Colors.purple;
      case LoyaltyTransactionType.adjustment:
        return Colors.orange;
      case LoyaltyTransactionType.promotion:
        return Colors.pink;
    }
  }

  IconData _getTransactionTypeIcon(LoyaltyTransactionType type) {
    switch (type) {
      case LoyaltyTransactionType.earned:
        return Icons.add_circle;
      case LoyaltyTransactionType.redeemed:
        return Icons.redeem;
      case LoyaltyTransactionType.expired:
        return Icons.schedule;
      case LoyaltyTransactionType.bonus:
        return Icons.star;
      case LoyaltyTransactionType.cashback:
        return Icons.account_balance_wallet;
      case LoyaltyTransactionType.referral:
        return Icons.people;
      case LoyaltyTransactionType.adjustment:
        return Icons.tune;
      case LoyaltyTransactionType.promotion:
        return Icons.local_offer;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
