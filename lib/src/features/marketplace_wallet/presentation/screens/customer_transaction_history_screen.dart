import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/customer_transaction_management_provider.dart';
import '../widgets/transaction_filter_bottom_sheet.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/transaction_search_bar.dart';
import '../widgets/transaction_stats_card.dart';
import '../widgets/transaction_export_dialog.dart';
import '../../data/models/customer_wallet.dart';

/// Customer transaction history screen with advanced filtering and search
class CustomerTransactionHistoryScreen extends ConsumerStatefulWidget {
  const CustomerTransactionHistoryScreen({super.key});

  @override
  ConsumerState<CustomerTransactionHistoryScreen> createState() => _CustomerTransactionHistoryScreenState();
}

class _CustomerTransactionHistoryScreenState extends ConsumerState<CustomerTransactionHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Load transactions when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerTransactionManagementProvider.notifier).loadTransactions(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(customerTransactionManagementProvider.notifier).loadMoreTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(customerTransactionManagementProvider);
    final stats = ref.watch(customerTransactionStatsProvider);

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: RefreshIndicator(
        onRefresh: () => ref.read(customerTransactionManagementProvider.notifier).refresh(),
        child: Column(
          children: [
            // Search and filter section
            _buildSearchAndFilterSection(theme, state),
            
            // Statistics card
            if (state.transactions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: TransactionStatsCard(stats: stats),
              ),
            ],
            
            // Transaction list
            Expanded(
              child: _buildTransactionList(theme, state),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(theme, state),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    final state = ref.watch(customerTransactionManagementProvider);
    
    return AppBar(
      title: const Text('Transaction History'),
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      actions: [
        // Filter indicator
        if (state.filter.hasActiveFilters)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Filtered',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        
        // More options menu
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 8),
                  Text('Export'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear_filters',
              child: Row(
                children: [
                  Icon(Icons.clear_all),
                  SizedBox(width: 8),
                  Text('Clear Filters'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('Refresh'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterSection(ThemeData theme, CustomerTransactionManagementState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Search bar
          TransactionSearchBar(
            controller: _searchController,
            onSearch: (query) {
              ref.read(customerTransactionManagementProvider.notifier).searchTransactions(query);
            },
            onClear: () {
              _searchController.clear();
              ref.read(customerTransactionManagementProvider.notifier).searchTransactions('');
            },
          ),
          
          const SizedBox(height: 12),
          
          // Quick filter chips
          _buildQuickFilterChips(theme, state),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChips(ThemeData theme, CustomerTransactionManagementState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Filter button
          FilterChip(
            label: const Text('Filters'),
            avatar: const Icon(Icons.tune, size: 18),
            selected: state.filter.hasActiveFilters,
            onSelected: (_) => _showFilterBottomSheet(),
            selectedColor: theme.colorScheme.primaryContainer,
          ),
          
          const SizedBox(width: 8),
          
          // Transaction type filters
          ...CustomerTransactionType.values.map((type) {
            final isSelected = state.filter.type == type;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(type.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  ref.read(customerTransactionManagementProvider.notifier)
                      .filterByType(selected ? type : null);
                },
                selectedColor: theme.colorScheme.primaryContainer,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTransactionList(ThemeData theme, CustomerTransactionManagementState state) {
    if (state.isLoading && state.transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError && state.transactions.isEmpty) {
      return _buildErrorState(theme, state.errorMessage!);
    }

    if (state.isEmpty) {
      return _buildEmptyState(theme);
    }

    final transactionsByDate = state.transactionsByDate;
    final sortedDates = transactionsByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Most recent first

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB
      itemCount: sortedDates.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= sortedDates.length) {
          // Loading more indicator
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final date = sortedDates[index];
        final transactions = transactionsByDate[date]!;

        return _buildDateSection(theme, date, transactions);
      },
    );
  }

  Widget _buildDateSection(ThemeData theme, DateTime date, List<CustomerWalletTransaction> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Text(
            _formatDate(date),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        
        // Transactions for this date
        ...transactions.map((transaction) => TransactionListItem(
          transaction: transaction,
          onTap: () => _showTransactionDetails(transaction),
        )),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Transactions Found',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your transaction history will appear here once you start using your wallet.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Transactions',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(customerTransactionManagementProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton(ThemeData theme, CustomerTransactionManagementState state) {
    if (state.transactions.isEmpty) return null;

    return FloatingActionButton.extended(
      onPressed: _showExportDialog,
      icon: const Icon(Icons.download),
      label: const Text('Export'),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _showExportDialog();
        break;
      case 'clear_filters':
        ref.read(customerTransactionManagementProvider.notifier).clearFilters();
        break;
      case 'refresh':
        ref.read(customerTransactionManagementProvider.notifier).refresh();
        break;
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TransactionFilterBottomSheet(
        currentFilter: ref.read(customerTransactionManagementProvider).filter,
        onApplyFilter: (filter) {
          ref.read(customerTransactionManagementProvider.notifier).applyFilter(filter);
        },
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => TransactionExportDialog(
        onExport: () async {
          final csvData = await ref.read(customerTransactionManagementProvider.notifier).exportTransactions();
          if (csvData != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Transactions exported successfully')),
            );
          }
        },
      ),
    );
  }

  void _showTransactionDetails(CustomerWalletTransaction transaction) {
    // Navigate to transaction details screen
    context.push('/wallet/transaction/${transaction.id}');
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'Today';
    } else if (date == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
