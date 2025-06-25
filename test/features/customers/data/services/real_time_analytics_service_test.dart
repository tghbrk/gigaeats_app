import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:gigaeats_app/features/customers/data/services/real_time_analytics_service.dart';
import 'package:gigaeats_app/features/customers/data/repositories/customer_wallet_analytics_repository.dart';
import 'package:gigaeats_app/core/utils/logger.dart';

// Mock classes
class MockCustomerWalletAnalyticsRepository extends Mock implements CustomerWalletAnalyticsRepository {}
class MockAppLogger extends Mock implements AppLogger {}

void main() {
  group('RealTimeAnalyticsService', () {
    late RealTimeAnalyticsService service;
    late MockCustomerWalletAnalyticsRepository mockRepository;

    setUp(() {
      mockRepository = MockCustomerWalletAnalyticsRepository();
      service = RealTimeAnalyticsService(repository: mockRepository);
    });

    tearDown(() async {
      await service.dispose();
    });

    test('should initialize with repository', () {
      expect(service, isNotNull);
      expect(service.isSubscribed, isFalse);
    });

    test('should provide stream getters', () {
      expect(service.analyticsUpdates, isA<Stream<Map<String, dynamic>>>());
      expect(service.categoryUpdates, isA<Stream<List<Map<String, dynamic>>>>());
      expect(service.refreshViewsUpdates, isA<Stream<bool>>());
      expect(service.balanceUpdates, isA<Stream<Map<String, dynamic>>>());
      expect(service.transactionUpdates, isA<Stream<Map<String, dynamic>>>());
      expect(service.trendsUpdates, isA<Stream<List<Map<String, dynamic>>>>());
    });

    test('should provide subscription status', () {
      final status = service.subscriptionStatus;
      expect(status, isA<Map<String, bool>>());
      expect(status.containsKey('analytics_summary'), isTrue);
      expect(status.containsKey('spending_categories'), isTrue);
      expect(status.containsKey('refresh_notifications'), isTrue);
      expect(status.containsKey('is_subscribed'), isTrue);
    });

    test('should trigger analytics refresh', () {
      // This should not throw
      expect(() => service.triggerAnalyticsRefresh(), returnsNormally);
    });

    test('should handle pause and resume', () async {
      // These should not throw
      expect(() => service.pauseSubscriptions(), returnsNormally);
      expect(() => service.resumeSubscriptions(), returnsNormally);
    });

    test('should dispose cleanly', () async {
      // This should not throw
      await expectLater(service.dispose(), completes);
    });

    group('Real-time streams', () {
      test('should emit analytics updates', () async {
        // Listen to the stream
        final stream = service.analyticsUpdates;
        expect(stream, isA<Stream<Map<String, dynamic>>>());
        
        // The stream should be broadcast
        final subscription1 = stream.listen((_) {});
        final subscription2 = stream.listen((_) {});
        
        await subscription1.cancel();
        await subscription2.cancel();
      });

      test('should emit category updates', () async {
        final stream = service.categoryUpdates;
        expect(stream, isA<Stream<List<Map<String, dynamic>>>>());
        
        final subscription = stream.listen((_) {});
        await subscription.cancel();
      });

      test('should emit balance updates', () async {
        final stream = service.balanceUpdates;
        expect(stream, isA<Stream<Map<String, dynamic>>>());
        
        final subscription = stream.listen((_) {});
        await subscription.cancel();
      });

      test('should emit transaction updates', () async {
        final stream = service.transactionUpdates;
        expect(stream, isA<Stream<Map<String, dynamic>>>());
        
        final subscription = stream.listen((_) {});
        await subscription.cancel();
      });
    });

    group('Error handling', () {
      test('should handle initialization errors gracefully', () async {
        // Test that errors don't crash the service
        expect(() => service.triggerAnalyticsRefresh(), returnsNormally);
      });

      test('should handle disposal errors gracefully', () async {
        // Multiple dispose calls should not throw
        await service.dispose();
        await expectLater(service.dispose(), completes);
      });
    });
  });
}
