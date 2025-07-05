import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'menu_organization.g.dart';

/// Enhanced menu category with organization features
@JsonSerializable()
class EnhancedMenuCategory extends Equatable {
  final String id;
  final String vendorId;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? iconName;
  final int sortOrder;
  final bool isActive;
  final bool isVisible;
  final bool isFeatured;
  final String? parentCategoryId;
  final List<String> subcategoryIds;
  final Map<String, dynamic>? displaySettings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EnhancedMenuCategory({
    required this.id,
    required this.vendorId,
    required this.name,
    this.description,
    this.imageUrl,
    this.iconName,
    this.sortOrder = 0,
    this.isActive = true,
    this.isVisible = true,
    this.isFeatured = false,
    this.parentCategoryId,
    this.subcategoryIds = const [],
    this.displaySettings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EnhancedMenuCategory.fromJson(Map<String, dynamic> json) => 
      _$EnhancedMenuCategoryFromJson(json);
  Map<String, dynamic> toJson() => _$EnhancedMenuCategoryToJson(this);

  @override
  List<Object?> get props => [
    id, vendorId, name, description, imageUrl, iconName, sortOrder,
    isActive, isVisible, isFeatured, parentCategoryId, subcategoryIds,
    displaySettings, createdAt, updatedAt
  ];

  EnhancedMenuCategory copyWith({
    String? id,
    String? vendorId,
    String? name,
    String? description,
    String? imageUrl,
    String? iconName,
    int? sortOrder,
    bool? isActive,
    bool? isVisible,
    bool? isFeatured,
    String? parentCategoryId,
    List<String>? subcategoryIds,
    Map<String, dynamic>? displaySettings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EnhancedMenuCategory(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      iconName: iconName ?? this.iconName,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      isVisible: isVisible ?? this.isVisible,
      isFeatured: isFeatured ?? this.isFeatured,
      parentCategoryId: parentCategoryId ?? this.parentCategoryId,
      subcategoryIds: subcategoryIds ?? this.subcategoryIds,
      displaySettings: displaySettings ?? this.displaySettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if this is a root category (no parent)
  bool get isRootCategory => parentCategoryId == null;

  /// Check if this category has subcategories
  bool get hasSubcategories => subcategoryIds.isNotEmpty;

  /// Get display icon based on category type
  String get displayIcon {
    if (iconName != null) return iconName!;
    
    // Default icons based on category name
    final lowerName = name.toLowerCase();
    if (lowerName.contains('rice') || lowerName.contains('nasi')) return 'rice_bowl';
    if (lowerName.contains('noodle') || lowerName.contains('mee')) return 'ramen_dining';
    if (lowerName.contains('drink') || lowerName.contains('beverage')) return 'local_drink';
    if (lowerName.contains('dessert') || lowerName.contains('sweet')) return 'cake';
    if (lowerName.contains('appetizer') || lowerName.contains('starter')) return 'restaurant';
    if (lowerName.contains('main') || lowerName.contains('course')) return 'dinner_dining';
    if (lowerName.contains('vegetarian') || lowerName.contains('vegan')) return 'eco';
    if (lowerName.contains('seafood') || lowerName.contains('fish')) return 'set_meal';
    
    return 'restaurant_menu';
  }
}

/// Menu item positioning and organization
@JsonSerializable()
class MenuItemPosition extends Equatable {
  final String menuItemId;
  final String categoryId;
  final int sortOrder;
  final bool isFeatured;
  final bool isRecommended;
  final bool isNew;
  final bool isPopular;
  final Map<String, dynamic>? displayTags;
  final DateTime updatedAt;

  const MenuItemPosition({
    required this.menuItemId,
    required this.categoryId,
    required this.sortOrder,
    this.isFeatured = false,
    this.isRecommended = false,
    this.isNew = false,
    this.isPopular = false,
    this.displayTags,
    required this.updatedAt,
  });

  factory MenuItemPosition.fromJson(Map<String, dynamic> json) => 
      _$MenuItemPositionFromJson(json);
  Map<String, dynamic> toJson() => _$MenuItemPositionToJson(this);

  @override
  List<Object?> get props => [
    menuItemId, categoryId, sortOrder, isFeatured, isRecommended,
    isNew, isPopular, displayTags, updatedAt
  ];

  MenuItemPosition copyWith({
    String? menuItemId,
    String? categoryId,
    int? sortOrder,
    bool? isFeatured,
    bool? isRecommended,
    bool? isNew,
    bool? isPopular,
    Map<String, dynamic>? displayTags,
    DateTime? updatedAt,
  }) {
    return MenuItemPosition(
      menuItemId: menuItemId ?? this.menuItemId,
      categoryId: categoryId ?? this.categoryId,
      sortOrder: sortOrder ?? this.sortOrder,
      isFeatured: isFeatured ?? this.isFeatured,
      isRecommended: isRecommended ?? this.isRecommended,
      isNew: isNew ?? this.isNew,
      isPopular: isPopular ?? this.isPopular,
      displayTags: displayTags ?? this.displayTags,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get display badges for this menu item
  List<MenuItemBadge> get displayBadges {
    final badges = <MenuItemBadge>[];
    
    if (isFeatured) badges.add(MenuItemBadge.featured);
    if (isRecommended) badges.add(MenuItemBadge.recommended);
    if (isNew) badges.add(MenuItemBadge.newItem);
    if (isPopular) badges.add(MenuItemBadge.popular);
    
    return badges;
  }
}

/// Menu organization configuration
@JsonSerializable()
class MenuOrganizationConfig extends Equatable {
  final String vendorId;
  final List<EnhancedMenuCategory> categories;
  final List<MenuItemPosition> itemPositions;
  final MenuDisplayStyle displayStyle;
  final bool enableCategoryImages;
  final bool enableSubcategories;
  final bool enableDragAndDrop;
  final bool showItemCounts;
  final bool groupByAvailability;
  final Map<String, dynamic>? customSettings;
  final DateTime updatedAt;

  const MenuOrganizationConfig({
    required this.vendorId,
    this.categories = const [],
    this.itemPositions = const [],
    this.displayStyle = MenuDisplayStyle.grid,
    this.enableCategoryImages = true,
    this.enableSubcategories = false,
    this.enableDragAndDrop = true,
    this.showItemCounts = true,
    this.groupByAvailability = false,
    this.customSettings,
    required this.updatedAt,
  });

  factory MenuOrganizationConfig.fromJson(Map<String, dynamic> json) => 
      _$MenuOrganizationConfigFromJson(json);
  Map<String, dynamic> toJson() => _$MenuOrganizationConfigToJson(this);

  @override
  List<Object?> get props => [
    vendorId, categories, itemPositions, displayStyle, enableCategoryImages,
    enableSubcategories, enableDragAndDrop, showItemCounts, groupByAvailability,
    customSettings, updatedAt
  ];

  MenuOrganizationConfig copyWith({
    String? vendorId,
    List<EnhancedMenuCategory>? categories,
    List<MenuItemPosition>? itemPositions,
    MenuDisplayStyle? displayStyle,
    bool? enableCategoryImages,
    bool? enableSubcategories,
    bool? enableDragAndDrop,
    bool? showItemCounts,
    bool? groupByAvailability,
    Map<String, dynamic>? customSettings,
    DateTime? updatedAt,
  }) {
    return MenuOrganizationConfig(
      vendorId: vendorId ?? this.vendorId,
      categories: categories ?? this.categories,
      itemPositions: itemPositions ?? this.itemPositions,
      displayStyle: displayStyle ?? this.displayStyle,
      enableCategoryImages: enableCategoryImages ?? this.enableCategoryImages,
      enableSubcategories: enableSubcategories ?? this.enableSubcategories,
      enableDragAndDrop: enableDragAndDrop ?? this.enableDragAndDrop,
      showItemCounts: showItemCounts ?? this.showItemCounts,
      groupByAvailability: groupByAvailability ?? this.groupByAvailability,
      customSettings: customSettings ?? this.customSettings,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get root categories (no parent)
  List<EnhancedMenuCategory> get rootCategories {
    return categories.where((cat) => cat.isRootCategory).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Get subcategories for a parent category
  List<EnhancedMenuCategory> getSubcategories(String parentId) {
    return categories.where((cat) => cat.parentCategoryId == parentId).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Get menu item position for a specific item
  MenuItemPosition? getItemPosition(String menuItemId) {
    return itemPositions.cast<MenuItemPosition?>().firstWhere(
      (pos) => pos?.menuItemId == menuItemId,
      orElse: () => null,
    );
  }

  /// Get items in a specific category sorted by position
  List<MenuItemPosition> getItemsInCategory(String categoryId) {
    return itemPositions.where((pos) => pos.categoryId == categoryId).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Update category sort orders after reordering
  MenuOrganizationConfig updateCategoryOrder(List<EnhancedMenuCategory> reorderedCategories) {
    final updatedCategories = <EnhancedMenuCategory>[];
    
    for (int i = 0; i < reorderedCategories.length; i++) {
      updatedCategories.add(reorderedCategories[i].copyWith(
        sortOrder: i,
        updatedAt: DateTime.now(),
      ));
    }
    
    // Add any categories not in the reordered list
    for (final category in categories) {
      if (!reorderedCategories.any((cat) => cat.id == category.id)) {
        updatedCategories.add(category);
      }
    }
    
    return copyWith(
      categories: updatedCategories,
      updatedAt: DateTime.now(),
    );
  }

  /// Update menu item positions after reordering
  MenuOrganizationConfig updateItemPositions(String categoryId, List<String> reorderedItemIds) {
    final updatedPositions = <MenuItemPosition>[];
    
    // Update positions for reordered items
    for (int i = 0; i < reorderedItemIds.length; i++) {
      final itemId = reorderedItemIds[i];
      final existingPosition = getItemPosition(itemId);
      
      if (existingPosition != null) {
        updatedPositions.add(existingPosition.copyWith(
          sortOrder: i,
          updatedAt: DateTime.now(),
        ));
      } else {
        // Create new position for items without existing position
        updatedPositions.add(MenuItemPosition(
          menuItemId: itemId,
          categoryId: categoryId,
          sortOrder: i,
          updatedAt: DateTime.now(),
        ));
      }
    }
    
    // Add positions for items in other categories
    for (final position in itemPositions) {
      if (position.categoryId != categoryId) {
        updatedPositions.add(position);
      }
    }
    
    return copyWith(
      itemPositions: updatedPositions,
      updatedAt: DateTime.now(),
    );
  }
}

/// Menu hierarchy node for tree structure
@JsonSerializable()
class MenuHierarchyNode extends Equatable {
  final EnhancedMenuCategory category;
  final List<MenuHierarchyNode> subcategories;
  final List<MenuItemPosition> items;
  final int totalItems;
  final int availableItems;

  const MenuHierarchyNode({
    required this.category,
    this.subcategories = const [],
    this.items = const [],
    this.totalItems = 0,
    this.availableItems = 0,
  });

  factory MenuHierarchyNode.fromJson(Map<String, dynamic> json) => 
      _$MenuHierarchyNodeFromJson(json);
  Map<String, dynamic> toJson() => _$MenuHierarchyNodeToJson(this);

  @override
  List<Object?> get props => [category, subcategories, items, totalItems, availableItems];

  MenuHierarchyNode copyWith({
    EnhancedMenuCategory? category,
    List<MenuHierarchyNode>? subcategories,
    List<MenuItemPosition>? items,
    int? totalItems,
    int? availableItems,
  }) {
    return MenuHierarchyNode(
      category: category ?? this.category,
      subcategories: subcategories ?? this.subcategories,
      items: items ?? this.items,
      totalItems: totalItems ?? this.totalItems,
      availableItems: availableItems ?? this.availableItems,
    );
  }

  /// Check if this node has any content (subcategories or items)
  bool get hasContent => subcategories.isNotEmpty || items.isNotEmpty;

  /// Get the depth level of this node in the hierarchy
  int get depth {
    if (subcategories.isEmpty) return 0;
    return subcategories.map((sub) => sub.depth).fold(0, (max, depth) => depth > max ? depth : max) + 1;
  }
}

/// Enums for menu organization
enum MenuDisplayStyle {
  list,
  grid,
  card,
  compact,
}

enum MenuItemBadge {
  featured,
  recommended,
  newItem,
  popular,
  soldOut,
  limitedTime,
}

/// Menu organization operation result
@JsonSerializable()
class MenuOrganizationResult extends Equatable {
  final bool success;
  final String? message;
  final MenuOrganizationConfig? config;
  final List<String> warnings;

  const MenuOrganizationResult({
    required this.success,
    this.message,
    this.config,
    this.warnings = const [],
  });

  factory MenuOrganizationResult.success({
    String? message,
    MenuOrganizationConfig? config,
    List<String> warnings = const [],
  }) {
    return MenuOrganizationResult(
      success: true,
      message: message,
      config: config,
      warnings: warnings,
    );
  }

  factory MenuOrganizationResult.failure({
    required String message,
    List<String> warnings = const [],
  }) {
    return MenuOrganizationResult(
      success: false,
      message: message,
      warnings: warnings,
    );
  }

  factory MenuOrganizationResult.fromJson(Map<String, dynamic> json) => 
      _$MenuOrganizationResultFromJson(json);
  Map<String, dynamic> toJson() => _$MenuOrganizationResultToJson(this);

  @override
  List<Object?> get props => [success, message, config, warnings];
}
