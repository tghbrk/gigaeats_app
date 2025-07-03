import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/marketplace_wallet/presentation/providers/wallet_analytics_provider.dart';
import '../../data/models/analytics/customer_spending_analytics.dart';
import '../../data/services/customer_spending_analytics_service.dart';

/// Provider for spending analytics service
final customerSpendingAnalyticsServiceProvider = Provider<CustomerSpendingAnalyticsService>((ref) {
  return CustomerSpendingAnalyticsService();
});

/// State class for spending analytics
class CustomerSpendingAnalyticsState {
  final bool isLoading;
  final String? errorMessage;
  final CustomerSpendingAnalytics? analytics;
  final List<SpendingTrend> trends;
  final List<SpendingCategory> categories;
  final List<MerchantSpending> topMerchants;
  final List<SpendingInsight> insights;
  final String selectedPeriod;
  final DateTime? startDate;
  final DateTime? endDate;

  const CustomerSpendingAnalyticsState({
    this.isLoading = false,
    this.errorMessage,
    this.analytics,
    this.trends = const [],
    this.categories = const [],
    this.topMerchants = const [],
    this.insights = const [],
    this.selectedPeriod = 'monthly',
    this.startDate,
    this.endDate,
  });

  CustomerSpendingAnalyticsState copyWith({
    bool? isLoading,
    String? errorMessage,
    CustomerSpendingAnalytics? analytics,
    List<SpendingTrend>? trends,
    List<SpendingCategory>? categories,
    List<MerchantSpending>? topMerchants,
    List<SpendingInsight>? insights,
    String? selectedPeriod,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return CustomerSpendingAnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      analytics: analytics ?? this.analytics,
      trends: trends ?? this.trends,
      categories: categories ?? this.categories,
      topMerchants: topMerchants ?? this.topMerchants,
      insights: insights ?? this.insights,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

/// Notifier for spending analytics
class CustomerSpendingAnalyticsNotifier extends StateNotifier<CustomerSpendingAnalyticsState> {
  final CustomerSpendingAnalyticsService _analyticsService;
  final Ref _ref;
  Timer? _refreshTimer;

  CustomerSpendingAnalyticsNotifier(this._analyticsService, this._ref)
      : super(const CustomerSpendingAnalyticsState());

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Load comprehensive spending analytics
  Future<void> loadAnalytics({
    String period = 'monthly',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final analytics = await _analyticsService.getSpendingAnalytics(
        userId: user.id,
        startDate: startDate,
        endDate: endDate,
        period: period,
      );

      state = state.copyWith(
        isLoading: false,
        analytics: analytics,
        selectedPeriod: period,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Load spending trends for charts
  Future<void> loadSpendingTrends({
    String period = 'daily',
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final trends = await _analyticsService.getSpendingTrends(
        userId: user.id,
        period: period,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );

      state = state.copyWith(trends: trends);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Load spending by category
  Future<void> loadSpendingByCategory({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final categories = await _analyticsService.getSpendingByCategory(
        userId: user.id,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );

      state = state.copyWith(categories: categories);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Load top merchants
  Future<void> loadTopMerchants({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final merchants = await _analyticsService.getTopMerchants(
        userId: user.id,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );

      state = state.copyWith(topMerchants: merchants);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Load spending insights
  Future<void> loadSpendingInsights({int limit = 5}) async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final insights = await _analyticsService.getSpendingInsights(
        userId: user.id,
        limit: limit,
      );

      state = state.copyWith(insights: insights);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Export spending data
  Future<Map<String, dynamic>> exportSpendingData({
    required String format,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categories,
  }) async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      return await _analyticsService.exportSpendingData(
        userId: user.id,
        format: format,
        startDate: startDate,
        endDate: endDate,
        categories: categories,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  /// Change selected period and reload data
  Future<void> changePeriod(String period) async {
    await loadAnalytics(period: period);
    await loadSpendingTrends(period: period == 'monthly' ? 'daily' : period);
  }

  /// Set custom date range
  Future<void> setDateRange(DateTime startDate, DateTime endDate) async {
    await loadAnalytics(
      period: 'custom',
      startDate: startDate,
      endDate: endDate,
    );
    await loadSpendingTrends(
      period: 'daily',
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Refresh all analytics data
  Future<void> refreshAll() async {
    await loadAnalytics(
      period: state.selectedPeriod,
      startDate: state.startDate,
      endDate: state.endDate,
    );
    await loadSpendingTrends(
      period: state.selectedPeriod == 'monthly' ? 'daily' : state.selectedPeriod,
      startDate: state.startDate,
      endDate: state.endDate,
    );
    await loadSpendingByCategory(
      startDate: state.startDate,
      endDate: state.endDate,
    );
    await loadTopMerchants(
      startDate: state.startDate,
      endDate: state.endDate,
    );
    await loadSpendingInsights();
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Setup real-time data refresh when wallet data changes
  void setupRealtimeRefresh() {
    // Listen to wallet analytics provider for real-time updates
    _ref.listen(
      walletAnalyticsProvider,
      (previous, next) {
        // Refresh analytics when wallet data changes
        if (previous != null && next != previous) {
          debugPrint('🔄 [ANALYTICS] Wallet data changed, refreshing analytics...');
          refreshAll();
        }
      },
    );

    // Setup periodic refresh every 30 seconds for real-time updates
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      debugPrint('🔄 [ANALYTICS] Periodic refresh triggered...');
      refreshAll();
    });

    debugPrint('✅ [ANALYTICS] Real-time refresh setup completed');
  }
}

/// Provider for spending analytics state management
final customerSpendingAnalyticsProvider = StateNotifierProvider<CustomerSpendingAnalyticsNotifier, CustomerSpendingAnalyticsState>((ref) {
  final analyticsService = ref.watch(customerSpendingAnalyticsServiceProvider);
  return CustomerSpendingAnalyticsNotifier(analyticsService, ref);
});

/// Provider for spending analytics as AsyncValue
final customerSpendingAnalyticsAsyncProvider = FutureProvider<CustomerSpendingAnalytics?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;

  if (user == null) {
    return null;
  }

  final analyticsService = ref.watch(customerSpendingAnalyticsServiceProvider);
  return analyticsService.getSpendingAnalytics(userId: user.id);
});

/// Provider for spending trends
final spendingTrendsProvider = FutureProvider.family<List<SpendingTrend>, Map<String, dynamic>>((ref, params) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;

  if (user == null) {
    return [];
  }

  final analyticsService = ref.watch(customerSpendingAnalyticsServiceProvider);
  return analyticsService.getSpendingTrends(
    userId: user.id,
    period: params['period'] as String? ?? 'daily',
    startDate: params['startDate'] as DateTime?,
    endDate: params['endDate'] as DateTime?,
    limit: params['limit'] as int?,
  );
});

/// Provider for spending categories
final spendingCategoriesProvider = FutureProvider.family<List<SpendingCategory>, Map<String, dynamic>>((ref, params) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;

  if (user == null) {
    return [];
  }

  final analyticsService = ref.watch(customerSpendingAnalyticsServiceProvider);
  return analyticsService.getSpendingByCategory(
    userId: user.id,
    startDate: params['startDate'] as DateTime?,
    endDate: params['endDate'] as DateTime?,
    limit: params['limit'] as int?,
  );
});

/// Provider for top merchants
final topMerchantsProvider = FutureProvider.family<List<MerchantSpending>, Map<String, dynamic>>((ref, params) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;

  if (user == null) {
    return [];
  }

  final analyticsService = ref.watch(customerSpendingAnalyticsServiceProvider);
  return analyticsService.getTopMerchants(
    userId: user.id,
    startDate: params['startDate'] as DateTime?,
    endDate: params['endDate'] as DateTime?,
    limit: params['limit'] as int? ?? 10,
  );
});

/// Provider for spending insights
final spendingInsightsProvider = FutureProvider<List<SpendingInsight>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;

  if (user == null) {
    return [];
  }

  final analyticsService = ref.watch(customerSpendingAnalyticsServiceProvider);
  return analyticsService.getSpendingInsights(userId: user.id);
});
