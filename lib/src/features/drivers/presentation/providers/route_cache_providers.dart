import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/services/route_cache_service.dart';
import '../../data/services/enhanced_route_service.dart';

/// Provider for navigation preferences
final navigationPreferencesProvider = StateNotifierProvider<NavigationPreferencesNotifier, NavigationPreferences>((ref) {
  return NavigationPreferencesNotifier();
});

/// Provider for cache statistics
final cacheStatisticsProvider = FutureProvider<CacheStatistics>((ref) async {
  return await RouteCacheService.getCacheStatistics();
});

/// Provider for offline routes list
final offlineRoutesProvider = FutureProvider<List<OfflineRoute>>((ref) async {
  return await RouteCacheService.listOfflineRoutes();
});

/// Provider for cached route lookup
final cachedRouteProvider = FutureProvider.family<DetailedRouteInfo?, CachedRouteParams>((ref, params) async {
  return await RouteCacheService.getCachedRoute(
    origin: params.origin,
    destination: params.destination,
    routeId: params.routeId,
  );
});

/// Provider for route caching with enhanced service integration
final routeCacheManagerProvider = StateNotifierProvider<RouteCacheManagerNotifier, RouteCacheState>((ref) {
  return RouteCacheManagerNotifier();
});

/// State notifier for navigation preferences
class NavigationPreferencesNotifier extends StateNotifier<NavigationPreferences> {
  NavigationPreferencesNotifier() : super(NavigationPreferences.defaultPreferences()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final preferences = await RouteCacheService.getNavigationPreferences();
      state = preferences;
    } catch (e) {
      debugPrint('NavigationPreferencesNotifier: Error loading preferences: $e');
    }
  }

  Future<void> updatePreferences(NavigationPreferences preferences) async {
    try {
      await RouteCacheService.saveNavigationPreferences(preferences);
      state = preferences;
    } catch (e) {
      debugPrint('NavigationPreferencesNotifier: Error updating preferences: $e');
    }
  }

  Future<void> updatePreferredApp(String appId) async {
    await updatePreferences(state.copyWith(preferredNavigationApp: appId));
  }

  Future<void> toggleCacheRoutes() async {
    await updatePreferences(state.copyWith(cacheRoutes: !state.cacheRoutes));
  }

  Future<void> toggleOfflineRoutes() async {
    await updatePreferences(state.copyWith(useOfflineRoutes: !state.useOfflineRoutes));
  }

  Future<void> toggleTrafficAlerts() async {
    await updatePreferences(state.copyWith(showTrafficAlerts: !state.showTrafficAlerts));
  }

  Future<void> updateRoutePreferences({
    bool? avoidTolls,
    bool? avoidHighways,
    bool? avoidFerries,
    String? units,
  }) async {
    await updatePreferences(state.copyWith(
      avoidTolls: avoidTolls,
      avoidHighways: avoidHighways,
      avoidFerries: avoidFerries,
      units: units,
    ));
  }
}

/// State notifier for route cache management
class RouteCacheManagerNotifier extends StateNotifier<RouteCacheState> {
  RouteCacheManagerNotifier() : super(const RouteCacheState.initial());

  /// Cache a route with automatic preference checking
  Future<void> cacheRoute({
    required LatLng origin,
    required LatLng destination,
    required DetailedRouteInfo routeInfo,
    String? routeId,
  }) async {
    try {
      // Check if caching is enabled
      final preferences = await RouteCacheService.getNavigationPreferences();
      if (!preferences.cacheRoutes) {
        debugPrint('RouteCacheManager: Route caching is disabled');
        return;
      }

      await RouteCacheService.cacheRoute(
        origin: origin,
        destination: destination,
        routeInfo: routeInfo,
        routeId: routeId,
      );

      state = state.copyWith(lastCachedRoute: routeId ?? _generateRouteKey(origin, destination));
    } catch (e) {
      debugPrint('RouteCacheManager: Error caching route: $e');
      state = state.copyWith(error: 'Failed to cache route: ${e.toString()}');
    }
  }

  /// Get cached route with fallback to enhanced route service
  Future<DetailedRouteInfo?> getRouteWithCache({
    required LatLng origin,
    required LatLng destination,
    String? routeId,
    String? googleApiKey,
    bool includeTraffic = true,
    bool includeElevation = true,
  }) async {
    try {
      state = const RouteCacheState.loading();

      // Check preferences
      final preferences = await RouteCacheService.getNavigationPreferences();
      
      // Try cache first if enabled
      if (preferences.cacheRoutes) {
        final cachedRoute = await RouteCacheService.getCachedRoute(
          origin: origin,
          destination: destination,
          routeId: routeId,
        );

        if (cachedRoute != null) {
          debugPrint('RouteCacheManager: Using cached route');
          state = RouteCacheState.success(cachedRoute, fromCache: true);
          return cachedRoute;
        }
      }

      // Fallback to enhanced route service
      debugPrint('RouteCacheManager: Calculating new route');
      final routeInfo = await EnhancedRouteService.calculateDetailedRoute(
        origin: origin,
        destination: destination,
        googleApiKey: googleApiKey,
        includeTraffic: includeTraffic,
        includeElevation: includeElevation,
      );

      if (routeInfo != null) {
        // Cache the new route if enabled
        if (preferences.cacheRoutes) {
          await cacheRoute(
            origin: origin,
            destination: destination,
            routeInfo: routeInfo,
            routeId: routeId,
          );
        }

        state = RouteCacheState.success(routeInfo, fromCache: false);
        return routeInfo;
      } else {
        state = const RouteCacheState.error('Failed to calculate route');
        return null;
      }
    } catch (e) {
      debugPrint('RouteCacheManager: Error getting route: $e');
      state = RouteCacheState.error('Error getting route: ${e.toString()}');
      return null;
    }
  }

  /// Save route for offline access
  Future<void> saveOfflineRoute({
    required String routeId,
    required LatLng origin,
    required LatLng destination,
    required DetailedRouteInfo routeInfo,
    String? routeName,
  }) async {
    try {
      await RouteCacheService.saveOfflineRoute(
        routeId: routeId,
        origin: origin,
        destination: destination,
        routeInfo: routeInfo,
        routeName: routeName,
      );

      state = state.copyWith(lastSavedOfflineRoute: routeId);
    } catch (e) {
      debugPrint('RouteCacheManager: Error saving offline route: $e');
      state = state.copyWith(error: 'Failed to save offline route: ${e.toString()}');
    }
  }

  /// Clear all cached routes
  Future<void> clearCache() async {
    try {
      await RouteCacheService.clearCache();
      state = state.copyWith(lastCachedRoute: null);
    } catch (e) {
      debugPrint('RouteCacheManager: Error clearing cache: $e');
      state = state.copyWith(error: 'Failed to clear cache: ${e.toString()}');
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  String _generateRouteKey(LatLng origin, LatLng destination) {
    return '${origin.latitude.toStringAsFixed(4)},${origin.longitude.toStringAsFixed(4)}_'
           '${destination.latitude.toStringAsFixed(4)},${destination.longitude.toStringAsFixed(4)}';
  }
}

/// State class for route cache management
class RouteCacheState {
  final DetailedRouteInfo? routeInfo;
  final bool isLoading;
  final bool fromCache;
  final String? error;
  final String? lastCachedRoute;
  final String? lastSavedOfflineRoute;

  const RouteCacheState._({
    this.routeInfo,
    this.isLoading = false,
    this.fromCache = false,
    this.error,
    this.lastCachedRoute,
    this.lastSavedOfflineRoute,
  });

  const RouteCacheState.initial() : this._();

  const RouteCacheState.loading() : this._(isLoading: true);

  const RouteCacheState.success(DetailedRouteInfo routeInfo, {bool fromCache = false}) 
      : this._(routeInfo: routeInfo, fromCache: fromCache);

  const RouteCacheState.error(String error) : this._(error: error);

  bool get hasRoute => routeInfo != null;
  bool get hasError => error != null;
  bool get isSuccess => hasRoute && !hasError && !isLoading;

  RouteCacheState copyWith({
    DetailedRouteInfo? routeInfo,
    bool? isLoading,
    bool? fromCache,
    String? error,
    String? lastCachedRoute,
    String? lastSavedOfflineRoute,
  }) {
    return RouteCacheState._(
      routeInfo: routeInfo ?? this.routeInfo,
      isLoading: isLoading ?? this.isLoading,
      fromCache: fromCache ?? this.fromCache,
      error: error,
      lastCachedRoute: lastCachedRoute ?? this.lastCachedRoute,
      lastSavedOfflineRoute: lastSavedOfflineRoute ?? this.lastSavedOfflineRoute,
    );
  }

  @override
  String toString() {
    return 'RouteCacheState(routeInfo: $routeInfo, isLoading: $isLoading, fromCache: $fromCache, error: $error)';
  }
}

/// Parameters for cached route lookup
class CachedRouteParams {
  final LatLng origin;
  final LatLng destination;
  final String? routeId;

  const CachedRouteParams({
    required this.origin,
    required this.destination,
    this.routeId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CachedRouteParams &&
        other.origin == origin &&
        other.destination == destination &&
        other.routeId == routeId;
  }

  @override
  int get hashCode => origin.hashCode ^ destination.hashCode ^ routeId.hashCode;
}
