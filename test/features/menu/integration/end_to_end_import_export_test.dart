import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mockito/mockito.dart';
import 'package:gigaeats_app/src/features/menu/data/services/menu_template_service.dart';
import 'package:gigaeats_app/src/features/menu/data/services/menu_import_service.dart';
import 'package:gigaeats_app/src/features/menu/data/services/customization_formatter.dart';
import 'package:gigaeats_app/src/features/menu/data/repositories/menu_item_repository.dart';

// Create a mock repository
class MockMenuItemRepository extends Mock implements MenuItemRepository {}

void main() {
  group('End-to-End Import/Export Workflow', () {
    late MenuTemplateService templateService;
    late MenuImportService importService;
    late MockMenuItemRepository mockRepository;

    setUp(() {
      templateService = MenuTemplateService();
      mockRepository = MockMenuItemRepository();
      importService = MenuImportService(menuItemRepository: mockRepository);
    });

    test('Complete workflow: Generate template → Edit → Preview → Import', () async {
      // Step 1: Generate user-friendly template with sample data
      final templateCsv = await templateService.generateUserFriendlyCsvTemplate(includeSampleData: true);
      
      expect(templateCsv, isNotEmpty);
      expect(templateCsv, contains('Item Name'));
      expect(templateCsv, contains('Nasi Lemak Special'));
      
      // Step 2: Simulate user editing the template (add a new item)
      final editedCsv = '$templateCsv\nMy Special Dish,Delicious homemade dish,Main Course,15.50,Yes,pax,1,,30,Yes,No,No,Yes,3,"nuts","homemade, special",14.00,5,,"Size*: Small(+0), Large(+3.00); Spice Level: Mild(+0), Hot(+1.50)",';
      
      // Step 3: Create a mock file for import
      final csvBytes = Uint8List.fromList(editedCsv.codeUnits);
      final mockFile = PlatformFile(
        name: 'edited_menu.csv',
        size: csvBytes.length,
        bytes: csvBytes,
      );

      // Step 4: Process file for preview
      final previewResult = await importService.processFileForPreview(
        mockFile,
        vendorId: 'test-vendor-123',
      );

      // Verify preview results
      expect(previewResult.totalRows, 6); // 5 sample + 1 new item
      expect(previewResult.validRows, 6); // All should be valid
      expect(previewResult.errorRows, 0);
      expect(previewResult.fileName, 'edited_menu.csv');
      
      // Check that our new item was parsed correctly
      final newItem = previewResult.rows.firstWhere((row) => row.name == 'My Special Dish');
      expect(newItem.category, 'Main Course');
      expect(newItem.basePrice, 15.50);
      expect(newItem.isHalal, true);
      expect(newItem.isSpicy, true);
      expect(newItem.spicyLevel, 3);
      expect(newItem.customizationGroups, contains('Size*'));
      expect(newItem.customizationGroups, contains('Large(+3.00)'));
      expect(newItem.isValid, true);
      
      // Step 5: Verify categories are extracted correctly
      expect(previewResult.categories, contains('Main Course'));
      expect(previewResult.categories, contains('Beverage'));
      expect(previewResult.categories, contains('Dessert'));
    });

    test('Error handling workflow: Invalid data → Preview shows errors → User fixes', () async {
      // Step 1: Create CSV with errors
      final errorCsv = [
        'Item Name,Description,Category,Price (RM),Available,Unit,Min Order,Max Order,Prep Time (min),Halal,Vegetarian,Vegan,Spicy,Spicy Level,Allergens,Tags,Bulk Price (RM),Bulk Min Qty,Image URL,Customizations,Notes',
        ',Missing name item,Main Course,12.50,Yes,pax,1,,25,Yes,No,No,Yes,2,"nuts, eggs","malaysian, traditional",11.00,10,,"Protein*: Chicken(+3.00), Beef(+4.00)",',
        'Valid Item,,,-5.00,Yes,pax,1,,25,Yes,No,No,Yes,2,"nuts, eggs","malaysian, traditional",11.00,10,,"Invalid customization format without proper structure",',
        'Another Valid Item,Good description,Appetizer,8.50,Yes,pax,1,,15,Yes,Yes,No,No,,"","",,,,"",',
      ].join('\n');

      final csvBytes = Uint8List.fromList(errorCsv.codeUnits);
      final mockFile = PlatformFile(
        name: 'error_menu.csv',
        size: csvBytes.length,
        bytes: csvBytes,
      );

      // Step 2: Process for preview
      final previewResult = await importService.processFileForPreview(
        mockFile,
        vendorId: 'test-vendor-123',
      );

      // Step 3: Verify error detection
      expect(previewResult.totalRows, 3);
      expect(previewResult.errorRows, 2); // Two items with errors
      expect(previewResult.validRows, 1); // One valid item
      
      // Check specific errors
      final firstRow = previewResult.rows[0];
      expect(firstRow.hasErrors, true);
      expect(firstRow.errors, contains('Item name is required'));
      
      final secondRow = previewResult.rows[1];
      expect(secondRow.hasErrors, true);
      expect(secondRow.errors, contains('Category is required'));
      expect(secondRow.errors, contains('Price must be non-negative'));
      expect(secondRow.errors, contains('Invalid customization format'));
      
      final thirdRow = previewResult.rows[2];
      expect(thirdRow.hasErrors, false);
      expect(thirdRow.isValid, true);
    });

    test('Customization format workflow: Complex customizations → Parse → Validate', () async {
      // Test complex customization scenarios
      final testCases = [
        {
          'input': 'Size*: Small(+0), Medium(+2.00), Large(+4.00); Protein*: Chicken(+3.00), Beef(+4.00), Fish(+3.50); Extras: Extra Rice(+2.00), Extra Sauce(+1.00)',
          'shouldBeValid': true,
          'description': 'Complex multi-group with required and optional groups'
        },
        {
          'input': 'Temperature: Hot(+0), Iced(+0.50)',
          'shouldBeValid': true,
          'description': 'Simple optional group'
        },
        {
          'input': 'Invalid format without proper structure',
          'shouldBeValid': false,
          'description': 'Invalid format should be rejected'
        },
        {
          'input': 'Size: Small(+0), Large(-2.00)',
          'shouldBeValid': false,
          'description': 'Negative prices should be rejected'
        },
      ];

      for (final testCase in testCases) {
        final validation = CustomizationFormatter.validateCustomizationText(testCase['input'] as String);
        expect(validation.isValid, testCase['shouldBeValid'], 
               reason: 'Failed for: ${testCase['description']}');
        
        if (validation.isValid) {
          // If valid, test round-trip conversion
          final parsed = CustomizationFormatter.parseCustomizationsFromText(testCase['input'] as String);
          final formatted = CustomizationFormatter.formatCustomizationsToText(parsed);
          
          // The formatted version should also be valid
          final revalidation = CustomizationFormatter.validateCustomizationText(formatted);
          expect(revalidation.isValid, true, 
                 reason: 'Round-trip failed for: ${testCase['description']}');
        }
      }
    });

    test('Template quality validation: Sample data should be realistic and diverse', () async {
      final userFriendlyTemplate = await templateService.generateUserFriendlyCsvTemplate(includeSampleData: true);
      
      // Parse the template to analyze sample data
      final lines = userFriendlyTemplate.split('\n');
      expect(lines.length, greaterThan(5)); // Header + at least 5 sample items
      
      // Check for diversity in categories
      final categories = <String>{};
      final prices = <double>[];
      final customizations = <String>[];
      
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) continue;
        
        // Simple CSV parsing for validation (not production-quality)
        final parts = lines[i].split(',');
        if (parts.length >= 21) {
          categories.add(parts[2]); // Category column
          
          final priceStr = parts[3]; // Price column
          final price = double.tryParse(priceStr);
          if (price != null) {
            prices.add(price);
          }
          
          final customization = parts[19]; // Customizations column
          if (customization.isNotEmpty && customization != '""') {
            customizations.add(customization);
          }
        }
      }
      
      // Validate diversity
      expect(categories.length, greaterThanOrEqualTo(3), reason: 'Should have diverse categories');
      expect(prices.length, greaterThanOrEqualTo(5), reason: 'Should have price examples');
      expect(prices.every((p) => p > 0), true, reason: 'All prices should be positive');
      expect(prices.any((p) => p < 10), true, reason: 'Should have affordable items');
      expect(prices.any((p) => p > 10), true, reason: 'Should have premium items');
      expect(customizations.length, greaterThanOrEqualTo(3), reason: 'Should have customization examples');
      
      // Check for Malaysian context
      expect(userFriendlyTemplate.toLowerCase(), contains('nasi'));
      expect(userFriendlyTemplate.toLowerCase(), contains('teh'));
      expect(userFriendlyTemplate, contains('RM'));
    });

    test('Template format validation: Should generate proper CSV structure', () async {
      final userFriendlyTemplate = await templateService.generateUserFriendlyCsvTemplate(includeSampleData: false);
      final technicalTemplate = await templateService.generateCsvTemplate(includeSampleData: false);

      // User-friendly template should have readable headers
      expect(userFriendlyTemplate, contains('Item Name'));
      expect(userFriendlyTemplate, contains('Price (RM)'));
      expect(userFriendlyTemplate, contains('Available'));

      // Technical template should have system headers
      expect(technicalTemplate, contains('name'));
      expect(technicalTemplate, contains('base_price'));
      expect(technicalTemplate, contains('is_available'));

      // Both should be valid CSV format
      final userFriendlyLines = userFriendlyTemplate.split('\n');
      final technicalLines = technicalTemplate.split('\n');

      expect(userFriendlyLines.length, greaterThan(0));
      expect(technicalLines.length, greaterThan(0));

      // Headers should have consistent number of columns
      final userFriendlyColumns = userFriendlyLines[0].split(',').length;
      final technicalColumns = technicalLines[0].split(',').length;

      expect(userFriendlyColumns, greaterThan(15), reason: 'Should have comprehensive columns');
      expect(technicalColumns, greaterThan(15), reason: 'Should have comprehensive columns');
    });

    test('Performance validation: Large dataset handling', () async {
      // Create a large CSV with many items
      final headerLine = 'Item Name,Description,Category,Price (RM),Available,Unit,Min Order,Max Order,Prep Time (min),Halal,Vegetarian,Vegan,Spicy,Spicy Level,Allergens,Tags,Bulk Price (RM),Bulk Min Qty,Image URL,Customizations,Notes';
      final dataLines = <String>[];
      
      // Generate 100 test items
      for (int i = 1; i <= 100; i++) {
        dataLines.add('Test Item $i,Description for item $i,Main Course,${(10 + i * 0.5).toStringAsFixed(2)},Yes,pax,1,,${15 + i},Yes,No,No,No,,"","",,,,"",');
      }
      
      final largeCsv = [headerLine, ...dataLines].join('\n');
      final csvBytes = Uint8List.fromList(largeCsv.codeUnits);
      final mockFile = PlatformFile(
        name: 'large_menu.csv',
        size: csvBytes.length,
        bytes: csvBytes,
      );

      // Measure processing time
      final stopwatch = Stopwatch()..start();
      
      final previewResult = await importService.processFileForPreview(
        mockFile,
        vendorId: 'test-vendor-123',
      );
      
      stopwatch.stop();
      
      // Verify results
      expect(previewResult.totalRows, 100);
      expect(previewResult.validRows, 100);
      expect(previewResult.errorRows, 0);
      
      // Performance should be reasonable (less than 5 seconds for 100 items)
      expect(stopwatch.elapsedMilliseconds, lessThan(5000), 
             reason: 'Processing 100 items should be fast');
      
      print('Processed 100 items in ${stopwatch.elapsedMilliseconds}ms');
    });
  });
}
