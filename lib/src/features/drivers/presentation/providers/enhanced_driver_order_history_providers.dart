import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/data/models/order.dart';
import '../../../../data/models/user_role.dart';
import '../../data/models/grouped_order_history.dart';

/// Enhanced date range filter parameters for order history with persistence and validation
@immutable
class DateRangeFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final int offset;
  final String? filterName; // For named/saved filters
  final bool isPersistent; // Whether this filter should be saved
  final DateTime? createdAt; // When the filter was created
  final Map<String, dynamic>? metadata; // Additional filter metadata

  const DateRangeFilter({
    this.startDate,
    this.endDate,
    this.limit = 20,
    this.offset = 0,
    this.filterName,
    this.isPersistent = false,
    this.createdAt,
    this.metadata,
  });

  DateRangeFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
    String? filterName,
    bool? isPersistent,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return DateRangeFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      filterName: filterName ?? this.filterName,
      isPersistent: isPersistent ?? this.isPersistent,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
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
    };
  }

  /// Create from JSON for persistence
  factory DateRangeFilter.fromJson(Map<String, dynamic> json) {
    return DateRangeFilter(
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      limit: json['limit'] ?? 20,
      offset: json['offset'] ?? 0,
      filterName: json['filterName'],
      isPersistent: json['isPersistent'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      metadata: json['metadata'],
    );
  }

  /// Check if this filter has any active constraints
  bool get hasActiveFilter {
    return startDate != null || endDate != null;
  }

  /// Get a human-readable description of the filter
  String get description {
    if (!hasActiveFilter) return 'All Orders';

    if (startDate != null && endDate != null) {
      final days = endDate!.difference(startDate!).inDays + 1;
      return 'Custom range ($days days)';
    } else if (startDate != null) {
      return 'From ${_formatDate(startDate!)}';
    } else if (endDate != null) {
      return 'Until ${_formatDate(endDate!)}';
    }
    return 'Custom Filter';
  }

  /// Get cache key for this filter
  String getCacheKey(String driverId) {
    final startStr = startDate?.toIso8601String() ?? 'null';
    final endStr = endDate?.toIso8601String() ?? 'null';
    return 'driver_orders_${driverId}_${startStr}_${endStr}_${limit}_$offset';
  }

  /// Validate the filter parameters
  FilterValidationResult validate() {
    final errors = <String>[];
    final warnings = <String>[];

    // Check date range validity
    if (startDate != null && endDate != null) {
      if (startDate!.isAfter(endDate!)) {
        errors.add('Start date cannot be after end date');
      }

      final daysDifference = endDate!.difference(startDate!).inDays;
      if (daysDifference > 365) {
        warnings.add('Date range is very large (${daysDifference} days). This may affect performance.');
      }
    }

    // Check future dates
    final now = DateTime.now();
    if (startDate != null && startDate!.isAfter(now)) {
      warnings.add('Start date is in the future');
    }
    if (endDate != null && endDate!.isAfter(now.add(const Duration(days: 1)))) {
      warnings.add('End date is in the future');
    }

    // Check pagination parameters
    if (limit <= 0) {
      errors.add('Limit must be greater than 0');
    }
    if (limit > 1000) {
      warnings.add('Large limit ($limit) may affect performance');
    }
    if (offset < 0) {
      errors.add('Offset cannot be negative');
    }

    return FilterValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateRangeFilter &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.limit == limit &&
        other.offset == offset &&
        other.filterName == filterName &&
        other.isPersistent == isPersistent;
  }

  @override
  int get hashCode {
    return Object.hash(startDate, endDate, limit, offset, filterName, isPersistent);
  }

  @override
  String toString() {
    return 'DateRangeFilter(start: $startDate, end: $endDate, limit: $limit, offset: $offset, name: $filterName)';
  }
}

/// Filter validation result for date range filters
@immutable
class FilterValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const FilterValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;

  @override
  String toString() {
    return 'FilterValidationResult(isValid: $isValid, errors: $errors, warnings: $warnings)';
  }
}

/// Performance impact levels for different filter types
enum FilterPerformanceImpact {
  low,      // < 100 orders typically
  medium,   // 100-1000 orders typically
  high,     // 1000-5000 orders typically
  veryHigh; // > 5000 orders typically

  String get displayName {
    switch (this) {
      case FilterPerformanceImpact.low:
        return 'Low Impact';
      case FilterPerformanceImpact.medium:
        return 'Medium Impact';
      case FilterPerformanceImpact.high:
        return 'High Impact';
      case FilterPerformanceImpact.veryHigh:
        return 'Very High Impact';
    }
  }

  String get description {
    switch (this) {
      case FilterPerformanceImpact.low:
        return 'Fast loading, minimal impact';
      case FilterPerformanceImpact.medium:
        return 'Moderate loading time';
      case FilterPerformanceImpact.high:
        return 'May take longer to load';
      case FilterPerformanceImpact.veryHigh:
        return 'Significant loading time expected';
    }
  }
}

/// Enhanced quick date filter options for easy selection with additional metadata
enum QuickDateFilter {
  today,
  yesterday,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  last7Days,
  last30Days,
  last90Days, // New: Last 90 days
  thisYear,   // New: This year
  lastYear,   // New: Last year
  all;

  String get displayName {
    switch (this) {
      case QuickDateFilter.today:
        return 'Today';
      case QuickDateFilter.yesterday:
        return 'Yesterday';
      case QuickDateFilter.thisWeek:
        return 'This Week';
      case QuickDateFilter.lastWeek:
        return 'Last Week';
      case QuickDateFilter.thisMonth:
        return 'This Month';
      case QuickDateFilter.lastMonth:
        return 'Last Month';
      case QuickDateFilter.last7Days:
        return 'Last 7 Days';
      case QuickDateFilter.last30Days:
        return 'Last 30 Days';
      case QuickDateFilter.last90Days:
        return 'Last 90 Days';
      case QuickDateFilter.thisYear:
        return 'This Year';
      case QuickDateFilter.lastYear:
        return 'Last Year';
      case QuickDateFilter.all:
        return 'All Time';
    }
  }

  /// Get a short description for the filter
  String get shortDescription {
    switch (this) {
      case QuickDateFilter.today:
        return 'Orders from today';
      case QuickDateFilter.yesterday:
        return 'Orders from yesterday';
      case QuickDateFilter.thisWeek:
        return 'Orders from this week';
      case QuickDateFilter.lastWeek:
        return 'Orders from last week';
      case QuickDateFilter.thisMonth:
        return 'Orders from this month';
      case QuickDateFilter.lastMonth:
        return 'Orders from last month';
      case QuickDateFilter.last7Days:
        return 'Orders from the last 7 days';
      case QuickDateFilter.last30Days:
        return 'Orders from the last 30 days';
      case QuickDateFilter.last90Days:
        return 'Orders from the last 90 days';
      case QuickDateFilter.thisYear:
        return 'Orders from this year';
      case QuickDateFilter.lastYear:
        return 'Orders from last year';
      case QuickDateFilter.all:
        return 'All order history';
    }
  }

  /// Get the expected performance impact of this filter
  FilterPerformanceImpact get performanceImpact {
    switch (this) {
      case QuickDateFilter.today:
      case QuickDateFilter.yesterday:
        return FilterPerformanceImpact.low;
      case QuickDateFilter.thisWeek:
      case QuickDateFilter.lastWeek:
      case QuickDateFilter.last7Days:
        return FilterPerformanceImpact.low;
      case QuickDateFilter.thisMonth:
      case QuickDateFilter.lastMonth:
      case QuickDateFilter.last30Days:
        return FilterPerformanceImpact.medium;
      case QuickDateFilter.last90Days:
      case QuickDateFilter.thisYear:
        return FilterPerformanceImpact.high;
      case QuickDateFilter.lastYear:
      case QuickDateFilter.all:
        return FilterPerformanceImpact.veryHigh;
    }
  }

  /// Check if this filter is commonly used (for caching priority)
  bool get isCommonlyUsed {
    switch (this) {
      case QuickDateFilter.today:
      case QuickDateFilter.yesterday:
      case QuickDateFilter.thisWeek:
      case QuickDateFilter.thisMonth:
      case QuickDateFilter.last7Days:
      case QuickDateFilter.last30Days:
        return true;
      default:
        return false;
    }
  }

  /// Get the cache priority for this filter
  int get cachePriority {
    if (isCommonlyUsed) {
      switch (this) {
        case QuickDateFilter.today:
          return 10; // Highest priority
        case QuickDateFilter.yesterday:
        case QuickDateFilter.thisWeek:
          return 8;
        case QuickDateFilter.thisMonth:
        case QuickDateFilter.last7Days:
          return 6;
        case QuickDateFilter.last30Days:
          return 4;
        default:
          return 2;
      }
    }
    return 1; // Lowest priority
  }

  DateRangeFilter toDateRangeFilter() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (this) {
      case QuickDateFilter.today:
        return DateRangeFilter(
          startDate: today,
          endDate: today.add(const Duration(days: 1)),
        );
      case QuickDateFilter.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return DateRangeFilter(
          startDate: yesterday,
          endDate: today,
        );
      case QuickDateFilter.thisWeek:
        final weekStart = today.subtract(Duration(days: now.weekday - 1));
        return DateRangeFilter(
          startDate: weekStart,
          endDate: today.add(const Duration(days: 1)),
        );
      case QuickDateFilter.lastWeek:
        final lastWeekEnd = today.subtract(Duration(days: now.weekday));
        final lastWeekStart = lastWeekEnd.subtract(const Duration(days: 6));
        return DateRangeFilter(
          startDate: lastWeekStart,
          endDate: lastWeekEnd.add(const Duration(days: 1)),
        );
      case QuickDateFilter.thisMonth:
        final monthStart = DateTime(now.year, now.month, 1);
        return DateRangeFilter(
          startDate: monthStart,
          endDate: today.add(const Duration(days: 1)),
        );
      case QuickDateFilter.lastMonth:
        final lastMonthStart = DateTime(now.year, now.month - 1, 1);
        final lastMonthEnd = DateTime(now.year, now.month, 1);
        return DateRangeFilter(
          startDate: lastMonthStart,
          endDate: lastMonthEnd,
        );
      case QuickDateFilter.last7Days:
        return DateRangeFilter(
          startDate: today.subtract(const Duration(days: 7)),
          endDate: today.add(const Duration(days: 1)),
        );
      case QuickDateFilter.last30Days:
        return DateRangeFilter(
          startDate: today.subtract(const Duration(days: 30)),
          endDate: today.add(const Duration(days: 1)),
        );
      case QuickDateFilter.last90Days:
        return DateRangeFilter(
          startDate: today.subtract(const Duration(days: 90)),
          endDate: today.add(const Duration(days: 1)),
        );
      case QuickDateFilter.thisYear:
        final yearStart = DateTime(now.year, 1, 1);
        return DateRangeFilter(
          startDate: yearStart,
          endDate: today.add(const Duration(days: 1)),
        );
      case QuickDateFilter.lastYear:
        final lastYearStart = DateTime(now.year - 1, 1, 1);
        final lastYearEnd = DateTime(now.year, 1, 1);
        return DateRangeFilter(
          startDate: lastYearStart,
          endDate: lastYearEnd,
        );
      case QuickDateFilter.all:
        return const DateRangeFilter();
    }
  }
}

/// Enhanced state notifier for managing date filter selection with persistence
class DateFilterNotifier extends StateNotifier<DateRangeFilter> {
  static const String _persistenceKey = 'driver_date_filter_v2';
  SharedPreferences? _prefs;

  DateFilterNotifier() : super(QuickDateFilter.all.toDateRangeFilter()) {
    _initializePersistence();
  }

  /// Initialize persistence and load saved filter
  Future<void> _initializePersistence() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadPersistedFilter();
    } catch (e) {
      debugPrint('🚗 DateFilter: Error initializing persistence: $e');
    }
  }

  /// Load persisted filter from storage
  Future<void> _loadPersistedFilter() async {
    try {
      final filterJson = _prefs?.getString(_persistenceKey);
      if (filterJson != null) {
        final filterData = jsonDecode(filterJson) as Map<String, dynamic>;
        final filter = DateRangeFilter.fromJson(filterData);

        // Validate the loaded filter
        final validation = filter.validate();
        if (validation.isValid) {
          state = filter;
          debugPrint('🚗 DateFilter: Loaded persisted filter: ${filter.description}');
        } else {
          debugPrint('🚗 DateFilter: Invalid persisted filter, using default');
          await _clearPersistedFilter();
        }
      }
    } catch (e) {
      debugPrint('🚗 DateFilter: Error loading persisted filter: $e');
      await _clearPersistedFilter();
    }
  }

  /// Persist current filter to storage
  Future<void> _persistFilter() async {
    try {
      if (_prefs != null && state.isPersistent) {
        final filterJson = jsonEncode(state.toJson());
        await _prefs!.setString(_persistenceKey, filterJson);
        debugPrint('🚗 DateFilter: Persisted filter: ${state.description}');
      }
    } catch (e) {
      debugPrint('🚗 DateFilter: Error persisting filter: $e');
    }
  }

  /// Clear persisted filter from storage
  Future<void> _clearPersistedFilter() async {
    try {
      await _prefs?.remove(_persistenceKey);
      debugPrint('🚗 DateFilter: Cleared persisted filter');
    } catch (e) {
      debugPrint('🚗 DateFilter: Error clearing persisted filter: $e');
    }
  }

  void setQuickFilter(QuickDateFilter filter, {bool persist = true}) {
    debugPrint('🚗 DateFilter: Setting quick filter: ${filter.displayName}');
    state = filter.toDateRangeFilter().copyWith(
      isPersistent: persist,
      createdAt: DateTime.now(),
    );
    if (persist) _persistFilter();
  }

  void setCustomDateRange(DateTime? startDate, DateTime? endDate, {bool persist = true}) {
    debugPrint('🚗 DateFilter: Setting custom date range: $startDate to $endDate');
    state = DateRangeFilter(
      startDate: startDate,
      endDate: endDate,
      limit: state.limit,
      offset: 0, // Reset offset when changing date range
      isPersistent: persist,
      createdAt: DateTime.now(),
    );
    if (persist) _persistFilter();
  }

  void setLimit(int limit) {
    debugPrint('🚗 DateFilter: Setting limit: $limit');
    state = state.copyWith(limit: limit, offset: 0);
    if (state.isPersistent) _persistFilter();
  }

  void setOffset(int offset) {
    debugPrint('🚗 DateFilter: Setting offset: $offset');
    state = state.copyWith(offset: offset);
    // Don't persist offset changes as they're temporary navigation state
  }

  void reset({bool clearPersistence = false}) {
    debugPrint('🚗 DateFilter: Resetting to default');
    state = QuickDateFilter.all.toDateRangeFilter();
    if (clearPersistence) _clearPersistedFilter();
  }

  /// Save current filter as a named preset
  Future<void> saveAsPreset(String name) async {
    try {
      final presetKey = 'driver_filter_preset_$name';
      final presetFilter = state.copyWith(
        filterName: name,
        isPersistent: true,
        createdAt: DateTime.now(),
      );

      if (_prefs != null) {
        final presetJson = jsonEncode(presetFilter.toJson());
        await _prefs!.setString(presetKey, presetJson);
        debugPrint('🚗 DateFilter: Saved preset "$name"');
      }
    } catch (e) {
      debugPrint('🚗 DateFilter: Error saving preset: $e');
    }
  }

  /// Load a named preset
  Future<bool> loadPreset(String name) async {
    try {
      final presetKey = 'driver_filter_preset_$name';
      final presetJson = _prefs?.getString(presetKey);

      if (presetJson != null) {
        final presetData = jsonDecode(presetJson) as Map<String, dynamic>;
        final presetFilter = DateRangeFilter.fromJson(presetData);

        final validation = presetFilter.validate();
        if (validation.isValid) {
          state = presetFilter;
          debugPrint('🚗 DateFilter: Loaded preset "$name"');
          return true;
        }
      }
    } catch (e) {
      debugPrint('🚗 DateFilter: Error loading preset: $e');
    }
    return false;
  }

  @override
  void dispose() {
    // Perform any cleanup if needed
    super.dispose();
  }
}

/// Provider for enhanced date filter state management with persistence
final dateFilterProvider = StateNotifierProvider<DateFilterNotifier, DateRangeFilter>((ref) {
  return DateFilterNotifier();
});

/// Provider for managing filter presets
final filterPresetsProvider = FutureProvider<List<String>>((ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final presetNames = keys
        .where((key) => key.startsWith('driver_filter_preset_'))
        .map((key) => key.replaceFirst('driver_filter_preset_', ''))
        .toList();

    debugPrint('🚗 FilterPresets: Found ${presetNames.length} presets');
    return presetNames;
  } catch (e) {
    debugPrint('🚗 FilterPresets: Error loading presets: $e');
    return <String>[];
  }
});

/// Performance metrics for filter operations
@immutable
class FilterPerformanceMetrics {
  final Duration loadTime;
  final int recordCount;
  final DateTime timestamp;
  final bool fromCache;
  final String filterDescription;

  const FilterPerformanceMetrics({
    required this.loadTime,
    required this.recordCount,
    required this.timestamp,
    required this.fromCache,
    required this.filterDescription,
  });

  Map<String, dynamic> toJson() {
    return {
      'loadTime': loadTime.inMilliseconds,
      'recordCount': recordCount,
      'timestamp': timestamp.toIso8601String(),
      'fromCache': fromCache,
      'filterDescription': filterDescription,
    };
  }

  factory FilterPerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return FilterPerformanceMetrics(
      loadTime: Duration(milliseconds: json['loadTime']),
      recordCount: json['recordCount'],
      timestamp: DateTime.parse(json['timestamp']),
      fromCache: json['fromCache'],
      filterDescription: json['filterDescription'],
    );
  }

  @override
  String toString() {
    return 'FilterPerformanceMetrics(loadTime: ${loadTime.inMilliseconds}ms, records: $recordCount, fromCache: $fromCache)';
  }
}

/// Provider for filter performance monitoring
final filterPerformanceProvider = StateProvider<Map<String, FilterPerformanceMetrics>>((ref) {
  return <String, FilterPerformanceMetrics>{};
});

/// Enhanced state notifier for managing quick filter selection with analytics
class QuickFilterNotifier extends StateNotifier<QuickDateFilter> {
  static const String _persistenceKey = 'driver_quick_filter_v2';
  static const String _analyticsKey = 'driver_filter_analytics_v2';
  SharedPreferences? _prefs;

  QuickFilterNotifier() : super(QuickDateFilter.all) {
    _initializePersistence();
  }

  Future<void> _initializePersistence() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadPersistedFilter();
    } catch (e) {
      debugPrint('🚗 QuickFilter: Error initializing persistence: $e');
    }
  }

  Future<void> _loadPersistedFilter() async {
    try {
      final filterName = _prefs?.getString(_persistenceKey);
      if (filterName != null) {
        final filter = QuickDateFilter.values.firstWhere(
          (f) => f.name == filterName,
          orElse: () => QuickDateFilter.all,
        );
        state = filter;
        debugPrint('🚗 QuickFilter: Loaded persisted filter: ${filter.displayName}');
      }
    } catch (e) {
      debugPrint('🚗 QuickFilter: Error loading persisted filter: $e');
    }
  }

  Future<void> _persistFilter() async {
    try {
      await _prefs?.setString(_persistenceKey, state.name);
      debugPrint('🚗 QuickFilter: Persisted filter: ${state.displayName}');
    } catch (e) {
      debugPrint('🚗 QuickFilter: Error persisting filter: $e');
    }
  }

  Future<void> _recordFilterUsage() async {
    try {
      final analyticsJson = _prefs?.getString(_analyticsKey);
      Map<String, dynamic> analytics = {};

      if (analyticsJson != null) {
        analytics = jsonDecode(analyticsJson) as Map<String, dynamic>;
      }

      final filterName = state.name;
      analytics[filterName] = (analytics[filterName] ?? 0) + 1;
      analytics['lastUsed_$filterName'] = DateTime.now().toIso8601String();

      await _prefs?.setString(_analyticsKey, jsonEncode(analytics));
    } catch (e) {
      debugPrint('🚗 QuickFilter: Error recording usage: $e');
    }
  }

  void setFilter(QuickDateFilter filter, {bool persist = true}) {
    debugPrint('🚗 QuickFilter: Setting filter: ${filter.displayName}');
    state = filter;
    if (persist) {
      _persistFilter();
      _recordFilterUsage();
    }
  }

  /// Get usage analytics for filters
  Future<Map<String, int>> getFilterAnalytics() async {
    try {
      final analyticsJson = _prefs?.getString(_analyticsKey);
      if (analyticsJson != null) {
        final analytics = jsonDecode(analyticsJson) as Map<String, dynamic>;
        return analytics.entries
            .where((entry) => !entry.key.startsWith('lastUsed_'))
            .map((entry) => MapEntry(entry.key, entry.value as int))
            .fold<Map<String, int>>({}, (map, entry) {
          map[entry.key] = entry.value;
          return map;
        });
      }
    } catch (e) {
      debugPrint('🚗 QuickFilter: Error getting analytics: $e');
    }
    return <String, int>{};
  }
}

/// Enhanced provider for driver order history with date filtering and pagination
final enhancedDriverOrderHistoryProvider = FutureProvider.family<List<Order>, DateRangeFilter>((ref, filter) async {
  final authState = ref.read(authStateProvider);

  if (authState.user?.role != UserRole.driver) {
    debugPrint('🚗 Enhanced History: User is not a driver, role: ${authState.user?.role}');
    return <Order>[];
  }

  final userId = authState.user?.id;
  if (userId == null) {
    debugPrint('🚗 Enhanced History: No user ID found');
    return <Order>[];
  }

  try {
    final supabase = Supabase.instance.client;
    
    debugPrint('🚗 Enhanced History: Fetching orders for user: $userId with filter: $filter');

    // First, get the driver ID for this user
    final driverResponse = await supabase
        .from('drivers')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (driverResponse == null) {
      debugPrint('🚗 Enhanced History: No driver profile found for user: $userId');
      return <Order>[];
    }

    final driverId = driverResponse['id'] as String;
    debugPrint('🚗 Enhanced History: Found driver ID: $driverId for user: $userId');

    // Build query with date filtering
    var query = supabase
        .from('orders')
        .select('''
          *,
          order_items:order_items(
            *,
            menu_item:menu_items!order_items_menu_item_id_fkey(
              id,
              name,
              image_url
            )
          ),
          vendors:vendors!orders_vendor_id_fkey(
            business_name,
            business_address
          )
        ''')
        .eq('assigned_driver_id', driverId)
        .inFilter('status', ['delivered', 'cancelled']);

    // Apply date filtering if specified
    if (filter.startDate != null) {
      query = query.gte('actual_delivery_time', filter.startDate!.toIso8601String());
      debugPrint('🚗 Enhanced History: Applied start date filter: ${filter.startDate}');
    }

    if (filter.endDate != null) {
      query = query.lt('actual_delivery_time', filter.endDate!.toIso8601String());
      debugPrint('🚗 Enhanced History: Applied end date filter: ${filter.endDate}');
    }

    // Apply ordering and pagination
    final response = await query
        .order('actual_delivery_time', ascending: false)
        .range(filter.offset, filter.offset + filter.limit - 1);

    debugPrint('🚗 Enhanced History: Retrieved ${response.length} orders');

    return response.map((json) => Order.fromJson(json)).toList();
  } catch (e) {
    debugPrint('🚗 Enhanced History: Error fetching orders: $e');
    throw Exception('Failed to fetch driver order history: $e');
  }
});

/// Provider for order count by date range (for displaying in headers)
final orderCountByDateProvider = FutureProvider.family<int, DateRangeFilter>((ref, filter) async {
  final authState = ref.read(authStateProvider);

  if (authState.user?.role != UserRole.driver) {
    return 0;
  }

  final userId = authState.user?.id;
  if (userId == null) {
    return 0;
  }

  try {
    final supabase = Supabase.instance.client;

    // Get driver ID
    final driverResponse = await supabase
        .from('drivers')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (driverResponse == null) {
      return 0;
    }

    final driverId = driverResponse['id'] as String;

    // Build count query using count() method
    var query = supabase
        .from('orders')
        .select('id')
        .eq('assigned_driver_id', driverId)
        .inFilter('status', ['delivered', 'cancelled']);

    // Apply date filtering
    if (filter.startDate != null) {
      query = query.gte('actual_delivery_time', filter.startDate!.toIso8601String());
    }

    if (filter.endDate != null) {
      query = query.lt('actual_delivery_time', filter.endDate!.toIso8601String());
    }

    final response = await query.count(CountOption.exact);
    final count = response.count;

    debugPrint('🚗 Order Count: Found $count orders for date range');
    return count;
  } catch (e) {
    debugPrint('🚗 Order Count: Error: $e');
    return 0;
  }
});

/// Real-time streaming provider for enhanced driver order history
final enhancedDriverOrderHistoryStreamProvider = StreamProvider.family<List<Order>, DateRangeFilter>((ref, filter) async* {
  final authState = ref.read(authStateProvider);

  if (authState.user?.role != UserRole.driver) {
    debugPrint('🚗 Enhanced History Stream: User is not a driver, role: ${authState.user?.role}');
    yield <Order>[];
    return;
  }

  final userId = authState.user?.id;
  if (userId == null) {
    debugPrint('🚗 Enhanced History Stream: No user ID found');
    yield <Order>[];
    return;
  }

  try {
    final supabase = Supabase.instance.client;

    debugPrint('🚗 Enhanced History Stream: Setting up stream for user: $userId with filter: $filter');

    // Get driver ID
    final driverResponse = await supabase
        .from('drivers')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (driverResponse == null) {
      debugPrint('🚗 Enhanced History Stream: No driver profile found for user: $userId');
      yield <Order>[];
      return;
    }

    final driverId = driverResponse['id'] as String;
    debugPrint('🚗 Enhanced History Stream: Found driver ID: $driverId');

    // Get initial data
    final initialOrders = await ref.read(enhancedDriverOrderHistoryProvider(filter).future);
    yield initialOrders;

    // Set up real-time stream
    yield* supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('assigned_driver_id', driverId)
        .order('actual_delivery_time', ascending: false)
        .asyncMap((data) async {
          debugPrint('🚗 Enhanced History Stream: Received ${data.length} orders from stream');

          // Filter for completed statuses
          final completedStatuses = ['delivered', 'cancelled'];
          var filteredData = data.where((json) =>
            completedStatuses.contains(json['status'])
          ).toList();

          // Apply date filtering in memory for real-time updates
          if (filter.startDate != null || filter.endDate != null) {
            filteredData = filteredData.where((json) {
              final actualDeliveryTime = json['actual_delivery_time'] as String?;
              if (actualDeliveryTime == null) return false;

              final deliveryDate = DateTime.parse(actualDeliveryTime);

              if (filter.startDate != null && deliveryDate.isBefore(filter.startDate!)) {
                return false;
              }

              if (filter.endDate != null && deliveryDate.isAfter(filter.endDate!)) {
                return false;
              }

              return true;
            }).toList();
          }

          // Apply pagination
          final paginatedData = filteredData
              .skip(filter.offset)
              .take(filter.limit)
              .toList();

          debugPrint('🚗 Enhanced History Stream: After filtering and pagination: ${paginatedData.length} orders');

          if (paginatedData.isEmpty) {
            return <Order>[];
          }

          // Fetch full order details for the filtered orders
          final orderIds = paginatedData.map((json) => json['id'] as String).toList();

          final detailedResponse = await supabase
              .from('orders')
              .select('''
                *,
                order_items:order_items(
                  *,
                  menu_item:menu_items!order_items_menu_item_id_fkey(
                    id,
                    name,
                    image_url
                  )
                ),
                vendors:vendors!orders_vendor_id_fkey(
                  business_name,
                  business_address
                )
              ''')
              .inFilter('id', orderIds)
              .order('actual_delivery_time', ascending: false);

          return detailedResponse.map((json) => Order.fromJson(json)).toList();
        });
  } catch (e) {
    debugPrint('🚗 Enhanced History Stream: Error: $e');
    yield <Order>[];
  }
});

/// Provider for daily order statistics
final dailyOrderStatsProvider = FutureProvider.family<Map<String, int>, String>((ref, driverId) async {
  try {
    final supabase = Supabase.instance.client;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thirtyDaysAgo = today.subtract(const Duration(days: 30));

    debugPrint('🚗 Daily Stats: Fetching stats for driver: $driverId');

    final response = await supabase
        .from('orders')
        .select('actual_delivery_time, status')
        .eq('assigned_driver_id', driverId)
        .inFilter('status', ['delivered', 'cancelled'])
        .gte('actual_delivery_time', thirtyDaysAgo.toIso8601String())
        .order('actual_delivery_time', ascending: false);

    final stats = <String, int>{};

    for (final order in response) {
      final actualDeliveryTime = order['actual_delivery_time'] as String?;
      if (actualDeliveryTime != null) {
        final deliveryDate = DateTime.parse(actualDeliveryTime);
        final dateKey = DateTime(deliveryDate.year, deliveryDate.month, deliveryDate.day)
            .toIso8601String()
            .split('T')[0];

        stats[dateKey] = (stats[dateKey] ?? 0) + 1;
      }
    }

    debugPrint('🚗 Daily Stats: Generated stats for ${stats.length} days');
    return stats;
  } catch (e) {
    debugPrint('🚗 Daily Stats: Error: $e');
    return <String, int>{};
  }
});

/// Utility provider for checking if more orders are available for pagination
final hasMoreOrdersProvider = FutureProvider.family<bool, DateRangeFilter>((ref, filter) async {
  final totalCount = await ref.read(orderCountByDateProvider(filter).future);
  final currentlyLoaded = filter.offset + filter.limit;
  return currentlyLoaded < totalCount;
});

/// Provider for grouped order history with enhanced organization
final groupedOrderHistoryProvider = FutureProvider.family<List<GroupedOrderHistory>, DateRangeFilter>((ref, filter) async {
  debugPrint('🔍 [GROUPED-ORDER-HISTORY] ========== PROVIDER CALLED ==========');
  debugPrint('🔍 [GROUPED-ORDER-HISTORY] Timestamp: ${DateTime.now()}');
  debugPrint('🔍 [GROUPED-ORDER-HISTORY] Filter: $filter');
  debugPrint('🔍 [GROUPED-ORDER-HISTORY] Filter type: ${filter.runtimeType}');
  debugPrint('🔍 [GROUPED-ORDER-HISTORY] Filter start date: ${filter.startDate}');
  debugPrint('🔍 [GROUPED-ORDER-HISTORY] Filter end date: ${filter.endDate}');

  try {
    debugPrint('🔍 [GROUPED-ORDER-HISTORY] About to call enhancedDriverOrderHistoryProvider...');
    final orders = await ref.read(enhancedDriverOrderHistoryProvider(filter).future);
    debugPrint('🔍 [GROUPED-ORDER-HISTORY] Raw orders received: ${orders.length}');
    debugPrint('🔍 [GROUPED-ORDER-HISTORY] Raw orders type: ${orders.runtimeType}');

    if (orders.isNotEmpty) {
      debugPrint('🔍 [GROUPED-ORDER-HISTORY] Sample order: ${orders.first.id} - ${orders.first.status}');
    }

    debugPrint('🔍 [GROUPED-ORDER-HISTORY] About to call GroupedOrderHistory.fromOrders...');
    final groupedHistory = GroupedOrderHistory.fromOrders(orders);
    debugPrint('🔍 [GROUPED-ORDER-HISTORY] Grouped history created: ${groupedHistory.length} groups');
    debugPrint('🔍 [GROUPED-ORDER-HISTORY] Grouped history type: ${groupedHistory.runtimeType}');

    for (int i = 0; i < groupedHistory.length; i++) {
      final group = groupedHistory[i];
      debugPrint('🔍 [GROUPED-ORDER-HISTORY] Group $i: ${group.orders.length} orders');
    }

    debugPrint('🔍 [GROUPED-ORDER-HISTORY] ========== PROVIDER COMPLETED ==========');
    return groupedHistory;
  } catch (e, stackTrace) {
    debugPrint('🔍 [GROUPED-ORDER-HISTORY] ERROR: $e');
    debugPrint('🔍 [GROUPED-ORDER-HISTORY] Stack trace: $stackTrace');
    rethrow;
  }
});

/// Provider for order history summary statistics
final orderHistorySummaryProvider = FutureProvider.family<OrderHistorySummary, DateRangeFilter>((ref, filter) async {
  final groupedHistory = await ref.read(groupedOrderHistoryProvider(filter).future);
  return GroupedOrderHistory.getSummary(groupedHistory);
});

/// Enhanced provider for current selected quick filter with persistence
final selectedQuickFilterProvider = StateNotifierProvider<QuickFilterNotifier, QuickDateFilter>((ref) {
  return QuickFilterNotifier();
});

/// Provider that combines date filter with selected quick filter with enhanced logic
final combinedDateFilterProvider = Provider<DateRangeFilter>((ref) {
  final quickFilter = ref.watch(selectedQuickFilterProvider);
  final customFilter = ref.watch(dateFilterProvider);

  // If a quick filter is selected, use it; otherwise use custom filter
  if (quickFilter != QuickDateFilter.all) {
    final quickFilterRange = quickFilter.toDateRangeFilter();
    return quickFilterRange.copyWith(
      limit: customFilter.limit,
      offset: customFilter.offset,
      isPersistent: true,
      createdAt: DateTime.now(),
      metadata: {
        'source': 'quick_filter',
        'filterType': quickFilter.name,
        'performanceImpact': quickFilter.performanceImpact.name,
        'isCommonlyUsed': quickFilter.isCommonlyUsed,
      },
    );
  }

  return customFilter;
});

/// Provider for filter usage analytics
final filterAnalyticsProvider = FutureProvider<Map<String, int>>((ref) async {
  final quickFilterNotifier = ref.read(selectedQuickFilterProvider.notifier);
  return await quickFilterNotifier.getFilterAnalytics();
});

/// Provider for commonly used filters (for UI optimization)
final commonFiltersProvider = Provider<List<QuickDateFilter>>((ref) {
  return QuickDateFilter.values.where((filter) => filter.isCommonlyUsed).toList();
});

/// Convenience provider that automatically uses the combined filter
final autoFilteredOrderHistoryProvider = FutureProvider<List<Order>>((ref) async {
  final filter = ref.watch(combinedDateFilterProvider);
  return ref.read(enhancedDriverOrderHistoryProvider(filter).future);
});

/// Convenience provider for auto-filtered grouped history
final autoFilteredGroupedHistoryProvider = FutureProvider<List<GroupedOrderHistory>>((ref) async {
  final filter = ref.watch(combinedDateFilterProvider);
  return ref.read(groupedOrderHistoryProvider(filter).future);
});
