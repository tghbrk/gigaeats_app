/// Temporary stub for MenuItem model - to be implemented later
class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final bool isAvailable;
  final bool isVegetarian;
  final String? imageUrl;
  final String vendorId;
  final String categoryId;
  final DateTime createdAt;

  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.isAvailable = true,
    this.isVegetarian = false,
    this.imageUrl,
    required this.vendorId,
    required this.categoryId,
    required this.createdAt,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      isAvailable: json['is_available'] ?? true,
      isVegetarian: json['is_vegetarian'] ?? false,
      imageUrl: json['image_url'],
      vendorId: json['vendor_id'] ?? '',
      categoryId: json['category_id'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'is_available': isAvailable,
      'is_vegetarian': isVegetarian,
      'image_url': imageUrl,
      'vendor_id': vendorId,
      'category_id': categoryId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

enum MenuItemStatus {
  available,
  unavailable,
  outOfStock,
}

enum DietaryType {
  vegetarian,
  vegan,
  glutenFree,
  halal,
  kosher,
}

class MenuCategory {
  final String id;
  final String name;
  final String? description;
  final int sortOrder;

  const MenuCategory({
    required this.id,
    required this.name,
    this.description,
    this.sortOrder = 0,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sort_order': sortOrder,
    };
  }
}

class BulkPricingTier {
  final int minimumQuantity;
  final double price;
  final double? discountPercentage;

  const BulkPricingTier({
    required this.minimumQuantity,
    required this.price,
    this.discountPercentage,
  });

  factory BulkPricingTier.fromJson(Map<String, dynamic> json) {
    return BulkPricingTier(
      minimumQuantity: json['minimum_quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
      discountPercentage: json['discount_percentage']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minimum_quantity': minimumQuantity,
      'price': price,
      'discount_percentage': discountPercentage,
    };
  }
}
