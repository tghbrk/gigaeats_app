import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/driver.dart';

/// Service for driver-specific authentication and profile management
/// Handles driver registration, profile creation, and validation
class DriverAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Register a new driver user with proper profile setup
  Future<DriverRegistrationResult> registerDriverUser({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    String? vendorId,
  }) async {
    try {
      debugPrint('DriverAuthService: Registering driver user: $email');

      // First, register the user with Supabase Auth
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': 'driver',
          'phone_number': phoneNumber,
        },
        emailRedirectTo: 'gigaeats://auth/callback',
      );

      if (authResponse.user == null) {
        return DriverRegistrationResult.failure('Failed to create user account');
      }

      debugPrint('DriverAuthService: Auth user created, setting up driver profile');

      // Wait a moment for the trigger to process
      await Future.delayed(const Duration(milliseconds: 1000));

      // Use the database function to ensure proper driver setup
      final profileResult = await _supabase.rpc('register_driver_user', params: {
        'p_email': email,
        'p_full_name': fullName,
        'p_phone_number': phoneNumber,
        'p_vendor_id': vendorId,
      });

      if (profileResult.isNotEmpty) {
        final result = profileResult.first;
        final success = result['success'] as bool;
        final message = result['message'] as String;

        if (!success) {
          debugPrint('DriverAuthService: Driver profile setup failed: $message');
          return DriverRegistrationResult.failure(message);
        }

        final userId = result['user_id'] as String;
        final driverId = result['driver_id'] as String;

        debugPrint('DriverAuthService: Driver profile setup successful');

        // Get the complete driver profile
        final driver = await getDriverProfile(userId);
        if (driver == null) {
          return DriverRegistrationResult.failure('Failed to retrieve driver profile');
        }

        return DriverRegistrationResult.success(
          userId: userId,
          driverId: driverId,
          driver: driver,
          message: 'Driver registration successful',
        );
      }

      return DriverRegistrationResult.failure('Failed to setup driver profile');
    } catch (e) {
      debugPrint('DriverAuthService: Error registering driver user: $e');
      return DriverRegistrationResult.failure('Registration failed: ${e.toString()}');
    }
  }

  /// Get driver profile by user ID
  Future<Driver?> getDriverProfile(String userId) async {
    try {
      debugPrint('DriverAuthService: Getting driver profile for user: $userId');

      final response = await _supabase
          .from('drivers')
          .select('''
            id,
            user_id,
            vendor_id,
            name,
            phone_number,
            status,
            is_active,
            vehicle_details,
            last_location,
            last_seen,
            created_at,
            updated_at
          ''')
          .eq('user_id', userId)
          .single();

      debugPrint('DriverAuthService: Driver profile retrieved successfully');
      return Driver.fromJson(response);
    } catch (e) {
      debugPrint('DriverAuthService: Error getting driver profile: $e');
      return null;
    }
  }

  /// Validate driver user setup
  Future<DriverValidationResult> validateDriverSetup(String userId) async {
    try {
      debugPrint('DriverAuthService: Validating driver setup for user: $userId');

      final response = await _supabase.rpc('validate_driver_user_setup', params: {
        'p_user_id': userId,
      });

      if (response.isNotEmpty) {
        final result = response.first;
        
        return DriverValidationResult(
          isValid: result['is_valid'] as bool,
          userExists: result['user_exists'] as bool,
          driverExists: result['driver_exists'] as bool,
          hasCorrectRole: result['has_correct_role'] as bool,
          driverId: result['driver_id'] as String?,
          issues: List<String>.from(result['issues'] ?? []),
        );
      }

      return DriverValidationResult(
        isValid: false,
        userExists: false,
        driverExists: false,
        hasCorrectRole: false,
        driverId: null,
        issues: ['Validation failed'],
      );
    } catch (e) {
      debugPrint('DriverAuthService: Error validating driver setup: $e');
      return DriverValidationResult(
        isValid: false,
        userExists: false,
        driverExists: false,
        hasCorrectRole: false,
        driverId: null,
        issues: ['Validation error: ${e.toString()}'],
      );
    }
  }

  /// Fix driver user setup issues
  Future<bool> fixDriverSetup(String userId) async {
    try {
      debugPrint('DriverAuthService: Fixing driver setup for user: $userId');

      // First validate to see what's wrong
      final validation = await validateDriverSetup(userId);
      
      if (validation.isValid) {
        debugPrint('DriverAuthService: Driver setup is already valid');
        return true;
      }

      // Get user information
      final userResponse = await _supabase
          .from('users')
          .select('id, email, full_name, phone_number, role')
          .eq('id', userId)
          .single();


      final userFullName = userResponse['full_name'] as String;
      final userPhoneNumber = userResponse['phone_number'] as String?;
      final userRole = userResponse['role'] as String;

      // Fix role if incorrect
      if (userRole != 'driver') {
        await _supabase
            .from('users')
            .update({'role': 'driver', 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', userId);
        debugPrint('DriverAuthService: Fixed user role to driver');
      }

      // Create driver record if missing
      if (!validation.driverExists) {
        await _supabase.from('drivers').insert({
          'user_id': userId,
          'name': userFullName,
          'phone_number': userPhoneNumber ?? '',
          'status': 'offline',
          'is_active': true,
          'vehicle_details': {
            'type': 'motorcycle',
            'plateNumber': '',
            'color': '',
            'brand': '',
            'model': '',
            'year': '',
          },
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        debugPrint('DriverAuthService: Created missing driver record');
      }

      // Validate again to confirm fix
      final revalidation = await validateDriverSetup(userId);
      debugPrint('DriverAuthService: Driver setup fix result: ${revalidation.isValid}');
      
      return revalidation.isValid;
    } catch (e) {
      debugPrint('DriverAuthService: Error fixing driver setup: $e');
      return false;
    }
  }

  /// Update driver profile information
  Future<bool> updateDriverProfile({
    required String driverId,
    String? name,
    String? phoneNumber,
    Map<String, dynamic>? vehicleDetails,
    String? profilePhotoUrl,
  }) async {
    try {
      debugPrint('DriverAuthService: Updating driver profile: $driverId');

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (vehicleDetails != null) updateData['vehicle_details'] = vehicleDetails;
      if (profilePhotoUrl != null) updateData['profile_photo_url'] = profilePhotoUrl;

      await _supabase
          .from('drivers')
          .update(updateData)
          .eq('id', driverId);

      debugPrint('DriverAuthService: Driver profile updated successfully');
      return true;
    } catch (e) {
      debugPrint('DriverAuthService: Error updating driver profile: $e');
      return false;
    }
  }

  /// Update driver status (online/offline/on_delivery)
  Future<bool> updateDriverStatus({
    required String driverId,
    required String status,
    Map<String, dynamic>? lastLocation,
  }) async {
    try {
      debugPrint('🔄 [DRIVER-AUTH] Updating driver status');
      debugPrint('🔄 [DRIVER-AUTH] Driver: $driverId, New Status: $status');

      final updateData = <String, dynamic>{
        'status': status,
        'last_seen': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (lastLocation != null) {
        updateData['last_location'] = lastLocation;
        debugPrint('🔄 [DRIVER-AUTH] Including location update in status change');
      }

      // Clear delivery status when driver goes offline
      if (status == 'offline') {
        updateData['current_delivery_status'] = null;
        debugPrint('🧹 [DRIVER-AUTH] Clearing driver delivery status for offline transition');
        debugPrint('🧹 [DRIVER-AUTH] Driver $driverId going offline - cleaning up workflow state');
      }

      await _supabase
          .from('drivers')
          .update(updateData)
          .eq('id', driverId);

      debugPrint('DriverAuthService: Driver status updated successfully');
      return true;
    } catch (e) {
      debugPrint('DriverAuthService: Error updating driver status: $e');
      return false;
    }
  }

  /// Get driver profile with real-time updates
  Stream<Driver?> getDriverProfileStream(String userId) {
    try {
      debugPrint('DriverAuthService: Setting up driver profile stream for user: $userId');

      return _supabase
          .from('drivers')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .map((data) {
            if (data.isEmpty) return null;
            return Driver.fromJson(data.first);
          });
    } catch (e) {
      debugPrint('DriverAuthService: Error setting up driver profile stream: $e');
      return Stream.value(null);
    }
  }

  /// Link existing driver to user account
  Future<bool> linkDriverToUser({
    required String userId,
    required String driverId,
  }) async {
    try {
      debugPrint('DriverAuthService: Linking driver $driverId to user $userId');

      // Check if driver is already linked to another user
      final existingLink = await _supabase
          .from('drivers')
          .select('user_id')
          .eq('id', driverId)
          .single();

      if (existingLink['user_id'] != null && existingLink['user_id'] != userId) {
        debugPrint('DriverAuthService: Driver is already linked to another user');
        return false;
      }

      // Link driver to user
      await _supabase
          .from('drivers')
          .update({
            'user_id': userId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);

      // Update user role to driver
      await _supabase
          .from('users')
          .update({
            'role': 'driver',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      debugPrint('DriverAuthService: Driver linked to user successfully');
      return true;
    } catch (e) {
      debugPrint('DriverAuthService: Error linking driver to user: $e');
      return false;
    }
  }

  /// Check if email is available for driver registration
  Future<bool> isEmailAvailable(String email) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('email', email)
          .limit(1);

      return response.isEmpty;
    } catch (e) {
      debugPrint('DriverAuthService: Error checking email availability: $e');
      return false;
    }
  }

  /// Check if phone number is available for driver registration
  Future<bool> isPhoneNumberAvailable(String phoneNumber) async {
    try {
      final response = await _supabase
          .from('drivers')
          .select('id')
          .eq('phone_number', phoneNumber)
          .not('user_id', 'is', null)
          .limit(1);

      return response.isEmpty;
    } catch (e) {
      debugPrint('DriverAuthService: Error checking phone availability: $e');
      return false;
    }
  }
}

/// Result class for driver registration
class DriverRegistrationResult {
  final bool success;
  final String message;
  final String? userId;
  final String? driverId;
  final Driver? driver;

  DriverRegistrationResult._({
    required this.success,
    required this.message,
    this.userId,
    this.driverId,
    this.driver,
  });

  factory DriverRegistrationResult.success({
    required String userId,
    required String driverId,
    required Driver driver,
    required String message,
  }) {
    return DriverRegistrationResult._(
      success: true,
      message: message,
      userId: userId,
      driverId: driverId,
      driver: driver,
    );
  }

  factory DriverRegistrationResult.failure(String message) {
    return DriverRegistrationResult._(
      success: false,
      message: message,
    );
  }
}

/// Result class for driver validation
class DriverValidationResult {
  final bool isValid;
  final bool userExists;
  final bool driverExists;
  final bool hasCorrectRole;
  final String? driverId;
  final List<String> issues;

  DriverValidationResult({
    required this.isValid,
    required this.userExists,
    required this.driverExists,
    required this.hasCorrectRole,
    required this.driverId,
    required this.issues,
  });

  @override
  String toString() {
    return 'DriverValidationResult(isValid: $isValid, userExists: $userExists, driverExists: $driverExists, hasCorrectRole: $hasCorrectRole, driverId: $driverId, issues: $issues)';
  }
}
