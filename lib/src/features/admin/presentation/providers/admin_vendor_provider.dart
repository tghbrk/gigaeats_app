import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/admin_repository.dart';


// ============================================================================
// ADMIN VENDOR STATE
// ============================================================================

/// State for admin vendor management
class AdminVendorState {
  final List<Map<String, dynamic>> vendors;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final String? selectedVerificationStatus;
  final bool? isActiveFilter;
  final String sortBy;
  final bool ascending;
  final int currentPage;
  final bool hasMore;

  const AdminVendorState({
    this.vendors = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedVerificationStatus,
    this.isActiveFilter,
    this.sortBy = 'created_at',
    this.ascending = false,
    this.currentPage = 0,
    this.hasMore = true,
  });

  AdminVendorState copyWith({
    List<Map<String, dynamic>>? vendors,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? selectedVerificationStatus,
    bool? isActiveFilter,
    String? sortBy,
    bool? ascending,
    int? currentPage,
    bool? hasMore,
  }) {
    return AdminVendorState(
      vendors: vendors ?? this.vendors,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedVerificationStatus: selectedVerificationStatus ?? this.selectedVerificationStatus,
      isActiveFilter: isActiveFilter ?? this.isActiveFilter,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// ============================================================================
// ADMIN VENDOR NOTIFIER
// ============================================================================

/// Notifier for admin vendor management
class AdminVendorNotifier extends StateNotifier<AdminVendorState> {
  final AdminRepository _repository;

  AdminVendorNotifier(this._repository) : super(const AdminVendorState());

  /// Load vendors with current filters
  Future<void> loadVendors({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final vendors = await _repository.getVendorsForAdmin(
        searchQuery: state.searchQuery.isEmpty ? null : state.searchQuery,
        verificationStatus: state.selectedVerificationStatus,
        isActive: state.isActiveFilter,
        sortBy: state.sortBy,
        ascending: state.ascending,
        limit: 50,
        offset: refresh ? 0 : state.currentPage * 50,
      );

      if (refresh || state.currentPage == 0) {
        state = state.copyWith(
          vendors: vendors,
          isLoading: false,
          hasMore: vendors.length == 50,
          currentPage: 0,
        );
      } else {
        state = state.copyWith(
          vendors: [...state.vendors, ...vendors],
          isLoading: false,
          hasMore: vendors.length == 50,
        );
      }
    } catch (e) {
      debugPrint('🔍 AdminVendorNotifier: Error loading vendors: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Load more vendors (pagination)
  Future<void> loadMoreVendors() async {
    if (!state.hasMore || state.isLoading) return;

    state = state.copyWith(currentPage: state.currentPage + 1);
    await loadVendors();
  }

  /// Update search query
  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, currentPage: 0);
    loadVendors(refresh: true);
  }

  /// Update verification status filter
  void updateVerificationStatusFilter(String? status) {
    state = state.copyWith(selectedVerificationStatus: status, currentPage: 0);
    loadVendors(refresh: true);
  }

  /// Update active status filter
  void updateActiveStatusFilter(bool? isActive) {
    state = state.copyWith(isActiveFilter: isActive, currentPage: 0);
    loadVendors(refresh: true);
  }

  /// Update sorting
  void updateSorting(String sortBy, bool ascending) {
    state = state.copyWith(sortBy: sortBy, ascending: ascending, currentPage: 0);
    loadVendors(refresh: true);
  }

  /// Approve vendor
  Future<void> approveVendor(String vendorId, {String? adminNotes}) async {
    try {
      await _repository.approveVendor(vendorId, adminNotes: adminNotes);
      
      // Update local state
      final updatedVendors = state.vendors.map((vendor) {
        if (vendor['id'] == vendorId) {
          return {
            ...vendor,
            'verification_status': 'approved',
            'is_verified': true,
            'admin_notes': adminNotes,
          };
        }
        return vendor;
      }).toList();

      state = state.copyWith(vendors: updatedVendors);
    } catch (e) {
      debugPrint('🔍 AdminVendorNotifier: Error approving vendor: $e');
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  /// Reject vendor
  Future<void> rejectVendor(String vendorId, String rejectionReason, {String? adminNotes}) async {
    try {
      await _repository.rejectVendor(vendorId, rejectionReason, adminNotes: adminNotes);
      
      // Update local state
      final updatedVendors = state.vendors.map((vendor) {
        if (vendor['id'] == vendorId) {
          return {
            ...vendor,
            'verification_status': 'rejected',
            'is_verified': false,
            'rejection_reason': rejectionReason,
            'admin_notes': adminNotes,
          };
        }
        return vendor;
      }).toList();

      state = state.copyWith(vendors: updatedVendors);
    } catch (e) {
      debugPrint('🔍 AdminVendorNotifier: Error rejecting vendor: $e');
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  /// Toggle vendor status
  Future<void> toggleVendorStatus(String vendorId, bool isActive) async {
    try {
      await _repository.toggleVendorStatus(vendorId, isActive);
      
      // Update local state
      final updatedVendors = state.vendors.map((vendor) {
        if (vendor['id'] == vendorId) {
          return {
            ...vendor,
            'is_active': isActive,
          };
        }
        return vendor;
      }).toList();

      state = state.copyWith(vendors: updatedVendors);
    } catch (e) {
      debugPrint('🔍 AdminVendorNotifier: Error toggling vendor status: $e');
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Admin vendor management provider
final adminVendorProvider = StateNotifierProvider<AdminVendorNotifier, AdminVendorState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return AdminVendorNotifier(repository);
});

/// Admin vendor details provider
final adminVendorDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, vendorId) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getVendorDetailsForAdmin(vendorId);
});

/// Admin repository provider (from admin_providers.dart)
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});
