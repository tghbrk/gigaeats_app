import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/customer_transaction_management_provider.dart';
import '../../data/models/customer_wallet.dart';

/// Recent transactions preview widget
class RecentTransactionsPreview extends ConsumerStatefulWidget {
  final VoidCallback? onViewAllPressed;
  final Function(String)? onTransactionPressed;
  final int limit;

  const RecentTransactionsPreview({
    super.key,
    this.onViewAllPressed,
    this.onTransactionPressed,
    this.limit = 5,
  });

  @override
  ConsumerState<RecentTransactionsPreview> createState() => _RecentTransactionsPreviewState();
}

class _RecentTransactionsPreviewState extends ConsumerState<RecentTransactionsPreview> {
  bool _hasInitialized = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionState = ref.watch(customerTransactionManagementProvider);

    // Initialize transactions loading on first build
    if (!_hasInitialized && !transactionState.isLoading && transactionState.transactions.isEmpty) {
      debugPrint('🔍 [RECENT-TRANSACTIONS-PREVIEW] Initializing transaction loading');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(customerTransactionManagementProvider.notifier).loadTransactions(refresh: true);
      });
      _hasInitialized = true;
    }

    debugPrint('🔍 [RECENT-TRANSACTIONS-PREVIEW] Building with ${transactionState.transactions.length} transactions');
    final topUpCount = transactionState.transactions.where((t) => t.type == CustomerTransactionType.topUp).length;
    debugPrint('🔍 [RECENT-TRANSACTIONS-PREVIEW] Top-up transactions available: $topUpCount');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.onViewAllPressed != null)
                  TextButton(
                    onPressed: widget.onViewAllPressed,
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (transactionState.isLoading)
              _buildLoadingState(theme)
            else if (transactionState.hasError)
              _buildErrorState(theme, transactionState.errorMessage!)
            else if (transactionState.isEmpty)
              _buildEmptyState(theme)
            else
              _buildTransactionsList(theme, transactionState.transactions.take(widget.limit).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Column(
      children: List.generate(3, (index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 60,
              height: 16,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Error loading transactions: $error',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No Transactions Yet',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your transaction history will appear here',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(ThemeData theme, List<CustomerWalletTransaction> transactions) {
    debugPrint('🔍 [RECENT-TRANSACTIONS-PREVIEW] Building list with ${transactions.length} transactions');
    final topUpCount = transactions.where((t) => t.type == CustomerTransactionType.topUp).length;
    debugPrint('🔍 [RECENT-TRANSACTIONS-PREVIEW] Top-up transactions in list: $topUpCount');

    return Column(
      children: transactions.map((transaction) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: _buildTransactionItem(theme, transaction),
      )).toList(),
    );
  }

  Widget _buildTransactionItem(ThemeData theme, CustomerWalletTransaction transaction) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onTransactionPressed?.call(transaction.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Transaction icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getTransactionColor(theme, transaction).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getTransactionIcon(transaction),
                  color: _getTransactionColor(theme, transaction),
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Transaction details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.type.displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTimestamp(transaction.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatAmount(transaction),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: transaction.isCredit 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _buildStatusChip(theme, transaction),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme, CustomerWalletTransaction transaction) {
    // For CustomerWalletTransaction, we assume completed status
    // since these are historical transactions that have been processed
    Color statusColor = theme.colorScheme.primary;
    String statusText = 'Completed';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        statusText,
        style: theme.textTheme.bodySmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w500,
          fontSize: 10,
        ),
      ),
    );
  }

  IconData _getTransactionIcon(CustomerWalletTransaction transaction) {
    switch (transaction.type) {
      case CustomerTransactionType.topUp:
        return Icons.add_circle;
      case CustomerTransactionType.orderPayment:
        return Icons.shopping_cart;
      case CustomerTransactionType.refund:
        return Icons.undo;
      case CustomerTransactionType.transfer:
        return Icons.send;
      case CustomerTransactionType.adjustment:
        return Icons.tune;
    }
  }

  Color _getTransactionColor(ThemeData theme, CustomerWalletTransaction transaction) {
    switch (transaction.type) {
      case CustomerTransactionType.topUp:
        return theme.colorScheme.primary;
      case CustomerTransactionType.orderPayment:
        return theme.colorScheme.error;
      case CustomerTransactionType.refund:
        return theme.colorScheme.tertiary;
      case CustomerTransactionType.transfer:
        return theme.colorScheme.secondary;
      case CustomerTransactionType.adjustment:
        return Colors.orange;
    }
  }

  String _formatAmount(CustomerWalletTransaction transaction) {
    final prefix = transaction.isCredit ? '+' : '-';
    return '$prefix${transaction.formattedAmount}';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }


}
