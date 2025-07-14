import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:gigaeats_app/src/features/menu/data/models/menu_export_import.dart';
import 'package:gigaeats_app/src/features/menu/data/models/product.dart';
import 'package:gigaeats_app/src/features/menu/data/services/menu_export_service.dart';
// TODO: Uncomment when import service tests are added
// import 'package:gigaeats_app/src/features/menu/data/services/menu_import_service.dart';
import 'package:gigaeats_app/src/features/menu/data/repositories/menu_item_repository.dart';

import 'import_export_test.mocks.dart';

@GenerateMocks([MenuItemRepository])
void main() {
  group('Menu Import/Export Tests', () {
    late MockMenuItemRepository mockRepository;
    late MenuExportService exportService;
    // TODO: Add import service tests when needed
    // late MenuImportService importService;

    setUp(() {
      mockRepository = MockMenuItemRepository();
      exportService = MenuExportService(menuItemRepository: mockRepository);
      // TODO: Initialize import service when tests are added
      // importService = MenuImportService(menuItemRepository: mockRepository);
    });

    group('MenuExportService', () {
      test('should export menu data to JSON format', () async {
        // Arrange
        const vendorId = 'test-vendor-id';
        const vendorName = 'Test Vendor';
        final mockMenuItems = [
          Product(
            id: '1',
            vendorId: vendorId,
            name: 'Test Item 1',
            description: 'Test description',
            category: 'Main Course',
            tags: ['spicy', 'popular'],
            basePrice: 15.99,
            currency: 'MYR',
            includesSst: true,
            isAvailable: true,
            minOrderQuantity: 1,
            preparationTimeMinutes: 30,
            allergens: ['nuts'],
            isHalal: true,
            isVegetarian: false,
            isVegan: false,
            isSpicy: true,
            spicyLevel: 3,
            galleryImages: [],
            customizations: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Product(
            id: '2',
            vendorId: vendorId,
            name: 'Test Item 2',
            description: 'Another test item',
            category: 'Beverages',
            tags: ['cold', 'refreshing'],
            basePrice: 5.50,
            currency: 'MYR',
            includesSst: false,
            isAvailable: true,
            minOrderQuantity: 1,
            preparationTimeMinutes: 5,
            allergens: [],
            isHalal: true,
            isVegetarian: true,
            isVegan: true,
            isSpicy: false,
            galleryImages: [],
            customizations: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockRepository.getMenuItems(
          vendorId,
          category: null,
          isAvailable: true,
          isVegetarian: null,
          isHalal: null,
          maxPrice: null,
          limit: 50,
          offset: 0,
        )).thenAnswer((_) async => mockMenuItems);

        // Act
        final result = await exportService.exportMenu(
          vendorId: vendorId,
          vendorName: vendorName,
          format: ExportFormat.json,
        );

        // Assert
        expect(result.isSuccessful, isTrue);
        expect(result.format, equals(ExportFormat.json));
        expect(result.totalItems, equals(2));
        expect(result.fileName, contains('gigaeats_menu_Test_Vendor'));
        expect(result.fileName, endsWith('.json'));
        verify(mockRepository.getMenuItems(
          vendorId,
          category: null,
          isAvailable: true,
          isVegetarian: null,
          isHalal: null,
          maxPrice: null,
          limit: 50,
          offset: 0,
        )).called(1);
      });

      test('should export menu data to CSV format', () async {
        // Arrange
        const vendorId = 'test-vendor-id';
        const vendorName = 'Test Vendor';
        final mockMenuItems = [
          Product(
            id: '1',
            vendorId: vendorId,
            name: 'Test Item',
            description: 'Test description',
            category: 'Main Course',
            tags: ['spicy'],
            basePrice: 15.99,
            currency: 'MYR',
            includesSst: true,
            isAvailable: true,
            minOrderQuantity: 1,
            preparationTimeMinutes: 30,
            allergens: ['nuts'],
            isHalal: true,
            isVegetarian: false,
            isVegan: false,
            isSpicy: true,
            spicyLevel: 3,
            galleryImages: [],
            customizations: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockRepository.getMenuItems(
          vendorId,
          category: null,
          isAvailable: true,
          isVegetarian: null,
          isHalal: null,
          maxPrice: null,
          limit: 50,
          offset: 0,
        )).thenAnswer((_) async => mockMenuItems);

        // Act
        final result = await exportService.exportMenu(
          vendorId: vendorId,
          vendorName: vendorName,
          format: ExportFormat.csv,
        );

        // Assert
        expect(result.isSuccessful, isTrue);
        expect(result.format, equals(ExportFormat.csv));
        expect(result.totalItems, equals(1));
        expect(result.fileName, contains('gigaeats_menu_Test_Vendor'));
        expect(result.fileName, endsWith('.csv'));
        verify(mockRepository.getMenuItems(
          vendorId,
          category: null,
          isAvailable: true,
          isVegetarian: null,
          isHalal: null,
          maxPrice: null,
          limit: 50,
          offset: 0,
        )).called(1);
      });

      test('should handle export errors gracefully', () async {
        // Arrange
        const vendorId = 'test-vendor-id';
        const vendorName = 'Test Vendor';

        when(mockRepository.getMenuItems(
          vendorId,
          category: null,
          isAvailable: true,
          isVegetarian: null,
          isHalal: null,
          maxPrice: null,
          limit: 50,
          offset: 0,
        )).thenThrow(Exception('Database error'));

        // Act
        final result = await exportService.exportMenu(
          vendorId: vendorId,
          vendorName: vendorName,
          format: ExportFormat.json,
        );

        // Assert
        expect(result.isFailed, isTrue);
        expect(result.errorMessage, contains('Database error'));
        expect(result.totalItems, equals(0));
      });
    });

    group('Data Models', () {
      test('MenuExportData should serialize to JSON correctly', () {
        // Arrange
        final exportData = MenuExportData(
          vendorId: 'test-vendor',
          vendorName: 'Test Vendor',
          exportedAt: DateTime(2025, 1, 1, 12, 0, 0),
          menuItems: [],
          categories: [],
          totalItems: 0,
          totalCategories: 0,
        );

        // Act
        final json = exportData.toJson();

        // Assert
        expect(json['vendorId'], equals('test-vendor'));
        expect(json['vendorName'], equals('Test Vendor'));
        expect(json['exportVersion'], equals('1.0'));
        expect(json['totalItems'], equals(0));
        expect(json['totalCategories'], equals(0));
      });

      test('MenuExportResult should track progress correctly', () {
        // Arrange
        final result = MenuExportResult(
          id: 'test-id',
          vendorId: 'test-vendor',
          format: ExportFormat.json,
          status: ExportStatus.completed,
          filePath: '/test/path/file.json',
          fileName: 'test_file.json',
          fileSize: 1024,
          totalItems: 5,
          totalCategories: 2,
          startedAt: DateTime.now(),
          completedAt: DateTime.now(),
        );

        // Assert
        expect(result.isSuccessful, isTrue);
        expect(result.isFailed, isFalse);
        expect(result.isInProgress, isFalse);
        expect(result.formattedFileSize, equals('1.0KB'));
      });

      test('ImportValidationError should categorize severity correctly', () {
        // Arrange
        const error = ImportValidationError(
          row: 5,
          field: 'price',
          message: 'Invalid price format',
          value: 'invalid',
          severity: 'error',
        );

        const warning = ImportValidationError(
          row: 8,
          field: 'spicy_level',
          message: 'Spicy level should be 1-5',
          value: '6',
          severity: 'warning',
        );

        // Assert
        expect(error.isError, isTrue);
        expect(error.isWarning, isFalse);
        expect(warning.isError, isFalse);
        expect(warning.isWarning, isTrue);
      });

      test('MenuImportResult should calculate success rate correctly', () {
        // Arrange
        final result = MenuImportResult(
          id: 'test-id',
          vendorId: 'test-vendor',
          fileName: 'test.csv',
          status: ImportStatus.completed,
          totalRows: 10,
          validRows: 8,
          importedRows: 7,
          skippedRows: 1,
          errorRows: 2,
          conflictResolution: ImportConflictResolution.skip,
          startedAt: DateTime.now(),
        );

        // Assert
        expect(result.successRate, equals(70.0)); // 7/10 * 100
        expect(result.isSuccessful, isTrue);
        expect(result.hasErrors, isFalse);
      });
    });

    group('Export/Import Formats', () {
      test('ExportFormat should have correct properties', () {
        // Assert
        expect(ExportFormat.json.displayName, equals('JSON'));
        expect(ExportFormat.json.extension, equals('json'));
        expect(ExportFormat.json.mimeType, equals('application/json'));

        expect(ExportFormat.csv.displayName, equals('CSV'));
        expect(ExportFormat.csv.extension, equals('csv'));
        expect(ExportFormat.csv.mimeType, equals('text/csv'));
      });

      test('ImportConflictResolution should have correct display names', () {
        // Assert
        expect(ImportConflictResolution.skip.displayName, equals('Skip existing items'));
        expect(ImportConflictResolution.update.displayName, equals('Update existing items'));
        expect(ImportConflictResolution.replace.displayName, equals('Replace all items'));
      });
    });
  });
}
