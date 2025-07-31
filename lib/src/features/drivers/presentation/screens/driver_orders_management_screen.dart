import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/user_role.dart';
import '../../../../shared/widgets/auth_guard.dart';
import '../widgets/incoming_orders_tab.dart';
import '../widgets/active_orders_tab.dart';
import '../widgets/enhanced_history_orders_tab.dart';
import '../providers/driver_orders_management_providers.dart';

/// Dedicated Orders Management screen for drivers with three distinct tabs
class DriverOrdersManagementScreen extends ConsumerStatefulWidget {
  const DriverOrdersManagementScreen({super.key});

  @override
  ConsumerState<DriverOrdersManagementScreen> createState() => _DriverOrdersManagementScreenState();
}

class _DriverOrdersManagementScreenState extends ConsumerState<DriverOrdersManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      allowedRoles: const [UserRole.driver, UserRole.admin],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Orders'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshAllTabs,
              tooltip: 'Refresh all orders',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Incoming'),
              Tab(text: 'Active'),
              Tab(text: 'History'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            IncomingOrdersTab(),
            ActiveOrdersTab(),
            EnhancedHistoryOrdersTab(),
          ],
        ),
      ),
    );
  }

  // Removed unused helper methods: _buildCompactTabContent and _buildTabBadge

  void _refreshAllTabs() {
    debugPrint('🚗 Refreshing all order tabs');
    
    // Invalidate all stream providers to force refresh
    ref.invalidate(incomingOrdersStreamProvider);
    ref.invalidate(activeOrdersStreamProvider);
    ref.invalidate(historyOrdersStreamProvider);
    
    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing orders...'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
