import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../features/user_management/domain/user.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/user_repository.dart';
import '../utils/logger.dart';

/// Service for synchronizing authentication state between Firebase and Supabase
/// Note: This is a placeholder implementation since we've migrated to pure Supabase auth
class AuthSyncService {
  final UserRepository _userRepository = UserRepository();
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Initialize the auth sync service
  AuthSyncService();

  /// Sync user data when authentication state changes
  Future<void> syncUserData(User user) async {
    try {
      // Check if user exists in our database
      final existingUser = await _userRepository.getUserProfile(user.id);

      if (existingUser != null) {
        // Update existing user record
        await _userRepository.updateUserProfile(user);
      }
      // Note: User creation is handled by database triggers on auth.users
    } catch (e) {
      // Log error but don't throw to avoid breaking auth flow
      AppLogger().error('AuthSyncService: Error syncing user data', e);
    }
  }

  /// Handle user sign out
  Future<void> handleSignOut() async {
    try {
      // Clear any cached user data
      // This is a placeholder for any cleanup needed during sign out
    } catch (e) {
      AppLogger().error('AuthSyncService: Error during sign out', e);
    }
  }

  /// Get current authenticated user
  User? getCurrentUser() {
    final supabaseUser = _supabase.auth.currentUser;
    if (supabaseUser == null) return null;

    // Convert Supabase user to our User model
    return User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      fullName: supabaseUser.userMetadata?['full_name'] ?? 'Unknown User',
      phoneNumber: supabaseUser.phone,
      role: UserRole.customer, // Default role, should be determined from user metadata
      isVerified: supabaseUser.emailConfirmedAt != null,
      isActive: true,
      createdAt: DateTime.parse(supabaseUser.createdAt),
      updatedAt: DateTime.now(),
    );
  }

  /// Listen to auth state changes
  Stream<User?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((data) {
      final supabaseUser = data.session?.user;
      if (supabaseUser == null) return null;

      return User(
        id: supabaseUser.id,
        email: supabaseUser.email ?? '',
        fullName: supabaseUser.userMetadata?['full_name'] ?? 'Unknown User',
        phoneNumber: supabaseUser.phone,
        role: UserRole.customer, // Default role, should be determined from user metadata
        isVerified: supabaseUser.emailConfirmedAt != null,
        isActive: true,
        createdAt: DateTime.parse(supabaseUser.createdAt),
        updatedAt: DateTime.now(),
      );
    });
  }
}
