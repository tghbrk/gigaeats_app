import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/vendor.dart';
import '../../data/repositories/vendor_repository.dart';
import 'vendor_repository_providers.dart';
import '../../../../presentation/providers/repository_providers.dart' show vendorDashboardMetricsProvider;
import '../../../../core/services/file_upload_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Vendor Profile Form State
class VendorProfileFormState {
  final String? id;
  final String businessName;
  final String businessRegistrationNumber;
  final String businessAddress;
  final String businessType;
  final List<String> cuisineTypes;
  final bool isHalalCertified;
  final String? halalCertificationNumber;
  final String? description;
  final String? coverImageUrl;
  final List<String> galleryImages;
  final Map<String, dynamic>? businessHours;
  final List<String> serviceAreas;
  final double? minimumOrderAmount;
  final double? deliveryFee;
  final double? freeDeliveryThreshold;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  const VendorProfileFormState({
    this.id,
    this.businessName = '',
    this.businessRegistrationNumber = '',
    this.businessAddress = '',
    this.businessType = '',
    this.cuisineTypes = const [],
    this.isHalalCertified = false,
    this.halalCertificationNumber,
    this.description,
    this.coverImageUrl,
    this.galleryImages = const [],
    this.businessHours,
    this.serviceAreas = const [],
    this.minimumOrderAmount,
    this.deliveryFee,
    this.freeDeliveryThreshold,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  VendorProfileFormState copyWith({
    String? id,
    String? businessName,
    String? businessRegistrationNumber,
    String? businessAddress,
    String? businessType,
    List<String>? cuisineTypes,
    bool? isHalalCertified,
    String? halalCertificationNumber,
    String? description,
    String? coverImageUrl,
    List<String>? galleryImages,
    Map<String, dynamic>? businessHours,
    List<String>? serviceAreas,
    double? minimumOrderAmount,
    double? deliveryFee,
    double? freeDeliveryThreshold,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
  }) {
    return VendorProfileFormState(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      businessRegistrationNumber: businessRegistrationNumber ?? this.businessRegistrationNumber,
      businessAddress: businessAddress ?? this.businessAddress,
      businessType: businessType ?? this.businessType,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      isHalalCertified: isHalalCertified ?? this.isHalalCertified,
      halalCertificationNumber: halalCertificationNumber ?? this.halalCertificationNumber,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      businessHours: businessHours ?? this.businessHours,
      serviceAreas: serviceAreas ?? this.serviceAreas,
      minimumOrderAmount: minimumOrderAmount ?? this.minimumOrderAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      freeDeliveryThreshold: freeDeliveryThreshold ?? this.freeDeliveryThreshold,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  bool get isValid {
    return businessName.isNotEmpty &&
           businessRegistrationNumber.isNotEmpty &&
           businessAddress.isNotEmpty &&
           businessType.isNotEmpty &&
           cuisineTypes.isNotEmpty;
  }

  Vendor toVendor({required String userId}) {
    return Vendor(
      id: id ?? '',
      userId: userId,
      businessName: businessName,
      businessRegistrationNumber: businessRegistrationNumber,
      businessAddress: businessAddress,
      businessType: businessType,
      cuisineTypes: cuisineTypes,
      isHalalCertified: isHalalCertified,
      halalCertificationNumber: halalCertificationNumber,
      description: description,
      coverImageUrl: coverImageUrl,
      galleryImages: galleryImages,
      businessHours: businessHours,
      serviceAreas: serviceAreas,
      minimumOrderAmount: minimumOrderAmount,
      deliveryFee: deliveryFee,
      freeDeliveryThreshold: freeDeliveryThreshold,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static VendorProfileFormState fromVendor(Vendor vendor) {
    return VendorProfileFormState(
      id: vendor.id,
      businessName: vendor.businessName,
      businessRegistrationNumber: vendor.businessRegistrationNumber,
      businessAddress: vendor.businessAddress,
      businessType: vendor.businessType,
      cuisineTypes: vendor.cuisineTypes,
      isHalalCertified: vendor.isHalalCertified,
      halalCertificationNumber: vendor.halalCertificationNumber,
      description: vendor.description,
      coverImageUrl: vendor.coverImageUrl,
      galleryImages: vendor.galleryImages,
      businessHours: vendor.businessHours,
      serviceAreas: vendor.serviceAreas ?? [],
      minimumOrderAmount: vendor.minimumOrderAmount,
      deliveryFee: vendor.deliveryFee,
      freeDeliveryThreshold: vendor.freeDeliveryThreshold,
    );
  }
}

// File Upload Service Provider
final fileUploadServiceProvider = Provider<FileUploadService>((ref) {
  return FileUploadService();
});

// Vendor Profile Form Provider
final vendorProfileFormProvider = StateNotifierProvider<VendorProfileFormNotifier, VendorProfileFormState>((ref) {
  final vendorRepository = ref.watch(vendorRepositoryProvider);
  final fileUploadService = ref.watch(fileUploadServiceProvider);
  final authState = ref.watch(authStateProvider);

  return VendorProfileFormNotifier(
    vendorRepository: vendorRepository,
    fileUploadService: fileUploadService,
    userId: authState.user?.id,
    ref: ref,
  );
});

// Current Vendor Profile Provider
final currentVendorProfileProvider = FutureProvider<Vendor?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final vendorRepository = ref.watch(vendorRepositoryProvider);
  
  if (authState.user?.id == null) return null;
  
  try {
    return await vendorRepository.getVendorByUserId(authState.user!.id);
  } catch (e) {
    debugPrint('Error loading current vendor profile: $e');
    return null;
  }
});

// Vendor Profile Form Notifier
class VendorProfileFormNotifier extends StateNotifier<VendorProfileFormState> {
  final VendorRepository _vendorRepository;
  final FileUploadService _fileUploadService;
  final String? _userId;
  final Ref _ref;

  VendorProfileFormNotifier({
    required VendorRepository vendorRepository,
    required FileUploadService fileUploadService,
    required String? userId,
    required Ref ref,
  }) : _vendorRepository = vendorRepository,
       _fileUploadService = fileUploadService,
       _userId = userId,
       _ref = ref,
       super(const VendorProfileFormState());

  void updateBusinessName(String value) {
    state = state.copyWith(businessName: value, errorMessage: null);
  }

  void updateBusinessRegistrationNumber(String value) {
    state = state.copyWith(businessRegistrationNumber: value, errorMessage: null);
  }

  void updateBusinessAddress(String value) {
    state = state.copyWith(businessAddress: value, errorMessage: null);
  }

  void updateBusinessType(String value) {
    state = state.copyWith(businessType: value, errorMessage: null);
  }

  void updateCuisineTypes(List<String> value) {
    state = state.copyWith(cuisineTypes: value, errorMessage: null);
  }

  void updateIsHalalCertified(bool value) {
    state = state.copyWith(
      isHalalCertified: value,
      halalCertificationNumber: value ? state.halalCertificationNumber : null,
      errorMessage: null,
    );
  }

  void updateHalalCertificationNumber(String? value) {
    state = state.copyWith(halalCertificationNumber: value, errorMessage: null);
  }

  void updateDescription(String? value) {
    state = state.copyWith(description: value, errorMessage: null);
  }

  void updateBusinessHours(Map<String, dynamic> value) {
    state = state.copyWith(businessHours: value, errorMessage: null);
  }

  void updateServiceAreas(List<String> value) {
    state = state.copyWith(serviceAreas: value, errorMessage: null);
  }

  void updateMinimumOrderAmount(double? value) {
    state = state.copyWith(minimumOrderAmount: value, errorMessage: null);
  }

  void updateDeliveryFee(double? value) {
    state = state.copyWith(deliveryFee: value, errorMessage: null);
  }

  void updateFreeDeliveryThreshold(double? value) {
    state = state.copyWith(freeDeliveryThreshold: value, errorMessage: null);
  }

  // Load existing vendor profile for editing
  Future<void> loadVendorProfile(String vendorId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final vendor = await _vendorRepository.getVendorById(vendorId);
      if (vendor != null) {
        state = VendorProfileFormState.fromVendor(vendor);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Vendor profile not found',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load vendor profile: $e',
      );
    }
  }

  // Load current user's vendor profile
  Future<void> loadCurrentVendorProfile() async {
    if (_userId == null) {
      state = state.copyWith(errorMessage: 'User not authenticated');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final vendor = await _vendorRepository.getVendorByUserId(_userId);
      if (vendor != null) {
        state = VendorProfileFormState.fromVendor(vendor);
      } else {
        // No existing profile, keep empty form
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load vendor profile: $e',
      );
    }
  }

  // Upload cover image
  Future<void> uploadCoverImage(XFile imageFile) async {
    if (_userId == null) {
      state = state.copyWith(errorMessage: 'User not authenticated');
      return;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final imageUrl = await _fileUploadService.uploadVendorCoverImage(_userId, imageFile);
      state = state.copyWith(
        coverImageUrl: imageUrl,
        isSaving: false,
        successMessage: 'Cover image uploaded successfully',
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to upload cover image: $e',
      );
    }
  }

  // Add gallery image
  Future<void> addGalleryImage(XFile imageFile) async {
    if (_userId == null) {
      state = state.copyWith(errorMessage: 'User not authenticated');
      return;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final imageUrl = await _fileUploadService.uploadFile(
        imageFile,
        bucketName: 'user-uploads',
        fileName: 'gallery_${_userId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        folderPath: 'vendor-gallery',
      );

      final updatedGallery = [...state.galleryImages, imageUrl];
      state = state.copyWith(
        galleryImages: updatedGallery,
        isSaving: false,
        successMessage: 'Gallery image added successfully',
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to upload gallery image: $e',
      );
    }
  }

  // Remove gallery image
  void removeGalleryImage(String imageUrl) {
    final updatedGallery = state.galleryImages.where((url) => url != imageUrl).toList();
    state = state.copyWith(galleryImages: updatedGallery);
  }

  // Save vendor profile
  Future<bool> saveProfile() async {
    if (_userId == null) {
      state = state.copyWith(errorMessage: 'User not authenticated');
      return false;
    }

    if (!state.isValid) {
      state = state.copyWith(errorMessage: 'Please fill in all required fields');
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final vendor = state.toVendor(userId: _userId);
      await _vendorRepository.upsertVendor(vendor);

      // Invalidate all vendor-related providers to refresh cached data
      _invalidateVendorProviders();

      state = state.copyWith(
        isSaving: false,
        successMessage: 'Vendor profile saved successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save vendor profile: $e',
      );
      return false;
    }
  }

  // Helper method to invalidate vendor-related providers
  void _invalidateVendorProviders() {
    // Invalidate current vendor providers to force refresh
    _ref.invalidate(currentVendorProfileProvider);

    // Also invalidate the main currentVendorProvider from repository_providers.dart
    _ref.invalidate(currentVendorProvider);

    // Invalidate dashboard metrics that depend on vendor data
    _ref.invalidate(vendorDashboardMetricsProvider);
  }

  // Delete vendor profile
  Future<bool> deleteProfile() async {
    if (_userId == null || state.id == null) {
      state = state.copyWith(errorMessage: 'Cannot delete profile');
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      await _vendorRepository.deleteVendor(state.id!);

      // Reset form state
      state = const VendorProfileFormState(
        successMessage: 'Vendor profile deleted successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to delete vendor profile: $e',
      );
      return false;
    }
  }

  // Clear messages
  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  // Reset form
  void resetForm() {
    state = const VendorProfileFormState();
  }
}
