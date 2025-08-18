import 'package:flutter/material.dart';

/// GigaEats Vendor-Specific Color Palette
/// 
/// Colors specifically designed for the vendor dashboard interface
/// based on the UI/UX mockup specifications.
class GEVendorColors {
  // Prevent instantiation
  GEVendorColors._();

  // Primary Colors (from mockup)
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color primaryGreenDark = Color(0xFF388E3C);
  static const Color secondaryBlue = Color(0xFF2196F3);
  static const Color accentPurple = Color(0xFF9C27B0);
  
  // Status Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color dangerRed = Color(0xFFF44336);
  static const Color warningOrange = Color(0xFFFF9800);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);
  
  // Background Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE0E0E0);
  
  // Metric Card Icon Colors (with transparency backgrounds)
  static const Color revenueIconColor = dangerRed;
  static const Color ordersIconColor = secondaryBlue;
  static const Color valueIconColor = accentPurple;
  static const Color ratingIconColor = warningOrange;
  
  // Icon Background Colors (10% opacity)
  static Color get revenueIconBackground => revenueIconColor.withValues(alpha: 0.1);
  static Color get ordersIconBackground => ordersIconColor.withValues(alpha: 0.1);
  static Color get valueIconBackground => valueIconColor.withValues(alpha: 0.1);
  static Color get ratingIconBackground => ratingIconColor.withValues(alpha: 0.1);
  
  // Quick Action Button Colors
  static const Color quickActionPrimary = primaryGreen;
  static const Color quickActionSecondary = secondaryBlue;
  static const Color quickActionTertiary = accentPurple;
  
  // Trend Colors
  static const Color trendPositive = successGreen;
  static const Color trendNegative = dangerRed;
  static const Color trendNeutral = textLight;
  
  // Chart Colors
  static const Color chartPrimary = primaryGreen;
  static const Color chartSecondary = secondaryBlue;
  static const Color chartAccent = accentPurple;
  
  // Shadow Colors
  static Color get shadowLight => const Color(0x00000000).withValues(alpha: 0.1);
  static Color get shadowMedium => const Color(0x00000000).withValues(alpha: 0.15);
  
  /// Get icon color for metric type
  static Color getMetricIconColor(String metricType) {
    switch (metricType.toLowerCase()) {
      case 'revenue':
      case 'earnings':
      case 'income':
        return revenueIconColor;
      case 'orders':
      case 'sales':
      case 'transactions':
        return ordersIconColor;
      case 'value':
      case 'average':
      case 'avg':
        return valueIconColor;
      case 'rating':
      case 'reviews':
      case 'feedback':
        return ratingIconColor;
      default:
        return primaryGreen;
    }
  }
  
  /// Get icon background color for metric type
  static Color getMetricIconBackground(String metricType) {
    return getMetricIconColor(metricType).withValues(alpha: 0.1);
  }
  
  /// Get trend color based on value
  static Color getTrendColor(double? value, {bool isPositiveBetter = true}) {
    if (value == null || value == 0) return trendNeutral;
    
    if (isPositiveBetter) {
      return value > 0 ? trendPositive : trendNegative;
    } else {
      return value > 0 ? trendNegative : trendPositive;
    }
  }
  
  /// Get chart color by index
  static Color getChartColor(int index) {
    final colors = [chartPrimary, chartSecondary, chartAccent];
    return colors[index % colors.length];
  }
}
