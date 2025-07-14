import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

import 'product.dart';
import 'menu_item.dart';

part 'menu_export_import.g.dart';

/// Export format options
enum ExportFormat {
  @JsonValue('json')
  json('JSON', 'json', 'application/json'),
  @JsonValue('csv')
  csv('CSV', 'csv', 'text/csv');

  const ExportFormat(this.displayName, this.extension, this.mimeType);
  final String displayName;
  final String extension;
  final String mimeType;
}

/// Import conflict resolution options
enum ImportConflictResolution {
  @JsonValue('skip')
  skip('Skip existing items'),
  @JsonValue('update')
  update('Update existing items'),
  @JsonValue('replace')
  replace('Replace all items');

  const ImportConflictResolution(this.displayName);
  final String displayName;
}

/// Export progress status
enum ExportStatus {
  @JsonValue('preparing')
  preparing('Preparing export...'),
  @JsonValue('exporting')
  exporting('Exporting data...'),
  @JsonValue('generating')
  generating('Generating file...'),
  @JsonValue('completed')
  completed('Export completed'),
  @JsonValue('failed')
  failed('Export failed');

  const ExportStatus(this.displayName);
  final String displayName;
}

/// Import progress status
enum ImportStatus {
  @JsonValue('validating')
  validating('Validating file...'),
  @JsonValue('processing')
  processing('Processing data...'),
  @JsonValue('importing')
  importing('Importing items...'),
  @JsonValue('completed')
  completed('Import completed'),
  @JsonValue('failed')
  failed('Import failed');

  const ImportStatus(this.displayName);
  final String displayName;
}

/// Complete menu export data structure
@JsonSerializable()
class MenuExportData extends Equatable {
  final String vendorId;
  final String vendorName;
  final DateTime exportedAt;
  final String exportVersion;
  final List<Product> menuItems;
  final List<MenuCategory> categories;
  final Map<String, dynamic> metadata;
  final int totalItems;
  final int totalCategories;

  const MenuExportData({
    required this.vendorId,
    required this.vendorName,
    required this.exportedAt,
    this.exportVersion = '1.0',
    required this.menuItems,
    required this.categories,
    this.metadata = const {},
    required this.totalItems,
    required this.totalCategories,
  });

  factory MenuExportData.fromJson(Map<String, dynamic> json) => _$MenuExportDataFromJson(json);
  Map<String, dynamic> toJson() => _$MenuExportDataToJson(this);

  @override
  List<Object?> get props => [
        vendorId,
        vendorName,
        exportedAt,
        exportVersion,
        menuItems,
        categories,
        metadata,
        totalItems,
        totalCategories,
      ];
}

/// Export operation result
@JsonSerializable()
class MenuExportResult extends Equatable {
  final String id;
  final String vendorId;
  final ExportFormat format;
  final ExportStatus status;
  final String? filePath;
  final String? fileName;
  final int? fileSize;
  final int totalItems;
  final int totalCategories;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final Map<String, dynamic> metadata;

  const MenuExportResult({
    required this.id,
    required this.vendorId,
    required this.format,
    required this.status,
    this.filePath,
    this.fileName,
    this.fileSize,
    required this.totalItems,
    required this.totalCategories,
    required this.startedAt,
    this.completedAt,
    this.errorMessage,
    this.metadata = const {},
  });

  factory MenuExportResult.fromJson(Map<String, dynamic> json) => _$MenuExportResultFromJson(json);
  Map<String, dynamic> toJson() => _$MenuExportResultToJson(this);

  @override
  List<Object?> get props => [
        id,
        vendorId,
        format,
        status,
        filePath,
        fileName,
        fileSize,
        totalItems,
        totalCategories,
        startedAt,
        completedAt,
        errorMessage,
        metadata,
      ];

  MenuExportResult copyWith({
    String? id,
    String? vendorId,
    ExportFormat? format,
    ExportStatus? status,
    String? filePath,
    String? fileName,
    int? fileSize,
    int? totalItems,
    int? totalCategories,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return MenuExportResult(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      format: format ?? this.format,
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      totalItems: totalItems ?? this.totalItems,
      totalCategories: totalCategories ?? this.totalCategories,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get formatted file size
  String get formattedFileSize {
    if (fileSize == null) return 'Unknown';
    final size = fileSize!;
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Check if export was successful
  bool get isSuccessful => status == ExportStatus.completed && filePath != null;

  /// Check if export failed
  bool get isFailed => status == ExportStatus.failed;

  /// Check if export is in progress
  bool get isInProgress => [
        ExportStatus.preparing,
        ExportStatus.exporting,
        ExportStatus.generating,
      ].contains(status);
}

/// Import validation error
@JsonSerializable()
class ImportValidationError extends Equatable {
  final int row;
  final String field;
  final String message;
  final String? value;
  final String severity; // 'error', 'warning', 'info'

  const ImportValidationError({
    required this.row,
    required this.field,
    required this.message,
    this.value,
    this.severity = 'error',
  });

  factory ImportValidationError.fromJson(Map<String, dynamic> json) => _$ImportValidationErrorFromJson(json);
  Map<String, dynamic> toJson() => _$ImportValidationErrorToJson(this);

  @override
  List<Object?> get props => [row, field, message, value, severity];

  bool get isError => severity == 'error';
  bool get isWarning => severity == 'warning';
  bool get isInfo => severity == 'info';
}

/// Import operation result
@JsonSerializable()
class MenuImportResult extends Equatable {
  final String id;
  final String vendorId;
  final String fileName;
  final ImportStatus status;
  final int totalRows;
  final int validRows;
  final int importedRows;
  final int skippedRows;
  final int errorRows;
  final List<ImportValidationError> errors;
  final List<ImportValidationError> warnings;
  final ImportConflictResolution conflictResolution;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final Map<String, dynamic> metadata;

  const MenuImportResult({
    required this.id,
    required this.vendorId,
    required this.fileName,
    required this.status,
    required this.totalRows,
    required this.validRows,
    required this.importedRows,
    required this.skippedRows,
    required this.errorRows,
    this.errors = const [],
    this.warnings = const [],
    required this.conflictResolution,
    required this.startedAt,
    this.completedAt,
    this.errorMessage,
    this.metadata = const {},
  });

  factory MenuImportResult.fromJson(Map<String, dynamic> json) => _$MenuImportResultFromJson(json);
  Map<String, dynamic> toJson() => _$MenuImportResultToJson(this);

  @override
  List<Object?> get props => [
        id,
        vendorId,
        fileName,
        status,
        totalRows,
        validRows,
        importedRows,
        skippedRows,
        errorRows,
        errors,
        warnings,
        conflictResolution,
        startedAt,
        completedAt,
        errorMessage,
        metadata,
      ];

  /// Check if import was successful
  bool get isSuccessful => status == ImportStatus.completed && importedRows > 0;

  /// Check if import failed
  bool get isFailed => status == ImportStatus.failed;

  /// Check if import is in progress
  bool get isInProgress => [
        ImportStatus.validating,
        ImportStatus.processing,
        ImportStatus.importing,
      ].contains(status);

  /// Check if there are validation errors
  bool get hasErrors => errors.isNotEmpty;

  /// Check if there are warnings
  bool get hasWarnings => warnings.isNotEmpty;

  /// Get success rate percentage
  double get successRate {
    if (totalRows == 0) return 0.0;
    return (importedRows / totalRows) * 100;
  }
}
