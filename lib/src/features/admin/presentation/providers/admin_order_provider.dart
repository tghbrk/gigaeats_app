import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/admin_repository.dart';

// ============================================================================
// ADMIN ORDER STATE
// ============================================================================

/// State for admin order management
class AdminOrderState {
  final List<Map<String, dynamic>> orders;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final String? selectedStatus;
  final String? selectedVendorId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String sortBy;
  final bool ascending;
  final int currentPage;
  final bool hasMore;

  const AdminOrderState({
    this.orders = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedStatus,
    this.selectedVendorId,
    this.startDate,
    this.endDate,
    this.sortBy = 'created_at',
    this.ascending = false,
    this.currentPage = 0,
    this.hasMore = true,
  });

  AdminOrderState copyWith({
    List<Map<String, dynamic>>? orders,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? selectedStatus,
    String? selectedVendorId,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    bool? ascending,
    int? currentPage,
    bool? hasMore,
  }) {
    return AdminOrderState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedVendorId: selectedVendorId ?? this.selectedVendorId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// ============================================================================
// ADMIN ORDER NOTIFIER
// ============================================================================

/// Notifier for admin order management
class AdminOrderNotifier extends StateNotifier<AdminOrderState> {
  final AdminRepository _repository;

  AdminOrderNotifier(this._repository) : super(const AdminOrderState());

  /// Load orders with current filters
  Future<void> loadOrders({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final orders = await _repository.getOrdersForAdmin(
        searchQuery: state.searchQuery.isEmpty ? null : state.searchQuery,
        status: state.selectedStatus,
        vendorId: state.selectedVendorId,
        startDate: state.startDate,
        endDate: state.endDate,
        sortBy: state.sortBy,
        ascending: state.ascending,
        limit: 50,
        offset: refresh ? 0 : state.currentPage * 50,
      );

      if (refresh || state.currentPage == 0) {
        state = state.copyWith(
          orders: orders,
          isLoading: false,
          hasMore: orders.length == 50,
          currentPage: 0,
        );
      } else {
        state = state.copyWith(
          orders: [...state.orders, ...orders],
          isLoading: false,
          hasMore: orders.length == 50,
        );
      }
    } catch (e) {
      debugPrint('🔍 AdminOrderNotifier: Error loading orders: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Load more orders (pagination)
  Future<void> loadMoreOrders() async {
    if (!state.hasMore || state.isLoading) return;

    state = state.copyWith(currentPage: state.currentPage + 1);
    await loadOrders();
  }

  /// Update search query
  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, currentPage: 0);
    loadOrders(refresh: true);
  }

  /// Update status filter
  void updateStatusFilter(String? status) {
    state = state.copyWith(selectedStatus: status, currentPage: 0);
    loadOrders(refresh: true);
  }

  /// Update vendor filter
  void updateVendorFilter(String? vendorId) {
    state = state.copyWith(selectedVendorId: vendorId, currentPage: 0);
    loadOrders(refresh: true);
  }

  /// Update date range filter
  void updateDateRangeFilter(DateTime? startDate, DateTime? endDate) {
    state = state.copyWith(startDate: startDate, endDate: endDate, currentPage: 0);
    loadOrders(refresh: true);
  }

  /// Update sorting
  void updateSorting(String sortBy, bool ascending) {
    state = state.copyWith(sortBy: sortBy, ascending: ascending, currentPage: 0);
    loadOrders(refresh: true);
  }

  /// Update order status
  Future<void> updateOrderStatus(
    String orderId,
    String newStatus, {
    String? adminNotes,
    int? priorityLevel,
  }) async {
    try {
      await _repository.updateOrderStatus(
        orderId,
        newStatus,
        adminNotes: adminNotes,
        priorityLevel: priorityLevel,
      );
      
      // Update local state
      final updatedOrders = state.orders.map((order) {
        if (order['id'] == orderId) {
          return {
            ...order,
            'status': newStatus,
            'admin_notes': adminNotes ?? order['admin_notes'],
            'priority_level': priorityLevel ?? order['priority_level'],
            'updated_at': DateTime.now().toIso8601String(),
          };
        }
        return order;
      }).toList();

      state = state.copyWith(orders: updatedOrders);
    } catch (e) {
      debugPrint('🔍 AdminOrderNotifier: Error updating order status: $e');
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  /// Process order refund
  Future<void> processOrderRefund(
    String orderId,
    double refundAmount,
    String refundReason,
  ) async {
    try {
      await _repository.processOrderRefund(orderId, refundAmount, refundReason);
      
      // Update local state
      final updatedOrders = state.orders.map((order) {
        if (order['id'] == orderId) {
          return {
            ...order,
            'refund_amount': refundAmount,
            'refund_reason': refundReason,
            'refunded_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };
        }
        return order;
      }).toList();

      state = state.copyWith(orders: updatedOrders);
    } catch (e) {
      debugPrint('🔍 AdminOrderNotifier: Error processing refund: $e');
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

/// Admin order management provider
final adminOrderProvider = StateNotifierProvider<AdminOrderNotifier, AdminOrderState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return AdminOrderNotifier(repository);
});

/// Admin order details provider
final adminOrderDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, orderId) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getOrderDetailsForAdmin(orderId);
});

/// Admin order analytics provider
final adminOrderAnalyticsProvider = FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getOrderAnalytics(
    startDate: params['startDate'] as DateTime?,
    endDate: params['endDate'] as DateTime?,
    limit: params['limit'] as int? ?? 30,
  );
});

/// Admin repository provider (from admin_providers.dart)
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});
