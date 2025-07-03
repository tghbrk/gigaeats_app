# Customer Menu Widgets

This directory contains reusable UI components for customer-facing menu functionality in the GigaEats app. All widgets follow Material Design 3 principles and maintain consistency across the application.

## Components Overview

### 🏪 Restaurant Components

#### `RestaurantInfoCard`
Displays comprehensive restaurant information including name, rating, status, cuisine types, and delivery details.

**Features:**
- Restaurant name and open/closed status
- Star rating and review count
- Description and cuisine type chips
- Delivery fee and time information
- Optional favorite and share actions

**Usage:**
```dart
RestaurantInfoCard(
  vendor: vendor,
  onFavoritePressed: () => _toggleFavorite(vendor),
  onSharePressed: () => _shareVendor(vendor),
)
```

### 🍽️ Menu Components

#### `MenuItemCard`
Enhanced menu item display with availability status, features, and add to cart functionality.

**Features:**
- Product image with availability overlay
- Enhanced typography and visual hierarchy
- Feature chips (Halal, Vegetarian, Spicy, etc.)
- Price display with minimum order information
- Add to cart button with proper states

**Usage:**
```dart
MenuItemCard(
  product: product,
  onTap: () => _showMenuItemDetails(product),
  onAddToCart: () => _addToCart(product),
)
```

#### `MenuSearchBar`
Material Design 3 styled search bar for menu item filtering.

**Features:**
- Modern SearchBar widget styling
- Clear button functionality
- Customizable hint text and actions
- Optional filter button integration

**Usage:**
```dart
MenuSearchBar(
  controller: _searchController,
  onChanged: (value) => setState(() => _searchQuery = value),
)
```

#### `CategoryFilterTabs`
Horizontal scrollable filter chips for menu categorization.

**Features:**
- Category filtering with item counts
- Material Design 3 chip styling
- Dynamic count updates
- Multiple styling variants (simple, material)

**Usage:**
```dart
CategoryFilterTabs(
  categories: categories,
  selectedCategory: _selectedCategory,
  onCategorySelected: (category) => setState(() => _selectedCategory = category),
  categoryCounts: categoryCounts,
)
```

### 🎯 Interactive Components

#### `QuantitySelectorDialog`
Reusable dialog for quantity selection with product information and validation.

**Features:**
- Product information display
- Quantity controls with validation
- Minimum order quantity support
- Real-time total price calculation
- Material Design 3 dialog styling

**Usage:**
```dart
QuantitySelectorDialog.show(
  context: context,
  product: product,
  onAddToCart: (quantity) => _addItemToCart(product, vendor, quantity: quantity),
)
```

#### `FeatureChip`
Small chips for displaying dietary and product features.

**Features:**
- Icon and text display
- Color-coded system
- Predefined factory methods
- Customizable styling

**Usage:**
```dart
FeatureChip.halal()
FeatureChip.vegetarian()
FeatureChip.spicy()
// Or custom:
FeatureChip(
  label: 'Custom',
  color: Colors.blue,
  icon: Icons.star,
)
```

## Design Principles

### Material Design 3 Compliance
- Uses proper color scheme tokens (primaryContainer, surfaceContainerHighest, etc.)
- Consistent elevation and shadow patterns
- Enhanced typography scale with appropriate font weights
- Modern component styling with rounded corners and proper spacing

### Accessibility
- Proper contrast ratios for all text and backgrounds
- Appropriate touch target sizes (minimum 48dp)
- Semantic labels and tooltips
- Screen reader friendly structure

### Performance
- Efficient widget rebuilds with proper key usage
- Optimized image loading with error handling
- Minimal widget tree depth
- Proper disposal of controllers and listeners

## Usage Guidelines

### Import Pattern
Use the index file for clean imports:
```dart
import '../../widgets/customer/index.dart';
```

### Consistency
- Always use the reusable components instead of creating custom implementations
- Follow the established color scheme and typography patterns
- Maintain consistent spacing and padding throughout

### Customization
- Use the provided parameters for customization
- Extend components through composition rather than inheritance
- Follow the established naming conventions for new components

## Testing
All components should be tested with:
- Unit tests for business logic
- Widget tests for UI behavior
- Integration tests for user interactions
- Accessibility tests for screen reader compatibility

## Contributing
When adding new components:
1. Follow the established patterns and naming conventions
2. Include comprehensive documentation
3. Add proper error handling and loading states
4. Ensure Material Design 3 compliance
5. Update this README with component information
