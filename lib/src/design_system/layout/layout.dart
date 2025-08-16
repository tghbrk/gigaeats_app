/// GigaEats Design System Layout Components
///
/// This file exports all layout-related components for consistent
/// screen structure and content organization.
library;

export 'ge_screen.dart';

/// Layout components collection
class GELayout {
  // Prevent instantiation
  GELayout._();
  
  /// Layout components are available through their respective exports:
  /// 
  /// **Screen Layouts:**
  /// - GEScreen - Standardized screen layout
  /// - GEScreen.scrollable - Scrollable screen variant
  /// 
  /// **Content Organization:**
  /// - GESection - Section layout for organizing content
  /// - GEContainer - Standardized container with consistent styling
  /// - GEContainer.card - Card-style container variant
  /// - GEGrid - Responsive grid layout
  /// - GEGrid.responsive - Auto-responsive grid variant
  /// 
  /// **Usage Examples:**
  /// ```dart
  /// // Using screen layout
  /// GEScreen.scrollable(
  ///   appBar: AppBar(title: Text('Title')),
  ///   body: Column(children: [...]),
  ///   onRefresh: () async {},
  /// )
  /// 
  /// // Using section layout
  /// GESection(
  ///   title: 'Recent Orders',
  ///   action: TextButton(child: Text('View All')),
  ///   child: OrdersList(),
  /// )
  /// 
  /// // Using container
  /// GEContainer.card(
  ///   child: Text('Card content'),
  /// )
  /// 
  /// // Using grid
  /// GEGrid.responsive(
  ///   children: items.map((item) => ItemCard(item)).toList(),
  /// )
  /// ```
}
