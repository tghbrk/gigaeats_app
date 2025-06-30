import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/customer_profile.dart';
import '../../data/repositories/customer_profile_repository.dart';
import '../../../../core/utils/profile_validators.dart';
import 'package:flutter/foundation.dart';

part 'customer_profile_form_provider.freezed.dart';

/// State for customer profile form
@freezed
class CustomerProfileFormState with _$CustomerProfileFormState {
  const factory CustomerProfileFormState({
    @Default(false) bool isLoading,
    @Default(false) bool isSaving,
    String? error,
    CustomerProfile? originalProfile,
    @Default('') String fullName,
    @Default('') String phoneNumber,
    @Default(false) bool hasUnsavedChanges,
    @Default({}) Map<String, String> fieldErrors,
  }) = _CustomerProfileFormState;
}

/// Customer profile form state notifier
class CustomerProfileFormNotifier extends StateNotifier<CustomerProfileFormState> {
  CustomerProfileFormNotifier({
    required CustomerProfileRepository repository,
  }) : _repository = repository,
       super(const CustomerProfileFormState());

  final CustomerProfileRepository _repository;

  /// Initialize form with current profile data
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final profile = await _repository.getCurrentProfile();
      
      if (profile != null) {
        state = state.copyWith(
          isLoading: false,
          originalProfile: profile,
          fullName: profile.fullName,
          phoneNumber: profile.phoneNumber ?? '',
          hasUnsavedChanges: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'No profile found',
        );
      }
    } catch (e) {
      debugPrint('Error initializing profile form: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update full name
  void updateFullName(String fullName) {
    final trimmedName = fullName.trim();
    state = state.copyWith(
      fullName: trimmedName,
      hasUnsavedChanges: _hasChanges(fullName: trimmedName),
      fieldErrors: {...state.fieldErrors}..remove('fullName'),
    );
  }

  /// Update phone number
  void updatePhoneNumber(String phoneNumber) {
    final trimmedPhone = phoneNumber.trim();
    state = state.copyWith(
      phoneNumber: trimmedPhone,
      hasUnsavedChanges: _hasChanges(phoneNumber: trimmedPhone),
      fieldErrors: {...state.fieldErrors}..remove('phoneNumber'),
    );
  }

  /// Validate form fields
  bool validateForm() {
    final errors = <String, String>{};

    // Validate full name
    final fullNameError = ProfileValidators.validateFullName(state.fullName);
    if (fullNameError != null) {
      errors['fullName'] = fullNameError;
    }

    // Validate phone number (optional)
    final phoneError = ProfileValidators.validateMalaysianPhoneNumber(
      state.phoneNumber,
      required: false,
    );
    if (phoneError != null) {
      errors['phoneNumber'] = phoneError;
    }

    state = state.copyWith(fieldErrors: errors);
    return errors.isEmpty;
  }

  /// Save profile changes
  Future<bool> saveProfile() async {
    if (!validateForm()) {
      return false;
    }
    
    state = state.copyWith(isSaving: true, error: null);
    
    try {
      final originalProfile = state.originalProfile;
      if (originalProfile == null) {
        throw Exception('No original profile found');
      }
      
      // Create updated profile
      final updatedProfile = originalProfile.copyWith(
        fullName: state.fullName,
        phoneNumber: state.phoneNumber.isEmpty ? null : state.phoneNumber,
      );
      
      // Save to repository
      await _repository.updateProfile(updatedProfile);
      
      // Update state
      state = state.copyWith(
        isSaving: false,
        originalProfile: updatedProfile,
        hasUnsavedChanges: false,
      );
      
      debugPrint('Profile updated successfully');
      return true;
    } catch (e) {
      debugPrint('Error saving profile: $e');
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to save profile: $e',
      );
      return false;
    }
  }

  /// Reset form to original values
  void resetForm() {
    final original = state.originalProfile;
    if (original != null) {
      state = state.copyWith(
        fullName: original.fullName,
        phoneNumber: original.phoneNumber ?? '',
        hasUnsavedChanges: false,
        fieldErrors: {},
        error: null,
      );
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear field error
  void clearFieldError(String field) {
    state = state.copyWith(
      fieldErrors: {...state.fieldErrors}..remove(field),
    );
  }

  /// Check if form has changes compared to original
  bool _hasChanges({
    String? fullName,
    String? phoneNumber,
  }) {
    final original = state.originalProfile;
    if (original == null) return false;

    final currentFullName = fullName ?? state.fullName;
    final currentPhoneNumber = phoneNumber ?? state.phoneNumber;

    return currentFullName != original.fullName ||
           currentPhoneNumber != (original.phoneNumber ?? '');
  }

  /// Get field error message
  String? getFieldError(String field) {
    return state.fieldErrors[field];
  }

  /// Check if field has error
  bool hasFieldError(String field) {
    return state.fieldErrors.containsKey(field);
  }
}

/// Provider for customer profile form
final customerProfileFormProvider = StateNotifierProvider<CustomerProfileFormNotifier, CustomerProfileFormState>((ref) {
  final repository = ref.watch(customerProfileRepositoryProvider);
  
  return CustomerProfileFormNotifier(
    repository: repository,
  );
});

/// Provider for customer profile repository
final customerProfileRepositoryProvider = Provider<CustomerProfileRepository>((ref) {
  return CustomerProfileRepository();
});
