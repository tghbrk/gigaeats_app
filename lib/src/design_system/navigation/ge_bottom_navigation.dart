import 'package:flutter/material.dart';
import '../tokens/tokens.dart';
import '../theme/theme.dart';
import '../../data/models/user_role.dart';

/// GigaEats Design System Bottom Navigation Component
/// 
/// A standardized bottom navigation that supports role-specific
/// customization while maintaining consistent design patterns.
class GEBottomNavigation extends StatelessWidget {
  final List<GENavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final UserRole? userRole;
  final Color? backgroundColor;
  final double? elevation;
  final bool showLabels;
  final GENavigationType type;

  const GEBottomNavigation({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.userRole,
    this.backgroundColor,
    this.elevation,
    this.showLabels = true,
    this.type = GENavigationType.adaptive,
  });

  /// Material 3 Navigation Bar style
  const GEBottomNavigation.navigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.userRole,
    this.backgroundColor,
    this.elevation,
    this.showLabels = true,
  }) : type = GENavigationType.navigationBar;

  /// Legacy Bottom Navigation Bar style
  const GEBottomNavigation.bottomNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.userRole,
    this.backgroundColor,
    this.elevation,
    this.showLabels = true,
  }) : type = GENavigationType.bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleTheme = userRole != null 
        ? GERoleThemeExtension.fromUserRole(userRole!)
        : theme.extension<GERoleThemeExtension>();
    
    switch (type) {
      case GENavigationType.navigationBar:
        return _buildNavigationBar(context, theme, roleTheme);
      case GENavigationType.bottomNavigationBar:
        return _buildBottomNavigationBar(context, theme, roleTheme);
      case GENavigationType.adaptive:
        // Use NavigationBar for Material 3, BottomNavigationBar for older versions
        return _buildNavigationBar(context, theme, roleTheme);
    }
  }

  Widget _buildNavigationBar(
    BuildContext context,
    ThemeData theme,
    GERoleThemeExtension? roleTheme,
  ) {
    final accentColor = roleTheme?.accentColor ?? theme.colorScheme.primary;
    
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      elevation: elevation ?? GEElevation.bottomNavigation,
      indicatorColor: accentColor.withValues(alpha: 0.1),
      destinations: destinations.map((dest) => NavigationDestination(
        icon: Icon(dest.icon),
        selectedIcon: Icon(dest.selectedIcon ?? dest.icon),
        label: showLabels ? dest.label : '',
        tooltip: dest.tooltip,
      )).toList(),
      labelBehavior: showLabels 
          ? NavigationDestinationLabelBehavior.alwaysShow
          : NavigationDestinationLabelBehavior.alwaysHide,
    );
  }

  Widget _buildBottomNavigationBar(
    BuildContext context,
    ThemeData theme,
    GERoleThemeExtension? roleTheme,
  ) {
    final accentColor = roleTheme?.accentColor ?? theme.colorScheme.primary;
    
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onDestinationSelected,
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      elevation: elevation ?? GEElevation.bottomNavigation,
      selectedItemColor: accentColor,
      unselectedItemColor: theme.colorScheme.onSurfaceVariant,
      type: destinations.length > 3 
          ? BottomNavigationBarType.fixed 
          : BottomNavigationBarType.shifting,
      showSelectedLabels: showLabels,
      showUnselectedLabels: showLabels,
      items: destinations.map((dest) => BottomNavigationBarItem(
        icon: Icon(dest.icon),
        activeIcon: Icon(dest.selectedIcon ?? dest.icon),
        label: dest.label,
        tooltip: dest.tooltip,
      )).toList(),
    );
  }
}

/// Navigation destination for GE bottom navigation
class GENavigationDestination {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final String? tooltip;
  final Widget? badge;

  const GENavigationDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.tooltip,
    this.badge,
  });
}

/// Navigation type enumeration
enum GENavigationType {
  navigationBar,
  bottomNavigationBar,
  adaptive,
}

/// Role-based navigation configuration
class GERoleNavigationConfig {
  final UserRole userRole;
  final List<GENavigationDestination> destinations;
  final String title;
  final IconData roleIcon;

  const GERoleNavigationConfig({
    required this.userRole,
    required this.destinations,
    required this.title,
    required this.roleIcon,
  });

  /// Customer navigation configuration
  static const customer = GERoleNavigationConfig(
    userRole: UserRole.customer,
    title: 'GigaEats',
    roleIcon: Icons.person,
    destinations: [
      GENavigationDestination(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: 'Home',
        tooltip: 'Home screen',
      ),
      GENavigationDestination(
        icon: Icons.restaurant_outlined,
        selectedIcon: Icons.restaurant,
        label: 'Restaurants',
        tooltip: 'Browse restaurants',
      ),
      GENavigationDestination(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
        label: 'Orders',
        tooltip: 'Your orders',
      ),
      GENavigationDestination(
        icon: Icons.account_balance_wallet_outlined,
        selectedIcon: Icons.account_balance_wallet,
        label: 'Wallet',
        tooltip: 'Your wallet',
      ),
      GENavigationDestination(
        icon: Icons.person_outlined,
        selectedIcon: Icons.person,
        label: 'Profile',
        tooltip: 'Your profile',
      ),
    ],
  );

  /// Vendor navigation configuration
  static const vendor = GERoleNavigationConfig(
    userRole: UserRole.vendor,
    title: 'Vendor Dashboard',
    roleIcon: Icons.store,
    destinations: [
      GENavigationDestination(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: 'Dashboard',
        tooltip: 'Vendor dashboard',
      ),
      GENavigationDestination(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
        label: 'Orders',
        tooltip: 'Manage orders',
      ),
      GENavigationDestination(
        icon: Icons.restaurant_menu_outlined,
        selectedIcon: Icons.restaurant_menu,
        label: 'Menu',
        tooltip: 'Manage menu',
      ),
      GENavigationDestination(
        icon: Icons.analytics_outlined,
        selectedIcon: Icons.analytics,
        label: 'Analytics',
        tooltip: 'View analytics',
      ),
      GENavigationDestination(
        icon: Icons.person_outlined,
        selectedIcon: Icons.person,
        label: 'Profile',
        tooltip: 'Vendor profile',
      ),
    ],
  );

  /// Driver navigation configuration
  static const driver = GERoleNavigationConfig(
    userRole: UserRole.driver,
    title: 'Driver Dashboard',
    roleIcon: Icons.delivery_dining,
    destinations: [
      GENavigationDestination(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: 'Dashboard',
        tooltip: 'Driver dashboard',
      ),
      GENavigationDestination(
        icon: Icons.assignment_outlined,
        selectedIcon: Icons.assignment,
        label: 'Orders',
        tooltip: 'Delivery orders',
      ),
      GENavigationDestination(
        icon: Icons.account_balance_wallet_outlined,
        selectedIcon: Icons.account_balance_wallet,
        label: 'Earnings',
        tooltip: 'Your earnings',
      ),
      GENavigationDestination(
        icon: Icons.person_outlined,
        selectedIcon: Icons.person,
        label: 'Profile',
        tooltip: 'Driver profile',
      ),
    ],
  );

  /// Sales Agent navigation configuration
  static const salesAgent = GERoleNavigationConfig(
    userRole: UserRole.salesAgent,
    title: 'Sales Agent Dashboard',
    roleIcon: Icons.support_agent,
    destinations: [
      GENavigationDestination(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: 'Dashboard',
        tooltip: 'Sales dashboard',
      ),
      GENavigationDestination(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
        label: 'Orders',
        tooltip: 'Manage orders',
      ),
      GENavigationDestination(
        icon: Icons.store_outlined,
        selectedIcon: Icons.store,
        label: 'Vendors',
        tooltip: 'Vendor management',
      ),
      GENavigationDestination(
        icon: Icons.people_outlined,
        selectedIcon: Icons.people,
        label: 'Customers',
        tooltip: 'Customer management',
      ),
      GENavigationDestination(
        icon: Icons.person_outlined,
        selectedIcon: Icons.person,
        label: 'Profile',
        tooltip: 'Your profile',
      ),
    ],
  );

  /// Admin navigation configuration
  static const admin = GERoleNavigationConfig(
    userRole: UserRole.admin,
    title: 'Admin Dashboard',
    roleIcon: Icons.admin_panel_settings,
    destinations: [
      GENavigationDestination(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: 'Dashboard',
        tooltip: 'Admin dashboard',
      ),
      GENavigationDestination(
        icon: Icons.people_outlined,
        selectedIcon: Icons.people,
        label: 'Users',
        tooltip: 'User management',
      ),
      GENavigationDestination(
        icon: Icons.store_outlined,
        selectedIcon: Icons.store,
        label: 'Vendors',
        tooltip: 'Vendor management',
      ),
      GENavigationDestination(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
        label: 'Orders',
        tooltip: 'Order management',
      ),
      GENavigationDestination(
        icon: Icons.analytics_outlined,
        selectedIcon: Icons.analytics,
        label: 'Reports',
        tooltip: 'System reports',
      ),
    ],
  );

  /// Get navigation configuration by user role
  static GERoleNavigationConfig fromUserRole(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return customer;
      case UserRole.vendor:
        return vendor;
      case UserRole.driver:
        return driver;
      case UserRole.salesAgent:
        return salesAgent;
      case UserRole.admin:
        return admin;
    }
  }
}
