import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/vendor.dart';
import '../../data/repositories/vendor_repository.dart';
import 'vendor_repository_providers.dart';
import '../../../../core/services/file_upload_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/debug_logger.dart';
import '../../../../presentation/providers/repository_providers.dart' show currentVendorProvider;

part 'vendor_profile_edit_providers.freezed.dart';

final _logger = AppLogger();

// ============================================================================
// STATE CLASSES
// ============================================================================

/// Vendor profile edit form state
@freezed
class VendorProfileEditState with _$VendorProfileEditState {
  const factory VendorProfileEditState({
    // Form data
    @Default('') String businessName,
    @Default('') String businessRegistrationNumber,
    @Default('') String businessAddress,
    @Default('') String businessType,
    @Default([]) List<String> cuisineTypes,
    @Default(false) bool isHalalCertified,
    String? halalCertificationNumber,
    @Default('') String description,
    String? coverImageUrl,
    @Default([]) List<String> galleryImages,
    @Default({}) Map<String, dynamic> businessHours,
    @Default([]) List<String> serviceAreas,
    @Default(50.0) double minimumOrderAmount,
    @Default(15.0) double deliveryFee,
    @Default(200.0) double freeDeliveryThreshold,
    
    // Form state
    @Default(false) bool isLoading,
    @Default(false) bool isSaving,
    @Default(false) bool hasUnsavedChanges,
    @Default({}) Map<String, String> fieldErrors,
    String? globalError,
    String? successMessage,
    
    // Original data for rollback
    Vendor? originalVendor,
    
    // Validation state
    @Default(false) bool isValidating,
    @Default(true) bool isFormValid,
    DateTime? lastValidated,
  }) = _VendorProfileEditState;
}

/// Image upload state
@freezed
class ImageUploadState with _$ImageUploadState {
  const factory ImageUploadState({
    @Default(false) bool isUploading,
    @Default(0.0) double progress,
    String? status,
    String? error,
    String? uploadedUrl,
  }) = _ImageUploadState;
}

/// Business hours edit state
@freezed
class BusinessHoursEditState with _$BusinessHoursEditState {
  const factory BusinessHoursEditState({
    @Default({}) Map<String, dynamic> hours,
    @Default(false) bool hasChanges,
    @Default({}) Map<String, String> errors,
  }) = _BusinessHoursEditState;
}

// ============================================================================
// STATE NOTIFIERS
// ============================================================================

/// Main vendor profile edit form notifier
class VendorProfileEditNotifier extends StateNotifier<VendorProfileEditState> {
  final VendorRepository _vendorRepository;
  final Ref _ref;

  VendorProfileEditNotifier({
    required VendorRepository vendorRepository,
    required Ref ref,
  }) : _vendorRepository = vendorRepository,
       _ref = ref,
       super(const VendorProfileEditState());

  /// Load vendor profile for editing
  Future<void> loadVendorProfile() async {
    final authState = _ref.read(authStateProvider);
    if (authState.user?.id == null) {
      _setError('User not authenticated');
      return;
    }

    _logger.info('🔍 [VENDOR-EDIT] Loading vendor profile for user: ${authState.user!.id}');
    state = state.copyWith(isLoading: true, globalError: null);

    try {
      final vendor = await _vendorRepository.getVendorByUserId(authState.user!.id);
      if (vendor != null) {
        _logger.info('✅ [VENDOR-EDIT] Vendor profile loaded: ${vendor.businessName}');
        state = _createStateFromVendor(vendor);
      } else {
        _logger.warning('⚠️ [VENDOR-EDIT] No vendor profile found');
        state = state.copyWith(
          isLoading: false,
          globalError: 'Vendor profile not found',
        );
      }
    } catch (e, stackTrace) {
      _logger.error('❌ [VENDOR-EDIT] Failed to load vendor profile', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        globalError: 'Failed to load vendor profile: $e',
      );
    }
  }

  /// Update business name
  void updateBusinessName(String value) {
    _updateField('businessName', value);
    state = state.copyWith(
      businessName: value,
      hasUnsavedChanges: true,
    );
    _validateField('businessName', value);
  }

  /// Update business registration number
  void updateBusinessRegistrationNumber(String value) {
    _updateField('businessRegistrationNumber', value);
    state = state.copyWith(
      businessRegistrationNumber: value,
      hasUnsavedChanges: true,
    );
    _validateField('businessRegistrationNumber', value);
  }

  /// Update business address
  void updateBusinessAddress(String value) {
    _updateField('businessAddress', value);
    state = state.copyWith(
      businessAddress: value,
      hasUnsavedChanges: true,
    );
    _validateField('businessAddress', value);
  }

  /// Update business type
  void updateBusinessType(String value) {
    _updateField('businessType', value);
    state = state.copyWith(
      businessType: value,
      hasUnsavedChanges: true,
    );
    _validateField('businessType', value);
  }

  /// Update cuisine types
  void updateCuisineTypes(List<String> value) {
    _logger.info('🍽️ [VENDOR-EDIT] Updating cuisine types: $value');
    _updateField('cuisineTypes', value);
    state = state.copyWith(
      cuisineTypes: value,
      hasUnsavedChanges: true,
    );
    _validateField('cuisineTypes', value);
    _logger.info('🍽️ [VENDOR-EDIT] Cuisine types updated, state now has: ${state.cuisineTypes}');
  }

  /// Update cover image URL
  void updateCoverImageUrl(String? value) {
    _logger.info('📸 [VENDOR-EDIT] Updating cover image URL: $value');
    _updateField('coverImageUrl', value);
    state = state.copyWith(
      coverImageUrl: value,
      hasUnsavedChanges: true,
    );
    _logger.info('📸 [VENDOR-EDIT] Cover image URL updated');
  }

  /// Update gallery images
  void updateGalleryImages(List<String> value) {
    _logger.info('🖼️ [VENDOR-EDIT] Updating gallery images: ${value.length} images');
    _updateField('galleryImages', value);
    state = state.copyWith(
      galleryImages: value,
      hasUnsavedChanges: true,
    );
    _logger.info('🖼️ [VENDOR-EDIT] Gallery images updated');
  }

  /// Update minimum order amount
  void updateMinimumOrderAmount(double value) {
    _logger.info('💰 [VENDOR-EDIT] Updating minimum order amount: RM $value');
    _updateField('minimumOrderAmount', value);
    state = state.copyWith(
      minimumOrderAmount: value,
      hasUnsavedChanges: true,
    );
    _validateField('minimumOrderAmount', value);
    _logger.info('💰 [VENDOR-EDIT] Minimum order amount updated');
  }

  /// Update delivery fee
  void updateDeliveryFee(double value) {
    _logger.info('🚚 [VENDOR-EDIT] Updating delivery fee: RM $value');
    _updateField('deliveryFee', value);
    state = state.copyWith(
      deliveryFee: value,
      hasUnsavedChanges: true,
    );
    _validateField('deliveryFee', value);
    _logger.info('🚚 [VENDOR-EDIT] Delivery fee updated');
  }

  /// Update free delivery threshold
  void updateFreeDeliveryThreshold(double value) {
    _logger.info('🆓 [VENDOR-EDIT] Updating free delivery threshold: RM $value');
    _updateField('freeDeliveryThreshold', value);
    state = state.copyWith(
      freeDeliveryThreshold: value,
      hasUnsavedChanges: true,
    );
    _validateField('freeDeliveryThreshold', value);
    _logger.info('🆓 [VENDOR-EDIT] Free delivery threshold updated');
  }

  /// Update halal certification
  void updateHalalCertification(bool isHalal, String? certNumber) {
    _updateField('isHalalCertified', isHalal);
    state = state.copyWith(
      isHalalCertified: isHalal,
      halalCertificationNumber: certNumber,
      hasUnsavedChanges: true,
    );
    _validateField('halalCertification', {'isHalal': isHalal, 'certNumber': certNumber});
  }

  /// Update description
  void updateDescription(String value) {
    _updateField('description', value);
    state = state.copyWith(
      description: value,
      hasUnsavedChanges: true,
    );
    _validateField('description', value);
  }

  /// Update business hours
  void updateBusinessHours(Map<String, dynamic> hours) {
    debugPrint('🕒 [VENDOR-PROFILE-EDIT] Updating business hours');
    debugPrint('🕒 [VENDOR-PROFILE-EDIT] New hours: $hours');

    _updateField('businessHours', hours);
    state = state.copyWith(
      businessHours: hours,
      hasUnsavedChanges: true,
    );
    _validateField('businessHours', hours);

    debugPrint('🕒 [VENDOR-PROFILE-EDIT] Business hours updated in state');
    debugPrint('🕒 [VENDOR-PROFILE-EDIT] Has unsaved changes: ${state.hasUnsavedChanges}');
  }

  /// Update service areas
  void updateServiceAreas(List<String> areas) {
    _updateField('serviceAreas', areas);
    state = state.copyWith(
      serviceAreas: areas,
      hasUnsavedChanges: true,
    );
    _validateField('serviceAreas', areas);
  }



  /// Save vendor profile
  Future<bool> saveProfile() async {
    _logger.info('💾 [VENDOR-EDIT] Saving vendor profile...');
    DebugLogger.info('💾 [VENDOR-EDIT] Starting profile save operation', tag: 'VendorProfileEdit');

    // Log current state before save
    DebugLogger.logObject('Pre-Save State', {
      'hasUnsavedChanges': state.hasUnsavedChanges,
      'fieldErrorCount': state.fieldErrors.length,
      'isFormValid': state.isFormValid,
      'isSaving': state.isSaving,
      'businessName': state.businessName,
      'businessType': state.businessType,
      'cuisineTypesCount': state.cuisineTypes.length,
    });

    // Clear any previous messages
    state = state.copyWith(globalError: null, successMessage: null);

    // Validate all fields first
    if (!_validateAllFields()) {
      _logger.warning('⚠️ [VENDOR-EDIT] Validation failed, cannot save');
      final validationSummary = getValidationSummary();
      _logger.warning('⚠️ [VENDOR-EDIT] Validation errors: ${validationSummary['errors']}');
      DebugLogger.warning('⚠️ [VENDOR-EDIT] Validation failed', tag: 'VendorProfileEdit');
      DebugLogger.logObject('Validation Errors', validationSummary);

      // Set a helpful error message
      final missingFields = _getMissingRequiredFields();
      if (missingFields.isNotEmpty) {
        DebugLogger.warning('⚠️ [VENDOR-EDIT] Missing required fields: ${missingFields.join(', ')}', tag: 'VendorProfileEdit');
        state = state.copyWith(
          globalError: 'Please fill in required fields: ${missingFields.join(', ')}',
        );
      } else {
        DebugLogger.warning('⚠️ [VENDOR-EDIT] Form has validation errors', tag: 'VendorProfileEdit');
        state = state.copyWith(
          globalError: 'Please fix validation errors before saving',
        );
      }
      return false;
    }

    state = state.copyWith(isSaving: true);
    DebugLogger.info('🚀 [VENDOR-EDIT] Starting save operation', tag: 'VendorProfileEdit');

    try {
      // Call the Edge Function to update vendor profile
      final updateData = _buildUpdatePayload();
      _logger.info('📤 [VENDOR-EDIT] Sending update data: ${updateData.keys.toList()}');
      DebugLogger.info('📤 [VENDOR-EDIT] Building update payload', tag: 'VendorProfileEdit');
      DebugLogger.logObject('Update Payload Keys', {'keys': updateData.keys.toList()});
      DebugLogger.logObject('Update Data Sample', {
        'businessName': updateData['business_name'],
        'businessType': updateData['business_type'],
        'cuisineTypesCount': (updateData['cuisine_types'] as List?)?.length ?? 0,
        'hasBusinessHours': updateData['business_hours'] != null,
        'hasPricingSettings': updateData['minimum_order_amount'] != null,
      });

      // Use Supabase Edge Function for secure update
      DebugLogger.info('🌐 [VENDOR-EDIT] Calling updateVendorProfileSecure Edge Function', tag: 'VendorProfileEdit');
      final response = await _vendorRepository.updateVendorProfileSecure(updateData);
      DebugLogger.info('📥 [VENDOR-EDIT] Received response from Edge Function', tag: 'VendorProfileEdit');
      DebugLogger.logObject('Response Status', {
        'success': response['success'],
        'hasData': response['data'] != null,
        'hasError': response['error'] != null,
      });

      if (response['success'] == true) {
        _logger.info('✅ [VENDOR-EDIT] Profile saved successfully');
        DebugLogger.info('✅ [VENDOR-EDIT] Profile save successful', tag: 'VendorProfileEdit');

        // Update the original vendor data to reflect the changes
        final updatedVendor = Vendor.fromJson(response['data']);
        DebugLogger.logObject('Updated Vendor', {
          'id': updatedVendor.id,
          'businessName': updatedVendor.businessName,
          'lastUpdated': DateTime.now().toIso8601String(),
        });

        state = state.copyWith(
          isSaving: false,
          hasUnsavedChanges: false,
          successMessage: 'Profile updated successfully! Your changes have been saved.',
          originalVendor: updatedVendor,
          fieldErrors: {}, // Clear any field errors on successful save
        );

        // Invalidate the current vendor provider to refresh the profile screen
        DebugLogger.info('🔄 [VENDOR-EDIT] Invalidating currentVendorProvider', tag: 'VendorProfileEdit');
        _ref.invalidate(currentVendorProvider);

        return true;
      } else {
        final errorMessage = response['error'] ?? 'Unknown error occurred';
        _logger.error('❌ [VENDOR-EDIT] Server error: $errorMessage');
        DebugLogger.error('❌ [VENDOR-EDIT] Server error: $errorMessage', tag: 'VendorProfileEdit');
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      _logger.error('❌ [VENDOR-EDIT] Failed to save profile', e, stackTrace);
      DebugLogger.error('❌ [VENDOR-EDIT] Save operation failed: $e', tag: 'VendorProfileEdit');
      DebugLogger.logObject('Error Details', {
        'errorType': e.runtimeType.toString(),
        'errorMessage': e.toString(),
        'hasStackTrace': stackTrace != null,
        'stackTraceLength': stackTrace?.toString().length ?? 0,
      });

      // Provide user-friendly error messages
      String userFriendlyError;
      if (e.toString().contains('network') || e.toString().contains('connection')) {
        userFriendlyError = 'Network error. Please check your internet connection and try again.';
        DebugLogger.warning('🌐 [VENDOR-EDIT] Network error detected', tag: 'VendorProfileEdit');
      } else if (e.toString().contains('timeout')) {
        userFriendlyError = 'Request timed out. Please try again.';
        DebugLogger.warning('⏱️ [VENDOR-EDIT] Timeout error detected', tag: 'VendorProfileEdit');
      } else if (e.toString().contains('permission') || e.toString().contains('unauthorized')) {
        userFriendlyError = 'You don\'t have permission to update this profile.';
        DebugLogger.warning('🔒 [VENDOR-EDIT] Permission error detected', tag: 'VendorProfileEdit');
      } else {
        userFriendlyError = 'Failed to save profile. Please try again or contact support if the problem persists.';
        DebugLogger.warning('❓ [VENDOR-EDIT] Unknown error type', tag: 'VendorProfileEdit');
      }

      DebugLogger.info('💬 [VENDOR-EDIT] User-friendly error: $userFriendlyError', tag: 'VendorProfileEdit');

      state = state.copyWith(
        isSaving: false,
        globalError: userFriendlyError,
      );
      return false;
    }
  }

  /// Reset form to original values
  void resetForm() {
    if (state.originalVendor != null) {
      _logger.info('🔄 [VENDOR-EDIT] Resetting form to original values');
      state = _createStateFromVendor(state.originalVendor!);
    }
  }

  /// Clear all errors
  void clearErrors() {
    state = state.copyWith(
      fieldErrors: {},
      globalError: null,
      successMessage: null,
    );
  }

  /// Clear success message
  void clearSuccessMessage() {
    state = state.copyWith(successMessage: null);
  }

  /// Clear specific field error
  void clearFieldError(String fieldName) {
    final updatedErrors = Map<String, String>.from(state.fieldErrors);
    updatedErrors.remove(fieldName);
    state = state.copyWith(fieldErrors: updatedErrors);
  }

  /// Validate specific field manually
  void validateField(String fieldName, dynamic value) {
    _validateField(fieldName, value);
  }

  /// Get validation summary
  Map<String, dynamic> getValidationSummary() {
    return {
      'hasErrors': state.fieldErrors.isNotEmpty,
      'errorCount': state.fieldErrors.length,
      'errors': state.fieldErrors,
      'isFormValid': state.isFormValid,
      'hasRequiredFields': _hasRequiredFields(),
      'missingRequiredFields': _getMissingRequiredFields(),
    };
  }

  /// Get list of missing required fields
  List<String> _getMissingRequiredFields() {
    final missing = <String>[];

    if (state.businessName.trim().isEmpty) missing.add('Business Name');
    if (state.businessRegistrationNumber.trim().isEmpty) missing.add('Registration Number');
    if (state.businessAddress.trim().isEmpty) missing.add('Business Address');
    if (state.businessType.trim().isEmpty) missing.add('Business Type');
    if (state.cuisineTypes.isEmpty) missing.add('Cuisine Types');

    return missing;
  }

  /// Manually trigger unsaved changes check
  void checkForUnsavedChanges() {
    final hasChanges = _checkForUnsavedChanges();
    if (state.hasUnsavedChanges != hasChanges) {
      state = state.copyWith(hasUnsavedChanges: hasChanges);
    }
  }

  /// Get detailed changes summary
  Map<String, dynamic> getChangesSummary() {
    final original = state.originalVendor;
    if (original == null) return {};

    final changes = <String, dynamic>{};

    if (state.businessName.trim() != original.businessName) {
      changes['businessName'] = {
        'original': original.businessName,
        'current': state.businessName.trim(),
      };
    }

    if (state.businessRegistrationNumber.trim() != original.businessRegistrationNumber) {
      changes['businessRegistrationNumber'] = {
        'original': original.businessRegistrationNumber,
        'current': state.businessRegistrationNumber.trim(),
      };
    }

    if (state.businessAddress.trim() != original.businessAddress) {
      changes['businessAddress'] = {
        'original': original.businessAddress,
        'current': state.businessAddress.trim(),
      };
    }

    if (state.businessType != original.businessType) {
      changes['businessType'] = {
        'original': original.businessType,
        'current': state.businessType,
      };
    }

    if (!_listsEqual(state.cuisineTypes, original.cuisineTypes)) {
      changes['cuisineTypes'] = {
        'original': original.cuisineTypes,
        'current': state.cuisineTypes,
      };
    }

    if (state.description.trim() != (original.description ?? '')) {
      changes['description'] = {
        'original': original.description ?? '',
        'current': state.description.trim(),
      };
    }

    if (state.minimumOrderAmount != (original.minimumOrderAmount ?? 50.0)) {
      changes['minimumOrderAmount'] = {
        'original': original.minimumOrderAmount ?? 50.0,
        'current': state.minimumOrderAmount,
      };
    }

    if (state.deliveryFee != (original.deliveryFee ?? 15.0)) {
      changes['deliveryFee'] = {
        'original': original.deliveryFee ?? 15.0,
        'current': state.deliveryFee,
      };
    }

    if (state.freeDeliveryThreshold != (original.freeDeliveryThreshold ?? 200.0)) {
      changes['freeDeliveryThreshold'] = {
        'original': original.freeDeliveryThreshold ?? 200.0,
        'current': state.freeDeliveryThreshold,
      };
    }

    return changes;
  }

  /// Discard all unsaved changes and revert to original
  void discardChanges() {
    if (state.originalVendor != null) {
      _logger.info('🔄 [VENDOR-EDIT] Discarding unsaved changes');
      state = _createStateFromVendor(state.originalVendor!);
    }
  }

  // Private helper methods
  void _updateField(String fieldName, dynamic value) {
    _logger.debug('📝 [VENDOR-EDIT] Updating field: $fieldName');

    // Clear field error when user starts typing
    final updatedErrors = Map<String, String>.from(state.fieldErrors);
    updatedErrors.remove(fieldName);

    // Check if this change makes the form dirty
    final hasChanges = _checkForUnsavedChanges();

    state = state.copyWith(
      fieldErrors: updatedErrors,
      globalError: null,
      successMessage: null,
      hasUnsavedChanges: hasChanges,
    );
  }

  /// Check if current form data differs from original vendor data
  bool _checkForUnsavedChanges() {
    final original = state.originalVendor;
    if (original == null) return false;

    // Compare all form fields with original data
    return state.businessName.trim() != original.businessName ||
           state.businessRegistrationNumber.trim() != original.businessRegistrationNumber ||
           state.businessAddress.trim() != original.businessAddress ||
           state.businessType != original.businessType ||
           !_listsEqual(state.cuisineTypes, original.cuisineTypes) ||
           state.isHalalCertified != original.isHalalCertified ||
           state.halalCertificationNumber != original.halalCertificationNumber ||
           state.description.trim() != (original.description ?? '') ||
           state.coverImageUrl != original.coverImageUrl ||
           !_listsEqual(state.galleryImages, original.galleryImages) ||
           !_mapsEqual(state.businessHours, original.businessHours ?? {}) ||
           !_listsEqual(state.serviceAreas, original.serviceAreas ?? []) ||
           state.minimumOrderAmount != (original.minimumOrderAmount ?? 50.0) ||
           state.deliveryFee != (original.deliveryFee ?? 15.0) ||
           state.freeDeliveryThreshold != (original.freeDeliveryThreshold ?? 200.0);
  }

  /// Helper method to compare lists
  bool _listsEqual<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  /// Helper method to compare maps
  bool _mapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) return false;
    }
    return true;
  }

  void _validateField(String fieldName, dynamic value) {
    final errors = Map<String, String>.from(state.fieldErrors);
    
    switch (fieldName) {
      case 'businessName':
        final nameValue = value as String?;
        if (nameValue == null || nameValue.trim().isEmpty) {
          errors[fieldName] = 'Business name is required';
        } else if (nameValue.trim().length < 2) {
          errors[fieldName] = 'Business name must be at least 2 characters';
        } else if (nameValue.trim().length > 100) {
          errors[fieldName] = 'Business name must be less than 100 characters';
        } else if (!RegExp(r"^[a-zA-Z0-9\s\-'&\.]+$").hasMatch(nameValue.trim())) {
          errors[fieldName] = 'Business name contains invalid characters';
        } else {
          errors.remove(fieldName);
        }
        break;

      case 'businessRegistrationNumber':
        final regValue = value as String?;
        if (regValue == null || regValue.trim().isEmpty) {
          errors[fieldName] = 'Business registration number is required';
        } else if (regValue.trim().length < 5) {
          errors[fieldName] = 'Registration number must be at least 5 characters';
        } else if (regValue.trim().length > 20) {
          errors[fieldName] = 'Registration number must be less than 20 characters';
        } else if (!RegExp(r'^[A-Z0-9\-]+$').hasMatch(regValue.trim().toUpperCase())) {
          errors[fieldName] = 'Registration number format is invalid';
        } else {
          errors.remove(fieldName);
        }
        break;

      case 'businessAddress':
        final addressValue = value as String?;
        if (addressValue == null || addressValue.trim().isEmpty) {
          errors[fieldName] = 'Business address is required';
        } else if (addressValue.trim().length < 10) {
          errors[fieldName] = 'Address must be at least 10 characters';
        } else if (addressValue.trim().length > 500) {
          errors[fieldName] = 'Address must be less than 500 characters';
        } else {
          errors.remove(fieldName);
        }
        break;
        
      case 'businessType':
        final validTypes = ['restaurant', 'cafe', 'food_truck', 'catering', 'bakery', 'grocery', 'other'];
        final typeValue = value as String?;
        if (typeValue == null || typeValue.isEmpty) {
          errors[fieldName] = 'Business type is required';
        } else if (!validTypes.contains(typeValue)) {
          errors[fieldName] = 'Invalid business type';
        } else {
          errors.remove(fieldName);
        }
        break;

      case 'cuisineTypes':
        final cuisineValue = value as List<String>?;
        if (cuisineValue == null || cuisineValue.isEmpty) {
          errors[fieldName] = 'At least one cuisine type must be selected';
        } else if (cuisineValue.length > 5) {
          errors[fieldName] = 'Maximum 5 cuisine types allowed';
        } else {
          errors.remove(fieldName);
        }
        break;

      case 'description':
        final descValue = value as String?;
        if (descValue != null) {
          if (descValue.trim().length > 1000) {
            errors[fieldName] = 'Description must be less than 1000 characters';
          } else if (descValue.trim().length < 10 && descValue.trim().isNotEmpty) {
            errors[fieldName] = 'Description must be at least 10 characters if provided';
          } else {
            errors.remove(fieldName);
          }
        } else {
          errors.remove(fieldName);
        }
        break;
        
      case 'minimumOrderAmount':
        final minOrderValue = value as double?;
        if (minOrderValue != null) {
          if (minOrderValue < 0) {
            errors[fieldName] = 'Minimum order amount cannot be negative';
          } else if (minOrderValue > 1000) {
            errors[fieldName] = 'Minimum order amount cannot exceed RM 1000';
          } else {
            errors.remove(fieldName);
          }
        } else {
          errors.remove(fieldName);
        }
        break;

      case 'deliveryFee':
        final deliveryFeeValue = value as double?;
        if (deliveryFeeValue != null) {
          if (deliveryFeeValue < 0) {
            errors[fieldName] = 'Delivery fee cannot be negative';
          } else if (deliveryFeeValue > 100) {
            errors[fieldName] = 'Delivery fee cannot exceed RM 100';
          } else {
            errors.remove(fieldName);
          }
        } else {
          errors.remove(fieldName);
        }
        break;

      case 'freeDeliveryThreshold':
        final thresholdValue = value as double?;
        if (thresholdValue != null) {
          if (thresholdValue < 0) {
            errors[fieldName] = 'Free delivery threshold cannot be negative';
          } else if (thresholdValue > 2000) {
            errors[fieldName] = 'Free delivery threshold cannot exceed RM 2000';
          } else if (state.minimumOrderAmount != null && thresholdValue < state.minimumOrderAmount!) {
            errors[fieldName] = 'Free delivery threshold should be higher than minimum order amount';
          } else {
            errors.remove(fieldName);
          }
        } else {
          errors.remove(fieldName);
        }
        break;
    }
    
    state = state.copyWith(
      fieldErrors: errors,
      isFormValid: errors.isEmpty && _hasRequiredFields(),
      lastValidated: DateTime.now(),
    );
  }

  /// Check if all required fields are filled
  bool _hasRequiredFields() {
    return state.businessName.trim().isNotEmpty &&
           state.businessRegistrationNumber.trim().isNotEmpty &&
           state.businessAddress.trim().isNotEmpty &&
           state.businessType.trim().isNotEmpty &&
           state.cuisineTypes.isNotEmpty;
  }

  bool _validateAllFields() {
    _validateField('businessName', state.businessName);
    _validateField('businessRegistrationNumber', state.businessRegistrationNumber);
    _validateField('businessAddress', state.businessAddress);
    _validateField('businessType', state.businessType);
    _validateField('cuisineTypes', state.cuisineTypes);
    _validateField('description', state.description);
    _validateField('minimumOrderAmount', state.minimumOrderAmount);
    _validateField('deliveryFee', state.deliveryFee);
    _validateField('freeDeliveryThreshold', state.freeDeliveryThreshold);

    return state.fieldErrors.isEmpty && _hasRequiredFields();
  }

  Map<String, dynamic> _buildUpdatePayload() {
    debugPrint('🏪 [VENDOR-PROFILE-EDIT] Building update payload');
    debugPrint('🏪 [VENDOR-PROFILE-EDIT] Business hours in state: ${state.businessHours}');

    final payload = {
      'business_name': state.businessName,
      'business_registration_number': state.businessRegistrationNumber,
      'business_address': state.businessAddress,
      'business_type': state.businessType,
      'cuisine_types': state.cuisineTypes,
      'is_halal_certified': state.isHalalCertified,
      'halal_certification_number': state.halalCertificationNumber,
      'description': state.description,
      'cover_image_url': state.coverImageUrl,
      'gallery_images': state.galleryImages,
      'business_hours': state.businessHours,
      'service_areas': state.serviceAreas,
      'minimum_order_amount': state.minimumOrderAmount,
      'delivery_fee': state.deliveryFee,
      'free_delivery_threshold': state.freeDeliveryThreshold,
    };

    debugPrint('🏪 [VENDOR-PROFILE-EDIT] Final payload business_hours: ${payload['business_hours']}');
    return payload;
  }

  VendorProfileEditState _createStateFromVendor(Vendor vendor) {
    _logger.info('🍽️ [VENDOR-EDIT] Creating state from vendor with cuisine types: ${vendor.cuisineTypes}');
    return VendorProfileEditState(
      businessName: vendor.businessName,
      businessRegistrationNumber: vendor.businessRegistrationNumber,
      businessAddress: vendor.businessAddress,
      businessType: vendor.businessType,
      cuisineTypes: vendor.cuisineTypes,
      isHalalCertified: vendor.isHalalCertified,
      halalCertificationNumber: vendor.halalCertificationNumber,
      description: vendor.description ?? '',
      coverImageUrl: vendor.coverImageUrl,
      galleryImages: vendor.galleryImages,
      businessHours: vendor.businessHours ?? {},
      serviceAreas: vendor.serviceAreas ?? [],
      minimumOrderAmount: vendor.minimumOrderAmount ?? 50.0,
      deliveryFee: vendor.deliveryFee ?? 15.0,
      freeDeliveryThreshold: vendor.freeDeliveryThreshold ?? 200.0,
      isLoading: false,
      originalVendor: vendor,
      hasUnsavedChanges: false,
      isFormValid: true,
    );
  }

  void _setError(String error) {
    state = state.copyWith(
      isLoading: false,
      isSaving: false,
      globalError: error,
    );
  }
}

/// Image upload notifier for cover photo and gallery
class ImageUploadNotifier extends StateNotifier<ImageUploadState> {
  final FileUploadService _fileUploadService;
  final String _userId;

  ImageUploadNotifier({
    required FileUploadService fileUploadService,
    required String userId,
  }) : _fileUploadService = fileUploadService,
       _userId = userId,
       super(const ImageUploadState());

  /// Upload cover image
  Future<String?> uploadCoverImage(XFile imageFile) async {
    _logger.info('📸 [IMAGE-UPLOAD] Uploading cover image...');

    state = state.copyWith(
      isUploading: true,
      progress: 0.0,
      status: 'Preparing image...',
      error: null,
    );

    try {
      state = state.copyWith(progress: 0.2, status: 'Compressing image...');

      // Upload using the existing file upload service
      final imageUrl = await _fileUploadService.uploadVendorCoverImage(_userId, imageFile);

      state = state.copyWith(
        progress: 1.0,
        status: 'Upload complete!',
        uploadedUrl: imageUrl,
      );

      // Clear state after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          state = const ImageUploadState();
        }
      });

      _logger.info('✅ [IMAGE-UPLOAD] Cover image uploaded successfully');
      return imageUrl;
    } catch (e, stackTrace) {
      _logger.error('❌ [IMAGE-UPLOAD] Failed to upload cover image', e, stackTrace);
      state = state.copyWith(
        isUploading: false,
        error: 'Failed to upload image: $e',
      );
      return null;
    }
  }

  /// Upload gallery image
  Future<String?> uploadGalleryImage(XFile imageFile) async {
    _logger.info('🖼️ [IMAGE-UPLOAD] Uploading gallery image...');

    state = state.copyWith(
      isUploading: true,
      progress: 0.0,
      status: 'Preparing image...',
      error: null,
    );

    try {
      state = state.copyWith(progress: 0.2, status: 'Compressing image...');

      // Upload using the existing file upload service
      final imageUrl = await _fileUploadService.uploadMenuItemImage(_userId, 'gallery', imageFile);

      state = state.copyWith(
        progress: 1.0,
        status: 'Upload complete!',
        uploadedUrl: imageUrl,
      );

      // Clear state after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          state = const ImageUploadState();
        }
      });

      _logger.info('✅ [IMAGE-UPLOAD] Gallery image uploaded successfully');
      return imageUrl;
    } catch (e, stackTrace) {
      _logger.error('❌ [IMAGE-UPLOAD] Failed to upload gallery image', e, stackTrace);
      state = state.copyWith(
        isUploading: false,
        error: 'Failed to upload image: $e',
      );
      return null;
    }
  }

  /// Clear upload state
  void clearState() {
    state = const ImageUploadState();
  }
}

/// Business hours edit notifier
class BusinessHoursEditNotifier extends StateNotifier<BusinessHoursEditState> {
  BusinessHoursEditNotifier() : super(const BusinessHoursEditState());

  /// Initialize business hours
  void initializeHours(Map<String, dynamic> hours) {
    state = state.copyWith(hours: hours, hasChanges: false);
  }

  /// Update hours for a specific day
  void updateDayHours(String day, bool isOpen, String? openTime, String? closeTime) {
    final updatedHours = Map<String, dynamic>.from(state.hours);
    updatedHours[day] = {
      'is_open': isOpen,
      'open': openTime,
      'close': closeTime,
    };

    // Validate the time format
    final errors = Map<String, String>.from(state.errors);
    if (isOpen) {
      if (openTime == null || !_isValidTimeFormat(openTime)) {
        errors['${day}_open'] = 'Invalid open time format';
      } else {
        errors.remove('${day}_open');
      }

      if (closeTime == null || !_isValidTimeFormat(closeTime)) {
        errors['${day}_close'] = 'Invalid close time format';
      } else {
        errors.remove('${day}_close');
      }
    } else {
      errors.remove('${day}_open');
      errors.remove('${day}_close');
    }

    state = state.copyWith(
      hours: updatedHours,
      hasChanges: true,
      errors: errors,
    );
  }

  /// Copy hours from one day to another
  void copyHours(String fromDay, String toDay) {
    if (state.hours.containsKey(fromDay)) {
      final fromHours = state.hours[fromDay];
      final updatedHours = Map<String, dynamic>.from(state.hours);
      updatedHours[toDay] = Map<String, dynamic>.from(fromHours);

      state = state.copyWith(
        hours: updatedHours,
        hasChanges: true,
      );
    }
  }

  /// Apply same hours to multiple days
  void applyToMultipleDays(List<String> days, bool isOpen, String? openTime, String? closeTime) {
    final updatedHours = Map<String, dynamic>.from(state.hours);
    final errors = Map<String, String>.from(state.errors);

    for (final day in days) {
      updatedHours[day] = {
        'is_open': isOpen,
        'open': openTime,
        'close': closeTime,
      };

      // Clear any existing errors for these days
      errors.remove('${day}_open');
      errors.remove('${day}_close');
    }

    state = state.copyWith(
      hours: updatedHours,
      hasChanges: true,
      errors: errors,
    );
  }

  /// Validate all business hours
  bool validateAllHours() {
    final errors = <String, String>{};

    for (final entry in state.hours.entries) {
      final day = entry.key;
      final dayHours = entry.value as Map<String, dynamic>;

      if (dayHours['is_open'] == true) {
        final openTime = dayHours['open'] as String?;
        final closeTime = dayHours['close'] as String?;

        if (openTime == null || !_isValidTimeFormat(openTime)) {
          errors['${day}_open'] = 'Invalid open time format';
        }

        if (closeTime == null || !_isValidTimeFormat(closeTime)) {
          errors['${day}_close'] = 'Invalid close time format';
        }
      }
    }

    state = state.copyWith(errors: errors);
    return errors.isEmpty;
  }

  /// Reset changes
  void resetChanges() {
    state = state.copyWith(hasChanges: false, errors: {});
  }

  bool _isValidTimeFormat(String time) {
    final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    return timeRegex.hasMatch(time);
  }
}

// ============================================================================
// PROVIDER DEFINITIONS
// ============================================================================

/// Main vendor profile edit provider
final vendorProfileEditProvider = StateNotifierProvider<VendorProfileEditNotifier, VendorProfileEditState>((ref) {
  final vendorRepository = ref.watch(vendorRepositoryProvider);

  return VendorProfileEditNotifier(
    vendorRepository: vendorRepository,
    ref: ref,
  );
});

/// Image upload provider
final imageUploadProvider = StateNotifierProvider<ImageUploadNotifier, ImageUploadState>((ref) {
  final authState = ref.watch(authStateProvider);
  final fileUploadService = ref.watch(fileUploadServiceProvider);

  return ImageUploadNotifier(
    fileUploadService: fileUploadService,
    userId: authState.user?.id ?? '',
  );
});

/// Business hours edit provider
final businessHoursEditProvider = StateNotifierProvider<BusinessHoursEditNotifier, BusinessHoursEditState>((ref) {
  return BusinessHoursEditNotifier();
});

// ============================================================================
// COMPUTED PROVIDERS
// ============================================================================

/// Check if form has validation errors
final hasValidationErrorsProvider = Provider<bool>((ref) {
  final editState = ref.watch(vendorProfileEditProvider);
  return editState.fieldErrors.isNotEmpty;
});

/// Get specific field error
final fieldErrorProvider = Provider.family<String?, String>((ref, fieldName) {
  final editState = ref.watch(vendorProfileEditProvider);
  return editState.fieldErrors[fieldName];
});

/// Check if specific field has error
final fieldHasErrorProvider = Provider.family<bool, String>((ref, fieldName) {
  final editState = ref.watch(vendorProfileEditProvider);
  return editState.fieldErrors.containsKey(fieldName);
});

/// Get validation summary
final validationSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  final notifier = ref.read(vendorProfileEditProvider.notifier);
  return notifier.getValidationSummary();
});

/// Check if form can be saved (no errors and has required fields)
final canSaveFormProvider = Provider<bool>((ref) {
  final editState = ref.watch(vendorProfileEditProvider);
  return editState.isFormValid &&
         editState.hasUnsavedChanges &&
         !editState.isSaving &&
         !editState.isLoading;
});

/// Check if form has unsaved changes
final formIsDirtyProvider = Provider<bool>((ref) {
  final editState = ref.watch(vendorProfileEditProvider);
  return editState.hasUnsavedChanges;
});

/// Get error count
final errorCountProvider = Provider<int>((ref) {
  final editState = ref.watch(vendorProfileEditProvider);
  return editState.fieldErrors.length;
});

/// Check if form is currently saving
final isSavingProvider = Provider<bool>((ref) {
  final editState = ref.watch(vendorProfileEditProvider);
  return editState.isSaving;
});

/// Get success message
final successMessageProvider = Provider<String?>((ref) {
  final editState = ref.watch(vendorProfileEditProvider);
  return editState.successMessage;
});

/// Get global error message
final globalErrorProvider = Provider<String?>((ref) {
  final editState = ref.watch(vendorProfileEditProvider);
  return editState.globalError;
});

/// Get changes summary
final changesSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  final notifier = ref.read(vendorProfileEditProvider.notifier);
  return notifier.getChangesSummary();
});

/// Check if specific field has unsaved changes
final fieldHasChangesProvider = Provider.family<bool, String>((ref, fieldName) {
  final changes = ref.watch(changesSummaryProvider);
  return changes.containsKey(fieldName);
});

/// Get count of changed fields
final changedFieldsCountProvider = Provider<int>((ref) {
  final changes = ref.watch(changesSummaryProvider);
  return changes.length;
});

/// Check if form can be discarded (has unsaved changes)
final canDiscardChangesProvider = Provider<bool>((ref) {
  final editState = ref.watch(vendorProfileEditProvider);
  return editState.hasUnsavedChanges && !editState.isSaving;
});



// File upload service provider (if not already defined)
final fileUploadServiceProvider = Provider<FileUploadService>((ref) {
  return FileUploadService();
});
