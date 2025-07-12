import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'enhanced_route_service.dart';

/// Service for caching route information and navigation preferences
class RouteCacheService {
  static const String _routeCacheKey = 'cached_routes';
  static const String _preferencesKey = 'navigation_preferences';
  static const String _offlineRoutesKey = 'offline_routes';
  static const Duration _cacheExpiry = Duration(hours: 2);
  static const int _maxCachedRoutes = 50;

  /// Cache a route calculation result
  static Future<void> cacheRoute({
    required LatLng origin,
    required LatLng destination,
    required DetailedRouteInfo routeInfo,
    String? routeId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = routeId ?? _generateRouteKey(origin, destination);
      
      final cachedRoute = CachedRoute(
        id: cacheKey,
        origin: origin,
        destination: destination,
        routeInfo: routeInfo,
        cachedAt: DateTime.now(),
        expiresAt: DateTime.now().add(_cacheExpiry),
      );

      // Get existing cache
      final existingCache = await _getCachedRoutes();
      
      // Add new route and remove expired ones
      existingCache[cacheKey] = cachedRoute;
      await _cleanExpiredRoutes(existingCache);
      
      // Limit cache size
      if (existingCache.length > _maxCachedRoutes) {
        await _limitCacheSize(existingCache);
      }

      // Save updated cache
      final cacheJson = existingCache.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString(_routeCacheKey, jsonEncode(cacheJson));
      
      debugPrint('🗺️ RouteCacheService: Cached route $cacheKey');
    } catch (e) {
      debugPrint('🗺️ RouteCacheService: Error caching route: $e');
    }
  }

  /// Get cached route if available and not expired
  static Future<DetailedRouteInfo?> getCachedRoute({
    required LatLng origin,
    required LatLng destination,
    String? routeId,
  }) async {
    try {
      final cacheKey = routeId ?? _generateRouteKey(origin, destination);
      final cachedRoutes = await _getCachedRoutes();
      
      final cachedRoute = cachedRoutes[cacheKey];
      if (cachedRoute == null) {
        return null;
      }

      // Check if expired
      if (DateTime.now().isAfter(cachedRoute.expiresAt)) {
        debugPrint('🗺️ RouteCacheService: Cached route $cacheKey expired');
        await _removeCachedRoute(cacheKey);
        return null;
      }

      debugPrint('🗺️ RouteCacheService: Retrieved cached route $cacheKey');
      return cachedRoute.routeInfo;
    } catch (e) {
      debugPrint('🗺️ RouteCacheService: Error getting cached route: $e');
      return null;
    }
  }

  /// Save navigation preferences
  static Future<void> saveNavigationPreferences(NavigationPreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_preferencesKey, jsonEncode(preferences.toJson()));
      debugPrint('🗺️ RouteCacheService: Navigation preferences saved');
    } catch (e) {
      debugPrint('🗺️ RouteCacheService: Error saving preferences: $e');
    }
  }

  /// Get navigation preferences
  static Future<NavigationPreferences> getNavigationPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsJson = prefs.getString(_preferencesKey);
      
      if (prefsJson != null) {
        final prefsMap = jsonDecode(prefsJson) as Map<String, dynamic>;
        return NavigationPreferences.fromJson(prefsMap);
      }
    } catch (e) {
      debugPrint('🗺️ RouteCacheService: Error getting preferences: $e');
    }
    
    return NavigationPreferences.defaultPreferences();
  }

  /// Save route for offline access
  static Future<void> saveOfflineRoute({
    required String routeId,
    required LatLng origin,
    required LatLng destination,
    required DetailedRouteInfo routeInfo,
    String? routeName,
  }) async {
    try {
      final offlineRoute = OfflineRoute(
        id: routeId,
        name: routeName ?? 'Route to ${_formatCoordinates(destination)}',
        origin: origin,
        destination: destination,
        routeInfo: routeInfo,
        savedAt: DateTime.now(),
      );

      // Save to file system for larger storage
      final file = await _getOfflineRouteFile(routeId);
      await file.writeAsString(jsonEncode(offlineRoute.toJson()));

      // Update offline routes index
      await _updateOfflineRoutesIndex(offlineRoute);
      
      debugPrint('🗺️ RouteCacheService: Saved offline route $routeId');
    } catch (e) {
      debugPrint('🗺️ RouteCacheService: Error saving offline route: $e');
    }
  }

  /// Get offline route
  static Future<OfflineRoute?> getOfflineRoute(String routeId) async {
    try {
      final file = await _getOfflineRouteFile(routeId);
      if (!await file.exists()) {
        return null;
      }

      final routeJson = await file.readAsString();
      final routeMap = jsonDecode(routeJson) as Map<String, dynamic>;
      return OfflineRoute.fromJson(routeMap);
    } catch (e) {
      debugPrint('🗺️ RouteCacheService: Error getting offline route: $e');
      return null;
    }
  }

  /// List all offline routes
  static Future<List<OfflineRoute>> listOfflineRoutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final indexJson = prefs.getString(_offlineRoutesKey);
      
      if (indexJson == null) {
        return [];
      }

      final indexList = jsonDecode(indexJson) as List<dynamic>;
      final routes = <OfflineRoute>[];

      for (final routeData in indexList) {
        try {
          final route = OfflineRoute.fromJson(routeData as Map<String, dynamic>);
          routes.add(route);
        } catch (e) {
          debugPrint('🗺️ RouteCacheService: Error parsing offline route: $e');
        }
      }

      return routes;
    } catch (e) {
      debugPrint('🗺️ RouteCacheService: Error listing offline routes: $e');
      return [];
    }
  }

  /// Delete offline route
  static Future<void> deleteOfflineRoute(String routeId) async {
    try {
      // Delete file
      final file = await _getOfflineRouteFile(routeId);
      if (await file.exists()) {
        await file.delete();
      }

      // Update index
      final routes = await listOfflineRoutes();
      routes.removeWhere((route) => route.id == routeId);
      await _saveOfflineRoutesIndex(routes);
      
      debugPrint('🗺️ RouteCacheService: Deleted offline route $routeId');
    } catch (e) {
      debugPrint('🗺️ RouteCacheService: Error deleting offline route: $e');
    }
  }

  /// Clear all cached routes
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_routeCacheKey);
      debugPrint('🗺️ RouteCacheService: Cache cleared');
    } catch (e) {
      debugPrint('🗺️ RouteCacheService: Error clearing cache: $e');
    }
  }

  /// Get cache statistics
  static Future<CacheStatistics> getCacheStatistics() async {
    try {
      final cachedRoutes = await _getCachedRoutes();
      final offlineRoutes = await listOfflineRoutes();
      
      final now = DateTime.now();
      final expiredCount = cachedRoutes.values
          .where((route) => now.isAfter(route.expiresAt))
          .length;

      return CacheStatistics(
        cachedRoutesCount: cachedRoutes.length,
        offlineRoutesCount: offlineRoutes.length,
        expiredRoutesCount: expiredCount,
        cacheSize: await _calculateCacheSize(),
      );
    } catch (e) {
      debugPrint('🗺️ RouteCacheService: Error getting cache statistics: $e');
      return CacheStatistics.empty();
    }
  }

  // Private helper methods

  static String _generateRouteKey(LatLng origin, LatLng destination) {
    return '${origin.latitude.toStringAsFixed(4)},${origin.longitude.toStringAsFixed(4)}_'
           '${destination.latitude.toStringAsFixed(4)},${destination.longitude.toStringAsFixed(4)}';
  }

  static Future<Map<String, CachedRoute>> _getCachedRoutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_routeCacheKey);
      
      if (cacheJson == null) {
        return {};
      }

      final cacheMap = jsonDecode(cacheJson) as Map<String, dynamic>;
      return cacheMap.map((key, value) => 
          MapEntry(key, CachedRoute.fromJson(value as Map<String, dynamic>)));
    } catch (e) {
      debugPrint('🗺️ RouteCacheService: Error getting cached routes: $e');
      return {};
    }
  }

  static Future<void> _cleanExpiredRoutes(Map<String, CachedRoute> cache) async {
    final now = DateTime.now();
    cache.removeWhere((key, route) => now.isAfter(route.expiresAt));
  }

  static Future<void> _limitCacheSize(Map<String, CachedRoute> cache) async {
    if (cache.length <= _maxCachedRoutes) return;

    // Sort by cache time and remove oldest
    final sortedEntries = cache.entries.toList()
      ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));

    final toRemove = sortedEntries.length - _maxCachedRoutes;
    for (int i = 0; i < toRemove; i++) {
      cache.remove(sortedEntries[i].key);
    }
  }

  static Future<void> _removeCachedRoute(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedRoutes = await _getCachedRoutes();
      cachedRoutes.remove(cacheKey);
      
      final cacheJson = cachedRoutes.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString(_routeCacheKey, jsonEncode(cacheJson));
    } catch (e) {
      debugPrint('🗺️ RouteCacheService: Error removing cached route: $e');
    }
  }

  static Future<File> _getOfflineRouteFile(String routeId) async {
    final directory = await getApplicationDocumentsDirectory();
    final routesDir = Directory('${directory.path}/offline_routes');
    if (!await routesDir.exists()) {
      await routesDir.create(recursive: true);
    }
    return File('${routesDir.path}/$routeId.json');
  }

  static Future<void> _updateOfflineRoutesIndex(OfflineRoute route) async {
    final routes = await listOfflineRoutes();
    routes.removeWhere((r) => r.id == route.id);
    routes.add(route);
    await _saveOfflineRoutesIndex(routes);
  }

  static Future<void> _saveOfflineRoutesIndex(List<OfflineRoute> routes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final indexJson = routes.map((route) => route.toJson()).toList();
      await prefs.setString(_offlineRoutesKey, jsonEncode(indexJson));
    } catch (e) {
      debugPrint('🗺️ RouteCacheService: Error saving offline routes index: $e');
    }
  }

  static String _formatCoordinates(LatLng coordinates) {
    return '${coordinates.latitude.toStringAsFixed(4)}, ${coordinates.longitude.toStringAsFixed(4)}';
  }

  static Future<int> _calculateCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_routeCacheKey);
      return cacheJson?.length ?? 0;
    } catch (e) {
      return 0;
    }
  }
}

/// Cached route data model
class CachedRoute {
  final String id;
  final LatLng origin;
  final LatLng destination;
  final DetailedRouteInfo routeInfo;
  final DateTime cachedAt;
  final DateTime expiresAt;

  const CachedRoute({
    required this.id,
    required this.origin,
    required this.destination,
    required this.routeInfo,
    required this.cachedAt,
    required this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'origin': {'lat': origin.latitude, 'lng': origin.longitude},
      'destination': {'lat': destination.latitude, 'lng': destination.longitude},
      'routeInfo': routeInfo.toJson(),
      'cachedAt': cachedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory CachedRoute.fromJson(Map<String, dynamic> json) {
    return CachedRoute(
      id: json['id'] as String,
      origin: LatLng(
        json['origin']['lat'] as double,
        json['origin']['lng'] as double,
      ),
      destination: LatLng(
        json['destination']['lat'] as double,
        json['destination']['lng'] as double,
      ),
      routeInfo: DetailedRouteInfo.fromJson(json['routeInfo'] as Map<String, dynamic>),
      cachedAt: DateTime.parse(json['cachedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}

/// Offline route data model
class OfflineRoute {
  final String id;
  final String name;
  final LatLng origin;
  final LatLng destination;
  final DetailedRouteInfo routeInfo;
  final DateTime savedAt;

  const OfflineRoute({
    required this.id,
    required this.name,
    required this.origin,
    required this.destination,
    required this.routeInfo,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'origin': {'lat': origin.latitude, 'lng': origin.longitude},
      'destination': {'lat': destination.latitude, 'lng': destination.longitude},
      'routeInfo': routeInfo.toJson(),
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory OfflineRoute.fromJson(Map<String, dynamic> json) {
    return OfflineRoute(
      id: json['id'] as String,
      name: json['name'] as String,
      origin: LatLng(
        json['origin']['lat'] as double,
        json['origin']['lng'] as double,
      ),
      destination: LatLng(
        json['destination']['lat'] as double,
        json['destination']['lng'] as double,
      ),
      routeInfo: DetailedRouteInfo.fromJson(json['routeInfo'] as Map<String, dynamic>),
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }
}

/// Navigation preferences model
class NavigationPreferences {
  final String preferredNavigationApp;
  final bool avoidTolls;
  final bool avoidHighways;
  final bool avoidFerries;
  final String units; // metric, imperial
  final bool showTrafficAlerts;
  final bool cacheRoutes;
  final bool useOfflineRoutes;

  const NavigationPreferences({
    required this.preferredNavigationApp,
    required this.avoidTolls,
    required this.avoidHighways,
    required this.avoidFerries,
    required this.units,
    required this.showTrafficAlerts,
    required this.cacheRoutes,
    required this.useOfflineRoutes,
  });

  factory NavigationPreferences.defaultPreferences() {
    return const NavigationPreferences(
      preferredNavigationApp: 'in_app',
      avoidTolls: false,
      avoidHighways: false,
      avoidFerries: false,
      units: 'metric',
      showTrafficAlerts: true,
      cacheRoutes: true,
      useOfflineRoutes: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preferredNavigationApp': preferredNavigationApp,
      'avoidTolls': avoidTolls,
      'avoidHighways': avoidHighways,
      'avoidFerries': avoidFerries,
      'units': units,
      'showTrafficAlerts': showTrafficAlerts,
      'cacheRoutes': cacheRoutes,
      'useOfflineRoutes': useOfflineRoutes,
    };
  }

  factory NavigationPreferences.fromJson(Map<String, dynamic> json) {
    return NavigationPreferences(
      preferredNavigationApp: json['preferredNavigationApp'] as String? ?? 'in_app',
      avoidTolls: json['avoidTolls'] as bool? ?? false,
      avoidHighways: json['avoidHighways'] as bool? ?? false,
      avoidFerries: json['avoidFerries'] as bool? ?? false,
      units: json['units'] as String? ?? 'metric',
      showTrafficAlerts: json['showTrafficAlerts'] as bool? ?? true,
      cacheRoutes: json['cacheRoutes'] as bool? ?? true,
      useOfflineRoutes: json['useOfflineRoutes'] as bool? ?? false,
    );
  }

  NavigationPreferences copyWith({
    String? preferredNavigationApp,
    bool? avoidTolls,
    bool? avoidHighways,
    bool? avoidFerries,
    String? units,
    bool? showTrafficAlerts,
    bool? cacheRoutes,
    bool? useOfflineRoutes,
  }) {
    return NavigationPreferences(
      preferredNavigationApp: preferredNavigationApp ?? this.preferredNavigationApp,
      avoidTolls: avoidTolls ?? this.avoidTolls,
      avoidHighways: avoidHighways ?? this.avoidHighways,
      avoidFerries: avoidFerries ?? this.avoidFerries,
      units: units ?? this.units,
      showTrafficAlerts: showTrafficAlerts ?? this.showTrafficAlerts,
      cacheRoutes: cacheRoutes ?? this.cacheRoutes,
      useOfflineRoutes: useOfflineRoutes ?? this.useOfflineRoutes,
    );
  }
}

/// Cache statistics model
class CacheStatistics {
  final int cachedRoutesCount;
  final int offlineRoutesCount;
  final int expiredRoutesCount;
  final int cacheSize;

  const CacheStatistics({
    required this.cachedRoutesCount,
    required this.offlineRoutesCount,
    required this.expiredRoutesCount,
    required this.cacheSize,
  });

  factory CacheStatistics.empty() {
    return const CacheStatistics(
      cachedRoutesCount: 0,
      offlineRoutesCount: 0,
      expiredRoutesCount: 0,
      cacheSize: 0,
    );
  }

  String get formattedCacheSize {
    if (cacheSize < 1024) {
      return '${cacheSize}B';
    } else if (cacheSize < 1024 * 1024) {
      return '${(cacheSize / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(cacheSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }
}
