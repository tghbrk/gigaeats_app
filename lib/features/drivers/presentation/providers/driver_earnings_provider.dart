import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../data/models/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/driver_earnings.dart';
import '../../data/services/driver_earnings_service.dart';

/// Provider for driver earnings service
final driverEarningsServiceProvider = Provider<DriverEarningsService>((ref) {
  return DriverEarningsService();
});

/// Provider for current driver ID - using autoDispose to prevent memory leaks
final currentDriverIdProvider = FutureProvider.autoDispose<String?>((ref) async {
  final authState = ref.read(authStateProvider);

  if (authState.user?.role != UserRole.driver) {
    return null;
  }

  try {
    final userId = authState.user?.id ?? '';
    if (userId.isEmpty) {
      return null;
    }

    final supabase = Supabase.instance.client;
    final driverResponse = await supabase
        .from('drivers')
        .select('id')
        .eq('user_id', userId)
        .single();

    final driverId = driverResponse['id'] as String;
    debugPrint('🚗 Found driver ID: $driverId');
    return driverId;
  } catch (e) {
    debugPrint('Error getting driver ID: $e');
    return null;
  }
});

/// Stable parameter class to prevent infinite rebuilds
class EarningsParams {
  final String driverId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String period;
  final String stableKey;

  const EarningsParams({
    required this.driverId,
    this.startDate,
    this.endDate,
    required this.period,
    required this.stableKey,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EarningsParams &&
          runtimeType == other.runtimeType &&
          driverId == other.driverId &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          period == other.period &&
          stableKey == other.stableKey;

  @override
  int get hashCode =>
      driverId.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      period.hashCode ^
      stableKey.hashCode;

  @override
  String toString() => 'EarningsParams(driverId: $driverId, period: $period, stableKey: $stableKey)';
}

/// Provider for driver earnings summary - fixed to prevent infinite loops
final driverEarningsSummaryProvider = FutureProvider.family<Map<String, dynamic>, EarningsParams>((ref, params) async {
  debugPrint('💰 driverEarningsSummaryProvider called with params: $params at ${DateTime.now()}');
  final earningsService = ref.read(driverEarningsServiceProvider);

  try {
    final result = await earningsService.getDriverEarningsSummary(
      params.driverId,
      startDate: params.startDate,
      endDate: params.endDate,
    );
    debugPrint('💰 driverEarningsSummaryProvider: result = $result');
    return result;
  } catch (e) {
    debugPrint('💰 Error getting driver earnings summary: $e');
    return {};
  }
});

/// Provider for driver earnings breakdown - fixed to prevent infinite loops
final driverEarningsBreakdownProvider = FutureProvider.family<Map<String, double>, EarningsParams>((ref, params) async {
  debugPrint('💰 driverEarningsBreakdownProvider called with params: $params at ${DateTime.now()}');
  final earningsService = ref.read(driverEarningsServiceProvider);

  try {
    final result = await earningsService.getDriverEarningsBreakdown(
      params.driverId,
      startDate: params.startDate,
      endDate: params.endDate,
    );
    debugPrint('💰 driverEarningsBreakdownProvider: result = $result');
    return result;
  } catch (e) {
    debugPrint('💰 Error getting driver earnings breakdown: $e');
    return {};
  }
});

/// Provider for driver earnings history
final driverEarningsHistoryProvider = FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final earningsService = ref.read(driverEarningsServiceProvider);
  final driverId = await ref.watch(currentDriverIdProvider.future);

  if (driverId == null) {
    return [];
  }

  try {
    return await earningsService.getDriverEarningsHistory(
      driverId,
      page: params['page'] as int? ?? 1,
      limit: params['limit'] as int? ?? 20,
      startDate: params['startDate'] as DateTime?,
      endDate: params['endDate'] as DateTime?,
    );
  } catch (e) {
    debugPrint('Error getting driver earnings history: $e');
    return [];
  }
});

/// Provider for daily earnings data (for charts)
final driverDailyEarningsProvider = FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final earningsService = ref.read(driverEarningsServiceProvider);
  final driverId = await ref.watch(currentDriverIdProvider.future);

  if (driverId == null) {
    return [];
  }

  try {
    return await earningsService.getDailyEarnings(
      driverId,
      startDate: params['startDate'] as DateTime?,
      endDate: params['endDate'] as DateTime?,
    );
  } catch (e) {
    debugPrint('Error getting driver daily earnings: $e');
    return [];
  }
});

/// Provider for driver commission structure
final driverCommissionStructureProvider = FutureProvider.family<DriverCommissionStructure?, Map<String, String>>((ref, params) async {
  final earningsService = ref.read(driverEarningsServiceProvider);
  final driverId = await ref.watch(currentDriverIdProvider.future);

  if (driverId == null) {
    return null;
  }

  try {
    return await earningsService.getDriverCommissionStructure(
      driverId,
      params['vendorId']!,
    );
  } catch (e) {
    debugPrint('Error getting driver commission structure: $e');
    return null;
  }
});

/// Real-time provider for driver earnings
final driverEarningsStreamProvider = StreamProvider.autoDispose<List<DriverEarnings>>((ref) async* {
  final earningsService = ref.read(driverEarningsServiceProvider);
  final driverId = await ref.watch(currentDriverIdProvider.future);

  if (driverId == null) {
    yield <DriverEarnings>[];
    return;
  }

  yield* earningsService.streamDriverEarnings(driverId);
});

/// State notifier for managing earnings screen state
class DriverEarningsState {
  final String selectedPeriod;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isLoading;
  final String? error;
  final Map<String, DateTime?>? _cachedDateRange;

  const DriverEarningsState({
    this.selectedPeriod = 'Today',
    this.startDate,
    this.endDate,
    this.isLoading = false,
    this.error,
    Map<String, DateTime?>? cachedDateRange,
  }) : _cachedDateRange = cachedDateRange;

  DriverEarningsState copyWith({
    String? selectedPeriod,
    DateTime? startDate,
    DateTime? endDate,
    bool? isLoading,
    String? error,
  }) {
    return DriverEarningsState(
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      cachedDateRange: selectedPeriod != null ? null : _cachedDateRange, // Clear cache if period changed
    );
  }

  /// Get date range based on selected period
  Map<String, DateTime?> get dateRange {
    // Return cached range if available and period hasn't changed
    if (_cachedDateRange != null) {
      return _cachedDateRange;
    }

    final now = DateTime.now();
    Map<String, DateTime?> range;

    switch (selectedPeriod) {
      case 'Today':
        range = {
          'startDate': DateTime(now.year, now.month, now.day),
          'endDate': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };
        break;
      case 'This Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        range = {
          'startDate': DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
          'endDate': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };
        break;
      case 'This Month':
        range = {
          'startDate': DateTime(now.year, now.month, 1),
          'endDate': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };
        break;
      case 'All Time':
        range = {
          'startDate': null,
          'endDate': null,
        };
        break;
      default:
        range = {
          'startDate': startDate,
          'endDate': endDate,
        };
        break;
    }

    return range;
  }
}

class DriverEarningsNotifier extends StateNotifier<DriverEarningsState> {
  DriverEarningsNotifier() : super(const DriverEarningsState());

  void setPeriod(String period) {
    state = state.copyWith(selectedPeriod: period);
  }

  void setCustomDateRange(DateTime? startDate, DateTime? endDate) {
    state = state.copyWith(
      selectedPeriod: 'Custom',
      startDate: startDate,
      endDate: endDate,
    );
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }
}

/// Provider for driver earnings state
final driverEarningsStateProvider = StateNotifierProvider<DriverEarningsNotifier, DriverEarningsState>((ref) {
  return DriverEarningsNotifier();
});


