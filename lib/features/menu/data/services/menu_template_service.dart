
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
    final headers = MenuImportService.expectedHeaders.values.toList();
    final rows = <List<String>>[headers];

    if (includeSampleData) {
      rows.addAll(_getSampleData());
    }

    final csvConverter = const ListToCsvConverter();
    return csvConverter.convert(rows);
  }

  /// Generate Excel template with sample data
  Future<Uint8List> generateExcelTemplate({bool includeSampleData = true}) async {
    final excel = Excel.createExcel();
    final sheet = excel['Menu Items'];

    // Add headers
    final headers = MenuImportService.expectedHeaders.values.toList();
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

    // Add sample data if requested
    if (includeSampleData) {
      final sampleData = _getSampleData();
      for (int rowIndex = 0; rowIndex < sampleData.length; rowIndex++) {
        final row = sampleData[rowIndex];
        for (int colIndex = 0; colIndex < row.length; colIndex++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: colIndex, 
            rowIndex: rowIndex + 1,
          ));
          cell.value = TextCellValue(row[colIndex]);
        }
      }
    }

    // Auto-fit columns
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 15.0);
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

  /// Save file and share on mobile platforms
  Future<void> _saveAndShareFile(Uint8List data, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(data);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'GigaEats Menu Import Template',
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
}
