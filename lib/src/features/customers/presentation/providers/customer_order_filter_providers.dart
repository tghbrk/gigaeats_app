import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/customer_order_history_models.dart';

/// Provider for current customer order filter state
final customerOrderFilterProvider = StateNotifierProvider<CustomerOrderFilterNotifier, CustomerOrderFilterState>((ref) {
  return CustomerOrderFilterNotifier();
});

/// State notifier for managing customer order filter state
class CustomerOrderFilterNotifier extends StateNotifier<CustomerOrderFilterState> {
  static const String _filterKey = 'customer_order_filter';
  
  CustomerOrderFilterNotifier() : super(CustomerOrderFilterState.initial()) {
    _loadSavedFilter();
  }

  /// Load saved filter from SharedPreferences
  Future<void> _loadSavedFilter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filterJson = prefs.getString(_filterKey);
      
      if (filterJson != null) {
        // Parse saved filter (implement JSON parsing if needed)
        debugPrint('🛒 Filter: Loaded saved filter from preferences');
      }
    } catch (e) {
      debugPrint('🛒 Filter: Error loading saved filter: $e');
    }
  }

  /// Save current filter to SharedPreferences
  Future<void> _saveFilter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Save filter as JSON (implement JSON serialization if needed)
      await prefs.setString(_filterKey, state.filter.toJson().toString());
      debugPrint('🛒 Filter: Saved filter to preferences');
    } catch (e) {
      debugPrint('🛒 Filter: Error saving filter: $e');
    }
  }

  /// Update the date range filter
  void updateDateRange({DateTime? startDate, DateTime? endDate}) {
    final newFilter = state.filter.copyWith(
      startDate: startDate,
      endDate: endDate,
      offset: 0, // Reset to first page when filter changes
    );
    
    state = state.copyWith(
      filter: newFilter,
      hasUnsavedChanges: true,
    );
    
    debugPrint('🛒 Filter: Updated date range - start: $startDate, end: $endDate');
  }

  /// Update the status filter
  void updateStatusFilter(CustomerOrderFilterStatus? statusFilter) {
    final newFilter = state.filter.copyWith(
      statusFilter: statusFilter,
      offset: 0, // Reset to first page when filter changes
    );
    
    state = state.copyWith(
      filter: newFilter,
      hasUnsavedChanges: true,
    );
    
    debugPrint('🛒 Filter: Updated status filter to: $statusFilter');
  }

  /// Apply a quick date filter
  void applyQuickFilter(CustomerQuickDateFilter quickFilter) {
    final dateRangeFilter = quickFilter.toDateRangeFilter();
    
    state = state.copyWith(
      filter: dateRangeFilter,
      selectedQuickFilter: quickFilter,
      hasUnsavedChanges: true,
    );
    
    debugPrint('🛒 Filter: Applied quick filter: ${quickFilter.displayName}');
  }

  /// Update pagination settings
  void updatePagination({int? limit, int? offset}) {
    final newFilter = state.filter.copyWith(
      limit: limit,
      offset: offset,
    );
    
    state = state.copyWith(filter: newFilter);
    
    debugPrint('🛒 Filter: Updated pagination - limit: $limit, offset: $offset');
  }

  /// Reset filter to default values
  void resetFilter() {
    state = CustomerOrderFilterState.initial();
    debugPrint('🛒 Filter: Reset to default values');
  }

  /// Apply and save the current filter
  Future<void> applyFilter() async {
    state = state.copyWith(
      hasUnsavedChanges: false,
      isApplied: true,
    );
    
    await _saveFilter();
    debugPrint('🛒 Filter: Applied and saved filter');
  }

  /// Clear all filters
  void clearFilters() {
    state = CustomerOrderFilterState(
      filter: const CustomerDateRangeFilter(),
      selectedQuickFilter: CustomerQuickDateFilter.all,
      hasUnsavedChanges: true,
      isApplied: false,
    );
    
    debugPrint('🛒 Filter: Cleared all filters');
  }

  /// Set a complete filter (used by UI components)
  void setFilter(CustomerDateRangeFilter filter, {CustomerQuickDateFilter? quickFilter}) {
    state = state.copyWith(
      filter: filter,
      selectedQuickFilter: quickFilter,
      hasUnsavedChanges: true,
    );
    
    debugPrint('🛒 Filter: Set complete filter: $filter');
  }

  /// Get next page filter
  CustomerDateRangeFilter getNextPageFilter() {
    return state.filter.nextPage;
  }

  /// Get previous page filter
  CustomerDateRangeFilter getPreviousPageFilter() {
    return state.filter.previousPage;
  }

  /// Check if filter has date constraints
  bool get hasDateFilter => state.filter.hasDateFilter;

  /// Check if filter has status constraints
  bool get hasStatusFilter => state.filter.hasStatusFilter;

  /// Get performance impact of current filter
  CustomerFilterPerformanceImpact get performanceImpact => state.filter.performanceImpact;
}

/// State for customer order filter management
@immutable
class CustomerOrderFilterState {
  final CustomerDateRangeFilter filter;
  final CustomerQuickDateFilter? selectedQuickFilter;
  final bool hasUnsavedChanges;
  final bool isApplied;

  const CustomerOrderFilterState({
    required this.filter,
    this.selectedQuickFilter,
    required this.hasUnsavedChanges,
    required this.isApplied,
  });

  /// Create initial state with default values
  factory CustomerOrderFilterState.initial() {
    return const CustomerOrderFilterState(
      filter: CustomerDateRangeFilter(limit: 20, offset: 0),
      selectedQuickFilter: CustomerQuickDateFilter.all,
      hasUnsavedChanges: false,
      isApplied: false,
    );
  }

  /// Create a copy with updated values
  CustomerOrderFilterState copyWith({
    CustomerDateRangeFilter? filter,
    CustomerQuickDateFilter? selectedQuickFilter,
    bool? hasUnsavedChanges,
    bool? isApplied,
  }) {
    return CustomerOrderFilterState(
      filter: filter ?? this.filter,
      selectedQuickFilter: selectedQuickFilter ?? this.selectedQuickFilter,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      isApplied: isApplied ?? this.isApplied,
    );
  }

  /// Check if the current filter is valid
  bool get isValid => filter.isValid;

  /// Get validation errors
  List<String> get validationErrors => filter.validate();

  /// Check if filter has any constraints
  bool get hasActiveFilters => filter.hasDateFilter || filter.hasStatusFilter;

  /// Get filter description for display
  String get filterDescription {
    final parts = <String>[];
    
    if (selectedQuickFilter != null && selectedQuickFilter != CustomerQuickDateFilter.all) {
      parts.add(selectedQuickFilter!.displayName);
    } else if (filter.hasDateFilter) {
      if (filter.startDate != null && filter.endDate != null) {
        parts.add(CustomerGroupedOrderHistory.getDateRangeDisplay(filter.startDate!, filter.endDate!));
      } else if (filter.startDate != null) {
        parts.add('From ${filter.startDate!.toString().split(' ')[0]}');
      } else if (filter.endDate != null) {
        parts.add('Until ${filter.endDate!.toString().split(' ')[0]}');
      }
    }
    
    if (filter.statusFilter != null && filter.statusFilter != CustomerOrderFilterStatus.all) {
      parts.add(filter.statusFilter!.displayName);
    }
    
    return parts.isEmpty ? 'All Orders' : parts.join(' • ');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerOrderFilterState &&
          runtimeType == other.runtimeType &&
          filter == other.filter &&
          selectedQuickFilter == other.selectedQuickFilter &&
          hasUnsavedChanges == other.hasUnsavedChanges &&
          isApplied == other.isApplied;

  @override
  int get hashCode => Object.hash(
        filter,
        selectedQuickFilter,
        hasUnsavedChanges,
        isApplied,
      );

  @override
  String toString() => 'CustomerOrderFilterState('
      'filter: $filter, '
      'selectedQuickFilter: $selectedQuickFilter, '
      'hasUnsavedChanges: $hasUnsavedChanges, '
      'isApplied: $isApplied'
      ')';
}

/// Provider for quick access to current filter
final currentCustomerOrderFilterProvider = Provider<CustomerDateRangeFilter>((ref) {
  final filterState = ref.watch(customerOrderFilterProvider);
  return filterState.filter;
});

/// Provider for filter validation status
final customerOrderFilterValidationProvider = Provider<List<String>>((ref) {
  final filterState = ref.watch(customerOrderFilterProvider);
  return filterState.validationErrors;
});

/// Provider for filter performance impact
final customerOrderFilterPerformanceProvider = Provider<CustomerFilterPerformanceImpact>((ref) {
  final filterState = ref.watch(customerOrderFilterProvider);
  return filterState.filter.performanceImpact;
});

/// Provider for checking if filters are active
final hasActiveCustomerOrderFiltersProvider = Provider<bool>((ref) {
  final filterState = ref.watch(customerOrderFilterProvider);
  return filterState.hasActiveFilters;
});
