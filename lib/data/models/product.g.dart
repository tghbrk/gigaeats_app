// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
  id: json['id'] as String,
  vendorId: json['vendorId'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  category: json['category'] as String,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  pricing: ProductPricing.fromJson(json['pricing'] as Map<String, dynamic>),
  availability: ProductAvailability.fromJson(
    json['availability'] as Map<String, dynamic>,
  ),
  nutrition: json['nutrition'] == null
      ? null
      : ProductNutrition.fromJson(json['nutrition'] as Map<String, dynamic>),
  allergens:
      (json['allergens'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  isHalal: json['isHalal'] as bool? ?? false,
  isVegetarian: json['isVegetarian'] as bool? ?? false,
  isVegan: json['isVegan'] as bool? ?? false,
  isSpicy: json['isSpicy'] as bool? ?? false,
  spicyLevel: (json['spicyLevel'] as num?)?.toInt() ?? 0,
  imageUrl: json['imageUrl'] as String?,
  galleryImages:
      (json['galleryImages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
  totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
  isActive: json['isActive'] as bool? ?? true,
  isFeatured: json['isFeatured'] as bool? ?? false,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
  'id': instance.id,
  'vendorId': instance.vendorId,
  'name': instance.name,
  'description': instance.description,
  'category': instance.category,
  'tags': instance.tags,
  'pricing': instance.pricing,
  'availability': instance.availability,
  'nutrition': instance.nutrition,
  'allergens': instance.allergens,
  'isHalal': instance.isHalal,
  'isVegetarian': instance.isVegetarian,
  'isVegan': instance.isVegan,
  'isSpicy': instance.isSpicy,
  'spicyLevel': instance.spicyLevel,
  'imageUrl': instance.imageUrl,
  'galleryImages': instance.galleryImages,
  'rating': instance.rating,
  'totalReviews': instance.totalReviews,
  'isActive': instance.isActive,
  'isFeatured': instance.isFeatured,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

ProductPricing _$ProductPricingFromJson(Map<String, dynamic> json) =>
    ProductPricing(
      basePrice: (json['basePrice'] as num).toDouble(),
      discountPrice: (json['discountPrice'] as num?)?.toDouble(),
      bulkPrice: (json['bulkPrice'] as num?)?.toDouble(),
      bulkMinQuantity: (json['bulkMinQuantity'] as num?)?.toInt(),
      currency: json['currency'] as String? ?? 'MYR',
      includesSst: json['includesSst'] as bool? ?? false,
    );

Map<String, dynamic> _$ProductPricingToJson(ProductPricing instance) =>
    <String, dynamic>{
      'basePrice': instance.basePrice,
      'discountPrice': instance.discountPrice,
      'bulkPrice': instance.bulkPrice,
      'bulkMinQuantity': instance.bulkMinQuantity,
      'currency': instance.currency,
      'includesSst': instance.includesSst,
    };

ProductAvailability _$ProductAvailabilityFromJson(
  Map<String, dynamic> json,
) => ProductAvailability(
  isAvailable: json['isAvailable'] as bool? ?? true,
  stockQuantity: (json['stockQuantity'] as num?)?.toInt(),
  dailyLimit: (json['dailyLimit'] as num?)?.toInt(),
  weeklyLimit: (json['weeklyLimit'] as num?)?.toInt(),
  availableDays:
      (json['availableDays'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  availableTimeStart: json['availableTimeStart'] as String?,
  availableTimeEnd: json['availableTimeEnd'] as String?,
  minimumOrderQuantity: (json['minimumOrderQuantity'] as num?)?.toInt() ?? 1,
  maximumOrderQuantity: (json['maximumOrderQuantity'] as num?)?.toInt() ?? 1000,
  preparationTimeMinutes:
      (json['preparationTimeMinutes'] as num?)?.toInt() ?? 30,
);

Map<String, dynamic> _$ProductAvailabilityToJson(
  ProductAvailability instance,
) => <String, dynamic>{
  'isAvailable': instance.isAvailable,
  'stockQuantity': instance.stockQuantity,
  'dailyLimit': instance.dailyLimit,
  'weeklyLimit': instance.weeklyLimit,
  'availableDays': instance.availableDays,
  'availableTimeStart': instance.availableTimeStart,
  'availableTimeEnd': instance.availableTimeEnd,
  'minimumOrderQuantity': instance.minimumOrderQuantity,
  'maximumOrderQuantity': instance.maximumOrderQuantity,
  'preparationTimeMinutes': instance.preparationTimeMinutes,
};

ProductNutrition _$ProductNutritionFromJson(Map<String, dynamic> json) =>
    ProductNutrition(
      calories: (json['calories'] as num?)?.toDouble(),
      protein: (json['protein'] as num?)?.toDouble(),
      carbohydrates: (json['carbohydrates'] as num?)?.toDouble(),
      fat: (json['fat'] as num?)?.toDouble(),
      fiber: (json['fiber'] as num?)?.toDouble(),
      sugar: (json['sugar'] as num?)?.toDouble(),
      sodium: (json['sodium'] as num?)?.toDouble(),
      servingSize: json['servingSize'] as String? ?? '1 serving',
    );

Map<String, dynamic> _$ProductNutritionToJson(ProductNutrition instance) =>
    <String, dynamic>{
      'calories': instance.calories,
      'protein': instance.protein,
      'carbohydrates': instance.carbohydrates,
      'fat': instance.fat,
      'fiber': instance.fiber,
      'sugar': instance.sugar,
      'sodium': instance.sodium,
      'servingSize': instance.servingSize,
    };
