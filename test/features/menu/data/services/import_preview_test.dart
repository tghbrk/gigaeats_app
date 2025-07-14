import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mockito/mockito.dart';
import 'package:gigaeats_app/src/features/menu/data/services/menu_import_service.dart';
import 'package:gigaeats_app/src/features/menu/data/models/menu_import_data.dart' as import_data;
import 'package:gigaeats_app/src/features/menu/data/repositories/menu_item_repository.dart';

// Create a mock repository
class MockMenuItemRepository extends Mock implements MenuItemRepository {}

void main() {
  group('Import Preview Functionality', () {
    late MenuImportService importService;

    setUp(() {
      final mockRepository = MockMenuItemRepository();
      importService = MenuImportService(menuItemRepository: mockRepository);
    });

    test('should process CSV file for preview without importing', () async {
      // Create a simple CSV content with exact header matches
      final csvContent = [
        'Item Name,Description,Category,Price (RM),Available,Unit,Min Order,Max Order,Prep Time (min),Halal,Vegetarian,Vegan,Spicy,Spicy Level,Allergens,Tags,Bulk Price (RM),Bulk Min Qty,Image URL,Customizations,Notes',
        'Nasi Lemak,Traditional coconut rice,Main Course,12.50,Yes,pax,1,,25,Yes,No,No,Yes,2,"nuts, eggs","malaysian, traditional",11.00,10,https://example.com/nasi-lemak.jpg,"Protein*: Chicken(+3.00), Beef(+4.00); Spice Level: Mild(+0), Hot(+1.00)",',
        'Teh Tarik,Malaysian pulled tea,Beverage,3.50,Yes,cup,1,5,5,Yes,Yes,Yes,No,,"dairy","malaysian, drink",3.00,6,,"Sweetness: Less Sweet(+0), Normal(+0), Extra Sweet(+0.50); Temperature: Hot(+0), Iced(+0.50)",',
      ].join('\n');

      final csvBytes = Uint8List.fromList(csvContent.codeUnits);
      
      // Create a mock PlatformFile
      final mockFile = PlatformFile(
        name: 'test_menu.csv',
        size: csvBytes.length,
        bytes: csvBytes,
      );

      // Process file for preview
      final result = await importService.processFileForPreview(
        mockFile,
        vendorId: 'test-vendor-123',
      );

      // Verify the result
      expect(result, isA<import_data.MenuImportResult>());
      expect(result.totalRows, 2); // Header + 2 data rows
      expect(result.validRows, 2); // Both items should be valid
      expect(result.errorRows, 0);
      expect(result.fileName, 'test_menu.csv');
      expect(result.fileType, '.csv');

      // Check the parsed rows
      expect(result.rows.length, 2);
      
      final firstRow = result.rows[0];
      expect(firstRow.name, 'Nasi Lemak');
      expect(firstRow.category, 'Main Course');
      expect(firstRow.basePrice, 12.50);
      expect(firstRow.isHalal, true);
      expect(firstRow.isVegetarian, false);
      expect(firstRow.isSpicy, true);
      expect(firstRow.spicyLevel, 2);
      expect(firstRow.customizationGroups, contains('Protein*'));
      expect(firstRow.isValid, true);
      expect(firstRow.hasErrors, false);

      final secondRow = result.rows[1];
      expect(secondRow.name, 'Teh Tarik');
      expect(secondRow.category, 'Beverage');
      expect(secondRow.basePrice, 3.50);
      expect(secondRow.isHalal, true);
      expect(secondRow.isVegetarian, true);
      expect(secondRow.isSpicy, false);
      expect(secondRow.customizationGroups, contains('Sweetness'));
      expect(secondRow.isValid, true);
      expect(secondRow.hasErrors, false);

      // Check categories extraction
      expect(result.categories, contains('Main Course'));
      expect(result.categories, contains('Beverage'));
    });

    test('should handle validation errors in preview', () async {
      // Create CSV with validation errors
      final csvContent = [
        'Item Name,Description,Category,Price (RM),Available,Unit,Min Order,Max Order,Prep Time (min),Halal,Vegetarian,Vegan,Spicy,Spicy Level,Allergens,Tags,Bulk Price (RM),Bulk Min Qty,Image URL,Customizations,Notes',
        ',Missing name item,Main Course,12.50,Yes,pax,1,,25,Yes,No,No,Yes,2,"nuts, eggs","malaysian, traditional",11.00,10,https://example.com/nasi-lemak.jpg,"Protein*: Chicken(+3.00), Beef(+4.00); Spice Level: Mild(+0), Hot(+1.00)",',
        'Valid Item,,,-5.00,Yes,pax,1,,25,Yes,No,No,Yes,2,"nuts, eggs","malaysian, traditional",11.00,10,https://example.com/nasi-lemak.jpg,"Protein*: Chicken(+3.00), Beef(+4.00); Spice Level: Mild(+0), Hot(+1.00)",',
      ].join('\n');

      final csvBytes = Uint8List.fromList(csvContent.codeUnits);
      
      final mockFile = PlatformFile(
        name: 'test_errors.csv',
        size: csvBytes.length,
        bytes: csvBytes,
      );

      final result = await importService.processFileForPreview(
        mockFile,
        vendorId: 'test-vendor-123',
      );

      // Verify error handling
      expect(result.totalRows, 2);
      expect(result.errorRows, 2); // Both rows have errors
      expect(result.validRows, 0);

      // Check first row errors (missing name)
      final firstRow = result.rows[0];
      expect(firstRow.hasErrors, true);
      expect(firstRow.errors, contains('Item name is required'));

      // Check second row errors (missing category and negative price)
      final secondRow = result.rows[1];
      expect(secondRow.hasErrors, true);
      expect(secondRow.errors, contains('Category is required'));
      expect(secondRow.errors, contains('Price must be non-negative'));
    });

    test('should handle customization format validation', () async {
      // Create CSV with invalid customization format
      final csvContent = [
        'Item Name,Description,Category,Price (RM),Available,Unit,Min Order,Max Order,Prep Time (min),Halal,Vegetarian,Vegan,Spicy,Spicy Level,Allergens,Tags,Bulk Price (RM),Bulk Min Qty,Image URL,Customizations,Notes',
        'Test Item,Test description,Main Course,12.50,Yes,pax,1,,25,Yes,No,No,Yes,2,"nuts, eggs","malaysian, traditional",11.00,10,,"Invalid customization format without proper structure",',
      ].join('\n');

      final csvBytes = Uint8List.fromList(csvContent.codeUnits);
      
      final mockFile = PlatformFile(
        name: 'test_customizations.csv',
        size: csvBytes.length,
        bytes: csvBytes,
      );

      final result = await importService.processFileForPreview(
        mockFile,
        vendorId: 'test-vendor-123',
      );

      // Check customization validation
      final row = result.rows[0];
      expect(row.hasErrors, true);
      expect(row.errors.any((error) => error.contains('Invalid customization format')), true);
    });

    test('should extract categories correctly', () async {
      final csvContent = [
        'Item Name,Description,Category,Price (RM),Available,Unit,Min Order,Max Order,Prep Time (min),Halal,Vegetarian,Vegan,Spicy,Spicy Level,Allergens,Tags,Bulk Price (RM),Bulk Min Qty,Image URL,Customizations,Notes',
        'Item 1,Description 1,Appetizer,5.00,Yes,pax,1,,15,Yes,No,No,No,,"","",,,,"",',
        'Item 2,Description 2,Main Course,15.00,Yes,pax,1,,30,Yes,No,No,No,,"","",,,,"",',
        'Item 3,Description 3,Dessert,8.00,Yes,pax,1,,10,Yes,Yes,Yes,No,,"","",,,,"",',
        'Item 4,Description 4,Beverage,4.00,Yes,cup,1,,5,Yes,Yes,Yes,No,,"","",,,,"",',
      ].join('\n');

      final csvBytes = Uint8List.fromList(csvContent.codeUnits);
      
      final mockFile = PlatformFile(
        name: 'test_categories.csv',
        size: csvBytes.length,
        bytes: csvBytes,
      );

      final result = await importService.processFileForPreview(
        mockFile,
        vendorId: 'test-vendor-123',
      );

      // Check categories extraction
      expect(result.categories.length, 4);
      expect(result.categories, contains('Appetizer'));
      expect(result.categories, contains('Main Course'));
      expect(result.categories, contains('Dessert'));
      expect(result.categories, contains('Beverage'));
      
      // Categories should be sorted
      expect(result.categories, ['Appetizer', 'Beverage', 'Dessert', 'Main Course']);
    });
  });
}
