import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Enhanced date range filter parameters for vendor order history with persistence and validation
@immutable
class VendorDateRangeFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final int offset;
  final String? filterName; // For named/saved filters
  final bool isPersistent; // Whether this filter should be saved
  final DateTime? createdAt; // When the filter was created
  final Map<String, dynamic>? metadata; // Additional filter metadata
  final VendorOrderFilterStatus? statusFilter; // Filter by order status

  const VendorDateRangeFilter({
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
  VendorDateRangeFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
    String? filterName,
    bool? isPersistent,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
    VendorOrderFilterStatus? statusFilter,
  }) {
    return VendorDateRangeFilter(
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

  /// Create from JSON for persistence
  factory VendorDateRangeFilter.fromJson(Map<String, dynamic> json) {
    return VendorDateRangeFilter(
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      limit: json['limit'] ?? 20,
      offset: json['offset'] ?? 0,
      filterName: json['filterName'],
      isPersistent: json['isPersistent'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      metadata: json['metadata'],
      statusFilter: json['statusFilter'] != null
          ? VendorOrderFilterStatus.values.firstWhere(
              (e) => e.name == json['statusFilter'],
              orElse: () => VendorOrderFilterStatus.all,
            )
          : null,
    );
  }

  /// Check if this filter has any active constraints
  bool get hasActiveFilter {
    return startDate != null || endDate != null || statusFilter != null;
  }

  /// Get a human-readable description of the filter
  String get description {
    if (!hasActiveFilter) return 'All Orders';

    final parts = <String>[];
    
    if (startDate != null && endDate != null) {
      final days = endDate!.difference(startDate!).inDays + 1;
      parts.add('Custom range ($days days)');
    } else if (startDate != null) {
      parts.add('From ${_formatDate(startDate!)}');
    } else if (endDate != null) {
      parts.add('Until ${_formatDate(endDate!)}');
    }

    if (statusFilter != null && statusFilter != VendorOrderFilterStatus.all) {
      parts.add(statusFilter!.displayName);
    }

    return parts.join(' • ');
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (date.year == now.year) {
      return DateFormat('MMM dd').format(date);
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  /// Check if this is a valid date range
  bool get isValidRange {
    if (startDate == null || endDate == null) return true;
    return startDate!.isBefore(endDate!) || startDate!.isAtSameMomentAs(endDate!);
  }

  /// Get next page filter
  VendorDateRangeFilter get nextPage => copyWith(offset: offset + limit);

  /// Reset to first page
  VendorDateRangeFilter get firstPage => copyWith(offset: 0);

  /// Factory methods for common date ranges
  static VendorDateRangeFilter today() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return VendorDateRangeFilter(
      startDate: startOfDay,
      endDate: endOfDay,
      filterName: 'Today',
    );
  }

  static VendorDateRangeFilter yesterday() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final startOfDay = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final endOfDay = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
    return VendorDateRangeFilter(
      startDate: startOfDay,
      endDate: endOfDay,
      filterName: 'Yesterday',
    );
  }

  static VendorDateRangeFilter thisWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return VendorDateRangeFilter(
      startDate: startOfWeek,
      endDate: now,
      filterName: 'This Week',
    );
  }

  static VendorDateRangeFilter lastWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = weekStart.subtract(const Duration(days: 1));
    return VendorDateRangeFilter(
      startDate: DateTime(lastWeekStart.year, lastWeekStart.month, lastWeekStart.day),
      endDate: DateTime(lastWeekEnd.year, lastWeekEnd.month, lastWeekEnd.day, 23, 59, 59),
      filterName: 'Last Week',
    );
  }

  static VendorDateRangeFilter thisMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return VendorDateRangeFilter(
      startDate: startOfMonth,
      endDate: now,
      filterName: 'This Month',
    );
  }

  static VendorDateRangeFilter lastMonth() {
    final now = DateTime.now();
    final monthAgo = DateTime(now.year, now.month - 1, now.day);
    return VendorDateRangeFilter(
      startDate: monthAgo,
      endDate: now,
      filterName: 'Last Month',
    );
  }

  static VendorDateRangeFilter custom(DateTime startDate, DateTime endDate) {
    return VendorDateRangeFilter(
      startDate: startDate,
      endDate: endDate,
      filterName: 'Custom Range',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VendorDateRangeFilter &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.limit == limit &&
        other.offset == offset &&
        other.filterName == filterName &&
        other.isPersistent == isPersistent &&
        other.createdAt == createdAt &&
        other.statusFilter == statusFilter;
  }

  @override
  int get hashCode {
    return Object.hash(
      startDate,
      endDate,
      limit,
      offset,
      filterName,
      isPersistent,
      createdAt,
      statusFilter,
    );
  }

  @override
  String toString() {
    return 'VendorDateRangeFilter(startDate: $startDate, endDate: $endDate, limit: $limit, offset: $offset, filterName: $filterName, statusFilter: $statusFilter)';
  }
}

/// Enum for vendor order filter status
enum VendorOrderFilterStatus {
  all('All Orders'),
  active('Active Orders'),
  completed('Completed Orders'),
  cancelled('Cancelled Orders'),
  preparing('Preparing'),
  ready('Ready'),
  delivered('Delivered');

  const VendorOrderFilterStatus(this.displayName);

  final String displayName;

  /// Get the corresponding order statuses for this filter
  List<String> get orderStatuses {
    switch (this) {
      case VendorOrderFilterStatus.all:
        return [];
      case VendorOrderFilterStatus.active:
        return ['pending', 'confirmed', 'preparing', 'ready', 'out_for_delivery'];
      case VendorOrderFilterStatus.completed:
        return ['delivered'];
      case VendorOrderFilterStatus.cancelled:
        return ['cancelled'];
      case VendorOrderFilterStatus.preparing:
        return ['preparing'];
      case VendorOrderFilterStatus.ready:
        return ['ready'];
      case VendorOrderFilterStatus.delivered:
        return ['delivered'];
    }
  }
}

/// Quick date filter options for vendor orders
enum VendorQuickDateFilter {
  all('All Time'),
  today('Today'),
  yesterday('Yesterday'),
  thisWeek('This Week'),
  lastWeek('Last Week'),
  thisMonth('This Month'),
  lastMonth('Last Month'),
  custom('Custom Range');

  const VendorQuickDateFilter(this.displayName);

  final String displayName;

  /// Convert to VendorDateRangeFilter
  VendorDateRangeFilter toDateRangeFilter() {
    switch (this) {
      case VendorQuickDateFilter.all:
        return const VendorDateRangeFilter();
      case VendorQuickDateFilter.today:
        return VendorDateRangeFilter.today();
      case VendorQuickDateFilter.yesterday:
        return VendorDateRangeFilter.yesterday();
      case VendorQuickDateFilter.thisWeek:
        return VendorDateRangeFilter.thisWeek();
      case VendorQuickDateFilter.lastWeek:
        return VendorDateRangeFilter.lastWeek();
      case VendorQuickDateFilter.thisMonth:
        return VendorDateRangeFilter.thisMonth();
      case VendorQuickDateFilter.lastMonth:
        return VendorDateRangeFilter.lastMonth();
      case VendorQuickDateFilter.custom:
        return const VendorDateRangeFilter();
    }
  }
}
