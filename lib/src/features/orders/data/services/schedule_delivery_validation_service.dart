import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/logger.dart';

/// Comprehensive validation service for scheduled delivery
class ScheduleDeliveryValidationService {
  final AppLogger _logger = AppLogger();

  /// Validate scheduled delivery time with comprehensive business rules
  ScheduleValidationResult validateScheduledTime({
    required DateTime scheduledTime,
    String? vendorId,
    dynamic vendor,
    int minimumAdvanceHours = 2,
    int maxDaysAhead = 7,
    bool checkBusinessHours = true,
    bool checkVendorHours = true,
  }) {
    _logger.info('🔍 [SCHEDULE-VALIDATION] Validating scheduled time: $scheduledTime');

    final now = DateTime.now();
    final errors = <String>[];
    final warnings = <String>[];

    // 1. Check if time is in the past
    if (scheduledTime.isBefore(now)) {
      errors.add('Cannot schedule delivery in the past');
      return ScheduleValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
      );
    }

    // 2. Check minimum advance notice
    final minimumAdvanceTime = now.add(Duration(hours: minimumAdvanceHours));
    if (scheduledTime.isBefore(minimumAdvanceTime)) {
      errors.add('Please schedule at least $minimumAdvanceHours hours in advance');
    }

    // 3. Check maximum advance time
    final maximumAdvanceTime = now.add(Duration(days: maxDaysAhead));
    if (scheduledTime.isAfter(maximumAdvanceTime)) {
      errors.add('Cannot schedule more than $maxDaysAhead days in advance');
    }

    // 4. Check business hours (8 AM to 10 PM)
    if (checkBusinessHours) {
      final hour = scheduledTime.hour;
      if (hour < 8 || hour > 22) {
        errors.add('Delivery time must be between 8:00 AM and 10:00 PM');
      }
    }

    // 5. Check day of week restrictions
    final dayOfWeek = scheduledTime.weekday;
    if (dayOfWeek == DateTime.sunday) {
      warnings.add('Sunday deliveries may have limited availability');
    }

    // 6. Check vendor-specific hours if available
    if (checkVendorHours && vendor != null) {
      final vendorValidation = _validateVendorHours(scheduledTime, vendor);
      if (!vendorValidation.isValid) {
        errors.addAll(vendorValidation.errors);
        warnings.addAll(vendorValidation.warnings);
      }
    }

    // 7. Check for peak hours (lunch and dinner rush)
    final peakHourValidation = _validatePeakHours(scheduledTime);
    warnings.addAll(peakHourValidation.warnings);

    // 8. Check for holidays or special dates
    final holidayValidation = _validateHolidays(scheduledTime);
    warnings.addAll(holidayValidation.warnings);

    final isValid = errors.isEmpty;
    
    _logger.info('✅ [SCHEDULE-VALIDATION] Validation result: $isValid (${errors.length} errors, ${warnings.length} warnings)');

    return ScheduleValidationResult(
      isValid: isValid,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate vendor-specific business hours
  ScheduleValidationResult _validateVendorHours(DateTime scheduledTime, dynamic vendor) {
    final errors = <String>[];
    final warnings = <String>[];

    // TODO: Implement vendor-specific validation when vendor model is available
    // For now, use placeholder logic
    
    // Example: Check if vendor is open on the scheduled day
    final dayOfWeek = scheduledTime.weekday;
    if (dayOfWeek == DateTime.monday) {
      // Some vendors might be closed on Mondays
      warnings.add('Some vendors may be closed on Mondays. Please verify with the restaurant.');
    }

    return ScheduleValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate peak hours and provide warnings
  ScheduleValidationResult _validatePeakHours(DateTime scheduledTime) {
    final warnings = <String>[];
    final hour = scheduledTime.hour;

    // Lunch rush: 12 PM - 2 PM
    if (hour >= 12 && hour <= 14) {
      warnings.add('Lunch rush hour - delivery may take longer than usual');
    }

    // Dinner rush: 6 PM - 8 PM
    if (hour >= 18 && hour <= 20) {
      warnings.add('Dinner rush hour - delivery may take longer than usual');
    }

    return ScheduleValidationResult(
      isValid: true,
      errors: [],
      warnings: warnings,
    );
  }

  /// Validate holidays and special dates
  ScheduleValidationResult _validateHolidays(DateTime scheduledTime) {
    final warnings = <String>[];

    // Check for major holidays (simplified implementation)
    final month = scheduledTime.month;
    final day = scheduledTime.day;

    // New Year's Day
    if (month == 1 && day == 1) {
      warnings.add('New Year\'s Day - limited vendor availability');
    }

    // Christmas Day
    if (month == 12 && day == 25) {
      warnings.add('Christmas Day - most vendors will be closed');
    }

    // Chinese New Year (approximate - varies by year)
    if (month == 1 || month == 2) {
      warnings.add('Chinese New Year period - some vendors may have modified hours');
    }

    // Hari Raya periods (approximate)
    if (month == 4 || month == 5) {
      warnings.add('Hari Raya period - some vendors may have modified hours');
    }

    return ScheduleValidationResult(
      isValid: true,
      errors: [],
      warnings: warnings,
    );
  }

  /// Get suggested alternative times if validation fails
  List<DateTime> getSuggestedTimes({
    required DateTime originalTime,
    String? vendorId,
    dynamic vendor,
    int minimumAdvanceHours = 2,
    int maxDaysAhead = 7,
  }) {
    final suggestions = <DateTime>[];
    final now = DateTime.now();

    // Start from the minimum advance time
    var suggestedTime = now.add(Duration(hours: minimumAdvanceHours));

    // Round to next hour
    suggestedTime = DateTime(
      suggestedTime.year,
      suggestedTime.month,
      suggestedTime.day,
      suggestedTime.hour + 1,
      0,
    );

    // Generate 5 suggestions
    for (int i = 0; i < 5; i++) {
      // Ensure it's within business hours
      if (suggestedTime.hour >= 8 && suggestedTime.hour <= 22) {
        final validation = validateScheduledTime(
          scheduledTime: suggestedTime,
          vendorId: vendorId,
          vendor: vendor,
          minimumAdvanceHours: minimumAdvanceHours,
          maxDaysAhead: maxDaysAhead,
        );

        if (validation.isValid) {
          suggestions.add(suggestedTime);
        }
      }

      // Move to next hour
      suggestedTime = suggestedTime.add(const Duration(hours: 1));

      // If we've gone past business hours, move to next day at 8 AM
      if (suggestedTime.hour > 22) {
        suggestedTime = DateTime(
          suggestedTime.year,
          suggestedTime.month,
          suggestedTime.day + 1,
          8,
          0,
        );
      }

      // Don't suggest beyond max days ahead
      if (suggestedTime.isAfter(now.add(Duration(days: maxDaysAhead)))) {
        break;
      }
    }

    return suggestions;
  }
}

/// Result of schedule validation
class ScheduleValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ScheduleValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  /// Get the primary error message
  String? get primaryError => errors.isNotEmpty ? errors.first : null;

  /// Get all messages combined
  List<String> get allMessages => [...errors, ...warnings];

  /// Check if there are any warnings
  bool get hasWarnings => warnings.isNotEmpty;
}

/// Provider for schedule delivery validation service
final scheduleDeliveryValidationServiceProvider = Provider<ScheduleDeliveryValidationService>((ref) {
  return ScheduleDeliveryValidationService();
});
