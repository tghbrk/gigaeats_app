import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../models/menu_export_import.dart';
import '../models/menu_import_data.dart' as import_data;
import '../models/product.dart';
import '../repositories/menu_item_repository.dart';
import 'customization_formatter.dart';

/// Enhanced service for handling bulk menu import from CSV/Excel/JSON files
class MenuImportService {
  final MenuItemRepository _menuItemRepository;

  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxRows = 1000; // Maximum rows to process

  MenuImportService({
    required MenuItemRepository menuItemRepository,
  }) : _menuItemRepository = menuItemRepository;

  /// Expected column headers for CSV/Excel files
  static const Map<String, List<String>> expectedHeaders = {
    'name': ['Item Name', 'Name'],
    'description': ['Description'],
    'category': ['Category'],
    'base_price': ['Price (RM)', 'Base Price (RM)', 'Price'],
    'unit': ['Unit'],
    'min_order_quantity': ['Min Order', 'Min Order Qty', 'Min Order Quantity'],
    'max_order_quantity': ['Max Order', 'Max Order Qty', 'Max Order Quantity'],
    'preparation_time_minutes': ['Prep Time (min)', 'Preparation Time (min)', 'Prep Time'],
    'is_available': ['Available', 'Available (Y/N)', 'Is Available'],
    'is_halal': ['Halal', 'Halal (Y/N)', 'Is Halal'],
    'is_vegetarian': ['Vegetarian', 'Vegetarian (Y/N)', 'Is Vegetarian'],
    'is_vegan': ['Vegan', 'Vegan (Y/N)', 'Is Vegan'],
    'is_spicy': ['Spicy', 'Spicy (Y/N)', 'Is Spicy'],
    'spicy_level': ['Spicy Level', 'Spicy Level (1-5)'],
    'allergens': ['Allergens'],
    'tags': ['Tags'],
    'image_url': ['Image URL'],
    'nutritional_info': ['Nutritional Info (JSON)', 'Nutrition Info'],
    'bulk_price': ['Bulk Price (RM)', 'Bulk Price'],
    'bulk_min_quantity': ['Bulk Min Qty', 'Bulk Min Quantity'],
    'customization_groups': ['Customizations', 'Customizations (JSON)'],
    'notes': ['Notes'], // New field for user-friendly format
  };

  /// Pick and process import file with conflict resolution
  Future<MenuImportResult?> pickAndProcessFile({
    required String vendorId,
    ImportConflictResolution conflictResolution = ImportConflictResolution.skip,
    Function(ImportStatus)? onStatusUpdate,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls', 'json'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      return await processFile(
        file,
        vendorId: vendorId,
        conflictResolution: conflictResolution,
        onStatusUpdate: onStatusUpdate,
      );
    } catch (e) {
      debugPrint('❌ [MENU-IMPORT] Error picking file: $e');
      rethrow;
    }
  }

  /// Process uploaded file with enhanced features
  Future<MenuImportResult> processFile(
    PlatformFile file, {
    required String vendorId,
    ImportConflictResolution conflictResolution = ImportConflictResolution.skip,
    Function(ImportStatus)? onStatusUpdate,
  }) async {
    final importId = DateTime.now().millisecondsSinceEpoch.toString();
    final startTime = DateTime.now();

    debugPrint('🍽️ [MENU-IMPORT] Starting import for vendor: $vendorId, file: ${file.name}');

    try {
      // Update status: Validating
      onStatusUpdate?.call(ImportStatus.validating);

      // Validate file
      _validateFile(file);

      final extension = path.extension(file.name).toLowerCase();
      final fileData = file.bytes!;

      // Update status: Processing
      onStatusUpdate?.call(ImportStatus.processing);

      List<Product> menuItems;

      if (extension == '.json') {
        menuItems = await _processJsonFile(fileData);
      } else {
        // Process CSV/Excel and convert to Product objects
        List<List<dynamic>> rows;
        if (extension == '.csv') {
          rows = await _processCsvFile(fileData);
        } else if (extension == '.xlsx' || extension == '.xls') {
          rows = await _processExcelFile(fileData);
        } else {
          throw Exception('Unsupported file format: $extension');
        }
        menuItems = await _convertRowsToProducts(rows, vendorId);
      }

      // Update status: Importing
      onStatusUpdate?.call(ImportStatus.importing);

      // Process import with conflict resolution
      final result = await _performImport(
        menuItems,
        vendorId,
        conflictResolution,
        file.name,
        importId,
        startTime,
      );

      // Update status: Completed
      onStatusUpdate?.call(ImportStatus.completed);

      return result;

    } catch (e) {
      debugPrint('❌ [MENU-IMPORT] Import failed: $e');
      onStatusUpdate?.call(ImportStatus.failed);

      return MenuImportResult(
        id: importId,
        vendorId: vendorId,
        fileName: file.name,
        status: ImportStatus.failed,
        totalRows: 0,
        validRows: 0,
        importedRows: 0,
        skippedRows: 0,
        errorRows: 0,
        conflictResolution: conflictResolution,
        startedAt: startTime,
        completedAt: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }

  /// Validate file constraints
  void _validateFile(PlatformFile file) {
    if (file.size > maxFileSize) {
      throw Exception('File size exceeds ${maxFileSize ~/ (1024 * 1024)}MB limit');
    }

    final extension = path.extension(file.name).toLowerCase();
    if (!['.csv', '.xlsx', '.xls', '.json'].contains(extension)) {
      throw Exception('Unsupported file format. Please use CSV, Excel, or JSON files.');
    }

    if (file.bytes == null) {
      throw Exception('File data is not available');
    }
  }

  /// Process file for preview without importing
  Future<import_data.MenuImportResult> processFileForPreview(
    PlatformFile file, {
    required String vendorId,
    Function(ImportStatus)? onStatusUpdate,
  }) async {
    final startTime = DateTime.now();

    debugPrint('🍽️ [MENU-IMPORT] Processing file for preview: ${file.name}');

    try {
      // Update status: Validating
      onStatusUpdate?.call(ImportStatus.validating);

      // Validate file
      _validateFile(file);

      final extension = path.extension(file.name).toLowerCase();
      final fileData = file.bytes!;

      // Update status: Processing
      onStatusUpdate?.call(ImportStatus.processing);

      List<import_data.MenuImportRow> rows;

      if (extension == '.json') {
        rows = await _processJsonFileForPreview(fileData, vendorId);
      } else {
        // Process CSV/Excel and convert to MenuImportRow objects
        List<List<dynamic>> rawRows;
        if (extension == '.csv') {
          rawRows = await _processCsvFile(fileData);
        } else if (extension == '.xlsx' || extension == '.xls') {
          rawRows = await _processExcelFile(fileData);
        } else {
          throw Exception('Unsupported file format: $extension');
        }
        rows = await _convertRowsToImportRows(rawRows, vendorId);
      }

      // Update status: Completed
      onStatusUpdate?.call(ImportStatus.completed);

      // Create detailed result for preview
      final validRows = rows.where((row) => row.isValid).length;
      final errorRows = rows.where((row) => row.hasErrors).length;
      final warningRows = rows.where((row) => row.hasWarnings && !row.hasErrors).length;

      return import_data.MenuImportResult(
        rows: rows,
        categories: _extractCategories(rows),
        totalRows: rows.length,
        validRows: validRows,
        errorRows: errorRows,
        warningRows: warningRows,
        importedAt: startTime,
        fileName: file.name,
        fileType: extension,
      );

    } catch (e) {
      debugPrint('❌ [MENU-IMPORT] Preview processing failed: $e');
      onStatusUpdate?.call(ImportStatus.failed);

      final extension = path.extension(file.name).toLowerCase();
      return import_data.MenuImportResult(
        rows: [],
        categories: [],
        totalRows: 0,
        validRows: 0,
        errorRows: 1,
        warningRows: 0,
        importedAt: startTime,
        fileName: file.name,
        fileType: extension,
      );
    }
  }

  /// Process JSON file for preview
  Future<List<import_data.MenuImportRow>> _processJsonFileForPreview(
    Uint8List fileData,
    String vendorId,
  ) async {
    try {
      final jsonString = utf8.decode(fileData);
      final jsonData = jsonDecode(jsonString);
      final rows = <import_data.MenuImportRow>[];

      List<Product> products = [];

      if (jsonData is Map<String, dynamic>) {
        // Handle MenuExportData format
        if (jsonData.containsKey('menuItems')) {
          final exportData = MenuExportData.fromJson(jsonData);
          products = exportData.menuItems;
        }
        // Handle single Product
        else if (jsonData.containsKey('name') && jsonData.containsKey('basePrice')) {
          products = [Product.fromJson(jsonData)];
        }
      } else if (jsonData is List) {
        // Handle array of Products
        products = jsonData.map((item) => Product.fromJson(item as Map<String, dynamic>)).toList();
      }

      // Convert products to import rows
      for (int i = 0; i < products.length; i++) {
        final product = products[i];
        rows.add(_convertProductToImportRow(product, i + 1));
      }

      return rows;
    } catch (e) {
      debugPrint('❌ [MENU-IMPORT] Error processing JSON for preview: $e');
      return [
        import_data.MenuImportRow(
          name: 'Error',
          category: 'Error',
          basePrice: 0.0,
          rowNumber: 1,
          errors: ['Failed to parse JSON file: $e'],
        ),
      ];
    }
  }

  /// Convert CSV/Excel rows to MenuImportRow objects
  Future<List<import_data.MenuImportRow>> _convertRowsToImportRows(
    List<List<dynamic>> rows,
    String vendorId,
  ) async {
    if (rows.isEmpty) return [];

    final headerMap = _mapHeaders(rows[0].map((e) => e.toString()).toList());
    final importRows = <import_data.MenuImportRow>[];

    for (int i = 1; i < rows.length; i++) {
      final rowData = rows[i];
      final rowNumber = i + 1;

      try {
        final importRow = _convertRowDataToImportRow(rowData, headerMap, rowNumber);
        importRows.add(importRow);
      } catch (e) {
        debugPrint('❌ [MENU-IMPORT] Error converting row $rowNumber: $e');
        importRows.add(
          import_data.MenuImportRow(
            name: 'Error in row $rowNumber',
            category: 'Error',
            basePrice: 0.0,
            rowNumber: rowNumber,
            errors: ['Failed to parse row: $e'],
          ),
        );
      }
    }

    return importRows;
  }

  /// Convert Product to MenuImportRow
  import_data.MenuImportRow _convertProductToImportRow(Product product, int rowNumber) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate required fields
    if (product.name.trim().isEmpty) {
      errors.add('Item name is required');
    }
    if (product.category.trim().isEmpty) {
      errors.add('Category is required');
    }
    if (product.basePrice < 0) {
      errors.add('Price must be non-negative');
    }

    // Convert customizations to text format
    String? customizationsText;
    if (product.customizations.isNotEmpty) {
      try {
        customizationsText = CustomizationFormatter.formatCustomizationsToText(product.customizations);
      } catch (e) {
        warnings.add('Could not convert customizations to text format');
      }
    }

    return import_data.MenuImportRow(
      name: product.name,
      description: product.description,
      category: product.category,
      basePrice: product.basePrice,
      unit: 'pax', // Default unit since Product model doesn't have this field
      minOrderQuantity: product.minOrderQuantity,
      maxOrderQuantity: product.maxOrderQuantity,
      preparationTimeMinutes: product.preparationTimeMinutes,
      isAvailable: product.isAvailable,
      isHalal: product.isHalal,
      isVegetarian: product.isVegetarian,
      isVegan: product.isVegan,
      isSpicy: product.isSpicy,
      spicyLevel: product.spicyLevel,
      allergens: product.allergens.join(', '),
      tags: product.tags.join(', '),
      imageUrl: product.imageUrl,
      nutritionalInfo: product.nutritionInfo != null ? jsonEncode(product.nutritionInfo) : null,
      bulkPrice: product.bulkPrice,
      bulkMinQuantity: product.bulkMinQuantity,
      customizationGroups: customizationsText,
      rowNumber: rowNumber,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Convert row data to MenuImportRow
  import_data.MenuImportRow _convertRowDataToImportRow(
    List<dynamic> rowData,
    Map<String, int> headerMap,
    int rowNumber,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    // Extract and validate required fields
    final name = _getStringValue(rowData, headerMap, 'name')?.trim() ?? '';
    if (name.isEmpty) {
      errors.add('Item name is required');
    }

    final category = _getStringValue(rowData, headerMap, 'category')?.trim() ?? '';
    if (category.isEmpty) {
      errors.add('Category is required');
    }

    final basePrice = _getDoubleValue(rowData, headerMap, 'base_price') ?? 0.0;
    if (basePrice < 0) {
      errors.add('Price must be non-negative');
    }

    // Extract optional fields with validation
    final spicyLevel = _getIntValue(rowData, headerMap, 'spicy_level');
    if (spicyLevel != null && (spicyLevel < 1 || spicyLevel > 5)) {
      warnings.add('Spicy level should be between 1 and 5');
    }

    final minOrderQuantity = _getIntValue(rowData, headerMap, 'min_order_quantity');
    final maxOrderQuantity = _getIntValue(rowData, headerMap, 'max_order_quantity');
    if (minOrderQuantity != null && maxOrderQuantity != null && minOrderQuantity > maxOrderQuantity) {
      warnings.add('Minimum order quantity cannot be greater than maximum');
    }

    // Validate customizations format
    final customizationsStr = _getStringValue(rowData, headerMap, 'customization_groups');
    if (customizationsStr != null && customizationsStr.isNotEmpty) {
      final validation = CustomizationFormatter.validateCustomizationText(customizationsStr);
      if (!validation.isValid) {
        errors.add('Invalid customization format: ${validation.message}');
      }
    }

    return import_data.MenuImportRow(
      name: name,
      description: _getStringValue(rowData, headerMap, 'description'),
      category: category,
      basePrice: basePrice,
      unit: _getStringValue(rowData, headerMap, 'unit'),
      minOrderQuantity: minOrderQuantity,
      maxOrderQuantity: maxOrderQuantity,
      preparationTimeMinutes: _getIntValue(rowData, headerMap, 'preparation_time_minutes'),
      isAvailable: _getBoolValue(rowData, headerMap, 'is_available'),
      isHalal: _getBoolValue(rowData, headerMap, 'is_halal'),
      isVegetarian: _getBoolValue(rowData, headerMap, 'is_vegetarian'),
      isVegan: _getBoolValue(rowData, headerMap, 'is_vegan'),
      isSpicy: _getBoolValue(rowData, headerMap, 'is_spicy'),
      spicyLevel: spicyLevel,
      allergens: _getStringValue(rowData, headerMap, 'allergens'),
      tags: _getStringValue(rowData, headerMap, 'tags'),
      imageUrl: _getStringValue(rowData, headerMap, 'image_url'),
      nutritionalInfo: _getStringValue(rowData, headerMap, 'nutritional_info'),
      bulkPrice: _getDoubleValue(rowData, headerMap, 'bulk_price'),
      bulkMinQuantity: _getIntValue(rowData, headerMap, 'bulk_min_quantity'),
      customizationGroups: customizationsStr,
      rowNumber: rowNumber,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Extract categories from import rows
  List<String> _extractCategories(List<import_data.MenuImportRow> rows) {
    final categories = <String>{};
    for (final row in rows) {
      if (row.category.isNotEmpty && row.isValid) {
        categories.add(row.category);
      }
    }
    return categories.toList()..sort();
  }

  /// Process JSON file
  Future<List<Product>> _processJsonFile(Uint8List fileData) async {
    try {
      final jsonString = utf8.decode(fileData);
      final jsonData = jsonDecode(jsonString);

      if (jsonData is Map<String, dynamic>) {
        // Handle MenuExportData format
        if (jsonData.containsKey('menuItems')) {
          final exportData = MenuExportData.fromJson(jsonData);
          return exportData.menuItems;
        }
        // Handle single Product
        else if (jsonData.containsKey('name') && jsonData.containsKey('basePrice')) {
          return [Product.fromJson(jsonData)];
        }
      } else if (jsonData is List) {
        // Handle array of Products
        return jsonData.map((item) => Product.fromJson(item as Map<String, dynamic>)).toList();
      }

      throw Exception('Invalid JSON format. Expected MenuExportData, Product, or array of Products.');
    } catch (e) {
      debugPrint('❌ [MENU-IMPORT] Failed to parse JSON file: $e');
      throw Exception('Failed to parse JSON file: $e');
    }
  }

  /// Convert CSV/Excel rows to Product objects
  Future<List<Product>> _convertRowsToProducts(List<List<dynamic>> rows, String vendorId) async {
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
    final products = <Product>[];
    final errors = <ImportValidationError>[];

    for (int i = 1; i < rows.length; i++) {
      final rowData = rows[i];
      try {
        final product = await _parseRowToProduct(rowData, headerMap, i + 1, vendorId);
        if (product != null) {
          products.add(product);
        }
      } catch (e) {
        errors.add(ImportValidationError(
          row: i + 1,
          field: 'general',
          message: e.toString(),
          severity: 'error',
        ));
      }
    }

    if (errors.isNotEmpty && products.isEmpty) {
      throw Exception('No valid products found. ${errors.length} errors encountered.');
    }

    return products;
  }

  /// Parse a single row to Product object
  Future<Product?> _parseRowToProduct(
    List<dynamic> rowData,
    Map<String, int> headerMap,
    int rowNumber,
    String vendorId,
  ) async {
    try {
      // Extract required fields
      final name = _getStringValue(rowData, headerMap, 'name')?.trim();
      final category = _getStringValue(rowData, headerMap, 'category')?.trim();
      final basePriceStr = _getStringValue(rowData, headerMap, 'base_price');

      if (name == null || name.isEmpty) {
        throw Exception('Item name is required');
      }

      if (category == null || category.isEmpty) {
        throw Exception('Category is required');
      }

      double? basePrice;
      if (basePriceStr != null && basePriceStr.isNotEmpty) {
        basePrice = double.tryParse(basePriceStr.replaceAll(RegExp(r'[^\d.]'), ''));
        if (basePrice == null || basePrice < 0) {
          throw Exception('Invalid base price: $basePriceStr');
        }
      } else {
        throw Exception('Base price is required');
      }

      // Parse optional fields
      final description = _getStringValue(rowData, headerMap, 'description');
      final currency = _getStringValue(rowData, headerMap, 'currency') ?? 'MYR';

      // Parse boolean fields
      final isAvailable = _getBoolValue(rowData, headerMap, 'is_available') ?? true;
      final isHalal = _getBoolValue(rowData, headerMap, 'is_halal') ?? false;
      final isVegetarian = _getBoolValue(rowData, headerMap, 'is_vegetarian') ?? false;
      final isVegan = _getBoolValue(rowData, headerMap, 'is_vegan') ?? false;
      final isSpicy = _getBoolValue(rowData, headerMap, 'is_spicy') ?? false;
      final includesSst = _getBoolValue(rowData, headerMap, 'includes_sst') ?? false;
      final isFeatured = _getBoolValue(rowData, headerMap, 'is_featured') ?? false;

      // Parse numeric fields
      final minOrderQuantity = _getIntValue(rowData, headerMap, 'min_order_quantity') ?? 1;
      final maxOrderQuantity = _getIntValue(rowData, headerMap, 'max_order_quantity');
      final preparationTimeMinutes = _getIntValue(rowData, headerMap, 'preparation_time_minutes') ?? 30;
      final spicyLevel = _getIntValue(rowData, headerMap, 'spicy_level');
      final totalReviews = _getIntValue(rowData, headerMap, 'total_reviews') ?? 0;

      // Parse bulk pricing
      final bulkPriceStr = _getStringValue(rowData, headerMap, 'bulk_price');
      double? bulkPrice;
      if (bulkPriceStr != null && bulkPriceStr.isNotEmpty) {
        bulkPrice = double.tryParse(bulkPriceStr.replaceAll(RegExp(r'[^\d.]'), ''));
      }
      final bulkMinQuantity = _getIntValue(rowData, headerMap, 'bulk_min_quantity');

      // Parse arrays
      final allergens = _getStringValue(rowData, headerMap, 'allergens')
          ?.split(';')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList() ?? [];

      final tags = _getStringValue(rowData, headerMap, 'tags')
          ?.split(';')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList() ?? [];

      final galleryImagesStr = _getStringValue(rowData, headerMap, 'gallery_images');
      final galleryImages = galleryImagesStr?.split(';')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList() ?? [];

      // Parse JSON fields
      Map<String, dynamic>? nutritionInfo;
      final nutritionInfoStr = _getStringValue(rowData, headerMap, 'nutritional_info');
      if (nutritionInfoStr != null && nutritionInfoStr.isNotEmpty) {
        try {
          nutritionInfo = jsonDecode(nutritionInfoStr) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('⚠️ [MENU-IMPORT] Invalid nutrition info JSON at row $rowNumber: $e');
        }
      }

      // Parse customizations (supports both JSON and simplified text format)
      List<MenuItemCustomization> customizations = [];
      final customizationsStr = _getStringValue(rowData, headerMap, 'customization_groups');
      if (customizationsStr != null && customizationsStr.isNotEmpty) {
        try {
          // Try to parse as JSON first (technical format)
          if (customizationsStr.trim().startsWith('[') || customizationsStr.trim().startsWith('{')) {
            final customizationData = jsonDecode(customizationsStr) as List;
            customizations = customizationData
                .map((item) => MenuItemCustomization.fromJson(item as Map<String, dynamic>))
                .toList();
          } else {
            // Parse as simplified text format (user-friendly format)
            customizations = CustomizationFormatter.parseCustomizationsFromText(customizationsStr);
          }
        } catch (e) {
          debugPrint('⚠️ [MENU-IMPORT] Invalid customizations format at row $rowNumber: $e');
          // Try the other format as fallback
          try {
            if (customizationsStr.trim().startsWith('[') || customizationsStr.trim().startsWith('{')) {
              // If JSON failed, try text format
              customizations = CustomizationFormatter.parseCustomizationsFromText(customizationsStr);
            } else {
              // If text failed, try JSON format
              final customizationData = jsonDecode(customizationsStr) as List;
              customizations = customizationData
                  .map((item) => MenuItemCustomization.fromJson(item as Map<String, dynamic>))
                  .toList();
            }
          } catch (e2) {
            debugPrint('⚠️ [MENU-IMPORT] Failed to parse customizations in any format at row $rowNumber: $e2');
            // Add user-friendly error message
            throw Exception(_getCustomizationErrorMessage(customizationsStr));
          }
        }
      }

      // Parse rating
      final ratingStr = _getStringValue(rowData, headerMap, 'rating');
      double? rating;
      if (ratingStr != null && ratingStr.isNotEmpty) {
        rating = double.tryParse(ratingStr);
        if (rating != null && (rating < 0 || rating > 5)) {
          rating = null; // Invalid rating
        }
      }

      return Product(
        id: '', // Will be generated by database
        vendorId: vendorId,
        name: name,
        description: description,
        category: category,
        tags: tags,
        basePrice: basePrice,
        bulkPrice: bulkPrice,
        bulkMinQuantity: bulkMinQuantity,
        currency: currency,
        includesSst: includesSst,
        isAvailable: isAvailable,
        minOrderQuantity: minOrderQuantity,
        maxOrderQuantity: maxOrderQuantity,
        preparationTimeMinutes: preparationTimeMinutes,
        allergens: allergens,
        isHalal: isHalal,
        isVegetarian: isVegetarian,
        isVegan: isVegan,
        isSpicy: isSpicy,
        spicyLevel: spicyLevel,
        imageUrl: _getStringValue(rowData, headerMap, 'image_url'),
        galleryImages: galleryImages,
        nutritionInfo: nutritionInfo,
        rating: rating,
        totalReviews: totalReviews,
        isFeatured: isFeatured,
        customizations: customizations,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

    } catch (e) {
      debugPrint('❌ [MENU-IMPORT] Error parsing row $rowNumber: $e');
      rethrow;
    }
  }

  /// Perform the actual import with conflict resolution
  Future<MenuImportResult> _performImport(
    List<Product> menuItems,
    String vendorId,
    ImportConflictResolution conflictResolution,
    String fileName,
    String importId,
    DateTime startTime,
  ) async {
    try {
      debugPrint('🍽️ [MENU-IMPORT] Performing import with ${conflictResolution.name} strategy');

      int importedRows = 0;
      int skippedRows = 0;
      int errorRows = 0;
      final errors = <ImportValidationError>[];
      final warnings = <ImportValidationError>[];

      // Get existing menu items for conflict detection
      final existingItems = await _menuItemRepository.getMenuItems(vendorId);
      final existingItemNames = existingItems.map((item) => item.name.toLowerCase()).toSet();

      for (int i = 0; i < menuItems.length; i++) {
        final item = menuItems[i];
        final rowNumber = i + 1;

        try {
          final itemNameLower = item.name.toLowerCase();
          final itemExists = existingItemNames.contains(itemNameLower);

          if (itemExists) {
            switch (conflictResolution) {
              case ImportConflictResolution.skip:
                skippedRows++;
                warnings.add(ImportValidationError(
                  row: rowNumber,
                  field: 'name',
                  message: 'Item "${item.name}" already exists - skipped',
                  value: item.name,
                  severity: 'warning',
                ));
                continue;

              case ImportConflictResolution.update:
                // Find existing item and update it
                final existingItem = existingItems.firstWhere(
                  (existing) => existing.name.toLowerCase() == itemNameLower,
                );
                final updatedItem = item.copyWith(id: existingItem.id);
                await _menuItemRepository.updateMenuItem(updatedItem);
                importedRows++;
                break;

              case ImportConflictResolution.replace:
                // Delete existing and create new
                final existingItem = existingItems.firstWhere(
                  (existing) => existing.name.toLowerCase() == itemNameLower,
                );
                await _menuItemRepository.deleteMenuItem(existingItem.id);
                await _menuItemRepository.createMenuItem(item);
                importedRows++;
                break;
            }
          } else {
            // Create new item
            await _menuItemRepository.createMenuItem(item);
            importedRows++;
          }

        } catch (e) {
          errorRows++;
          errors.add(ImportValidationError(
            row: rowNumber,
            field: 'general',
            message: 'Failed to import item: $e',
            value: item.name,
            severity: 'error',
          ));
          debugPrint('❌ [MENU-IMPORT] Failed to import item "${item.name}": $e');
        }
      }

      return MenuImportResult(
        id: importId,
        vendorId: vendorId,
        fileName: fileName,
        status: ImportStatus.completed,
        totalRows: menuItems.length,
        validRows: menuItems.length - errorRows,
        importedRows: importedRows,
        skippedRows: skippedRows,
        errorRows: errorRows,
        errors: errors,
        warnings: warnings,
        conflictResolution: conflictResolution,
        startedAt: startTime,
        completedAt: DateTime.now(),
        metadata: {
          'conflictResolution': conflictResolution.name,
          'existingItemsCount': existingItems.length,
        },
      );

    } catch (e) {
      debugPrint('❌ [MENU-IMPORT] Import operation failed: $e');
      rethrow;
    }
  }

  /// Helper method to get string value from row data
  String? _getStringValue(List<dynamic> rowData, Map<String, int> headerMap, String field) {
    final index = headerMap[field];
    if (index == null || index >= rowData.length) return null;
    final value = rowData[index];
    return value?.toString().trim();
  }

  /// Helper method to get boolean value from row data
  bool? _getBoolValue(List<dynamic> rowData, Map<String, int> headerMap, String field) {
    final stringValue = _getStringValue(rowData, headerMap, field);
    if (stringValue == null || stringValue.isEmpty) return null;

    final lowerValue = stringValue.toLowerCase();
    if (['true', 'yes', 'y', '1'].contains(lowerValue)) return true;
    if (['false', 'no', 'n', '0'].contains(lowerValue)) return false;
    return null;
  }

  /// Helper method to get integer value from row data
  int? _getIntValue(List<dynamic> rowData, Map<String, int> headerMap, String field) {
    final stringValue = _getStringValue(rowData, headerMap, field);
    if (stringValue == null || stringValue.isEmpty) return null;
    return int.tryParse(stringValue.replaceAll(RegExp(r'[^\d]'), ''));
  }

  /// Helper method to get double value from row data
  double? _getDoubleValue(List<dynamic> rowData, Map<String, int> headerMap, String field) {
    final stringValue = _getStringValue(rowData, headerMap, field);
    if (stringValue == null || stringValue.isEmpty) return null;
    // Allow negative numbers by preserving the minus sign
    return double.tryParse(stringValue.replaceAll(RegExp(r'[^\d.-]'), ''));
  }

  /// Process CSV file
  Future<List<List<dynamic>>> _processCsvFile(Uint8List fileData) async {
    try {
      final csvString = utf8.decode(fileData);
      const csvConverter = CsvToListConverter(
        fieldDelimiter: ',',
        textDelimiter: '"',
        eol: '\n',
      );
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



  /// Map file headers to expected fields
  Map<String, int> _mapHeaders(List<String> headers) {
    final headerMap = <String, int>{};

    for (int i = 0; i < headers.length; i++) {
      final header = headers[i].toLowerCase().trim();
      bool foundMatch = false;

      // Try to match with expected headers
      for (final entry in expectedHeaders.entries) {
        final fieldKey = entry.key;
        final possibleHeaders = entry.value;

        // Check if header matches any of the possible headers for this field
        for (final expectedHeader in possibleHeaders) {
          if (header == expectedHeader.toLowerCase() ||
              header.contains(fieldKey.replaceAll('_', ' ')) ||
              header.contains(fieldKey.replaceAll('_', ''))) {
            headerMap[fieldKey] = i;
            foundMatch = true;
            break;
          }
        }

        // If we found a match for this header, stop looking for other field matches
        if (foundMatch) {
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

  /// Generate user-friendly error message for customization parsing failures
  String _getCustomizationErrorMessage(String customizationsStr) {
    if (customizationsStr.trim().startsWith('[') || customizationsStr.trim().startsWith('{')) {
      return 'Invalid JSON format in customizations. Please check the JSON syntax or use the simplified format: "Group: Option1(+price), Option2(+price)"';
    } else {
      return 'Invalid customization format. Expected format: "Group: Option1(+price), Option2(+price); NextGroup: Option1(+price)". Example: "Size*: Small(+0), Large(+2.00); Add-ons: Cheese(+1.50)"';
    }
  }
}
