import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// TODO: Resolve SalesAgentProfile type conflicts between domain and data models
// Original: import '../../data/models/sales_agent_profile.dart';
// import '../../data/models/sales_agent_profile.dart' as data_model; // Unused - methods now use domain_model
import '../../../domain/sales_agent_profile.dart' as domain_model;
import '../../providers/sales_agent_profile_state_provider.dart';
import '../../data/repositories/sales_agent_repository.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/profile_image_picker.dart';
// import 'sales_agent_notification_settings_screen.dart'; // TEMPORARILY COMMENTED OUT

class SalesAgentProfileScreen extends ConsumerStatefulWidget {
  const SalesAgentProfileScreen({super.key});

  @override
  ConsumerState<SalesAgentProfileScreen> createState() => _SalesAgentProfileScreenState();
}

class _SalesAgentProfileScreenState extends ConsumerState<SalesAgentProfileScreen> {
  Map<String, dynamic>? _statistics;
  bool _isLoadingStatistics = false;
  String? _statisticsError;

  @override
  void initState() {
    super.initState();
    // Auto-load profile using provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(salesAgentProfileStateProvider.notifier).loadCurrentProfile();
      _loadStatistics();
    });
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoadingStatistics = true;
      _statisticsError = null;
    });

    try {
      final repository = SalesAgentRepository();
      final profileState = ref.read(salesAgentProfileStateProvider);

      if (profileState.profile?.id != null) {
        final statistics = await repository.getSalesAgentStatistics(profileState.profile!.id);
        setState(() {
          _statistics = statistics;
          _isLoadingStatistics = false;
        });
      } else {
        setState(() {
          _statisticsError = 'Profile not loaded';
          _isLoadingStatistics = false;
        });
      }
    } catch (e) {
      setState(() {
        _statisticsError = e.toString();
        _isLoadingStatistics = false;
      });
    }
  }

  // TODO: Restore original SalesAgentProfile type when conflicts are resolved
  // Original: void _navigateToEditProfile(SalesAgentProfile profile) {
  void _navigateToEditProfile(domain_model.SalesAgentProfile profile) {
    context.push('/sales-agent/profile/edit', extra: profile).then((result) {
      if (result == true) {
        // Refresh profile after editing
        ref.read(salesAgentProfileStateProvider.notifier).refresh();
        _loadStatistics(); // Reload statistics as well
      }
    });
  }

  Future<void> _refreshProfile() async {
    ref.read(salesAgentProfileStateProvider.notifier).refresh();
    await _loadStatistics();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileState = ref.watch(salesAgentProfileStateProvider);

    if (profileState.isLoading) {
      return const Scaffold(
        body: LoadingWidget(message: 'Loading profile...'),
      );
    }

    if (profileState.error != null) {
      return Scaffold(
        body: CustomErrorWidget(
          message: profileState.error ?? 'Failed to load sales agent profile',
          onRetry: () => ref.read(salesAgentProfileStateProvider.notifier).refresh(),
        ),
      );
    }

    if (profileState.profile == null) {
      return Scaffold(
        body: CustomErrorWidget(
          message: 'Sales agent profile not found',
          onRetry: () => ref.read(salesAgentProfileStateProvider.notifier).refresh(),
        ),
      );
    }

    final profile = profileState.profile!;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: CustomScrollView(
          slivers: [
          // Profile Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                profile.displayName,
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
                      ProfileImagePicker(
                        onImageSelected: (file) {
                          // TODO: Restore when image selection logic is implemented
                          debugPrint('🖼️ Sales agent profile image selected: $file');
                        },
                        // TODO: Restore when currentImageUrl parameter is implemented
                        // currentImageUrl: profile.profileImageUrl,
                        // TODO: Restore when userId parameter is implemented
                        // userId: profile.id,
                        size: 80,
                        // TODO: Restore when onImageUploaded parameter is implemented
                        /*onImageUploaded: (imageUrl) {
                          // Refresh profile after image upload
                          ref.read(salesAgentProfileStateProvider.notifier).refresh();
                        },*/
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            profile.isKycVerified ? Icons.verified : Icons.pending,
                            color: profile.isKycVerified ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            profile.verificationStatus.toUpperCase(),
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
                onPressed: () => _navigateToEditProfile(profile),
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
                children: [
                  // Personal Information
                  _buildSectionCard(
                    title: 'Personal Information',
                    icon: Icons.person,
                    child: _buildPersonalInfo(profile),
                  ),

                  const SizedBox(height: 16),

                  // Employment Details
                  _buildSectionCard(
                    title: 'Employment Details',
                    icon: Icons.work,
                    child: _buildEmploymentDetails(profile),
                  ),

                  const SizedBox(height: 16),

                  // Performance Metrics
                  _buildSectionCard(
                    title: 'Performance Metrics',
                    icon: Icons.analytics,
                    child: _buildPerformanceMetrics(profile),
                  ),

                  const SizedBox(height: 16),

                  // Assigned Regions
                  _buildSectionCard(
                    title: 'Assigned Regions',
                    icon: Icons.location_on,
                    child: _buildAssignedRegions(profile),
                  ),

                  const SizedBox(height: 16),

                  // Settings
                  _buildSectionCard(
                    title: 'Settings',
                    icon: Icons.settings,
                    child: _buildSettings(profile),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
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

  // TODO: Restore original SalesAgentProfile type when conflicts are resolved
  // Original: Widget _buildPersonalInfo(SalesAgentProfile profile) {
  Widget _buildPersonalInfo(domain_model.SalesAgentProfile profile) {
    return Column(
      children: [
        _buildInfoRow('Full Name', profile.fullName),
        _buildInfoRow('Email', profile.email),
        // TODO: Restore dead null aware expression - commented out for analyzer cleanup
        // Original: _buildInfoRow('Phone Number', profile.phoneNumber ?? 'Not provided'),
        _buildInfoRow('Phone Number', profile.phoneNumber ?? 'Not provided'),
        _buildInfoRow('Account Status', profile.isActive ? 'Active' : 'Inactive'),
        // TODO: Restore profile.isVerified when provider is implemented - commented out for analyzer cleanup
        _buildInfoRow('Email Verified', 'Unknown'), // profile.isVerified ? 'Yes' : 'No'),
      ],
    );
  }

  // TODO: Restore original SalesAgentProfile type when conflicts are resolved
  // Original: Widget _buildEmploymentDetails(SalesAgentProfile profile) {
  Widget _buildEmploymentDetails(domain_model.SalesAgentProfile profile) {
    return Column(
      children: [
        // TODO: Restore profile.companyName when provider is implemented - commented out for analyzer cleanup
        _buildInfoRow('Company Name', 'Not provided'), // profile.companyName ?? 'Not provided'),
        // TODO: Restore profile.businessRegistrationNumber when provider is implemented - commented out for analyzer cleanup
        _buildInfoRow('Business Registration', 'Not provided'), // profile.businessRegistrationNumber ?? 'Not provided'),
        // TODO: Restore profile.businessAddress when provider is implemented - commented out for analyzer cleanup
        _buildInfoRow('Business Address', 'Not provided'), // profile.businessAddress ?? 'Not provided'),
        // TODO: Restore profile.businessType when provider is implemented - commented out for analyzer cleanup
        _buildInfoRow('Business Type', 'Not provided'), // profile.businessType ?? 'Not provided'),
        // TODO: Restore profile.formattedCommissionRate when provider is implemented - commented out for analyzer cleanup
        _buildInfoRow('Commission Rate', 'Not available'), // profile.formattedCommissionRate),
        // TODO: Restore profile.verificationStatus when provider is implemented - commented out for analyzer cleanup
        _buildInfoRow('Verification Status', 'UNKNOWN'), // profile.verificationStatus.toUpperCase()),
      ],
    );
  }

  // TODO: Restore original SalesAgentProfile type when conflicts are resolved
  // Original: Widget _buildPerformanceMetrics(SalesAgentProfile profile) {
  Widget _buildPerformanceMetrics(domain_model.SalesAgentProfile profile) {
    return Column(
      children: [
        // TODO: Restore profile.totalEarnings when provider is implemented - commented out for analyzer cleanup
        _buildInfoRow('Total Earnings', 'RM 0.00'), // 'RM ${profile.totalEarnings.toStringAsFixed(2)}'),
        // TODO: Restore profile.totalOrders when provider is implemented - commented out for analyzer cleanup
        _buildInfoRow('Total Orders', '0'), // profile.totalOrders.toString()),
        // TODO: Restore profile.averageOrderValue when provider is implemented - commented out for analyzer cleanup
        _buildInfoRow('Average Order Value', 'RM 0.00'), // 'RM ${profile.averageOrderValue.toStringAsFixed(2)}'),

        // Statistics section with loading/error handling
        if (_isLoadingStatistics) ...[
          const SizedBox(height: 8),
          const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('Loading statistics...'),
            ],
          ),
        ] else if (_statisticsError != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Statistics unavailable',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ] else if (_statistics != null) ...[
          _buildInfoRow(
            'Total Customers',
            (_statistics!['total_customers'] ?? 0).toString()
          ),
          _buildInfoRow(
            'Success Rate',
            '${((_statistics!['success_rate'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(1)}%'
          ),
        ] else ...[
          const SizedBox(height: 8),
          Text(
            'No statistics available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }

  // TODO: Restore original SalesAgentProfile type when conflicts are resolved
  // Original: Widget _buildAssignedRegions(SalesAgentProfile profile) {
  Widget _buildAssignedRegions(domain_model.SalesAgentProfile profile) {
    // TODO: Restore profile.assignedRegions when provider is implemented - commented out for analyzer cleanup
    if (true) { // profile.assignedRegions.isEmpty) {
      return const Text(
        'No regions assigned',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.grey,
        ),
      );
    }

    // TODO: Restore assignedRegions when provider is implemented - commented out for analyzer cleanup
    /*
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: profile.assignedRegions.map((region) {
        return Chip(
          label: Text(
            region,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        );
      }).toList(),
    );
    */
  }

  // TODO: Restore original SalesAgentProfile type when conflicts are resolved
  // Original: Widget _buildSettings(SalesAgentProfile profile) {
  Widget _buildSettings(domain_model.SalesAgentProfile profile) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.edit),
          title: const Text('Edit Profile'),
          subtitle: const Text('Update personal and employment information'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _navigateToEditProfile(profile),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notification Settings'),
          subtitle: const Text('Manage notification preferences'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // TEMPORARILY COMMENTED OUT - NOTIFICATION SETTINGS SCREEN
            // Navigator.of(context).push(
            //   MaterialPageRoute(
            //     builder: (context) => const SalesAgentNotificationSettingsScreen(),
            //   ),
            // );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notification settings temporarily unavailable')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
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
}
