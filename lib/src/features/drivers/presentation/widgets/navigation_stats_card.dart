import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/enhanced_navigation_provider.dart';
import '../providers/navigation_location_providers.dart';

/// Navigation statistics card widget that displays current speed, ETA, and remaining distance
/// with Material Design 3 styling for the Enhanced In-App Navigation System
class NavigationStatsCard extends ConsumerWidget {
  final double? currentSpeed;
  final DateTime? eta;
  final double? remainingDistance;
  final bool showSpeedLimit;
  final double? speedLimit;
  final bool compact;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const NavigationStatsCard({
    super.key,
    this.currentSpeed,
    this.eta,
    this.remainingDistance,
    this.showSpeedLimit = false,
    this.speedLimit,
    this.compact = false,
    this.margin,
    this.onTap,
  });

  /// Static method that creates a widget that automatically gets data from providers
  static Widget fromProviders({
    Key? key,
    bool showSpeedLimit = false,
    double? speedLimit,
    bool compact = false,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return _NavigationStatsCardFromProviders(
      key: key,
      showSpeedLimit: showSpeedLimit,
      speedLimit: speedLimit,
      compact: compact,
      margin: margin,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Container(
      margin: margin ?? const EdgeInsets.all(16),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(compact ? 12 : 16),
          child: Container(
            padding: EdgeInsets.all(compact ? 12 : 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(compact ? 12 : 16),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: compact ? _buildCompactLayout(theme) : _buildFullLayout(theme),
          ),
        ),
      ),
    );
  }

  /// Build full layout with all statistics
  Widget _buildFullLayout(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.speed,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Navigation Stats',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Statistics grid
        Row(
          children: [
            // Current Speed
            Expanded(
              child: _buildStatItem(
                theme,
                icon: Icons.speed,
                label: 'Speed',
                value: _formatSpeed(currentSpeed),
                unit: 'km/h',
                isWarning: _isSpeedWarning(),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Remaining Distance
            Expanded(
              child: _buildStatItem(
                theme,
                icon: Icons.straighten,
                label: 'Distance',
                value: _formatDistance(remainingDistance),
                unit: null,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // ETA (full width)
        _buildStatItem(
          theme,
          icon: Icons.access_time,
          label: 'Estimated Arrival',
          value: _formatETA(eta),
          unit: null,
          fullWidth: true,
        ),
        
        // Speed limit warning (if applicable)
        if (showSpeedLimit && speedLimit != null && _isSpeedWarning()) ...[
          const SizedBox(height: 12),
          _buildSpeedLimitWarning(theme),
        ],
      ],
    );
  }

  /// Build compact layout for smaller displays
  Widget _buildCompactLayout(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Speed
        _buildCompactStatItem(
          theme,
          icon: Icons.speed,
          value: _formatSpeed(currentSpeed),
          unit: 'km/h',
          isWarning: _isSpeedWarning(),
        ),
        
        // Distance
        _buildCompactStatItem(
          theme,
          icon: Icons.straighten,
          value: _formatDistance(remainingDistance),
          unit: null,
        ),
        
        // ETA
        _buildCompactStatItem(
          theme,
          icon: Icons.access_time,
          value: _formatETA(eta),
          unit: null,
        ),
      ],
    );
  }

  /// Build individual stat item
  Widget _buildStatItem(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    String? unit,
    bool isWarning = false,
    bool fullWidth = false,
  }) {
    final color = isWarning ? Colors.orange : theme.colorScheme.onSurface;
    
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: isWarning ? Border.all(color: Colors.orange.withValues(alpha: 0.3)) : null,
      ),
      child: Column(
        crossAxisAlignment: fullWidth ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Build compact stat item for compact layout
  Widget _buildCompactStatItem(
    ThemeData theme, {
    required IconData icon,
    required String value,
    String? unit,
    bool isWarning = false,
  }) {
    final color = isWarning ? Colors.orange : theme.colorScheme.primary;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 18,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 2),
              Text(
                unit,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Build speed limit warning
  Widget _buildSpeedLimitWarning(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning,
            color: Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Speed limit: ${speedLimit!.toInt()} km/h',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Format speed value
  String _formatSpeed(double? speed) {
    if (speed == null || speed <= 0) return '--';
    return speed.toInt().toString();
  }

  /// Format distance value with enhanced validation and formatting
  String _formatDistance(double? distance) {
    if (distance == null) return '--';

    // Validate distance is reasonable
    if (distance < 0) {
      debugPrint('⚠️ [NAV-STATS] Negative distance detected: $distance');
      return '--';
    }

    if (distance > 100000) { // > 100km
      debugPrint('⚠️ [NAV-STATS] Unrealistic distance detected: ${distance}m (${(distance/1000).toStringAsFixed(2)}km)');
      return '--';
    }

    // Format based on distance magnitude
    if (distance < 10) {
      // Very close distances - show with 1 decimal place
      return '${distance.toStringAsFixed(1)}m';
    } else if (distance < 100) {
      // Close distances - show whole meters
      return '${distance.round()}m';
    } else if (distance < 1000) {
      // Medium distances - show whole meters
      return '${distance.round()}m';
    } else if (distance < 10000) {
      // Distances 1-10km - show with 1 decimal place
      return '${(distance / 1000).toStringAsFixed(1)}km';
    } else {
      // Long distances - show whole kilometers
      return '${(distance / 1000).round()}km';
    }
  }

  /// Format ETA value with enhanced formatting and validation
  String _formatETA(DateTime? eta) {
    if (eta == null) return '--';

    final now = DateTime.now();
    final difference = eta.difference(now);

    // Handle past times (should not happen in normal navigation)
    if (difference.isNegative) {
      debugPrint('⚠️ [NAV-STATS] ETA is in the past: $eta');
      return 'Overdue';
    }

    // Handle unrealistic future times (more than 24 hours)
    if (difference.inHours > 24) {
      debugPrint('⚠️ [NAV-STATS] Unrealistic ETA detected: $eta (${difference.inHours}h from now)');
      return '--';
    }

    // Format based on time remaining
    if (difference.inSeconds < 30) {
      return 'Arriving';
    } else if (difference.inMinutes < 1) {
      return '<1min';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}min';
      }
    } else {
      return '--';
    }
  }

  /// Get ETA color based on time remaining and traffic conditions
  // ignore: unused_element
  Color _getETAColor(ThemeData theme, DateTime? eta) {
    if (eta == null) return theme.colorScheme.onSurface;

    final now = DateTime.now();
    final difference = eta.difference(now);

    if (difference.isNegative) {
      return theme.colorScheme.error; // Overdue
    } else if (difference.inMinutes < 5) {
      return Colors.orange; // Arriving soon
    } else if (difference.inMinutes < 15) {
      return theme.colorScheme.primary; // Normal
    } else {
      return theme.colorScheme.secondary; // Plenty of time
    }
  }

  /// Check if current speed exceeds speed limit
  bool _isSpeedWarning() {
    if (!showSpeedLimit || speedLimit == null || currentSpeed == null) {
      return false;
    }
    return currentSpeed! > speedLimit! + 5; // 5 km/h tolerance
  }
}

/// Internal widget that automatically gets data from providers
class _NavigationStatsCardFromProviders extends ConsumerWidget {
  final bool showSpeedLimit;
  final double? speedLimit;
  final bool compact;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const _NavigationStatsCardFromProviders({
    super.key,
    required this.showSpeedLimit,
    this.speedLimit,
    required this.compact,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(enhancedNavigationProvider);
    final locationState = ref.watch(navigationLocationProvider);

    // Get current speed from location data
    double? currentSpeed;
    final speed = locationState.location?.speed;
    if (speed != null && speed > 0) {
      currentSpeed = speed * 3.6; // Convert m/s to km/h
    }
    
    return NavigationStatsCard(
      currentSpeed: currentSpeed,
      eta: navState.estimatedArrival,
      remainingDistance: navState.remainingDistance,
      showSpeedLimit: showSpeedLimit,
      speedLimit: speedLimit,
      compact: compact,
      margin: margin,
      onTap: onTap,
    );
  }
}
