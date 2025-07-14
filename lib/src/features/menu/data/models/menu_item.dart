import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'customization_template.dart';

part 'menu_item.g.dart';

enum MenuItemStatus {
  @JsonValue('available')
  available,
  @JsonValue('unavailable')
  unavailable,
  @JsonValue('out_of_stock')
  outOfStock,
  @JsonValue('discontinued')
  discontinued,
}

enum DietaryType {
  @JsonValue('halal')
  halal,
  @JsonValue('vegetarian')
  vegetarian,
  @JsonValue('vegan')
  vegan,
  @JsonValue('gluten_free')
  glutenFree,
  @JsonValue('dairy_free')
  dairyFree,
  @JsonValue('nut_free')
  nutFree,
}

@JsonSerializable()
class BulkPricingTier extends Equatable {
  final int minimumQuantity;
  final double pricePerUnit;
  final double? discountPercentage;
  final String? description;

  const BulkPricingTier({
    required this.minimumQuantity,
    required this.pricePerUnit,
    this.discountPercentage,
    this.description,
  });

  factory BulkPricingTier.fromJson(Map<String, dynamic> json) => _$BulkPricingTierFromJson(json);
  Map<String, dynamic> toJson() => _$BulkPricingTierToJson(this);

  @override
  List<Object?> get props => [minimumQuantity, pricePerUnit, discountPercentage, description];
}

@JsonSerializable()
class MenuItemCustomization extends Equatable {
  final String id;
  final String name;
  final String type; // 'radio', 'checkbox', 'text'
  final bool isRequired;
  final List<CustomizationOption> options;
  final double? additionalCost;

  const MenuItemCustomization({
    required this.id,
    required this.name,
    required this.type,
    this.isRequired = false,
    this.options = const [],
    this.additionalCost,
  });

  factory MenuItemCustomization.fromJson(Map<String, dynamic> json) => _$MenuItemCustomizationFromJson(json);
  Map<String, dynamic> toJson() => _$MenuItemCustomizationToJson(this);

  @override
  List<Object?> get props => [id, name, type, isRequired, options, additionalCost];
}

@JsonSerializable()
class CustomizationOption extends Equatable {
  final String id;
  final String name;
  final double additionalCost;
  final bool isDefault;

  const CustomizationOption({
    required this.id,
    required this.name,
    this.additionalCost = 0.0,
    this.isDefault = false,
  });

  factory CustomizationOption.fromJson(Map<String, dynamic> json) => _$CustomizationOptionFromJson(json);
  Map<String, dynamic> toJson() => _$CustomizationOptionToJson(this);

  @override
  List<Object?> get props => [id, name, additionalCost, isDefault];
}

@JsonSerializable()
class MenuItem extends Equatable {
  final String id;
  final String vendorId;
  final String name;
  final String description;
  final String category;
  final double basePrice;
  final List<BulkPricingTier> bulkPricingTiers;
  final int minimumOrderQuantity;
  final int? maximumOrderQuantity;
  final MenuItemStatus status;
  final List<String> imageUrls;
  final List<DietaryType> dietaryTypes;
  final List<String> allergens;
  final List<MenuItemCustomization> customizations;
  final List<CustomizationTemplate> linkedTemplates; // Templates linked to this menu item
  final List<MenuItemTemplateLink> templateLinks; // Link metadata for templates
  final int preparationTimeMinutes;
  final int? availableQuantity;
  final String? unit; // 'pax', 'kg', 'pieces', etc.
  final bool isHalalCertified;
  final double? rating;
  final int reviewCount;
  final Map<String, dynamic>? nutritionalInfo;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  // Additional properties for validation service compatibility
  final int? stockQuantity; // Alias for availableQuantity for validation compatibility
  final bool isAvailable; // Computed from status for validation compatibility

  const MenuItem({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.description,
    required this.category,
    required this.basePrice,
    this.bulkPricingTiers = const [],
    this.minimumOrderQuantity = 1,
    this.maximumOrderQuantity,
    this.status = MenuItemStatus.available,
    this.imageUrls = const [],
    this.dietaryTypes = const [],
    this.allergens = const [],
    this.customizations = const [],
    this.linkedTemplates = const [],
    this.templateLinks = const [],
    this.preparationTimeMinutes = 30,
    this.availableQuantity,
    this.unit = 'pax',
    this.isHalalCertified = false,
    this.rating,
    this.reviewCount = 0,
    this.nutritionalInfo,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  }) : stockQuantity = availableQuantity,
       isAvailable = status == MenuItemStatus.available;

  factory MenuItem.fromJson(Map<String, dynamic> json) => _$MenuItemFromJson(json);
  Map<String, dynamic> toJson() => _$MenuItemToJson(this);

  @override
  List<Object?> get props => [
        id,
        vendorId,
        name,
        description,
        category,
        basePrice,
        bulkPricingTiers,
        minimumOrderQuantity,
        maximumOrderQuantity,
        status,
        imageUrls,
        dietaryTypes,
        allergens,
        customizations,
        linkedTemplates,
        templateLinks,
        preparationTimeMinutes,
        availableQuantity,
        unit,
        isHalalCertified,
        rating,
        reviewCount,
        nutritionalInfo,
        tags,
        createdAt,
        updatedAt,
        isActive,
        stockQuantity,
        isAvailable,
      ];

  MenuItem copyWith({
    String? id,
    String? vendorId,
    String? name,
    String? description,
    String? category,
    double? basePrice,
    List<BulkPricingTier>? bulkPricingTiers,
    int? minimumOrderQuantity,
    int? maximumOrderQuantity,
    MenuItemStatus? status,
    List<String>? imageUrls,
    List<DietaryType>? dietaryTypes,
    List<String>? allergens,
    List<MenuItemCustomization>? customizations,
    List<CustomizationTemplate>? linkedTemplates,
    List<MenuItemTemplateLink>? templateLinks,
    int? preparationTimeMinutes,
    int? availableQuantity,
    String? unit,
    bool? isHalalCertified,
    double? rating,
    int? reviewCount,
    Map<String, dynamic>? nutritionalInfo,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    // Note: stockQuantity and isAvailable are computed properties, not directly settable
  }) {
    return MenuItem(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      basePrice: basePrice ?? this.basePrice,
      bulkPricingTiers: bulkPricingTiers ?? this.bulkPricingTiers,
      minimumOrderQuantity: minimumOrderQuantity ?? this.minimumOrderQuantity,
      maximumOrderQuantity: maximumOrderQuantity ?? this.maximumOrderQuantity,
      status: status ?? this.status,
      imageUrls: imageUrls ?? this.imageUrls,
      dietaryTypes: dietaryTypes ?? this.dietaryTypes,
      allergens: allergens ?? this.allergens,
      customizations: customizations ?? this.customizations,
      linkedTemplates: linkedTemplates ?? this.linkedTemplates,
      templateLinks: templateLinks ?? this.templateLinks,
      preparationTimeMinutes: preparationTimeMinutes ?? this.preparationTimeMinutes,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      unit: unit ?? this.unit,
      isHalalCertified: isHalalCertified ?? this.isHalalCertified,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Get effective price for a given quantity
  double getEffectivePrice(int quantity) {
    if (bulkPricingTiers.isEmpty) {
      return basePrice;
    }

    // Find the best applicable tier
    BulkPricingTier? bestTier;
    for (final tier in bulkPricingTiers) {
      if (quantity >= tier.minimumQuantity) {
        if (bestTier == null || tier.minimumQuantity > bestTier.minimumQuantity) {
          bestTier = tier;
        }
      }
    }

    return bestTier?.pricePerUnit ?? basePrice;
  }

  // Get total price for a given quantity
  double getTotalPrice(int quantity) {
    return getEffectivePrice(quantity) * quantity;
  }

  // Check if quantity is valid for this item
  bool isValidQuantity(int quantity) {
    if (quantity < minimumOrderQuantity) return false;
    if (maximumOrderQuantity != null && quantity > maximumOrderQuantity!) return false;
    if (availableQuantity != null && quantity > availableQuantity!) return false;
    return true;
  }

  // Get discount percentage for a given quantity
  double? getDiscountPercentage(int quantity) {
    if (bulkPricingTiers.isEmpty) return null;

    for (final tier in bulkPricingTiers) {
      if (quantity >= tier.minimumQuantity) {
        return tier.discountPercentage;
      }
    }
    return null;
  }

  // Template-related helper methods

  /// Gets all customizations including both direct and template-based ones
  List<MenuItemCustomization> get allCustomizations {
    final List<MenuItemCustomization> all = List.from(customizations);

    // Convert linked templates to MenuItemCustomization format
    for (final template in linkedTemplates) {
      final templateCustomization = MenuItemCustomization(
        id: template.id,
        name: template.name,
        type: template.type,
        isRequired: template.isRequired,
        options: template.options.map((option) => CustomizationOption(
          id: option.id,
          name: option.name,
          additionalCost: option.additionalPrice,
          isDefault: option.isDefault,
        )).toList(),
      );
      all.add(templateCustomization);
    }

    return all;
  }

  /// Checks if this menu item uses any templates
  bool get hasLinkedTemplates => linkedTemplates.isNotEmpty;

  /// Gets the number of active template links
  int get activeTemplateLinksCount =>
      templateLinks.where((link) => link.isActive).length;

  /// Gets templates sorted by display order
  List<CustomizationTemplate> get sortedLinkedTemplates {
    final List<CustomizationTemplate> sorted = List.from(linkedTemplates);
    sorted.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return sorted;
  }

  /// Checks if a specific template is linked to this menu item
  bool isTemplateLinked(String templateId) {
    return linkedTemplates.any((template) => template.id == templateId);
  }

  /// Gets the minimum additional cost from all customizations (direct + templates)
  double get minimumCustomizationCost {
    double minCost = 0.0;

    // Add minimum cost from direct customizations
    for (final customization in customizations) {
      if (customization.isRequired && customization.options.isNotEmpty) {
        final minOptionCost = customization.options
            .map((o) => o.additionalCost)
            .reduce((a, b) => a < b ? a : b);
        minCost += minOptionCost;
      }
    }

    // Add minimum cost from template-based customizations
    for (final template in linkedTemplates) {
      if (template.isRequired) {
        minCost += template.minimumAdditionalCost;
      }
    }

    return minCost;
  }

  /// Gets the maximum additional cost from all customizations (direct + templates)
  double get maximumCustomizationCost {
    double maxCost = 0.0;

    // Add maximum cost from direct customizations
    for (final customization in customizations) {
      if (customization.options.isNotEmpty) {
        if (customization.type == 'single') {
          final maxOptionCost = customization.options
              .map((o) => o.additionalCost)
              .reduce((a, b) => a > b ? a : b);
          maxCost += maxOptionCost;
        } else {
          // For multiple selection, sum all options
          maxCost += customization.options
              .map((o) => o.additionalCost)
              .reduce((a, b) => a + b);
        }
      }
    }

    // Add maximum cost from template-based customizations
    for (final template in linkedTemplates) {
      maxCost += template.maximumAdditionalCost;
    }

    return maxCost;
  }
}

@JsonSerializable()
class MenuCategory extends Equatable {
  final String id;
  @JsonKey(name: 'vendor_id')
  final String vendorId;
  final String name;
  final String? description;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'sort_order')
  final int sortOrder;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const MenuCategory({
    required this.id,
    required this.vendorId,
    required this.name,
    this.description,
    this.imageUrl,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) => _$MenuCategoryFromJson(json);
  Map<String, dynamic> toJson() => _$MenuCategoryToJson(this);

  @override
  List<Object?> get props => [
        id,
        vendorId,
        name,
        description,
        imageUrl,
        sortOrder,
        isActive,
        createdAt,
        updatedAt,
      ];
}
