// TODO: Restore when dart:async is used
// import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
// TODO: Restore when go_router is used
// import 'package:go_router/go_router.dart';

// UserRole import for role checking
import '../../../../data/models/user_role.dart';
// TODO: Restore when loading_widget is used
// import '../../../../shared/widgets/loading_widget.dart';
// TODO: Restore when profile_image_picker is used
// import '../../../../shared/widgets/profile_image_picker.dart';
// Enhanced auth provider for accessing user role
import '../../../../auth/presentation/providers/enhanced_auth_provider.dart';
// Auth provider and utils
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/auth_utils.dart';
// Driver domain and provider imports
import '../../../domain/driver.dart';
import '../../providers/driver_profile_provider.dart';
// Camera permission service
import '../../../../../core/services/camera_permission_service.dart';
// Validation utilities
import '../../../../../core/utils/profile_validators.dart';

/// Driver profile screen with personal info and vehicle details
class DriverProfileScreen extends ConsumerStatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  ConsumerState<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends ConsumerState<DriverProfileScreen> {
  final _formKey = GlobalKey<FormState>();

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

  void _loadDriverProfile(Driver driver) {
    debugPrint('🚗 Loading driver profile data into form controllers');
    debugPrint('🚗 Driver: ${driver.name} (${driver.id})');

    _nameController.text = driver.name;
    _phoneController.text = driver.phoneNumber;
    _vehicleTypeController.text = driver.vehicleDetails.type;
    _vehicleModelController.text = driver.vehicleDetails.model ?? '';
    _licensePlateController.text = driver.vehicleDetails.plateNumber;
    _vehicleBrandController.text = driver.vehicleDetails.brand ?? '';
    _vehicleColorController.text = driver.vehicleDetails.color ?? '';
    _vehicleYearController.text = driver.vehicleDetails.year?.toString() ?? '';

    debugPrint('🚗 Form controllers loaded successfully');
  }



  /// Validate form fields before saving
  bool _validateForm() {
    debugPrint('🔍 [FORM-VALIDATION] ===== VALIDATING FORM FIELDS =====');

    // Validate form using GlobalKey
    if (!_formKey.currentState!.validate()) {
      debugPrint('🔍 [FORM-VALIDATION] ❌ Form validation failed');
      return false;
    }

    // Additional validation using ProfileValidators
    final nameError = ProfileValidators.validateFullName(_nameController.text);
    if (nameError != null) {
      debugPrint('🔍 [FORM-VALIDATION] ❌ Name validation failed: $nameError');
      _showError(nameError);
      return false;
    }

    final phoneError = ProfileValidators.validateMalaysianPhoneNumber(_phoneController.text);
    if (phoneError != null) {
      debugPrint('🔍 [FORM-VALIDATION] ❌ Phone validation failed: $phoneError');
      _showError(phoneError);
      return false;
    }

    // Validate required vehicle fields
    if (_vehicleTypeController.text.trim().isEmpty) {
      debugPrint('🔍 [FORM-VALIDATION] ❌ Vehicle type is required');
      _showError('Vehicle type is required');
      return false;
    }

    if (_licensePlateController.text.trim().isEmpty) {
      debugPrint('🔍 [FORM-VALIDATION] ❌ License plate is required');
      _showError('License plate number is required');
      return false;
    }

    // Validate vehicle year if provided
    final yearText = _vehicleYearController.text.trim();
    if (yearText.isNotEmpty) {
      final year = int.tryParse(yearText);
      if (year == null || year < 1900 || year > DateTime.now().year + 1) {
        debugPrint('🔍 [FORM-VALIDATION] ❌ Invalid vehicle year: $yearText');
        _showError('Please enter a valid vehicle year');
        return false;
      }
    }

    debugPrint('🔍 [FORM-VALIDATION] ✅ All validations passed');
    return true;
  }

  /// Collect form data and build VehicleDetails object
  VehicleDetails _collectVehicleDetails() {
    debugPrint('🔍 [DATA-COLLECTION] ===== COLLECTING VEHICLE DETAILS =====');

    final vehicleDetails = VehicleDetails(
      type: _vehicleTypeController.text.trim(),
      plateNumber: _licensePlateController.text.trim(),
      brand: _vehicleBrandController.text.trim().isEmpty ? null : _vehicleBrandController.text.trim(),
      model: _vehicleModelController.text.trim().isEmpty ? null : _vehicleModelController.text.trim(),
      color: _vehicleColorController.text.trim().isEmpty ? null : _vehicleColorController.text.trim(),
      year: _vehicleYearController.text.trim().isEmpty ? null : _vehicleYearController.text.trim(),
    );

    debugPrint('🔍 [DATA-COLLECTION] Vehicle details collected:');
    debugPrint('🔍 [DATA-COLLECTION] - Type: ${vehicleDetails.type}');
    debugPrint('🔍 [DATA-COLLECTION] - Plate: ${vehicleDetails.plateNumber}');
    debugPrint('🔍 [DATA-COLLECTION] - Brand: ${vehicleDetails.brand}');
    debugPrint('🔍 [DATA-COLLECTION] - Model: ${vehicleDetails.model}');
    debugPrint('🔍 [DATA-COLLECTION] - Color: ${vehicleDetails.color}');
    debugPrint('🔍 [DATA-COLLECTION] - Year: ${vehicleDetails.year}');

    return vehicleDetails;
  }

  /// Save profile changes to database
  Future<void> _saveProfile() async {
    debugPrint('💾 [SAVE-PROFILE] ===== STARTING PROFILE SAVE =====');

    // Validate form first
    if (!_validateForm()) {
      debugPrint('💾 [SAVE-PROFILE] ❌ Validation failed, aborting save');
      return;
    }

    // Get current driver data
    final driverProfileAsync = ref.read(driverProfileStreamProvider);
    final driver = driverProfileAsync.value;

    if (driver == null) {
      debugPrint('💾 [SAVE-PROFILE] ❌ No driver data available');
      _showError('Driver profile not found. Please try again.');
      return;
    }

    try {
      // Set loading state
      ref.read(driverProfileLoadingProvider.notifier).state = true;
      debugPrint('💾 [SAVE-PROFILE] Loading state enabled');

      // Collect form data
      final name = _nameController.text.trim();
      final phoneNumber = _phoneController.text.trim();
      final vehicleDetails = _collectVehicleDetails();

      debugPrint('💾 [SAVE-PROFILE] Collected data:');
      debugPrint('💾 [SAVE-PROFILE] - Driver ID: ${driver.id}');
      debugPrint('💾 [SAVE-PROFILE] - Name: $name');
      debugPrint('💾 [SAVE-PROFILE] - Phone: $phoneNumber');

      // Call backend API
      final driverProfileActions = ref.read(driverProfileActionsProvider);
      final success = await driverProfileActions.updateProfile(
        driverId: driver.id,
        name: name,
        phoneNumber: phoneNumber,
        vehicleDetails: vehicleDetails,
      );

      if (success) {
        debugPrint('💾 [SAVE-PROFILE] ✅ Profile updated successfully');

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }

        // Exit edit mode
        ref.read(profileEditingProvider.notifier).state = false;
        debugPrint('💾 [SAVE-PROFILE] Edit mode disabled after successful save');

        // Refresh profile data
        ref.invalidate(driverProfileStreamProvider);
        debugPrint('💾 [SAVE-PROFILE] Profile stream invalidated for refresh');

      } else {
        debugPrint('💾 [SAVE-PROFILE] ❌ Profile update failed');
        _showError('Failed to update profile. Please try again.');
      }

    } catch (e) {
      debugPrint('💾 [SAVE-PROFILE] ❌ Error during save: $e');
      _showError('Error updating profile: $e');
    } finally {
      // Clear loading state
      if (mounted) {
        ref.read(driverProfileLoadingProvider.notifier).state = false;
        debugPrint('💾 [SAVE-PROFILE] Loading state disabled');
      }
    }
  }



  /// Toggle driver status between online and offline
  Future<void> _toggleDriverStatus(Driver driver) async {
    debugPrint('🚦 [STATUS-TOGGLE] ===== TOGGLING DRIVER STATUS =====');
    debugPrint('🚦 [STATUS-TOGGLE] Current status: ${driver.status}');
    debugPrint('🚦 [STATUS-TOGGLE] Driver ID: ${driver.id}');

    // Determine new status
    final newStatus = driver.status == DriverStatus.online ? 'offline' : 'online';
    debugPrint('🚦 [STATUS-TOGGLE] New status will be: $newStatus');

    try {
      // Set loading state
      ref.read(driverProfileLoadingProvider.notifier).state = true;
      debugPrint('🚦 [STATUS-TOGGLE] Loading state enabled');

      // Update status using driver profile actions
      final driverProfileActions = ref.read(driverProfileActionsProvider);
      final success = await driverProfileActions.updateStatus(
        driverId: driver.id,
        status: newStatus,
      );

      if (success) {
        debugPrint('🚦 [STATUS-TOGGLE] Status updated successfully to: $newStatus');

        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status changed to ${newStatus.toUpperCase()}'),
              backgroundColor: newStatus == 'online' ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Refresh the driver profile to get updated status
        ref.invalidate(driverProfileStreamProvider);
        debugPrint('🚦 [STATUS-TOGGLE] Driver profile stream invalidated for refresh');
      } else {
        debugPrint('🚦 [STATUS-TOGGLE] Failed to update status');
        _showError('Failed to update status. Please try again.');
      }
    } catch (e) {
      debugPrint('🚦 [STATUS-TOGGLE] Error updating status: $e');
      _showError('Error updating status: $e');
    } finally {
      // Clear loading state
      if (mounted) {
        ref.read(driverProfileLoadingProvider.notifier).state = false;
        debugPrint('🚦 [STATUS-TOGGLE] Loading state disabled');
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 [PROFILE-SCREEN] ===== BUILD METHOD CALLED =====');
    debugPrint('🎨 [PROFILE-SCREEN] Timestamp: ${DateTime.now()}');
    debugPrint('🎨 [PROFILE-SCREEN] Context: ${context.runtimeType}');

    // TODO: Use theme when styling is restored
    // final theme = Theme.of(context);
    // TODO: Restore when authStateProvider is implemented
    // final authState = ref.watch(authStateProvider);
    // Restore real driver profile providers
    final driverProfileAsync = ref.watch(driverProfileStreamProvider);
    final isEditing = ref.watch(profileEditingProvider);
    final isLoading = ref.watch(driverProfileLoadingProvider);
    final error = ref.watch(driverProfileErrorProvider);

    // Get theme for debug logging
    final theme = Theme.of(context);
    debugPrint('🎨 [PROFILE-SCREEN] Theme primary color: ${theme.colorScheme.primary}');
    debugPrint('🎨 [PROFILE-SCREEN] Theme surface color: ${theme.colorScheme.surface}');

    // Get auth state from enhanced provider
    final authState = ref.watch(enhancedAuthStateProvider);

    // Enhanced debug logging for authentication state
    debugPrint('🎨 [PROFILE-SCREEN] ===== AUTHENTICATION & STATE =====');
    debugPrint('🚗 DriverProfileScreen: Build called');
    debugPrint('🚗 Auth Status: ${authState.status}');
    debugPrint('🚗 User: ${authState.user?.email} (ID: ${authState.user?.id})');
    debugPrint('🚗 User Role: ${authState.user?.role}');
    debugPrint('🚗 Is Authenticated: ${authState.isAuthenticated}');
    debugPrint('🚗 Driver Profile Async State: ${driverProfileAsync.runtimeType}');
    debugPrint('🎨 [PROFILE-SCREEN] Edit mode active: $isEditing');
    debugPrint('🎨 [PROFILE-SCREEN] profileEditingProvider state: ${ref.read(profileEditingProvider)}');
    debugPrint('🎨 [PROFILE-SCREEN] UI will show edit button: ${!isEditing}');
    debugPrint('🎨 [PROFILE-SCREEN] UI will show save/cancel buttons: $isEditing');

    // Debug auth state details
    debugPrint('🔍 [AUTH-DEBUG] Full auth state: $authState');
    debugPrint('🔍 [AUTH-DEBUG] User object: ${authState.user}');
    debugPrint('🔍 [AUTH-DEBUG] User role: ${authState.user?.role}');
    debugPrint('🔍 [AUTH-DEBUG] User role type: ${authState.user?.role.runtimeType}');

    // TEMPORARY: Disable auth checks for testing debug logging
    debugPrint('🚗 [TEMP] Bypassing auth checks for debug testing');
    debugPrint('🚗 [TEMP] Auth state: ${authState.isAuthenticated}');
    debugPrint('🚗 [TEMP] User role: ${authState.user?.role}');

    /*
    // Check if user is authenticated first
    if (!authState.isAuthenticated) {
      debugPrint('🚗 Access denied - User not authenticated (status: ${authState.status})');
      return Scaffold(
        appBar: AppBar(title: const Text('Driver Profile')),
        body: const Center(
          child: Text('Please log in to access driver profile.'),
        ),
      );
    }

    // Check if user is a driver
    final userRole = authState.user!.role;
    final isDriver = userRole == UserRole.driver;

    if (!isDriver) {
      debugPrint('🚗 Access denied - User role is not driver: $userRole');
      return Scaffold(
        appBar: AppBar(title: const Text('Driver Profile')),
        body: const Center(
          child: Text('Access denied. Driver role required.'),
        ),
      );
    }
    */

    debugPrint('🚗 User is driver, proceeding with profile screen');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Profile'),
        actions: [

          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                debugPrint('🎨 [EDIT-MODE] ===== EDIT BUTTON TAPPED =====');
                debugPrint('🎨 [EDIT-MODE] Current isEditing state: $isEditing');
                debugPrint('🎨 [EDIT-MODE] About to set profileEditingProvider to true');

                try {
                  ref.read(profileEditingProvider.notifier).state = true;
                  debugPrint('🎨 [EDIT-MODE] ✅ Successfully set profileEditingProvider to true');

                  // Verify the state was actually set
                  final newState = ref.read(profileEditingProvider);
                  debugPrint('🎨 [EDIT-MODE] Verification - New state is: $newState');

                  if (newState) {
                    debugPrint('🎨 [EDIT-MODE] ✅ Edit mode enabled successfully');
                  } else {
                    debugPrint('🎨 [EDIT-MODE] ❌ Edit mode failed to enable - state is still false');
                  }
                } catch (e) {
                  debugPrint('🎨 [EDIT-MODE] ❌ Error setting edit mode: $e');
                }
              },
            ),
          if (isEditing) ...[
            TextButton(
              onPressed: isLoading ? null : _saveProfile,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.transparent,
              ),
              child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
            ),
            TextButton(
              onPressed: () {
                debugPrint('🎨 [EDIT-MODE] ===== CANCELLING EDIT MODE =====');
                ref.read(profileEditingProvider.notifier).state = false;
                debugPrint('🎨 [EDIT-MODE] Edit mode cancelled successfully');
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.transparent,
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
      // Enhanced profile header with real driver data
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
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading driver profile...'),
              ],
            ),
          );
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
              ],
            ),
          );
        },
      ),
    );
  }

  // TODO: Restore when driverProfileAsync.when is implemented
  /*
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
  */

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
    final authState = ref.watch(enhancedAuthStateProvider);

    debugPrint('🎨 [ENHANCED-HEADER] ===== BUILDING PROFILE HEADER =====');
    debugPrint('🎨 [ENHANCED-HEADER] Driver ID: ${driver.id}');
    debugPrint('🎨 [ENHANCED-HEADER] Driver Name: ${driver.name}');
    debugPrint('🎨 [ENHANCED-HEADER] Driver Phone: ${driver.phoneNumber}');
    debugPrint('🎨 [ENHANCED-HEADER] Driver Status: ${driver.status}');
    debugPrint('🎨 [ENHANCED-HEADER] Driver Active: ${driver.isActive}');
    debugPrint('🎨 [ENHANCED-HEADER] Profile Photo URL: ${driver.profilePhotoUrl ?? "NULL"}');
    debugPrint('🎨 [ENHANCED-HEADER] Edit mode: $isEditing');
    debugPrint('🎨 [ENHANCED-HEADER] Auth user ID: ${authState.user?.id ?? "NULL"}');
    debugPrint('🎨 [ENHANCED-HEADER] Vehicle details: ${driver.vehicleDetails.plateNumber}');
    debugPrint('🎨 [ENHANCED-HEADER] Created at: ${driver.createdAt}');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.surface,
          ],
          stops: const [0.0, 0.7],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          children: [
            // Enhanced Profile Image with Upload Progress
            _buildEnhancedProfileImage(theme, driver, isEditing, authState),

            const SizedBox(height: 20),

            // Driver Name with Typography Hierarchy
            Text(
              driver.name,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Driver ID/Email
            Text(
              driver.phoneNumber,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Status and Rating Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Enhanced Status Indicator
                _buildEnhancedStatusIndicator(theme, driver),

                const SizedBox(width: 24),

                // Rating Display (if available)
                _buildRatingDisplay(theme, driver),
              ],
            ),

            const SizedBox(height: 16),

            // Verification Badges
            _buildVerificationBadges(theme, driver),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedProfileImage(ThemeData theme, Driver driver, bool isEditing, EnhancedAuthState authState) {
    debugPrint('🖼️ [PROFILE-IMAGE] ===== BUILDING ENHANCED PROFILE IMAGE =====');
    debugPrint('🖼️ [PROFILE-IMAGE] Has profile photo: ${driver.profilePhotoUrl != null && driver.profilePhotoUrl!.isNotEmpty}');
    debugPrint('🖼️ [PROFILE-IMAGE] Photo URL: ${driver.profilePhotoUrl ?? "NULL"}');
    debugPrint('🖼️ [PROFILE-IMAGE] Edit mode: $isEditing');
    debugPrint('🖼️ [PROFILE-IMAGE] Theme primary: ${theme.colorScheme.primary}');

    return Stack(
      children: [
        // Profile Image Container with Border
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: driver.profilePhotoUrl != null && driver.profilePhotoUrl!.isNotEmpty
                ? Image.network(
                    driver.profilePhotoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildProfilePlaceholder(theme),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildImageLoadingIndicator(theme, loadingProgress);
                    },
                  )
                : _buildProfilePlaceholder(theme),
          ),
        ),

        // Edit Button (when in edit mode)
        if (isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _showImagePickerOptions(authState),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: theme.colorScheme.onPrimary,
                  size: 18,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfilePlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.person,
        size: 60,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildImageLoadingIndicator(ThemeData theme, ImageChunkEvent loadingProgress) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
              : null,
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildEnhancedStatusIndicator(ThemeData theme, Driver driver) {
    final statusColor = _getStatusColor(driver.status);
    final statusIcon = _getStatusIcon(driver.status);
    final isLoading = ref.watch(driverProfileLoadingProvider);

    debugPrint('🚦 [STATUS-INDICATOR] ===== BUILDING STATUS INDICATOR =====');
    debugPrint('🚦 [STATUS-INDICATOR] Driver status: ${driver.status}');
    debugPrint('🚦 [STATUS-INDICATOR] Status display name: ${driver.status.displayName}');
    debugPrint('🚦 [STATUS-INDICATOR] Status color: $statusColor');
    debugPrint('🚦 [STATUS-INDICATOR] Status icon: $statusIcon');
    debugPrint('🚦 [STATUS-INDICATOR] Is loading: $isLoading');

    return InkWell(
      onTap: isLoading ? null : () => _toggleDriverStatus(driver),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              )
            else
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              statusIcon,
              size: 16,
              color: statusColor,
            ),
            const SizedBox(width: 6),
            Text(
              driver.status.displayName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.touch_app,
              size: 12,
              color: statusColor.withValues(alpha: 0.6),
            ),
          ],
        ),
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

  IconData _getStatusIcon(DriverStatus status) {
    switch (status) {
      case DriverStatus.online:
        return Icons.check_circle;
      case DriverStatus.onDelivery:
        return Icons.local_shipping;
      case DriverStatus.offline:
        return Icons.cancel;
    }
  }

  Widget _buildRatingDisplay(ThemeData theme, Driver driver) {
    // For now, we'll use a placeholder rating since the current Driver model doesn't have rating
    // This will be connected to actual rating data in future iterations
    const double rating = 4.8; // Placeholder
    const int totalRatings = 127; // Placeholder

    debugPrint('⭐ [RATING-DISPLAY] ===== BUILDING RATING DISPLAY =====');
    debugPrint('⭐ [RATING-DISPLAY] Driver ID: ${driver.id}');
    debugPrint('⭐ [RATING-DISPLAY] Placeholder rating: $rating');
    debugPrint('⭐ [RATING-DISPLAY] Placeholder total ratings: $totalRatings');
    debugPrint('⭐ [RATING-DISPLAY] Theme amber color available: ${Colors.amber}');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: 16,
            color: Colors.amber,
          ),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '($totalRatings)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBadges(ThemeData theme, Driver driver) {
    debugPrint('🏆 [VERIFICATION-BADGES] ===== BUILDING VERIFICATION BADGES =====');
    debugPrint('🏆 [VERIFICATION-BADGES] Driver ID: ${driver.id}');
    debugPrint('🏆 [VERIFICATION-BADGES] Driver active: ${driver.isActive}');
    debugPrint('🏆 [VERIFICATION-BADGES] Vehicle plate: ${driver.vehicleDetails.plateNumber}');
    debugPrint('🏆 [VERIFICATION-BADGES] Created at: ${driver.createdAt}');

    final badges = <Widget>[];

    // Active Status Badge
    if (driver.isActive) {
      debugPrint('🏆 [VERIFICATION-BADGES] Adding Verified badge (driver is active)');
      badges.add(_buildBadge(
        theme,
        icon: Icons.verified,
        label: 'Verified',
        color: Colors.green,
      ));
    }

    // Vehicle Verified Badge (placeholder logic)
    if (driver.vehicleDetails.plateNumber.isNotEmpty) {
      debugPrint('🏆 [VERIFICATION-BADGES] Adding Vehicle Verified badge (plate: ${driver.vehicleDetails.plateNumber})');
      badges.add(_buildBadge(
        theme,
        icon: Icons.directions_car,
        label: 'Vehicle Verified',
        color: Colors.blue,
      ));
    }

    // Experience Badge (placeholder logic based on creation date)
    final daysSinceJoined = DateTime.now().difference(driver.createdAt).inDays;
    debugPrint('🏆 [VERIFICATION-BADGES] Days since joined: $daysSinceJoined');
    if (daysSinceJoined > 30) {
      debugPrint('🏆 [VERIFICATION-BADGES] Adding Experienced badge (${daysSinceJoined} days)');
      badges.add(_buildBadge(
        theme,
        icon: Icons.workspace_premium,
        label: 'Experienced',
        color: Colors.purple,
      ));
    }

    debugPrint('🏆 [VERIFICATION-BADGES] Total badges generated: ${badges.length}');

    if (badges.isEmpty) {
      debugPrint('🏆 [VERIFICATION-BADGES] No badges to display');
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: badges,
    );
  }

  Widget _buildBadge(ThemeData theme, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    debugPrint('🏆 [BADGE] Creating badge: $label (color: $color, icon: $icon)');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePickerOptions(EnhancedAuthState authState) {
    debugPrint('📷 [IMAGE-PICKER] ===== SHOWING IMAGE PICKER MODAL =====');
    debugPrint('📷 [IMAGE-PICKER] Auth state: ${authState.user?.id}');
    debugPrint('📷 [IMAGE-PICKER] Context available: ${context.mounted}');

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Update Profile Photo',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.blue),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  debugPrint('📷 [IMAGE-PICKER] Gallery option tapped');
                  Navigator.pop(context);
                  _pickImageFromGallery(authState);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_camera, color: Colors.green),
                ),
                title: const Text('Take Photo'),
                onTap: () {
                  debugPrint('📷 [IMAGE-PICKER] Camera option tapped');
                  Navigator.pop(context);
                  _pickImageFromCamera(authState);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery(EnhancedAuthState authState) async {
    debugPrint('🖼️ [GALLERY-PICKER] ===== GALLERY PICKER CALLED =====');
    debugPrint('🖼️ [GALLERY-PICKER] User ID: ${authState.user?.id}');
    debugPrint('🖼️ [GALLERY-PICKER] Auth status: ${authState.status}');

    await _pickAndUploadImage(ImageSource.gallery, authState);
  }

  Future<void> _pickImageFromCamera(EnhancedAuthState authState) async {
    debugPrint('📷 [CAMERA-PICKER] ===== CAMERA PICKER CALLED =====');
    debugPrint('📷 [CAMERA-PICKER] User ID: ${authState.user?.id}');
    debugPrint('📷 [CAMERA-PICKER] Auth status: ${authState.status}');

    await _pickAndUploadImage(ImageSource.camera, authState);
  }

  Future<void> _pickAndUploadImage(ImageSource source, EnhancedAuthState authState) async {
    try {
      // Get current driver data
      final driverProfileAsync = ref.read(driverProfileStreamProvider);
      final driver = driverProfileAsync.value;

      if (driver == null) {
        _showError('Driver profile not found. Please try again.');
        return;
      }

      debugPrint('🖼️ [IMAGE-UPLOAD] ===== STARTING IMAGE UPLOAD PROCESS =====');
      debugPrint('🖼️ [IMAGE-UPLOAD] Source: ${source.name}');
      debugPrint('🖼️ [IMAGE-UPLOAD] Driver ID: ${driver.id}');

      // Check permissions for camera if needed
      if (source == ImageSource.camera) {
        final hasPermissions = await CameraPermissionService.handlePhotoPermissionRequest(context);
        if (!hasPermissions) {
          debugPrint('📷 [CAMERA-PICKER] Camera permissions denied');
          return;
        }
      }

      // Set upload state
      ref.read(profilePhotoUploadProvider.notifier).state = true;
      debugPrint('🖼️ [IMAGE-UPLOAD] Upload state enabled');

      // Pick image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) {
        debugPrint('🖼️ [IMAGE-UPLOAD] No image selected');
        ref.read(profilePhotoUploadProvider.notifier).state = false;
        return;
      }

      debugPrint('🖼️ [IMAGE-UPLOAD] Image selected: ${image.path}');
      debugPrint('🖼️ [IMAGE-UPLOAD] Image size: ${await image.length()} bytes');

      // Upload image using driver profile actions
      final driverProfileActions = ref.read(driverProfileActionsProvider);
      final newPhotoUrl = await driverProfileActions.updateProfilePhoto(
        driverId: driver.id,
        imageFile: image,
        oldPhotoUrl: driver.profilePhotoUrl,
      );

      if (newPhotoUrl != null) {
        debugPrint('🖼️ [IMAGE-UPLOAD] Profile photo updated successfully');
        debugPrint('🖼️ [IMAGE-UPLOAD] New photo URL: $newPhotoUrl');

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }

        // Refresh the driver profile to show new photo
        ref.invalidate(driverProfileStreamProvider);
        debugPrint('🖼️ [IMAGE-UPLOAD] Driver profile stream invalidated for refresh');
      } else {
        debugPrint('🖼️ [IMAGE-UPLOAD] Failed to update profile photo');
        _showError('Failed to update profile photo. Please try again.');
      }
    } catch (e) {
      debugPrint('🖼️ [IMAGE-UPLOAD] Error uploading image: $e');
      _showError('Error uploading image: $e');
    } finally {
      // Clear upload state
      if (mounted) {
        ref.read(profilePhotoUploadProvider.notifier).state = false;
        debugPrint('🖼️ [IMAGE-UPLOAD] Upload state disabled');
      }
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
          validator: (value) => ProfileValidators.validateFullName(value),
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: Icons.phone,
          enabled: isEditing,
          keyboardType: TextInputType.phone,
          validator: (value) => ProfileValidators.validateMalaysianPhoneNumber(value),
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
            if (value == null || value.trim().isEmpty) {
              return 'Vehicle type is required';
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
            // Vehicle model is optional, no validation needed
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
            if (value == null || value.trim().isEmpty) {
              return 'License plate number is required';
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
    // TODO: Restore when driverPerformanceStatsProvider is implemented
    // final performanceStatsAsync = ref.watch(driverPerformanceStatsProvider);

    return _buildSection(
      theme,
      title: 'Performance Stats',
      children: [
        // TODO: Restore when performanceStatsAsync is implemented
        /* performanceStatsAsync.when(
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
        ), */
        // Placeholder for performance stats
        const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Performance stats will be implemented in next iteration'),
          ),
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
            // TODO: Implement navigation to notification settings
            debugPrint('🚗 Navigation to notification settings not implemented yet');
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

  // TODO: Restore when _currentDriver and profile editing is implemented
  /*
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
  */

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
              // TODO: Implement logout functionality
              debugPrint('🚗 Logout functionality not implemented yet');
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
            // TODO: Implement performance stats refresh
            debugPrint('🚗 Performance stats refresh not implemented yet');
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

  Widget _buildTestProfileContent(ThemeData theme, bool isEditing) {
    debugPrint('🧪 [TEST-CONTENT] ===== BUILDING TEST PROFILE CONTENT =====');
    debugPrint('🧪 [TEST-CONTENT] Edit mode: $isEditing');
    debugPrint('🧪 [TEST-CONTENT] Enhanced header debug logging is active');

    return SingleChildScrollView(
      child: Column(
        children: [
          // Enhanced Profile Header Demo Container
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.1),
                  theme.colorScheme.surface,
                ],
                stops: const [0.0, 0.7],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                children: [
                  // Profile Image Demo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Driver Name Demo
                  Text(
                    'Ahmad Rahman',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Phone Number Demo
                  Text(
                    '+60123456789',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Status and Rating Demo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Status Indicator Demo
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Online',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 24),

                      // Rating Demo
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '4.8',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(127)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Verification Badges Demo
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      // Verified Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified,
                              size: 12,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Vehicle Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.directions_car,
                              size: 12,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Vehicle Verified',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Experience Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.purple.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.workspace_premium,
                              size: 12,
                              color: Colors.purple,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Experienced',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.purple,
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
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

          const SizedBox(height: 32),

          // Demo Info Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.construction, size: 48, color: Colors.orange),
                    const SizedBox(height: 16),
                    Text(
                      'Enhanced Profile Header Demo',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The enhanced profile header design is now active! All debug logging is working. Navigate to the Profile tab to see the enhanced header in action.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '🎯 Debug Logging Active',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check the console logs for detailed information about:\n• Profile screen initialization\n• Enhanced header rendering\n• Status indicators\n• Rating display\n• Verification badges\n• Image picker interactions',
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /*
  TODO: Restore when driverProfileAsync.when is implemented

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
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
