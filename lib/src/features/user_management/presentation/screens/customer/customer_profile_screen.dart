import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/customer_profile_provider.dart';
import '../../providers/customer_order_statistics_provider.dart';
import '../../providers/customer_address_provider.dart' as address_provider;
import '../../../../auth/presentation/providers/auth_provider.dart';

import '../../widgets/customer_address_summary.dart';
import '../../../../../shared/widgets/profile_image_picker.dart';
import '../../../../../shared/widgets/custom_error_widget.dart';


/// Customer profile screen for viewing and managing customer profile
class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('🔍 [PROFILE-SCREEN] Customer profile screen initialized');
    // Load customer profile and addresses when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🔍 [PROFILE-SCREEN] Loading profile and addresses...');
      ref.read(customerProfileProvider.notifier).loadProfile();
      ref.read(address_provider.customerAddressesProvider.notifier).loadAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(customerProfileProvider);
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/customer/profile/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/customer/settings'),
          ),
        ],
      ),
      body: profileState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : profileState.error != null
              ? _buildErrorState(profileState.error!)
              : RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(customerProfileProvider.notifier).refresh();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileHeader(profileState, authState),
                        const SizedBox(height: 24),
                        _buildStatsSection(profileState),
                        const SizedBox(height: 24),
                        _buildAddressSection(),
                        const SizedBox(height: 24),
                        _buildQuickActions(),
                        const SizedBox(height: 24),
                        _buildAccountSection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  /// Build profile header with avatar and basic info
  Widget _buildProfileHeader(dynamic profileState, dynamic authState) {
    final theme = Theme.of(context);
    final profile = profileState.profile;
    final user = authState.user;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Profile image with upload functionality
              Stack(
                children: [
                  ProfileImagePicker(
                    currentImageUrl: profile?.profileImageUrl,
                    userId: user?.id ?? '',
                    size: 100,
                    onImageUploaded: (imageUrl) {
                      // Update profile with new image URL
                      if (profile != null) {
                        final updatedProfile = profile.copyWith(profileImageUrl: imageUrl);
                        ref.read(customerProfileProvider.notifier).updateProfile(updatedProfile);
                      }
                    },
                  ),
                  // Verification badge
                  if (profile?.isVerified == true)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Name and basic info
              Text(
                profile?.fullName ?? user?.fullName ?? 'Customer',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
              ),
              if (profile?.phoneNumber != null) ...[
                const SizedBox(height: 4),
                Text(
                  profile!.phoneNumber!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              // Member since
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Member since ${_formatDate(profile?.createdAt ?? DateTime.now())}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build statistics section showing order stats and loyalty points
  Widget _buildStatsSection(dynamic profileState) {
    debugPrint('🔍 [PROFILE-SCREEN] Building stats section...');
    final theme = Theme.of(context);
    final profile = profileState.profile;
    final orderStatsAsync = ref.watch(customerOrderQuickStatsProvider);
    debugPrint('🔍 [PROFILE-SCREEN] Order stats async state: ${orderStatsAsync.runtimeType}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Stats',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push('/customer/orders'),
              icon: const Icon(Icons.history, size: 18),
              label: const Text('View All'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        orderStatsAsync.when(
          data: (orderStats) => _buildOrderStatsCards(orderStats, profile, theme),
          loading: () => _buildStatsLoadingCards(theme),
          error: (error, _) => _buildStatsErrorCard(theme, error.toString()),
        ),
      ],
    );
  }

  Widget _buildOrderStatsCards(Map<String, dynamic> orderStats, dynamic profile, ThemeData theme) {
    return Column(
      children: [
        // First row: Order statistics
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.shopping_bag,
                title: 'Total Orders',
                value: '${orderStats['totalOrders'] ?? 0}',
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.attach_money,
                title: 'Total Spent',
                value: 'RM ${(orderStats['totalSpent'] ?? 0.0).toStringAsFixed(2)}',
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Second row: Active orders and monthly spending
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.pending_actions,
                title: 'Active Orders',
                value: '${orderStats['activeOrders'] ?? 0}',
                color: theme.colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.calendar_month,
                title: 'This Month',
                value: 'RM ${(orderStats['monthlySpending'] ?? 0.0).toStringAsFixed(2)}',
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Third row: Loyalty points and status
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.stars,
                title: 'Loyalty Points',
                value: '${orderStats['loyaltyPoints'] ?? 0}',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.verified_user,
                title: 'Status',
                value: profile?.isVerified == true ? 'Verified' : 'Pending',
                color: profile?.isVerified == true ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build individual stat card
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build address section
  Widget _buildAddressSection() {
    return const CustomerAddressSummary(
      showAddButton: true,
      showManageButton: true,
      padding: EdgeInsets.all(16),
    );
  }

  Widget _buildQuickActions() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionTile(
          icon: Icons.history,
          title: 'Order History',
          subtitle: 'View your past orders and track deliveries',
          onTap: () => context.push('/customer/orders'),
        ),
        Consumer(
          builder: (context, ref, child) {
            final addressesState = ref.watch(address_provider.customerAddressesProvider);
            final addressCount = addressesState.addresses.length;
            final hasDefault = addressesState.addresses.any((addr) => addr.isDefault);

            String subtitle;
            if (addressCount == 0) {
              subtitle = 'Add your first delivery address';
            } else if (addressCount == 1) {
              subtitle = hasDefault ? '1 address (default set)' : '1 address';
            } else {
              subtitle = hasDefault ? '$addressCount addresses (default set)' : '$addressCount addresses';
            }

            return _buildActionTile(
              icon: Icons.location_on,
              title: 'Manage Addresses',
              subtitle: subtitle,
              onTap: () => context.push('/customer/addresses'),
              trailing: addressCount > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$addressCount',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : null,
            );
          },
        ),
        _buildActionTile(
          icon: Icons.payment,
          title: 'Payment Methods',
          subtitle: 'Manage your payment options',
          onTap: () => context.push('/customer/payment-methods'),
        ),
        _buildActionTile(
          icon: Icons.account_balance_wallet,
          title: 'Wallet',
          subtitle: 'Manage your wallet balance',
          onTap: () => context.push('/customer/wallet'),
        ),
      ],
    );
  }

  /// Build action tile for quick actions
  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withValues(alpha: 0.1)
                : theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : theme.colorScheme.primary,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red : null,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  /// Build account section with settings and logout
  Widget _buildAccountSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionTile(
          icon: Icons.settings,
          title: 'Settings',
          subtitle: 'App preferences and notifications',
          onTap: () => context.push('/customer/settings'),
        ),
        _buildActionTile(
          icon: Icons.help_outline,
          title: 'Help & Support',
          subtitle: 'Get help and contact support',
          onTap: () => context.push('/customer/support'),
        ),
        _buildActionTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          subtitle: 'Read our privacy policy',
          onTap: () => context.push('/privacy-policy'),
        ),
        _buildActionTile(
          icon: Icons.logout,
          title: 'Logout',
          subtitle: 'Sign out of your account',
          onTap: _showLogoutDialog,
        ),
      ],
    );
  }

  /// Show logout confirmation dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authStateProvider.notifier).signOut();
              if (mounted) {
                context.go('/auth/login');
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  /// Build error state widget
  Widget _buildErrorState(String error) {
    return CustomErrorWidget(
      message: error,
      onRetry: () {
        ref.read(customerProfileProvider.notifier).refresh();
      },
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }

  Widget _buildStatsLoadingCards(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildLoadingStatCard(theme)),
            const SizedBox(width: 12),
            Expanded(child: _buildLoadingStatCard(theme)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildLoadingStatCard(theme)),
            const SizedBox(width: 12),
            Expanded(child: _buildLoadingStatCard(theme)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildLoadingStatCard(theme)),
            const SizedBox(width: 12),
            Expanded(child: _buildLoadingStatCard(theme)),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingStatCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 20,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsErrorCard(ThemeData theme, String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load order statistics',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              ref.invalidate(customerOrderQuickStatsProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
