import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:gigaeats_app/src/features/drivers/data/services/enhanced_3d_navigation_camera_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/navigation_models.dart';

void main() {
  group('Enhanced3DNavigationCameraService Tests', () {
    late Enhanced3DNavigationCameraService cameraService;

    setUp(() {
      cameraService = Enhanced3DNavigationCameraService();
    });

    tearDown(() async {
      await cameraService.dispose();
    });

    group('Basic Properties', () {
      test('should have correct default values', () {
        // Assert
        expect(cameraService.isFollowingLocation, isTrue);
        expect(cameraService.currentBearing, equals(0.0));
        expect(cameraService.currentZoom, equals(18.0));
      });

      test('should allow enabling and disabling location following', () {
        // Act
        cameraService.setLocationFollowing(false);

        // Assert
        expect(cameraService.isFollowingLocation, isFalse);

        // Act
        cameraService.setLocationFollowing(true);

        // Assert
        expect(cameraService.isFollowingLocation, isTrue);
      });
    });

    group('Error Handling', () {
      test('should throw exception when starting navigation without initialization', () async {
        // Arrange
        final uninitializedService = Enhanced3DNavigationCameraService();
        final session = _createTestNavigationSession();

        // Act & Assert
        expect(
          () => uninitializedService.startNavigationCamera(session),
          throwsException,
        );
      });

      test('should handle disposal without initialization', () async {
        // Arrange
        final uninitializedService = Enhanced3DNavigationCameraService();

        // Act & Assert - should not throw
        await uninitializedService.dispose();
      });

      test('should handle multiple dispose calls', () async {
        // Act & Assert - should not throw
        await cameraService.dispose();
        await cameraService.dispose();
      });
    });
  });
}

/// Create a test navigation session for testing
NavigationSession _createTestNavigationSession() {
  final route = NavigationRoute(
    id: 'test-route',
    polylinePoints: [],
    totalDistanceMeters: 800.0,
    totalDurationSeconds: 180, // 3 minutes
    durationInTrafficSeconds: 200,
    instructions: [
      NavigationInstruction(
        id: 'instruction-1',
        type: NavigationInstructionType.straight,
        text: 'Head north on Market Street',
        htmlText: 'Head north on <b>Market Street</b>',
        distanceMeters: 500.0,
        durationSeconds: 120, // 2 minutes
        location: const LatLng(37.7749, -122.4194),
        timestamp: DateTime.now(),
      ),
      NavigationInstruction(
        id: 'instruction-2',
        type: NavigationInstructionType.turnRight,
        text: 'Turn right onto Main Street',
        htmlText: 'Turn right onto <b>Main Street</b>',
        distanceMeters: 300.0,
        durationSeconds: 60, // 1 minute
        location: const LatLng(37.7799, -122.4194),
        timestamp: DateTime.now(),
      ),
    ],
    summary: 'Route via Market Street and Main Street',
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
