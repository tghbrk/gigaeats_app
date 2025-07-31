import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/navigation_models.dart';
import '../providers/enhanced_navigation_provider.dart';

/// Battery optimization widget for the Enhanced In-App Navigation System
/// Shows battery status, current optimization mode, and recommendations
class NavigationBatteryOptimizationWidget extends ConsumerWidget {
  final bool isCompact;
  final VoidCallback? onTap;

  const NavigationBatteryOptimizationWidget({
    super.key,
    this.isCompact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final navProvider = ref.watch(enhancedNavigationProvider.notifier);
    
    try {
      final recommendations = navProvider.getBatteryOptimizationRecommendations();
      
      if (isCompact) {
        return _buildCompactWidget(context, theme, recommendations);
      } else {
        return _buildFullWidget(context, theme, recommendations);
      }
    } catch (e) {
      return _buildErrorWidget(context, theme);
    }
  }

  /// Build compact battery status widget
  Widget _buildCompactWidget(
    BuildContext context,
    ThemeData theme,
    NavigationBatteryOptimizationRecommendations recommendations,
  ) {
    return Material(
      color: _getBatteryStatusColor(recommendations, theme).withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getBatteryIcon(recommendations),
                color: _getBatteryStatusColor(recommendations, theme),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                '${recommendations.batteryLevel}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _getBatteryStatusColor(recommendations, theme),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _getLocationModeIcon(recommendations.currentLocationMode),
                color: theme.colorScheme.outline,
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build full battery optimization widget
  Widget _buildFullWidget(
    BuildContext context,
    ThemeData theme,
    NavigationBatteryOptimizationRecommendations recommendations,
  ) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  _getBatteryIcon(recommendations),
                  color: _getBatteryStatusColor(recommendations, theme),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Battery Optimization',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        recommendations.batteryStatusDescription,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getBatteryStatusColor(recommendations, theme),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Location mode status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getLocationModeIcon(recommendations.currentLocationMode),
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location Mode',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          recommendations.locationModeDescription,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Estimated navigation time
            if (recommendations.estimatedNavigationTime != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: theme.colorScheme.outline,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Estimated navigation time: ${_formatDuration(recommendations.estimatedNavigationTime!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            
            // Critical actions
            if (recommendations.criticalActions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.red.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Critical Actions Required',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...recommendations.criticalActions.map((action) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            color: Colors.red.shade700,
                            size: 6,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              action,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
            
            // Recommendations
            if (recommendations.recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Recommendations',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...recommendations.recommendations.map((recommendation) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: theme.colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recommendation,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  /// Build error widget when battery info is unavailable
  Widget _buildErrorWidget(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.battery_unknown,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Battery info unavailable',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  /// Get battery icon based on level and state
  IconData _getBatteryIcon(NavigationBatteryOptimizationRecommendations recommendations) {
    if (recommendations.isCharging) {
      return Icons.battery_charging_full;
    }
    
    if (recommendations.batteryLevel >= 90) {
      return Icons.battery_full;
    } else if (recommendations.batteryLevel >= 60) {
      return Icons.battery_5_bar;
    } else if (recommendations.batteryLevel >= 40) {
      return Icons.battery_3_bar;
    } else if (recommendations.batteryLevel >= 20) {
      return Icons.battery_2_bar;
    } else {
      return Icons.battery_1_bar;
    }
  }

  /// Get location mode icon
  IconData _getLocationModeIcon(NavigationLocationMode mode) {
    switch (mode) {
      case NavigationLocationMode.highAccuracy:
        return Icons.gps_fixed;
      case NavigationLocationMode.balanced:
        return Icons.location_on;
      case NavigationLocationMode.batterySaver:
        return Icons.battery_saver;
      case NavigationLocationMode.powerSaver:
        return Icons.power_settings_new;
    }
  }

  /// Get battery status color
  Color _getBatteryStatusColor(
    NavigationBatteryOptimizationRecommendations recommendations,
    ThemeData theme,
  ) {
    if (recommendations.isCharging) {
      return Colors.green.shade700;
    } else if (recommendations.isCriticalBattery) {
      return Colors.red.shade700;
    } else if (recommendations.isLowBattery) {
      return Colors.orange.shade700;
    } else {
      return theme.colorScheme.primary;
    }
  }

  /// Format duration for display
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}

/// Show battery optimization dialog
Future<void> showBatteryOptimizationDialog(BuildContext context) async {
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      child: const NavigationBatteryOptimizationWidget(),
    ),
  );
}
