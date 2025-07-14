import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../models/menu_export_import.dart';
import '../models/product.dart';
import '../models/menu_item.dart';
import '../repositories/menu_item_repository.dart';
import 'customization_formatter.dart';

/// Service for exporting menu data
class MenuExportService {
  final MenuItemRepository _menuItemRepository;

  MenuExportService({
    required MenuItemRepository menuItemRepository,
  }) : _menuItemRepository = menuItemRepository;

  /// Export vendor menu to specified format
  Future<MenuExportResult> exportMenu({
    required String vendorId,
    required String vendorName,
    required ExportFormat format,
    bool includeInactiveItems = false,
    List<String>? categoryFilter,
    Function(ExportStatus)? onStatusUpdate,
    bool userFriendlyFormat = false, // New parameter for simplified CSV
  }) async {
    final exportId = DateTime.now().millisecondsSinceEpoch.toString();
    final startTime = DateTime.now();

    debugPrint('🍽️ [MENU-EXPORT] Starting export for vendor: $vendorId, format: ${format.name}');

    try {
      // Update status: Preparing
      onStatusUpdate?.call(ExportStatus.preparing);

      // Fetch menu data
      final menuItems = await _fetchMenuItems(
        vendorId,
        includeInactiveItems: includeInactiveItems,
        categoryFilter: categoryFilter,
      );

      final categories = await _fetchCategories(vendorId);

      debugPrint('🍽️ [MENU-EXPORT] Fetched ${menuItems.length} items and ${categories.length} categories');

      // Update status: Exporting
      onStatusUpdate?.call(ExportStatus.exporting);

      // Create export data
      final exportData = MenuExportData(
        vendorId: vendorId,
        vendorName: vendorName,
        exportedAt: DateTime.now(),
        menuItems: menuItems,
        categories: categories,
        totalItems: menuItems.length,
        totalCategories: categories.length,
        metadata: {
          'includeInactiveItems': includeInactiveItems,
          'categoryFilter': categoryFilter,
          'exportFormat': format.name,
        },
      );

      // Update status: Generating
      onStatusUpdate?.call(ExportStatus.generating);

      // Generate file based on format
      String filePath;
      String fileName;
      int fileSize;

      switch (format) {
        case ExportFormat.json:
          final result = await _generateJsonFile(exportData, vendorName);
          filePath = result['filePath'];
          fileName = result['fileName'];
          fileSize = result['fileSize'];
          break;
        case ExportFormat.csv:
          final result = userFriendlyFormat
            ? await _generateUserFriendlyCsvFile(exportData, vendorName)
            : await _generateCsvFile(exportData, vendorName);
          filePath = result['filePath'];
          fileName = result['fileName'];
          fileSize = result['fileSize'];
          break;
      }

      debugPrint('🍽️ [MENU-EXPORT] Generated file: $fileName (${_formatFileSize(fileSize)})');

      // Update status: Completed
      onStatusUpdate?.call(ExportStatus.completed);

      return MenuExportResult(
        id: exportId,
        vendorId: vendorId,
        format: format,
        status: ExportStatus.completed,
        filePath: filePath,
        fileName: fileName,
        fileSize: fileSize,
        totalItems: menuItems.length,
        totalCategories: categories.length,
        startedAt: startTime,
        completedAt: DateTime.now(),
      );

    } catch (e) {
      debugPrint('❌ [MENU-EXPORT] Export failed: $e');
      onStatusUpdate?.call(ExportStatus.failed);

      return MenuExportResult(
        id: exportId,
        vendorId: vendorId,
        format: format,
        status: ExportStatus.failed,
        totalItems: 0,
        totalCategories: 0,
        startedAt: startTime,
        completedAt: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }

  /// Share exported file
  Future<void> shareExportedFile(MenuExportResult exportResult) async {
    if (!exportResult.isSuccessful || exportResult.filePath == null) {
      throw Exception('Export file not available for sharing');
    }

    try {
      debugPrint('🍽️ [MENU-EXPORT] Sharing file: ${exportResult.fileName}');

      await Share.shareXFiles(
        [XFile(exportResult.filePath!)],
        text: 'Menu Export - ${exportResult.fileName}',
        subject: 'GigaEats Menu Export',
      );

      debugPrint('🍽️ [MENU-EXPORT] File shared successfully');
    } catch (e) {
      debugPrint('❌ [MENU-EXPORT] Failed to share file: $e');
      rethrow;
    }
  }



  /// Fetch menu items for export
  Future<List<Product>> _fetchMenuItems(
    String vendorId, {
    bool includeInactiveItems = false,
    List<String>? categoryFilter,
  }) async {
    try {
      final items = await _menuItemRepository.getMenuItems(
        vendorId,
        isAvailable: includeInactiveItems ? null : true,
      );

      // Apply category filter if specified
      if (categoryFilter != null && categoryFilter.isNotEmpty) {
        return items.where((item) => categoryFilter.contains(item.category)).toList();
      }

      return items;
    } catch (e) {
      debugPrint('❌ [MENU-EXPORT] Failed to fetch menu items: $e');
      rethrow;
    }
  }

  /// Fetch categories for export
  Future<List<MenuCategory>> _fetchCategories(String vendorId) async {
    try {
      // Note: This would need to be implemented in the repository
      // For now, extract unique categories from menu items
      final items = await _menuItemRepository.getMenuItems(vendorId);
      final categoryNames = items.map((item) => item.category).toSet().toList();
      
      return categoryNames.map((name) => MenuCategory(
        id: name.toLowerCase().replaceAll(' ', '_'),
        vendorId: vendorId,
        name: name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )).toList();
    } catch (e) {
      debugPrint('❌ [MENU-EXPORT] Failed to fetch categories: $e');
      return [];
    }
  }

  /// Generate JSON export file
  Future<Map<String, dynamic>> _generateJsonFile(
    MenuExportData exportData,
    String vendorName,
  ) async {
    try {
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData.toJson());
      final bytes = utf8.encode(jsonString);

      final fileName = _generateFileName(vendorName, 'json');
      final filePath = await _saveFile(bytes, fileName);

      return {
        'filePath': filePath,
        'fileName': fileName,
        'fileSize': bytes.length,
      };
    } catch (e) {
      debugPrint('❌ [MENU-EXPORT] Failed to generate JSON file: $e');
      rethrow;
    }
  }

  /// Generate CSV export file
  Future<Map<String, dynamic>> _generateCsvFile(
    MenuExportData exportData,
    String vendorName,
  ) async {
    try {
      final csvData = _convertToCSV(exportData);
      final csvString = const ListToCsvConverter().convert(csvData);
      final bytes = utf8.encode(csvString);

      final fileName = _generateFileName(vendorName, 'csv');
      final filePath = await _saveFile(bytes, fileName);

      return {
        'filePath': filePath,
        'fileName': fileName,
        'fileSize': bytes.length,
      };
    } catch (e) {
      debugPrint('❌ [MENU-EXPORT] Failed to generate CSV file: $e');
      rethrow;
    }
  }

  /// Generate user-friendly CSV export file
  Future<Map<String, dynamic>> _generateUserFriendlyCsvFile(
    MenuExportData exportData,
    String vendorName,
  ) async {
    try {
      final csvData = _convertToUserFriendlyCSV(exportData);
      final csvString = const ListToCsvConverter().convert(csvData);
      final bytes = utf8.encode(csvString);

      final fileName = _generateUserFriendlyFileName(vendorName, 'csv');
      final filePath = await _saveFile(bytes, fileName);

      return {
        'filePath': filePath,
        'fileName': fileName,
        'fileSize': bytes.length,
      };
    } catch (e) {
      debugPrint('❌ [MENU-EXPORT] Failed to generate user-friendly CSV file: $e');
      rethrow;
    }
  }

  /// Convert export data to CSV format
  List<List<dynamic>> _convertToCSV(MenuExportData exportData) {
    final rows = <List<dynamic>>[];

    // Add headers
    rows.add([
      'ID',
      'Name',
      'Description',
      'Category',
      'Base Price',
      'Bulk Price',
      'Bulk Min Quantity',
      'Currency',
      'Includes SST',
      'Is Available',
      'Min Order Quantity',
      'Max Order Quantity',
      'Preparation Time (minutes)',
      'Allergens',
      'Is Halal',
      'Is Vegetarian',
      'Is Vegan',
      'Is Spicy',
      'Spicy Level',
      'Image URL',
      'Gallery Images',
      'Tags',
      'Nutrition Info',
      'Rating',
      'Total Reviews',
      'Is Featured',
      'Customizations',
      'Created At',
      'Updated At',
    ]);

    // Add menu items
    for (final item in exportData.menuItems) {
      rows.add([
        item.id,
        item.name,
        item.description ?? '',
        item.category,
        item.basePrice,
        item.bulkPrice ?? '',
        item.bulkMinQuantity ?? '',
        item.currency ?? 'MYR',
        item.includesSst ?? false,
        item.isAvailable ?? true,
        item.minOrderQuantity ?? 1,
        item.maxOrderQuantity ?? '',
        item.preparationTimeMinutes ?? 30,
        item.allergens.join(';'),
        item.isHalal ?? false,
        item.isVegetarian ?? false,
        item.isVegan ?? false,
        item.isSpicy ?? false,
        item.spicyLevel ?? '',
        item.imageUrl ?? '',
        item.galleryImages.join(';'),
        item.tags.join(';'),
        item.nutritionInfo != null ? jsonEncode(item.nutritionInfo) : '',
        item.rating ?? '',
        item.totalReviews ?? 0,
        item.isFeatured ?? false,
        item.customizations.isNotEmpty ? jsonEncode(item.customizations.map((c) => c.toJson()).toList()) : '',
        item.createdAt?.toIso8601String() ?? '',
        item.updatedAt?.toIso8601String() ?? '',
      ]);
    }

    return rows;
  }

  /// Convert export data to user-friendly CSV format
  List<List<dynamic>> _convertToUserFriendlyCSV(MenuExportData exportData) {
    final rows = <List<dynamic>>[];

    // Add user-friendly headers
    rows.add([
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
    ]);

    // Add menu items with user-friendly formatting
    for (final item in exportData.menuItems) {
      rows.add([
        item.name,
        item.description ?? '',
        item.category,
        item.basePrice.toStringAsFixed(2),
        item.isAvailable == true ? 'Yes' : 'No',
        'pax', // Default unit since Product model doesn't have unit field
        item.minOrderQuantity ?? 1,
        item.maxOrderQuantity ?? '',
        item.preparationTimeMinutes ?? 30,
        item.isHalal == true ? 'Yes' : 'No',
        item.isVegetarian == true ? 'Yes' : 'No',
        item.isVegan == true ? 'Yes' : 'No',
        item.isSpicy == true ? 'Yes' : 'No',
        item.spicyLevel ?? '',
        item.allergens.join(', '),
        item.tags.join(', '),
        item.bulkPrice?.toStringAsFixed(2) ?? '',
        item.bulkMinQuantity ?? '',
        item.imageUrl ?? '',
        CustomizationFormatter.formatCustomizationsToText(item.customizations),
        '', // Notes field for vendor use
      ]);
    }

    return rows;
  }

  /// Generate unique filename
  String _generateFileName(String vendorName, String extension) {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final cleanVendorName = vendorName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    return 'gigaeats_menu_${cleanVendorName}_$timestamp.$extension';
  }

  /// Generate user-friendly filename
  String _generateUserFriendlyFileName(String vendorName, String extension) {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final cleanVendorName = vendorName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    return 'gigaeats_menu_simplified_${cleanVendorName}_$timestamp.$extension';
  }

  /// Save file to device storage and make it accessible
  Future<String> _saveFile(List<int> bytes, String fileName) async {
    try {
      // Always save to app documents directory for now (this is what was working before)
      // The sharing mechanism will handle making it accessible to users
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);

      debugPrint('🍽️ [MENU-EXPORT] File saved to: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('❌ [MENU-EXPORT] Failed to save file: $e');
      rethrow;
    }
  }

  /// Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
