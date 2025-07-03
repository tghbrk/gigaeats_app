import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/wallet_analytics.dart';
import '../../data/services/wallet_analytics_service.dart';
import '../../../../core/data/services/real_time_analytics_service.dart';
import '../../../../core/data/services/analytics_privacy_service.dart';
import '../../data/repositories/customer_wallet_analytics_repository.dart';

/// State for wallet analytics
@immutable
class WalletAnalyticsState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<WalletAnalytics> analytics;
  final List<SpendingTrendData> trends;
  final List<TransactionCategoryData> categories;
  final List<Map<String, dynamic>> summaryCards;
  final String selectedPeriod;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, bool> privacySettings;

  const WalletAnalyticsState({
    this.isLoading = false,
    this.errorMessage,
    this.analytics = const [],
    this.trends = const [],
    this.categories = const [],
    this.summaryCards = const [],
    this.selectedPeriod = 'monthly',
    this.startDate,
    this.endDate,
    this.privacySettings = const {},
  });

  WalletAnalyticsState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<WalletAnalytics>? analytics,
    List<SpendingTrendData>? trends,
    List<TransactionCategoryData>? categories,
    List<Map<String, dynamic>>? summaryCards,
    String? selectedPeriod,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, bool>? privacySettings,
  }) {
    return WalletAnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      analytics: analytics ?? this.analytics,
      trends: trends ?? this.trends,
      categories: categories ?? this.categories,
      summaryCards: summaryCards ?? this.summaryCards,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      privacySettings: privacySettings ?? this.privacySettings,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        analytics,
        trends,
        categories,
        summaryCards,
        selectedPeriod,
        startDate,
        endDate,
        privacySettings,
      ];

  /// Get current month analytics
  WalletAnalytics? get currentMonthAnalytics {
    if (analytics.isEmpty) return null;
    return analytics.firstWhere(
      (a) => a.periodType == 'monthly',
      orElse: () => analytics.first,
    );
  }

  /// Check if analytics are enabled
  bool get analyticsEnabled {
    return privacySettings['allow_analytics'] ?? false;
  }

  /// Check if export is allowed
  bool get exportEnabled {
    return privacySettings['allow_export'] ?? false;
  }
}

/// Wallet analytics notifier
class WalletAnalyticsNotifier extends StateNotifier<WalletAnalyticsState> {
  final Ref _ref;
  final WalletAnalyticsService _analyticsService;
  final RealTimeAnalyticsService _realtimeService;
  final AnalyticsPrivacyService _privacyService;

  @override
  set state(WalletAnalyticsState newState) {
    debugPrint('🔄 [WALLET-ANALYTICS-PROVIDER] State change:');
    debugPrint('   - isLoading: ${state.isLoading} → ${newState.isLoading}');
    debugPrint('   - errorMessage: ${state.errorMessage} → ${newState.errorMessage}');
    debugPrint('   - analyticsEnabled: ${state.analyticsEnabled} → ${newState.analyticsEnabled}');
    debugPrint('   - analytics count: ${state.analytics.length} → ${newState.analytics.length}');
    debugPrint('   - trends count: ${state.trends.length} → ${newState.trends.length}');
    debugPrint('   - categories count: ${state.categories.length} → ${newState.categories.length}');
    debugPrint('   - summaryCards count: ${state.summaryCards.length} → ${newState.summaryCards.length}');
    super.state = newState;
  }

  WalletAnalyticsNotifier(
    this._ref,
    this._analyticsService,
    this._realtimeService,
    this._privacyService,
  ) : super(const WalletAnalyticsState()) {
    debugPrint('🔍 [WALLET-ANALYTICS-PROVIDER] Constructor called');
    _initializeAnalytics();
  }

  /// Initialize analytics and load initial data
  Future<void> _initializeAnalytics() async {
    debugPrint('🔍 [WALLET-ANALYTICS-PROVIDER] _initializeAnalytics() called');
    try {
      await loadPrivacySettings();
      debugPrint('🔍 [WALLET-ANALYTICS-PROVIDER] Privacy settings loaded, analyticsEnabled: ${state.analyticsEnabled}');

      if (state.analyticsEnabled) {
        debugPrint('🔍 [WALLET-ANALYTICS-PROVIDER] Analytics enabled, loading data...');
        await loadAnalytics();
        _setupRealtimeUpdates();
        debugPrint('✅ [WALLET-ANALYTICS-PROVIDER] Initialization completed successfully');
      } else {
        debugPrint('⚠️ [WALLET-ANALYTICS-PROVIDER] Analytics disabled, skipping data load');
      }
    } catch (e, stack) {
      debugPrint('❌ [WALLET-ANALYTICS-PROVIDER] Error in _initializeAnalytics: $e');
      debugPrint('❌ [WALLET-ANALYTICS-PROVIDER] Stack trace: $stack');
    }
  }

  /// Load privacy settings
  Future<void> loadPrivacySettings() async {
    debugPrint('🔍 [WALLET-ANALYTICS-PROVIDER] loadPrivacySettings() called');
    try {
      final result = await _privacyService.getPrivacySettings();
      result.fold(
        (failure) {
          debugPrint('❌ [WALLET-ANALYTICS-PROVIDER] Failed to load privacy settings: ${failure.message}');
          // Set default settings if loading fails
          state = state.copyWith(privacySettings: {'allow_analytics': true, 'allow_export': true});
        },
        (settings) {
          debugPrint('✅ [WALLET-ANALYTICS-PROVIDER] Privacy settings loaded: $settings');
          state = state.copyWith(privacySettings: settings);
        },
      );
    } catch (e, stack) {
      debugPrint('❌ [WALLET-ANALYTICS-PROVIDER] Error loading privacy settings: $e');
      debugPrint('❌ [WALLET-ANALYTICS-PROVIDER] Stack trace: $stack');
      // Set default settings if error occurs
      state = state.copyWith(privacySettings: {'allow_analytics': true, 'allow_export': true});
    }
  }

  /// Load comprehensive analytics data
  Future<void> loadAnalytics({
    String? periodType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    debugPrint('🔍 [WALLET-ANALYTICS-PROVIDER] loadAnalytics() called');
    debugPrint('🔍 [WALLET-ANALYTICS-PROVIDER] Parameters - periodType: $periodType, startDate: $startDate, endDate: $endDate');
    debugPrint('🔍 [WALLET-ANALYTICS-PROVIDER] Current state - analyticsEnabled: ${state.analyticsEnabled}');

    if (!state.analyticsEnabled) {
      debugPrint('⚠️ [WALLET-ANALYTICS-PROVIDER] Analytics disabled, setting error message');
      state = state.copyWith(
        errorMessage: 'Analytics disabled. Enable in wallet settings.',
      );
      return;
    }

    debugPrint('🔍 [WALLET-ANALYTICS-PROVIDER] Setting loading state to true');
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final period = periodType ?? state.selectedPeriod;

      // Load analytics summary
      final analyticsResult = await _analyticsService.getAnalyticsSummary(
        periodType: period,
        limit: 12,
      );

      await analyticsResult.fold(
        (failure) async {
          debugPrint('❌ [ANALYTICS-PROVIDER] Analytics loading failed: ${failure.message}');
          state = state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          );
        },
        (analytics) async {
          try {
            // Load additional data in parallel
            final futures = await Future.wait([
              _loadSpendingTrends(period, startDate, endDate),
              _loadSpendingCategories(period, startDate, endDate),
              _loadSummaryCards(),
            ]);

            debugPrint('✅ [ANALYTICS-PROVIDER] Analytics loaded successfully');
            state = state.copyWith(
              isLoading: false,
              analytics: analytics,
              trends: futures[0] as List<SpendingTrendData>,
              categories: futures[1] as List<TransactionCategoryData>,
              summaryCards: futures[2] as List<Map<String, dynamic>>,
              selectedPeriod: period,
              startDate: startDate,
              endDate: endDate,
              errorMessage: null, // Clear any previous errors
            );
          } catch (e) {
            debugPrint('❌ [ANALYTICS-PROVIDER] Error loading additional data: $e');
            // Don't fail completely if additional data fails, just log it
            state = state.copyWith(
              isLoading: false,
              analytics: analytics,
              selectedPeriod: period,
              startDate: startDate,
              endDate: endDate,
              errorMessage: null, // Don't show error for partial failures
            );
          }
        },
      );
    } catch (e) {
      debugPrint('❌ [ANALYTICS-PROVIDER] Unexpected error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load analytics. Please try again.',
      );
    }
  }

  /// Load spending trends
  Future<List<SpendingTrendData>> _loadSpendingTrends(
    String periodType,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      final result = await _analyticsService.getSpendingTrends(
        days: 30,
      );

      return result.fold(
        (failure) {
          debugPrint('Failed to load spending trends: ${failure.message}');
          return <SpendingTrendData>[];
        },
        (trends) => trends,
      );
    } catch (e) {
      debugPrint('Error loading spending trends: $e');
      return <SpendingTrendData>[];
    }
  }

  /// Load spending categories
  Future<List<TransactionCategoryData>> _loadSpendingCategories(
    String periodType,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      final result = await _analyticsService.getSpendingCategories(
        days: 30,
      );

      return result.fold(
        (failure) {
          debugPrint('Failed to load spending categories: ${failure.message}');
          return <TransactionCategoryData>[];
        },
        (categories) => categories,
      );
    } catch (e) {
      debugPrint('Error loading spending categories: $e');
      return <TransactionCategoryData>[];
    }
  }

  /// Load summary cards
  Future<List<Map<String, dynamic>>> _loadSummaryCards() async {
    try {
      final result = await _analyticsService.getSummaryCards();

      return result.fold(
        (failure) {
          debugPrint('Failed to load summary cards: ${failure.message}');
          return <Map<String, dynamic>>[];
        },
        (cards) => cards.map((card) => {
          'title': card.title,
          'value': card.value,
          'subtitle': card.subtitle,
          'trend': card.trend,
          'trendPercentage': card.trendPercentage,
          'icon': card.icon,
          'color': card.color,
          'isPositiveTrend': card.isPositiveTrend,
        }).toList(),
      );
    } catch (e) {
      debugPrint('Error loading summary cards: $e');
      return <Map<String, dynamic>>[];
    }
  }

  /// Setup real-time updates
  void _setupRealtimeUpdates() {
    final authState = _ref.read(authStateProvider);
    final user = authState.user;

    if (user != null) {
      _realtimeService.initializeSubscriptions();

      // Listen to analytics updates
      _realtimeService.analyticsUpdates.listen((_) {
        if (mounted) {
          loadAnalytics();
        }
      });

      // Listen to transaction updates for immediate feedback
      _realtimeService.transactionUpdates.listen((transaction) {
        if (mounted) {
          _handleTransactionUpdate(transaction);
        }
      });

      // Listen to balance updates
      _realtimeService.balanceUpdates.listen((balance) {
        if (mounted) {
          _handleBalanceUpdate(balance);
        }
      });

      // Listen to category updates
      _realtimeService.categoryUpdates.listen((categories) {
        if (mounted) {
          _handleCategoryUpdate(categories);
        }
      });
    }
  }

  /// Handle real-time transaction updates
  void _handleTransactionUpdate(Map<String, dynamic> transaction) {
    debugPrint('🔄 [WALLET-ANALYTICS] Real-time transaction update received');

    // Update summary cards with new transaction
    final currentCards = state.summaryCards.toList();
    if (currentCards.isNotEmpty) {
      // Update transaction count
      final transactionCard = currentCards.firstWhere(
        (card) => card['title'] == 'Transactions',
        orElse: () => <String, dynamic>{},
      );

      if (transactionCard.isNotEmpty) {
        final currentCount = int.tryParse(transactionCard['value'] ?? '0') ?? 0;
        transactionCard['value'] = (currentCount + 1).toString();
      }

      state = state.copyWith(summaryCards: currentCards);
    }
  }

  /// Handle real-time balance updates
  void _handleBalanceUpdate(Map<String, dynamic> balance) {
    debugPrint('🔄 [WALLET-ANALYTICS] Real-time balance update received');

    // Trigger a refresh of analytics data to reflect new balance
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        loadAnalytics();
      }
    });
  }

  /// Handle real-time category updates
  void _handleCategoryUpdate(List<Map<String, dynamic>> categories) {
    debugPrint('🔄 [WALLET-ANALYTICS] Real-time category update received');

    // Convert to TransactionCategoryData and update state
    final categoryData = categories.map((cat) => TransactionCategoryData(
      categoryType: cat['category_type'] ?? 'unknown',
      categoryName: cat['category_name'] ?? 'Unknown',
      totalAmount: (cat['total_amount'] as num?)?.toDouble() ?? 0.0,
      transactionCount: cat['transaction_count'] ?? 0,
      avgAmount: (cat['avg_amount'] as num?)?.toDouble() ?? 0.0,
      percentageOfTotal: (cat['percentage_of_total'] as num?)?.toDouble() ?? 0.0,
      vendorId: cat['vendor_id'],
      vendorName: cat['vendor_name'],
    )).toList();

    state = state.copyWith(categories: categoryData);
  }

  /// Change selected period and reload data
  Future<void> changePeriod(String period) async {
    await loadAnalytics(periodType: period);
  }

  /// Set custom date range
  Future<void> setDateRange(DateTime startDate, DateTime endDate) async {
    await loadAnalytics(
      periodType: 'custom',
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Refresh all analytics data
  Future<void> refreshAll() async {
    debugPrint('🔍 [WALLET-ANALYTICS-PROVIDER] refreshAll() called');
    try {
      await loadPrivacySettings();
      if (state.analyticsEnabled) {
        debugPrint('🔍 [WALLET-ANALYTICS-PROVIDER] Analytics enabled, loading analytics data...');
        await loadAnalytics();
      } else {
        debugPrint('⚠️ [WALLET-ANALYTICS-PROVIDER] Analytics disabled, skipping data load');
      }
    } catch (e, stack) {
      debugPrint('❌ [WALLET-ANALYTICS-PROVIDER] Error in refreshAll: $e');
      debugPrint('❌ [WALLET-ANALYTICS-PROVIDER] Stack trace: $stack');
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  @override
  void dispose() {
    _realtimeService.dispose();
    super.dispose();
  }
}

/// Providers
final customerWalletAnalyticsRepositoryProvider = Provider<CustomerWalletAnalyticsRepository>((ref) {
  return CustomerWalletAnalyticsRepository();
});

final walletAnalyticsServiceProvider = Provider<WalletAnalyticsService>((ref) {
  final repository = ref.watch(customerWalletAnalyticsRepositoryProvider);
  return WalletAnalyticsService(repository: repository);
});

final realTimeAnalyticsServiceProvider = Provider<RealTimeAnalyticsService>((ref) {
  final repository = ref.watch(customerWalletAnalyticsRepositoryProvider);
  return RealTimeAnalyticsService(repository: repository);
});

final analyticsPrivacyServiceProvider = Provider<AnalyticsPrivacyService>((ref) {
  final repository = ref.watch(customerWalletAnalyticsRepositoryProvider);
  return AnalyticsPrivacyService(repository: repository);
});

final walletAnalyticsProvider = StateNotifierProvider<WalletAnalyticsNotifier, WalletAnalyticsState>((ref) {
  final analyticsService = ref.watch(walletAnalyticsServiceProvider);
  final realtimeService = ref.watch(realTimeAnalyticsServiceProvider);
  final privacyService = ref.watch(analyticsPrivacyServiceProvider);
  
  return WalletAnalyticsNotifier(
    ref,
    analyticsService,
    realtimeService,
    privacyService,
  );
});
