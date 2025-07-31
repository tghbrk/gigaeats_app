import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/user_role.dart';
import '../../../../shared/widgets/auth_guard.dart';
// Import the enhanced driver profile screen with debug logging
import '../../../user_management/presentation/screens/driver/driver_profile_screen.dart';
import '../../../payments/presentation/screens/driver/driver_earnings_screen.dart';
import 'driver_orders_screen.dart';
import 'driver_orders_management_screen.dart';

/// Main driver dashboard with bottom navigation
///
/// Note: The Map tab has been removed as it didn't serve a functional purpose
/// in the driver workflow. Map functionality is preserved in navigation features
/// used during order delivery. Future implementation may add a map feature for
/// visualizing nearby orders.
class DriverDashboard extends ConsumerStatefulWidget {
  const DriverDashboard({super.key});

  @override
  ConsumerState<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends ConsumerState<DriverDashboard> {
  int _selectedIndex = 0;

  final List<NavigationDestination> _destinations = [
    const NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const NavigationDestination(
      icon: Icon(Icons.assignment_outlined),
      selectedIcon: Icon(Icons.assignment),
      label: 'Orders',
    ),
    const NavigationDestination(
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet),
      label: 'Earnings',
    ),
    const NavigationDestination(
      icon: Icon(Icons.person_outlined),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      allowedRoles: const [UserRole.driver, UserRole.admin],
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            const DriverOrdersScreen(key: ValueKey('driver_dashboard_tab')),
            const DriverOrdersManagementScreen(key: ValueKey('driver_orders_management_tab')),
            // Use the static earnings screen to prevent infinite loops
            const DriverEarningsScreen(key: ValueKey('driver_earnings_tab')),
            const DriverProfileScreen(key: ValueKey('driver_profile_tab')),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: _destinations,
        ),
      ),
    );
  }
}

/// Wrapper widget to isolate earnings screen rebuilds
class _EarningsScreenWrapper extends StatefulWidget {
  @override
  _EarningsScreenWrapperState createState() => _EarningsScreenWrapperState();
}

class _EarningsScreenWrapperState extends State<_EarningsScreenWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    debugPrint('💰 _EarningsScreenWrapper: build() called at ${DateTime.now()}');
    return const DriverEarningsScreen();
  }
}
