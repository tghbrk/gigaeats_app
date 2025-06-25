import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/wallet_transactions_provider.dart';
import '../../data/models/wallet_transaction.dart';

class RecentTransactionsWidget extends ConsumerWidget {
  final int limit;
  final bool showHeader;

  const RecentTransactionsWidget({
    super.key,
    this.limit = 5,
    this.showHeader = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final transactionState = ref.watch(currentUserTransactionHistoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/wallet/transactions'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        if (transactionState.isLoading)
          const Center(child: LoadingWidget())
        else if (transactionState.errorMessage != null)
          _buildErrorState(context, transactionState.errorMessage!)
        else if (transactionState.isEmpty)
          _buildEmptyState(context)
        else
          _buildTransactionsList(context, transactionState.transactions.take(limit).toList()),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Failed to load transactions',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your transaction history will appear here',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(BuildContext context, List<WalletTransaction> transactions) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return TransactionTile(
          transaction: transaction,
          onTap: () => context.push('/wallet/transactions/${transaction.id}'),
        );
      },
    );
  }
}

class TransactionTile extends StatelessWidget {
  final WalletTransaction transaction;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Transaction Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getTransactionColor(transaction).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTransactionIcon(transaction),
                  color: _getTransactionColor(transaction),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Transaction Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.displayDescription,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          transaction.transactionType.displayName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(transaction.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount and Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${transaction.isCredit ? '+' : '-'}${transaction.formattedAmount}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: transaction.isCredit 
                          ? AppTheme.successColor 
                          : AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(transaction).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      transaction.status.displayName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(transaction),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTransactionIcon(WalletTransaction transaction) {
    switch (transaction.transactionType) {
      case WalletTransactionType.credit:
        return Icons.add_circle;
      case WalletTransactionType.debit:
        return Icons.remove_circle;
      case WalletTransactionType.commission:
        return Icons.monetization_on;
      case WalletTransactionType.payout:
        return Icons.account_balance;
      case WalletTransactionType.refund:
        return Icons.undo;
      case WalletTransactionType.adjustment:
        return Icons.tune;
      case WalletTransactionType.bonus:
        return Icons.card_giftcard;
    }
  }

  Color _getTransactionColor(WalletTransaction transaction) {
    switch (transaction.transactionType) {
      case WalletTransactionType.credit:
        return AppTheme.successColor;
      case WalletTransactionType.debit:
        return AppTheme.errorColor;
      case WalletTransactionType.commission:
        return AppTheme.warningColor;
      case WalletTransactionType.payout:
        return AppTheme.infoColor;
      case WalletTransactionType.refund:
        return AppTheme.primaryColor;
      case WalletTransactionType.adjustment:
        return Colors.grey;
      case WalletTransactionType.bonus:
        return Colors.purple;
    }
  }

  Color _getStatusColor(WalletTransaction transaction) {
    switch (transaction.status) {
      case TransactionStatus.completed:
        return AppTheme.successColor;
      case TransactionStatus.pending:
        return AppTheme.warningColor;
      case TransactionStatus.failed:
        return AppTheme.errorColor;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(date);
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }
}
