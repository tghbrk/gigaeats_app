import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/customer_wallet.dart';
import '../providers/customer_wallet_provider.dart';
import '../widgets/customer_wallet_transaction_history_widget.dart';

/// Full-screen transaction history with advanced filtering and search
class CustomerWalletTransactionHistoryScreen extends ConsumerStatefulWidget {
  const CustomerWalletTransactionHistoryScreen({super.key});

  @override
  ConsumerState<CustomerWalletTransactionHistoryScreen> createState() =>
      _CustomerWalletTransactionHistoryScreenState();
}

class _CustomerWalletTransactionHistoryScreenState
    extends ConsumerState<CustomerWalletTransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  CustomerTransactionType? _selectedFilter;
  DateTimeRange? _selectedDateRange;
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionsState = ref.watch(customerWalletTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list : Icons.filter_list_outlined),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(customerWalletTransactionsProvider.notifier).refreshTransactions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          if (_showFilters) _buildFilterSection(context),

          // Transaction summary
          _buildTransactionSummary(context, transactionsState),

          // Transaction list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(customerWalletTransactionsProvider.notifier).refreshTransactions();
              },
              child: CustomerWalletTransactionHistoryWidget(
                showHeader: false,
                enablePagination: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    final theme = Theme.of(context);

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
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search transactions...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilters();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) => _applyFilters(),
          ),
          const SizedBox(height: 16),

          // Filter chips
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All Types'),
                        selected: _selectedFilter == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = selected ? null : _selectedFilter;
                          });
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 8),
                      ...CustomerTransactionType.values.map((type) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(type.displayName),
                          selected: _selectedFilter == type,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = selected ? type : null;
                            });
                            _applyFilters();
                          },
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Date range filter
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _selectedDateRange == null
                        ? 'Select Date Range'
                        : '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}',
                  ),
                ),
              ),
              if (_selectedDateRange != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedDateRange = null;
                    });
                    _applyFilters();
                  },
                  icon: const Icon(Icons.clear),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionSummary(BuildContext context, CustomerWalletTransactionsState state) {
    final theme = Theme.of(context);

    if (state.transactions.isEmpty) return const SizedBox.shrink();

    final totalCredits = state.transactions
        .where((t) => t.isCredit)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalDebits = state.transactions
        .where((t) => t.isDebit)
        .fold(0.0, (sum, t) => sum + t.amount.abs());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total In',
              'RM ${totalCredits.toStringAsFixed(2)}',
              Colors.green,
              Icons.trending_up,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Total Out',
              'RM ${totalDebits.toStringAsFixed(2)}',
              Colors.red,
              Icons.trending_down,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Net Amount',
              'RM ${(totalCredits - totalDebits).toStringAsFixed(2)}',
              totalCredits >= totalDebits ? Colors.green : Colors.red,
              Icons.account_balance,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    // Apply search and filters
    ref.read(customerWalletTransactionsProvider.notifier).filterByType(_selectedFilter);
    
    if (_selectedDateRange != null) {
      ref.read(customerWalletTransactionsProvider.notifier).filterByDateRange(
        _selectedDateRange!.start,
        _selectedDateRange!.end,
      );
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
      _applyFilters();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
