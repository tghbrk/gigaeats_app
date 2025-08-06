
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';


import 'menu_import_service.dart';

/// Service for generating menu import templates
class MenuTemplateService {
  /// Generate CSV template with sample data
  Future<String> generateCsvTemplate({bool includeSampleData = true}) async {
    final headers = MenuImportService.expectedHeaders.values.map((list) => list.first).toList();
    final rows = <List<String>>[headers];

    if (includeSampleData) {
      rows.addAll(_getSampleData());
    }

    final csvConverter = const ListToCsvConverter();
    return csvConverter.convert(rows);
  }

  /// Generate user-friendly CSV template with sample data
  Future<String> generateUserFriendlyCsvTemplate({bool includeSampleData = true}) async {
    final headers = _getUserFriendlyHeaders();
    final rows = <List<String>>[headers];

    if (includeSampleData) {
      rows.addAll(_getUserFriendlySampleData());
    }

    final csvConverter = const ListToCsvConverter();
    return csvConverter.convert(rows);
  }

  /// Generate Excel template with sample data
  Future<Uint8List> generateExcelTemplate({bool includeSampleData = true}) async {
    final excel = Excel.createExcel();
    final sheet = excel['Menu Items'];

    // Add headers
    final headers = MenuImportService.expectedHeaders.values.map((list) => list.first).toList();
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);

      // Style header cells
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue50,
        fontColorHex: ExcelColor.black,
      );
    }

    if (includeSampleData) {
      final sampleData = _getSampleData();
      for (int rowIndex = 0; rowIndex < sampleData.length; rowIndex++) {
        final rowData = sampleData[rowIndex];
        for (int colIndex = 0; colIndex < rowData.length; colIndex++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: colIndex,
            rowIndex: rowIndex + 1,
          ));
          cell.value = TextCellValue(rowData[colIndex]);
        }
      }
    }

    return Uint8List.fromList(excel.encode()!);
  }

  /// Generate user-friendly Excel template with sample data
  Future<Uint8List> generateUserFriendlyExcelTemplate({bool includeSampleData = true}) async {
    final excel = Excel.createExcel();
    final sheet = excel['Menu Items'];

    // Add user-friendly headers
    final headers = _getUserFriendlyHeaders();
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);

      // Style header cells
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.green50,
        fontColorHex: ExcelColor.black,
      );
    }

    if (includeSampleData) {
      final sampleData = _getUserFriendlySampleData();
      for (int rowIndex = 0; rowIndex < sampleData.length; rowIndex++) {
        final rowData = sampleData[rowIndex];
        for (int colIndex = 0; colIndex < rowData.length; colIndex++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: colIndex,
            rowIndex: rowIndex + 1,
          ));
          cell.value = TextCellValue(rowData[colIndex]);
        }
      }
    }

    return Uint8List.fromList(excel.encode()!);
  }

  /// Download CSV template
  Future<void> downloadCsvTemplate({bool includeSampleData = true}) async {
    try {
      final csvContent = await generateCsvTemplate(includeSampleData: includeSampleData);
      
      if (kIsWeb) {
        // For web, trigger download
        await _downloadFileWeb(
          Uint8List.fromList(csvContent.codeUnits),
          'gigaeats_menu_template.csv',
          'text/csv',
        );
      } else {
        // For mobile, save to downloads and share
        await _saveAndShareFile(
          Uint8List.fromList(csvContent.codeUnits),
          'gigaeats_menu_template.csv',
        );
      }
    } catch (e) {
      debugPrint('Error downloading CSV template: $e');
      rethrow;
    }
  }

  /// Download Excel template
  Future<void> downloadExcelTemplate({bool includeSampleData = true}) async {
    try {
      final excelData = await generateExcelTemplate(includeSampleData: includeSampleData);
      
      if (kIsWeb) {
        // For web, trigger download
        await _downloadFileWeb(
          excelData,
          'gigaeats_menu_template.xlsx',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
      } else {
        // For mobile, save to downloads and share
        await _saveAndShareFile(excelData, 'gigaeats_menu_template.xlsx');
      }
    } catch (e) {
      debugPrint('Error downloading Excel template: $e');
      rethrow;
    }
  }

  /// Download user-friendly CSV template
  Future<void> downloadUserFriendlyCsvTemplate({bool includeSampleData = true}) async {
    try {
      final csvContent = await generateUserFriendlyCsvTemplate(includeSampleData: includeSampleData);

      if (kIsWeb) {
        // For web, trigger download
        await _downloadFileWeb(
          Uint8List.fromList(csvContent.codeUnits),
          'gigaeats_menu_template_simplified.csv',
          'text/csv',
        );
      } else {
        // For mobile, save to downloads and share
        await _saveAndShareFile(
          Uint8List.fromList(csvContent.codeUnits),
          'gigaeats_menu_template_simplified.csv',
        );
      }
    } catch (e) {
      debugPrint('Error downloading user-friendly CSV template: $e');
      rethrow;
    }
  }

  /// Download user-friendly Excel template
  Future<void> downloadUserFriendlyExcelTemplate({bool includeSampleData = true}) async {
    try {
      final excelData = await generateUserFriendlyExcelTemplate(includeSampleData: includeSampleData);

      if (kIsWeb) {
        // For web, trigger download
        await _downloadFileWeb(
          excelData,
          'gigaeats_menu_template_simplified.xlsx',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
      } else {
        // For mobile, save to downloads and share
        await _saveAndShareFile(
          excelData,
          'gigaeats_menu_template_simplified.xlsx',
        );
      }
    } catch (e) {
      debugPrint('Error downloading user-friendly Excel template: $e');
      rethrow;
    }
  }

  /// Get sample data for templates
  List<List<String>> _getSampleData() {
    return [
      [
        'Nasi Lemak Special',
        'Traditional Malaysian coconut rice with sambal, anchovies, peanuts, boiled egg, and cucumber',
        'Rice Dishes',
        '12.50',
        'pax',
        '1',
        '50',
        '25',
        'Y',
        'Y',
        'N',
        'N',
        'Y',
        '2',
        'Contains nuts, eggs',
        'malaysian, traditional, spicy',
        'https://example.com/nasi-lemak.jpg',
        '{"calories": 450, "protein": "15g", "carbs": "65g", "fat": "18g"}',
        '11.00',
        '10',
        '[{"name": "Protein", "type": "single_select", "required": true, "options": [{"name": "Chicken", "price": 3.00}, {"name": "Beef", "price": 4.00}, {"name": "Fish", "price": 3.50}]}]',
      ],
      [
        'Teh Tarik',
        'Traditional Malaysian pulled tea with condensed milk',
        'Beverages',
        '3.50',
        'cup',
        '1',
        '20',
        '5',
        'Y',
        'Y',
        'Y',
        'N',
        'N',
        '',
        'Contains dairy',
        'malaysian, traditional, hot',
        'https://example.com/teh-tarik.jpg',
        '{"calories": 120, "protein": "3g", "carbs": "18g", "fat": "4g"}',
        '3.00',
        '5',
        '[{"name": "Sweetness", "type": "single_select", "required": false, "options": [{"name": "Less Sweet", "price": 0}, {"name": "Normal", "price": 0}, {"name": "Extra Sweet", "price": 0.50}]}]',
      ],
      [
        'Roti Canai',
        'Flaky flatbread served with curry dhal',
        'Breakfast',
        '2.00',
        'piece',
        '1',
        '10',
        '15',
        'Y',
        'Y',
        'Y',
        'N',
        'N',
        '',
        'Contains gluten',
        'malaysian, traditional, vegetarian',
        'https://example.com/roti-canai.jpg',
        '{"calories": 180, "protein": "5g", "carbs": "28g", "fat": "6g"}',
        '1.80',
        '5',
        '[{"name": "Curry", "type": "multiple", "required": false, "options": [{"name": "Dhal Curry", "price": 0}, {"name": "Fish Curry", "price": 1.00}, {"name": "Chicken Curry", "price": 1.50}]}]',
      ],
    ];
  }

  /// Get user-friendly headers for template
  List<String> _getUserFriendlyHeaders() {
    return [
      'Item Name',
      'Description',
      'Category',
      'Price (RM)',
      'Available',
      'Unit',
      'Min Order',
      'Max Order',
      'Prep Time (min)',
      'Halal',
      'Vegetarian',
      'Vegan',
      'Spicy',
      'Spicy Level',
      'Allergens',
      'Tags',
      'Bulk Price (RM)',
      'Bulk Min Qty',
      'Image URL',
      'Customizations',
      'Notes',
    ];
  }

  /// Get user-friendly sample data for templates
  List<List<String>> _getUserFriendlySampleData() {
    return [
      [
        'Nasi Lemak Special',
        'Traditional coconut rice with sambal and sides',
        'Main Course',
        '12.50',
        'Yes',
        'pax',
        '1',
        '',
        '25',
        'Yes',
        'No',
        'No',
        'Yes',
        '2',
        'nuts, eggs',
        'malaysian, traditional',
        '11.00',
        '10',
        'https://example.com/nasi-lemak.jpg',
        'Protein*: Chicken(+3.00), Beef(+4.00), Fish(+3.50); Spice Level: Mild(+0), Medium(+0), Hot(+0)',
        '',
      ],
      [
        'Teh Tarik',
        'Traditional pulled milk tea',
        'Beverages',
        '3.50',
        'Yes',
        'cup',
        '1',
        '',
        '5',
        'Yes',
        'Yes',
        'No',
        'No',
        '',
        '',
        'traditional',
        '3.00',
        '5',
        '',
        'Sweetness: Less Sweet(+0), Normal(+0), Extra Sweet(+0); Temperature: Hot(+0), Iced(+0.50)',
        '',
      ],
      [
        'Roti Canai',
        'Flaky flatbread served with curry dhal',
        'Breakfast',
        '2.00',
        'Yes',
        'piece',
        '1',
        '10',
        '15',
        'Yes',
        'Yes',
        'No',
        'No',
        '',
        'gluten',
        'traditional',
        '1.80',
        '5',
        '',
        'Curry: Dhal(+0), Fish Curry(+1.00), Chicken Curry(+1.50)',
        '',
      ],
      [
        'Mee Goreng',
        'Spicy fried noodles with vegetables',
        'Main Course',
        '8.50',
        'Yes',
        'pax',
        '1',
        '',
        '20',
        'Yes',
        'No',
        'No',
        'Yes',
        '3',
        'gluten, soy',
        'malaysian, spicy',
        '7.50',
        '8',
        '',
        'Protein*: Chicken(+2.00), Beef(+3.00), Seafood(+4.00), Tofu(+0); Spice Level: Mild(+0), Medium(+0), Hot(+0), Extra Hot(+1.00)',
        '',
      ],
      [
        'Cendol',
        'Traditional shaved ice dessert',
        'Desserts',
        '4.50',
        'Yes',
        'bowl',
        '1',
        '',
        '10',
        'Yes',
        'Yes',
        'No',
        'No',
        '',
        '',
        'traditional',
        '',
        '',
        '',
        'Toppings: Extra Coconut Milk(+0.50), Red Beans(+0.50), Sweet Corn(+0.50)',
        '',
      ],
    ];
  }

  /// Save file and share on mobile platforms
  Future<void> _saveAndShareFile(Uint8List data, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(data);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'GigaEats Menu Import Template',
        ),
      );
    } catch (e) {
      debugPrint('Error saving and sharing file: $e');
      rethrow;
    }
  }

  /// Download file on web platform
  Future<void> _downloadFileWeb(Uint8List data, String fileName, String mimeType) async {
    try {
      // This would need to be implemented with web-specific download logic
      // For now, we'll throw an error to indicate web download needs implementation
      throw UnimplementedError('Web download not implemented yet');
    } catch (e) {
      debugPrint('Error downloading file on web: $e');
      rethrow;
    }
  }

  /// Generate instructions for using the template
  String getTemplateInstructions() {
    return '''
# GigaEats Menu Import Template Instructions

## Required Fields
- **Item Name**: The name of your menu item (required)
- **Category**: Menu category (required)
- **Base Price (RM)**: Price in Malaysian Ringgit (required)

## Optional Fields
- **Description**: Detailed description of the item
- **Unit**: Unit of measurement (default: pax)
- **Min/Max Order Qty**: Minimum and maximum order quantities
- **Prep Time (min)**: Preparation time in minutes
- **Available (Y/N)**: Whether item is currently available
- **Halal/Vegetarian/Vegan/Spicy (Y/N)**: Dietary information
- **Spicy Level (1-5)**: Spiciness rating from 1 (mild) to 5 (very spicy)
- **Allergens**: Comma-separated list of allergens
- **Tags**: Comma-separated list of tags
- **Image URL**: Direct link to item image
- **Nutritional Info (JSON)**: Nutritional information in JSON format
- **Bulk Price/Qty**: Bulk pricing information
- **Customizations (JSON)**: Customization options in JSON format

## Boolean Fields
Use Y/Yes/True/1 for true values, N/No/False/0 for false values.

## Customizations Format
Use JSON format for customization groups:
```json
[
  {
    'name': 'Size',
    'type': 'single_select',
    'required': true,
    'options': [
      {'name': 'Small', 'price': 0},
      {'name': 'Large', 'price': 2.00}
    ]
  }
]
```

## Tips
1. Keep item names unique within your menu
2. Use consistent category names
3. Ensure prices are positive numbers
4. Test with a small batch first
5. Review the preview before final import

## File Formats Supported
- CSV (.csv)
- Excel (.xlsx, .xls)
- Maximum file size: 10MB
- Maximum rows: 1000

For support, contact: support@gigaeats.com
''';
  }

  /// Generate validation rules documentation
  Map<String, String> getValidationRules() {
    return {
      'Item Name': 'Required, must be unique, 1-100 characters',
      'Description': 'Optional, maximum 500 characters',
      'Category': 'Required, will be created if doesn\'t exist',
      'Base Price': 'Required, must be positive number',
      'Unit': 'Optional, default is "pax"',
      'Min Order Qty': 'Optional, must be positive integer',
      'Max Order Qty': 'Optional, must be greater than min quantity',
      'Prep Time': 'Optional, in minutes, positive integer',
      'Available': 'Optional, Y/N, default is Y',
      'Halal': 'Optional, Y/N, default is N',
      'Vegetarian': 'Optional, Y/N, default is N',
      'Vegan': 'Optional, Y/N, default is N',
      'Spicy': 'Optional, Y/N, default is N',
      'Spicy Level': 'Optional, integer 1-5',
      'Allergens': 'Optional, comma-separated list',
      'Tags': 'Optional, comma-separated list',
      'Image URL': 'Optional, valid URL format',
      'Nutritional Info': 'Optional, valid JSON format',
      'Bulk Price': 'Optional, positive number',
      'Bulk Min Qty': 'Required if bulk price specified',
      'Customizations': 'Optional, valid JSON array format',
    };
  }

  /// Get user-friendly template instructions
  String getUserFriendlyTemplateInstructions() {
    return '''
# GigaEats Menu Import Template - User-Friendly Format

## Quick Start Guide
1. Download this template with sample data
2. Edit the data in your favorite spreadsheet app (Excel, Google Sheets)
3. Save as CSV file
4. Upload to GigaEats

## Column Descriptions

### Required Fields
- **Item Name**: Unique name for your menu item
- **Category**: Food category (e.g., "Main Course", "Beverages", "Desserts")
- **Price (RM)**: Base price in Malaysian Ringgit (numbers only, e.g., 12.50)

### Basic Information
- **Description**: Brief description of the item
- **Available**: Yes/No - whether item is currently available
- **Unit**: Serving unit (e.g., "pax", "piece", "bowl", "cup")
- **Min Order**: Minimum order quantity (default: 1)
- **Max Order**: Maximum order quantity (leave blank for unlimited)
- **Prep Time (min)**: Preparation time in minutes

### Dietary Information
- **Halal**: Yes/No
- **Vegetarian**: Yes/No
- **Vegan**: Yes/No
- **Spicy**: Yes/No
- **Spicy Level**: 1-5 scale (only if spicy = Yes)

### Additional Details
- **Allergens**: Comma-separated list (e.g., "nuts, eggs, dairy")
- **Tags**: Comma-separated keywords (e.g., "malaysian, traditional, popular")
- **Bulk Price (RM)**: Discounted price for bulk orders
- **Bulk Min Qty**: Minimum quantity for bulk pricing
- **Image URL**: Link to item image
- **Notes**: Internal notes (not shown to customers)

### Customizations (Advanced)
Use simple text format: "Group: Option1(+price), Option2(+price)"

**Examples:**
- Size: Small(+0), Large(+2.00)
- Protein*: Chicken(+3.00), Beef(+4.00), Fish(+3.50)
- Add-ons: Cheese(+1.50), Bacon(+2.00)

**Rules:**
- Groups separated by semicolons (;)
- Options separated by commas (,)
- Prices in parentheses with + sign
- Required groups marked with asterisk (*)

**Full Example:**
Size*: Small(+0), Large(+2.00); Add-ons: Cheese(+1.50), Bacon(+2.00); Spice Level: Mild(+0), Hot(+0)

## Tips for Success
1. **Start Small**: Import 5-10 items first to test
2. **Use Sample Data**: Modify the provided examples
3. **Keep Names Unique**: Each item name should be different
4. **Consistent Categories**: Use the same category names
5. **Test Customizations**: Start with simple options
6. **Check Prices**: Ensure all prices are positive numbers
7. **Save as CSV**: Most spreadsheet apps can export to CSV

## Common Mistakes to Avoid
- Don't use special characters in item names
- Don't leave required fields empty
- Don't use negative prices
- Don't mix Yes/No with Y/N in the same file
- Don't use complex customization formats initially

## Need Help?
- Check the sample data for examples
- Use the simplified format for customizations
- Contact support if you encounter issues
''';
  }
}
