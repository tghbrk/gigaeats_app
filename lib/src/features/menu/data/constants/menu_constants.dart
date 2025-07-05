// Menu Item Status Enum
enum MenuItemStatus {
  available('available', 'Available'),
  unavailable('unavailable', 'Unavailable'),
  outOfStock('out_of_stock', 'Out of Stock'),
  discontinued('discontinued', 'Discontinued');

  const MenuItemStatus(this.value, this.displayName);
  final String value;
  final String displayName;

  static MenuItemStatus fromString(String value) {
    return MenuItemStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => MenuItemStatus.available,
    );
  }
}

// Dietary Type Enum
enum DietaryType {
  halal('halal', 'Halal'),
  vegetarian('vegetarian', 'Vegetarian'),
  vegan('vegan', 'Vegan'),
  glutenFree('gluten_free', 'Gluten Free'),
  dairyFree('dairy_free', 'Dairy Free'),
  nutFree('nut_free', 'Nut Free'),
  keto('keto', 'Keto'),
  lowCarb('low_carb', 'Low Carb'),
  organic('organic', 'Organic');

  const DietaryType(this.value, this.displayName);
  final String value;
  final String displayName;

  static DietaryType fromString(String value) {
    return DietaryType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DietaryType.halal,
    );
  }

  static List<String> get allValues => DietaryType.values.map((e) => e.value).toList();
  static List<String> get allDisplayNames => DietaryType.values.map((e) => e.displayName).toList();
}

// Spicy Level Enum
enum SpicyLevel {
  none(0, 'Not Spicy'),
  mild(1, 'Mild'),
  medium(2, 'Medium'),
  hot(3, 'Hot'),
  veryHot(4, 'Very Hot'),
  extreme(5, 'Extreme');

  const SpicyLevel(this.level, this.displayName);
  final int level;
  final String displayName;

  static SpicyLevel fromLevel(int level) {
    return SpicyLevel.values.firstWhere(
      (spicy) => spicy.level == level,
      orElse: () => SpicyLevel.none,
    );
  }
}

// Customization Type Enum
enum CustomizationType {
  single('single_select', 'Single Selection'),
  multiple('multiple_select', 'Multiple Selection'),
  text('text_input', 'Text Input'),
  number('number_input', 'Number Input');

  const CustomizationType(this.value, this.displayName);
  final String value;
  final String displayName;

  static CustomizationType fromString(String value) {
    return CustomizationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => CustomizationType.single,
    );
  }

  static List<String> get allValues => CustomizationType.values.map((e) => e.value).toList();
  static List<String> get allDisplayNames => CustomizationType.values.map((e) => e.displayName).toList();
}

// Currency Constants
class CurrencyConstants {
  static const String myr = 'MYR';
  static const String usd = 'USD';
  static const String sgd = 'SGD';
  static const String eur = 'EUR';
  static const String gbp = 'GBP';

  static const List<String> supported = [myr, usd, sgd, eur, gbp];
  
  static const Map<String, String> symbols = {
    myr: 'RM',
    usd: '\$',
    sgd: 'S\$',
    eur: '€',
    gbp: '£',
  };

  static String getSymbol(String currency) {
    return symbols[currency] ?? currency;
  }
}

// Unit Constants for Menu Items
class UnitConstants {
  static const String pax = 'pax';
  static const String pieces = 'pieces';
  static const String kg = 'kg';
  static const String grams = 'grams';
  static const String liters = 'liters';
  static const String ml = 'ml';
  static const String portions = 'portions';
  static const String servings = 'servings';

  static const List<String> all = [
    pax,
    pieces,
    kg,
    grams,
    liters,
    ml,
    portions,
    servings,
  ];

  static const Map<String, String> displayNames = {
    pax: 'Per Person',
    pieces: 'Pieces',
    kg: 'Kilograms',
    grams: 'Grams',
    liters: 'Liters',
    ml: 'Milliliters',
    portions: 'Portions',
    servings: 'Servings',
  };

  static String getDisplayName(String unit) {
    return displayNames[unit] ?? unit;
  }
}

// Preparation Time Constants
class PreparationTimeConstants {
  static const int quick = 15; // 15 minutes
  static const int normal = 30; // 30 minutes
  static const int slow = 60; // 1 hour
  static const int verySlow = 120; // 2 hours

  static const List<int> common = [15, 20, 30, 45, 60, 90, 120];

  static String getDisplayText(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours hr';
      } else {
        return '$hours hr $remainingMinutes min';
      }
    }
  }
}

// Common Tags for Menu Items
class MenuItemTags {
  static const String popular = 'Popular';
  static const String newItem = 'New';
  static const String recommended = 'Recommended';
  static const String chefSpecial = 'Chef Special';
  static const String seasonal = 'Seasonal';
  static const String limitedTime = 'Limited Time';
  static const String bestseller = 'Bestseller';
  static const String healthy = 'Healthy';
  static const String comfort = 'Comfort Food';
  static const String fusion = 'Fusion';
  static const String traditional = 'Traditional';
  static const String signature = 'Signature';

  static const List<String> all = [
    popular,
    newItem,
    recommended,
    chefSpecial,
    seasonal,
    limitedTime,
    bestseller,
    healthy,
    comfort,
    fusion,
    traditional,
    signature,
  ];
}

// Validation Constants
class MenuValidationConstants {
  static const int minNameLength = 2;
  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 500;
  static const double minPrice = 0.01;
  static const double maxPrice = 9999.99;
  static const int minPrepTime = 5;
  static const int maxPrepTime = 480; // 8 hours
  static const int minQuantity = 1;
  static const int maxQuantity = 999;
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
}

// Default Values
class MenuDefaults {
  static const String currency = CurrencyConstants.myr;
  static const int preparationTime = 30;
  static const int minOrderQuantity = 1;
  static const bool isAvailable = true;
  static const bool includesSst = false;
  static const bool isHalal = false;
  static const bool isVegetarian = false;
  static const bool isVegan = false;
  static const bool isSpicy = false;
  static const int spicyLevel = 0;
  static const bool isFeatured = false;
  static const String unit = UnitConstants.pax;
}
