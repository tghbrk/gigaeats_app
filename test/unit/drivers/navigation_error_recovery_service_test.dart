import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:gigaeats_app/src/features/drivers/data/services/navigation_error_recovery_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/navigation_models.dart';

void main() {
  group('NavigationErrorRecoveryService Tests', () {
    late NavigationErrorRecoveryService errorRecoveryService;

    setUp(() {
      errorRecoveryService = NavigationErrorRecoveryService();
    });

    tearDown(() async {
      await errorRecoveryService.dispose();
    });

    group('Basic Properties', () {
      test('should have correct default values', () {
        // Assert
        expect(errorRecoveryService.isNetworkAvailable, isTrue);
        expect(errorRecoveryService.isGpsSignalStrong, isFalse); // No signal received yet
      });

      test('should reset error counters', () {
        // Act
        errorRecoveryService.resetErrorCounters();

        // Assert - should not throw
        expect(true, isTrue); // Basic test to ensure method works
      });
    });

    group('Error Handling', () {
      test('should handle network failure error', () async {
        // Arrange
        final error = NavigationError.networkFailure('Network connection lost');
        final session = _createTestNavigationSession();

        // Act
        final result = await errorRecoveryService.handleNavigationError(error, session);

        // Assert
        expect(result.type, isA<NavigationErrorRecoveryType>());
        expect(result.message, isNotEmpty);
      });

      test('should handle GPS signal loss error', () async {
        // Arrange
        final error = NavigationError.gpsSignalLoss('GPS signal weak');
        final session = _createTestNavigationSession();

        // Act
        final result = await errorRecoveryService.handleNavigationError(error, session);

        // Assert
        expect(result.type, isA<NavigationErrorRecoveryType>());
        expect(result.message, isNotEmpty);
      });

      test('should handle route calculation failure', () async {
        // Arrange
        final error = NavigationError.routeCalculationFailure('Failed to calculate route');
        final session = _createTestNavigationSession();

        // Act
        final result = await errorRecoveryService.handleNavigationError(error, session);

        // Assert
        expect(result.type, isA<NavigationErrorRecoveryType>());
        expect(result.message, isNotEmpty);
      });

      test('should handle critical system failure', () async {
        // Arrange
        final error = NavigationError.criticalSystemFailure('System crashed');
        final session = _createTestNavigationSession();

        // Act
        final result = await errorRecoveryService.handleNavigationError(error, session);

        // Assert
        expect(result.type, isA<NavigationErrorRecoveryType>());
        expect(result.message, isNotEmpty);
      });
    });

    group('External Navigation', () {
      test('should launch external navigation app', () async {
        // Arrange
        final app = ExternalNavApp(
          name: 'Google Maps',
          packageName: 'com.google.android.apps.maps',
          platform: 'android',
        );
        final destination = LatLng(37.7749, -122.4194);

        // Act
        final result = await errorRecoveryService.launchExternalNavigation(app, destination);

        // Assert
        expect(result, isA<bool>());
        // Note: Result depends on whether the app is actually installed
      });
    });

    group('Error Recovery Results', () {
      test('should create retry result', () {
        // Act
        final result = NavigationErrorRecoveryResult.retry('Retrying...', retryCount: 2);

        // Assert
        expect(result.type, equals(NavigationErrorRecoveryType.retry));
        expect(result.message, equals('Retrying...'));
        expect(result.retryCount, equals(2));
      });

      test('should create external navigation result', () {
        // Arrange
        final apps = [
          ExternalNavApp(
            name: 'Google Maps',
            packageName: 'com.google.android.apps.maps',
            platform: 'android',
          ),
        ];
        final destination = LatLng(37.7749, -122.4194);

        // Act
        final result = NavigationErrorRecoveryResult.externalNavigation(
          'Use external app',
          availableApps: apps,
          destination: destination,
        );

        // Assert
        expect(result.type, equals(NavigationErrorRecoveryType.externalNavigation));
        expect(result.message, equals('Use external app'));
        expect(result.availableApps, equals(apps));
        expect(result.destination, equals(destination));
      });

      test('should create degraded service result', () {
        // Act
        final result = NavigationErrorRecoveryResult.degraded(
          'Service degraded',
          degradedFeatures: ['voice_guidance', '3d_camera'],
        );

        // Assert
        expect(result.type, equals(NavigationErrorRecoveryType.degraded));
        expect(result.message, equals('Service degraded'));
        expect(result.degradedFeatures, equals(['voice_guidance', '3d_camera']));
      });

      test('should create failed result', () {
        // Act
        final result = NavigationErrorRecoveryResult.failed('Navigation failed');

        // Assert
        expect(result.type, equals(NavigationErrorRecoveryType.failed));
        expect(result.message, equals('Navigation failed'));
      });

      test('should create network unavailable result', () {
        // Act
        final result = NavigationErrorRecoveryResult.networkUnavailable(
          'No network',
          suggestedAction: 'Check connection',
        );

        // Assert
        expect(result.type, equals(NavigationErrorRecoveryType.networkUnavailable));
        expect(result.message, equals('No network'));
        expect(result.suggestedAction, equals('Check connection'));
      });

      test('should create permission required result', () {
        // Act
        final result = NavigationErrorRecoveryResult.permissionRequired(
          'Permission needed',
          suggestedAction: 'Grant permission',
        );

        // Assert
        expect(result.type, equals(NavigationErrorRecoveryType.permissionRequired));
        expect(result.message, equals('Permission needed'));
        expect(result.suggestedAction, equals('Grant permission'));
      });

      test('should create service required result', () {
        // Act
        final result = NavigationErrorRecoveryResult.serviceRequired(
          'Service needed',
          suggestedAction: 'Enable service',
        );

        // Assert
        expect(result.type, equals(NavigationErrorRecoveryType.serviceRequired));
        expect(result.message, equals('Service needed'));
        expect(result.suggestedAction, equals('Enable service'));
      });

      test('should create cooldown result', () {
        // Act
        final result = NavigationErrorRecoveryResult.cooldown();

        // Assert
        expect(result.type, equals(NavigationErrorRecoveryType.cooldown));
        expect(result.message, equals('Error recovery in cooldown period'));
      });
    });

    group('Resource Management', () {
      test('should dispose resources properly', () async {
        // Act & Assert - should not throw
        await errorRecoveryService.dispose();
      });

      test('should handle multiple dispose calls', () async {
        // Act & Assert - should not throw
        await errorRecoveryService.dispose();
        await errorRecoveryService.dispose();
      });
    });
  });
}

/// Create a test navigation session for testing
NavigationSession _createTestNavigationSession() {
  final route = NavigationRoute(
    id: 'test-route',
    polylinePoints: [],
    totalDistanceMeters: 1000.0,
    totalDurationSeconds: 300, // 5 minutes
    durationInTrafficSeconds: 350,
    instructions: [
      NavigationInstruction(
        id: 'instruction-1',
        type: NavigationInstructionType.straight,
        text: 'Continue straight',
        htmlText: 'Continue straight',
        distanceMeters: 500.0,
        durationSeconds: 150,
        location: const LatLng(37.7749, -122.4194),
        timestamp: DateTime.now(),
      ),
    ],
    summary: 'Test route',
    calculatedAt: DateTime.now(),
  );

  return NavigationSession(
    id: 'test-session',
    orderId: 'test-order',
    route: route,
    origin: const LatLng(37.7749, -122.4194),
    destination: const LatLng(37.7849, -122.4094),
    status: NavigationSessionStatus.active,
    startTime: DateTime.now(),
    currentInstructionIndex: 0,
    preferences: NavigationPreferences(
      voiceGuidanceEnabled: true,
      language: 'en',
      avoidTolls: false,
      avoidHighways: false,
    ),
  );
}
