// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
  id: json['id'] as String,
  vendorId: json['vendor_id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  category: json['category'] as String,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  basePrice: (json['base_price'] as num).toDouble(),
  bulkPrice: (json['bulk_price'] as num?)?.toDouble(),
  bulkMinQuantity: (json['bulk_min_quantity'] as num?)?.toInt(),
  currency: json['currency'] as String?,
  includesSst: json['includes_sst'] as bool?,
  isAvailable: json['is_available'] as bool?,
  minOrderQuantity: (json['min_order_quantity'] as num?)?.toInt(),
  maxOrderQuantity: (json['max_order_quantity'] as num?)?.toInt(),
  preparationTimeMinutes: (json['preparation_time_minutes'] as num?)?.toInt(),
  allergens:
      (json['allergens'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  isHalal: json['is_halal'] as bool?,
  isVegetarian: json['is_vegetarian'] as bool?,
  isVegan: json['is_vegan'] as bool?,
  isSpicy: json['is_spicy'] as bool?,
  spicyLevel: (json['spicy_level'] as num?)?.toInt(),
  imageUrl: json['image_url'] as String?,
  galleryImages:
      (json['gallery_images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  nutritionInfo: json['nutrition_info'] as Map<String, dynamic>?,
  rating: (json['rating'] as num?)?.toDouble(),
  totalReviews: (json['total_reviews'] as num?)?.toInt(),
  isFeatured: json['is_featured'] as bool?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
  'id': instance.id,
  'vendor_id': instance.vendorId,
  'name': instance.name,
  'description': instance.description,
  'category': instance.category,
  'tags': instance.tags,
  'base_price': instance.basePrice,
  'bulk_price': instance.bulkPrice,
  'bulk_min_quantity': instance.bulkMinQuantity,
  'currency': instance.currency,
  'includes_sst': instance.includesSst,
  'is_available': instance.isAvailable,
  'min_order_quantity': instance.minOrderQuantity,
  'max_order_quantity': instance.maxOrderQuantity,
  'preparation_time_minutes': instance.preparationTimeMinutes,
  'allergens': instance.allergens,
  'is_halal': instance.isHalal,
  'is_vegetarian': instance.isVegetarian,
  'is_vegan': instance.isVegan,
  'is_spicy': instance.isSpicy,
  'spicy_level': instance.spicyLevel,
  'image_url': instance.imageUrl,
  'gallery_images': instance.galleryImages,
  'nutrition_info': instance.nutritionInfo,
  'rating': instance.rating,
  'total_reviews': instance.totalReviews,
  'is_featured': instance.isFeatured,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};
