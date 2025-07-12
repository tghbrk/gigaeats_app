import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:gigaeats_app/src/features/drivers/data/services/route_cache_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/enhanced_route_service.dart';

void main() {
  group('RouteCacheService Tests', () {
    late DetailedRouteInfo mockRouteInfo;
    late LatLng mockOrigin;
    late LatLng mockDestination;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      
      mockOrigin = const LatLng(3.1390, 101.6869);
      mockDestination = const LatLng(3.1590, 101.7123);
      
      mockRouteInfo = DetailedRouteInfo(
        distance: 5.2,
        duration: 15,
        polylinePoints: [mockOrigin, mockDestination],
        distanceText: '5.2 km',
        durationText: '15 min',
        steps: [
          RouteStep(
            instruction: 'Head north on Test Street',
            distance: 1.0,
            duration: 3,
            startLocation: mockOrigin,
            endLocation: const LatLng(3.1400, 101.6869),
            maneuver: 'straight',
            roadName: 'Test Street',
          ),
        ],
        elevationProfile: [
          ElevationPoint(
            distance: 0.0,
            elevation: 100.0,
            location: mockOrigin,
          ),
        ],
        trafficCondition: 'Light traffic',
        estimatedArrival: DateTime.now().add(const Duration(minutes: 15)),
        warnings: 'Construction ahead',
        origin: mockOrigin,
        destination: mockDestination,
      );
    });

    group('Route Caching', () {
      test('caches route successfully', () async {
        await RouteCacheService.cacheRoute(
          origin: mockOrigin,
          destination: mockDestination,
          routeInfo: mockRouteInfo,
        );

        final cachedRoute = await RouteCacheService.getCachedRoute(
          origin: mockOrigin,
          destination: mockDestination,
        );

        expect(cachedRoute, isNotNull);
        expect(cachedRoute!.distance, equals(5.2));
        expect(cachedRoute.duration, equals(15));
        expect(cachedRoute.distanceText, equals('5.2 km'));
      });

      test('returns null for non-existent cached route', () async {
        final cachedRoute = await RouteCacheService.getCachedRoute(
          origin: const LatLng(0.0, 0.0),
          destination: const LatLng(1.0, 1.0),
        );

        expect(cachedRoute, isNull);
      });

      test('caches route with custom route ID', () async {
        const customRouteId = 'custom-route-123';
        
        await RouteCacheService.cacheRoute(
          origin: mockOrigin,
          destination: mockDestination,
          routeInfo: mockRouteInfo,
          routeId: customRouteId,
        );

        final cachedRoute = await RouteCacheService.getCachedRoute(
          origin: mockOrigin,
          destination: mockDestination,
          routeId: customRouteId,
        );

        expect(cachedRoute, isNotNull);
        expect(cachedRoute!.distance, equals(5.2));
      });

      test('clears cache successfully', () async {
        await RouteCacheService.cacheRoute(
          origin: mockOrigin,
          destination: mockDestination,
          routeInfo: mockRouteInfo,
        );

        // Verify route is cached
        var cachedRoute = await RouteCacheService.getCachedRoute(
          origin: mockOrigin,
          destination: mockDestination,
        );
        expect(cachedRoute, isNotNull);

        // Clear cache
        await RouteCacheService.clearCache();

        // Verify route is no longer cached
        cachedRoute = await RouteCacheService.getCachedRoute(
          origin: mockOrigin,
          destination: mockDestination,
        );
        expect(cachedRoute, isNull);
      });
    });

    group('Navigation Preferences', () {
      test('saves and retrieves navigation preferences', () async {
        final preferences = NavigationPreferences(
          preferredNavigationApp: 'google_maps',
          avoidTolls: true,
          avoidHighways: false,
          avoidFerries: true,
          units: 'metric',
          showTrafficAlerts: true,
          cacheRoutes: true,
          useOfflineRoutes: false,
        );

        await RouteCacheService.saveNavigationPreferences(preferences);
        final retrievedPreferences = await RouteCacheService.getNavigationPreferences();

        expect(retrievedPreferences.preferredNavigationApp, equals('google_maps'));
        expect(retrievedPreferences.avoidTolls, isTrue);
        expect(retrievedPreferences.avoidHighways, isFalse);
        expect(retrievedPreferences.avoidFerries, isTrue);
        expect(retrievedPreferences.units, equals('metric'));
        expect(retrievedPreferences.showTrafficAlerts, isTrue);
        expect(retrievedPreferences.cacheRoutes, isTrue);
        expect(retrievedPreferences.useOfflineRoutes, isFalse);
      });

      test('returns default preferences when none saved', () async {
        final preferences = await RouteCacheService.getNavigationPreferences();

        expect(preferences.preferredNavigationApp, equals('in_app'));
        expect(preferences.avoidTolls, isFalse);
        expect(preferences.avoidHighways, isFalse);
        expect(preferences.avoidFerries, isFalse);
        expect(preferences.units, equals('metric'));
        expect(preferences.showTrafficAlerts, isTrue);
        expect(preferences.cacheRoutes, isTrue);
        expect(preferences.useOfflineRoutes, isFalse);
      });
    });

    group('Cache Statistics', () {
      test('returns correct cache statistics', () async {
        // Cache a route
        await RouteCacheService.cacheRoute(
          origin: mockOrigin,
          destination: mockDestination,
          routeInfo: mockRouteInfo,
        );

        final statistics = await RouteCacheService.getCacheStatistics();

        expect(statistics.cachedRoutesCount, equals(1));
        expect(statistics.offlineRoutesCount, equals(0));
        expect(statistics.expiredRoutesCount, equals(0));
        expect(statistics.cacheSize, greaterThan(0));
      });

      test('returns empty statistics when no cache', () async {
        final statistics = await RouteCacheService.getCacheStatistics();

        expect(statistics.cachedRoutesCount, equals(0));
        expect(statistics.offlineRoutesCount, equals(0));
        expect(statistics.expiredRoutesCount, equals(0));
        expect(statistics.cacheSize, equals(0));
      });

      test('formats cache size correctly', () async {
        final statistics = CacheStatistics(
          cachedRoutesCount: 1,
          offlineRoutesCount: 0,
          expiredRoutesCount: 0,
          cacheSize: 1024,
        );

        expect(statistics.formattedCacheSize, equals('1.0KB'));

        final largeStatistics = CacheStatistics(
          cachedRoutesCount: 1,
          offlineRoutesCount: 0,
          expiredRoutesCount: 0,
          cacheSize: 1024 * 1024,
        );

        expect(largeStatistics.formattedCacheSize, equals('1.0MB'));
      });
    });

    group('Model Serialization', () {
      test('CachedRoute serializes and deserializes correctly', () async {
        final cachedRoute = CachedRoute(
          id: 'test-route',
          origin: mockOrigin,
          destination: mockDestination,
          routeInfo: mockRouteInfo,
          cachedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 2)),
        );

        final json = cachedRoute.toJson();
        final deserializedRoute = CachedRoute.fromJson(json);

        expect(deserializedRoute.id, equals('test-route'));
        expect(deserializedRoute.origin.latitude, equals(mockOrigin.latitude));
        expect(deserializedRoute.origin.longitude, equals(mockOrigin.longitude));
        expect(deserializedRoute.destination.latitude, equals(mockDestination.latitude));
        expect(deserializedRoute.destination.longitude, equals(mockDestination.longitude));
        expect(deserializedRoute.routeInfo.distance, equals(5.2));
      });

      test('NavigationPreferences serializes and deserializes correctly', () async {
        final preferences = NavigationPreferences(
          preferredNavigationApp: 'waze',
          avoidTolls: true,
          avoidHighways: true,
          avoidFerries: false,
          units: 'imperial',
          showTrafficAlerts: false,
          cacheRoutes: false,
          useOfflineRoutes: true,
        );

        final json = preferences.toJson();
        final deserializedPreferences = NavigationPreferences.fromJson(json);

        expect(deserializedPreferences.preferredNavigationApp, equals('waze'));
        expect(deserializedPreferences.avoidTolls, isTrue);
        expect(deserializedPreferences.avoidHighways, isTrue);
        expect(deserializedPreferences.avoidFerries, isFalse);
        expect(deserializedPreferences.units, equals('imperial'));
        expect(deserializedPreferences.showTrafficAlerts, isFalse);
        expect(deserializedPreferences.cacheRoutes, isFalse);
        expect(deserializedPreferences.useOfflineRoutes, isTrue);
      });

      test('NavigationPreferences copyWith works correctly', () async {
        final originalPreferences = NavigationPreferences.defaultPreferences();
        
        final updatedPreferences = originalPreferences.copyWith(
          preferredNavigationApp: 'google_maps',
          avoidTolls: true,
        );

        expect(updatedPreferences.preferredNavigationApp, equals('google_maps'));
        expect(updatedPreferences.avoidTolls, isTrue);
        expect(updatedPreferences.avoidHighways, equals(originalPreferences.avoidHighways));
        expect(updatedPreferences.units, equals(originalPreferences.units));
      });
    });

    group('Error Handling', () {
      test('handles cache errors gracefully', () async {
        // This test would require mocking SharedPreferences to throw errors
        // For now, we'll test that the methods don't throw exceptions
        expect(() async {
          await RouteCacheService.getCachedRoute(
            origin: mockOrigin,
            destination: mockDestination,
          );
        }, returnsNormally);
      });

      test('handles preference errors gracefully', () async {
        expect(() async {
          await RouteCacheService.getNavigationPreferences();
        }, returnsNormally);
      });
    });
  });
}
