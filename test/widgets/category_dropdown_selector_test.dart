import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigaeats_app/src/features/menu/presentation/widgets/vendor/category_dialogs.dart';
import 'package:gigaeats_app/src/features/menu/data/models/menu_item.dart';
import 'package:gigaeats_app/src/features/menu/presentation/providers/menu_category_providers.dart';

void main() {
  group('CategoryDropdownSelector Layout Tests', () {
    late List<MenuCategory> mockCategories;

    setUp(() {
      mockCategories = [
        MenuCategory(
          id: 'cat1',
          vendorId: 'vendor1',
          name: 'Main Course',
          description: 'Main dishes',
          imageUrl: null,
          sortOrder: 1,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuCategory(
          id: 'cat2',
          vendorId: 'vendor1',
          name: 'Very Long Category Name That Should Truncate Properly',
          description: 'Long category name test',
          imageUrl: 'https://example.com/image.jpg',
          sortOrder: 2,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MenuCategory(
          id: 'cat3',
          vendorId: 'vendor1',
          name: 'Beverages',
          description: 'Drinks and beverages',
          imageUrl: null,
          sortOrder: 3,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    });

    testWidgets('CategoryDropdownSelector renders without layout errors', (WidgetTester tester) async {
      // Mock the provider
      final container = ProviderContainer(
        overrides: [
          vendorMenuCategoriesProvider('vendor1').overrideWith(
            (ref) => Future.value(mockCategories),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: CategoryDropdownSelector(
                vendorId: 'vendor1',
                selectedCategoryId: null,
                onCategorySelected: (categoryId) {},
                hintText: 'Select a category',
                allowEmpty: true,
              ),
            ),
          ),
        ),
      );

      // Wait for the provider to load
      await tester.pumpAndSettle();

      // Verify the dropdown is rendered
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      
      // Verify no layout overflow errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('CategoryDropdownSelector dropdown opens without layout errors', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          vendorMenuCategoriesProvider('vendor1').overrideWith(
            (ref) => Future.value(mockCategories),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: CategoryDropdownSelector(
                vendorId: 'vendor1',
                selectedCategoryId: null,
                onCategorySelected: (categoryId) {},
                hintText: 'Select a category',
                allowEmpty: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the dropdown to open it
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Verify dropdown items are rendered
      expect(find.text('No Category'), findsOneWidget);
      expect(find.text('Main Course'), findsOneWidget);
      expect(find.text('Very Long Category Name That Should Truncate Properly'), findsOneWidget);
      expect(find.text('Beverages'), findsOneWidget);

      // Verify no layout overflow errors when dropdown is open
      expect(tester.takeException(), isNull);
    });

    testWidgets('CategoryDropdownSelector handles long category names properly', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          vendorMenuCategoriesProvider('vendor1').overrideWith(
            (ref) => Future.value(mockCategories),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200, // Constrained width to test text overflow
                child: CategoryDropdownSelector(
                  vendorId: 'vendor1',
                  selectedCategoryId: null,
                  onCategorySelected: (categoryId) {},
                  hintText: 'Select a category',
                  allowEmpty: true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Verify long text is handled properly (should not cause overflow)
      expect(tester.takeException(), isNull);
      
      // Verify the long category name is present
      expect(find.text('Very Long Category Name That Should Truncate Properly'), findsOneWidget);
    });

    testWidgets('CategoryDropdownSelector selection works correctly', (WidgetTester tester) async {
      String? selectedCategoryId;
      
      final container = ProviderContainer(
        overrides: [
          vendorMenuCategoriesProvider('vendor1').overrideWith(
            (ref) => Future.value(mockCategories),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: CategoryDropdownSelector(
                vendorId: 'vendor1',
                selectedCategoryId: selectedCategoryId,
                onCategorySelected: (categoryId) {
                  selectedCategoryId = categoryId;
                },
                hintText: 'Select a category',
                allowEmpty: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open dropdown and select a category
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Main Course'));
      await tester.pumpAndSettle();

      // Verify selection callback was called
      expect(selectedCategoryId, equals('cat1'));
      
      // Verify no layout errors during selection
      expect(tester.takeException(), isNull);
    });

    testWidgets('CategoryDropdownSelector with pre-selected category', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          vendorMenuCategoriesProvider('vendor1').overrideWith(
            (ref) => Future.value(mockCategories),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: CategoryDropdownSelector(
                vendorId: 'vendor1',
                selectedCategoryId: 'cat2', // Pre-selected
                onCategorySelected: (categoryId) {},
                hintText: 'Select a category',
                allowEmpty: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify pre-selected category is displayed
      expect(find.text('Very Long Category Name That Should Truncate Properly'), findsOneWidget);
      
      // Verify no layout errors with pre-selection
      expect(tester.takeException(), isNull);
    });
  });
}
