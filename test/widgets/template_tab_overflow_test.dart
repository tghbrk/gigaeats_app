import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigaeats_app/src/features/menu/presentation/widgets/vendor/enhanced_template_selector.dart';


void main() {
  group('Template Selection TabBar Overflow Tests', () {

    testWidgets('TabBar renders without overflow errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedTemplateSelector(
                vendorId: 'vendor1',
                selectedTemplateIds: [],
                onTemplatesSelected: (templates) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no overflow errors
      expect(tester.takeException(), isNull);

      // Verify TabBar is present
      expect(find.byType(TabBar), findsOneWidget);

      // Verify tab titles are displayed
      expect(find.text('Browse Templates'), findsOneWidget);
      expect(find.text('Selected Templates'), findsOneWidget);

      // Verify tab icons are displayed
      expect(find.byIcon(Icons.grid_view), findsOneWidget);
      expect(find.byIcon(Icons.checklist), findsOneWidget);
    });

    testWidgets('Tab switching works without layout violations', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedTemplateSelector(
                vendorId: 'vendor1',
                selectedTemplateIds: [],
                onTemplatesSelected: (templates) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial state (Browse tab should be active)
      expect(tester.takeException(), isNull);

      // Tap on Selected Templates tab
      await tester.tap(find.text('Selected Templates'));
      await tester.pumpAndSettle();

      // Verify no overflow errors after tab switch
      expect(tester.takeException(), isNull);

      // Tap back to Browse Templates tab
      await tester.tap(find.text('Browse Templates'));
      await tester.pumpAndSettle();

      // Verify no overflow errors after switching back
      expect(tester.takeException(), isNull);
    });

    testWidgets('TabBar handles constrained width correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300, // Constrained width
                child: EnhancedTemplateSelector(
                  vendorId: 'vendor1',
                  selectedTemplateIds: [],
                  onTemplatesSelected: (templates) {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no overflow errors with constrained width
      expect(tester.takeException(), isNull);

      // Verify tabs are still functional
      expect(find.text('Browse Templates'), findsOneWidget);
      expect(find.text('Selected Templates'), findsOneWidget);

      // Test tab switching with constrained width
      await tester.tap(find.text('Selected Templates'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('TabBar handles very narrow width with text truncation', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200, // Very narrow width
                child: EnhancedTemplateSelector(
                  vendorId: 'vendor1',
                  selectedTemplateIds: [],
                  onTemplatesSelected: (templates) {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no overflow errors with very narrow width
      expect(tester.takeException(), isNull);

      // Verify TabBar is still present
      expect(find.byType(TabBar), findsOneWidget);

      // Tab text might be truncated but should still be findable
      expect(find.textContaining('Browse'), findsOneWidget);
      expect(find.textContaining('Selected'), findsOneWidget);
    });

    testWidgets('TabBar maintains proper height constraints', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedTemplateSelector(
                vendorId: 'vendor1',
                selectedTemplateIds: [],
                onTemplatesSelected: (templates) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the Container that wraps the TabBar
      final containerFinder = find.ancestor(
        of: find.byType(TabBar),
        matching: find.byType(Container),
      );

      expect(containerFinder, findsOneWidget);

      // Verify the Container has the expected height
      final container = tester.widget<Container>(containerFinder);
      expect(container.constraints?.maxHeight, 48.0);
    });

    testWidgets('TabBar with selected templates displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedTemplateSelector(
                vendorId: 'vendor1',
                selectedTemplateIds: ['template1'], // Pre-selected template
                onTemplatesSelected: (templates) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no overflow errors with pre-selected templates
      expect(tester.takeException(), isNull);

      // Switch to Selected Templates tab
      await tester.tap(find.text('Selected Templates'));
      await tester.pumpAndSettle();

      // Verify no overflow errors in selected tab
      expect(tester.takeException(), isNull);

      // Verify selected template is displayed
      expect(find.text('Test Template 1'), findsOneWidget);
    });

    testWidgets('TabBar handles empty template list correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedTemplateSelector(
                vendorId: 'vendor1',
                selectedTemplateIds: [],
                onTemplatesSelected: (templates) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no overflow errors with empty template list
      expect(tester.takeException(), isNull);

      // Verify TabBar is still present
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Browse Templates'), findsOneWidget);
      expect(find.text('Selected Templates'), findsOneWidget);

      // Test tab switching with empty list
      await tester.tap(find.text('Selected Templates'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('TabBar handles rapid tab switching without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedTemplateSelector(
                vendorId: 'vendor1',
                selectedTemplateIds: [],
                onTemplatesSelected: (templates) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Perform rapid tab switching
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('Selected Templates'));
        await tester.pump(const Duration(milliseconds: 100));
        
        await tester.tap(find.text('Browse Templates'));
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.pumpAndSettle();

      // Verify no overflow errors after rapid switching
      expect(tester.takeException(), isNull);
    });
  });
}
