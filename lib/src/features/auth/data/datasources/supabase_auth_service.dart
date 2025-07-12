import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../../../core/config/supabase_config.dart';
import '../models/auth_result.dart';
import '../../../user_management/domain/user.dart';
import '../../../../data/models/user_role.dart';

/// Supabase authentication service replacing Firebase Auth
class SupabaseAuthService {
  final SupabaseClient _supabase;
  final SharedPreferences _prefs;

  SupabaseAuthService({
    SupabaseClient? supabase,
    required SharedPreferences prefs,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _prefs = prefs;

  /// Get current Supabase user
  User? get currentUser {
    final supabaseUser = _supabase.auth.currentUser;
    if (supabaseUser == null) return null;

    // Convert Supabase User to our app User model
    return User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      fullName: supabaseUser.userMetadata?['full_name'] ?? 'User',
      phoneNumber: supabaseUser.phone ?? '',
      role: userRole ?? UserRole.salesAgent,
      isVerified: supabaseUser.emailConfirmedAt != null || supabaseUser.phoneConfirmedAt != null,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Get current user stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Check if user is authenticated
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  /// Get user ID
  String? get userId => _supabase.auth.currentUser?.id;

  /// Get user role from local storage or user metadata
  UserRole? get userRole {
    final roleString = _prefs.getString('user_role');
    if (roleString != null) {
      return UserRole.fromString(roleString);
    }
    
    // Fallback to user metadata
    final user = _supabase.auth.currentUser;
    if (user?.userMetadata != null) {
      final metaRole = user!.userMetadata!['role'] as String?;
      if (metaRole != null) {
        return UserRole.fromString(metaRole);
      }
    }
    
    return null;
  }

  /// Test basic network connectivity
  Future<bool> testNetworkConnectivity() async {
    try {
      debugPrint('🌐 SupabaseAuthService: Testing basic network connectivity...');

      // Test basic HTTP connectivity to Supabase
      final uri = Uri.parse('${SupabaseConfig.url}/rest/v1/');
      final request = http.Request('GET', uri);
      request.headers['apikey'] = SupabaseConfig.anonKey;
      request.headers['Authorization'] = 'Bearer ${SupabaseConfig.anonKey}';

      final client = http.Client();
      final response = await client.send(request).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('❌ SupabaseAuthService: Network connectivity test timed out');
          throw Exception('Network connectivity timeout');
        },
      );

      await response.stream.drain();
      client.close();

      debugPrint('✅ SupabaseAuthService: Network connectivity test successful (status: ${response.statusCode})');
      return response.statusCode < 500; // Accept any non-server error
    } catch (e) {
      debugPrint('❌ SupabaseAuthService: Network connectivity test failed: $e');
      return false;
    }
  }

  /// Test database connectivity
  Future<bool> testDatabaseConnectivity() async {
    try {
      debugPrint('🔍 SupabaseAuthService: Testing database connectivity...');

      // Try a simple query that doesn't require authentication
      await _supabase
          .from('users')
          .select('count')
          .limit(1)
          .timeout(const Duration(seconds: 10), onTimeout: () {
            debugPrint('❌ SupabaseAuthService: Database connectivity test timed out');
            throw Exception('Database connectivity timeout');
          });

      debugPrint('✅ SupabaseAuthService: Database connectivity test successful');
      return true;
    } catch (e) {
      debugPrint('❌ SupabaseAuthService: Database connectivity test failed: $e');
      return false;
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 SupabaseAuthService: Attempting to sign in user: $email');

      // First test network connectivity
      debugPrint('🔍 SupabaseAuthService: Testing connectivity before auth...');
      final isNetworkConnected = await testNetworkConnectivity();
      if (!isNetworkConnected) {
        debugPrint('❌ SupabaseAuthService: Network connectivity failed, aborting auth');
        return AuthResult.failure('Unable to connect to server. Please check your internet connection.');
      }
      debugPrint('✅ SupabaseAuthService: Network connectivity confirmed');

      // Then test database connectivity
      final isDatabaseConnected = await testDatabaseConnectivity();
      if (!isDatabaseConnected) {
        debugPrint('❌ SupabaseAuthService: Database connectivity failed, aborting auth');
        return AuthResult.failure('Database connection failed. Please try again later.');
      }
      debugPrint('✅ SupabaseAuthService: Database connectivity confirmed');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        debugPrint('❌ SupabaseAuthService: Supabase auth call timed out after 15 seconds');
        throw Exception('Authentication timeout after 15 seconds. Please check your connection and try again.');
      });

      debugPrint('🔐 SupabaseAuthService: Supabase auth call completed');

      if (response.user == null) {
        debugPrint('❌ SupabaseAuthService: No user in response');
        return AuthResult.failure('Failed to sign in user');
      }

      debugPrint('✅ SupabaseAuthService: Supabase auth successful, user ID: ${response.user!.id}');
      debugPrint('🔍 SupabaseAuthService: About to fetch user profile...');

      // Get user profile from database
      final user = await _getUserProfile(response.user!.id);
      if (user == null) {
        debugPrint('❌ SupabaseAuthService: User profile not found');
        return AuthResult.failure('User profile not found');
      }

      debugPrint('✅ SupabaseAuthService: User profile fetched successfully');

      // Store user data locally
      await _storeUserData(
        userId: user.id,
        role: user.role,
      );

      return AuthResult.success(user);
    } on AuthException catch (e) {
      debugPrint('SupabaseAuthService: Auth exception: ${e.message}');
      return AuthResult.failure(_getSupabaseErrorMessage(e));
    } catch (e) {
      debugPrint('SupabaseAuthService: Unexpected error: $e');
      return AuthResult.failure('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Register with email and password
  Future<AuthResult> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    UserRole role = UserRole.salesAgent,
  }) async {
    try {
      debugPrint('SupabaseAuthService: Attempting to register user: $email');

      // Validate Malaysian phone number if provided
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        final validationResult = _validateMalaysianPhoneNumber(phoneNumber);
        if (!validationResult.isValid) {
          return AuthResult.failure(validationResult.errorMessage!);
        }
        phoneNumber = validationResult.formattedNumber;
      }

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role.value,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        },
      );

      if (response.user == null) {
        return AuthResult.failure('Failed to create user');
      }

      debugPrint('SupabaseAuthService: Registration successful');

      // Create user profile manually using database function
      User? user;
      try {
        debugPrint('SupabaseAuthService: Creating user profile for ${response.user!.id}');

        final profileResult = await _supabase
            .rpc('create_user_profile_from_auth', params: {
          'auth_user_id': response.user!.id,
        });

        if (profileResult != null && profileResult.isNotEmpty) {
          final profileData = profileResult[0];
          user = User(
            id: profileData['user_id'],
            email: profileData['email'],
            fullName: profileData['full_name'],
            phoneNumber: phoneNumber ?? '',
            role: UserRole.fromString(profileData['role']),
            isVerified: response.user!.emailConfirmedAt != null,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          debugPrint('SupabaseAuthService: User profile created successfully');
        }
      } catch (e) {
        debugPrint('SupabaseAuthService: Error creating user profile: $e');
        // Continue with fallback approach
      }

      // Fallback: try to get user profile from database
      if (user == null) {
        for (int i = 0; i < 3; i++) {
          user = await _getUserProfile(response.user!.id);
          if (user != null) break;
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (user == null) {
        // If still no user profile, create fallback user object
        debugPrint('SupabaseAuthService: User profile not found after registration, creating fallback');
        final fallbackUser = User(
          id: response.user!.id,
          email: email,
          fullName: fullName,
          phoneNumber: phoneNumber ?? '',
          role: role,
          isVerified: false,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        return AuthResult.success(fallbackUser);
      }

      // Store user data locally
      await _storeUserData(
        userId: user.id,
        role: user.role,
      );

      return AuthResult.success(user);
    } on AuthException catch (e) {
      debugPrint('SupabaseAuthService: Auth exception: ${e.message}');
      return AuthResult.failure(_getSupabaseErrorMessage(e));
    } catch (e) {
      debugPrint('SupabaseAuthService: Unexpected error: $e');
      return AuthResult.failure('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      debugPrint('🔐 SupabaseAuthService: Starting sign out process...');
      debugPrint('🔐 SupabaseAuthService: Current user before sign out: ${_supabase.auth.currentUser?.email}');

      await _supabase.auth.signOut();
      debugPrint('🔐 SupabaseAuthService: Supabase auth.signOut() completed');

      await _clearUserData();
      debugPrint('🔐 SupabaseAuthService: User data cleared');

      debugPrint('🔐 SupabaseAuthService: Current user after sign out: ${_supabase.auth.currentUser}');
      debugPrint('🔐 SupabaseAuthService: Sign out successful');
    } catch (e) {
      debugPrint('🔐 SupabaseAuthService: Error signing out: $e');
      rethrow;
    }
  }

  /// Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return AuthResult.success(null);
    } on AuthException catch (e) {
      return AuthResult.failure(_getSupabaseErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Update password
  Future<AuthResult> updatePassword({
    required String newPassword,
  }) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return AuthResult.success(null);
    } on AuthException catch (e) {
      return AuthResult.failure(_getSupabaseErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Verify phone number (Malaysian numbers)
  Future<AuthResult> verifyPhoneNumber({
    required String phoneNumber,
  }) async {
    try {
      // Validate Malaysian phone number format
      final validationResult = _validateMalaysianPhoneNumber(phoneNumber);
      if (!validationResult.isValid) {
        return AuthResult.failure(validationResult.errorMessage!);
      }

      final formattedNumber = validationResult.formattedNumber!;
      debugPrint('SupabaseAuthService: Verifying phone number: $formattedNumber');

      await _supabase.auth.signInWithOtp(
        phone: formattedNumber,
      );

      return AuthResult.success(null);
    } on AuthException catch (e) {
      debugPrint('SupabaseAuthService: Phone verification failed: ${e.message}');
      return AuthResult.failure(_getSupabaseErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Verify OTP code
  Future<AuthResult> verifyOtp({
    required String phone,
    required String token,
  }) async {
    try {
      debugPrint('SupabaseAuthService: Verifying OTP code');

      final response = await _supabase.auth.verifyOTP(
        type: OtpType.sms,
        phone: phone,
        token: token,
      );

      if (response.user == null) {
        return AuthResult.failure('Failed to verify OTP');
      }

      // Update current user's phone number if they're already signed in
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        await _supabase.auth.updateUser(
          UserAttributes(phone: phone),
        );
        
        // Update user profile in database
        await _supabase.from('users').update({
          'phone_number': phone,
          'is_verified': true,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('supabase_user_id', currentUser.id);
      }

      return AuthResult.success(null);
    } on AuthException catch (e) {
      return AuthResult.failure(_getSupabaseErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Resend verification email
  Future<AuthResult> resendVerificationEmail(String email) async {
    try {
      debugPrint('SupabaseAuthService: Resending verification email to $email');

      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );

      debugPrint('SupabaseAuthService: Verification email resent successfully');
      return AuthResult.success(null);
    } on AuthException catch (e) {
      debugPrint('SupabaseAuthService: Failed to resend verification email: ${e.message}');
      return AuthResult.failure(_getSupabaseErrorMessage(e));
    } catch (e) {
      debugPrint('SupabaseAuthService: Unexpected error resending verification email: $e');
      return AuthResult.failure('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Get user profile from database (public method)
  Future<User?> getUserProfile(String userId) async {
    return _getUserProfile(userId);
  }

  /// Get user profile from database
  Future<User?> _getUserProfile(String userId) async {
    try {
      debugPrint('🔍 SupabaseAuthService: Starting user profile fetch for: $userId');

      // Use a more specific query to avoid RLS circular dependency issues
      final response = await _supabase
          .from('users')
          .select('id, email, full_name, phone_number, role, is_verified, is_active, profile_image_url, metadata, created_at, updated_at, supabase_user_id')
          .eq('supabase_user_id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 10), onTimeout: () {
            debugPrint('❌ SupabaseAuthService: User profile fetch timed out after 10 seconds');
            throw Exception('User profile fetch timeout after 10 seconds');
          });

      if (response == null) {
        debugPrint('❌ SupabaseAuthService: No user profile found for: $userId');
        return null;
      }

      debugPrint('✅ SupabaseAuthService: User profile fetched successfully');
      return User.fromJson(response);
    } catch (e) {
      debugPrint('❌ SupabaseAuthService: Error getting user profile: $e');
      return null;
    }
  }

  /// Store user data locally
  Future<void> _storeUserData({
    required String userId,
    required UserRole role,
  }) async {
    await _prefs.setString('user_id', userId);
    await _prefs.setString('user_role', role.value);
    await _prefs.setBool('is_authenticated', true);
  }

  /// Clear user data
  Future<void> _clearUserData() async {
    await _prefs.remove('user_id');
    await _prefs.remove('user_role');
    await _prefs.setBool('is_authenticated', false);
  }

  /// Validate Malaysian phone number
  PhoneValidationResult _validateMalaysianPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return PhoneValidationResult.invalid('Phone number cannot be empty');
    }

    // Check if it starts with Malaysia country code
    if (digitsOnly.startsWith('60')) {
      // Remove country code and validate
      final localNumber = digitsOnly.substring(2);
      return _validateLocalMalaysianNumber(localNumber, '+60');
    }

    // Check if it starts with 0 (local format)
    if (digitsOnly.startsWith('0')) {
      return _validateLocalMalaysianNumber(digitsOnly, '+60');
    }

    // If no country code, assume Malaysian and add +60
    if (digitsOnly.length >= 9 && digitsOnly.length <= 11) {
      return _validateLocalMalaysianNumber('0$digitsOnly', '+60');
    }

    return PhoneValidationResult.invalid(
      'Invalid Malaysian phone number format. Please use format: 01X-XXXXXXX or +601X-XXXXXXX'
    );
  }

  PhoneValidationResult _validateLocalMalaysianNumber(String localNumber, String countryCode) {
    final digitsOnly = localNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Mobile numbers: 01X-XXXXXXX (10-11 digits with leading 0)
    if (digitsOnly.startsWith('01')) {
      if (digitsOnly.length >= 10 && digitsOnly.length <= 11) {
        // Valid mobile number
        final formatted = '$countryCode${digitsOnly.substring(1)}'; // Remove leading 0 and add country code
        return PhoneValidationResult.valid(formatted);
      }
    }

    // Landline numbers: 0X-XXXXXXX (9-10 digits with leading 0, X != 1)
    if (digitsOnly.startsWith('0') && !digitsOnly.startsWith('01')) {
      if (digitsOnly.length >= 9 && digitsOnly.length <= 10) {
        // Valid landline number
        final formatted = '$countryCode${digitsOnly.substring(1)}'; // Remove leading 0 and add country code
        return PhoneValidationResult.valid(formatted);
      }
    }

    return PhoneValidationResult.invalid(
      'Invalid Malaysian phone number. Mobile: 01X-XXXXXXX, Landline: 0X-XXXXXXX'
    );
  }

  /// Get Supabase error message
  String _getSupabaseErrorMessage(AuthException e) {
    switch (e.message) {
      case 'Invalid login credentials':
        return 'Invalid email or password. Please check your credentials and try again.';
      case 'Email not confirmed':
        return 'Please verify your email address before signing in.';
      case 'User already registered':
        return 'An account with this email already exists. Please sign in instead.';
      case 'Password should be at least 6 characters':
        return 'Password must be at least 6 characters long.';
      case 'Signup requires a valid password':
        return 'Please enter a valid password.';
      case 'Unable to validate email address: invalid format':
        return 'Please enter a valid email address.';
      case 'Phone number is invalid':
        return 'Please enter a valid Malaysian phone number.';
      default:
        return e.message;
    }
  }
}

/// Phone validation result
class PhoneValidationResult {
  final bool isValid;
  final String? formattedNumber;
  final String? errorMessage;

  PhoneValidationResult.valid(this.formattedNumber)
      : isValid = true,
        errorMessage = null;

  PhoneValidationResult.invalid(this.errorMessage)
      : isValid = false,
        formattedNumber = null;
}
