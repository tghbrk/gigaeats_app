import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/admin_providers_index.dart';
import '../widgets/user_management_widgets.dart';
import '../widgets/user_form_dialogs.dart';

// ============================================================================
// COMPREHENSIVE USER MANAGEMENT SCREEN
// ============================================================================

/// Standalone user management screen with full functionality
class AdminUserManagementScreen extends ConsumerStatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  ConsumerState<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends ConsumerState<AdminUserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load users when screen is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminUserManagementProvider.notifier).loadUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(adminUserManagementProvider.notifier).loadUsers(refresh: true);
            },
            tooltip: 'Refresh Users',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _showExportDialog(context),
            tooltip: 'Export Users',
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'bulk_actions',
                child: ListTile(
                  leading: Icon(Icons.checklist),
                  title: Text('Bulk Actions'),
                ),
              ),
              const PopupMenuItem(
                value: 'user_statistics',
                child: ListTile(
                  leading: Icon(Icons.analytics),
                  title: Text('User Statistics'),
                ),
              ),
              const PopupMenuItem(
                value: 'export_csv',
                child: ListTile(
                  leading: Icon(Icons.file_download),
                  title: Text('Export CSV'),
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Users', icon: Icon(Icons.people)),
            Tab(text: 'Pending', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All Users Tab
          const _AllUsersTab(),
          
          // Pending Users Tab
          const _PendingUsersTab(),
          
          // Analytics Tab
          const _UserAnalyticsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin_user_management_fab',
        onPressed: () => _showCreateUserDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'bulk_actions':
        _showBulkActionsDialog(context);
        break;
      case 'user_statistics':
        _showUserStatisticsDialog(context);
        break;
      case 'export_csv':
        _exportUsersCSV();
        break;
    }
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Users'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Export as CSV'),
              onTap: () {
                Navigator.of(context).pop();
                _exportUsersCSV();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.of(context).pop();
                _exportUsersPDF();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCreateUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const UserCreationDialog(),
    );
  }

  void _showBulkActionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Actions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Activate Selected'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implement bulk activate
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Deactivate Selected'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implement bulk deactivate
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Selected'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implement bulk delete
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showUserStatisticsDialog(BuildContext context) {
    final userStatsAsync = ref.watch(userStatisticsProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Statistics'),
        content: SizedBox(
          width: double.maxFinite,
          child: userStatsAsync.when(
            data: (stats) => Column(
              mainAxisSize: MainAxisSize.min,
              children: stats.map((stat) => ListTile(
                title: Text(stat.role.toUpperCase()),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stat.totalUsers.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '+${stat.newThisWeek} this week',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              )).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text('Error: $error'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _exportUsersCSV() {
    // TODO: Implement CSV export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV export functionality coming soon')),
    );
  }

  void _exportUsersPDF() {
    // TODO: Implement PDF export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF export functionality coming soon')),
    );
  }
}

// ============================================================================
// TAB CONTENT WIDGETS
// ============================================================================

/// All users tab content
class _AllUsersTab extends StatelessWidget {
  const _AllUsersTab();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        // Search and Filter Bar
        UserSearchAndFilterBar(),
        
        // User List
        Expanded(
          child: UserListWidget(),
        ),
      ],
    );
  }
}

/// Pending users tab content
class _PendingUsersTab extends ConsumerWidget {
  const _PendingUsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pending_actions,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Pending Users',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Pending user approvals will appear here',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// User analytics tab content
class _UserAnalyticsTab extends ConsumerWidget {
  const _UserAnalyticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStatsAsync = ref.watch(userStatisticsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: userStatsAsync.when(
        data: (stats) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: stats.length,
                itemBuilder: (context, index) {
                  final stat = stats[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            stat.role.toUpperCase(),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            stat.totalUsers.toString(),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '+${stat.newThisWeek} this week',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading statistics: $error'),
            ],
          ),
        ),
      ),
    );
  }
}
