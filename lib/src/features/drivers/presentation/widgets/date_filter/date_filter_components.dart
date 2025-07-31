/// Date Filter Components for Driver Order History
///
/// This file exports all the date filter components for easy importing
/// and provides utility functions for common date filtering operations.
library;

// Core components
export 'driver_order_date_filter.dart';
export 'compact_date_filter_bar.dart';
export 'calendar_date_picker.dart';
export 'date_filter_dialog.dart';

// Providers (re-exported for convenience)
export '../../providers/enhanced_driver_order_history_providers.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/enhanced_driver_order_history_providers.dart';
import 'date_filter_dialog.dart';
import 'compact_date_filter_bar.dart';
import 'driver_order_date_filter.dart';

/// Utility class for common date filter operations
class DateFilterUtils {
  /// Show date filter bottom sheet
  static Future<void> showFilterBottomSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DriverOrderDateFilter(
        showAsBottomSheet: true,
      ),
    );
  }

  /// Show date filter dialog
  static Future<void> showFilterDialog(
    BuildContext context, {
    VoidCallback? onFilterApplied,
  }) {
    return showDateFilterDialog(
      context,
      onFilterApplied: onFilterApplied,
    );
  }

  /// Reset all filters to default
  static void resetFilters(WidgetRef ref) {
    ref.read(selectedQuickFilterProvider.notifier).setFilter(QuickDateFilter.all);
    ref.read(dateFilterProvider.notifier).reset();
  }

  /// Apply a quick filter
  static void applyQuickFilter(WidgetRef ref, QuickDateFilter filter) {
    ref.read(selectedQuickFilterProvider.notifier).setFilter(filter);
    if (filter != QuickDateFilter.all) {
      ref.read(dateFilterProvider.notifier).reset();
    }
  }

  /// Apply a custom date range
  static void applyCustomDateRange(
    WidgetRef ref,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    ref.read(selectedQuickFilterProvider.notifier).setFilter(QuickDateFilter.all);
    ref.read(dateFilterProvider.notifier).setCustomDateRange(startDate, endDate);
  }

  /// Get current filter description for display
  static String getCurrentFilterDescription(
    QuickDateFilter quickFilter,
    DateRangeFilter dateFilter,
  ) {
    if (quickFilter != QuickDateFilter.all) {
      return quickFilter.displayName;
    } else if (dateFilter.startDate != null || dateFilter.endDate != null) {
      if (dateFilter.startDate != null && dateFilter.endDate != null) {
        final days = dateFilter.endDate!.difference(dateFilter.startDate!).inDays + 1;
        return 'Custom range ($days days)';
      } else if (dateFilter.startDate != null) {
        return 'From ${_formatDate(dateFilter.startDate!)}';
      } else if (dateFilter.endDate != null) {
        return 'Until ${_formatDate(dateFilter.endDate!)}';
      }
    }
    return 'All Orders';
  }

  /// Check if any filter is currently active
  static bool hasActiveFilter(
    QuickDateFilter quickFilter,
    DateRangeFilter dateFilter,
  ) {
    return quickFilter != QuickDateFilter.all ||
           dateFilter.startDate != null ||
           dateFilter.endDate != null;
  }

  /// Get filter icon based on current filter
  static IconData getFilterIcon(
    QuickDateFilter quickFilter,
    DateRangeFilter dateFilter,
  ) {
    if (quickFilter != QuickDateFilter.all) {
      switch (quickFilter) {
        case QuickDateFilter.today:
          return Icons.today;
        case QuickDateFilter.yesterday:
          return Icons.history_toggle_off;
        case QuickDateFilter.thisWeek:
        case QuickDateFilter.lastWeek:
        case QuickDateFilter.last7Days:
          return Icons.view_week;
        case QuickDateFilter.thisMonth:
        case QuickDateFilter.lastMonth:
        case QuickDateFilter.last30Days:
          return Icons.calendar_view_month;
        case QuickDateFilter.last90Days:
          return Icons.date_range;
        case QuickDateFilter.thisYear:
        case QuickDateFilter.lastYear:
          return Icons.calendar_today;
        case QuickDateFilter.all:
          return Icons.history;
      }
    } else if (dateFilter.startDate != null || dateFilter.endDate != null) {
      return Icons.date_range;
    }
    return Icons.history;
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year) {
      return '${_getMonthName(date.month)} ${date.day}';
    } else {
      return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
    }
  }

  static String _getMonthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }
}

/// Widget that provides a complete date filter interface
class CompleteDateFilterInterface extends ConsumerWidget {
  final bool showCompactBar;
  final bool showQuickChips;
  final bool showSummary;
  final EdgeInsetsGeometry? padding;

  const CompleteDateFilterInterface({
    super.key,
    this.showCompactBar = true,
    this.showQuickChips = false,
    this.showSummary = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        if (showCompactBar)
          CompactDateFilterBar(padding: padding),
        
        if (showQuickChips)
          QuickFilterChips(padding: padding),
        
        if (showSummary)
          DateRangeSummary(padding: padding),
      ],
    );
  }
}

/// Mixin for widgets that need date filtering functionality
mixin DateFilterMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Show filter options
  void showFilterOptions(BuildContext context) {
    DateFilterUtils.showFilterDialog(context);
  }

  /// Reset filters
  void resetFilters() {
    DateFilterUtils.resetFilters(ref);
  }

  /// Apply quick filter
  void applyQuickFilter(QuickDateFilter filter) {
    DateFilterUtils.applyQuickFilter(ref, filter);
  }

  /// Apply custom date range
  void applyCustomDateRange(DateTime? startDate, DateTime? endDate) {
    DateFilterUtils.applyCustomDateRange(ref, startDate, endDate);
  }

  /// Get current filter description
  String getCurrentFilterDescription() {
    final quickFilter = ref.watch(selectedQuickFilterProvider);
    final dateFilter = ref.watch(dateFilterProvider);
    return DateFilterUtils.getCurrentFilterDescription(quickFilter, dateFilter);
  }

  /// Check if any filter is active
  bool hasActiveFilter() {
    final quickFilter = ref.watch(selectedQuickFilterProvider);
    final dateFilter = ref.watch(dateFilterProvider);
    return DateFilterUtils.hasActiveFilter(quickFilter, dateFilter);
  }

  /// Get current filter icon
  IconData getCurrentFilterIcon() {
    final quickFilter = ref.watch(selectedQuickFilterProvider);
    final dateFilter = ref.watch(dateFilterProvider);
    return DateFilterUtils.getFilterIcon(quickFilter, dateFilter);
  }
}
