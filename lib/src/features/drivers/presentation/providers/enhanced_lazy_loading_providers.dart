import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/data/models/order.dart';
import '../../../../data/models/user_role.dart';
import '../../data/services/enhanced_lazy_loading_service.dart';
import 'enhanced_driver_order_history_providers.dart';

/// Enhanced lazy loading providers with cursor-based pagination and performance optimization

/// Provider for enhanced lazy loading with cursor pagination
final enhancedLazyLoadingProvider = FutureProvider.family<EnhancedLazyLoadingResult<Order>, LazyLoadingRequest>((ref, request) async {
  final authState = ref.read(authStateProvider);

  if (authState.user?.role != UserRole.driver) {
    debugPrint('🚀 EnhancedLazyLoading: User is not a driver, role: ${authState.user?.role}');
    return EnhancedLazyLoadingResult<Order>(
      items: [],
      hasMore: false,
      nextCursor: null,
      isLoading: false,
      currentPage: 1,
      totalLoaded: 0,
      fromCache: false,
      loadTime: Duration.zero,
      cacheKey: 'empty',
    );
  }

  final userId = authState.user?.id;
  if (userId == null) {
    debugPrint('🚀 EnhancedLazyLoading: No user ID found');
    return EnhancedLazyLoadingResult<Order>(
      items: [],
      hasMore: false,
      nextCursor: null,
      isLoading: false,
      currentPage: 1,
      totalLoaded: 0,
      fromCache: false,
      loadTime: Duration.zero,
      cacheKey: 'no_user',
    );
  }

  try {
    // Get driver ID from user profile
    final driverId = await _getDriverId(userId);
    if (driverId == null) {
      debugPrint('🚀 EnhancedLazyLoading: No driver found for user: $userId');
      return EnhancedLazyLoadingResult<Order>(
        items: [],
        hasMore: false,
        nextCursor: null,
        isLoading: false,
        currentPage: 1,
        totalLoaded: 0,
        fromCache: false,
        loadTime: Duration.zero,
        cacheKey: 'no_driver',
      );
    }

    // Initialize service if needed
    await EnhancedLazyLoadingService.instance.initialize();

    // Load orders with enhanced lazy loading
    return await EnhancedLazyLoadingService.instance.loadOrders(
      driverId: driverId,
      filter: request.filter,
      cursor: request.cursor,
      forceRefresh: request.forceRefresh,
      prefetch: request.prefetch,
    );
  } catch (e) {
    debugPrint('🚀 EnhancedLazyLoading: Error loading orders: $e');
    return EnhancedLazyLoadingResult<Order>(
      items: [],
      hasMore: false,
      nextCursor: null,
      isLoading: false,
      currentPage: 1,
      totalLoaded: 0,
      fromCache: false,
      loadTime: Duration.zero,
      cacheKey: 'error',
      error: e.toString(),
    );
  }
});

/// Provider for lazy loading state management
final lazyLoadingStateProvider = StateNotifierProvider.family<LazyLoadingStateNotifier, LazyLoadingState, String>((ref, driverId) {
  return LazyLoadingStateNotifier(driverId);
});

/// Provider for performance analytics
final lazyLoadingPerformanceProvider = Provider<Map<String, dynamic>>((ref) {
  return EnhancedLazyLoadingService.instance.getPerformanceAnalytics();
});

/// Provider for infinite scroll management
final infiniteScrollProvider = StateNotifierProvider.family<InfiniteScrollNotifier, InfiniteScrollState, String>((ref, driverId) {
  return InfiniteScrollNotifier(driverId, ref);
});

/// State notifier for lazy loading management
class LazyLoadingStateNotifier extends StateNotifier<LazyLoadingState> {
  final String driverId;

  LazyLoadingStateNotifier(this.driverId) : super(LazyLoadingState.initial());

  /// Load more data
  Future<void> loadMore(DateRangeFilter filter, String? cursor) async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final result = await EnhancedLazyLoadingService.instance.loadOrders(
        driverId: driverId,
        filter: filter,
        cursor: cursor,
      );

      state = state.copyWith(
        isLoading: false,
        hasMore: result.hasMore,
        nextCursor: result.nextCursor,
        totalLoaded: state.totalLoaded + result.items.length,
        lastLoadTime: result.loadTime,
        error: result.error,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Prefetch next page
  Future<void> prefetchNext(DateRangeFilter filter, String? cursor) async {
    if (!state.hasMore || state.isLoading) return;

    try {
      await EnhancedLazyLoadingService.instance.prefetchNextPage(
        driverId: driverId,
        currentFilter: filter,
        currentCursor: cursor,
      );
    } catch (e) {
      debugPrint('🚀 LazyLoadingState: Prefetch error: $e');
    }
  }

  /// Reset state
  void reset() {
    state = LazyLoadingState.initial();
  }

  /// Clear driver state
  void clearDriverState() {
    EnhancedLazyLoadingService.instance.clearDriverState(driverId);
    reset();
  }
}

/// State notifier for infinite scroll management
class InfiniteScrollNotifier extends StateNotifier<InfiniteScrollState> {
  final String driverId;
  final Ref ref;

  InfiniteScrollNotifier(this.driverId, this.ref) : super(InfiniteScrollState.initial());

  /// Check if should load more based on scroll position
  bool shouldLoadMore(int currentIndex, int totalItems, DateRangeFilter filter, String? cursor) {
    return EnhancedLazyLoadingService.instance.shouldLoadMore(
      driverId: driverId,
      filter: filter,
      cursor: cursor,
      currentIndex: currentIndex,
      totalItems: totalItems,
    );
  }

  /// Trigger load more
  Future<void> triggerLoadMore(DateRangeFilter filter, String? cursor) async {
    if (state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final result = await EnhancedLazyLoadingService.instance.loadMore(
        driverId: driverId,
        currentFilter: filter,
        currentCursor: cursor,
      );

      state = state.copyWith(
        isLoadingMore: false,
        hasMore: result.hasMore,
        nextCursor: result.nextCursor,
        lastLoadTime: result.loadTime,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  /// Update scroll metrics
  void updateScrollMetrics({
    required double scrollPosition,
    required double maxScrollExtent,
    required double scrollVelocity,
  }) {
    state = state.copyWith(
      scrollPosition: scrollPosition,
      maxScrollExtent: maxScrollExtent,
      scrollVelocity: scrollVelocity,
      lastScrollUpdate: DateTime.now(),
    );
  }

  /// Reset state
  void reset() {
    state = InfiniteScrollState.initial();
  }
}

/// Helper function to get driver ID from user ID
Future<String?> _getDriverId(String userId) async {
  try {
    // This would typically be cached or retrieved from a provider
    // For now, we'll use a simple approach
    return userId; // Assuming user ID is the same as driver ID for simplicity
  } catch (e) {
    debugPrint('🚀 EnhancedLazyLoading: Error getting driver ID: $e');
    return null;
  }
}

/// Lazy loading request model
@immutable
class LazyLoadingRequest {
  final DateRangeFilter filter;
  final String? cursor;
  final bool forceRefresh;
  final bool prefetch;

  const LazyLoadingRequest({
    required this.filter,
    this.cursor,
    this.forceRefresh = false,
    this.prefetch = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LazyLoadingRequest &&
        other.filter == filter &&
        other.cursor == cursor &&
        other.forceRefresh == forceRefresh &&
        other.prefetch == prefetch;
  }

  @override
  int get hashCode {
    return Object.hash(filter, cursor, forceRefresh, prefetch);
  }

  @override
  String toString() {
    return 'LazyLoadingRequest(filter: $filter, cursor: $cursor, forceRefresh: $forceRefresh, prefetch: $prefetch)';
  }
}

/// Lazy loading state model
@immutable
class LazyLoadingState {
  final bool isLoading;
  final bool hasMore;
  final String? nextCursor;
  final int totalLoaded;
  final Duration? lastLoadTime;
  final String? error;

  const LazyLoadingState({
    required this.isLoading,
    required this.hasMore,
    this.nextCursor,
    required this.totalLoaded,
    this.lastLoadTime,
    this.error,
  });

  factory LazyLoadingState.initial() {
    return const LazyLoadingState(
      isLoading: false,
      hasMore: true,
      totalLoaded: 0,
    );
  }

  LazyLoadingState copyWith({
    bool? isLoading,
    bool? hasMore,
    String? nextCursor,
    int? totalLoaded,
    Duration? lastLoadTime,
    String? error,
  }) {
    return LazyLoadingState(
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: nextCursor ?? this.nextCursor,
      totalLoaded: totalLoaded ?? this.totalLoaded,
      lastLoadTime: lastLoadTime ?? this.lastLoadTime,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'LazyLoadingState(isLoading: $isLoading, hasMore: $hasMore, totalLoaded: $totalLoaded)';
  }
}

/// Infinite scroll state model
@immutable
class InfiniteScrollState {
  final bool isLoadingMore;
  final bool hasMore;
  final String? nextCursor;
  final double scrollPosition;
  final double maxScrollExtent;
  final double scrollVelocity;
  final DateTime? lastScrollUpdate;
  final Duration? lastLoadTime;
  final String? error;

  const InfiniteScrollState({
    required this.isLoadingMore,
    required this.hasMore,
    this.nextCursor,
    required this.scrollPosition,
    required this.maxScrollExtent,
    required this.scrollVelocity,
    this.lastScrollUpdate,
    this.lastLoadTime,
    this.error,
  });

  factory InfiniteScrollState.initial() {
    return const InfiniteScrollState(
      isLoadingMore: false,
      hasMore: true,
      scrollPosition: 0.0,
      maxScrollExtent: 0.0,
      scrollVelocity: 0.0,
    );
  }

  InfiniteScrollState copyWith({
    bool? isLoadingMore,
    bool? hasMore,
    String? nextCursor,
    double? scrollPosition,
    double? maxScrollExtent,
    double? scrollVelocity,
    DateTime? lastScrollUpdate,
    Duration? lastLoadTime,
    String? error,
  }) {
    return InfiniteScrollState(
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: nextCursor ?? this.nextCursor,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      maxScrollExtent: maxScrollExtent ?? this.maxScrollExtent,
      scrollVelocity: scrollVelocity ?? this.scrollVelocity,
      lastScrollUpdate: lastScrollUpdate ?? this.lastScrollUpdate,
      lastLoadTime: lastLoadTime ?? this.lastLoadTime,
      error: error ?? this.error,
    );
  }

  double get scrollPercentage {
    if (maxScrollExtent <= 0) return 0.0;
    return (scrollPosition / maxScrollExtent).clamp(0.0, 1.0);
  }

  @override
  String toString() {
    return 'InfiniteScrollState(isLoadingMore: $isLoadingMore, hasMore: $hasMore, scrollPercentage: ${(scrollPercentage * 100).toStringAsFixed(1)}%)';
  }
}
