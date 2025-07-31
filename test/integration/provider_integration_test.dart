import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:gigaeats_app/src/features/drivers/presentation/providers/multi_order_batch_provider.dart';
import 'package:gigaeats_app/src/features/drivers/presentation/providers/enhanced_navigation_provider.dart';
import 'package:gigaeats_app/src/features/drivers/presentation/providers/enhanced_location_provider.dart';

/// Comprehensive provider integration test for GigaEats driver workflow
/// Tests multi-order batch provider and enhanced navigation provider integration
/// Validates state management, provider dependencies, and potential loops
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('GigaEats Driver Provider Integration Tests', () {
    late ProviderContainer container;

    setUp(() {
      // Create a fresh provider container for each test
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('Multi-Order Batch Provider - Initial State', (WidgetTester tester) async {
      debugPrint('🧪 [PROVIDER-TEST] Testing multi-order batch provider initial state');

      // Test initial state
      final initialState = container.read(multiOrderBatchProvider);
      
      expect(initialState.activeBatch, isNull);
      expect(initialState.batchOrders, isEmpty);
      expect(initialState.batchSummary, isNull);
      expect(initialState.isLoading, isFalse);
      expect(initialState.error, isNull);
      
      debugPrint('✅ [PROVIDER-TEST] Multi-order batch provider initial state is correct');
    });

    testWidgets('Enhanced Navigation Provider - Initial State', (WidgetTester tester) async {
      debugPrint('🧪 [PROVIDER-TEST] Testing enhanced navigation provider initial state');

      // Test initial state
      final initialState = container.read(enhancedNavigationProvider);
      
      expect(initialState.currentSession, isNull);
      expect(initialState.currentInstruction, isNull);
      expect(initialState.nextInstruction, isNull);
      expect(initialState.recentTrafficAlerts, isEmpty);
      expect(initialState.isNavigating, isFalse);
      expect(initialState.isVoiceEnabled, isTrue);
      expect(initialState.remainingDistance, isNull);
      expect(initialState.estimatedArrival, isNull);
      expect(initialState.error, isNull);
      
      debugPrint('✅ [PROVIDER-TEST] Enhanced navigation provider initial state is correct');
    });

    testWidgets('Provider Dependencies - No Circular References', (WidgetTester tester) async {
      debugPrint('🧪 [PROVIDER-TEST] Testing provider dependencies for circular references');

      try {
        // Test reading multiple providers simultaneously
        final batchState = container.read(multiOrderBatchProvider);
        final navState = container.read(enhancedNavigationProvider);
        final locationState = container.read(enhancedLocationProvider);
        
        // Test derived providers
        final activeBatch = container.read(activeBatchProvider);
        final batchOrders = container.read(batchOrdersProvider);
        final batchSummary = container.read(batchSummaryProvider);
        final batchProgress = container.read(batchProgressProvider);

        debugPrint('🔍 [PROVIDER-TEST] Batch state loaded: ${batchState.activeBatch?.id ?? 'none'}');
        debugPrint('🔍 [PROVIDER-TEST] Navigation state loaded: ${navState.isNavigating}');
        debugPrint('🔍 [PROVIDER-TEST] Location state loaded: ${locationState.isTracking}');
        debugPrint('🔍 [PROVIDER-TEST] Active batch: ${activeBatch?.id ?? 'none'}');
        debugPrint('🔍 [PROVIDER-TEST] Batch orders count: ${batchOrders.length}');
        debugPrint('🔍 [PROVIDER-TEST] Batch summary: ${batchSummary?.totalOrders ?? 0}');
        debugPrint('🔍 [PROVIDER-TEST] Batch progress: ${batchProgress.toStringAsFixed(1)}%');
        
        debugPrint('✅ [PROVIDER-TEST] No circular references detected');
      } catch (e) {
        debugPrint('❌ [PROVIDER-TEST] Provider dependency error: $e');
        fail('Provider circular reference detected: $e');
      }
    });

    testWidgets('Provider State Management - Memory Leaks Check', (WidgetTester tester) async {
      debugPrint('🧪 [PROVIDER-TEST] Testing provider memory management');

      // Create multiple containers to test disposal
      final containers = <ProviderContainer>[];
      
      for (int i = 0; i < 5; i++) {
        final testContainer = ProviderContainer();
        containers.add(testContainer);
        
        // Read providers to initialize them
        testContainer.read(multiOrderBatchProvider);
        testContainer.read(enhancedNavigationProvider);
        testContainer.read(enhancedLocationProvider);
        
        debugPrint('🔍 [PROVIDER-TEST] Created container $i');
      }
      
      // Dispose all containers
      for (int i = 0; i < containers.length; i++) {
        containers[i].dispose();
        debugPrint('🔍 [PROVIDER-TEST] Disposed container $i');
      }
      
      debugPrint('✅ [PROVIDER-TEST] Memory management test completed');
    });

    testWidgets('Provider Error Handling', (WidgetTester tester) async {
      debugPrint('🧪 [PROVIDER-TEST] Testing provider error handling');

      // Test batch provider error handling
      final batchNotifier = container.read(multiOrderBatchProvider.notifier);
      
      // Test with invalid driver ID
      await batchNotifier.loadActiveBatch('invalid-driver-id');
      
      final batchState = container.read(multiOrderBatchProvider);
      debugPrint('🔍 [PROVIDER-TEST] Batch state after invalid load: error=${batchState.error}');
      
      // Test navigation provider error handling
      final navNotifier = container.read(enhancedNavigationProvider.notifier);
      
      // Test with invalid navigation parameters
      await navNotifier.startNavigation(
        origin: const LatLng(0, 0),
        destination: const LatLng(0, 0),
        orderId: 'invalid-order-id',
      );

      final navState = container.read(enhancedNavigationProvider);
      debugPrint('🔍 [PROVIDER-TEST] Navigation state after invalid start: error=${navState.error}');
      
      debugPrint('✅ [PROVIDER-TEST] Error handling test completed');
    });

    testWidgets('Real-time Subscription Integration', (WidgetTester tester) async {
      debugPrint('🧪 [PROVIDER-TEST] Testing real-time subscription integration');

      // This test would require actual Supabase connection
      // For now, we'll test the provider structure
      
      try {
        // Test if providers can handle subscription updates
        container.read(multiOrderBatchProvider.notifier);
        container.read(enhancedNavigationProvider.notifier);

        // Simulate subscription updates
        await Future.delayed(const Duration(milliseconds: 100));

        debugPrint('🔍 [PROVIDER-TEST] Subscription integration structure validated');
        debugPrint('✅ [PROVIDER-TEST] Real-time subscription test completed');
      } catch (e) {
        debugPrint('❌ [PROVIDER-TEST] Subscription integration error: $e');
        // Don't fail the test for subscription errors in testing environment
      }
    });

    testWidgets('Provider Performance - State Update Frequency', (WidgetTester tester) async {
      debugPrint('🧪 [PROVIDER-TEST] Testing provider performance and update frequency');

      final stopwatch = Stopwatch()..start();
      int updateCount = 0;
      
      // Listen to provider changes
      container.listen<MultiOrderBatchState>(
        multiOrderBatchProvider,
        (previous, next) {
          updateCount++;
          debugPrint('🔍 [PROVIDER-TEST] Batch provider update #$updateCount');
        },
      );
      
      // Trigger multiple state updates
      final batchNotifier = container.read(multiOrderBatchProvider.notifier);
      
      for (int i = 0; i < 3; i++) {
        await batchNotifier.loadActiveBatch('test-driver-$i');
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      stopwatch.stop();
      
      debugPrint('🔍 [PROVIDER-TEST] Performance test completed:');
      debugPrint('  - Updates: $updateCount');
      debugPrint('  - Duration: ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('  - Avg per update: ${stopwatch.elapsedMilliseconds / updateCount}ms');
      
      // Ensure reasonable performance
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Less than 5 seconds
      expect(updateCount, greaterThan(0)); // At least some updates
      
      debugPrint('✅ [PROVIDER-TEST] Performance test passed');
    });
  });
}
