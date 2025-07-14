import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gigaeats_app/src/features/menu/presentation/widgets/vendor/enhanced_customization_section.dart';
import 'package:gigaeats_app/src/features/menu/presentation/widgets/vendor/enhanced_template_selector.dart';
import 'package:gigaeats_app/src/features/menu/presentation/widgets/vendor/template_preview_card.dart';
import 'package:gigaeats_app/src/features/menu/data/models/customization_template.dart';


void main() {
  group('MenuItemForm Overflow Fixes Integration Tests', () {
    late List<CustomizationTemplate> mockTemplates;

    setUp(() {
      mockTemplates = [
        CustomizationTemplate(
          id: 'template1',
          vendorId: 'vendor1',
          name: 'Very Long Template Name That Should Truncate Properly Without Causing Overflow',
          description: 'A template with a very long name to test overflow handling',
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
            TemplateOption(
              id: 'opt2',
              templateId: 'template1',
              name: 'Option 2',
              additionalPrice: 3.00,
              displayOrder: 2,
              isAvailable: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
          usageCount: 15,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CustomizationTemplate(
          id: 'template2',
          vendorId: 'vendor1',
          name: 'Multiple Selection Template',
          description: 'Template for multiple selections',
          type: 'multiple',
          isRequired: false,
          displayOrder: 2,
          isActive: true,
          options: [
            TemplateOption(
              id: 'opt3',
              templateId: 'template2',
              name: 'Extra Long Option Name That Should Also Truncate',
              additionalPrice: 1.50,
              displayOrder: 1,
              isAvailable: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
          usageCount: 8,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    });

    testWidgets('EnhancedCustomizationSection handles overflow correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300, // Constrained width to test overflow
                child: EnhancedCustomizationSection(
                  linkedTemplates: mockTemplates,
                  onTemplatesChanged: (templates) {},
                  vendorId: 'vendor1',
                  menuItemName: 'Test Menu Item',
                  basePrice: 10.00,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no overflow errors
      expect(tester.takeException(), isNull);

      // Verify templates are displayed
      expect(find.text('Very Long Template Name That Should Truncate Properly Without Causing Overflow'), findsOneWidget);
      expect(find.text('Multiple Selection Template'), findsOneWidget);

      // Test expansion of template cards
      await tester.tap(find.text('Very Long Template Name That Should Truncate Properly Without Causing Overflow'));
      await tester.pumpAndSettle();

      // Verify no overflow after expansion
      expect(tester.takeException(), isNull);
    });

    testWidgets('EnhancedTemplateSelector handles badge overflow correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 250, // Very constrained width
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

      // Verify no overflow errors
      expect(tester.takeException(), isNull);

      // Verify template cards are displayed
      expect(find.byType(Card), findsWidgets);

      // Test template selection
      final checkboxes = find.byType(Checkbox);
      if (checkboxes.evaluate().isNotEmpty) {
        await tester.tap(checkboxes.first);
        await tester.pumpAndSettle();

        // Verify no overflow after selection
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('TemplatePreviewCard handles badge overflow correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200, // Constrained width
              child: TemplatePreviewCard(
                template: mockTemplates[0], // Template with long name and required badge
                showPricing: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no overflow errors
      expect(tester.takeException(), isNull);

      // Verify template content is displayed
      expect(find.text('Very Long Template Name That Should Truncate Properly Without Causing Overflow'), findsOneWidget);
      expect(find.text('Single'), findsOneWidget);
      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('Template cards handle multiple badges without overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 150, // Very constrained width to force overflow scenarios
              child: Column(
                children: mockTemplates.map((template) => 
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TemplatePreviewCard(
                      template: template,
                      showPricing: true,
                    ),
                  ),
                ).toList(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no overflow errors with multiple templates
      expect(tester.takeException(), isNull);

      // Verify both templates are displayed
      expect(find.byType(TemplatePreviewCard), findsNWidgets(2));
    });

    testWidgets('Template selector with many templates handles overflow', (WidgetTester tester) async {
      // Test template selector with many templates (templates loaded via provider)

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 600,
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

      // Verify no overflow errors with many templates
      expect(tester.takeException(), isNull);

      // Test scrolling
      await tester.drag(find.byType(ListView).first, const Offset(0, -200));
      await tester.pumpAndSettle();

      // Verify no overflow after scrolling
      expect(tester.takeException(), isNull);
    });

    testWidgets('Enhanced customization section with empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                child: EnhancedCustomizationSection(
                  linkedTemplates: [], // Empty templates
                  onTemplatesChanged: (templates) {},
                  vendorId: 'vendor1',
                  menuItemName: 'Test Menu Item',
                  basePrice: 10.00,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no overflow errors with empty state
      expect(tester.takeException(), isNull);

      // Verify empty state is displayed
      expect(find.text('No templates applied'), findsOneWidget);
    });

    testWidgets('Template cards with extreme content lengths', (WidgetTester tester) async {
      final extremeTemplate = CustomizationTemplate(
        id: 'extreme',
        vendorId: 'vendor1',
        name: 'This is an extremely long template name that should definitely cause overflow issues if not handled properly with ellipsis truncation and flexible widgets',
        description: 'Extreme description',
        type: 'single',
        isRequired: true,
        displayOrder: 1,
        isActive: true,
        options: List.generate(50, (index) =>
          TemplateOption(
            id: 'extreme_opt$index',
            templateId: 'extreme',
            name: 'Extreme Option $index with Very Long Name',
            additionalPrice: index * 0.1,
            displayOrder: index,
            isAvailable: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
        usageCount: 999,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100, // Extremely constrained width
              child: TemplatePreviewCard(
                template: extremeTemplate,
                showPricing: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no overflow errors even with extreme content
      expect(tester.takeException(), isNull);
    });
  });
}
