import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../../../data/models/user_role.dart';
import '../../../../shared/widgets/quick_action_button.dart';
import '../../../user_management/presentation/screens/admin/admin_profile_screen.dart';
import '../../../user_management/presentation/screens/admin/admin_notification_settings_screen.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _selectedIndex = 0;

  // Use GE navigation configuration for admin role
  final _navigationConfig = GERoleNavigationConfig.admin;

  @override
  Widget build(BuildContext context) {
    return GEScreen(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _AdminDashboardTab(),
          _AdminUsersTab(),
          _AdminVendorsTab(),
          _AdminOrdersTab(),
          _AdminReportsTab(),
        ],
      ),
      bottomNavigationBar: GEBottomNavigation.navigationBar(
        destinations: _navigationConfig.destinations,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        userRole: UserRole.admin,
      ),
    );
  }
}

class _AdminDashboardTab extends ConsumerWidget {
  const _AdminDashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GEScreen.scrollable(
      appBar: GEAppBar.withRole(
        title: 'Admin Dashboard',
        userRole: UserRole.admin,
        onNotificationTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AdminNotificationSettingsScreen(),
            ),
          );
        },
        onProfileTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AdminProfileScreen(),
            ),
          );
        },
        actions: [
          IconButton(
            icon: const Icon(Icons.developer_mode),
            onPressed: () {
              context.push('/test-consolidated');
            },
            tooltip: 'Developer Tools',
          ),
        ],
      ),
      onRefresh: () async {
        // TODO: Implement refresh logic
        await Future.delayed(const Duration(seconds: 1));
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GESection(
            title: 'Platform Overview',
            subtitle: 'Monitor key metrics and system performance',
            child: GEGrid(
              crossAxisCount: 2,
              children: [
                GEDashboardCard(
                  title: 'Total Revenue',
                  value: 'RM 125,450',
                  subtitle: '+18% this month',
                  icon: Icons.account_balance_wallet,
                  trend: '+18%',
                  isPositiveTrend: true,
                ),
                GEDashboardCard(
                  title: 'Active Users',
                  value: '1,247',
                  subtitle: '89 new this week',
                  icon: Icons.people,
                ),
                GEDashboardCard(
                  title: 'Total Orders',
                  value: '3,456',
                  subtitle: '234 today',
                  icon: Icons.receipt_long,
                ),
                GEDashboardCard(
                  title: 'Active Vendors',
                  value: '89',
                  subtitle: '12 pending approval',
                  icon: Icons.store,
                ),
              ],
            ),
          ),
          GESection(
            title: 'Quick Actions',
            subtitle: 'Common administrative tasks',
            child: Column(
              children: [
              
              Row(
                children: [
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.person_add,
                      label: 'Approve Users',
                      onTap: () {
                        // TODO: Navigate to user approvals
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.store_mall_directory,
                      label: 'Manage Vendors',
                      onTap: () {
                        // TODO: Navigate to vendor management
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.assessment,
                      label: 'View Reports',
                      onTap: () {
                        // TODO: Navigate to reports
                      },
                    ),
                  ),
                ],
              ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



// Placeholder tabs - to be implemented
class _AdminUsersTab extends StatelessWidget {
  const _AdminUsersTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: const Center(
        child: Text('User Management Tab - Coming Soon'),
      ),
    );
  }
}

class _AdminVendorsTab extends StatelessWidget {
  const _AdminVendorsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Management')),
      body: const Center(
        child: Text('Vendor Management Tab - Coming Soon'),
      ),
    );
  }
}

class _AdminOrdersTab extends StatelessWidget {
  const _AdminOrdersTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Management')),
      body: const Center(
        child: Text('Order Management Tab - Coming Soon'),
      ),
    );
  }
}

class _AdminReportsTab extends StatelessWidget {
  const _AdminReportsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Analytics')),
      body: const Center(
        child: Text('Reports & Analytics Tab - Coming Soon'),
      ),
    );
  }
}
