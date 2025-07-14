import 'package:flutter_test/flutter_test.dart';
import 'package:csv/csv.dart';
import 'package:gigaeats_app/src/features/menu/data/services/menu_template_service.dart';

void main() {
  group('Template Generation Service', () {
    late MenuTemplateService templateService;

    setUp(() {
      templateService = MenuTemplateService();
    });

    group('User-Friendly Templates', () {
      test('should generate user-friendly CSV template with correct headers', () async {
        final csvContent = await templateService.generateUserFriendlyCsvTemplate(includeSampleData: false);
        
        // Check that it contains user-friendly headers
        expect(csvContent, contains('Item Name'));
        expect(csvContent, contains('Price (RM)'));
        expect(csvContent, contains('Available'));
        expect(csvContent, contains('Customizations'));
        
        // Should not contain technical headers
        expect(csvContent, isNot(contains('base_price')));
        expect(csvContent, isNot(contains('is_available')));
        expect(csvContent, isNot(contains('customization_groups')));
      });

      test('should generate user-friendly CSV template with sample data', () async {
        final csvContent = await templateService.generateUserFriendlyCsvTemplate(includeSampleData: true);
        
        // Check for sample data
        expect(csvContent, contains('Nasi Lemak Special'));
        expect(csvContent, contains('Teh Tarik'));
        expect(csvContent, contains('Yes')); // Available field
        expect(csvContent, contains('No')); // Boolean fields
        expect(csvContent, contains('Protein*:')); // Simplified customizations
      });

      test('should generate user-friendly Excel template', () async {
        final excelData = await templateService.generateUserFriendlyExcelTemplate(includeSampleData: true);
        
        // Check that we get binary data
        expect(excelData, isNotEmpty);
        expect(excelData.length, greaterThan(1000)); // Excel files are typically larger
      });

      test('should include simplified customizations in sample data', () async {
        final csvContent = await templateService.generateUserFriendlyCsvTemplate(includeSampleData: true);
        
        // Check for simplified customization format
        expect(csvContent, contains('Protein*:'));
        expect(csvContent, contains('(+'));
        expect(csvContent, contains(');'));
        expect(csvContent, contains('Spice Level:'));
        
        // Should not contain JSON format
        expect(csvContent, isNot(contains('{"name":')));
        expect(csvContent, isNot(contains('"type":')));
      });
    });

    group('Technical Templates', () {
      test('should generate technical CSV template with system headers', () async {
        final csvContent = await templateService.generateCsvTemplate(includeSampleData: false);
        
        // Check that it contains the first header from each group
        expect(csvContent, contains('Item Name')); // First option from name headers
        expect(csvContent, contains('Price (RM)')); // First option from price headers
      });

      test('should generate technical Excel template', () async {
        final excelData = await templateService.generateExcelTemplate(includeSampleData: true);
        
        // Check that we get binary data
        expect(excelData, isNotEmpty);
        expect(excelData.length, greaterThan(1000));
      });
    });

    group('Template Instructions', () {
      test('should provide user-friendly instructions', () {
        final instructions = templateService.getUserFriendlyTemplateInstructions();
        
        expect(instructions, contains('User-Friendly Format'));
        expect(instructions, contains('Quick Start Guide'));
        expect(instructions, contains('Yes/No'));
        expect(instructions, contains('Group: Option1(+price)'));
        expect(instructions, contains('Tips for Success'));
        
        // Should be comprehensive
        expect(instructions.length, greaterThan(1000));
      });

      test('should provide technical instructions', () {
        final instructions = templateService.getTemplateInstructions();
        
        expect(instructions, contains('Required Fields'));
        expect(instructions, isNotEmpty);
      });
    });

    group('Sample Data Quality', () {
      test('should include diverse menu items in user-friendly samples', () async {
        final csvContent = await templateService.generateUserFriendlyCsvTemplate(includeSampleData: true);
        
        // Check for variety of categories
        expect(csvContent, contains('Main Course'));
        expect(csvContent, contains('Beverages'));
        expect(csvContent, contains('Breakfast'));
        expect(csvContent, contains('Desserts'));
        
        // Check for variety of dietary options
        expect(csvContent, contains('Yes')); // Halal
        expect(csvContent, contains('No')); // Non-vegetarian
        
        // Check for different customization patterns
        expect(csvContent, contains('Protein*:')); // Required customization
        expect(csvContent, contains('Sweetness:')); // Optional customization
        expect(csvContent, contains('Curry:')); // Simple customization
      });

      test('should have realistic pricing in samples', () async {
        final csvContent = await templateService.generateUserFriendlyCsvTemplate(includeSampleData: true);
        
        // Check for Malaysian Ringgit pricing
        expect(csvContent, contains('12.50')); // Nasi Lemak
        expect(csvContent, contains('3.50')); // Teh Tarik
        expect(csvContent, contains('2.00')); // Roti Canai
        
        // Check for bulk pricing
        expect(csvContent, contains('11.00')); // Bulk price
        expect(csvContent, contains('10')); // Bulk quantity
      });

      test('should demonstrate proper customization format', () async {
        final csvContent = await templateService.generateUserFriendlyCsvTemplate(includeSampleData: true);
        
        // Check customization format examples
        expect(csvContent, contains('(+0)')); // Free options
        expect(csvContent, contains('(+1.00)')); // Paid options
        expect(csvContent, contains('*:')); // Required groups
        expect(csvContent, contains('; ')); // Group separators
        expect(csvContent, contains(', ')); // Option separators
      });
    });

    group('File Format Validation', () {
      test('should generate valid CSV format', () async {
        final csvContent = await templateService.generateUserFriendlyCsvTemplate(includeSampleData: true);

        // Use proper CSV parsing instead of simple string splitting
        const csvParser = CsvToListConverter();
        final parsedRows = csvParser.convert(csvContent);

        expect(parsedRows.length, greaterThan(5)); // Header + sample rows

        // Check header row has correct number of columns
        final headerRow = parsedRows[0];
        expect(headerRow.length, 21); // Expected number of user-friendly columns

        // Check data rows have same number of columns
        if (parsedRows.length > 1) {
          final dataRow = parsedRows[1];
          expect(dataRow.length, headerRow.length);
        }
      });

      test('should handle special characters in CSV', () async {
        final csvContent = await templateService.generateUserFriendlyCsvTemplate(includeSampleData: true);
        
        // Should handle commas in descriptions
        expect(csvContent, contains('Traditional coconut rice with sambal and sides'));
        
        // Should handle quotes and special characters
        expect(csvContent, isNot(contains('""'))); // No double quotes issues
      });
    });
  });
}
