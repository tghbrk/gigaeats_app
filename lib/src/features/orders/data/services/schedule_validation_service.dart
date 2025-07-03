import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../user_management/domain/vendor.dart';
import '../../../core/utils/logger.dart';

/// Service for validating order scheduling
class ScheduleValidationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AppLogger _logger = AppLogger();

  /// Validate a scheduled delivery time
  Future<ScheduleValidationResult> validateSchedule({
    required DateTime dateTime,
    String? vendorId,
    Vendor? vendor,
    int minimumAdvanceHours = 2,
    bool allowSameDay = true,
  }) async {
    try {
      _logger.info('📅 [SCHEDULE-VALIDATION] Validating schedule: $dateTime');

      final validationChecks = <ScheduleValidationCheck>[];

      // Check 1: Basic time validation
      final basicCheck = _validateBasicTime(dateTime, minimumAdvanceHours, allowSameDay);
      validationChecks.add(basicCheck);

      // Check 2: Business hours validation
      final businessHoursCheck = _validateBusinessHours(dateTime);
      validationChecks.add(businessHoursCheck);

      // Check 3: Vendor-specific validation
      if (vendor != null || vendorId != null) {
        final vendorCheck = await _validateVendorAvailability(
          dateTime,
          vendor: vendor,
          vendorId: vendorId,
        );
        validationChecks.add(vendorCheck);
      }

      // Check 4: Holiday and special day validation
      final holidayCheck = await _validateHolidays(dateTime);
      validationChecks.add(holidayCheck);

      // Check 5: Capacity validation
      final capacityCheck = await _validateDeliveryCapacity(dateTime, vendorId);
      validationChecks.add(capacityCheck);

      // Determine overall result
      final hasErrors = validationChecks.any((check) => !check.isValid && check.severity == ValidationSeverity.error);
      final hasWarnings = validationChecks.any((check) => !check.isValid && check.severity == ValidationSeverity.warning);

      final isValid = !hasErrors;
      final message = _generateValidationMessage(validationChecks, isValid);

      final result = ScheduleValidationResult(
        isValid: isValid,
        message: message,
        checks: validationChecks,
        hasWarnings: hasWarnings,
        estimatedDeliveryWindow: _calculateDeliveryWindow(dateTime),
        alternativeSuggestions: isValid ? [] : _generateAlternatives(dateTime, validationChecks),
      );

      _logger.info('✅ [SCHEDULE-VALIDATION] Validation completed: ${result.isValid}');
      return result;

    } catch (e) {
      _logger.error('❌ [SCHEDULE-VALIDATION] Validation failed', e);
      
      return ScheduleValidationResult(
        isValid: false,
        message: 'Validation service error: ${e.toString()}',
        checks: [
          ScheduleValidationCheck(
            type: ScheduleValidationType.system,
            isValid: false,
            severity: ValidationSeverity.error,
            message: 'System error during validation',
          ),
        ],
      );
    }
  }

  /// Validate multiple time slots in batch
  Future<Map<DateTime, ScheduleValidationResult>> validateBatch({
    required List<DateTime> dateTimes,
    String? vendorId,
    Vendor? vendor,
    int minimumAdvanceHours = 2,
    bool allowSameDay = true,
  }) async {
    final results = <DateTime, ScheduleValidationResult>{};

    for (final dateTime in dateTimes) {
      final result = await validateSchedule(
        dateTime: dateTime,
        vendorId: vendorId,
        vendor: vendor,
        minimumAdvanceHours: minimumAdvanceHours,
        allowSameDay: allowSameDay,
      );
      results[dateTime] = result;
    }

    return results;
  }

  /// Get available time slots for a specific date
  Future<List<TimeSlot>> getAvailableTimeSlots({
    required DateTime date,
    String? vendorId,
    Vendor? vendor,
    int minimumAdvanceHours = 2,
  }) async {
    try {
      final slots = <TimeSlot>[];
      final startHour = 8; // 8 AM
      final endHour = 22; // 10 PM
      final slotDuration = 30; // 30 minutes

      for (int hour = startHour; hour < endHour; hour++) {
        for (int minute = 0; minute < 60; minute += slotDuration) {
          final slotTime = DateTime(date.year, date.month, date.day, hour, minute);
          
          final validation = await validateSchedule(
            dateTime: slotTime,
            vendorId: vendorId,
            vendor: vendor,
            minimumAdvanceHours: minimumAdvanceHours,
          );

          slots.add(TimeSlot(
            dateTime: slotTime,
            isAvailable: validation.isValid,
            hasWarnings: validation.hasWarnings,
            reason: validation.isValid ? null : validation.message,
          ));
        }
      }

      return slots;
    } catch (e) {
      _logger.error('❌ [SCHEDULE-VALIDATION] Failed to get time slots', e);
      return [];
    }
  }

  ScheduleValidationCheck _validateBasicTime(
    DateTime dateTime,
    int minimumAdvanceHours,
    bool allowSameDay,
  ) {
    final now = DateTime.now();
    
    // Check if time is in the past
    if (dateTime.isBefore(now)) {
      return ScheduleValidationCheck(
        type: ScheduleValidationType.timing,
        isValid: false,
        severity: ValidationSeverity.error,
        message: 'Scheduled time cannot be in the past',
      );
    }

    // Check minimum advance notice
    final minimumTime = now.add(Duration(hours: minimumAdvanceHours));
    if (dateTime.isBefore(minimumTime)) {
      return ScheduleValidationCheck(
        type: ScheduleValidationType.timing,
        isValid: false,
        severity: ValidationSeverity.error,
        message: 'Please schedule at least $minimumAdvanceHours hours in advance',
      );
    }

    // Check same-day restriction
    if (!allowSameDay) {
      final today = DateTime(now.year, now.month, now.day);
      final scheduledDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
      
      if (scheduledDay == today) {
        return ScheduleValidationCheck(
          type: ScheduleValidationType.timing,
          isValid: false,
          severity: ValidationSeverity.error,
          message: 'Same-day delivery is not available',
        );
      }
    }

    return ScheduleValidationCheck(
      type: ScheduleValidationType.timing,
      isValid: true,
      severity: ValidationSeverity.info,
      message: 'Timing is valid',
    );
  }

  ScheduleValidationCheck _validateBusinessHours(DateTime dateTime) {
    final hour = dateTime.hour;
    
    // Standard business hours: 8 AM to 10 PM
    if (hour < 8 || hour >= 22) {
      return ScheduleValidationCheck(
        type: ScheduleValidationType.businessHours,
        isValid: false,
        severity: ValidationSeverity.error,
        message: 'Delivery time must be between 8:00 AM and 10:00 PM',
      );
    }

    // Warning for early morning or late evening
    if (hour < 9 || hour >= 21) {
      return ScheduleValidationCheck(
        type: ScheduleValidationType.businessHours,
        isValid: true,
        severity: ValidationSeverity.warning,
        message: 'Delivery scheduled during extended hours',
      );
    }

    return ScheduleValidationCheck(
      type: ScheduleValidationType.businessHours,
      isValid: true,
      severity: ValidationSeverity.info,
      message: 'Within business hours',
    );
  }

  Future<ScheduleValidationCheck> _validateVendorAvailability(
    DateTime dateTime, {
    Vendor? vendor,
    String? vendorId,
  }) async {
    try {
      // If vendor object is provided, check its business hours
      if (vendor != null) {
        // TODO: Implement proper vendor business hours checking
        // For now, assume vendor is available during standard hours
        return ScheduleValidationCheck(
          type: ScheduleValidationType.vendorHours,
          isValid: true,
          severity: ValidationSeverity.info,
          message: 'Vendor is available',
        );
      }

      // If only vendorId is provided, fetch vendor data
      if (vendorId != null) {
        final vendorData = await _getVendorBusinessHours(vendorId);
        
        if (vendorData != null) {
          final isOpen = _isVendorOpenAt(vendorData, dateTime);
          
          return ScheduleValidationCheck(
            type: ScheduleValidationType.vendorHours,
            isValid: isOpen,
            severity: isOpen ? ValidationSeverity.info : ValidationSeverity.error,
            message: isOpen 
                ? 'Vendor is open at scheduled time'
                : 'Vendor is closed at scheduled time',
          );
        }
      }

      return ScheduleValidationCheck(
        type: ScheduleValidationType.vendorHours,
        isValid: true,
        severity: ValidationSeverity.warning,
        message: 'Vendor availability could not be verified',
      );

    } catch (e) {
      return ScheduleValidationCheck(
        type: ScheduleValidationType.vendorHours,
        isValid: false,
        severity: ValidationSeverity.warning,
        message: 'Failed to check vendor availability',
      );
    }
  }

  Future<ScheduleValidationCheck> _validateHolidays(DateTime dateTime) async {
    try {
      // Check for Malaysian public holidays
      final holidays = await _getHolidays(dateTime.year);
      final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);
      
      final isHoliday = holidays.any((holiday) => 
          DateTime(holiday.year, holiday.month, holiday.day) == dateOnly);

      if (isHoliday) {
        return ScheduleValidationCheck(
          type: ScheduleValidationType.holiday,
          isValid: true,
          severity: ValidationSeverity.warning,
          message: 'Scheduled on a public holiday - delivery may be delayed',
        );
      }

      return ScheduleValidationCheck(
        type: ScheduleValidationType.holiday,
        isValid: true,
        severity: ValidationSeverity.info,
        message: 'No holiday conflicts',
      );

    } catch (e) {
      return ScheduleValidationCheck(
        type: ScheduleValidationType.holiday,
        isValid: true,
        severity: ValidationSeverity.info,
        message: 'Holiday check unavailable',
      );
    }
  }

  Future<ScheduleValidationCheck> _validateDeliveryCapacity(
    DateTime dateTime,
    String? vendorId,
  ) async {
    try {
      // Check delivery capacity for the time slot
      final hourSlot = DateTime(dateTime.year, dateTime.month, dateTime.day, dateTime.hour);
      
      // Mock capacity check - in real implementation, check against database
      final ordersInSlot = await _getOrdersInTimeSlot(hourSlot, vendorId);
      const maxOrdersPerHour = 10; // Configurable limit

      if (ordersInSlot >= maxOrdersPerHour) {
        return ScheduleValidationCheck(
          type: ScheduleValidationType.capacity,
          isValid: false,
          severity: ValidationSeverity.error,
          message: 'Time slot is fully booked',
        );
      }

      if (ordersInSlot >= maxOrdersPerHour * 0.8) {
        return ScheduleValidationCheck(
          type: ScheduleValidationType.capacity,
          isValid: true,
          severity: ValidationSeverity.warning,
          message: 'Time slot is almost full',
        );
      }

      return ScheduleValidationCheck(
        type: ScheduleValidationType.capacity,
        isValid: true,
        severity: ValidationSeverity.info,
        message: 'Time slot available',
      );

    } catch (e) {
      return ScheduleValidationCheck(
        type: ScheduleValidationType.capacity,
        isValid: true,
        severity: ValidationSeverity.warning,
        message: 'Capacity check unavailable',
      );
    }
  }

  String _generateValidationMessage(List<ScheduleValidationCheck> checks, bool isValid) {
    if (isValid) {
      final warnings = checks.where((c) => c.severity == ValidationSeverity.warning).toList();
      if (warnings.isNotEmpty) {
        return warnings.first.message;
      }
      return 'Schedule is valid and available';
    } else {
      final errors = checks.where((c) => !c.isValid && c.severity == ValidationSeverity.error).toList();
      if (errors.isNotEmpty) {
        return errors.first.message;
      }
      return 'Schedule validation failed';
    }
  }

  DeliveryWindow _calculateDeliveryWindow(DateTime scheduledTime) {
    // Calculate a 30-minute delivery window
    final startTime = scheduledTime.subtract(const Duration(minutes: 15));
    final endTime = scheduledTime.add(const Duration(minutes: 15));
    
    return DeliveryWindow(
      startTime: startTime,
      endTime: endTime,
      estimatedTime: scheduledTime,
    );
  }

  List<DateTime> _generateAlternatives(DateTime originalTime, List<ScheduleValidationCheck> checks) {
    final alternatives = <DateTime>[];
    
    // Suggest next available hour
    alternatives.add(originalTime.add(const Duration(hours: 1)));
    
    // Suggest same time next day
    alternatives.add(originalTime.add(const Duration(days: 1)));
    
    // Suggest earlier time same day if possible
    if (originalTime.hour > 9) {
      alternatives.add(originalTime.subtract(const Duration(hours: 1)));
    }
    
    return alternatives.take(3).toList();
  }

  Future<Map<String, dynamic>?> _getVendorBusinessHours(String vendorId) async {
    try {
      final response = await _supabase
          .from('vendor_business_hours')
          .select()
          .eq('vendor_id', vendorId)
          .single();
      
      return response;
    } catch (e) {
      return null;
    }
  }

  bool _isVendorOpenAt(Map<String, dynamic> businessHours, DateTime dateTime) {
    // Simplified check - in real implementation, parse business hours properly
    return true;
  }

  Future<List<DateTime>> _getHolidays(int year) async {
    // Mock Malaysian holidays - in real implementation, fetch from API or database
    return [
      DateTime(year, 1, 1), // New Year
      DateTime(year, 8, 31), // Merdeka Day
      DateTime(year, 12, 25), // Christmas
    ];
  }

  Future<int> _getOrdersInTimeSlot(DateTime hourSlot, String? vendorId) async {
    try {
      final endSlot = hourSlot.add(const Duration(hours: 1));
      
      var query = _supabase
          .from('orders')
          .select('id')
          .gte('scheduled_delivery_time', hourSlot.toIso8601String())
          .lt('scheduled_delivery_time', endSlot.toIso8601String());

      if (vendorId != null) {
        query = query.eq('vendor_id', vendorId);
      }

      final response = await query;
      return response.length;
    } catch (e) {
      return 0;
    }
  }
}

/// Schedule validation result
class ScheduleValidationResult {
  final bool isValid;
  final String? message;
  final List<ScheduleValidationCheck> checks;
  final bool hasWarnings;
  final DeliveryWindow? estimatedDeliveryWindow;
  final List<DateTime> alternativeSuggestions;

  const ScheduleValidationResult({
    required this.isValid,
    this.message,
    this.checks = const [],
    this.hasWarnings = false,
    this.estimatedDeliveryWindow,
    this.alternativeSuggestions = const [],
  });
}

/// Individual validation check
class ScheduleValidationCheck {
  final ScheduleValidationType type;
  final bool isValid;
  final ValidationSeverity severity;
  final String message;

  const ScheduleValidationCheck({
    required this.type,
    required this.isValid,
    required this.severity,
    required this.message,
  });
}

/// Time slot availability
class TimeSlot {
  final DateTime dateTime;
  final bool isAvailable;
  final bool hasWarnings;
  final String? reason;

  const TimeSlot({
    required this.dateTime,
    required this.isAvailable,
    this.hasWarnings = false,
    this.reason,
  });
}

/// Delivery window
class DeliveryWindow {
  final DateTime startTime;
  final DateTime endTime;
  final DateTime estimatedTime;

  const DeliveryWindow({
    required this.startTime,
    required this.endTime,
    required this.estimatedTime,
  });
}

/// Validation enums
enum ScheduleValidationType { timing, businessHours, vendorHours, holiday, capacity, system }
enum ValidationSeverity { info, warning, error }
