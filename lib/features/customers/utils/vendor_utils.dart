import 'package:flutter/material.dart';
import '../../vendors/data/models/vendor.dart';

class VendorUtils {
  /// Check if vendor is currently open based on business hours
  static bool isVendorOpen(Vendor vendor) {
    if (!vendor.isActive) return false;
    
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    
    final businessHours = vendor.businessHours;
    if (businessHours == null || businessHours.isEmpty) {
      // Default to open if no hours specified
      return true;
    }
    
    final daySchedule = businessHours[dayName];
    if (daySchedule == null) return false;
    
    // Parse day schedule
    final isOpen = daySchedule['isOpen'] as bool? ?? false;
    if (!isOpen) return false;
    
    final openTime = daySchedule['openTime'] as String?;
    final closeTime = daySchedule['closeTime'] as String?;
    
    if (openTime == null || closeTime == null) return false;
    
    try {
      final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);
      final openTimeOfDay = _parseTimeString(openTime);
      final closeTimeOfDay = _parseTimeString(closeTime);
      
      if (openTimeOfDay == null || closeTimeOfDay == null) return false;
      
      // Handle overnight hours (e.g., 22:00 - 02:00)
      if (_isTimeAfter(closeTimeOfDay, openTimeOfDay)) {
        // Normal hours (e.g., 09:00 - 18:00)
        return _isTimeBetween(currentTime, openTimeOfDay, closeTimeOfDay);
      } else {
        // Overnight hours (e.g., 22:00 - 02:00)
        return _isTimeAfter(currentTime, openTimeOfDay) || 
               _isTimeBefore(currentTime, closeTimeOfDay);
      }
    } catch (e) {
      // If parsing fails, assume open
      return true;
    }
  }
  
  /// Get vendor status text (Open/Closed/Opens at X)
  static String getVendorStatusText(Vendor vendor) {
    if (!vendor.isActive) return 'Temporarily Closed';
    
    if (isVendorOpen(vendor)) {
      return 'Open';
    }
    
    // Find next opening time
    final nextOpenTime = getNextOpeningTime(vendor);
    if (nextOpenTime != null) {
      final now = DateTime.now();
      final difference = nextOpenTime.difference(now);
      
      if (difference.inDays == 0) {
        return 'Opens at ${_formatTime(TimeOfDay(hour: nextOpenTime.hour, minute: nextOpenTime.minute))}';
      } else if (difference.inDays == 1) {
        return 'Opens tomorrow at ${_formatTime(TimeOfDay(hour: nextOpenTime.hour, minute: nextOpenTime.minute))}';
      } else {
        return 'Opens ${_getDayName(nextOpenTime.weekday)} at ${_formatTime(TimeOfDay(hour: nextOpenTime.hour, minute: nextOpenTime.minute))}';
      }
    }
    
    return 'Closed';
  }
  
  /// Get next opening time for a vendor
  static DateTime? getNextOpeningTime(Vendor vendor) {
    if (!vendor.isActive) return null;
    
    final businessHours = vendor.businessHours;
    if (businessHours == null || businessHours.isEmpty) return null;
    
    final now = DateTime.now();
    
    // Check next 7 days
    for (int i = 0; i < 7; i++) {
      final checkDate = now.add(Duration(days: i));
      final dayName = _getDayName(checkDate.weekday);
      final daySchedule = businessHours[dayName];
      
      if (daySchedule == null) continue;
      
      final isOpen = daySchedule['isOpen'] as bool? ?? false;
      if (!isOpen) continue;
      
      final openTime = daySchedule['openTime'] as String?;
      if (openTime == null) continue;
      
      final openTimeOfDay = _parseTimeString(openTime);
      if (openTimeOfDay == null) continue;
      
      final openDateTime = DateTime(
        checkDate.year,
        checkDate.month,
        checkDate.day,
        openTimeOfDay.hour,
        openTimeOfDay.minute,
      );
      
      // If it's today, check if opening time is in the future
      if (i == 0 && openDateTime.isBefore(now)) continue;
      
      return openDateTime;
    }
    
    return null;
  }
  
  /// Format business hours for display
  static String formatBusinessHours(Vendor vendor) {
    final businessHours = vendor.businessHours;
    if (businessHours == null || businessHours.isEmpty) {
      return 'Hours not specified';
    }
    
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    final hoursText = <String>[];
    
    for (int i = 0; i < days.length; i++) {
      final daySchedule = businessHours[days[i]];
      if (daySchedule == null) continue;
      
      final isOpen = daySchedule['isOpen'] as bool? ?? false;
      if (!isOpen) {
        hoursText.add('${dayNames[i]}: Closed');
        continue;
      }
      
      final openTime = daySchedule['openTime'] as String?;
      final closeTime = daySchedule['closeTime'] as String?;
      
      if (openTime != null && closeTime != null) {
        hoursText.add('${dayNames[i]}: $openTime - $closeTime');
      } else {
        hoursText.add('${dayNames[i]}: Open');
      }
    }
    
    return hoursText.join('\n');
  }
  
  /// Get today's business hours
  static String getTodayHours(Vendor vendor) {
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    
    final businessHours = vendor.businessHours;
    if (businessHours == null || businessHours.isEmpty) {
      return 'Hours not specified';
    }
    
    final daySchedule = businessHours[dayName];
    if (daySchedule == null) return 'Closed today';
    
    final isOpen = daySchedule['isOpen'] as bool? ?? false;
    if (!isOpen) return 'Closed today';
    
    final openTime = daySchedule['openTime'] as String?;
    final closeTime = daySchedule['closeTime'] as String?;
    
    if (openTime != null && closeTime != null) {
      return '$openTime - $closeTime';
    }
    
    return 'Open today';
  }
  
  /// Calculate estimated delivery time
  static String getEstimatedDeliveryTime(Vendor vendor, {int additionalMinutes = 0}) {
    // Base delivery time (could be from vendor settings or calculated)
    int baseDeliveryMinutes = 30; // Default

    // Add preparation time if available
    // This would typically come from menu items or vendor settings
    int totalMinutes = baseDeliveryMinutes + additionalMinutes;

    if (totalMinutes < 60) {
      return '$totalMinutes mins';
    } else {
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}m';
      }
    }
  }
  
  /// Format delivery fee display
  static String formatDeliveryFee(double? deliveryFee, double? freeDeliveryThreshold, double orderAmount) {
    if (deliveryFee == null || deliveryFee == 0) {
      return 'Free delivery';
    }
    
    if (freeDeliveryThreshold != null && orderAmount >= freeDeliveryThreshold) {
      return 'Free delivery';
    }
    
    return 'RM${deliveryFee.toStringAsFixed(2)}';
  }
  
  /// Helper methods
  static String _getDayName(int weekday) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[weekday - 1];
  }
  
  static TimeOfDay? _parseTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return null;
      
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }
  
  static bool _isTimeBetween(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }
  
  static bool _isTimeAfter(TimeOfDay current, TimeOfDay reference) {
    final currentMinutes = current.hour * 60 + current.minute;
    final referenceMinutes = reference.hour * 60 + reference.minute;
    
    return currentMinutes >= referenceMinutes;
  }
  
  static bool _isTimeBefore(TimeOfDay current, TimeOfDay reference) {
    final currentMinutes = current.hour * 60 + current.minute;
    final referenceMinutes = reference.hour * 60 + reference.minute;
    
    return currentMinutes <= referenceMinutes;
  }
  
  static String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : hour;
    return '$displayHour:$minute $period';
  }
}


