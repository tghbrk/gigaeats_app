import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/user_role.dart';
import '../../../../shared/widgets/auth_guard.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/custom_error_widget.dart';
import '../providers/driver_withdrawal_provider.dart';
import '../providers/driver_wallet_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/withdrawal/withdrawal_history_filter_bottom_sheet.dart';
import '../widgets/withdrawal/withdrawal_history_search_bar.dart';
import '../widgets/withdrawal/withdrawal_history_stats_card.dart';
import '../widgets/withdrawal/withdrawal_history_list_item.dart';
import '../widgets/withdrawal/withdrawal_status_filter_chips.dart';
import '../../data/models/driver_withdrawal_request.dart';

/// Screen for viewing driver withdrawal history with status tracking
class DriverWithdrawalHistoryScreen extends ConsumerStatefulWidget {
  const DriverWithdrawalHistoryScreen({super.key});

  @override
  ConsumerState<DriverWithdrawalHistoryScreen> createState() => _DriverWithdrawalHistoryScreenState();
}

class _DriverWithdrawalHistoryScreenState extends ConsumerState<DriverWithdrawalHistoryScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  
  // Filter state
  DriverWithdrawalStatus? _selectedStatus;
  String? _selectedMethod;
  DateTimeRange? _selectedDateRange;
  double? _minAmount;
  double? _maxAmount;

  @override
  void initState() {
    super.initState();

    // Load withdrawal requests on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWithdrawalRequests();
      _setupRealtimeSubscription();
    });

    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  void _setupRealtimeSubscription() {
    // Get current user ID and setup real-time subscription
    final authState = ref.read(authStateProvider);
    if (authState.user?.id != null) {
      ref.read(driverWithdrawalProvider.notifier).setupRealtimeSubscription(authState.user!.id);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      // Load more when 80% scrolled
      _loadMoreWithdrawalRequests();
    }
  }

  void _loadWithdrawalRequests({bool refresh = false}) {
    debugPrint('🔍 [WITHDRAWAL-HISTORY] Loading withdrawal requests (refresh: $refresh)');
    
    final filters = <String, dynamic>{};
    
    if (_selectedStatus != null) {
      filters['status'] = _selectedStatus!.name;
    }
    
    if (_selectedMethod != null && _selectedMethod!.isNotEmpty) {
      filters['method'] = _selectedMethod;
    }
    
    if (_selectedDateRange != null) {
      filters['start_date'] = _selectedDateRange!.start.toIso8601String();
      filters['end_date'] = _selectedDateRange!.end.toIso8601String();
    }
    
    if (_minAmount != null) {
      filters['min_amount'] = _minAmount;
    }
    
    if (_maxAmount != null) {
      filters['max_amount'] = _maxAmount;
    }

    final searchQuery = _searchController.text.trim();
    if (searchQuery.isNotEmpty) {
      filters['search'] = searchQuery;
    }

    ref.read(driverWithdrawalProvider.notifier).loadWithdrawalRequests(
      filters: filters,
      pagination: {'page': 1, 'limit': 20},
    );
  }

  void _loadMoreWithdrawalRequests() {
    // TODO: Implement pagination for more requests
    debugPrint('🔍 [WITHDRAWAL-HISTORY] Loading more withdrawal requests');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final withdrawalState = ref.watch(driverWithdrawalProvider);

    return AuthGuard(
      allowedRoles: const [UserRole.driver, UserRole.admin],
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: _buildAppBar(theme),
        body: RefreshIndicator(
          onRefresh: () async => _loadWithdrawalRequests(refresh: true),
          child: Column(
            children: [
              // Search and filter section
              _buildSearchAndFilterSection(theme, withdrawalState),
              
              // Status filter chips
              if (_hasActiveFilters()) ...[
                _buildStatusFilterChips(theme),
                const SizedBox(height: 8),
              ],
              
              // Statistics card
              if (withdrawalState.withdrawalRequests?.isNotEmpty == true) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: const WithdrawalHistoryStatsCard(),
                ),
              ],
              
              // Withdrawal requests list
              Expanded(
                child: _buildWithdrawalRequestsList(theme, withdrawalState),
              ),
            ],
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(theme),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: const Text('Withdrawal History'),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      actions: [
        IconButton(
          onPressed: () => _showFilterBottomSheet(context),
          icon: const Icon(Icons.filter_list),
          color: Colors.white,
          tooltip: 'Filter',
        ),
        IconButton(
          onPressed: () => _loadWithdrawalRequests(refresh: true),
          icon: const Icon(Icons.refresh),
          color: Colors.white,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterSection(ThemeData theme, DriverWithdrawalState state) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          WithdrawalHistorySearchBar(
            controller: _searchController,
            onSearch: (query) {
              debugPrint('🔍 [WITHDRAWAL-HISTORY] Search query: $query');
              _loadWithdrawalRequests();
            },
            onClear: () {
              _searchController.clear();
              _loadWithdrawalRequests();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChips(ThemeData theme) {
    return WithdrawalStatusFilterChips(
      selectedStatus: _selectedStatus,
      selectedMethod: _selectedMethod,
      selectedDateRange: _selectedDateRange,
      onStatusChanged: (status) {
        setState(() {
          _selectedStatus = status;
        });
        _loadWithdrawalRequests();
      },
      onMethodChanged: (method) {
        setState(() {
          _selectedMethod = method;
        });
        _loadWithdrawalRequests();
      },
      onDateRangeChanged: (dateRange) {
        setState(() {
          _selectedDateRange = dateRange;
        });
        _loadWithdrawalRequests();
      },
      onClearFilters: () {
        setState(() {
          _selectedStatus = null;
          _selectedMethod = null;
          _selectedDateRange = null;
          _minAmount = null;
          _maxAmount = null;
        });
        _loadWithdrawalRequests();
      },
    );
  }

  Widget _buildWithdrawalRequestsList(ThemeData theme, DriverWithdrawalState state) {
    if (state.isLoading && (state.withdrawalRequests?.isEmpty ?? true)) {
      return const LoadingWidget();
    }

    if (state.errorMessage != null) {
      return CustomErrorWidget(
        message: 'Failed to load withdrawal history: ${state.errorMessage}',
        onRetry: () => _loadWithdrawalRequests(refresh: true),
      );
    }

    if (state.withdrawalRequests?.isEmpty ?? true) {
      return _buildEmptyState(theme);
    }

    final requests = state.withdrawalRequests!;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return WithdrawalHistoryListItem(
          request: request,
          onTap: () => _showWithdrawalDetails(request),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final walletState = ref.watch(driverWalletProvider);
    final canWithdraw = walletState.wallet?.isActive == true &&
                       walletState.wallet?.isVerified == true;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No withdrawal requests found',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasActiveFilters()
                ? 'Try adjusting your filters or search terms'
                : 'Your withdrawal requests will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: canWithdraw ? () => context.push('/driver/wallet/withdraw') : null,
            icon: const Icon(Icons.add),
            label: const Text('Request Withdrawal'),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton(ThemeData theme) {
    final walletState = ref.watch(driverWalletProvider);
    final canWithdraw = walletState.wallet?.isActive == true &&
                       walletState.wallet?.isVerified == true;

    return FloatingActionButton.extended(
      onPressed: canWithdraw ? () => context.push('/driver/wallet/withdraw') : null,
      icon: const Icon(Icons.add),
      label: const Text('New Request'),
      backgroundColor: canWithdraw ? AppTheme.primaryColor : theme.disabledColor,
      foregroundColor: Colors.white,
    );
  }

  bool _hasActiveFilters() {
    return _selectedStatus != null ||
           (_selectedMethod != null && _selectedMethod!.isNotEmpty) ||
           _selectedDateRange != null ||
           _minAmount != null ||
           _maxAmount != null ||
           _searchController.text.trim().isNotEmpty;
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => WithdrawalHistoryFilterBottomSheet(
        selectedStatus: _selectedStatus,
        selectedMethod: _selectedMethod,
        selectedDateRange: _selectedDateRange,
        minAmount: _minAmount,
        maxAmount: _maxAmount,
        onApplyFilters: (status, method, dateRange, minAmount, maxAmount) {
          setState(() {
            _selectedStatus = status;
            _selectedMethod = method;
            _selectedDateRange = dateRange;
            _minAmount = minAmount;
            _maxAmount = maxAmount;
          });
          _loadWithdrawalRequests();
        },
      ),
    );
  }

  void _showWithdrawalDetails(DriverWithdrawalRequest request) {
    context.push('/driver/wallet/withdrawal/${request.id}');
  }
}
