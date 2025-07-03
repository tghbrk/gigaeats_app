import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'menu_import_data.g.dart';

/// Represents a single menu item row from import file
@JsonSerializable()
class MenuImportRow extends Equatable {
  final String name;
  final String? description;
  final String category;
  final double basePrice;
  final String? unit;
  final int? minOrderQuantity;
  final int? maxOrderQuantity;
  final int? preparationTimeMinutes;
  final bool? isAvailable;
  final bool? isHalal;
  final bool? isVegetarian;
  final bool? isVegan;
  final bool? isSpicy;
  final int? spicyLevel;
  final String? allergens; // Comma-separated
  final String? tags; // Comma-separated
  final String? imageUrl;
  final String? nutritionalInfo; // JSON string
  
  // Bulk pricing
  final double? bulkPrice;
  final int? bulkMinQuantity;
  
  // Customization groups (will be parsed separately)
  final String? customizationGroups; // JSON string or structured format
  
  // Row metadata
  final int rowNumber;
  final List<String> errors;
  final List<String> warnings;

  const MenuImportRow({
    required this.name,
    this.description,
    required this.category,
    required this.basePrice,
    this.unit,
    this.minOrderQuantity,
    this.maxOrderQuantity,
    this.preparationTimeMinutes,
    this.isAvailable,
    this.isHalal,
    this.isVegetarian,
    this.isVegan,
    this.isSpicy,
    this.spicyLevel,
    this.allergens,
    this.tags,
    this.imageUrl,
    this.nutritionalInfo,
    this.bulkPrice,
    this.bulkMinQuantity,
    this.customizationGroups,
    required this.rowNumber,
    this.errors = const [],
    this.warnings = const [],
  });

  factory MenuImportRow.fromJson(Map<String, dynamic> json) => _$MenuImportRowFromJson(json);
  Map<String, dynamic> toJson() => _$MenuImportRowToJson(this);

  @override
  List<Object?> get props => [
    name, description, category, basePrice, unit, minOrderQuantity,
    maxOrderQuantity, preparationTimeMinutes, isAvailable, isHalal,
    isVegetarian, isVegan, isSpicy, spicyLevel, allergens, tags,
    imageUrl, nutritionalInfo, bulkPrice, bulkMinQuantity,
    customizationGroups, rowNumber, errors, warnings,
  ];

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get isValid => !hasErrors;

  MenuImportRow copyWith({
    String? name,
    String? description,
    String? category,
    double? basePrice,
    String? unit,
    int? minOrderQuantity,
    int? maxOrderQuantity,
    int? preparationTimeMinutes,
    bool? isAvailable,
    bool? isHalal,
    bool? isVegetarian,
    bool? isVegan,
    bool? isSpicy,
    int? spicyLevel,
    String? allergens,
    String? tags,
    String? imageUrl,
    String? nutritionalInfo,
    double? bulkPrice,
    int? bulkMinQuantity,
    String? customizationGroups,
    int? rowNumber,
    List<String>? errors,
    List<String>? warnings,
  }) {
    return MenuImportRow(
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      basePrice: basePrice ?? this.basePrice,
      unit: unit ?? this.unit,
      minOrderQuantity: minOrderQuantity ?? this.minOrderQuantity,
      maxOrderQuantity: maxOrderQuantity ?? this.maxOrderQuantity,
      preparationTimeMinutes: preparationTimeMinutes ?? this.preparationTimeMinutes,
      isAvailable: isAvailable ?? this.isAvailable,
      isHalal: isHalal ?? this.isHalal,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isVegan: isVegan ?? this.isVegan,
      isSpicy: isSpicy ?? this.isSpicy,
      spicyLevel: spicyLevel ?? this.spicyLevel,
      allergens: allergens ?? this.allergens,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
      bulkPrice: bulkPrice ?? this.bulkPrice,
      bulkMinQuantity: bulkMinQuantity ?? this.bulkMinQuantity,
      customizationGroups: customizationGroups ?? this.customizationGroups,
      rowNumber: rowNumber ?? this.rowNumber,
      errors: errors ?? this.errors,
      warnings: warnings ?? this.warnings,
    );
  }
}

/// Represents customization data from import
@JsonSerializable()
class ImportCustomizationGroup extends Equatable {
  final String name;
  final String type; // 'single' or 'multiple'
  final bool isRequired;
  final List<ImportCustomizationOption> options;

  const ImportCustomizationGroup({
    required this.name,
    required this.type,
    this.isRequired = false,
    this.options = const [],
  });

  factory ImportCustomizationGroup.fromJson(Map<String, dynamic> json) => _$ImportCustomizationGroupFromJson(json);
  Map<String, dynamic> toJson() => _$ImportCustomizationGroupToJson(this);

  @override
  List<Object?> get props => [name, type, isRequired, options];
}

@JsonSerializable()
class ImportCustomizationOption extends Equatable {
  final String name;
  final double additionalPrice;
  final bool isDefault;

  const ImportCustomizationOption({
    required this.name,
    this.additionalPrice = 0.0,
    this.isDefault = false,
  });

  factory ImportCustomizationOption.fromJson(Map<String, dynamic> json) => _$ImportCustomizationOptionFromJson(json);
  Map<String, dynamic> toJson() => _$ImportCustomizationOptionToJson(this);

  @override
  List<Object?> get props => [name, additionalPrice, isDefault];
}

/// Complete import result with metadata
@JsonSerializable()
class MenuImportResult extends Equatable {
  final List<MenuImportRow> rows;
  final List<String> categories;
  final int totalRows;
  final int validRows;
  final int errorRows;
  final int warningRows;
  final DateTime importedAt;
  final String fileName;
  final String fileType;

  const MenuImportResult({
    required this.rows,
    required this.categories,
    required this.totalRows,
    required this.validRows,
    required this.errorRows,
    required this.warningRows,
    required this.importedAt,
    required this.fileName,
    required this.fileType,
  });

  factory MenuImportResult.fromJson(Map<String, dynamic> json) => _$MenuImportResultFromJson(json);
  Map<String, dynamic> toJson() => _$MenuImportResultToJson(this);

  @override
  List<Object?> get props => [
    rows, categories, totalRows, validRows, errorRows, warningRows,
    importedAt, fileName, fileType,
  ];

  bool get hasErrors => errorRows > 0;
  bool get hasWarnings => warningRows > 0;
  bool get canProceed => validRows > 0;
  double get successRate => totalRows > 0 ? validRows / totalRows : 0.0;
}

/// Import validation error types
enum ImportErrorType {
  missingRequiredField,
  invalidDataType,
  invalidValue,
  duplicateName,
  invalidCategory,
  invalidPrice,
  invalidQuantity,
  invalidCustomization,
  fileTooLarge,
  unsupportedFormat,
}

/// Import validation error
@JsonSerializable()
class ImportValidationError extends Equatable {
  final ImportErrorType type;
  final String message;
  final String? field;
  final int? rowNumber;
  final String? suggestedFix;

  const ImportValidationError({
    required this.type,
    required this.message,
    this.field,
    this.rowNumber,
    this.suggestedFix,
  });

  factory ImportValidationError.fromJson(Map<String, dynamic> json) => _$ImportValidationErrorFromJson(json);
  Map<String, dynamic> toJson() => _$ImportValidationErrorToJson(this);

  @override
  List<Object?> get props => [type, message, field, rowNumber, suggestedFix];
}
