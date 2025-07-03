import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/customer_wallet.dart';
import '../../data/models/customer_wallet_error.dart';
import '../providers/customer_wallet_provider.dart';
import 'customer_wallet_error_widget.dart';

/// Widget to display customer wallet transaction history with pagination and filtering
class CustomerWalletTransactionHistoryWidget extends ConsumerStatefulWidget {
  final bool showHeader;
  final int maxItems;
  final bool enablePagination;
  final VoidCallback? onViewAll;

  const CustomerWalletTransactionHistoryWidget({
    super.key,
    this.showHeader = true,
    this.maxItems = 5,
    this.enablePagination = false,
    this.onViewAll,
  });

  @override
  ConsumerState<CustomerWalletTransactionHistoryWidget> createState() =>
      _CustomerWalletTransactionHistoryWidgetState();
}

class _CustomerWalletTransactionHistoryWidgetState
    extends ConsumerState<CustomerWalletTransactionHistoryWidget> {
  final ScrollController _scrollController = ScrollController();
  CustomerTransactionType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    
    // Load initial transactions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerWalletTransactionsProvider.notifier).loadTransactions(refresh: true);
    });

    // Setup pagination scroll listener
    if (widget.enablePagination) {
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(customerWalletTransactionsProvider.notifier).loadMoreTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionsState = ref.watch(customerWalletTransactionsProvider);

    // For paginated view (full-screen), use Column with Expanded
    if (widget.enablePagination) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with filter options
          if (widget.showHeader) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.onViewAll != null)
                  TextButton(
                    onPressed: widget.onViewAll,
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedFilter == null,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = null);
                        _applyFilter(null);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ...CustomerTransactionType.values.map((type) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(type.displayName),
                      selected: _selectedFilter == type,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = selected ? type : null);
                        _applyFilter(selected ? type : null);
                      },
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Transaction list - Expanded to fill available space
          Expanded(
            child: _buildTransactionContent(context, transactionsState),
          ),
        ],
      );
    }

    // For non-paginated view (embedded), use Column with shrinkWrap
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        if (widget.showHeader) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.onViewAll != null)
                TextButton(
                  onPressed: widget.onViewAll,
                  child: const Text('View All'),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Transaction content
        _buildTransactionContent(context, transactionsState),
      ],
    );
  }

  Widget _buildTransactionContent(BuildContext context, CustomerWalletTransactionsState transactionsState) {
    if (transactionsState.isLoading && transactionsState.transactions.isEmpty) {
      return const CustomerWalletLoadingWidget(message: 'Loading transactions...');
    } else if (transactionsState.errorMessage != null && transactionsState.transactions.isEmpty) {
      return CustomerWalletErrorBanner(
        error: CustomerWalletError.fromMessage(transactionsState.errorMessage!),
        onRetry: () => ref.read(customerWalletTransactionsProvider.notifier).refreshTransactions(),
      );
    } else if (transactionsState.transactions.isEmpty) {
      return _buildEmptyState(context);
    } else {
      return _buildTransactionsList(context, transactionsState);
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 32,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == null
                  ? 'Your transaction history will appear here'
                  : 'No ${_selectedFilter!.displayName.toLowerCase()} transactions found',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(BuildContext context, CustomerWalletTransactionsState state) {
    final displayTransactions = widget.enablePagination
        ? state.transactions
        : state.transactions.take(widget.maxItems).toList();

    // For paginated view, use a scrollable list that fills available space
    if (widget.enablePagination) {
      return CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < displayTransactions.length) {
                  final transaction = displayTransactions[index];
                  return Column(
                    children: [
                      CustomerWalletTransactionTile(transaction: transaction),
                      if (index < displayTransactions.length - 1)
                        const Divider(height: 1),
                    ],
                  );
                }
                return null;
              },
              childCount: displayTransactions.length,
            ),
          ),

          // Load more indicator
          if (state.isLoading && state.transactions.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

          // Error banner for pagination errors
          if (state.errorMessage != null && state.transactions.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: CustomerWalletErrorBanner(
                  error: CustomerWalletError.fromMessage(state.errorMessage!),
                  onRetry: () => ref.read(customerWalletTransactionsProvider.notifier).loadMoreTransactions(),
                ),
              ),
            ),
        ],
      );
    }

    // For non-paginated view, use a constrained column
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Transaction list with proper constraints
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.4, // Limit height to 40% of screen
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayTransactions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final transaction = displayTransactions[index];
              return CustomerWalletTransactionTile(transaction: transaction);
            },
          ),
        ),

        // Show more button for non-paginated view
        if (state.transactions.length > widget.maxItems)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TextButton(
              onPressed: widget.onViewAll,
              child: Text('View ${state.transactions.length - widget.maxItems} more transactions'),
            ),
          ),
      ],
    );
  }

  void _applyFilter(CustomerTransactionType? type) {
    ref.read(customerWalletTransactionsProvider.notifier).filterByType(type);
  }
}

/// Individual transaction tile widget
class CustomerWalletTransactionTile extends StatelessWidget {
  final CustomerWalletTransaction transaction;

  const CustomerWalletTransactionTile({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getTransactionColor(transaction.type).withValues(alpha: 0.15),
          radius: 20,
          child: Icon(
            _getTransactionIcon(transaction.type),
            color: _getTransactionColor(transaction.type),
            size: 20,
          ),
        ),
        title: Text(
          transaction.description ?? transaction.type.displayName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy • HH:mm').format(transaction.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w400,
              ),
            ),
            if (transaction.referenceId != null) ...[
              const SizedBox(height: 2),
              Text(
                'Ref: ${transaction.referenceId}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontFamily: 'monospace',
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${transaction.isCredit ? '+' : '-'}${transaction.formattedAmount}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: transaction.isCredit
                    ? Colors.green.shade700
                    : Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              transaction.formattedBalanceAfter,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        onTap: () => _showTransactionDetails(context, transaction),
      ),
    );
  }

  IconData _getTransactionIcon(CustomerTransactionType type) {
    switch (type) {
      case CustomerTransactionType.topUp:
        return Icons.add_circle_outline;
      case CustomerTransactionType.orderPayment:
        return Icons.shopping_cart_outlined;
      case CustomerTransactionType.refund:
        return Icons.undo_outlined;
      case CustomerTransactionType.transfer:
        return Icons.send_outlined;
      case CustomerTransactionType.adjustment:
        return Icons.tune_outlined;
    }
  }

  Color _getTransactionColor(CustomerTransactionType type) {
    switch (type) {
      case CustomerTransactionType.topUp:
        return Colors.green;
      case CustomerTransactionType.orderPayment:
        return Colors.blue;
      case CustomerTransactionType.refund:
        return Colors.orange;
      case CustomerTransactionType.transfer:
        return Colors.purple;
      case CustomerTransactionType.adjustment:
        return Colors.grey;
    }
  }

  void _showTransactionDetails(BuildContext context, CustomerWalletTransaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CustomerWalletTransactionDetailsSheet(transaction: transaction),
    );
  }
}

/// Transaction details bottom sheet
class CustomerWalletTransactionDetailsSheet extends StatelessWidget {
  final CustomerWalletTransaction transaction;

  const CustomerWalletTransactionDetailsSheet({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Transaction Details',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildDetailRow('Type', transaction.type.displayName),
                    _buildDetailRow('Amount', transaction.formattedAmount),
                    _buildDetailRow('Balance After', transaction.formattedBalanceAfter),
                    _buildDetailRow('Date', DateFormat('MMMM dd, yyyy').format(transaction.createdAt)),
                    _buildDetailRow('Time', DateFormat('HH:mm:ss').format(transaction.createdAt)),
                    if (transaction.description != null)
                      _buildDetailRow('Description', transaction.description!),
                    if (transaction.referenceId != null)
                      _buildDetailRow('Reference ID', transaction.referenceId!),
                    _buildDetailRow('Transaction ID', transaction.id),
                    if (transaction.metadata != null && transaction.metadata!.isNotEmpty)
                      _buildMetadataSection(transaction.metadata!),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection(Map<String, dynamic> metadata) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Additional Details',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        ...metadata.entries.map((entry) => _buildDetailRow(
          entry.key.replaceAll('_', ' ').toUpperCase(),
          entry.value.toString(),
        )),
      ],
    );
  }
}
