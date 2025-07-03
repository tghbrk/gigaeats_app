import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/schedule_delivery_validation_service.dart';
import '../../../core/utils/logger.dart';

/// Provider for schedule validation with caching and state management
class ScheduleValidationNotifier extends StateNotifier<ScheduleValidationState> {
  final ScheduleDeliveryValidationService _validationService;
  final AppLogger _logger = AppLogger();

  ScheduleValidationNotifier(this._validationService) 
      : super(const ScheduleValidationState());

  /// Validate a scheduled time and update state
  Future<void> validateScheduledTime({
    required DateTime scheduledTime,
    String? vendorId,
    dynamic vendor,
    int minimumAdvanceHours = 2,
    int maxDaysAhead = 7,
  }) async {
    _logger.info('🔍 [SCHEDULE-VALIDATION-PROVIDER] Validating: $scheduledTime');

    state = state.copyWith(isValidating: true, lastValidatedTime: scheduledTime);

    try {
      final result = _validationService.validateScheduledTime(
        scheduledTime: scheduledTime,
        vendorId: vendorId,
        vendor: vendor,
        minimumAdvanceHours: minimumAdvanceHours,
        maxDaysAhead: maxDaysAhead,
      );

      // Get suggested times if validation fails
      List<DateTime> suggestions = [];
      if (!result.isValid) {
        suggestions = _validationService.getSuggestedTimes(
          originalTime: scheduledTime,
          vendorId: vendorId,
          vendor: vendor,
          minimumAdvanceHours: minimumAdvanceHours,
          maxDaysAhead: maxDaysAhead,
        );
      }

      state = state.copyWith(
        isValidating: false,
        lastResult: result,
        suggestedTimes: suggestions,
        lastValidatedTime: scheduledTime,
      );

      _logger.info('✅ [SCHEDULE-VALIDATION-PROVIDER] Validation complete: ${result.isValid}');
    } catch (e, stack) {
      _logger.error('❌ [SCHEDULE-VALIDATION-PROVIDER] Validation error', e, stack);
      
      state = state.copyWith(
        isValidating: false,
        lastResult: const ScheduleValidationResult(
          isValid: false,
          errors: ['Validation failed. Please try again.'],
          warnings: [],
        ),
        suggestedTimes: [],
      );
    }
  }

  /// Clear validation state
  void clearValidation() {
    state = const ScheduleValidationState();
  }

  /// Get quick validation result without updating state
  ScheduleValidationResult quickValidate({
    required DateTime scheduledTime,
    String? vendorId,
    dynamic vendor,
    int minimumAdvanceHours = 2,
    int maxDaysAhead = 7,
  }) {
    return _validationService.validateScheduledTime(
      scheduledTime: scheduledTime,
      vendorId: vendorId,
      vendor: vendor,
      minimumAdvanceHours: minimumAdvanceHours,
      maxDaysAhead: maxDaysAhead,
    );
  }
}

/// State for schedule validation
class ScheduleValidationState {
  final bool isValidating;
  final ScheduleValidationResult? lastResult;
  final List<DateTime> suggestedTimes;
  final DateTime? lastValidatedTime;

  const ScheduleValidationState({
    this.isValidating = false,
    this.lastResult,
    this.suggestedTimes = const [],
    this.lastValidatedTime,
  });

  ScheduleValidationState copyWith({
    bool? isValidating,
    ScheduleValidationResult? lastResult,
    List<DateTime>? suggestedTimes,
    DateTime? lastValidatedTime,
  }) {
    return ScheduleValidationState(
      isValidating: isValidating ?? this.isValidating,
      lastResult: lastResult ?? this.lastResult,
      suggestedTimes: suggestedTimes ?? this.suggestedTimes,
      lastValidatedTime: lastValidatedTime ?? this.lastValidatedTime,
    );
  }

  /// Check if the given time matches the last validated time
  bool isTimeValidated(DateTime time) {
    return lastValidatedTime != null && 
           lastValidatedTime!.isAtSameMomentAs(time);
  }

  /// Get validation result for a specific time
  ScheduleValidationResult? getResultForTime(DateTime time) {
    return isTimeValidated(time) ? lastResult : null;
  }

  /// Check if validation is valid for a specific time
  bool isValidForTime(DateTime time) {
    final result = getResultForTime(time);
    return result?.isValid ?? false;
  }

  /// Get error message for a specific time
  String? getErrorForTime(DateTime time) {
    final result = getResultForTime(time);
    return result?.primaryError;
  }

  /// Get warnings for a specific time
  List<String> getWarningsForTime(DateTime time) {
    final result = getResultForTime(time);
    return result?.warnings ?? [];
  }
}

/// Provider for schedule validation
final scheduleValidationProvider = StateNotifierProvider<ScheduleValidationNotifier, ScheduleValidationState>((ref) {
  final validationService = ref.watch(scheduleDeliveryValidationServiceProvider);
  return ScheduleValidationNotifier(validationService);
});

/// Convenience providers
final isScheduleValidatingProvider = Provider<bool>((ref) {
  return ref.watch(scheduleValidationProvider).isValidating;
});

final lastScheduleValidationResultProvider = Provider<ScheduleValidationResult?>((ref) {
  return ref.watch(scheduleValidationProvider).lastResult;
});

final scheduleSuggestedTimesProvider = Provider<List<DateTime>>((ref) {
  return ref.watch(scheduleValidationProvider).suggestedTimes;
});

/// Provider for validating a specific time
final scheduleTimeValidationProvider = Provider.family<ScheduleValidationResult?, DateTime>((ref, time) {
  final state = ref.watch(scheduleValidationProvider);
  return state.getResultForTime(time);
});

/// Provider for checking if a specific time is valid
final isScheduleTimeValidProvider = Provider.family<bool, DateTime>((ref, time) {
  final state = ref.watch(scheduleValidationProvider);
  return state.isValidForTime(time);
});

/// Provider for getting error message for a specific time
final scheduleTimeErrorProvider = Provider.family<String?, DateTime>((ref, time) {
  final state = ref.watch(scheduleValidationProvider);
  return state.getErrorForTime(time);
});

/// Provider for getting warnings for a specific time
final scheduleTimeWarningsProvider = Provider.family<List<String>, DateTime>((ref, time) {
  final state = ref.watch(scheduleValidationProvider);
  return state.getWarningsForTime(time);
});
