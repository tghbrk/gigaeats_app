import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigaeats_app/src/features/menu/data/models/customization_template.dart';

/// Test utilities and helpers for customization template testing
class TemplateTestHelpers {
  /// Test configuration constants
  static const testConfig = {
    'supabaseUrl': 'https://abknoalhfltlhhdbclpv.supabase.co',
    'testVendorId': 'test-vendor-123',
    'testMenuItemId': 'test-menu-item-123',
    'testTemplateId': 'test-template-123',
  };

  /// Create a test ProviderContainer with mock overrides
  static ProviderContainer createTestContainer({
    List<Override> overrides = const [],
  }) {
    return ProviderContainer(
      overrides: overrides,
    );
  }

  /// Create a test MaterialApp wrapper for widget testing
  static Widget createTestApp({
    required Widget child,
    List<Override> providerOverrides = const [],
  }) {
    return ProviderScope(
      overrides: providerOverrides,
      child: MaterialApp(
        home: child,
      ),
    );
  }

  /// Create a mock CustomizationTemplate for testing
  static CustomizationTemplate createMockTemplate({
    String? id,
    String? vendorId,
    String? name,
    String? description,
    String? category,
    bool? isRequired,
    bool? allowMultiple,
    int? displayOrder,
    bool? isActive,
    int? usageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomizationTemplate(
      id: id ?? 'test-template-${DateTime.now().millisecondsSinceEpoch}',
      vendorId: vendorId ?? 'test-vendor-${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Test Template',
      description: description ?? 'Test template description',
      isRequired: isRequired ?? false,
      displayOrder: displayOrder ?? 0,
      isActive: isActive ?? true,
      usageCount: usageCount ?? 0,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Create a mock TemplateOption for testing
  static TemplateOption createMockOption({
    String? id,
    String? templateId,
    String? name,
    String? description,
    double? price,
    int? displayOrder,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TemplateOption(
      id: id ?? 'test-option-${DateTime.now().millisecondsSinceEpoch}',
      templateId: templateId ?? 'test-template-${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Test Option',
      additionalPrice: price ?? 0.0,
      displayOrder: displayOrder ?? 0,
      isAvailable: isAvailable ?? true,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Create a mock MenuItemTemplateLink for testing
  static MenuItemTemplateLink createMockLink({
    String? id,
    String? menuItemId,
    String? templateId,
    DateTime? createdAt,
  }) {
    return MenuItemTemplateLink(
      id: id ?? 'test-link-${DateTime.now().millisecondsSinceEpoch}',
      menuItemId: menuItemId ?? 'test-menu-item-${DateTime.now().millisecondsSinceEpoch}',
      templateId: templateId ?? 'test-template-${DateTime.now().millisecondsSinceEpoch}',
      linkedAt: createdAt ?? DateTime.now(),
    );
  }

  /// Create a complete template with options for testing
  static Map<String, dynamic> createCompleteTemplateData({
    String? vendorId,
    String? name,
    List<Map<String, dynamic>>? options,
  }) {
    return {
      'template': {
        'vendor_id': vendorId ?? 'test-vendor',
        'name': name ?? 'Complete Test Template',
        'description': 'A complete template for testing',
        'category': 'test',
        'is_required': true,
        'allow_multiple': false,
        'display_order': 1,
      },
      'options': options ?? [
        {
          'name': 'Small',
          'description': 'Small size',
          'price': 0.0,
          'display_order': 1,
        },
        {
          'name': 'Medium',
          'description': 'Medium size',
          'price': 2.50,
          'display_order': 2,
        },
        {
          'name': 'Large',
          'description': 'Large size',
          'price': 5.00,
          'display_order': 3,
        },
      ],
    };
  }

  /// Verify template data matches expected values
  static void verifyTemplateData(
    CustomizationTemplate template,
    Map<String, dynamic> expectedData,
  ) {
    expect(template.vendorId, equals(expectedData['vendor_id']));
    expect(template.name, equals(expectedData['name']));
    expect(template.description, equals(expectedData['description']));
    expect(template.category, equals(expectedData['category']));
    expect(template.isRequired, equals(expectedData['is_required'] ?? false));
    expect(template.allowMultiple, equals(expectedData['allow_multiple'] ?? false));
    expect(template.displayOrder, equals(expectedData['display_order'] ?? 0));
    expect(template.isActive, equals(expectedData['is_active'] ?? true));
  }

  /// Verify option data matches expected values
  static void verifyOptionData(
    TemplateOption option,
    Map<String, dynamic> expectedData,
  ) {
    expect(option.templateId, equals(expectedData['template_id']));
    expect(option.name, equals(expectedData['name']));
    expect(option.additionalPrice, equals(expectedData['additional_price'] ?? 0.0));
    expect(option.price, equals(expectedData['additional_price'] ?? 0.0)); // Backward compatibility getter
    expect(option.displayOrder, equals(expectedData['display_order'] ?? 0));
    expect(option.isAvailable, equals(expectedData['is_available'] ?? true));
  }

  /// Wait for async operations to complete
  static Future<void> waitForAsyncOperations(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  }

  /// Find widget by text with retry logic
  static Future<Finder> findTextWithRetry(
    WidgetTester tester,
    String text, {
    int maxRetries = 3,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      await tester.pumpAndSettle();
      final finder = find.text(text);
      if (finder.evaluate().isNotEmpty) {
        return finder;
      }
      if (i < maxRetries - 1) {
        await Future.delayed(delay);
      }
    }
    return find.text(text);
  }

  /// Tap widget with retry logic
  static Future<void> tapWithRetry(
    WidgetTester tester,
    Finder finder, {
    int maxRetries = 3,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        await tester.tap(finder);
        await tester.pumpAndSettle();
        return;
      } catch (e) {
        if (i < maxRetries - 1) {
          await Future.delayed(delay);
          await tester.pumpAndSettle();
        } else {
          rethrow;
        }
      }
    }
  }

  /// Enter text with validation
  static Future<void> enterTextSafely(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
    
    // Verify text was entered
    final widget = tester.widget<TextField>(finder);
    expect(widget.controller?.text ?? '', equals(text));
  }

  /// Scroll to widget if needed
  static Future<void> scrollToWidget(
    WidgetTester tester,
    Finder finder, {
    Finder? scrollable,
  }) async {
    final scrollableFinder = scrollable ?? find.byType(Scrollable);
    if (scrollableFinder.evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(
        finder,
        500.0,
        scrollable: scrollableFinder,
      );
      await tester.pumpAndSettle();
    }
  }

  /// Verify loading state
  static void verifyLoadingState(WidgetTester tester) {
    expect(
      find.byType(CircularProgressIndicator),
      findsOneWidget,
    );
  }

  /// Verify error state
  static void verifyErrorState(WidgetTester tester, String? errorMessage) {
    expect(find.byIcon(Icons.error), findsOneWidget);
    if (errorMessage != null) {
      expect(find.text(errorMessage), findsOneWidget);
    }
  }

  /// Verify empty state
  static void verifyEmptyState(WidgetTester tester, String? emptyMessage) {
    if (emptyMessage != null) {
      expect(find.text(emptyMessage), findsOneWidget);
    }
    expect(find.byType(ListView), findsNothing);
  }

  /// Generate test data for performance testing
  static List<CustomizationTemplate> generateTestTemplates(int count) {
    return List.generate(count, (index) => createMockTemplate(
      id: 'perf-template-$index',
      name: 'Performance Test Template $index',
      description: 'Template $index for performance testing',
      usageCount: index * 2,
      displayOrder: index,
    ));
  }

  /// Generate test options for a template
  static List<TemplateOption> generateTestOptions(String templateId, int count) {
    return List.generate(count, (index) => createMockOption(
      id: 'perf-option-$index',
      templateId: templateId,
      name: 'Option $index',
      price: index * 1.5,
      displayOrder: index,
    ));
  }

  /// Cleanup test data
  static Future<void> cleanupTestData(List<String> templateIds) async {
    // This would typically call the repository to clean up test data
    // For now, we'll just log the cleanup
    print('🧹 Cleaning up test templates: ${templateIds.join(', ')}');
  }

  /// Log test progress
  static void logTestProgress(String message) {
    print('🧪 TEST: $message');
  }

  /// Log test success
  static void logTestSuccess(String message) {
    print('✅ SUCCESS: $message');
  }

  /// Log test failure
  static void logTestFailure(String message) {
    print('❌ FAILURE: $message');
  }

  /// Measure test performance
  static Future<T> measurePerformance<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      stopwatch.stop();
      print('⏱️ PERFORMANCE: $operationName took ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      stopwatch.stop();
      print('⏱️ PERFORMANCE: $operationName failed after ${stopwatch.elapsedMilliseconds}ms');
      rethrow;
    }
  }
}
