/// GigaEats Design System Widget Components
///
/// This file exports all widget components for easy importing
/// throughout the application.
library;

// Button components
export 'buttons/buttons.dart';

// Card components
export 'cards/cards.dart';

// Input components
export 'inputs/inputs.dart';

// Layout components (to be added in next phase)
// export 'layout/layout.dart';

// Navigation components (to be added in next phase)
// export 'navigation/navigation.dart';

/// Widget components collection
class GEWidgets {
  // Prevent instantiation
  GEWidgets._();
  
  /// Widget components are available through their respective exports:
  /// 
  /// **Buttons:**
  /// - GEButton - Comprehensive button component
  /// 
  /// **Cards:**
  /// - GECard - Flexible card component
  /// - GEDashboardCard - Specialized dashboard card
  /// 
  /// **Inputs:**
  /// - GETextField - Comprehensive text field component
  /// 
  /// **Usage Examples:**
  /// ```dart
  /// // Using buttons
  /// GEButton.primary(
  ///   text: 'Save',
  ///   onPressed: () {},
  /// )
  /// 
  /// // Using cards
  /// GECard.elevated(
  ///   child: Text('Card content'),
  ///   onTap: () {},
  /// )
  /// 
  /// // Using text fields
  /// GETextField.outlined(
  ///   label: 'Email',
  ///   hint: 'Enter your email',
  /// )
  /// ```
}
