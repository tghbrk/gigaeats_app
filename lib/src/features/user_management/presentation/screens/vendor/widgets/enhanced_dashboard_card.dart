import 'package:flutter/material.dart';
import '../../../../../../design_system/design_system.dart';
import 'mini_chart.dart';
import 'progress_indicator.dart';

/// Enhanced Dashboard Card for Vendor Dashboard
/// 
/// A sophisticated dashboard card that supports mini charts, progress bars,
/// trend indicators, and custom styling to match the UI/UX mockup.
class EnhancedDashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool isLoading;
  
  // Trend support
  final String? trend;
  final bool isPositiveTrend;
  final double? trendValue;
  
  // Chart support
  final List<double>? chartData;
  final bool showChart;
  
  // Progress support
  final double? progressValue;
  final bool showProgress;
  
  // Styling
  final String? metricType;
  final double? height;
  final EdgeInsetsGeometry? margin;

  const EnhancedDashboardCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.onTap,
    this.isLoading = false,
    this.trend,
    this.isPositiveTrend = true,
    this.trendValue,
    this.chartData,
    this.showChart = false,
    this.progressValue,
    this.showProgress = false,
    this.metricType,
    this.height,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 [ENHANCED-CARD] Building card: $title');
    debugPrint('🎨 [ENHANCED-CARD] Value: $value, Loading: $isLoading');
    debugPrint('🎨 [ENHANCED-CARD] Show chart: $showChart, Chart data: ${chartData?.length ?? 0} points');
    debugPrint('🎨 [ENHANCED-CARD] Show progress: $showProgress, Progress value: $progressValue');

    final theme = Theme.of(context);
    final cardIconColor = iconColor ??
        (metricType != null ? GEVendorColors.getMetricIconColor(metricType!) : GEVendorColors.primaryGreen);
    final cardIconBackground = metricType != null
        ? GEVendorColors.getMetricIconBackground(metricType!)
        : cardIconColor.withValues(alpha: 0.1);
    
    return Container(
      height: height ?? 120, // Reduced from 140 to 120
      margin: margin ?? const EdgeInsets.all(0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GESpacing.sm),
          child: Container(
            padding: const EdgeInsets.all(GESpacing.sm), // Reduced from md to sm
            decoration: BoxDecoration(
              color: GEVendorColors.cardBackground,
              borderRadius: BorderRadius.circular(GESpacing.sm),
              border: Border.all(
                color: GEVendorColors.borderLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: GEVendorColors.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isLoading ? _buildLoadingContent() : _buildCardContent(theme, cardIconColor, cardIconBackground),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildCardContent(ThemeData theme, Color cardIconColor, Color cardIconBackground) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Allow column to shrink to fit content
      children: [
        // Header with title and icon
        _buildHeader(theme, cardIconColor, cardIconBackground),

        const SizedBox(height: GESpacing.xs), // Reduced spacing

        // Value display - make flexible
        Flexible(
          child: _buildValue(theme),
        ),

        const SizedBox(height: 2), // Minimal spacing

        // Details section (subtitle and trend) - make flexible
        Flexible(
          child: _buildDetails(theme),
        ),

        // Chart or progress indicator - make flexible
        if (showChart && chartData != null) ...[
          const SizedBox(height: 2), // Minimal spacing
          Flexible(
            child: _buildMiniChart(),
          ),
        ] else if (showProgress && progressValue != null) ...[
          const SizedBox(height: 2), // Minimal spacing
          Flexible(
            child: _buildProgressIndicator(),
          ),
        ],
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, Color cardIconColor, Color cardIconBackground) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith( // Changed from bodyMedium to bodySmall
              color: GEVendorColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 12, // Explicit smaller font size
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          width: 28, // Reduced from 36 to 28
          height: 28, // Reduced from 36 to 28
          decoration: BoxDecoration(
            color: cardIconBackground,
            borderRadius: BorderRadius.circular(6), // Smaller radius
          ),
          child: Icon(
            icon,
            size: 16, // Reduced from 20 to 16
            color: cardIconColor,
          ),
        ),
      ],
    );
  }

  Widget _buildValue(ThemeData theme) {
    return Text(
      value,
      style: theme.textTheme.titleLarge?.copyWith( // Changed from headlineMedium to titleLarge
        color: GEVendorColors.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 20, // Further reduced from 24 to 20 to prevent overflow
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDetails(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (subtitle != null)
          Expanded(
            child: Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: GEVendorColors.textSecondary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (trend != null) _buildTrendIndicator(theme),
      ],
    );
  }

  Widget _buildTrendIndicator(ThemeData theme) {
    final trendColor = GEVendorColors.getTrendColor(trendValue, isPositiveBetter: true);
    final trendIcon = isPositiveTrend ? Icons.arrow_upward : Icons.arrow_downward;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          trendIcon,
          size: 12,
          color: trendColor,
        ),
        const SizedBox(width: 2),
        Text(
          trend!,
          style: theme.textTheme.bodySmall?.copyWith(
            color: trendColor,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniChart() {
    return SizedBox(
      height: 40,
      child: MiniChart(
        data: chartData!,
        color: iconColor ?? GEVendorColors.primaryGreen,
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return EnhancedProgressIndicator(
      value: progressValue!,
      color: iconColor ?? GEVendorColors.primaryGreen,
    );
  }
}
