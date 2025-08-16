/// GigaEats Design System Navigation Components
///
/// This file exports all navigation-related components for consistent
/// navigation patterns across all user interfaces.
library;

export 'ge_bottom_navigation.dart';
export 'ge_app_bar.dart';

/// Navigation components collection
class GENavigation {
  // Prevent instantiation
  GENavigation._();
  
  /// Navigation components are available through their respective exports:
  /// 
  /// **Bottom Navigation:**
  /// - GEBottomNavigation - Standardized bottom navigation
  /// - GEBottomNavigation.navigationBar - Material 3 navigation bar style
  /// - GEBottomNavigation.bottomNavigationBar - Legacy bottom navigation style
  /// - GERoleNavigationConfig - Role-based navigation configurations
  /// 
  /// **App Bars:**
  /// - GEAppBar - Standardized app bar with role theming
  /// - GEAppBar.withRole - App bar with role indicator
  /// - GEAppBar.simple - Simple app bar with just title
  /// - GESearchAppBar - Search-focused app bar
  /// 
  /// **Navigation Data:**
  /// - GENavigationDestination - Navigation destination data
  /// - GERoleNavigationConfig - Role-specific navigation configurations
  /// 
  /// **Usage Examples:**
  /// ```dart
  /// // Using bottom navigation with role theming
  /// GEBottomNavigation.navigationBar(
  ///   destinations: GERoleNavigationConfig.customer.destinations,
  ///   selectedIndex: currentIndex,
  ///   onDestinationSelected: (index) => setState(() => currentIndex = index),
  ///   userRole: UserRole.customer,
  /// )
  /// 
  /// // Using app bar with role indicator
  /// GEAppBar.withRole(
  ///   title: 'Dashboard',
  ///   userRole: UserRole.vendor,
  ///   onNotificationTap: () => showNotifications(),
  ///   notificationCount: 3,
  ///   onProfileTap: () => showProfile(),
  /// )
  /// 
  /// // Using search app bar
  /// GESearchAppBar(
  ///   hintText: 'Search restaurants...',
  ///   onChanged: (query) => searchRestaurants(query),
  ///   userRole: UserRole.customer,
  /// )
  /// 
  /// // Getting role-specific navigation config
  /// final config = GERoleNavigationConfig.fromUserRole(UserRole.driver);
  /// ```
}
