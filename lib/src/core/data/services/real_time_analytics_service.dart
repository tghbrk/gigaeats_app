import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import '../../utils/logger.dart';
import '../../../features/marketplace_wallet/data/repositories/customer_wallet_analytics_repository.dart';


/// Service for real-time analytics updates via Supabase subscriptions
class RealTimeAnalyticsService {
  final CustomerWalletAnalyticsRepository _repository;
  final SupabaseClient _supabase = Supabase.instance.client;
  final AppLogger _logger = AppLogger();

  // Stream controllers for real-time updates
  final StreamController<Map<String, dynamic>> _analyticsUpdatesController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _categoryUpdatesController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<bool> _refreshViewsController =
      StreamController<bool>.broadcast();
  final StreamController<Map<String, dynamic>> _balanceUpdatesController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _transactionUpdatesController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _trendsUpdatesController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  // Subscription management
  RealtimeChannel? _analyticsChannel;
  RealtimeChannel? _categoriesChannel;
  RealtimeChannel? _refreshChannel;
  RealtimeChannel? _transactionsChannel;
  RealtimeChannel? _walletChannel;
  bool _isSubscribed = false;
  Timer? _debounceTimer;

  RealTimeAnalyticsService({
    required CustomerWalletAnalyticsRepository repository,
  }) : _repository = repository;

  /// Stream of analytics summary updates
  Stream<Map<String, dynamic>> get analyticsUpdates => _analyticsUpdatesController.stream;

  /// Stream of category breakdown updates
  Stream<List<Map<String, dynamic>>> get categoryUpdates => _categoryUpdatesController.stream;

  /// Stream of materialized view refresh notifications
  Stream<bool> get refreshViewsUpdates => _refreshViewsController.stream;

  /// Stream of balance updates
  Stream<Map<String, dynamic>> get balanceUpdates => _balanceUpdatesController.stream;

  /// Stream of transaction updates
  Stream<Map<String, dynamic>> get transactionUpdates => _transactionUpdatesController.stream;

  /// Stream of spending trends updates
  Stream<List<Map<String, dynamic>>> get trendsUpdates => _trendsUpdatesController.stream;

  /// Initialize real-time subscriptions for analytics
  Future<void> initializeSubscriptions() async {
    if (_isSubscribed) {
      debugPrint('🔄 [REALTIME-ANALYTICS] Already subscribed to analytics updates');
      return;
    }

    try {
      debugPrint('🔄 [REALTIME-ANALYTICS] Initializing analytics subscriptions');

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Subscribe to analytics summary changes
      await _subscribeToAnalyticsSummary(currentUser.id);

      // Subscribe to category changes
      await _subscribeToCategories(currentUser.id);

      // Subscribe to refresh notifications
      await _subscribeToRefreshNotifications();

      // Subscribe to transaction changes for live updates
      await _subscribeToTransactions(currentUser.id);

      // Subscribe to wallet balance changes
      await _subscribeToWalletBalance(currentUser.id);

      _isSubscribed = true;
      debugPrint('🔄 [REALTIME-ANALYTICS] Analytics subscriptions initialized successfully');
    } catch (e) {
      _logger.logError('Failed to initialize analytics subscriptions', e);
      rethrow;
    }
  }

  /// Subscribe to analytics summary table changes
  Future<void> _subscribeToAnalyticsSummary(String userId) async {
    _analyticsChannel = _supabase.channel('analytics_summary_$userId');

    _analyticsChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'wallet_analytics_summary',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('🔄 [REALTIME-ANALYTICS] Analytics summary updated: ${payload.eventType}');
            _handleAnalyticsUpdate(payload);
          },
        )
        .subscribe();

    debugPrint('🔄 [REALTIME-ANALYTICS] Subscribed to analytics summary updates');
  }

  /// Subscribe to spending categories table changes
  Future<void> _subscribeToCategories(String userId) async {
    _categoriesChannel = _supabase.channel('spending_categories_$userId');

    _categoriesChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'wallet_spending_categories',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('🔄 [REALTIME-ANALYTICS] Spending categories updated: ${payload.eventType}');
            _handleCategoryUpdate(payload);
          },
        )
        .subscribe();

    debugPrint('🔄 [REALTIME-ANALYTICS] Subscribed to spending categories updates');
  }

  /// Subscribe to materialized view refresh notifications
  Future<void> _subscribeToRefreshNotifications() async {
    _refreshChannel = _supabase.channel('analytics_refresh_notifications');

    _refreshChannel!
        .onBroadcast(
          event: 'refresh_analytics_views',
          callback: (payload) {
            debugPrint('🔄 [REALTIME-ANALYTICS] Materialized views refresh notification received');
            _handleRefreshNotification(payload);
          },
        )
        .subscribe();

    debugPrint('🔄 [REALTIME-ANALYTICS] Subscribed to refresh notifications');
  }

  /// Subscribe to transaction changes for live analytics updates
  Future<void> _subscribeToTransactions(String userId) async {
    _transactionsChannel = _supabase.channel('transactions_$userId');

    _transactionsChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'customer_wallet_transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('🔄 [REALTIME-ANALYTICS] Transaction update received: ${payload.eventType}');
            _handleTransactionUpdate(payload);
          },
        )
        .subscribe();

    debugPrint('🔄 [REALTIME-ANALYTICS] Subscribed to transaction updates');
  }

  /// Subscribe to wallet balance changes
  Future<void> _subscribeToWalletBalance(String userId) async {
    _walletChannel = _supabase.channel('wallet_balance_$userId');

    _walletChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'customer_wallets',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('🔄 [REALTIME-ANALYTICS] Wallet balance update received');
            _handleBalanceUpdate(payload);
          },
        )
        .subscribe();

    debugPrint('🔄 [REALTIME-ANALYTICS] Subscribed to wallet balance updates');
  }

  /// Handle analytics summary updates
  void _handleAnalyticsUpdate(PostgresChangePayload payload) {
    try {
      final record = payload.newRecord;
      if (record.isNotEmpty) {
        debugPrint('🔄 [REALTIME-ANALYTICS] Broadcasting analytics update');
        _analyticsUpdatesController.add(record);
      }
    } catch (e) {
      _logger.logError('Failed to handle analytics update', e);
    }
  }

  /// Handle category updates
  void _handleCategoryUpdate(PostgresChangePayload payload) {
    try {
      debugPrint('🔄 [REALTIME-ANALYTICS] Category update received, fetching latest data');
      
      // Fetch updated category data
      _fetchAndBroadcastCategories();
    } catch (e) {
      _logger.logError('Failed to handle category update', e);
    }
  }

  /// Handle materialized view refresh notifications
  void _handleRefreshNotification(Map<String, dynamic> payload) {
    try {
      debugPrint('🔄 [REALTIME-ANALYTICS] Broadcasting refresh notification');
      _refreshViewsController.add(true);
    } catch (e) {
      _logger.logError('Failed to handle refresh notification', e);
    }
  }

  /// Handle transaction updates with debouncing
  void _handleTransactionUpdate(PostgresChangePayload payload) {
    try {
      final record = payload.newRecord;
      debugPrint('🔄 [REALTIME-ANALYTICS] Transaction update: ${payload.eventType}');

      // Debounce rapid transaction updates
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        _transactionUpdatesController.add(record);
        _triggerAnalyticsRefreshDebounced();
      });
    } catch (e) {
      _logger.logError('Failed to handle transaction update', e);
    }
  }

  /// Handle wallet balance updates
  void _handleBalanceUpdate(PostgresChangePayload payload) {
    try {
      final record = payload.newRecord;
      debugPrint('🔄 [REALTIME-ANALYTICS] Balance update received');

      _balanceUpdatesController.add(record);

      // Trigger analytics refresh for balance-related metrics
      _triggerAnalyticsRefreshDebounced();
    } catch (e) {
      _logger.logError('Failed to handle balance update', e);
    }
  }

  /// Trigger analytics refresh with debouncing to prevent excessive updates
  void _triggerAnalyticsRefreshDebounced() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      triggerAnalyticsRefresh();
    });
  }

  /// Fetch and broadcast updated category data
  Future<void> _fetchAndBroadcastCategories() async {
    try {
      final categoriesResult = await _repository.getCategoryBreakdown30d();
      categoriesResult.fold(
        (failure) => _logger.logError('Failed to fetch updated categories', failure),
        (categories) {
          debugPrint('🔄 [REALTIME-ANALYTICS] Broadcasting category updates: ${categories.length} categories');
          _categoryUpdatesController.add(categories);
        },
      );
    } catch (e) {
      _logger.logError('Failed to fetch and broadcast categories', e);
    }
  }

  /// Manually trigger analytics refresh
  Future<void> triggerAnalyticsRefresh() async {
    try {
      debugPrint('🔄 [REALTIME-ANALYTICS] Manually triggering analytics refresh');

      final refreshResult = await _repository.refreshAnalyticsViews();
      refreshResult.fold(
        (failure) => _logger.logError('Failed to refresh analytics views', failure),
        (_) {
          debugPrint('🔄 [REALTIME-ANALYTICS] Analytics views refreshed successfully');
          _refreshViewsController.add(true);
        },
      );
    } catch (e) {
      _logger.logError('Failed to trigger analytics refresh', e);
    }
  }

  /// Check if subscriptions are active
  bool get isSubscribed => _isSubscribed;

  /// Get subscription status for debugging
  Map<String, bool> get subscriptionStatus => {
    'analytics_summary': _analyticsChannel != null && _isSubscribed,
    'spending_categories': _categoriesChannel != null && _isSubscribed,
    'refresh_notifications': _refreshChannel != null && _isSubscribed,
    'is_subscribed': _isSubscribed,
  };

  /// Pause subscriptions (useful for background/foreground transitions)
  Future<void> pauseSubscriptions() async {
    try {
      debugPrint('🔄 [REALTIME-ANALYTICS] Pausing analytics subscriptions');

      await _analyticsChannel?.unsubscribe();
      await _categoriesChannel?.unsubscribe();
      await _refreshChannel?.unsubscribe();

      debugPrint('🔄 [REALTIME-ANALYTICS] Analytics subscriptions paused');
    } catch (e) {
      _logger.logError('Failed to pause analytics subscriptions', e);
    }
  }

  /// Resume subscriptions
  Future<void> resumeSubscriptions() async {
    try {
      debugPrint('🔄 [REALTIME-ANALYTICS] Resuming analytics subscriptions');

      if (_isSubscribed) {
        _analyticsChannel?.subscribe();
        _categoriesChannel?.subscribe();
        _refreshChannel?.subscribe();
      } else {
        await initializeSubscriptions();
      }

      debugPrint('🔄 [REALTIME-ANALYTICS] Analytics subscriptions resumed');
    } catch (e) {
      _logger.logError('Failed to resume analytics subscriptions', e);
    }
  }

  /// Dispose of all subscriptions and controllers
  Future<void> dispose() async {
    try {
      debugPrint('🔄 [REALTIME-ANALYTICS] Disposing analytics subscriptions');

      // Cancel debounce timer
      _debounceTimer?.cancel();

      // Unsubscribe from channels
      await _analyticsChannel?.unsubscribe();
      await _categoriesChannel?.unsubscribe();
      await _refreshChannel?.unsubscribe();
      await _transactionsChannel?.unsubscribe();
      await _walletChannel?.unsubscribe();

      // Close stream controllers
      await _analyticsUpdatesController.close();
      await _categoryUpdatesController.close();
      await _refreshViewsController.close();
      await _balanceUpdatesController.close();
      await _transactionUpdatesController.close();
      await _trendsUpdatesController.close();

      _isSubscribed = false;
      debugPrint('🔄 [REALTIME-ANALYTICS] Analytics subscriptions disposed');
    } catch (e) {
      _logger.logError('Failed to dispose analytics subscriptions', e);
    }
  }

  /// Get real-time analytics data with fallback to repository
  Stream<Map<String, dynamic>> getCurrentMonthAnalyticsStream() async* {
    // First, emit current data
    final currentResult = await _repository.getCurrentMonthAnalytics();
    currentResult.fold(
      (failure) => _logger.logError('Failed to get current analytics', failure),
      (analytics) {
        if (analytics != null) {
          // Note: Cannot yield inside fold, will emit after
        }
      },
    );

    // Emit current data if available
    final analytics = currentResult.fold(
      (failure) => null,
      (analytics) => analytics,
    );
    if (analytics != null) {
      yield analytics;
    }

    // Then, listen for real-time updates
    await for (final update in analyticsUpdates) {
      // Filter for current month data
      final periodStart = update['period_start'] as String?;
      if (periodStart != null) {
        final updateDate = DateTime.parse(periodStart);
        final now = DateTime.now();
        final currentMonthStart = DateTime(now.year, now.month, 1);
        
        if (updateDate.year == currentMonthStart.year && 
            updateDate.month == currentMonthStart.month) {
          yield update;
        }
      }
    }
  }

  /// Get real-time category data stream
  Stream<List<Map<String, dynamic>>> getCategoryBreakdownStream() async* {
    // First, emit current data
    final currentResult = await _repository.getCategoryBreakdown30d();
    currentResult.fold(
      (failure) => _logger.logError('Failed to get current categories', failure),
      (categories) {
        // Note: Cannot yield inside fold, will emit after
      },
    );

    // Emit current data if available
    final categories = currentResult.fold(
      (failure) => <Map<String, dynamic>>[],
      (categories) => categories,
    );
    yield categories;

    // Then, listen for real-time updates
    await for (final update in categoryUpdates) {
      yield update;
    }
  }
}
