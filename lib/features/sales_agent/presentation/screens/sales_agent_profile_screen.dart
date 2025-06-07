import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/sales_agent_profile.dart';
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

  void _navigateToEditProfile(SalesAgentProfile profile) {
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
                        currentImageUrl: profile.profileImageUrl,
                        userId: profile.id,
                        size: 80,
                        onImageUploaded: (imageUrl) {
                          // Refresh profile after image upload
                          ref.read(salesAgentProfileStateProvider.notifier).refresh();
                        },
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

  Widget _buildPersonalInfo(SalesAgentProfile profile) {
    return Column(
      children: [
        _buildInfoRow('Full Name', profile.fullName),
        _buildInfoRow('Email', profile.email),
        _buildInfoRow('Phone Number', profile.phoneNumber ?? 'Not provided'),
        _buildInfoRow('Account Status', profile.isActive ? 'Active' : 'Inactive'),
        _buildInfoRow('Email Verified', profile.isVerified ? 'Yes' : 'No'),
      ],
    );
  }

  Widget _buildEmploymentDetails(SalesAgentProfile profile) {
    return Column(
      children: [
        _buildInfoRow('Company Name', profile.companyName ?? 'Not provided'),
        _buildInfoRow('Business Registration', profile.businessRegistrationNumber ?? 'Not provided'),
        _buildInfoRow('Business Address', profile.businessAddress ?? 'Not provided'),
        _buildInfoRow('Business Type', profile.businessType ?? 'Not provided'),
        _buildInfoRow('Commission Rate', profile.formattedCommissionRate),
        _buildInfoRow('Verification Status', profile.verificationStatus.toUpperCase()),
      ],
    );
  }

  Widget _buildPerformanceMetrics(SalesAgentProfile profile) {
    return Column(
      children: [
        _buildInfoRow('Total Earnings', 'RM ${profile.totalEarnings.toStringAsFixed(2)}'),
        _buildInfoRow('Total Orders', profile.totalOrders.toString()),
        _buildInfoRow('Average Order Value', 'RM ${profile.averageOrderValue.toStringAsFixed(2)}'),

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

  Widget _buildAssignedRegions(SalesAgentProfile profile) {
    if (profile.assignedRegions.isEmpty) {
      return const Text(
        'No regions assigned',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.grey,
        ),
      );
    }

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
  }

  Widget _buildSettings(SalesAgentProfile profile) {
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
