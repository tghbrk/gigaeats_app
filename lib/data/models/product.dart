import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'product.g.dart';

@JsonSerializable()
class Product extends Equatable {
  final String id;
  @JsonKey(name: 'vendor_id')
  final String vendorId;
  final String name;
  final String? description;
  final String category;
  final List<String> tags;
  @JsonKey(name: 'base_price')
  final double basePrice;
  @JsonKey(name: 'bulk_price')
  final double? bulkPrice;
  @JsonKey(name: 'bulk_min_quantity')
  final int? bulkMinQuantity;
  final String? currency;
  @JsonKey(name: 'includes_sst')
  final bool? includesSst;
  @JsonKey(name: 'is_available')
  final bool? isAvailable;
  @JsonKey(name: 'min_order_quantity')
  final int? minOrderQuantity;
  @JsonKey(name: 'max_order_quantity')
  final int? maxOrderQuantity;
  @JsonKey(name: 'preparation_time_minutes')
  final int? preparationTimeMinutes;
  final List<String> allergens;
  @JsonKey(name: 'is_halal')
  final bool? isHalal;
  @JsonKey(name: 'is_vegetarian')
  final bool? isVegetarian;
  @JsonKey(name: 'is_vegan')
  final bool? isVegan;
  @JsonKey(name: 'is_spicy')
  final bool? isSpicy;
  @JsonKey(name: 'spicy_level')
  final int? spicyLevel;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'gallery_images')
  final List<String> galleryImages;
  @JsonKey(name: 'nutrition_info')
  final Map<String, dynamic>? nutritionInfo;
  final double? rating;
  @JsonKey(name: 'total_reviews')
  final int? totalReviews;
  @JsonKey(name: 'is_featured')
  final bool? isFeatured;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const Product({
    required this.id,
    required this.vendorId,
    required this.name,
    this.description,
    required this.category,
    this.tags = const [],
    required this.basePrice,
    this.bulkPrice,
    this.bulkMinQuantity,
    this.currency,
    this.includesSst,
    this.isAvailable,
    this.minOrderQuantity,
    this.maxOrderQuantity,
    this.preparationTimeMinutes,
    this.allergens = const [],
    this.isHalal,
    this.isVegetarian,
    this.isVegan,
    this.isSpicy,
    this.spicyLevel,
    this.imageUrl,
    this.galleryImages = const [],
    this.nutritionInfo,
    this.rating,
    this.totalReviews,
    this.isFeatured,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);

  Product copyWith({
    String? id,
    String? vendorId,
    String? name,
    String? description,
    String? category,
    List<String>? tags,
    double? basePrice,
    double? bulkPrice,
    int? bulkMinQuantity,
    String? currency,
    bool? includesSst,
    bool? isAvailable,
    int? minOrderQuantity,
    int? maxOrderQuantity,
    int? preparationTimeMinutes,
    List<String>? allergens,
    bool? isHalal,
    bool? isVegetarian,
    bool? isVegan,
    bool? isSpicy,
    int? spicyLevel,
    String? imageUrl,
    List<String>? galleryImages,
    Map<String, dynamic>? nutritionInfo,
    double? rating,
    int? totalReviews,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      basePrice: basePrice ?? this.basePrice,
      bulkPrice: bulkPrice ?? this.bulkPrice,
      bulkMinQuantity: bulkMinQuantity ?? this.bulkMinQuantity,
      currency: currency ?? this.currency,
      includesSst: includesSst ?? this.includesSst,
      isAvailable: isAvailable ?? this.isAvailable,
      minOrderQuantity: minOrderQuantity ?? this.minOrderQuantity,
      maxOrderQuantity: maxOrderQuantity ?? this.maxOrderQuantity,
      preparationTimeMinutes: preparationTimeMinutes ?? this.preparationTimeMinutes,
      allergens: allergens ?? this.allergens,
      isHalal: isHalal ?? this.isHalal,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isVegan: isVegan ?? this.isVegan,
      isSpicy: isSpicy ?? this.isSpicy,
      spicyLevel: spicyLevel ?? this.spicyLevel,
      imageUrl: imageUrl ?? this.imageUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      nutritionInfo: nutritionInfo ?? this.nutritionInfo,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vendorId,
        name,
        description,
        category,
        tags,
        basePrice,
        bulkPrice,
        bulkMinQuantity,
        currency,
        includesSst,
        isAvailable,
        minOrderQuantity,
        maxOrderQuantity,
        preparationTimeMinutes,
        allergens,
        isHalal,
        isVegetarian,
        isVegan,
        isSpicy,
        spicyLevel,
        imageUrl,
        galleryImages,
        nutritionInfo,
        rating,
        totalReviews,
        isFeatured,
        createdAt,
        updatedAt,
      ];

  // Helper getters for backward compatibility and convenience
  double get effectivePrice => basePrice;

  double getPriceForQuantity(int quantity) {
    if (bulkPrice != null && bulkMinQuantity != null && quantity >= bulkMinQuantity!) {
      return bulkPrice!;
    }
    return effectivePrice;
  }

  bool get isInStock => isAvailable ?? true;
  bool get isHalalCertified => isHalal ?? false;
  bool get isVegetarianFriendly => isVegetarian ?? false;
  bool get isVeganFriendly => isVegan ?? false;
  bool get isSpicyFood => isSpicy ?? false;
  bool get isFeaturedItem => isFeatured ?? false;

  // Backward compatibility getters for old model structure
  ProductPricing get pricing => ProductPricing(
    basePrice: basePrice,
    bulkPrice: bulkPrice,
    bulkMinQuantity: bulkMinQuantity,
    currency: currency ?? 'MYR',
    includesSst: includesSst ?? false,
  );

  ProductAvailability get availability => ProductAvailability(
    isAvailable: isAvailable ?? true,
    minimumOrderQuantity: minOrderQuantity ?? 1,
    maximumOrderQuantity: maxOrderQuantity ?? 1000,
    preparationTimeMinutes: preparationTimeMinutes ?? 30,
  );

  ProductNutrition? get nutrition => nutritionInfo != null
    ? ProductNutrition.fromMap(nutritionInfo!)
    : null;

  // Non-nullable getters for UI
  String get safeDescription => description ?? '';
  double get safeRating => rating ?? 0.0;
  int get safeTotalReviews => totalReviews ?? 0;
  bool get safeIsHalal => isHalal ?? false;
  bool get safeIsVegetarian => isVegetarian ?? false;
  bool get safeIsVegan => isVegan ?? false;
  bool get safeIsSpicy => isSpicy ?? false;
  bool get safeIsFeatured => isFeatured ?? false;
  int get safeSpicyLevel => spicyLevel ?? 0;
}

// Product categories for Malaysian food
class ProductCategories {
  static const String rice = 'Rice Dishes';
  static const String noodles = 'Noodles';
  static const String curry = 'Curry & Gravy';
  static const String grilled = 'Grilled & BBQ';
  static const String soup = 'Soup';
  static const String appetizer = 'Appetizers';
  static const String dessert = 'Desserts';
  static const String beverage = 'Beverages';
  static const String vegetarian = 'Vegetarian';
  static const String seafood = 'Seafood';
  static const String chicken = 'Chicken';
  static const String beef = 'Beef';
  static const String mutton = 'Mutton';
  static const String snacks = 'Snacks';

  static const List<String> all = [
    rice,
    noodles,
    curry,
    grilled,
    soup,
    appetizer,
    dessert,
    beverage,
    vegetarian,
    seafood,
    chicken,
    beef,
    mutton,
    snacks,
  ];
}

// Backward compatibility classes
class ProductPricing {
  final double basePrice;
  final double? bulkPrice;
  final int? bulkMinQuantity;
  final String currency;
  final bool includesSst;

  const ProductPricing({
    required this.basePrice,
    this.bulkPrice,
    this.bulkMinQuantity,
    this.currency = 'MYR',
    this.includesSst = false,
  });

  double get effectivePrice => basePrice;

  double getPriceForQuantity(int quantity) {
    if (bulkPrice != null && bulkMinQuantity != null && quantity >= bulkMinQuantity!) {
      return bulkPrice!;
    }
    return effectivePrice;
  }
}

class ProductAvailability {
  final bool isAvailable;
  final int minimumOrderQuantity;
  final int maximumOrderQuantity;
  final int preparationTimeMinutes;
  final int? stockQuantity;

  const ProductAvailability({
    this.isAvailable = true,
    this.minimumOrderQuantity = 1,
    this.maximumOrderQuantity = 1000,
    this.preparationTimeMinutes = 30,
    this.stockQuantity,
  });

  bool get isInStock => isAvailable;
}

class ProductNutrition {
  final double? calories;
  final double? protein;
  final double? carbohydrates;
  final double? fat;
  final double? fiber;
  final double? sugar;
  final double? sodium;
  final String servingSize;

  const ProductNutrition({
    this.calories,
    this.protein,
    this.carbohydrates,
    this.fat,
    this.fiber,
    this.sugar,
    this.sodium,
    this.servingSize = '1 serving',
  });

  factory ProductNutrition.fromMap(Map<String, dynamic> map) {
    return ProductNutrition(
      calories: map['calories']?.toDouble(),
      protein: map['protein']?.toDouble(),
      carbohydrates: map['carbohydrates']?.toDouble(),
      fat: map['fat']?.toDouble(),
      fiber: map['fiber']?.toDouble(),
      sugar: map['sugar']?.toDouble(),
      sodium: map['sodium']?.toDouble(),
      servingSize: map['servingSize'] ?? '1 serving',
    );
  }
}

// Common allergens
class CommonAllergens {
  static const String nuts = 'Nuts';
  static const String dairy = 'Dairy';
  static const String eggs = 'Eggs';
  static const String soy = 'Soy';
  static const String gluten = 'Gluten';
  static const String shellfish = 'Shellfish';
  static const String fish = 'Fish';
  static const String sesame = 'Sesame';

  static const List<String> all = [
    nuts,
    dairy,
    eggs,
    soy,
    gluten,
    shellfish,
    fish,
    sesame,
  ];
}


