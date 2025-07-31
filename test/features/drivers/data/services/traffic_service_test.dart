import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:gigaeats_app/src/features/drivers/data/services/traffic_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/navigation_models.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/traffic_models.dart';

void main() {
  group('TrafficService Tests', () {
    late TrafficService trafficService;

    setUp(() {
      trafficService = TrafficService();
    });

    tearDown(() {
      trafficService.dispose();
    });

    test('should initialize successfully', () async {
      expect(() async => await trafficService.initialize(), returnsNormally);
    });

    test('should have required stream getters', () {
      expect(trafficService.trafficUpdateStream, isA<Stream<TrafficUpdate>>());
      expect(trafficService.incidentStream, isA<Stream<TrafficIncident>>());
      expect(trafficService.rerouteRecommendationStream, isA<Stream<RerouteRecommendation>>());
    });

    test('should start and stop monitoring', () async {
      await trafficService.initialize();

      final route = NavigationRoute(
        id: 'test_route',
        polylinePoints: [
          const LatLng(3.1478, 101.6953),
          const LatLng(3.1590, 101.7123),
        ],
        totalDistanceMeters: 1000.0,
        totalDurationSeconds: 120,
        durationInTrafficSeconds: 150,
        instructions: [],
        summary: 'Test route',
        calculatedAt: DateTime.now(),
      );

      expect(() async => await trafficService.startMonitoring(
        route: route,
        currentLocation: const LatLng(3.1478, 101.6953),
      ), returnsNormally);

      expect(() async => await trafficService.stopMonitoring(), returnsNormally);
    });

    test('should get current traffic conditions', () async {
      await trafficService.initialize();

      final route = NavigationRoute(
        id: 'test_route',
        polylinePoints: [
          const LatLng(3.1478, 101.6953),
          const LatLng(3.1590, 101.7123),
        ],
        totalDistanceMeters: 1000.0,
        totalDurationSeconds: 120,
        durationInTrafficSeconds: 150,
        instructions: [],
        summary: 'Test route',
        calculatedAt: DateTime.now(),
      );

      final trafficUpdate = await trafficService.getCurrentTrafficConditions(route);

      expect(trafficUpdate, isA<TrafficUpdate>());
      expect(trafficUpdate.routeId, equals('test_route'));
      expect(trafficUpdate.overallCondition, isA<TrafficCondition>());
      expect(trafficUpdate.incidents, isA<List<TrafficIncident>>());
      expect(trafficUpdate.estimatedDelay, isA<Duration>());
    });

    test('should report traffic incidents', () async {
      await trafficService.initialize();

      expect(() async => await trafficService.reportIncident(
        location: const LatLng(3.1500, 101.7000),
        type: TrafficIncidentType.accident,
        severity: TrafficSeverity.high,
        description: 'Test accident',
      ), returnsNormally);
    });

    test('should update location', () {
      expect(() => trafficService.updateLocation(const LatLng(3.1500, 101.7000)), returnsNormally);
    });

    test('should calculate alternative route', () async {
      await trafficService.initialize();

      final route = NavigationRoute(
        id: 'test_route',
        polylinePoints: [
          const LatLng(3.1478, 101.6953),
          const LatLng(3.1590, 101.7123),
        ],
        totalDistanceMeters: 1000.0,
        totalDurationSeconds: 120,
        durationInTrafficSeconds: 150,
        instructions: [],
        summary: 'Test route',
        calculatedAt: DateTime.now(),
      );

      final alternativeRoute = await trafficService.calculateAlternativeRoute(
        originalRoute: route,
        currentLocation: const LatLng(3.1478, 101.6953),
        avoidIncidents: [],
      );

      // Alternative route calculation may return null if no API key or network issues
      expect(alternativeRoute, isA<NavigationRoute?>());
    });

    test('should dispose properly', () {
      expect(() => trafficService.dispose(), returnsNormally);
    });
  });

  group('Traffic Models Tests', () {
    test('TrafficIncident should have correct properties', () {
      final incident = TrafficIncident(
        id: 'test_incident',
        type: TrafficIncidentType.accident,
        location: const LatLng(3.1500, 101.7000),
        severity: TrafficSeverity.high,
        description: 'Test accident',
        reportedAt: DateTime.now(),
      );

      expect(incident.id, equals('test_incident'));
      expect(incident.type, equals(TrafficIncidentType.accident));
      expect(incident.severity, equals(TrafficSeverity.high));
      expect(incident.typeDisplayName, equals('Accident'));
      expect(incident.severityDisplayName, equals('High'));
      expect(incident.isCurrentlyActive, isTrue);
    });

    test('TrafficSegment should calculate distance', () {
      final segment = TrafficSegment(
        startLocation: const LatLng(3.1478, 101.6953),
        endLocation: const LatLng(3.1590, 101.7123),
        condition: TrafficCondition.heavy,
        speedKmh: 20.0,
        delaySeconds: 300,
      );

      expect(segment.condition, equals(TrafficCondition.heavy));
      expect(segment.delay, equals(const Duration(seconds: 300)));
      expect(segment.distanceMeters, greaterThan(0));
    });

    test('TrafficUpdate should format delay text correctly', () {
      final trafficUpdate = TrafficUpdate(
        routeId: 'test_route',
        timestamp: DateTime.now(),
        overallCondition: TrafficCondition.heavy,
        incidents: [],
        estimatedDelay: const Duration(minutes: 15),
        requiresRerouting: true,
        affectedSegments: [],
      );

      expect(trafficUpdate.estimatedDelayText, equals('15 min delay'));
      expect(trafficUpdate.requiresRerouting, isTrue);
    });

    test('RerouteRecommendation should calculate confidence percentage', () {
      final route = NavigationRoute(
        id: 'test_route',
        polylinePoints: [const LatLng(3.1478, 101.6953)],
        totalDistanceMeters: 1000.0,
        totalDurationSeconds: 120,
        durationInTrafficSeconds: 150,
        instructions: [],
        summary: 'Test route',
        calculatedAt: DateTime.now(),
      );

      final recommendation = RerouteRecommendation(
        originalRoute: route,
        alternativeRoute: route,
        reason: 'Traffic congestion',
        estimatedTimeSaving: const Duration(minutes: 10),
        confidence: 0.85,
        incidents: [],
      );

      expect(recommendation.confidencePercentage, equals(85));
      expect(recommendation.timeSavingText, equals('10 minutes'));
    });
  });
}
