import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/wallet_transactions_provider.dart';
import '../providers/wallet_state_provider.dart';
import '../widgets/recent_transactions_widget.dart';
import '../../data/models/wallet_transaction.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  WalletTransactionType? _selectedFilter;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final transactionActions = ref.read(transactionActionsProvider);
      final walletState = ref.read(currentUserWalletProvider);
      
      if (walletState.wallet != null) {
        transactionActions.loadMoreTransactions(walletState.wallet!.id);
      }
    }
  }

  Future<void> _refreshTransactions() async {
    final transactionActions = ref.read(transactionActionsProvider);
    final walletState = ref.read(currentUserWalletProvider);
    
    if (walletState.wallet != null) {
      await transactionActions.refreshTransactions(walletState.wallet!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionState = ref.watch(currentUserTransactionHistoryProvider);
    final transactionSummary = ref.watch(transactionSummaryProvider(
      ref.watch(currentUserWalletProvider).wallet?.id ?? ''
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTransactions,
        child: Column(
          children: [
            // Summary Card
            if (transactionState.hasTransactions) ...[
              _buildSummaryCard(context, transactionSummary),
              const SizedBox(height: 8),
            ],

            // Filter Chips
            if (_hasActiveFilters()) ...[
              _buildFilterChips(context),
              const SizedBox(height: 8),
            ],

            // Transaction List
            Expanded(
              child: _buildTransactionList(context, transactionState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, TransactionSummary summary) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Transaction Summary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  context,
                  'Total Credits',
                  summary.formattedTotalCredits,
                  Icons.add_circle,
                  AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  context,
                  'Total Debits',
                  summary.formattedTotalDebits,
                  Icons.remove_circle,
                  AppTheme.errorColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Net Amount',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  summary.formattedNetAmount,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: summary.netAmount >= 0 
                        ? AppTheme.successColor 
                        : AppTheme.errorColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (_selectedFilter != null)
            FilterChip(
              label: Text(_selectedFilter!.displayName),
              selected: true,
              onSelected: (_) => _clearTypeFilter(),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: _clearTypeFilter,
            ),
          if (_startDate != null || _endDate != null) ...[
            const SizedBox(width: 8),
            FilterChip(
              label: Text(_getDateRangeText()),
              selected: true,
              onSelected: (_) => _clearDateFilter(),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: _clearDateFilter,
            ),
          ],
          const SizedBox(width: 8),
          ActionChip(
            label: const Text('Clear All'),
            onPressed: _clearAllFilters,
            backgroundColor: theme.colorScheme.errorContainer,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(BuildContext context, TransactionHistoryState state) {
    if (state.isLoading && state.transactions.isEmpty) {
      return const Center(child: LoadingWidget());
    }

    if (state.errorMessage != null && state.transactions.isEmpty) {
      return _buildErrorState(context, state.errorMessage!);
    }

    if (state.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.transactions.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.transactions.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final transaction = state.transactions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TransactionTile(
            transaction: transaction,
            onTap: () => context.push('/wallet/transactions/${transaction.id}'),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load transactions',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshTransactions,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _hasActiveFilters() ? 'No transactions found' : 'No transactions yet',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _hasActiveFilters() 
                  ? 'Try adjusting your filters to see more results'
                  : 'Your transaction history will appear here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            if (_hasActiveFilters()) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _clearAllFilters,
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TransactionFilterDialog(
        selectedType: _selectedFilter,
        startDate: _startDate,
        endDate: _endDate,
        onApplyFilters: _applyFilters,
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    // TODO: Implement search functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search functionality coming soon')),
    );
  }

  void _applyFilters({
    WalletTransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    setState(() {
      _selectedFilter = type;
      _startDate = startDate;
      _endDate = endDate;
    });

    final transactionActions = ref.read(transactionActionsProvider);
    final walletState = ref.read(currentUserWalletProvider);
    
    if (walletState.wallet != null) {
      transactionActions.applyFilters(
        walletState.wallet!.id,
        type: type,
        startDate: startDate,
        endDate: endDate,
      );
    }
  }

  void _clearTypeFilter() {
    _applyFilters(
      type: null,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  void _clearDateFilter() {
    _applyFilters(
      type: _selectedFilter,
      startDate: null,
      endDate: null,
    );
  }

  void _clearAllFilters() {
    _applyFilters(
      type: null,
      startDate: null,
      endDate: null,
    );
  }

  bool _hasActiveFilters() {
    return _selectedFilter != null || _startDate != null || _endDate != null;
  }

  String _getDateRangeText() {
    if (_startDate != null && _endDate != null) {
      return '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}';
    } else if (_startDate != null) {
      return 'From ${_formatDate(_startDate!)}';
    } else if (_endDate != null) {
      return 'Until ${_formatDate(_endDate!)}';
    }
    return 'Date Range';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Transaction filter dialog widget
class TransactionFilterDialog extends StatefulWidget {
  final WalletTransactionType? selectedType;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function({
    WalletTransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) onApplyFilters;

  const TransactionFilterDialog({
    super.key,
    this.selectedType,
    this.startDate,
    this.endDate,
    required this.onApplyFilters,
  });

  @override
  State<TransactionFilterDialog> createState() => _TransactionFilterDialogState();
}

class _TransactionFilterDialogState extends State<TransactionFilterDialog> {
  WalletTransactionType? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Transactions',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Transaction Type Filter
          Text(
            'Transaction Type',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedType == null,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedType = null);
                  }
                },
              ),
              ...WalletTransactionType.values.map((type) => FilterChip(
                label: Text(type.displayName),
                selected: _selectedType == type,
                onSelected: (selected) {
                  setState(() => _selectedType = selected ? type : null);
                },
              )),
            ],
          ),
          const SizedBox(height: 24),

          // Date Range Filter
          Text(
            'Date Range',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectStartDate(context),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_startDate != null
                    ? _formatDate(_startDate!)
                    : 'Start Date'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectEndDate(context),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_endDate != null
                    ? _formatDate(_endDate!)
                    : 'End Date'),
                ),
              ),
            ],
          ),
          if (_startDate != null || _endDate != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
              },
              child: const Text('Clear Date Range'),
            ),
          ],
          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedType = null;
                      _startDate = null;
                      _endDate = null;
                    });
                  },
                  child: const Text('Clear All'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApplyFilters(
                      type: _selectedType,
                      startDate: _startDate,
                      endDate: _endDate,
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
