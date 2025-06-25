import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_user.dart';
import '../providers/admin_providers_index.dart';
import '../../../../data/models/user_role.dart';
import 'user_form_dialogs.dart';

// ============================================================================
// USER SEARCH AND FILTER BAR
// ============================================================================

/// Search and filter bar for user management
class UserSearchAndFilterBar extends ConsumerStatefulWidget {
  const UserSearchAndFilterBar({super.key});

  @override
  ConsumerState<UserSearchAndFilterBar> createState() => _UserSearchAndFilterBarState();
}

class _UserSearchAndFilterBarState extends ConsumerState<UserSearchAndFilterBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userManagementState = ref.watch(adminUserManagementProvider);
    final notifier = ref.read(adminUserManagementProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users by name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          notifier.searchUsers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                notifier.searchUsers(value);
              },
            ),
            
            const SizedBox(height: 16),
            
            // Filter Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Role Filter
                FilterChip(
                  label: Text('Role: ${userManagementState.selectedRole ?? 'All'}'),
                  selected: userManagementState.selectedRole != null,
                  onSelected: (selected) {
                    _showRoleFilterDialog(context, notifier);
                  },
                ),
                
                // Verification Filter
                FilterChip(
                  label: Text('Verified: ${_getVerificationFilterText(userManagementState.isVerifiedFilter)}'),
                  selected: userManagementState.isVerifiedFilter != null,
                  onSelected: (selected) {
                    if (selected) {
                      _showVerificationFilterDialog(context, notifier);
                    } else {
                      notifier.filterByVerification(null);
                    }
                  },
                ),
                
                // Active Status Filter
                FilterChip(
                  label: Text('Status: ${_getActiveFilterText(userManagementState.isActiveFilter)}'),
                  selected: userManagementState.isActiveFilter != null,
                  onSelected: (selected) {
                    if (selected) {
                      _showActiveFilterDialog(context, notifier);
                    } else {
                      notifier.filterByActiveStatus(null);
                    }
                  },
                ),
                
                // Clear All Filters
                if (userManagementState.selectedRole != null ||
                    userManagementState.isVerifiedFilter != null ||
                    userManagementState.isActiveFilter != null)
                  ActionChip(
                    label: const Text('Clear Filters'),
                    onPressed: () {
                      notifier.filterByRole(null);
                      notifier.filterByVerification(null);
                      notifier.filterByActiveStatus(null);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getVerificationFilterText(bool? isVerified) {
    if (isVerified == null) return 'All';
    return isVerified ? 'Verified' : 'Unverified';
  }

  String _getActiveFilterText(bool? isActive) {
    if (isActive == null) return 'All';
    return isActive ? 'Active' : 'Inactive';
  }

  void _showRoleFilterDialog(BuildContext context, AdminUserManagementNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Roles'),
              onTap: () {
                notifier.filterByRole(null);
                Navigator.of(context).pop();
              },
            ),
            ...UserRole.values.map((role) => ListTile(
              title: Text(role.displayName),
              onTap: () {
                notifier.filterByRole(role.value);
                Navigator.of(context).pop();
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showVerificationFilterDialog(BuildContext context, AdminUserManagementNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Users'),
              onTap: () {
                notifier.filterByVerification(null);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('Verified Only'),
              onTap: () {
                notifier.filterByVerification(true);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('Unverified Only'),
              onTap: () {
                notifier.filterByVerification(false);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showActiveFilterDialog(BuildContext context, AdminUserManagementNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Users'),
              onTap: () {
                notifier.filterByActiveStatus(null);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('Active Only'),
              onTap: () {
                notifier.filterByActiveStatus(true);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('Inactive Only'),
              onTap: () {
                notifier.filterByActiveStatus(false);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// USER LIST WIDGET
// ============================================================================

/// User list with pagination and actions
class UserListWidget extends ConsumerWidget {
  const UserListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userManagementState = ref.watch(adminUserManagementProvider);
    final notifier = ref.read(adminUserManagementProvider.notifier);

    if (userManagementState.isLoading && userManagementState.users.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (userManagementState.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading users',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              userManagementState.errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                notifier.clearError();
                notifier.loadUsers(refresh: true);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (userManagementState.users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // User Count Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '${userManagementState.users.length} users found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (userManagementState.users.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _showBulkActionsDialog(context, ref),
                  icon: const Icon(Icons.checklist),
                  label: const Text('Bulk Actions'),
                ),
            ],
          ),
        ),
        
        // User List
        Expanded(
          child: ListView.builder(
            itemCount: userManagementState.users.length + (userManagementState.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == userManagementState.users.length) {
                // Load more button
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: userManagementState.isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: () => notifier.loadMoreUsers(),
                            child: const Text('Load More'),
                          ),
                  ),
                );
              }

              final user = userManagementState.users[index];
              return UserListItem(user: user);
            },
          ),
        ),
      ],
    );
  }

  void _showBulkActionsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Actions'),
        content: const Text('Bulk actions feature coming soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// USER LIST ITEM
// ============================================================================

/// Individual user list item with actions
class UserListItem extends ConsumerWidget {
  final AdminUser user;

  const UserListItem({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.1),
          child: user.profileImageUrl != null
              ? ClipOval(
                  child: Image.network(
                    user.profileImageUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.person,
                      color: _getRoleColor(user.role),
                    ),
                  ),
                )
              : Icon(
                  Icons.person,
                  color: _getRoleColor(user.role),
                ),
        ),
        title: Text(
          user.fullName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusChip(user.role.displayName, _getRoleColor(user.role)),
                const SizedBox(width: 8),
                if (user.isVerified)
                  _buildStatusChip('Verified', Colors.green)
                else
                  _buildStatusChip('Unverified', Colors.orange),
                const SizedBox(width: 8),
                _buildStatusChip(
                  user.isActive ? 'Active' : 'Inactive',
                  user.isActive ? Colors.blue : Colors.red,
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Details
                _buildDetailRow('Phone', user.phoneNumber ?? 'Not provided'),
                _buildDetailRow('Created', _formatDate(user.createdAt)),
                _buildDetailRow('Last Sign In', user.lastSignInAt != null ? _formatDate(user.lastSignInAt!) : 'Never'),
                if (user.totalOrders > 0) ...[
                  _buildDetailRow('Total Orders', user.totalOrders.toString()),
                  _buildDetailRow('Total Earnings', 'RM ${user.totalEarnings.toStringAsFixed(2)}'),
                ],

                const SizedBox(height: 16),

                // Action Buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Status Toggle
                    ElevatedButton.icon(
                      onPressed: () => _showStatusChangeDialog(context, ref, user),
                      icon: Icon(user.isActive ? Icons.block : Icons.check_circle),
                      label: Text(user.isActive ? 'Deactivate' : 'Activate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: user.isActive ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),

                    // Role Change
                    OutlinedButton.icon(
                      onPressed: () => _showRoleChangeDialog(context, ref, user),
                      icon: const Icon(Icons.admin_panel_settings),
                      label: const Text('Change Role'),
                    ),

                    // Edit User
                    OutlinedButton.icon(
                      onPressed: () => _showEditUserDialog(context, ref, user),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),

                    // View Details
                    OutlinedButton.icon(
                      onPressed: () => _showUserDetailsDialog(context, user),
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Details'),
                    ),

                    // Delete User
                    OutlinedButton.icon(
                      onPressed: () => _showDeleteUserDialog(context, ref, user),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
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

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.vendor:
        return Colors.orange;
      case UserRole.driver:
        return Colors.blue;
      case UserRole.salesAgent:
        return Colors.purple;
      case UserRole.customer:
        return Colors.green;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showStatusChangeDialog(BuildContext context, WidgetRef ref, AdminUser user) {
    final action = user.isActive ? 'deactivate' : 'activate';
    final notifier = ref.read(adminUserManagementProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action.toUpperCase()} User'),
        content: Text('Are you sure you want to $action ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.updateUserStatus(user.id, !user.isActive);
              Navigator.of(context).pop();
            },
            child: Text(action.toUpperCase()),
          ),
        ],
      ),
    );
  }

  void _showRoleChangeDialog(BuildContext context, WidgetRef ref, AdminUser user) {
    final notifier = ref.read(adminUserManagementProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change User Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UserRole.values.map((role) => ListTile(
            title: Text(role.displayName),
            selected: role == user.role,
            onTap: () {
              if (role != user.role) {
                notifier.updateUserRole(user.id, role.value);
              }
              Navigator.of(context).pop();
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showUserDetailsDialog(BuildContext context, AdminUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.fullName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', user.email),
              _buildDetailRow('Phone', user.phoneNumber ?? 'Not provided'),
              _buildDetailRow('Role', user.role.displayName),
              _buildDetailRow('Status', user.isActive ? 'Active' : 'Inactive'),
              _buildDetailRow('Verified', user.isVerified ? 'Yes' : 'No'),
              _buildDetailRow('Created', _formatDate(user.createdAt)),
              _buildDetailRow('Updated', _formatDate(user.updatedAt)),
              if (user.lastSignInAt != null)
                _buildDetailRow('Last Sign In', _formatDate(user.lastSignInAt!)),
              if (user.totalOrders > 0) ...[
                _buildDetailRow('Total Orders', user.totalOrders.toString()),
                _buildDetailRow('Total Earnings', 'RM ${user.totalEarnings.toStringAsFixed(2)}'),
              ],
            ],
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

  void _showEditUserDialog(BuildContext context, WidgetRef ref, AdminUser user) {
    showDialog(
      context: context,
      builder: (context) => UserEditDialog(user: user),
    );
  }

  void _showDeleteUserDialog(BuildContext context, WidgetRef ref, AdminUser user) {
    final notifier = ref.read(adminUserManagementProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.fullName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.deleteUser(user.id, reason: 'Deleted by admin');
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}
