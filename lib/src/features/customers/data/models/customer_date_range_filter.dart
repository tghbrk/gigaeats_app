import 'package:flutter/foundation.dart';

/// Enhanced date range filter parameters for customer order history with persistence and validation
@immutable
class CustomerDateRangeFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final int offset;
  final String? filterName; // For named/saved filters
  final bool isPersistent; // Whether this filter should be saved
  final DateTime? createdAt; // When the filter was created
  final Map<String, dynamic>? metadata; // Additional filter metadata
  final CustomerOrderFilterStatus? statusFilter; // Filter by order status

  const CustomerDateRangeFilter({
    this.startDate,
    this.endDate,
    this.limit = 20,
    this.offset = 0,
    this.filterName,
    this.isPersistent = false,
    this.createdAt,
    this.metadata,
    this.statusFilter,
  });

  /// Create a copy with updated values
  CustomerDateRangeFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
    String? filterName,
    bool? isPersistent,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
    CustomerOrderFilterStatus? statusFilter,
  }) {
    return CustomerDateRangeFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      filterName: filterName ?? this.filterName,
      isPersistent: isPersistent ?? this.isPersistent,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  /// Check if this filter has date constraints
  bool get hasDateFilter => startDate != null || endDate != null;

  /// Check if this filter has status constraints
  bool get hasStatusFilter => statusFilter != null;

  /// Check if this is the first page
  bool get isFirstPage => offset == 0;

  /// Get the current page number (1-based)
  int get currentPage => (offset ~/ limit) + 1;

  /// Get next page filter
  CustomerDateRangeFilter get nextPage => copyWith(offset: offset + limit);

  /// Get previous page filter
  CustomerDateRangeFilter get previousPage => copyWith(
        offset: offset - limit < 0 ? 0 : offset - limit,
      );

  /// Reset to first page
  CustomerDateRangeFilter get firstPage => copyWith(offset: 0);

  /// Factory methods for common date ranges
  static CustomerDateRangeFilter today() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return CustomerDateRangeFilter(
      startDate: startOfDay,
      endDate: endOfDay,
      filterName: 'Today',
    );
  }

  static CustomerDateRangeFilter yesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final startOfDay = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final endOfDay = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
    return CustomerDateRangeFilter(
      startDate: startOfDay,
      endDate: endOfDay,
      filterName: 'Yesterday',
    );
  }

  static CustomerDateRangeFilter lastWeek() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return CustomerDateRangeFilter(
      startDate: weekAgo,
      endDate: now,
      filterName: 'Last 7 Days',
    );
  }

  static CustomerDateRangeFilter lastMonth() {
    final now = DateTime.now();
    final monthAgo = DateTime(now.year, now.month - 1, now.day);
    return CustomerDateRangeFilter(
      startDate: monthAgo,
      endDate: now,
      filterName: 'Last Month',
    );
  }

  static CustomerDateRangeFilter custom(DateTime startDate, DateTime endDate) {
    return CustomerDateRangeFilter(
      startDate: startDate,
      endDate: endDate,
      filterName: 'Custom Range',
    );
  }

  /// Validate the filter parameters
  List<String> validate() {
    final errors = <String>[];

    if (limit <= 0) {
      errors.add('Limit must be greater than 0');
    }

    if (offset < 0) {
      errors.add('Offset must be non-negative');
    }

    if (startDate != null && endDate != null && startDate!.isAfter(endDate!)) {
      errors.add('Start date must be before or equal to end date');
    }

    if (startDate != null && startDate!.isAfter(DateTime.now())) {
      errors.add('Start date cannot be in the future');
    }

    if (endDate != null && endDate!.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      errors.add('End date cannot be in the future');
    }

    return errors;
  }

  /// Check if the filter is valid
  bool get isValid => validate().isEmpty;

  /// Get performance impact assessment
  CustomerFilterPerformanceImpact get performanceImpact {
    final daysDiff = _getDaysDifference();
    
    if (daysDiff <= 7) {
      return CustomerFilterPerformanceImpact.low;
    } else if (daysDiff <= 30) {
      return CustomerFilterPerformanceImpact.medium;
    } else if (daysDiff <= 90) {
      return CustomerFilterPerformanceImpact.high;
    } else {
      return CustomerFilterPerformanceImpact.veryHigh;
    }
  }

  /// Get the number of days covered by this filter
  int _getDaysDifference() {
    if (startDate == null && endDate == null) {
      return 365; // Default to 1 year if no dates specified
    }
    
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 365));
    final end = endDate ?? DateTime.now();
    
    return end.difference(start).inDays;
  }

  /// Generate a cache key for this filter
  String get cacheKey {
    final parts = <String>[
      'customer_orders',
      startDate?.toIso8601String() ?? 'null',
      endDate?.toIso8601String() ?? 'null',
      limit.toString(),
      offset.toString(),
      statusFilter?.name ?? 'all',
    ];
    return parts.join('_');
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'limit': limit,
      'offset': offset,
      'filterName': filterName,
      'isPersistent': isPersistent,
      'createdAt': createdAt?.toIso8601String(),
      'metadata': metadata,
      'statusFilter': statusFilter?.name,
    };
  }

  /// Create from JSON
  factory CustomerDateRangeFilter.fromJson(Map<String, dynamic> json) {
    return CustomerDateRangeFilter(
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      limit: json['limit'] ?? 20,
      offset: json['offset'] ?? 0,
      filterName: json['filterName'],
      isPersistent: json['isPersistent'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      metadata: json['metadata'],
      statusFilter: json['statusFilter'] != null 
          ? CustomerOrderFilterStatus.values.firstWhere(
              (e) => e.name == json['statusFilter'],
              orElse: () => CustomerOrderFilterStatus.all,
            )
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerDateRangeFilter &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          limit == other.limit &&
          offset == other.offset &&
          filterName == other.filterName &&
          isPersistent == other.isPersistent &&
          statusFilter == other.statusFilter;

  @override
  int get hashCode => Object.hash(
        startDate,
        endDate,
        limit,
        offset,
        filterName,
        isPersistent,
        statusFilter,
      );

  @override
  String toString() => 'CustomerDateRangeFilter('
      'startDate: $startDate, '
      'endDate: $endDate, '
      'limit: $limit, '
      'offset: $offset, '
      'statusFilter: $statusFilter'
      ')';
}

/// Performance impact levels for customer order filters
enum CustomerFilterPerformanceImpact {
  low,
  medium,
  high,
  veryHigh;

  String get description {
    switch (this) {
      case CustomerFilterPerformanceImpact.low:
        return 'Fast loading, minimal impact';
      case CustomerFilterPerformanceImpact.medium:
        return 'Moderate loading time';
      case CustomerFilterPerformanceImpact.high:
        return 'May take longer to load';
      case CustomerFilterPerformanceImpact.veryHigh:
        return 'Significant loading time expected';
    }
  }
}

/// Order status filter options for customers
enum CustomerOrderFilterStatus {
  all,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case CustomerOrderFilterStatus.all:
        return 'All Orders';
      case CustomerOrderFilterStatus.completed:
        return 'Completed Orders';
      case CustomerOrderFilterStatus.cancelled:
        return 'Cancelled Orders';
    }
  }

  String get description {
    switch (this) {
      case CustomerOrderFilterStatus.all:
        return 'Show both completed and cancelled orders';
      case CustomerOrderFilterStatus.completed:
        return 'Show only successfully delivered orders';
      case CustomerOrderFilterStatus.cancelled:
        return 'Show only cancelled orders';
    }
  }
}

/// Enhanced quick date filter options for customer orders
enum CustomerQuickDateFilter {
  today,
  yesterday,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  last7Days,
  last30Days,
  last90Days,
  thisYear,
  lastYear,
  all;

  String get displayName {
    switch (this) {
      case CustomerQuickDateFilter.today:
        return 'Today';
      case CustomerQuickDateFilter.yesterday:
        return 'Yesterday';
      case CustomerQuickDateFilter.thisWeek:
        return 'This Week';
      case CustomerQuickDateFilter.lastWeek:
        return 'Last Week';
      case CustomerQuickDateFilter.thisMonth:
        return 'This Month';
      case CustomerQuickDateFilter.lastMonth:
        return 'Last Month';
      case CustomerQuickDateFilter.last7Days:
        return 'Last 7 Days';
      case CustomerQuickDateFilter.last30Days:
        return 'Last 30 Days';
      case CustomerQuickDateFilter.last90Days:
        return 'Last 90 Days';
      case CustomerQuickDateFilter.thisYear:
        return 'This Year';
      case CustomerQuickDateFilter.lastYear:
        return 'Last Year';
      case CustomerQuickDateFilter.all:
        return 'All Time';
    }
  }

  String get description {
    switch (this) {
      case CustomerQuickDateFilter.today:
        return 'Orders placed today';
      case CustomerQuickDateFilter.yesterday:
        return 'Orders placed yesterday';
      case CustomerQuickDateFilter.thisWeek:
        return 'Orders from this week (Monday to today)';
      case CustomerQuickDateFilter.lastWeek:
        return 'Orders from last week';
      case CustomerQuickDateFilter.thisMonth:
        return 'Orders from this month';
      case CustomerQuickDateFilter.lastMonth:
        return 'Orders from last month';
      case CustomerQuickDateFilter.last7Days:
        return 'Orders from the last 7 days';
      case CustomerQuickDateFilter.last30Days:
        return 'Orders from the last 30 days';
      case CustomerQuickDateFilter.last90Days:
        return 'Orders from the last 90 days';
      case CustomerQuickDateFilter.thisYear:
        return 'Orders from this year';
      case CustomerQuickDateFilter.lastYear:
        return 'Orders from last year';
      case CustomerQuickDateFilter.all:
        return 'All orders regardless of date';
    }
  }

  /// Convert to CustomerDateRangeFilter
  CustomerDateRangeFilter toDateRangeFilter() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (this) {
      case CustomerQuickDateFilter.today:
        return CustomerDateRangeFilter(
          startDate: today,
          endDate: today.add(const Duration(days: 1)),
        );
      case CustomerQuickDateFilter.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return CustomerDateRangeFilter(
          startDate: yesterday,
          endDate: today,
        );
      case CustomerQuickDateFilter.thisWeek:
        final weekStart = today.subtract(Duration(days: now.weekday - 1));
        return CustomerDateRangeFilter(
          startDate: weekStart,
          endDate: today.add(const Duration(days: 1)),
        );
      case CustomerQuickDateFilter.lastWeek:
        final lastWeekEnd = today.subtract(Duration(days: now.weekday));
        final lastWeekStart = lastWeekEnd.subtract(const Duration(days: 6));
        return CustomerDateRangeFilter(
          startDate: lastWeekStart,
          endDate: lastWeekEnd.add(const Duration(days: 1)),
        );
      case CustomerQuickDateFilter.thisMonth:
        final monthStart = DateTime(now.year, now.month, 1);
        return CustomerDateRangeFilter(
          startDate: monthStart,
          endDate: today.add(const Duration(days: 1)),
        );
      case CustomerQuickDateFilter.lastMonth:
        final lastMonthStart = DateTime(now.year, now.month - 1, 1);
        final lastMonthEnd = DateTime(now.year, now.month, 1);
        return CustomerDateRangeFilter(
          startDate: lastMonthStart,
          endDate: lastMonthEnd,
        );
      case CustomerQuickDateFilter.last7Days:
        return CustomerDateRangeFilter(
          startDate: today.subtract(const Duration(days: 7)),
          endDate: today.add(const Duration(days: 1)),
        );
      case CustomerQuickDateFilter.last30Days:
        return CustomerDateRangeFilter(
          startDate: today.subtract(const Duration(days: 30)),
          endDate: today.add(const Duration(days: 1)),
        );
      case CustomerQuickDateFilter.last90Days:
        return CustomerDateRangeFilter(
          startDate: today.subtract(const Duration(days: 90)),
          endDate: today.add(const Duration(days: 1)),
        );
      case CustomerQuickDateFilter.thisYear:
        final yearStart = DateTime(now.year, 1, 1);
        return CustomerDateRangeFilter(
          startDate: yearStart,
          endDate: today.add(const Duration(days: 1)),
        );
      case CustomerQuickDateFilter.lastYear:
        final lastYearStart = DateTime(now.year - 1, 1, 1);
        final lastYearEnd = DateTime(now.year, 1, 1);
        return CustomerDateRangeFilter(
          startDate: lastYearStart,
          endDate: lastYearEnd,
        );
      case CustomerQuickDateFilter.all:
        return const CustomerDateRangeFilter();
    }
  }

  /// Get performance impact for this quick filter
  CustomerFilterPerformanceImpact get performanceImpact {
    switch (this) {
      case CustomerQuickDateFilter.today:
      case CustomerQuickDateFilter.yesterday:
        return CustomerFilterPerformanceImpact.low;
      case CustomerQuickDateFilter.thisWeek:
      case CustomerQuickDateFilter.lastWeek:
      case CustomerQuickDateFilter.last7Days:
        return CustomerFilterPerformanceImpact.low;
      case CustomerQuickDateFilter.thisMonth:
      case CustomerQuickDateFilter.lastMonth:
      case CustomerQuickDateFilter.last30Days:
        return CustomerFilterPerformanceImpact.medium;
      case CustomerQuickDateFilter.last90Days:
        return CustomerFilterPerformanceImpact.high;
      case CustomerQuickDateFilter.thisYear:
      case CustomerQuickDateFilter.lastYear:
      case CustomerQuickDateFilter.all:
        return CustomerFilterPerformanceImpact.veryHigh;
    }
  }
}
