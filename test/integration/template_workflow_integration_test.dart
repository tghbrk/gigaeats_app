import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gigaeats_app/main.dart' as app;
import 'package:gigaeats_app/src/features/menu/data/models/customization_template.dart';
import 'package:gigaeats_app/src/features/menu/data/repositories/customization_template_repository.dart';

/// Integration tests for the complete template workflow
/// Tests the end-to-end functionality of customization templates
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Template Workflow Integration Tests', () {
    late CustomizationTemplateRepository repository;
    late String testVendorId;
    late String testMenuItemId;

    setUpAll(() async {
      repository = CustomizationTemplateRepository();
      testVendorId = 'test-vendor-${DateTime.now().millisecondsSinceEpoch}';
      testMenuItemId = 'test-menu-item-${DateTime.now().millisecondsSinceEpoch}';
    });

    group('Template Creation Workflow', () {
      testWidgets('should create template with options successfully', (tester) async {
        // Start the app
        app.main();
        await tester.pumpAndSettle();

        // Test data
        final templateData = CustomizationTemplate.test(
          vendorId: testVendorId,
          name: 'Integration Test Size Options',
          description: 'Size options for integration testing',
          type: 'single', // 'single' instead of 'allow_multiple': false
          isRequired: true,
          displayOrder: 1,
        );

        // Create template
        final template = await repository.createTemplate(templateData);
        expect(template, isA<CustomizationTemplate>());
        expect(template.name, equals('Integration Test Size Options'));
        expect(template.vendorId, equals(testVendorId));
        expect(template.isRequired, isTrue);

        // Add options to template
        final smallOptionData = {
          'template_id': template.id,
          'name': 'Small',
          'description': 'Small size',
          'price': 0.0,
          'display_order': 1,
        };

        final largeOptionData = {
          'template_id': template.id,
          'name': 'Large',
          'description': 'Large size',
          'price': 5.50,
          'display_order': 2,
        };

        final smallOption = await repository.addOptionToTemplate(template.id, smallOptionData);
        final largeOption = await repository.addOptionToTemplate(template.id, largeOptionData);

        expect(smallOption.name, equals('Small'));
        expect(smallOption.price, equals(0.0));
        expect(largeOption.name, equals('Large'));
        expect(largeOption.price, equals(5.50));

        // Verify options are retrieved correctly
        final options = await repository.getTemplateOptions(template.id);
        expect(options, hasLength(2));
        expect(options[0].name, equals('Small')); // Should be ordered by display_order
        expect(options[1].name, equals('Large'));

        print('✅ Template creation workflow completed successfully');
      });

      testWidgets('should link template to menu item successfully', (tester) async {
        // Get existing template
        final templates = await repository.getTemplatesByVendor(testVendorId);
        expect(templates, isNotEmpty);
        final template = templates.first;

        // Link template to menu item
        final link = await repository.linkTemplateToMenuItem(
          menuItemId: testMenuItemId,
          templateId: template.id,
        );
        expect(link.menuItemId, equals(testMenuItemId));
        expect(link.templateId, equals(template.id));

        // Verify menu item templates are retrieved correctly
        final menuItemTemplates = await repository.getMenuItemTemplates(testMenuItemId);
        expect(menuItemTemplates, hasLength(1));
        expect(menuItemTemplates.first.id, equals(template.id));

        print('✅ Template linking workflow completed successfully');
      });
    });

    group('Template Management Workflow', () {
      testWidgets('should update template successfully', (tester) async {
        // Get existing template
        final templates = await repository.getTemplatesByVendor(testVendorId);
        expect(templates, isNotEmpty);
        final template = templates.first;

        // Update template
        final updatedTemplateData = template.copyWith(
          name: 'Updated Integration Test Template',
          description: 'Updated description for integration testing',
          isRequired: false,
        );

        final updatedTemplate = await repository.updateTemplate(updatedTemplateData);
        expect(updatedTemplate.name, equals('Updated Integration Test Template'));
        expect(updatedTemplate.description, equals('Updated description for integration testing'));
        expect(updatedTemplate.isRequired, isFalse);

        print('✅ Template update workflow completed successfully');
      });

      testWidgets('should bulk apply templates to menu items', (tester) async {
        // Get existing template
        final templates = await repository.getTemplatesByVendor(testVendorId);
        expect(templates, isNotEmpty);
        final template = templates.first;

        // Create additional test menu items
        final menuItemIds = [
          'test-menu-item-bulk-1-${DateTime.now().millisecondsSinceEpoch}',
          'test-menu-item-bulk-2-${DateTime.now().millisecondsSinceEpoch}',
          'test-menu-item-bulk-3-${DateTime.now().millisecondsSinceEpoch}',
        ];

        // Bulk apply template to menu items
        final results = await repository.bulkLinkTemplatesToMenuItems(
          menuItemIds: menuItemIds,
          templateIds: [template.id],
        );
        expect(results, hasLength(3));

        // Verify each menu item has the template linked
        for (final menuItemId in menuItemIds) {
          final menuItemTemplates = await repository.getMenuItemTemplates(menuItemId);
          expect(menuItemTemplates, hasLength(1));
          expect(menuItemTemplates.first.id, equals(template.id));
        }

        print('✅ Bulk template application workflow completed successfully');
      });
    });

    group('Template Analytics Workflow', () {
      testWidgets('should track template usage and generate analytics', (tester) async {
        // Get existing template
        final templates = await repository.getTemplatesByVendor(testVendorId);
        expect(templates, isNotEmpty);
        final template = templates.first;

        // Simulate template usage
        await repository.updateTemplateUsageCount(template.id);
        await repository.updateTemplateUsageCount(template.id);
        await repository.updateTemplateUsageCount(template.id);

        // Get updated template to verify usage count
        final updatedTemplates = await repository.getTemplatesByVendor(testVendorId);
        final updatedTemplate = updatedTemplates.firstWhere((t) => t.id == template.id);
        expect(updatedTemplate.usageCount, greaterThan(template.usageCount));

        // Get analytics summary
        final summary = await repository.getAnalyticsSummary(
          vendorId: testVendorId,
          periodStart: DateTime.now().subtract(const Duration(days: 30)),
          periodEnd: DateTime.now(),
        );

        expect(summary.vendorId, equals(testVendorId));
        expect(summary.totalTemplates, greaterThan(0));

        // Get performance metrics
        final performanceMetrics = await repository.getTemplatePerformanceMetrics(
          vendorId: testVendorId,
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now(),
        );

        expect(performanceMetrics, isNotEmpty);

        print('✅ Template analytics workflow completed successfully');
      });
    });

    group('Template Validation Workflow', () {
      testWidgets('should validate template data correctly', (tester) async {
        // Test valid template data
        final validData = {
          'vendor_id': testVendorId,
          'name': 'Valid Template',
          'description': 'Valid description',
          'category': 'test',
        };

        expect(repository.validateTemplateData(validData), isTrue);

        // Test invalid template data
        final invalidData = {
          'vendor_id': '',
          'name': '',
        };

        expect(repository.validateTemplateData(invalidData), isFalse);

        // Test valid option data
        final validOptionData = {
          'template_id': 'template-123',
          'name': 'Valid Option',
          'price': 5.50,
        };

        expect(repository.validateOptionData(validOptionData), isTrue);

        // Test invalid option data
        final invalidOptionData = {
          'template_id': '',
          'name': '',
          'price': -1.0,
        };

        expect(repository.validateOptionData(invalidOptionData), isFalse);

        print('✅ Template validation workflow completed successfully');
      });
    });

    group('Error Handling Workflow', () {
      testWidgets('should handle duplicate template names gracefully', (tester) async {
        // Create first template
        final templateData = CustomizationTemplate.test(
          vendorId: testVendorId,
          name: 'Duplicate Test Template',
          description: 'First template',
        );

        final firstTemplate = await repository.createTemplate(templateData);
        expect(firstTemplate.name, equals('Duplicate Test Template'));

        // Try to create second template with same name
        final duplicateData = CustomizationTemplate.test(
          vendorId: testVendorId,
          name: 'Duplicate Test Template',
          description: 'Second template',
        );

        // This should either succeed (if duplicates are allowed) or throw an error
        try {
          await repository.createTemplate(duplicateData);
          // If successful, verify both templates exist
          final templates = await repository.getTemplatesByVendor(testVendorId);
          final duplicateTemplates = templates.where((t) => t.name == 'Duplicate Test Template').toList();
          expect(duplicateTemplates.length, greaterThanOrEqualTo(1));
        } catch (e) {
          // If error is thrown, verify it's handled gracefully
          expect(e, isA<Exception>());
        }

        print('✅ Duplicate template handling workflow completed successfully');
      });

      testWidgets('should handle invalid template operations gracefully', (tester) async {
        // Try to get templates for non-existent vendor
        final nonExistentVendorTemplates = await repository.getTemplatesByVendor('non-existent-vendor');
        expect(nonExistentVendorTemplates, isEmpty);

        // Try to get options for non-existent template
        final nonExistentTemplateOptions = await repository.getTemplateOptions('non-existent-template');
        expect(nonExistentTemplateOptions, isEmpty);

        // Try to get templates for non-existent menu item
        final nonExistentMenuItemTemplates = await repository.getMenuItemTemplates('non-existent-menu-item');
        expect(nonExistentMenuItemTemplates, isEmpty);

        print('✅ Invalid operations handling workflow completed successfully');
      });
    });

    group('Performance Workflow', () {
      testWidgets('should handle large number of templates efficiently', (tester) async {
        final stopwatch = Stopwatch()..start();

        // Create multiple templates
        final templateFutures = <Future<CustomizationTemplate>>[];
        for (int i = 0; i < 10; i++) {
          final templateData = CustomizationTemplate.test(
            vendorId: testVendorId,
            name: 'Performance Test Template $i',
            description: 'Template for performance testing',
            displayOrder: i,
          );
          templateFutures.add(repository.createTemplate(templateData));
        }

        final templates = await Future.wait(templateFutures);
        expect(templates, hasLength(10));

        // Retrieve all templates
        final allTemplates = await repository.getTemplatesByVendor(testVendorId);
        expect(allTemplates.length, greaterThanOrEqualTo(10));

        stopwatch.stop();
        final elapsedMs = stopwatch.elapsedMilliseconds;

        // Performance assertion - should complete within reasonable time
        expect(elapsedMs, lessThan(10000)); // Less than 10 seconds

        print('✅ Performance workflow completed in ${elapsedMs}ms');
      });
    });

    tearDownAll(() async {
      // Clean up test data
      try {
        final templates = await repository.getTemplatesByVendor(testVendorId);
        for (final template in templates) {
          await repository.deleteTemplate(template.id);
        }
        print('✅ Test cleanup completed successfully');
      } catch (e) {
        print('⚠️ Test cleanup failed: $e');
      }
    });
  });
}
