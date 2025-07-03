import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../models/menu_import_data.dart';

/// Service for handling bulk menu import from CSV/Excel files
class MenuImportService {
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxRows = 1000; // Maximum rows to process

  /// Expected column headers for CSV/Excel files
  static const Map<String, String> expectedHeaders = {
    'name': 'Item Name',
    'description': 'Description',
    'category': 'Category',
    'base_price': 'Base Price (RM)',
    'unit': 'Unit',
    'min_order_quantity': 'Min Order Qty',
    'max_order_quantity': 'Max Order Qty',
    'preparation_time_minutes': 'Prep Time (min)',
    'is_available': 'Available (Y/N)',
    'is_halal': 'Halal (Y/N)',
    'is_vegetarian': 'Vegetarian (Y/N)',
    'is_vegan': 'Vegan (Y/N)',
    'is_spicy': 'Spicy (Y/N)',
    'spicy_level': 'Spicy Level (1-5)',
    'allergens': 'Allergens',
    'tags': 'Tags',
    'image_url': 'Image URL',
    'nutritional_info': 'Nutritional Info (JSON)',
    'bulk_price': 'Bulk Price (RM)',
    'bulk_min_quantity': 'Bulk Min Qty',
    'customization_groups': 'Customizations (JSON)',
  };

  /// Pick and process import file
  Future<MenuImportResult?> pickAndProcessFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      return await processFile(file);
    } catch (e) {
      debugPrint('Error picking file: $e');
      rethrow;
    }
  }

  /// Process uploaded file
  Future<MenuImportResult> processFile(PlatformFile file) async {
    // Validate file
    _validateFile(file);

    final extension = path.extension(file.name).toLowerCase();
    final fileData = file.bytes!;

    List<List<dynamic>> rows;

    if (extension == '.csv') {
      rows = await _processCsvFile(fileData);
    } else if (extension == '.xlsx' || extension == '.xls') {
      rows = await _processExcelFile(fileData);
    } else {
      throw Exception('Unsupported file format: $extension');
    }

    return await _parseRowsToImportData(rows, file.name, extension);
  }

  /// Validate file constraints
  void _validateFile(PlatformFile file) {
    if (file.size > maxFileSize) {
      throw Exception('File size exceeds ${maxFileSize ~/ (1024 * 1024)}MB limit');
    }

    final extension = path.extension(file.name).toLowerCase();
    if (!['.csv', '.xlsx', '.xls'].contains(extension)) {
      throw Exception('Unsupported file format. Please use CSV or Excel files.');
    }

    if (file.bytes == null) {
      throw Exception('File data is not available');
    }
  }

  /// Process CSV file
  Future<List<List<dynamic>>> _processCsvFile(Uint8List fileData) async {
    try {
      final csvString = utf8.decode(fileData);
      final csvConverter = const CsvToListConverter();
      return csvConverter.convert(csvString);
    } catch (e) {
      throw Exception('Failed to parse CSV file: $e');
    }
  }

  /// Process Excel file
  Future<List<List<dynamic>>> _processExcelFile(Uint8List fileData) async {
    try {
      final excel = Excel.decodeBytes(fileData);

      // Get the first sheet
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null) {
        throw Exception('No data found in Excel file');
      }

      final rows = <List<dynamic>>[];
      for (final row in sheet.rows) {
        final rowData = row.map((cell) {
          final value = cell?.value;
          // Convert different data types to strings for consistent processing
          if (value == null) return '';
          if (value is String) return value;
          if (value is num) return value.toString();
          if (value is bool) return value.toString();
          return value.toString();
        }).toList();
        rows.add(rowData);
      }

      return rows;
    } catch (e) {
      throw Exception('Failed to parse Excel file: $e');
    }
  }

  /// Parse raw rows into structured import data
  Future<MenuImportResult> _parseRowsToImportData(
    List<List<dynamic>> rows,
    String fileName,
    String fileType,
  ) async {
    if (rows.isEmpty) {
      throw Exception('File is empty');
    }

    if (rows.length > maxRows + 1) { // +1 for header
      throw Exception('File contains too many rows. Maximum allowed: $maxRows');
    }

    // Extract and validate headers
    final headers = rows.first.map((e) => e?.toString().trim() ?? '').toList();
    final headerMap = _mapHeaders(headers);

    // Process data rows
    final importRows = <MenuImportRow>[];
    final categories = <String>{};
    int validRows = 0;
    int errorRows = 0;
    int warningRows = 0;

    for (int i = 1; i < rows.length; i++) {
      final rowData = rows[i];
      final importRow = await _parseDataRow(rowData, headerMap, i + 1);
      
      importRows.add(importRow);
      
      if (importRow.hasErrors) {
        errorRows++;
      } else {
        validRows++;
        categories.add(importRow.category);
      }
      
      if (importRow.hasWarnings) {
        warningRows++;
      }
    }

    return MenuImportResult(
      rows: importRows,
      categories: categories.toList()..sort(),
      totalRows: importRows.length,
      validRows: validRows,
      errorRows: errorRows,
      warningRows: warningRows,
      importedAt: DateTime.now(),
      fileName: fileName,
      fileType: fileType,
    );
  }

  /// Map file headers to expected fields
  Map<String, int> _mapHeaders(List<String> headers) {
    final headerMap = <String, int>{};
    
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i].toLowerCase().trim();
      
      // Try to match with expected headers
      for (final entry in expectedHeaders.entries) {
        final expectedHeader = entry.value.toLowerCase();
        if (header == expectedHeader || 
            header.contains(entry.key.replaceAll('_', ' ')) ||
            header.contains(entry.key.replaceAll('_', ''))) {
          headerMap[entry.key] = i;
          break;
        }
      }
    }

    // Validate required headers
    final requiredFields = ['name', 'category', 'base_price'];
    final missingFields = requiredFields.where((field) => !headerMap.containsKey(field)).toList();
    
    if (missingFields.isNotEmpty) {
      throw Exception('Missing required columns: ${missingFields.join(', ')}');
    }

    return headerMap;
  }

  /// Parse a single data row
  Future<MenuImportRow> _parseDataRow(
    List<dynamic> rowData,
    Map<String, int> headerMap,
    int rowNumber,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];

    // Helper function to get cell value
    String? getCellValue(String field) {
      final index = headerMap[field];
      if (index == null || index >= rowData.length) return null;
      final value = rowData[index];
      return value?.toString().trim();
    }

    // Helper function to parse boolean
    bool? parseBool(String field) {
      final value = getCellValue(field);
      if (value == null || value.isEmpty) return null;
      final lower = value.toLowerCase();
      if (['y', 'yes', 'true', '1'].contains(lower)) return true;
      if (['n', 'no', 'false', '0'].contains(lower)) return false;
      warnings.add('Invalid boolean value for $field: $value');
      return null;
    }

    // Helper function to parse double
    double? parseDouble(String field) {
      final value = getCellValue(field);
      if (value == null || value.isEmpty) return null;
      try {
        return double.parse(value.replaceAll('RM', '').replaceAll(',', '').trim());
      } catch (e) {
        errors.add('Invalid number for $field: $value');
        return null;
      }
    }

    // Helper function to parse int
    int? parseInt(String field) {
      final value = getCellValue(field);
      if (value == null || value.isEmpty) return null;
      try {
        return int.parse(value);
      } catch (e) {
        errors.add('Invalid integer for $field: $value');
        return null;
      }
    }

    // Parse required fields
    final name = getCellValue('name');
    if (name == null || name.isEmpty) {
      errors.add('Item name is required');
    }

    final category = getCellValue('category');
    if (category == null || category.isEmpty) {
      errors.add('Category is required');
    }

    final basePrice = parseDouble('base_price');
    if (basePrice == null) {
      errors.add('Base price is required');
    } else if (basePrice < 0) {
      errors.add('Base price cannot be negative');
    }

    // Parse optional fields
    final description = getCellValue('description');
    final unit = getCellValue('unit') ?? 'pax';
    final minOrderQuantity = parseInt('min_order_quantity');
    final maxOrderQuantity = parseInt('max_order_quantity');
    final preparationTimeMinutes = parseInt('preparation_time_minutes');
    final isAvailable = parseBool('is_available') ?? true;
    final isHalal = parseBool('is_halal') ?? false;
    final isVegetarian = parseBool('is_vegetarian') ?? false;
    final isVegan = parseBool('is_vegan') ?? false;
    final isSpicy = parseBool('is_spicy') ?? false;
    final spicyLevel = parseInt('spicy_level');
    final allergens = getCellValue('allergens');
    final tags = getCellValue('tags');
    final imageUrl = getCellValue('image_url');
    final nutritionalInfo = getCellValue('nutritional_info');
    final bulkPrice = parseDouble('bulk_price');
    final bulkMinQuantity = parseInt('bulk_min_quantity');
    final customizationGroups = getCellValue('customization_groups');

    // Validate spicy level
    if (spicyLevel != null && (spicyLevel < 1 || spicyLevel > 5)) {
      warnings.add('Spicy level should be between 1-5');
    }

    // Validate quantities
    if (minOrderQuantity != null && minOrderQuantity < 1) {
      warnings.add('Minimum order quantity should be at least 1');
    }

    if (maxOrderQuantity != null && minOrderQuantity != null && maxOrderQuantity < minOrderQuantity) {
      warnings.add('Maximum order quantity should be greater than minimum');
    }

    // Validate bulk pricing
    if (bulkPrice != null && bulkMinQuantity == null) {
      warnings.add('Bulk minimum quantity required when bulk price is specified');
    }

    return MenuImportRow(
      name: name ?? '',
      description: description,
      category: category ?? '',
      basePrice: basePrice ?? 0.0,
      unit: unit,
      minOrderQuantity: minOrderQuantity,
      maxOrderQuantity: maxOrderQuantity,
      preparationTimeMinutes: preparationTimeMinutes,
      isAvailable: isAvailable,
      isHalal: isHalal,
      isVegetarian: isVegetarian,
      isVegan: isVegan,
      isSpicy: isSpicy,
      spicyLevel: spicyLevel,
      allergens: allergens,
      tags: tags,
      imageUrl: imageUrl,
      nutritionalInfo: nutritionalInfo,
      bulkPrice: bulkPrice,
      bulkMinQuantity: bulkMinQuantity,
      customizationGroups: customizationGroups,
      rowNumber: rowNumber,
      errors: errors,
      warnings: warnings,
    );
  }
}
