import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/customer_profile_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../core/utils/auth_utils.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load customer profile when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerProfileProvider.notifier).loadProfile();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/customer/profile/edit'),
          ),
        ],
      ),
      body: profileState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : profileState.error != null
              ? _buildErrorState(profileState.error!)
              : RefreshIndicator(
                  onRefresh: () => ref.read(customerProfileProvider.notifier).refresh(),
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
                        _buildQuickActions(),
                        const SizedBox(height: 24),
                        _buildAccountSection(),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  Widget _buildProfileHeader(CustomerProfileState profileState, AuthState authState) {
    final theme = Theme.of(context);
    final profile = profileState.profile;
    final user = authState.user;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile image
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  backgroundImage: profile?.profileImageUrl != null
                      ? NetworkImage(profile!.profileImageUrl!)
                      : null,
                  child: profile?.profileImageUrl == null
                      ? Icon(
                          Icons.person,
                          size: 50,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.camera_alt,
                        color: theme.colorScheme.onPrimary,
                        size: 20,
                      ),
                      onPressed: _showImageUploadDialog,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Name and email
            Text(
              profile?.fullName ?? user?.fullName ?? 'Customer',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            
            if (profile?.phoneNumber?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                profile!.phoneNumber!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Verification status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: profile?.isVerified == true
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    profile?.isVerified == true ? Icons.verified : Icons.pending,
                    size: 16,
                    color: profile?.isVerified == true ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    profile?.isVerified == true ? 'Verified' : 'Pending Verification',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: profile?.isVerified == true ? Colors.green[700] : Colors.orange[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(CustomerProfileState profileState) {
    final theme = Theme.of(context);
    final profile = profileState.profile;

    if (profile == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Stats',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // First row: Total Orders and Total Spent
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Total Orders',
                value: '${profile.totalOrders}',
                icon: Icons.receipt_long,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Total Spent',
                value: 'RM ${profile.totalSpent.toStringAsFixed(2)}',
                icon: Icons.attach_money,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Second row: Loyalty Points and Average Order Value
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Loyalty Points',
                value: '${profile.loyaltyPoints}',
                icon: Icons.stars,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Avg Order',
                value: profile.totalOrders > 0
                    ? 'RM ${(profile.totalSpent / profile.totalOrders).toStringAsFixed(2)}'
                    : 'RM 0.00',
                icon: Icons.trending_up,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Third row: Customer Since and Favorite Vendor
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Customer Since',
                value: _formatCustomerSinceDate(profile.createdAt),
                icon: Icons.calendar_today,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Favorite Restaurant',
                value: profile.favoriteVendorName ?? 'None yet',
                icon: Icons.favorite,
                isLongText: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    bool isLongText = false,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                fontSize: isLongText ? 12 : null,
              ),
              textAlign: TextAlign.center,
              maxLines: isLongText ? 2 : 1,
              overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  String _formatCustomerSinceDate(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

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

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionTile(
          icon: Icons.location_on,
          title: 'Manage Addresses',
          subtitle: 'Add or edit delivery addresses',
          onTap: () => context.push('/customer/addresses'),
        ),
        _buildActionTile(
          icon: Icons.settings,
          title: 'Preferences',
          subtitle: 'Food preferences and notifications',
          onTap: () => context.push('/customer/settings'),
        ),
        _buildActionTile(
          icon: Icons.history,
          title: 'Order History',
          subtitle: 'View your past orders',
          onTap: () => context.push('/customer/orders'),
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionTile(
          icon: Icons.settings,
          title: 'Settings',
          subtitle: 'App settings and preferences',
          onTap: () => context.push('/customer/settings'),
        ),
        _buildActionTile(
          icon: Icons.help,
          title: 'Help & Support',
          subtitle: 'Get help or contact support',
          onTap: () => context.push('/customer/support'),
        ),
        _buildActionTile(
          icon: Icons.logout,
          title: 'Sign Out',
          subtitle: 'Sign out of your account',
          onTap: _showSignOutDialog,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : theme.colorScheme.primary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Try Again',
              onPressed: () => ref.read(customerProfileProvider.notifier).refresh(),
              type: ButtonType.primary,
              isExpanded: false,
            ),
          ],
        ),
      ),
    );
  }

  void _showImageUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Profile Picture'),
        content: const Text('Profile picture upload functionality will be implemented soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthUtils.logout(context, ref);
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 4, // Profile is selected
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/customer/dashboard');
            break;
          case 1:
            context.push('/customer/restaurants');
            break;
          case 2:
            context.push('/customer/cart');
            break;
          case 3:
            context.push('/customer/orders');
            break;
          case 4:
            // Already on profile
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant),
          label: 'Restaurants',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
