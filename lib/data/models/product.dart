import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'product.g.dart';

@JsonSerializable()
class Product extends Equatable {
  final String id;
  final String vendorId;
  final String name;
  final String description;
  final String category;
  final List<String> tags;
  final ProductPricing pricing;
  final ProductAvailability availability;
  final ProductNutrition? nutrition;
  final List<String> allergens;
  final bool isHalal;
  final bool isVegetarian;
  final bool isVegan;
  final bool isSpicy;
  final int spicyLevel; // 0-5 scale
  final String? imageUrl;
  final List<String> galleryImages;
  final double rating;
  final int totalReviews;
  final bool isActive;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.description,
    required this.category,
    this.tags = const [],
    required this.pricing,
    required this.availability,
    this.nutrition,
    this.allergens = const [],
    this.isHalal = false,
    this.isVegetarian = false,
    this.isVegan = false,
    this.isSpicy = false,
    this.spicyLevel = 0,
    this.imageUrl,
    this.galleryImages = const [],
    this.rating = 0.0,
    this.totalReviews = 0,
    this.isActive = true,
    this.isFeatured = false,
    required this.createdAt,
    required this.updatedAt,
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
    ProductPricing? pricing,
    ProductAvailability? availability,
    ProductNutrition? nutrition,
    List<String>? allergens,
    bool? isHalal,
    bool? isVegetarian,
    bool? isVegan,
    bool? isSpicy,
    int? spicyLevel,
    String? imageUrl,
    List<String>? galleryImages,
    double? rating,
    int? totalReviews,
    bool? isActive,
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
      pricing: pricing ?? this.pricing,
      availability: availability ?? this.availability,
      nutrition: nutrition ?? this.nutrition,
      allergens: allergens ?? this.allergens,
      isHalal: isHalal ?? this.isHalal,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isVegan: isVegan ?? this.isVegan,
      isSpicy: isSpicy ?? this.isSpicy,
      spicyLevel: spicyLevel ?? this.spicyLevel,
      imageUrl: imageUrl ?? this.imageUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      isActive: isActive ?? this.isActive,
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
        pricing,
        availability,
        nutrition,
        allergens,
        isHalal,
        isVegetarian,
        isVegan,
        isSpicy,
        spicyLevel,
        imageUrl,
        galleryImages,
        rating,
        totalReviews,
        isActive,
        isFeatured,
        createdAt,
        updatedAt,
      ];
}

@JsonSerializable()
class ProductPricing extends Equatable {
  final double basePrice;
  final double? discountPrice;
  final double? bulkPrice; // Price for bulk orders (>= bulkMinQuantity)
  final int? bulkMinQuantity;
  final String currency;
  final bool includesSst;

  const ProductPricing({
    required this.basePrice,
    this.discountPrice,
    this.bulkPrice,
    this.bulkMinQuantity,
    this.currency = 'MYR',
    this.includesSst = false,
  });

  factory ProductPricing.fromJson(Map<String, dynamic> json) => _$ProductPricingFromJson(json);
  Map<String, dynamic> toJson() => _$ProductPricingToJson(this);

  double get effectivePrice => discountPrice ?? basePrice;
  
  double getPriceForQuantity(int quantity) {
    if (bulkPrice != null && bulkMinQuantity != null && quantity >= bulkMinQuantity!) {
      return bulkPrice!;
    }
    return effectivePrice;
  }

  @override
  List<Object?> get props => [basePrice, discountPrice, bulkPrice, bulkMinQuantity, currency, includesSst];
}

@JsonSerializable()
class ProductAvailability extends Equatable {
  final bool isAvailable;
  final int? stockQuantity;
  final int? dailyLimit;
  final int? weeklyLimit;
  final List<String> availableDays; // ['monday', 'tuesday', etc.]
  final String? availableTimeStart;
  final String? availableTimeEnd;
  final int minimumOrderQuantity;
  final int maximumOrderQuantity;
  final int preparationTimeMinutes;

  const ProductAvailability({
    this.isAvailable = true,
    this.stockQuantity,
    this.dailyLimit,
    this.weeklyLimit,
    this.availableDays = const [],
    this.availableTimeStart,
    this.availableTimeEnd,
    this.minimumOrderQuantity = 1,
    this.maximumOrderQuantity = 1000,
    this.preparationTimeMinutes = 30,
  });

  factory ProductAvailability.fromJson(Map<String, dynamic> json) => _$ProductAvailabilityFromJson(json);
  Map<String, dynamic> toJson() => _$ProductAvailabilityToJson(this);

  bool get isInStock => stockQuantity == null || stockQuantity! > 0;
  bool get hasStockLimit => stockQuantity != null;

  @override
  List<Object?> get props => [
        isAvailable,
        stockQuantity,
        dailyLimit,
        weeklyLimit,
        availableDays,
        availableTimeStart,
        availableTimeEnd,
        minimumOrderQuantity,
        maximumOrderQuantity,
        preparationTimeMinutes,
      ];
}

@JsonSerializable()
class ProductNutrition extends Equatable {
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

  factory ProductNutrition.fromJson(Map<String, dynamic> json) => _$ProductNutritionFromJson(json);
  Map<String, dynamic> toJson() => _$ProductNutritionToJson(this);

  @override
  List<Object?> get props => [calories, protein, carbohydrates, fat, fiber, sugar, sodium, servingSize];
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
