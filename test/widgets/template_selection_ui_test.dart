import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigaeats_app/src/features/menu/presentation/widgets/vendor/enhanced_template_selector.dart';
import 'package:gigaeats_app/src/features/menu/presentation/widgets/vendor/enhanced_customization_section.dart';
import 'package:gigaeats_app/src/features/menu/presentation/widgets/vendor/template_preview_card.dart';
import 'package:gigaeats_app/src/features/menu/data/models/customization_template.dart';

void main() {
  group('Template Selection UI Text Color Tests', () {
    late CustomizationTemplate mockTemplate;

    setUp(() {
      mockTemplate = CustomizationTemplate(
        id: 'template1',
        vendorId: 'vendor1',
        name: 'Test Template Name',
        description: 'Test template description',
        type: 'single',
        isRequired: true,
        displayOrder: 1,
        isActive: true,
        options: [
          TemplateOption(
            id: 'opt1',
            templateId: 'template1',
            name: 'Option 1',
            additionalPrice: 2.50,
            displayOrder: 1,
            isAvailable: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
        usageCount: 5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('EnhancedTemplateSelector displays text with proper colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.green,
                brightness: Brightness.light,
              ),
            ),
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

      // Find the template name text
      final templateNameFinder = find.text('Test Template Name');
      expect(templateNameFinder, findsWidgets);

      // Verify the text widget has proper styling
      final textWidget = tester.widget<Text>(templateNameFinder.first);
      expect(textWidget.style?.color, isNotNull);
      
      // Verify no rendering errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('EnhancedCustomizationSection displays text with proper colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.green,
                brightness: Brightness.light,
              ),
            ),
            home: Scaffold(
              body: EnhancedCustomizationSection(
                linkedTemplates: [mockTemplate],
                onTemplatesChanged: (templates) {},
                vendorId: 'vendor1',
                menuItemName: 'Test Menu Item',
                basePrice: 10.00,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the template name in ExpansionTile
      final templateNameFinder = find.text('Test Template Name');
      expect(templateNameFinder, findsOneWidget);

      // Verify the text widget has proper styling
      final textWidget = tester.widget<Text>(templateNameFinder);
      expect(textWidget.style?.color, isNotNull);
      
      // Verify no rendering errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('TemplatePreviewCard displays text with proper colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: Brightness.light,
            ),
          ),
          home: Scaffold(
            body: TemplatePreviewCard(
              template: mockTemplate,
              showPricing: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the template name text
      final templateNameFinder = find.text('Test Template Name');
      expect(templateNameFinder, findsOneWidget);

      // Verify the text widget has proper styling
      final textWidget = tester.widget<Text>(templateNameFinder);
      expect(textWidget.style?.color, isNotNull);
      
      // Verify no rendering errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('Template selection with dark theme maintains text visibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.green,
                brightness: Brightness.dark,
              ),
            ),
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

      // Verify template name is displayed
      expect(find.text('Test Template Name'), findsWidgets);

      // Verify badges are displayed
      expect(find.text('Single'), findsWidgets);
      expect(find.text('Required'), findsWidgets);
      
      // Verify no rendering errors with dark theme
      expect(tester.takeException(), isNull);
    });

    testWidgets('Template cards handle selection state changes correctly', (WidgetTester tester) async {
      final selectedTemplates = <String>[];
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.green,
                brightness: Brightness.light,
              ),
            ),
            home: Scaffold(
              body: EnhancedTemplateSelector(
                vendorId: 'vendor1',
                selectedTemplateIds: selectedTemplates,
                onTemplatesSelected: (templates) {
                  selectedTemplates.clear();
                  selectedTemplates.addAll(templates.map((t) => t.id));
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the checkbox
      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsOneWidget);
      
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Verify no rendering errors after selection
      expect(tester.takeException(), isNull);
      
      // Verify template name is still visible
      expect(find.text('Test Template Name'), findsWidgets);
    });

    testWidgets('Template selector empty state displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.green,
                brightness: Brightness.light,
              ),
            ),
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

      // Verify empty state text is displayed
      expect(find.text('No Templates Found'), findsOneWidget);
      expect(find.text('Try adjusting your filters or create a new template'), findsOneWidget);
      
      // Verify no rendering errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('Template customization section empty state displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.green,
                brightness: Brightness.light,
              ),
            ),
            home: Scaffold(
              body: EnhancedCustomizationSection(
                linkedTemplates: [], // Empty list
                onTemplatesChanged: (templates) {},
                vendorId: 'vendor1',
                menuItemName: 'Test Menu Item',
                basePrice: 10.00,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify empty state is displayed
      expect(find.text('No templates applied'), findsOneWidget);
      
      // Verify no rendering errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('Template cards with long names handle text overflow correctly', (WidgetTester tester) async {
      final longNameTemplate = CustomizationTemplate(
        id: 'long_template',
        vendorId: 'vendor1',
        name: 'This is a very long template name that should be truncated with ellipsis to prevent overflow issues',
        description: 'Long description',
        type: 'multiple',
        isRequired: false,
        displayOrder: 1,
        isActive: true,
        options: [],
        usageCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: Brightness.light,
            ),
          ),
          home: Scaffold(
            body: SizedBox(
              width: 200, // Constrained width
              child: TemplatePreviewCard(
                template: longNameTemplate,
                showPricing: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify long name is displayed (may be truncated)
      expect(find.textContaining('This is a very long template name'), findsOneWidget);
      
      // Verify no overflow errors
      expect(tester.takeException(), isNull);
    });
  });
}
