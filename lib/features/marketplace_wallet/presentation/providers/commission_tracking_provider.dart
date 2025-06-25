import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/commission_breakdown.dart';
import '../../data/models/wallet_transaction.dart';
import '../../data/providers/marketplace_wallet_providers.dart';
import '../../data/repositories/marketplace_wallet_repository.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import 'wallet_state_provider.dart';

/// Commission tracking state for managing commission data
class CommissionTrackingState {
  final List<CommissionBreakdown> commissions;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? startDate;
  final DateTime? endDate;
  final CommissionType? filterType;
  final CommissionPeriod period;
  final CommissionSummary? summary;
  final DateTime? lastUpdated;

  const CommissionTrackingState({
    this.commissions = const [],
    this.isLoading = false,
    this.errorMessage,
    this.startDate,
    this.endDate,
    this.filterType,
    this.period = CommissionPeriod.thisMonth,
    this.summary,
    this.lastUpdated,
  });

  CommissionTrackingState copyWith({
    List<CommissionBreakdown>? commissions,
    bool? isLoading,
    String? errorMessage,
    DateTime? startDate,
    DateTime? endDate,
    CommissionType? filterType,
    CommissionPeriod? period,
    CommissionSummary? summary,
    DateTime? lastUpdated,
  }) {
    return CommissionTrackingState(
      commissions: commissions ?? this.commissions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      filterType: filterType ?? this.filterType,
      period: period ?? this.period,
      summary: summary ?? this.summary,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get isEmpty => commissions.isEmpty && !isLoading;
  bool get hasCommissions => commissions.isNotEmpty;
}

/// Commission tracking notifier for managing commission operations
class CommissionTrackingNotifier extends StateNotifier<CommissionTrackingState> {
  final MarketplaceWalletRepository _repository;
  final Ref _ref;
  final String _userRole;

  CommissionTrackingNotifier(
    this._repository,
    this._ref,
    this._userRole,
  ) : super(const CommissionTrackingState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    debugPrint('🔍 [COMMISSION] Initializing commission tracking for role: $_userRole');
    await loadCommissions();
  }

  /// Load commission data based on transactions
  Future<void> loadCommissions({bool forceRefresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Get wallet ID for current user
      final walletState = _ref.read(currentUserWalletProvider);
      final walletId = walletState.wallet?.id;

      if (walletId == null) {
        throw Exception('No wallet found for current user');
      }

      // Calculate date range based on period
      final dateRange = _calculateDateRange(state.period);
      
      // Get commission transactions
      final result = await _repository.getWalletTransactions(
        walletId: walletId,
        type: WalletTransactionType.commission,
        startDate: dateRange.start,
        endDate: dateRange.end,
        limit: 100, // Get more for commission analysis
      );

      result.fold(
        (failure) {
          debugPrint('🔍 [COMMISSION] Failed to load commission transactions: ${failure.message}');
          state = state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          );
        },
        (transactions) async {
          debugPrint('🔍 [COMMISSION] Loaded ${transactions.length} commission transactions');
          
          // Convert transactions to commission breakdowns
          final commissions = await _convertTransactionsToCommissions(transactions);
          
          // Calculate summary
          final summary = _calculateCommissionSummary(commissions, transactions);
          
          state = state.copyWith(
            commissions: commissions,
            summary: summary,
            isLoading: false,
            startDate: dateRange.start,
            endDate: dateRange.end,
            lastUpdated: DateTime.now(),
          );
        },
      );
    } catch (e) {
      debugPrint('🔍 [COMMISSION] Error loading commissions: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Change commission period
  Future<void> changePeriod(CommissionPeriod newPeriod) async {
    debugPrint('🔍 [COMMISSION] Changing period to: ${newPeriod.displayName}');
    
    state = state.copyWith(period: newPeriod);
    await loadCommissions(forceRefresh: true);
  }

  /// Apply custom date range
  Future<void> applyCustomDateRange(DateTime startDate, DateTime endDate) async {
    debugPrint('🔍 [COMMISSION] Applying custom date range: $startDate to $endDate');
    
    state = state.copyWith(
      period: CommissionPeriod.custom,
      startDate: startDate,
      endDate: endDate,
    );
    
    await loadCommissions(forceRefresh: true);
  }

  /// Apply commission type filter
  Future<void> applyTypeFilter(CommissionType? type) async {
    debugPrint('🔍 [COMMISSION] Applying type filter: $type');
    
    state = state.copyWith(filterType: type);
    
    // Filter existing commissions
    final filteredCommissions = type == null
        ? state.commissions
        : state.commissions.where((commission) {
            // Filter based on user role and commission type
            switch (type) {
              case CommissionType.vendor:
                return _userRole == 'vendor' && commission.vendorAmount > 0;
              case CommissionType.salesAgent:
                return _userRole == 'sales_agent' && commission.salesAgentCommission > 0;
              case CommissionType.driver:
                return _userRole == 'driver' && commission.driverCommission > 0;
              case CommissionType.platform:
                return _userRole == 'admin' && commission.platformFee > 0;
              case CommissionType.delivery:
                return commission.deliveryFee > 0;
            }
          }).toList();
    
    state = state.copyWith(commissions: filteredCommissions);
  }

  /// Refresh commission data
  Future<void> refresh() async {
    debugPrint('🔍 [COMMISSION] Refreshing commission data');
    await loadCommissions(forceRefresh: true);
  }

  /// Get commission breakdown for specific order
  Future<CommissionBreakdown?> getOrderCommissionBreakdown(String orderId) async {
    try {
      final result = await _repository.getCommissionBreakdown(orderId: orderId);
      return result.fold(
        (failure) {
          debugPrint('🔍 [COMMISSION] Failed to get order commission breakdown: ${failure.message}');
          return null;
        },
        (breakdown) => breakdown,
      );
    } catch (e) {
      debugPrint('🔍 [COMMISSION] Error getting order commission breakdown: $e');
      return null;
    }
  }

  /// Convert wallet transactions to commission breakdowns
  Future<List<CommissionBreakdown>> _convertTransactionsToCommissions(
    List<WalletTransaction> transactions,
  ) async {
    final commissions = <CommissionBreakdown>[];
    
    for (final transaction in transactions) {
      if (transaction.referenceType == 'escrow_release' && transaction.referenceId != null) {
        // Try to get commission breakdown from order
        final breakdown = await getOrderCommissionBreakdown(transaction.referenceId!);
        if (breakdown != null) {
          commissions.add(breakdown);
        } else {
          // Create basic breakdown from transaction
          commissions.add(CommissionBreakdown(
            totalAmount: transaction.amount,
            vendorAmount: _userRole == 'vendor' ? transaction.amount : 0,
            platformFee: 0,
            salesAgentCommission: _userRole == 'sales_agent' ? transaction.amount : 0,
            driverCommission: _userRole == 'driver' ? transaction.amount : 0,
            deliveryFee: 0,
            orderId: transaction.referenceId,
            calculatedAt: transaction.createdAt,
          ));
        }
      }
    }
    
    return commissions;
  }

  /// Calculate commission summary
  CommissionSummary _calculateCommissionSummary(
    List<CommissionBreakdown> commissions,
    List<WalletTransaction> transactions,
  ) {
    double totalEarned = 0;
    double averageCommission = 0;
    int totalOrders = commissions.length;
    
    // Calculate based on user role
    for (final commission in commissions) {
      switch (_userRole) {
        case 'vendor':
          totalEarned += commission.vendorAmount;
          break;
        case 'sales_agent':
          totalEarned += commission.salesAgentCommission;
          break;
        case 'driver':
          totalEarned += commission.driverCommission;
          break;
        case 'admin':
          totalEarned += commission.platformFee;
          break;
      }
    }
    
    averageCommission = totalOrders > 0 ? totalEarned / totalOrders : 0;
    
    // Calculate growth rate (compare with previous period)
    double growthRate = 0;
    // TODO: Implement growth rate calculation
    
    return CommissionSummary(
      totalEarned: totalEarned,
      averageCommission: averageCommission,
      totalOrders: totalOrders,
      growthRate: growthRate,
      period: state.period,
      userRole: _userRole,
    );
  }

  /// Calculate date range for period
  DateRange _calculateDateRange(CommissionPeriod period) {
    final now = DateTime.now();
    
    switch (period) {
      case CommissionPeriod.today:
        final startOfDay = DateTime(now.year, now.month, now.day);
        return DateRange(startOfDay, now);
        
      case CommissionPeriod.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return DateRange(startOfWeekDay, now);
        
      case CommissionPeriod.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        return DateRange(startOfMonth, now);
        
      case CommissionPeriod.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final endOfLastMonth = DateTime(now.year, now.month, 0);
        return DateRange(lastMonth, endOfLastMonth);
        
      case CommissionPeriod.last30Days:
        final start = now.subtract(const Duration(days: 30));
        return DateRange(start, now);
        
      case CommissionPeriod.custom:
        return DateRange(
          state.startDate ?? now.subtract(const Duration(days: 30)),
          state.endDate ?? now,
        );
    }
  }

  @override
  void dispose() {
    debugPrint('🔍 [COMMISSION] Disposing commission tracking notifier');
    super.dispose();
  }
}

/// Commission tracking provider for different user roles
final commissionTrackingProvider = StateNotifierProvider.family<CommissionTrackingNotifier, CommissionTrackingState, String>((ref, userRole) {
  final repository = ref.watch(walletRepositoryProvider);

  return CommissionTrackingNotifier(repository, ref, userRole);
});

/// Current user commission tracking provider
final currentUserCommissionTrackingProvider = StateNotifierProvider<CommissionTrackingNotifier, CommissionTrackingState>((ref) {
  final authState = ref.watch(authStateProvider);
  final userRole = authState.user?.role.value ?? 'customer';

  final repository = ref.watch(walletRepositoryProvider);

  return CommissionTrackingNotifier(repository, ref, userRole);
});

/// Commission actions provider for UI operations
final commissionActionsProvider = Provider<CommissionActions>((ref) {
  return CommissionActions(ref);
});

/// Commission actions class for centralized commission operations
class CommissionActions {
  final Ref _ref;

  CommissionActions(this._ref);

  /// Change commission period
  Future<void> changePeriod(String userRole, CommissionPeriod period) async {
    final notifier = _ref.read(commissionTrackingProvider(userRole).notifier);
    await notifier.changePeriod(period);
  }

  /// Apply custom date range
  Future<void> applyCustomDateRange(String userRole, DateTime startDate, DateTime endDate) async {
    final notifier = _ref.read(commissionTrackingProvider(userRole).notifier);
    await notifier.applyCustomDateRange(startDate, endDate);
  }

  /// Apply type filter
  Future<void> applyTypeFilter(String userRole, CommissionType? type) async {
    final notifier = _ref.read(commissionTrackingProvider(userRole).notifier);
    await notifier.applyTypeFilter(type);
  }

  /// Refresh commission data
  Future<void> refresh(String userRole) async {
    final notifier = _ref.read(commissionTrackingProvider(userRole).notifier);
    await notifier.refresh();
  }

  /// Get commission state
  CommissionTrackingState getCommissionState(String userRole) {
    return _ref.read(commissionTrackingProvider(userRole));
  }
}

/// Commission period enum
enum CommissionPeriod {
  today,
  thisWeek,
  thisMonth,
  lastMonth,
  last30Days,
  custom,
}

extension CommissionPeriodExtension on CommissionPeriod {
  String get displayName {
    switch (this) {
      case CommissionPeriod.today:
        return 'Today';
      case CommissionPeriod.thisWeek:
        return 'This Week';
      case CommissionPeriod.thisMonth:
        return 'This Month';
      case CommissionPeriod.lastMonth:
        return 'Last Month';
      case CommissionPeriod.last30Days:
        return 'Last 30 Days';
      case CommissionPeriod.custom:
        return 'Custom Range';
    }
  }
}

/// Commission summary data class
class CommissionSummary {
  final double totalEarned;
  final double averageCommission;
  final int totalOrders;
  final double growthRate;
  final CommissionPeriod period;
  final String userRole;

  const CommissionSummary({
    required this.totalEarned,
    required this.averageCommission,
    required this.totalOrders,
    required this.growthRate,
    required this.period,
    required this.userRole,
  });

  String get formattedTotalEarned => 'MYR ${totalEarned.toStringAsFixed(2)}';
  String get formattedAverageCommission => 'MYR ${averageCommission.toStringAsFixed(2)}';
  String get formattedGrowthRate => '${growthRate >= 0 ? '+' : ''}${growthRate.toStringAsFixed(1)}%';
}

/// Date range data class
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange(this.start, this.end);
}
