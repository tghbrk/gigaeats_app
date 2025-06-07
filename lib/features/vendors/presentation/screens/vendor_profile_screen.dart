import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/vendor.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../presentation/providers/repository_providers.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
// TEMPORARILY COMMENTED OUT FOR QUICK WIN
// import 'vendor_edit_profile_screen.dart';
// import 'vendor_notification_settings_screen.dart';

class VendorProfileScreen extends ConsumerStatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  ConsumerState<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends ConsumerState<VendorProfileScreen> {
  bool _isLoading = false;
  Vendor? _vendor;

  @override
  void initState() {
    super.initState();
    _loadVendorProfile();
  }

  void _loadVendorProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get vendor profile from Supabase
      final vendorRepository = ref.read(vendorRepositoryProvider);
      final vendor = await vendorRepository.getVendorByUserId(userId);

      if (vendor == null) {
        throw Exception('Vendor profile not found');
      }

      setState(() {
        _vendor = vendor;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading vendor profile: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: LoadingWidget(message: 'Loading profile...'),
      );
    }

    if (_vendor == null) {
      return Scaffold(
        body: CustomErrorWidget(
          message: 'Failed to load vendor profile',
          onRetry: () => _loadVendorProfile(),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _vendor!.businessName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          _vendor!.businessName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _vendor!.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => _navigateToEditProfile(),
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Profile',
              ),
            ],
          ),

          // Profile Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status and Verification
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _vendor!.isActive
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _vendor!.isActive ? Icons.check_circle : Icons.block,
                              size: 16,
                              color: _vendor!.isActive ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _vendor!.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: _vendor!.isActive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_vendor!.isHalalCertified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                size: 16,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Halal Certified',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Business Information
                  _buildSectionCard(
                    title: 'Business Information',
                    icon: Icons.business,
                    child: _buildBusinessInfo(),
                  ),

                  const SizedBox(height: 16),

                  // Contact Information
                  _buildSectionCard(
                    title: 'Contact Information',
                    icon: Icons.contact_phone,
                    child: _buildContactInfo(),
                  ),

                  const SizedBox(height: 16),

                  // Address Information
                  _buildSectionCard(
                    title: 'Address',
                    icon: Icons.location_on,
                    child: _buildAddressInfo(),
                  ),

                  const SizedBox(height: 16),

                  // Operating Hours
                  _buildSectionCard(
                    title: 'Operating Hours',
                    icon: Icons.schedule,
                    child: _buildOperatingHours(),
                    action: IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _navigateToEditProfile(),
                      tooltip: 'Edit Operating Hours',
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cuisine Types
                  _buildSectionCard(
                    title: 'Cuisine Types',
                    icon: Icons.restaurant,
                    child: _buildCuisineTypes(),
                  ),

                  const SizedBox(height: 16),

                  // Settings
                  _buildSectionCard(
                    title: 'Settings',
                    icon: Icons.settings,
                    child: _buildSettings(),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? action,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (action != null) action,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfo() {
    return Column(
      children: [
        _buildInfoRow('Business Name', _vendor!.businessName),
        _buildInfoRow('Description', _vendor!.description ?? 'No description available'),
        _buildInfoRow('Business Type', _vendor!.businessType),
        _buildInfoRow('Rating', '${_vendor!.rating.toStringAsFixed(1)} stars'),
        _buildInfoRow('Total Reviews', '${_vendor!.totalReviews} reviews'),
        _buildInfoRow('SSM Number', _vendor!.businessRegistrationNumber),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Column(
      children: [
        _buildInfoRow('Email', _vendor!.email),
        _buildInfoRow('Phone', _vendor!.phoneNumber),
        // Note: Website field not available in current Vendor model
      ],
    );
  }

  Widget _buildAddressInfo() {
    return Column(
      children: [
        _buildInfoRow('Business Address', _vendor!.businessAddress),
        // Note: Detailed address breakdown not available in current Vendor model
      ],
    );
  }

  Widget _buildOperatingHours() {
    final dayNames = {
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday',
    };

    return Column(
      children: _vendor!.businessInfo.operatingHours.schedule.entries.map((entry) {
        final dayName = dayNames[entry.key] ?? entry.key;
        return _buildInfoRow(
          dayName,
          entry.value.safeIsOpen
              ? '${entry.value.openTime ?? 'N/A'} - ${entry.value.closeTime ?? 'N/A'}'
              : 'Closed',
        );
      }).toList(),
    );
  }

  Widget _buildCuisineTypes() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _vendor!.cuisineTypes.map((cuisine) {
        return Chip(
          label: Text(cuisine),
          backgroundColor: Colors.grey.withValues(alpha: 0.1),
        );
      }).toList(),
    );
  }

  Widget _buildSettings() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.edit),
          title: const Text('Edit Profile'),
          subtitle: const Text('Update business information'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _navigateToEditProfile(),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notification Settings'),
          subtitle: const Text('Manage notification preferences'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _navigateToNotificationSettings(),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.security),
          title: const Text('Security Settings'),
          subtitle: const Text('Password and security options'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showComingSoon('Security settings'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.help),
          title: const Text('Help & Support'),
          subtitle: const Text('Get help and contact support'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showComingSoon('Help & support'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          subtitle: const Text('Sign out of your account'),
          onTap: () => _showSignOutDialog(),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  void _navigateToEditProfile() {
    if (_vendor == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Edit Profile')),
          body: const Center(child: Text('Edit Profile - Coming Soon')),
        ),
      ),
    ).then((result) {
      // If the profile was updated successfully, reload the profile
      if (result == true) {
        _loadVendorProfile();
      }
    });
  }

  void _navigateToNotificationSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Notification Settings')),
          body: const Center(child: Text('Notification Settings - Coming Soon')),
        ),
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
            onPressed: () {
              Navigator.pop(context);
              ref.read(authStateProvider.notifier).signOut();
              context.go('/login');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
