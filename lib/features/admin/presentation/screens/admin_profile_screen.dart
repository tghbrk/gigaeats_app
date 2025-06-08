import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/auth_utils.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import 'admin_notification_settings_screen.dart';

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Profile'),
        ),
        body: const CustomErrorWidget(
          message: 'User not found. Please log in again.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit profile screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit profile coming soon')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            _buildProfileHeader(context, user),
            
            const SizedBox(height: 24),
            
            // Profile Information
            _buildProfileInformation(context, user),
            
            const SizedBox(height: 24),
            
            // Settings Section
            _buildSettingsSection(context),
            
            const SizedBox(height: 24),
            
            // Admin Actions
            _buildAdminActions(context),
            
            const SizedBox(height: 24),
            
            // Account Actions
            _buildAccountActions(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              backgroundImage: user.profileImageUrl != null 
                  ? NetworkImage(user.profileImageUrl!) 
                  : null,
              child: user.profileImageUrl == null
                  ? Icon(
                      Icons.admin_panel_settings,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Administrator',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        user.isVerified ? Icons.verified : Icons.pending,
                        size: 16,
                        color: user.isVerified ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.isVerified ? 'Verified' : 'Pending Verification',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: user.isVerified ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInformation(BuildContext context, dynamic user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(context, 'Email', user.email, Icons.email),
            const SizedBox(height: 12),
            _buildInfoRow(context, 'Phone', user.phoneNumber ?? 'Not provided', Icons.phone),
            const SizedBox(height: 12),
            _buildInfoRow(context, 'Role', 'Administrator', Icons.admin_panel_settings),
            const SizedBox(height: 12),
            _buildInfoRow(context, 'Status', user.isActive ? 'Active' : 'Inactive', Icons.circle),
            const SizedBox(height: 12),
            _buildInfoRow(context, 'Member Since', _formatDate(user.createdAt), Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notification Settings'),
              subtitle: const Text('Manage your notification preferences'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminNotificationSettingsScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Security Settings'),
              subtitle: const Text('Password and security options'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Navigate to security settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Security settings coming soon')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Settings'),
              subtitle: const Text('Data and privacy preferences'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Navigate to privacy settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Privacy settings coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('User Management'),
              subtitle: const Text('Manage users and permissions'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Navigate to user management
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User management coming soon')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Vendor Management'),
              subtitle: const Text('Approve and manage vendors'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Navigate to vendor management
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vendor management coming soon')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('System Analytics'),
              subtitle: const Text('View system performance and metrics'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Navigate to system analytics
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('System analytics coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActions(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Support'),
              subtitle: const Text('Get help and contact support'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Navigate to help
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help & support coming soon')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Sign out of your account'),
              onTap: () {
                _showSignOutDialog(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await AuthUtils.logout(context, ref);
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
