import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../data/models/menu_export_import.dart';
import '../../data/models/menu_import_data.dart' as import_data;
import '../../data/services/menu_export_service.dart';
import '../../data/services/menu_import_service.dart';
import '../../../../presentation/providers/repository_providers.dart';

/// Provider for MenuExportService
final menuExportServiceProvider = Provider<MenuExportService>((ref) {
  final menuItemRepository = ref.read(menuItemRepositoryProvider);
  return MenuExportService(menuItemRepository: menuItemRepository);
});

/// Provider for MenuImportService
final menuImportServiceProvider = Provider<MenuImportService>((ref) {
  final menuItemRepository = ref.read(menuItemRepositoryProvider);
  return MenuImportService(menuItemRepository: menuItemRepository);
});

/// State class for export operations
@immutable
class MenuExportState {
  final bool isExporting;
  final ExportStatus? status;
  final MenuExportResult? result;
  final String? errorMessage;
  final double progress;

  const MenuExportState({
    this.isExporting = false,
    this.status,
    this.result,
    this.errorMessage,
    this.progress = 0.0,
  });

  MenuExportState copyWith({
    bool? isExporting,
    ExportStatus? status,
    MenuExportResult? result,
    String? errorMessage,
    double? progress,
  }) {
    return MenuExportState(
      isExporting: isExporting ?? this.isExporting,
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
      progress: progress ?? this.progress,
    );
  }

  bool get isCompleted => status == ExportStatus.completed;
  bool get isFailed => status == ExportStatus.failed;
  bool get isInProgress => isExporting && !isCompleted && !isFailed;
}

/// State class for import operations
@immutable
class MenuImportState {
  final bool isImporting;
  final ImportStatus? status;
  final MenuImportResult? result;
  final String? errorMessage;
  final double progress;

  const MenuImportState({
    this.isImporting = false,
    this.status,
    this.result,
    this.errorMessage,
    this.progress = 0.0,
  });

  MenuImportState copyWith({
    bool? isImporting,
    ImportStatus? status,
    MenuImportResult? result,
    String? errorMessage,
    double? progress,
  }) {
    return MenuImportState(
      isImporting: isImporting ?? this.isImporting,
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
      progress: progress ?? this.progress,
    );
  }

  bool get isCompleted => status == ImportStatus.completed;
  bool get isFailed => status == ImportStatus.failed;
  bool get isInProgress => isImporting && !isCompleted && !isFailed;
}

/// Notifier for managing export operations
class MenuExportNotifier extends StateNotifier<MenuExportState> {
  final MenuExportService _exportService;
  // TODO: Add Ref _ref when provider invalidation is implemented

  MenuExportNotifier(this._exportService) : super(const MenuExportState());

  /// Export menu data
  Future<MenuExportResult?> exportMenu({
    required String vendorId,
    required String vendorName,
    required ExportFormat format,
    bool includeInactiveItems = false,
    List<String>? categoryFilter,
    bool userFriendlyFormat = false,
  }) async {
    try {
      debugPrint('🍽️ [EXPORT-PROVIDER] Starting export for vendor: $vendorId');

      state = state.copyWith(
        isExporting: true,
        status: ExportStatus.preparing,
        errorMessage: null,
        progress: 0.0,
      );

      final result = await _exportService.exportMenu(
        vendorId: vendorId,
        vendorName: vendorName,
        format: format,
        includeInactiveItems: includeInactiveItems,
        categoryFilter: categoryFilter,
        userFriendlyFormat: userFriendlyFormat,
        onStatusUpdate: (status) {
          debugPrint('🍽️ [EXPORT-PROVIDER] Status update: ${status.name}');
          
          double progress = 0.0;
          switch (status) {
            case ExportStatus.preparing:
              progress = 0.2;
              break;
            case ExportStatus.exporting:
              progress = 0.5;
              break;
            case ExportStatus.generating:
              progress = 0.8;
              break;
            case ExportStatus.completed:
              progress = 1.0;
              break;
            case ExportStatus.failed:
              progress = 0.0;
              break;
          }

          state = state.copyWith(
            status: status,
            progress: progress,
          );
        },
      );

      state = state.copyWith(
        isExporting: false,
        result: result,
        progress: result.isSuccessful ? 1.0 : 0.0,
      );

      debugPrint('🍽️ [EXPORT-PROVIDER] Export completed: ${result.isSuccessful}');
      return result;

    } catch (e) {
      debugPrint('❌ [EXPORT-PROVIDER] Export failed: $e');
      
      state = state.copyWith(
        isExporting: false,
        status: ExportStatus.failed,
        errorMessage: e.toString(),
        progress: 0.0,
      );
      
      return null;
    }
  }

  /// Share exported file
  Future<void> shareExportedFile(MenuExportResult result) async {
    try {
      debugPrint('🍽️ [EXPORT-PROVIDER] Sharing file: ${result.fileName}');
      await _exportService.shareExportedFile(result);
    } catch (e) {
      debugPrint('❌ [EXPORT-PROVIDER] Failed to share file: $e');
      state = state.copyWith(errorMessage: 'Failed to share file: $e');
    }
  }

  /// Reset export state
  void reset() {
    debugPrint('🍽️ [EXPORT-PROVIDER] Resetting export state');
    state = const MenuExportState();
  }
}

/// Notifier for managing import operations
class MenuImportNotifier extends StateNotifier<MenuImportState> {
  final MenuImportService _importService;
  // TODO: Add Ref _ref when provider invalidation is implemented

  MenuImportNotifier(this._importService) : super(const MenuImportState());

  /// Pick and process import file
  Future<MenuImportResult?> pickAndProcessFile({
    required String vendorId,
    ImportConflictResolution conflictResolution = ImportConflictResolution.skip,
  }) async {
    try {
      debugPrint('🍽️ [IMPORT-PROVIDER] Starting file picker for vendor: $vendorId');

      state = state.copyWith(
        isImporting: true,
        status: ImportStatus.validating,
        errorMessage: null,
        progress: 0.0,
      );

      final result = await _importService.pickAndProcessFile(
        vendorId: vendorId,
        conflictResolution: conflictResolution,
        onStatusUpdate: (status) {
          debugPrint('🍽️ [IMPORT-PROVIDER] Status update: ${status.name}');
          
          double progress = 0.0;
          switch (status) {
            case ImportStatus.validating:
              progress = 0.2;
              break;
            case ImportStatus.processing:
              progress = 0.5;
              break;
            case ImportStatus.importing:
              progress = 0.8;
              break;
            case ImportStatus.completed:
              progress = 1.0;
              break;
            case ImportStatus.failed:
              progress = 0.0;
              break;
          }

          state = state.copyWith(
            status: status,
            progress: progress,
          );
        },
      );

      if (result != null) {
        state = state.copyWith(
          isImporting: false,
          result: result,
          progress: result.isSuccessful ? 1.0 : 0.0,
        );

        // Invalidate menu providers after successful import
        if (result.isSuccessful) {
          debugPrint('🍽️ [IMPORT-PROVIDER] Invalidating menu providers after successful import');
          // TODO: Invalidate menu providers - will be implemented when providers are properly organized
          // _ref.invalidate(vendorMenuItemsProvider(vendorId));
          // _ref.invalidate(vendorMenuStatsProvider(vendorId));
        }

        debugPrint('🍽️ [IMPORT-PROVIDER] Import completed: ${result.isSuccessful}');
        return result;
      } else {
        // User cancelled file picker
        state = const MenuImportState();
        return null;
      }

    } catch (e) {
      debugPrint('❌ [IMPORT-PROVIDER] Import failed: $e');
      
      state = state.copyWith(
        isImporting: false,
        status: ImportStatus.failed,
        errorMessage: e.toString(),
        progress: 0.0,
      );
      
      return null;
    }
  }

  /// Reset import state
  void reset() {
    debugPrint('🍽️ [IMPORT-PROVIDER] Resetting import state');
    state = const MenuImportState();
  }

  /// Pick and process file for preview (returns detailed import data)
  Future<import_data.MenuImportResult?> pickAndProcessFileForPreview({
    required String vendorId,
  }) async {
    try {
      debugPrint('🍽️ [IMPORT-PROVIDER] Starting file picker for preview: $vendorId');

      state = state.copyWith(
        isImporting: true,
        status: ImportStatus.validating,
        errorMessage: null,
        progress: 0.0,
      );

      // Pick file first
      final fileResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls', 'json'],
        allowMultiple: false,
      );

      if (fileResult == null || fileResult.files.isEmpty) {
        // User cancelled file picker
        state = const MenuImportState();
        return null;
      }

      final file = fileResult.files.first;

      final result = await _importService.processFileForPreview(
        file,
        vendorId: vendorId,
        onStatusUpdate: (status) {
          debugPrint('🍽️ [IMPORT-PROVIDER] Preview status update: ${status.name}');

          double progress = 0.0;
          switch (status) {
            case ImportStatus.validating:
              progress = 0.3;
              break;
            case ImportStatus.processing:
              progress = 0.7;
              break;
            case ImportStatus.completed:
              progress = 1.0;
              break;
            case ImportStatus.failed:
              progress = 0.0;
              break;
            default:
              progress = 0.5;
              break;
          }

          state = state.copyWith(
            status: status,
            progress: progress,
          );
        },
      );

      debugPrint('🍽️ [IMPORT-PROVIDER] Preview processing completed: ${result.validRows}/${result.totalRows} valid items');

      state = state.copyWith(
        isImporting: false,
        status: ImportStatus.completed,
        progress: 1.0,
      );

      return result;

    } catch (e) {
      debugPrint('❌ [IMPORT-PROVIDER] Preview processing failed: $e');

      state = state.copyWith(
        isImporting: false,
        status: ImportStatus.failed,
        errorMessage: e.toString(),
        progress: 0.0,
      );

      rethrow;
    }
  }
}

/// Provider for export state management
final menuExportProvider = StateNotifierProvider<MenuExportNotifier, MenuExportState>((ref) {
  final exportService = ref.read(menuExportServiceProvider);
  return MenuExportNotifier(exportService);
});

/// Provider for import state management
final menuImportProvider = StateNotifierProvider<MenuImportNotifier, MenuImportState>((ref) {
  final importService = ref.read(menuImportServiceProvider);
  return MenuImportNotifier(importService);
});

/// Provider for checking if any import/export operation is in progress
final isMenuOperationInProgressProvider = Provider<bool>((ref) {
  final exportState = ref.watch(menuExportProvider);
  final importState = ref.watch(menuImportProvider);
  
  return exportState.isInProgress || importState.isInProgress;
});

/// Provider for getting current operation progress (0.0 to 1.0)
final menuOperationProgressProvider = Provider<double>((ref) {
  final exportState = ref.watch(menuExportProvider);
  final importState = ref.watch(menuImportProvider);
  
  if (exportState.isInProgress) return exportState.progress;
  if (importState.isInProgress) return importState.progress;
  
  return 0.0;
});

// Note: vendorMenuItemsProvider and vendorMenuStatsProvider are imported from menu_management_screen.dart
// These providers will be moved to a shared location in the future for better organization
