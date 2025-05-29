// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BulkPricingTier _$BulkPricingTierFromJson(Map<String, dynamic> json) =>
    BulkPricingTier(
      minimumQuantity: (json['minimumQuantity'] as num).toInt(),
      pricePerUnit: (json['pricePerUnit'] as num).toDouble(),
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble(),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$BulkPricingTierToJson(BulkPricingTier instance) =>
    <String, dynamic>{
      'minimumQuantity': instance.minimumQuantity,
      'pricePerUnit': instance.pricePerUnit,
      'discountPercentage': instance.discountPercentage,
      'description': instance.description,
    };

MenuItemCustomization _$MenuItemCustomizationFromJson(
  Map<String, dynamic> json,
) => MenuItemCustomization(
  id: json['id'] as String,
  name: json['name'] as String,
  type: json['type'] as String,
  isRequired: json['isRequired'] as bool? ?? false,
  options:
      (json['options'] as List<dynamic>?)
          ?.map((e) => CustomizationOption.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  additionalCost: (json['additionalCost'] as num?)?.toDouble(),
);

Map<String, dynamic> _$MenuItemCustomizationToJson(
  MenuItemCustomization instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': instance.type,
  'isRequired': instance.isRequired,
  'options': instance.options,
  'additionalCost': instance.additionalCost,
};

CustomizationOption _$CustomizationOptionFromJson(Map<String, dynamic> json) =>
    CustomizationOption(
      id: json['id'] as String,
      name: json['name'] as String,
      additionalCost: (json['additionalCost'] as num?)?.toDouble() ?? 0.0,
      isDefault: json['isDefault'] as bool? ?? false,
    );

Map<String, dynamic> _$CustomizationOptionToJson(
  CustomizationOption instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'additionalCost': instance.additionalCost,
  'isDefault': instance.isDefault,
};

MenuItem _$MenuItemFromJson(Map<String, dynamic> json) => MenuItem(
  id: json['id'] as String,
  vendorId: json['vendorId'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  category: json['category'] as String,
  basePrice: (json['basePrice'] as num).toDouble(),
  bulkPricingTiers:
      (json['bulkPricingTiers'] as List<dynamic>?)
          ?.map((e) => BulkPricingTier.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  minimumOrderQuantity: (json['minimumOrderQuantity'] as num?)?.toInt() ?? 1,
  maximumOrderQuantity: (json['maximumOrderQuantity'] as num?)?.toInt(),
  status:
      $enumDecodeNullable(_$MenuItemStatusEnumMap, json['status']) ??
      MenuItemStatus.available,
  imageUrls:
      (json['imageUrls'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  dietaryTypes:
      (json['dietaryTypes'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$DietaryTypeEnumMap, e))
          .toList() ??
      const [],
  allergens:
      (json['allergens'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  customizations:
      (json['customizations'] as List<dynamic>?)
          ?.map(
            (e) => MenuItemCustomization.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  preparationTimeMinutes:
      (json['preparationTimeMinutes'] as num?)?.toInt() ?? 30,
  availableQuantity: (json['availableQuantity'] as num?)?.toInt(),
  unit: json['unit'] as String? ?? 'pax',
  isHalalCertified: json['isHalalCertified'] as bool? ?? false,
  rating: (json['rating'] as num?)?.toDouble(),
  reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
  nutritionalInfo: json['nutritionalInfo'] as Map<String, dynamic>?,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$MenuItemToJson(MenuItem instance) => <String, dynamic>{
  'id': instance.id,
  'vendorId': instance.vendorId,
  'name': instance.name,
  'description': instance.description,
  'category': instance.category,
  'basePrice': instance.basePrice,
  'bulkPricingTiers': instance.bulkPricingTiers,
  'minimumOrderQuantity': instance.minimumOrderQuantity,
  'maximumOrderQuantity': instance.maximumOrderQuantity,
  'status': _$MenuItemStatusEnumMap[instance.status]!,
  'imageUrls': instance.imageUrls,
  'dietaryTypes': instance.dietaryTypes
      .map((e) => _$DietaryTypeEnumMap[e]!)
      .toList(),
  'allergens': instance.allergens,
  'customizations': instance.customizations,
  'preparationTimeMinutes': instance.preparationTimeMinutes,
  'availableQuantity': instance.availableQuantity,
  'unit': instance.unit,
  'isHalalCertified': instance.isHalalCertified,
  'rating': instance.rating,
  'reviewCount': instance.reviewCount,
  'nutritionalInfo': instance.nutritionalInfo,
  'tags': instance.tags,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'isActive': instance.isActive,
};

const _$MenuItemStatusEnumMap = {
  MenuItemStatus.available: 'available',
  MenuItemStatus.unavailable: 'unavailable',
  MenuItemStatus.outOfStock: 'out_of_stock',
  MenuItemStatus.discontinued: 'discontinued',
};

const _$DietaryTypeEnumMap = {
  DietaryType.halal: 'halal',
  DietaryType.vegetarian: 'vegetarian',
  DietaryType.vegan: 'vegan',
  DietaryType.glutenFree: 'gluten_free',
  DietaryType.dairyFree: 'dairy_free',
  DietaryType.nutFree: 'nut_free',
};

MenuCategory _$MenuCategoryFromJson(Map<String, dynamic> json) => MenuCategory(
  id: json['id'] as String,
  vendorId: json['vendorId'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  imageUrl: json['imageUrl'] as String?,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  isActive: json['isActive'] as bool? ?? true,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$MenuCategoryToJson(MenuCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vendorId': instance.vendorId,
      'name': instance.name,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
      'sortOrder': instance.sortOrder,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
