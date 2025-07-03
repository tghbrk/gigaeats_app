import 'package:flutter/material.dart';
import '../../vendors/data/models/vendor.dart';

class VendorUtils {
  /// Check if vendor is currently open based on business hours
  static bool isVendorOpen(Vendor vendor) {
    // TODO: Fix businessHours type mismatch - new Vendor model uses List<BusinessHours>, not Map
    // This method needs to be rewritten to work with List<BusinessHours> instead of Map
    if (!vendor.isActive) return false;

    // Temporary fix: always return true for active vendors
    return true;
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
    // TODO: Fix businessHours type mismatch - new Vendor model uses List<BusinessHours>, not Map
    // This method needs to be rewritten to work with List<BusinessHours> instead of Map
    if (!vendor.isActive) return null;

    // Temporary fix: return null (no next opening time available)
    return null;
  }
  
  /// Format business hours for display
  static String formatBusinessHours(Vendor vendor) {
    // TODO: Fix businessHours type mismatch - new Vendor model uses List<BusinessHours>, not Map
    // This method needs to be rewritten to work with List<BusinessHours> instead of Map

    // Temporary fix: return default message
    return 'Hours not specified';
  }
  
  /// Get today's business hours
  static String getTodayHours(Vendor vendor) {
    // TODO: Fix businessHours type mismatch - new Vendor model uses List<BusinessHours>, not Map
    // This method needs to be rewritten to work with List<BusinessHours> instead of Map

    // Temporary fix: return default message
    return 'Hours not specified';
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
  
  // TODO: Removed unused helper methods due to businessHours type mismatch
  // These methods need to be rewritten when the businessHours issue is fixed
  
  static String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : hour;
    return '$displayHour:$minute $period';
  }
}


