import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

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
  });

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
}

@JsonSerializable()
class MenuCategory extends Equatable {
  final String id;
  final String vendorId;
  final String name;
  final String? description;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
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
