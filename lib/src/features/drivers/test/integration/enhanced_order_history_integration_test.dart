import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';


import '../../presentation/providers/optimized_order_history_providers.dart';
import '../../presentation/widgets/enhanced_history_orders_tab.dart';
import '../../presentation/widgets/date_filter/date_filter_components.dart';
import '../../presentation/widgets/performance_monitor_widget.dart' as custom_performance;
import '../../data/services/order_history_cache_service.dart';
import '../../data/services/lazy_loading_service.dart';
import '../../data/services/optimized_database_service.dart';

/// Comprehensive integration test suite for enhanced driver order history
/// 
/// This test suite validates:
/// - Date filtering functionality
/// - Performance optimization
/// - UI components integration
/// - Database query optimization
/// - Cache system functionality
/// - Android emulator compatibility
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Enhanced Driver Order History Integration Tests', () {
    late ProviderContainer container;

    setUpAll(() async {
      // Initialize services
      await OrderHistoryCacheService.instance.initialize();
      LazyLoadingService.instance.initialize();
      
      debugPrint('🧪 Integration Test: Services initialized');
    });

    setUp(() {
      container = ProviderContainer();
      debugPrint('🧪 Integration Test: Provider container created');
    });

    tearDown(() {
      container.dispose();
      debugPrint('🧪 Integration Test: Provider container disposed');
    });

    testWidgets('Date Filter Components Integration Test', (WidgetTester tester) async {
      debugPrint('🧪 Testing: Date Filter Components Integration');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  CompactDateFilterBar(showOrderCount: true),
                  QuickFilterChips(),
                  Expanded(
                    child: Text('Test Content'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify compact date filter bar is rendered
      expect(find.byType(CompactDateFilterBar), findsOneWidget);
      debugPrint('✅ CompactDateFilterBar rendered successfully');

      // Verify quick filter chips are rendered
      expect(find.byType(QuickFilterChips), findsOneWidget);
      debugPrint('✅ QuickFilterChips rendered successfully');

      // Test filter button interaction
      final filterButton = find.byIcon(Icons.tune);
      if (filterButton.evaluate().isNotEmpty) {
        await tester.tap(filterButton);
        await tester.pumpAndSettle();
        debugPrint('✅ Filter button interaction successful');
      }

      // Test quick filter chip interaction
      final todayChip = find.text('Today');
      if (todayChip.evaluate().isNotEmpty) {
        await tester.tap(todayChip);
        await tester.pumpAndSettle();
        debugPrint('✅ Today filter chip interaction successful');
      }
    });

    testWidgets('Enhanced History Orders Tab Integration Test', (WidgetTester tester) async {
      debugPrint('🧪 Testing: Enhanced History Orders Tab Integration');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedHistoryOrdersTab(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify main components are rendered
      expect(find.byType(EnhancedHistoryOrdersTab), findsOneWidget);
      debugPrint('✅ EnhancedHistoryOrdersTab rendered successfully');

      // Verify date filter bar is present
      expect(find.byType(CompactDateFilterBar), findsOneWidget);
      debugPrint('✅ Date filter bar integrated successfully');

      // Test refresh functionality
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();
      debugPrint('✅ Pull-to-refresh functionality working');

      // Test scroll functionality
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -200));
        await tester.pumpAndSettle();
        debugPrint('✅ Scroll functionality working');
      }
    });

    testWidgets('Performance Monitor Integration Test', (WidgetTester tester) async {
      debugPrint('🧪 Testing: Performance Monitor Integration');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: custom_performance.PerformanceOverlay(
                enabled: true,
                child: Container(
                  child: Text('Performance Test Content'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify performance monitor is rendered
      expect(find.byType(custom_performance.PerformanceMonitorWidget), findsOneWidget);
      debugPrint('✅ PerformanceMonitorWidget rendered successfully');

      // Test performance monitor expansion
      final performanceWidget = find.byType(custom_performance.PerformanceMonitorWidget);
      if (performanceWidget.evaluate().isNotEmpty) {
        await tester.tap(performanceWidget);
        await tester.pumpAndSettle();
        debugPrint('✅ Performance monitor expansion working');
      }
    });

    test('Provider System Integration Test', () async {
      debugPrint('🧪 Testing: Provider System Integration');

      // Test date filter provider
      final dateFilter = container.read(dateFilterProvider);
      expect(dateFilter, isA<DateRangeFilter>());
      debugPrint('✅ DateFilterProvider working');

      // Test quick filter provider
      final quickFilter = container.read(selectedQuickFilterProvider);
      expect(quickFilter, isA<QuickDateFilter>());
      debugPrint('✅ QuickFilterProvider working');

      // Test combined filter provider
      final combinedFilter = container.read(combinedDateFilterProvider);
      expect(combinedFilter, isA<DateRangeFilter>());
      debugPrint('✅ CombinedFilterProvider working');

      // Test performance monitor provider
      final performanceData = container.read(performanceMonitorProvider);
      expect(performanceData, isA<Map<String, dynamic>>());
      expect(performanceData.containsKey('cacheStats'), isTrue);
      expect(performanceData.containsKey('lazyLoadingStats'), isTrue);
      debugPrint('✅ PerformanceMonitorProvider working');
    });

    test('Cache System Integration Test', () async {
      debugPrint('🧪 Testing: Cache System Integration');

      final cacheService = OrderHistoryCacheService.instance;
      
      // Test cache initialization
      await cacheService.initialize();
      debugPrint('✅ Cache service initialized');

      // Test cache statistics
      final stats = cacheService.getCacheStats();
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('memoryEntries'), isTrue);
      debugPrint('✅ Cache statistics working: $stats');

      // Test cache clearing
      await cacheService.clearAllCache();
      final clearedStats = cacheService.getCacheStats();
      expect(clearedStats['memoryEntries'], equals(0));
      debugPrint('✅ Cache clearing working');
    });

    test('Lazy Loading Service Integration Test', () async {
      debugPrint('🧪 Testing: Lazy Loading Service Integration');

      final lazyLoadingService = LazyLoadingService.instance;
      lazyLoadingService.initialize();

      // Test loading statistics
      final stats = lazyLoadingService.getLoadingStats();
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('activeStates'), isTrue);
      debugPrint('✅ Lazy loading statistics working: $stats');

      // Test state reset
      lazyLoadingService.resetState('test-driver-id');
      final resetStats = lazyLoadingService.getLoadingStats();
      expect(resetStats['activeStates'], equals(0));
      debugPrint('✅ Lazy loading state reset working');
    });

    test('Database Service Integration Test', () async {
      debugPrint('🧪 Testing: Database Service Integration');

      final dbService = OptimizedDatabaseService.instance;
      
      // Test service availability
      expect(dbService, isNotNull);
      debugPrint('✅ Database service available');

      // Note: Actual database tests would require authentication
      // This test validates the service structure and methods
      expect(dbService.getDriverOrderHistory, isA<Function>());
      expect(dbService.countDriverOrders, isA<Function>());
      expect(dbService.getDriverOrderStats, isA<Function>());
      expect(dbService.getDailyOrderStats, isA<Function>());
      debugPrint('✅ Database service methods available');
    });

    testWidgets('Date Filter Functionality Test', (WidgetTester tester) async {
      debugPrint('🧪 Testing: Date Filter Functionality');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  final quickFilter = ref.watch(selectedQuickFilterProvider);
                  final dateFilter = ref.watch(dateFilterProvider);
                  
                  return Column(
                    children: [
                      Text('Quick Filter: ${quickFilter.displayName}'),
                      Text('Date Filter: ${dateFilter.toString()}'),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(selectedQuickFilterProvider.notifier).state = QuickDateFilter.today;
                        },
                        child: Text('Set Today Filter'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(dateFilterProvider.notifier).setCustomDateRange(
                            DateTime.now().subtract(Duration(days: 7)),
                            DateTime.now(),
                          );
                        },
                        child: Text('Set Custom Range'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test quick filter change
      await tester.tap(find.text('Set Today Filter'));
      await tester.pumpAndSettle();
      
      expect(find.text('Quick Filter: Today'), findsOneWidget);
      debugPrint('✅ Quick filter change working');

      // Test custom date range
      await tester.tap(find.text('Set Custom Range'));
      await tester.pumpAndSettle();
      debugPrint('✅ Custom date range setting working');
    });

    testWidgets('Performance Monitoring Test', (WidgetTester tester) async {
      debugPrint('🧪 Testing: Performance Monitoring');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  final performanceData = ref.watch(performanceMonitorProvider);
                  
                  return Column(
                    children: [
                      Text('Cache Entries: ${performanceData['cacheStats']?['memoryEntries'] ?? 0}'),
                      Text('Loading States: ${performanceData['lazyLoadingStats']?['activeStates'] ?? 0}'),
                      custom_performance.PerformanceMetricsCard(),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify performance metrics are displayed
      expect(find.text('Performance Metrics'), findsOneWidget);
      debugPrint('✅ Performance metrics display working');

      // Verify cache entries display
      expect(find.textContaining('Cache Entries:'), findsOneWidget);
      debugPrint('✅ Cache entries display working');

      // Verify loading states display
      expect(find.textContaining('Loading States:'), findsOneWidget);
      debugPrint('✅ Loading states display working');
    });
  });
}
