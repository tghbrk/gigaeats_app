import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Information',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.person,
                            size: 30,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authState.user?.email ?? 'Not logged in',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Role: ${authState.user?.role.displayName ?? 'Unknown'}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Developer Tools Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Developer Tools',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: Icon(
                        Icons.developer_mode,
                        color: theme.colorScheme.primary,
                      ),
                      title: const Text('Consolidated Test Screen'),
                      subtitle: const Text('Access all testing tools and features'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        context.push('/test-consolidated');
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.camera_alt,
                        color: Colors.green,
                      ),
                      title: const Text('Delivery Proof Testing'),
                      subtitle: const Text('Test delivery proof capture workflow'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Navigate directly to delivery proof test
                        context.push('/test-consolidated');
                        // Show a snackbar to guide user
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Look for "Delivery Testing" section in the test screen'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.data_usage,
                        color: Colors.indigo,
                      ),
                      title: const Text('Data Integration Test'),
                      subtitle: const Text('Test data fetching and integration'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        context.push('/test-data');
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.auto_awesome,
                        color: Colors.purple,
                      ),
                      title: const Text('Enhanced Features Test'),
                      subtitle: const Text('Test enhanced order management features'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        context.push('/test-enhanced-features');
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // App Information Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Information',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                      title: const Text('Version'),
                      subtitle: const Text('1.0.0'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.cloud,
                        color: Colors.green,
                      ),
                      title: const Text('Backend'),
                      subtitle: const Text('Supabase (Connected)'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.security,
                        color: Colors.orange,
                      ),
                      title: const Text('Authentication'),
                      subtitle: const Text('Supabase Auth'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Actions Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actions',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: Icon(
                        Icons.refresh,
                        color: Colors.blue,
                      ),
                      title: const Text('Refresh App Data'),
                      subtitle: const Text('Reload all data from server'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Refresh app data
                        ref.invalidate(authStateProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('App data refreshed'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.logout,
                        color: Colors.red,
                      ),
                      title: const Text('Sign Out'),
                      subtitle: const Text('Sign out of your account'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => _showSignOutDialog(context, ref),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Footer
            Center(
              child: Text(
                'GigaEats - B2B2C Food Ordering Platform',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              await ref.read(authStateProvider.notifier).signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
