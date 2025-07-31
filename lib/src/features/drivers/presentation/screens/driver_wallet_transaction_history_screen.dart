import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/user_role.dart';
import '../../../../shared/widgets/auth_guard.dart';
import '../../data/models/driver_wallet_transaction.dart';
import '../providers/driver_wallet_transaction_provider.dart';
import '../widgets/wallet/driver_transaction_filter_bottom_sheet.dart';
import '../widgets/wallet/driver_transaction_search_bar.dart';
import '../widgets/wallet/driver_transaction_stats_card.dart';
import '../widgets/wallet/driver_transaction_list_item.dart';
import '../widgets/wallet/driver_transaction_export_dialog.dart';

/// Comprehensive driver wallet transaction history screen with filtering and search
class DriverWalletTransactionHistoryScreen extends ConsumerStatefulWidget {
  const DriverWalletTransactionHistoryScreen({super.key});

  @override
  ConsumerState<DriverWalletTransactionHistoryScreen> createState() => 
      _DriverWalletTransactionHistoryScreenState();
}

class _DriverWalletTransactionHistoryScreenState 
    extends ConsumerState<DriverWalletTransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize transaction loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(driverWalletTransactionProvider.notifier).loadTransactions();
    });

    // Setup infinite scroll
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(driverWalletTransactionProvider.notifier).loadMoreTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionState = ref.watch(driverWalletTransactionProvider);

    debugPrint('🏗️ [DRIVER-WALLET-TRANSACTION-HISTORY] Building screen');
    debugPrint('🏗️ [DRIVER-WALLET-TRANSACTION-HISTORY] Transaction count: ${transactionState.transactions.length}');
    debugPrint('🏗️ [DRIVER-WALLET-TRANSACTION-HISTORY] Loading state: ${transactionState.isLoading}');
    debugPrint('🏗️ [DRIVER-WALLET-TRANSACTION-HISTORY] Error: ${transactionState.errorMessage}');

    return AuthGuard(
      allowedRoles: const [UserRole.driver, UserRole.admin],
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: _buildAppBar(theme),
        body: RefreshIndicator(
          onRefresh: () => ref.read(driverWalletTransactionProvider.notifier).refreshTransactions(),
          child: Column(
            children: [
              // Search and filter section
              _buildSearchAndFilterSection(theme, transactionState),
              
              // Statistics card
              if (transactionState.transactions.isNotEmpty) ...[
                Builder(
                  builder: (context) {
                    debugPrint('📊 [DRIVER-WALLET-TRANSACTION-HISTORY] Rendering statistics card');
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: const DriverTransactionStatsCard(),
                    );
                  },
                ),
              ],
              
              // Transaction list
              Expanded(
                child: Builder(
                  builder: (context) {
                    debugPrint('📋 [DRIVER-WALLET-TRANSACTION-HISTORY] Rendering transaction list');
                    return _buildTransactionList(theme, transactionState);
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(theme, transactionState),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    debugPrint('🎨 [DRIVER-WALLET-TRANSACTION-HISTORY] Building AppBar with theme colors');
    debugPrint('🎨 [DRIVER-WALLET-TRANSACTION-HISTORY] Surface color: ${theme.colorScheme.surface}');
    debugPrint('🎨 [DRIVER-WALLET-TRANSACTION-HISTORY] OnSurface color: ${theme.colorScheme.onSurface}');

    return AppBar(
      title: const Text('Transaction History'),
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface, // Fix: Ensure text is visible on surface
      iconTheme: IconThemeData(color: theme.colorScheme.onSurface), // Fix: Ensure icons are visible
      actionsIconTheme: IconThemeData(color: theme.colorScheme.onSurface), // Fix: Ensure action icons are visible
      titleTextStyle: TextStyle(
        color: theme.colorScheme.onSurface, // Fix: Explicit title color
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      actions: [
        IconButton(
          onPressed: () => setState(() => _showFilters = !_showFilters),
          icon: Icon(
            _showFilters ? Icons.filter_list_off : Icons.filter_list,
          ),
          tooltip: _showFilters ? 'Hide Filters' : 'Show Filters',
        ),
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

  Widget _buildSearchAndFilterSection(ThemeData theme, DriverWalletTransactionState state) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _showFilters ? null : 0,
      child: Container(
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
            DriverTransactionSearchBar(
              controller: _searchController,
              onSearch: (query) {
                debugPrint('🔍 [DRIVER-TRANSACTION-HISTORY] Search query: $query');
                ref.read(driverWalletTransactionProvider.notifier).loadTransactions(
                  refresh: true,
                  searchQuery: query.isNotEmpty ? query : null,
                );
              },
              onClear: () {
                _searchController.clear();
                ref.read(driverWalletTransactionProvider.notifier).loadTransactions(refresh: true);
              },
            ),
            
            const SizedBox(height: 12),
            
            // Quick filter chips
            _buildQuickFilterChips(theme, state),
            
            const SizedBox(height: 12),
            
            // Advanced filter button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showFilterBottomSheet,
                icon: const Icon(Icons.tune),
                label: const Text('Advanced Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilterChips(ThemeData theme, DriverWalletTransactionState state) {
    final quickFilters = [
      {'label': 'All', 'type': null},
      {'label': 'Earnings', 'type': DriverWalletTransactionType.deliveryEarnings},
      {'label': 'Tips', 'type': DriverWalletTransactionType.tipPayment},
      {'label': 'Bonuses', 'type': DriverWalletTransactionType.completionBonus},
      {'label': 'Withdrawals', 'type': DriverWalletTransactionType.withdrawalRequest},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: quickFilters.map((filter) {
          final isSelected = state.filter.type == filter['type'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter['label'] as String),
              selected: isSelected,
              onSelected: (selected) {
                debugPrint('🔍 [DRIVER-TRANSACTION-HISTORY] Quick filter: ${filter['label']}');
                ref.read(driverWalletTransactionProvider.notifier).loadTransactions(
                  refresh: true,
                  type: selected ? filter['type'] as DriverWalletTransactionType? : null,
                );
              },
              selectedColor: theme.colorScheme.primaryContainer,
              checkmarkColor: theme.colorScheme.primary,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionList(ThemeData theme, DriverWalletTransactionState state) {
    if (state.isLoading && state.transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return Center(
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
              'Error loading transactions',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.read(driverWalletTransactionProvider.notifier).refreshTransactions(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.transactions.isEmpty) {
      return Center(
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
              'No transactions found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your wallet transactions will appear here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.transactions.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.transactions.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final transaction = state.transactions[index];
        return DriverTransactionListItem(
          transaction: transaction,
          onTap: () => _showTransactionDetails(transaction),
        );
      },
    );
  }

  Widget? _buildFloatingActionButton(ThemeData theme, DriverWalletTransactionState state) {
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
        ref.read(driverWalletTransactionProvider.notifier).clearFilter();
        _searchController.clear();
        break;
      case 'refresh':
        ref.read(driverWalletTransactionProvider.notifier).refreshTransactions();
        break;
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DriverTransactionFilterBottomSheet(
        currentFilter: ref.read(driverWalletTransactionProvider).filter,
        onApplyFilter: (filter) {
          debugPrint('🔍 [DRIVER-TRANSACTION-HISTORY] Applying filter: ${filter.toJson()}');
          ref.read(driverWalletTransactionProvider.notifier).applyFilter(filter);
        },
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => DriverTransactionExportDialog(
        onExport: (format, period) async {
          debugPrint('📤 [DRIVER-TRANSACTION-HISTORY] Exporting transactions');
          debugPrint('📤 [DRIVER-TRANSACTION-HISTORY] Format: $format, Period: $period');

          try {
            final transactionState = ref.read(driverWalletTransactionProvider);
            final transactions = transactionState.transactions;

            if (transactions.isEmpty) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No transactions to export'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              return;
            }

            // Filter transactions based on period
            final filteredTransactions = _filterTransactionsByPeriod(transactions, period);

            if (filteredTransactions.isEmpty) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No transactions found for selected period'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              return;
            }

            // Generate export data based on format
            final exportData = _generateExportData(filteredTransactions, format);

            debugPrint('📤 [DRIVER-TRANSACTION-HISTORY] Generated export data: ${exportData.length} characters');

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${filteredTransactions.length} transactions exported successfully'),
                  backgroundColor: Colors.green,
                  action: SnackBarAction(
                    label: 'View',
                    textColor: Colors.white,
                    onPressed: () {
                      _showExportPreview(exportData, format);
                    },
                  ),
                ),
              );
            }
          } catch (e) {
            debugPrint('❌ [DRIVER-TRANSACTION-HISTORY] Export error: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Export failed: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showTransactionDetails(DriverWalletTransaction transaction) {
    debugPrint('📋 [DRIVER-TRANSACTION-HISTORY] Showing details for transaction: ${transaction.id}');
    context.push('/driver/wallet/transaction/${transaction.id}');
  }

  /// Filter transactions based on selected time period
  List<DriverWalletTransaction> _filterTransactionsByPeriod(
    List<DriverWalletTransaction> transactions,
    String period,
  ) {
    final now = DateTime.now();
    DateTime? startDate;

    switch (period) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'last30':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 'last90':
        startDate = now.subtract(const Duration(days: 90));
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'all':
      default:
        return transactions; // Return all transactions
    }

    return transactions.where((transaction) {
      return transaction.createdAt.isAfter(startDate!);
    }).toList();
  }

  /// Generate export data in the specified format
  String _generateExportData(List<DriverWalletTransaction> transactions, String format) {
    switch (format) {
      case 'csv':
        return _generateCSVData(transactions);
      case 'json':
        return _generateJSONData(transactions);
      case 'pdf':
        return _generatePDFData(transactions);
      default:
        return _generateCSVData(transactions);
    }
  }

  /// Generate CSV format export data
  String _generateCSVData(List<DriverWalletTransaction> transactions) {
    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln('Date,Type,Description,Amount,Currency,Balance Before,Balance After,Processing Fee,Status,Reference ID');

    // CSV Data
    for (final transaction in transactions) {
      final status = transaction.processedAt != null ? 'Completed' : 'Pending';
      final description = transaction.description?.replaceAll(',', ';') ?? '';

      buffer.writeln([
        transaction.createdAt.toIso8601String().split('T')[0],
        transaction.transactionType.displayName,
        description,
        transaction.amount.toStringAsFixed(2),
        transaction.currency,
        transaction.balanceBefore.toStringAsFixed(2),
        transaction.balanceAfter.toStringAsFixed(2),
        transaction.processingFee.toStringAsFixed(2),
        status,
        transaction.referenceId ?? '',
      ].join(','));
    }

    return buffer.toString();
  }

  /// Generate JSON format export data
  String _generateJSONData(List<DriverWalletTransaction> transactions) {
    final exportData = {
      'export_date': DateTime.now().toIso8601String(),
      'total_transactions': transactions.length,
      'transactions': transactions.map((transaction) => {
        'id': transaction.id,
        'date': transaction.createdAt.toIso8601String(),
        'type': transaction.transactionType.displayName,
        'description': transaction.description,
        'amount': transaction.amount,
        'currency': transaction.currency,
        'balance_before': transaction.balanceBefore,
        'balance_after': transaction.balanceAfter,
        'processing_fee': transaction.processingFee,
        'status': transaction.processedAt != null ? 'Completed' : 'Pending',
        'reference_type': transaction.referenceType,
        'reference_id': transaction.referenceId,
        'metadata': transaction.metadata,
      }).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Generate PDF format export data (placeholder for actual PDF generation)
  String _generatePDFData(List<DriverWalletTransaction> transactions) {
    // For now, return a formatted text representation
    // In a real implementation, this would generate actual PDF content
    final buffer = StringBuffer();

    buffer.writeln('DRIVER WALLET TRANSACTION REPORT');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total Transactions: ${transactions.length}');
    buffer.writeln('=' * 50);
    buffer.writeln();

    for (final transaction in transactions) {
      buffer.writeln('Transaction ID: ${transaction.id}');
      buffer.writeln('Date: ${transaction.createdAt.toIso8601String().split('T')[0]}');
      buffer.writeln('Type: ${transaction.transactionType.displayName}');
      buffer.writeln('Amount: ${transaction.formattedAmount}');
      buffer.writeln('Description: ${transaction.description ?? 'N/A'}');
      buffer.writeln('Status: ${transaction.processedAt != null ? 'Completed' : 'Pending'}');
      if (transaction.referenceId != null) {
        buffer.writeln('Reference: ${transaction.referenceId}');
      }
      buffer.writeln('-' * 30);
    }

    return buffer.toString();
  }

  /// Show export preview dialog
  void _showExportPreview(String exportData, String format) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export Preview ($format)'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              exportData,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Copy to clipboard
              Clipboard.setData(ClipboardData(text: exportData));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export data copied to clipboard'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}
