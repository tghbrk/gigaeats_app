import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/user.dart';
import '../../../../data/models/user_role.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  UserRole? _selectedRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All Users', icon: Icon(Icons.people)),
            Tab(text: 'Sales Agents', icon: Icon(Icons.person_pin)),
            Tab(text: 'Vendors', icon: Icon(Icons.store)),
            Tab(text: 'Pending', icon: Icon(Icons.pending_actions)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddUserDialog,
            tooltip: 'Add User',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Stats Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _buildStatCard('Total Users', '1,247', Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Active', '1,156', Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Pending', '91', Colors.orange)),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(UserRole.values),
                _buildUsersTab([UserRole.salesAgent]),
                _buildUsersTab([UserRole.vendor]),
                _buildPendingUsersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab(List<UserRole> roles) {
    // Sample users data - in real app, this would come from a provider
    final sampleUsers = _getSampleUsers().where((user) => roles.contains(user.role)).toList();
    
    final filteredUsers = sampleUsers.where((user) {
      final matchesSearch = _searchQuery.isEmpty ||
          user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesRole = _selectedRole == null || user.role == _selectedRole;
      return matchesSearch && matchesRole;
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildPendingUsersTab() {
    final pendingUsers = _getSampleUsers().where((user) => !user.isVerified).toList();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingUsers.length,
      itemBuilder: (context, index) {
        final user = pendingUsers[index];
        return _buildPendingUserCard(user);
      },
    );
  }

  Widget _buildUserCard(User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.1),
          child: Icon(
            _getRoleIcon(user.role),
            color: _getRoleColor(user.role),
          ),
        ),
        title: Text(user.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getRoleDisplayName(user.role),
                    style: TextStyle(
                      fontSize: 10,
                      color: _getRoleColor(user.role),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: user.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 10,
                      color: user.isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleUserAction(value, user),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View Details')),
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(
              value: user.isActive ? 'deactivate' : 'activate',
              child: Text(user.isActive ? 'Deactivate' : 'Activate'),
            ),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingUserCard(User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
          child: const Icon(Icons.pending_actions, color: Colors.orange),
        ),
        title: Text(user.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            Text(
              'Role: ${_getRoleDisplayName(user.role)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => _approveUser(user),
              tooltip: 'Approve',
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _rejectUser(user),
              tooltip: 'Reject',
            ),
          ],
        ),
      ),
    );
  }

  List<User> _getSampleUsers() {
    return [
      User(
        id: '1',
        email: 'john.doe@example.com',
        fullName: 'John Doe',
        phoneNumber: '+60123456789',
        role: UserRole.salesAgent,
        isVerified: true,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      User(
        id: '2',
        email: 'jane.smith@restaurant.com',
        fullName: 'Jane Smith',
        phoneNumber: '+60198765432',
        role: UserRole.vendor,
        isVerified: true,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now(),
      ),
      User(
        id: '3',
        email: 'pending.user@example.com',
        fullName: 'Pending User',
        phoneNumber: '+60111222333',
        role: UserRole.vendor,
        isVerified: false,
        isActive: false,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now(),
      ),
      User(
        id: '4',
        email: 'admin@gigaeats.com',
        fullName: 'Admin User',
        phoneNumber: '+60199888777',
        role: UserRole.admin,
        isVerified: true,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 100)),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.purple;
      case UserRole.vendor:
        return Colors.orange;
      case UserRole.salesAgent:
        return Colors.blue;
      case UserRole.customer:
        return Colors.green;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.vendor:
        return Icons.store;
      case UserRole.salesAgent:
        return Icons.person_pin;
      case UserRole.customer:
        return Icons.person;
    }
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.vendor:
        return 'Vendor';
      case UserRole.salesAgent:
        return 'Sales Agent';
      case UserRole.customer:
        return 'Customer';
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New User'),
        content: const Text('User creation functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Users'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<UserRole?>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: 'Role'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Roles')),
                ...UserRole.values.map((role) => DropdownMenuItem(
                  value: role,
                  child: Text(_getRoleDisplayName(role)),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRole = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {}); // Refresh the list
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _handleUserAction(String action, User user) {
    String message;
    switch (action) {
      case 'view':
        message = 'View details for ${user.fullName}';
        break;
      case 'edit':
        message = 'Edit ${user.fullName}';
        break;
      case 'activate':
        message = 'Activated ${user.fullName}';
        break;
      case 'deactivate':
        message = 'Deactivated ${user.fullName}';
        break;
      case 'delete':
        message = 'Deleted ${user.fullName}';
        break;
      default:
        message = 'Unknown action';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _approveUser(User user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Approved ${user.fullName}')),
    );
  }

  void _rejectUser(User user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rejected ${user.fullName}')),
    );
  }
}
