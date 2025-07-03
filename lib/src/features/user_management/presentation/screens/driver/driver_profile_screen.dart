// TODO: Restore when dart:async is used
// import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// TODO: Restore when go_router is used
// import 'package:go_router/go_router.dart';

// TODO: Restore when user_role is used
// import '../../../../data/models/user_role.dart';
// TODO: Restore when loading_widget is used
// import '../../../../shared/widgets/loading_widget.dart';
// TODO: Restore when profile_image_picker is used
// import '../../../../shared/widgets/profile_image_picker.dart';
// TODO: Restore when auth_provider is used
// import '../../../auth/presentation/providers/auth_provider.dart';
// TODO: Restore when driver domain and provider are implemented
// import '../../../user_management/domain/driver.dart';
// import '../providers/driver_profile_provider.dart';

// TODO: Restore when auth_utils is used
// import '../../../../core/utils/auth_utils.dart';

/// Driver profile screen with personal info and vehicle details
class DriverProfileScreen extends ConsumerStatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  ConsumerState<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends ConsumerState<DriverProfileScreen> {
  // TODO: Use _formKey when form validation is restored
  // final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _vehicleBrandController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _vehicleYearController = TextEditingController();

  // TODO: Restore when Driver class is implemented
  // Driver? _currentDriver;
  // TODO: Use _currentDriver when Driver class is restored
  // Map<String, dynamic>? _currentDriver; // Placeholder until Driver class is implemented
  // TODO: Use _uploadedPhotoUrl when image upload is restored
  // String? _uploadedPhotoUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleTypeController.dispose();
    _vehicleModelController.dispose();
    _licensePlateController.dispose();
    _vehicleBrandController.dispose();
    _vehicleColorController.dispose();
    _vehicleYearController.dispose();
    super.dispose();
  }

  // TODO: Restore when Driver class is implemented
  // TODO: Restore unused element - commented out for analyzer cleanup
  /*
  void _loadDriverProfile(Map<String, dynamic>? driver) {
    if (driver == null) return;

    // TODO: Restore when _currentDriver is available
    // _currentDriver = driver;
    // TODO: Restore when driver.name is implemented
    _nameController.text = ''; // driver.name;
    // TODO: Restore when driver.phoneNumber is implemented
    _phoneController.text = ''; // driver.phoneNumber;
    // TODO: Restore when driver.vehicleDetails is implemented
    _vehicleTypeController.text = ''; // driver.vehicleDetails.type;
    _vehicleModelController.text = ''; // driver.vehicleDetails.model ?? '';
    _licensePlateController.text = ''; // driver.vehicleDetails.plateNumber;
    _vehicleBrandController.text = ''; // driver.vehicleDetails.brand ?? '';
    _vehicleColorController.text = ''; // driver.vehicleDetails.color ?? '';
    _vehicleYearController.text = ''; // driver.vehicleDetails.year ?? '';
  }
  */



  @override
  Widget build(BuildContext context) {
    // TODO: Use theme when styling is restored
    // final theme = Theme.of(context);
    // TODO: Restore when authStateProvider is implemented
    // final authState = ref.watch(authStateProvider);
    // TODO: Restore when driverProfileStreamProvider is implemented
    // final driverProfileAsync = ref.watch(driverProfileStreamProvider);
    // TODO: Restore when profileEditingProvider is implemented
    // final isEditing = ref.watch(profileEditingProvider);
    // TODO: Restore when driverProfileLoadingProvider is implemented
    // final isLoading = ref.watch(driverProfileLoadingProvider);
    // TODO: Restore when driverProfileErrorProvider is implemented
    // final error = ref.watch(driverProfileErrorProvider);

    // Placeholders
    final authState = <String, dynamic>{};
    final driverProfileAsync = <String, dynamic>{};
    final isEditing = false;
    // TODO: Restore unused variable - commented out for analyzer cleanup
    // final isLoading = false;
    // TODO: Use error when error handling is restored
    // final error = null;

    // Debug logging for authentication state
    debugPrint('🚗 DriverProfileScreen: Build called');
    debugPrint('🚗 Auth Status: ${authState['status']}');
    debugPrint('🚗 User: ${authState['user']?['email']} (ID: ${authState['user']?['id']})');
    debugPrint('🚗 User Role: ${authState['user']?['role']}');
    debugPrint('🚗 Driver Profile Async State: ${driverProfileAsync.runtimeType}');

    // Check if user is a driver
    if (authState['user']?['role'] != 'driver') { // UserRole.driver) {
      debugPrint('🚗 Access denied - User role is not driver: ${authState['user']?['role']}');
      return Scaffold(
        appBar: AppBar(title: const Text('Driver Profile')),
        body: const Center(
          child: Text('Access denied. Driver role required.'),
        ),
      );
    }

    debugPrint('🚗 User is driver, proceeding with profile screen');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Profile'),
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO: Restore when profileEditingProvider is implemented
                // ref.read(profileEditingProvider.notifier).state = true;
              },
            ),
          // TODO: Restore dead code - commented out for analyzer cleanup
          // TODO: Restore dead code - commented out for analyzer cleanup
          // if (isEditing)
          // TODO: Restore dead code - commented out for analyzer cleanup
          // if (false)
          //   TextButton(
          //     // TODO: Restore when _saveProfile is implemented
          //     // onPressed: isLoading ? null : _saveProfile,
          //     onPressed: null, // Placeholder
          //     style: TextButton.styleFrom(
          //       foregroundColor: Colors.white,
          //       backgroundColor: Colors.transparent,
          //     ),
          //     child: isLoading
          //       ? const SizedBox(
          //           width: 16,
          //           height: 16,
          //           child: CircularProgressIndicator(
          //             strokeWidth: 2,
          //             valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          //           ),
          //         )
          //       : const Text(
          //           'Save',
          //           style: TextStyle(
          //             fontWeight: FontWeight.w600,
          //             color: Colors.white,
          //           ),
          //         ),
          //   ),
        ],
      ),
      // TODO: Restore when driverProfileAsync.when is implemented
      body: const Center(child: Text('Driver profile not available')),
    );
      /* TODO: Restore when driverProfileAsync.when is implemented
      body: driverProfileAsync.when(
        data: (driver) {
          debugPrint('🚗 DriverProfileScreen: Data received - driver: ${driver?.name ?? 'null'}');

          if (driver == null) {
            debugPrint('🚗 DriverProfileScreen: Driver is null, showing not found message');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, color: Colors.grey, size: 64),
                  const SizedBox(height: 16),
                  const Text('Driver profile not found. Please contact support.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      debugPrint('🚗 DriverProfileScreen: Retry button pressed');
                      ref.invalidate(driverProfileStreamProvider);
                    },
                    child: const Text('Retry'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _createDriverProfile(),
                    child: const Text('Create Driver Profile'),
                  ),
                  const SizedBox(height: 16),
                  // Add logout button for users stuck in driver interface
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          debugPrint('🚗 DriverProfileScreen: Driver found: ${driver.name} (${driver.id})');

          // Load profile data when driver data is available
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadDriverProfile(driver);
          });

          return _buildProfileContent(theme, driver, isEditing, error);
        },
        loading: () {
          debugPrint('🚗 DriverProfileScreen: Loading state');
          return const Center(child: LoadingWidget());
        },
        error: (error, stack) {
          debugPrint('🚗 DriverProfileScreen: Error state: $error');
          debugPrint('🚗 DriverProfileScreen: Stack trace: $stack');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text('Failed to load driver profile'),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    debugPrint('🚗 DriverProfileScreen: Error retry button pressed');
                    ref.invalidate(driverProfileStreamProvider);
                  },
                  child: const Text('Retry'),
                ),
                const SizedBox(height: 16),
                // Add logout button for users stuck in driver interface
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileContent(ThemeData theme, Driver driver, bool isEditing, String? error) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error message
            if (error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        ref.read(driverProfileErrorProvider.notifier).state = null;
                      },
                    ),
                  ],
                ),
              ),

            // Profile Header
            _buildProfileHeader(theme, driver, isEditing),

            const SizedBox(height: 32),

            // Personal Information Section
            _buildPersonalInfoSection(theme, isEditing),

            const SizedBox(height: 24),

            // Vehicle Information Section
            _buildVehicleInfoSection(theme, isEditing),

            const SizedBox(height: 24),

            // Performance Stats Section
            _buildPerformanceSection(theme),

            const SizedBox(height: 24),

            // Settings Section
            _buildSettingsSection(theme),

            const SizedBox(height: 32),

            // Logout Button
            _buildLogoutButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, Driver driver, bool isEditing) {
    final authState = ref.watch(authStateProvider);

    return Center(
      child: Column(
        children: [
          ProfileImagePicker(
            onImageSelected: (file) {
              // TODO: Restore when image selection logic is implemented
              debugPrint('🖼️ Driver profile image selected: ${file?.path}');
            },
            // TODO: Restore when currentImageUrl parameter is implemented
            // currentImageUrl: _uploadedPhotoUrl ?? driver.profilePhotoUrl,
            // TODO: Restore when userId parameter is implemented
            // userId: authState.user?.id ?? '',
            size: 100,
            // TODO: Restore when isEditable parameter is implemented
            // isEditable: isEditing,
            // TODO: Restore when onImageUploaded parameter is implemented
            /*onImageUploaded: (imageUrl) {
              setState(() {
                _uploadedPhotoUrl = imageUrl;
              });
            },*/
          ),
          const SizedBox(height: 16),
          Text(
            driver.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(driver.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getStatusColor(driver.status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  driver.status.displayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getStatusColor(driver.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(DriverStatus status) {
    switch (status) {
      case DriverStatus.online:
        return Colors.green;
      case DriverStatus.onDelivery:
        return Colors.blue;
      case DriverStatus.offline:
        return Colors.grey;
    }
  }

  Widget _buildPersonalInfoSection(ThemeData theme, bool isEditing) {
    return _buildSection(
      theme,
      title: 'Personal Information',
      children: [
        _buildFormField(
          controller: _nameController,
          label: 'Full Name',
          icon: Icons.person,
          enabled: isEditing,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your full name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: Icons.phone,
          enabled: isEditing,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildVehicleInfoSection(ThemeData theme, bool isEditing) {
    return _buildSection(
      theme,
      title: 'Vehicle Information',
      children: [
        _buildFormField(
          controller: _vehicleTypeController,
          label: 'Vehicle Type',
          icon: Icons.two_wheeler,
          enabled: isEditing,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter vehicle type';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _vehicleModelController,
          label: 'Vehicle Model',
          icon: Icons.directions_car,
          enabled: isEditing,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter vehicle model';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _licensePlateController,
          label: 'License Plate',
          icon: Icons.confirmation_number,
          enabled: isEditing,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter license plate';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _vehicleBrandController,
          label: 'Vehicle Brand',
          icon: Icons.branding_watermark,
          enabled: isEditing,
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _vehicleColorController,
          label: 'Vehicle Color',
          icon: Icons.color_lens,
          enabled: isEditing,
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _vehicleYearController,
          label: 'Vehicle Year',
          icon: Icons.calendar_today,
          enabled: isEditing,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildPerformanceSection(ThemeData theme) {
    final performanceStatsAsync = ref.watch(driverPerformanceStatsProvider);

    return _buildSection(
      theme,
      title: 'Performance Stats',
      children: [
        performanceStatsAsync.when(
          data: (stats) => Column(
            children: [
              // First row: Total Deliveries and Rating
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      theme,
                      title: 'Total Deliveries',
                      value: '${stats.totalDeliveries}',
                      icon: Icons.local_shipping,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      theme,
                      title: 'Rating',
                      value: stats.customerRating.toStringAsFixed(1),
                      icon: Icons.star,
                      subtitle: '${stats.totalRatings} reviews',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Second row: On-Time Rate and Average Delivery Time
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      theme,
                      title: 'On-Time Rate',
                      value: '${stats.onTimeDeliveryRate.round()}%',
                      icon: Icons.timer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      theme,
                      title: 'Avg Delivery Time',
                      value: stats.formattedAverageDeliveryTime,
                      icon: Icons.access_time,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Third row: Distance Traveled and Monthly Earnings
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      theme,
                      title: 'Distance Traveled',
                      value: stats.formattedDistance,
                      icon: Icons.route,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      theme,
                      title: 'This Month',
                      value: 'RM ${stats.totalEarningsMonth.toStringAsFixed(0)}',
                      icon: Icons.account_balance_wallet,
                      subtitle: '${stats.deliveriesMonth} deliveries',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Fourth row: Today's Stats and Weekly Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      theme,
                      title: 'Today',
                      value: 'RM ${stats.totalEarningsToday.toStringAsFixed(0)}',
                      icon: Icons.today,
                      subtitle: '${stats.deliveriesToday} deliveries',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      theme,
                      title: 'This Week',
                      value: 'RM ${stats.totalEarningsWeek.toStringAsFixed(0)}',
                      icon: Icons.date_range,
                      subtitle: '${stats.deliveriesWeek} deliveries',
                    ),
                  ),
                ],
              ),
              if (stats.averageEarningsPerDelivery > 0) ...[
                const SizedBox(height: 12),
                // Fifth row: Average Earnings Per Delivery
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        theme,
                        title: 'Avg Per Delivery',
                        value: 'RM ${stats.averageEarningsPerDelivery.toStringAsFixed(2)}',
                        icon: Icons.monetization_on,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        theme,
                        title: 'Success Rate',
                        value: '${stats.successRatePercentage.toStringAsFixed(1)}%',
                        icon: Icons.check_circle,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Last updated: ${_formatLastUpdated(stats.lastUpdated)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => _buildErrorPerformanceStats(theme),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(ThemeData theme) {
    return _buildSection(
      theme,
      title: 'Settings',
      children: [
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notifications'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            debugPrint('🚗 Opening notification settings');
            context.push('/driver/notification-settings');
          },
        ),
        ListTile(
          leading: const Icon(Icons.security),
          title: const Text('Privacy & Security'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            debugPrint('🚗 Opening privacy settings');
          },
        ),
        ListTile(
          leading: const Icon(Icons.help),
          title: const Text('Help & Support'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            debugPrint('🚗 Opening help & support');
          },
        ),
      ],
    );
  }

  Widget _buildSection(
    ThemeData theme, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: !enabled,
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme, {
    required String title,
    required String value,
    required IconData icon,
    String? subtitle,
  }) {
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
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text(
          'Logout',
          style: TextStyle(color: Colors.red),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentDriver == null) {
      _showError('Driver profile not found');
      return;
    }

    try {
      // Set loading state
      ref.read(driverProfileLoadingProvider.notifier).state = true;
      ref.read(driverProfileErrorProvider.notifier).state = null;

      final actions = ref.read(driverProfileActionsProvider);

      // Create updated vehicle details
      final updatedVehicleDetails = _currentDriver!.vehicleDetails.copyWith(
        type: _vehicleTypeController.text.trim(),
        plateNumber: _licensePlateController.text.trim(),
        model: _vehicleModelController.text.trim().isEmpty
          ? null
          : _vehicleModelController.text.trim(),
        brand: _vehicleBrandController.text.trim().isEmpty
          ? null
          : _vehicleBrandController.text.trim(),
        color: _vehicleColorController.text.trim().isEmpty
          ? null
          : _vehicleColorController.text.trim(),
        year: _vehicleYearController.text.trim().isEmpty
          ? null
          : _vehicleYearController.text.trim(),
      );

      // Update profile
      final success = await actions.updateProfile(
        driverId: _currentDriver!.id,
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        vehicleDetails: updatedVehicleDetails,
      );

      if (success) {
        // Update profile photo if changed
        if (_uploadedPhotoUrl != null && _uploadedPhotoUrl != _currentDriver!.profilePhotoUrl) {
          await actions.updateProfile(
            driverId: _currentDriver!.id,
            // Only update photo URL, other fields remain unchanged
          );
        }

        ref.read(profileEditingProvider.notifier).state = false;
        _showSuccess('Profile updated successfully');
      } else {
        _showError('Failed to update profile. Please try again.');
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      _showError('Failed to update profile: $e');
    } finally {
      ref.read(driverProfileLoadingProvider.notifier).state = false;
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ref.read(driverProfileErrorProvider.notifier).state = message;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _createDriverProfile() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      _showError('User not authenticated');
      return;
    }

    debugPrint('🚗 Creating driver profile for user: $userId');

    try {
      // For now, show a dialog to explain that this would create a driver profile
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Create Driver Profile'),
          content: Text(
            'This would create a driver profile for user: $userId\n\n'
            'In a production app, this would:\n'
            '• Create a driver record in the database\n'
            '• Set up default vehicle details\n'
            '• Initialize driver status\n\n'
            'For now, please contact an administrator to set up your driver profile.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('🚗 Error creating driver profile: $e');
      _showError('Failed to create driver profile: $e');
    }
  }

  void _logout() {
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
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await AuthUtils.logout(context, ref);
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// Build error state for performance stats
  Widget _buildErrorPerformanceStats(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                theme,
                title: 'Total Deliveries',
                value: '0',
                icon: Icons.local_shipping,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                theme,
                title: 'Rating',
                value: '0.0',
                icon: Icons.star,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                theme,
                title: 'On-Time Rate',
                value: '0%',
                icon: Icons.timer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                theme,
                title: 'This Month',
                value: 'RM 0',
                icon: Icons.account_balance_wallet,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Unable to load performance data',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            ref.invalidate(driverPerformanceStatsProvider);
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    );
  }

  /// Format last updated timestamp
  String _formatLastUpdated(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
  */
  }
}
