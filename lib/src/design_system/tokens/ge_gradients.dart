import 'package:flutter/material.dart';
import 'ge_vendor_colors.dart';

/// GigaEats Gradient Definitions
/// 
/// Predefined gradients for consistent visual styling across
/// the vendor dashboard interface.
class GEGradients {
  // Prevent instantiation
  GEGradients._();

  /// Header gradient (green to dark green)
  static const LinearGradient headerGradient = LinearGradient(
    colors: [GEVendorColors.primaryGreen, GEVendorColors.primaryGreenDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
  );
  
  /// Alternative header gradient (135 degrees as in mockup)
  static const LinearGradient headerGradient135 = LinearGradient(
    colors: [GEVendorColors.primaryGreen, GEVendorColors.primaryGreenDark],
    begin: Alignment(-0.7, -0.7), // Approximately 135 degrees
    end: Alignment(0.7, 0.7),
    stops: [0.0, 1.0],
  );
  
  /// Avatar gradient (green to blue)
  static const LinearGradient avatarGradient = LinearGradient(
    colors: [GEVendorColors.primaryGreen, GEVendorColors.secondaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
  );
  
  /// Card gradient (subtle background)
  static LinearGradient cardGradient(Color color) => LinearGradient(
    colors: [
      color.withValues(alpha: 0.1),
      color.withValues(alpha: 0.05),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: const [0.0, 1.0],
  );
  
  /// Success gradient
  static const LinearGradient successGradient = LinearGradient(
    colors: [GEVendorColors.successGreen, Color(0xFF66BB6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Warning gradient
  static const LinearGradient warningGradient = LinearGradient(
    colors: [GEVendorColors.warningOrange, Color(0xFFFFB74D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Danger gradient
  static const LinearGradient dangerGradient = LinearGradient(
    colors: [GEVendorColors.dangerRed, Color(0xFFEF5350)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Chart area gradient
  static LinearGradient chartAreaGradient(Color color) => LinearGradient(
    colors: [
      color.withValues(alpha: 0.3),
      color.withValues(alpha: 0.1),
      color.withValues(alpha: 0.0),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: const [0.0, 0.5, 1.0],
  );
  
  /// Shimmer gradient for loading states
  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [
      Color(0xFFEBEBF4),
      Color(0xFFF4F4F4),
      Color(0xFFEBEBF4),
    ],
    stops: [0.1, 0.3, 0.4],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );
  
  /// Get gradient by metric type
  static LinearGradient getMetricGradient(String metricType) {
    final color = GEVendorColors.getMetricIconColor(metricType);
    return cardGradient(color);
  }
  
  /// Get status gradient
  static LinearGradient getStatusGradient(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
      case 'delivered':
        return successGradient;
      case 'warning':
      case 'pending':
      case 'preparing':
        return warningGradient;
      case 'error':
      case 'failed':
      case 'cancelled':
        return dangerGradient;
      default:
        return cardGradient(GEVendorColors.primaryGreen);
    }
  }
}
