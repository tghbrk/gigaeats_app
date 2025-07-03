import 'package:equatable/equatable.dart';
import 'customer_profile.dart';

/// Customer profile state for state management
class CustomerProfileState extends Equatable {
  final CustomerProfile? profile;
  final bool isLoading;
  final String? error;
  final bool isUpdating;
  final bool isDeleting;

  const CustomerProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
    this.isUpdating = false,
    this.isDeleting = false,
  });

  /// Create a copy of CustomerProfileState with updated fields
  CustomerProfileState copyWith({
    CustomerProfile? profile,
    bool? isLoading,
    String? error,
    bool? isUpdating,
    bool? isDeleting,
  }) {
    return CustomerProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
    );
  }

  /// Clear error
  CustomerProfileState clearError() {
    return copyWith(error: null);
  }

  /// Set loading state
  CustomerProfileState setLoading(bool loading) {
    return copyWith(isLoading: loading);
  }

  /// Set updating state
  CustomerProfileState setUpdating(bool updating) {
    return copyWith(isUpdating: updating);
  }

  /// Set deleting state
  CustomerProfileState setDeleting(bool deleting) {
    return copyWith(isDeleting: deleting);
  }

  /// Set error
  CustomerProfileState setError(String error) {
    return copyWith(error: error, isLoading: false, isUpdating: false, isDeleting: false);
  }

  /// Set profile
  CustomerProfileState setProfile(CustomerProfile profile) {
    return copyWith(profile: profile, isLoading: false, error: null);
  }

  /// Check if profile exists
  bool get hasProfile => profile != null;

  /// Check if profile is complete
  bool get isProfileComplete => profile?.isComplete ?? false;

  /// Check if any operation is in progress
  bool get isOperationInProgress => isLoading || isUpdating || isDeleting;

  /// Get profile completion percentage
  double get completionPercentage => profile?.completionPercentage ?? 0.0;

  /// Get display name
  String get displayName => profile?.displayName ?? 'Customer';

  /// Check if business account
  bool get isBusinessAccount => profile?.isBusinessAccount ?? false;

  /// Check if verified
  bool get isVerified => profile?.isVerified ?? false;

  /// Create initial state
  factory CustomerProfileState.initial() {
    return const CustomerProfileState();
  }

  /// Create loading state
  factory CustomerProfileState.loading() {
    return const CustomerProfileState(isLoading: true);
  }

  /// Create error state
  factory CustomerProfileState.error(String error) {
    return CustomerProfileState(error: error);
  }

  /// Create success state with profile
  factory CustomerProfileState.success(CustomerProfile profile) {
    return CustomerProfileState(profile: profile);
  }

  @override
  List<Object?> get props => [
        profile,
        isLoading,
        error,
        isUpdating,
        isDeleting,
      ];
}
