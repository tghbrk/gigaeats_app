import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/route_optimization_models.dart';
import '../../providers/route_optimization_provider.dart';

/// Real-time route adjustment panel for Phase 3 multi-order management
/// Provides interface for monitoring and applying dynamic route adjustments
class RealTimeRouteAdjustmentPanel extends ConsumerWidget {
  final OptimizedRoute? currentRoute;
  final RealTimeRouteState realTimeState;
  final VoidCallback? onCalculateAdjustment;
  final VoidCallback? onApplyAdjustment;

  const RealTimeRouteAdjustmentPanel({
    super.key,
    this.currentRoute,
    required this.realTimeState,
    this.onCalculateAdjustment,
    this.onApplyAdjustment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 16),
            _buildConditionsSection(theme),
            const SizedBox(height: 16),
            _buildAdjustmentSection(theme),
            const SizedBox(height: 16),
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.route,
          color: theme.colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'Real-Time Route Adjustment',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (realTimeState.isCalculatingAdjustment)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  Widget _buildConditionsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Conditions',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (realTimeState.realTimeConditions != null)
          _buildConditionsGrid(theme, realTimeState.realTimeConditions!)
        else
          _buildNoConditionsMessage(theme),
      ],
    );
  }

  Widget _buildConditionsGrid(ThemeData theme, Map<String, dynamic> conditions) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildConditionItem(
                  theme,
                  'Traffic',
                  _getTrafficCondition(conditions),
                  _getTrafficIcon(conditions),
                  _getTrafficColor(theme, conditions),
                ),
              ),
              Expanded(
                child: _buildConditionItem(
                  theme,
                  'Weather',
                  _getWeatherCondition(conditions),
                  _getWeatherIcon(conditions),
                  _getWeatherColor(theme, conditions),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildConditionItem(
                  theme,
                  'Orders',
                  conditions['order_changes'] == true ? 'Changed' : 'Stable',
                  conditions['order_changes'] == true ? Icons.change_circle : Icons.check_circle,
                  conditions['order_changes'] == true ? Colors.orange : Colors.green,
                ),
              ),
              Expanded(
                child: _buildConditionItem(
                  theme,
                  'Impact',
                  '${_calculateTotalImpact(conditions).toStringAsFixed(0)}%',
                  Icons.trending_up,
                  _getImpactColor(theme, _calculateTotalImpact(conditions)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConditionItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildNoConditionsMessage(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Text(
            'No real-time conditions available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Route Adjustment',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (realTimeState.lastAdjustment != null)
          _buildAdjustmentResult(theme, realTimeState.lastAdjustment!)
        else
          _buildNoAdjustmentMessage(theme),
      ],
    );
  }

  Widget _buildAdjustmentResult(ThemeData theme, RouteAdjustmentResult adjustment) {
    final statusColor = _getAdjustmentStatusColor(theme, adjustment.status);
    final statusIcon = _getAdjustmentStatusIcon(adjustment.status);

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                statusIcon,
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 8),
              Text(
                adjustment.status.displayName,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (adjustment.improvementScore != null)
                Text(
                  '+${adjustment.improvementScore!.toStringAsFixed(0)}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            adjustment.message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          if (adjustment.adjustmentReason != null) ...[
            const SizedBox(height: 4),
            Text(
              'Reason: ${adjustment.adjustmentReason}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoAdjustmentMessage(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Text(
            'No route adjustment calculated yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    final canCalculate = currentRoute != null && !realTimeState.isCalculatingAdjustment;
    final canApply = realTimeState.lastAdjustment?.isSuccess == true;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: canCalculate ? onCalculateAdjustment : null,
            icon: realTimeState.isCalculatingAdjustment
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.calculate),
            label: Text(
              realTimeState.isCalculatingAdjustment ? 'Calculating...' : 'Calculate',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: canApply ? onApplyAdjustment : null,
            icon: const Icon(Icons.check),
            label: const Text('Apply'),
          ),
        ),
      ],
    );
  }

  // Helper methods for conditions
  String _getTrafficCondition(Map<String, dynamic> conditions) {
    final trafficData = conditions['traffic'] as Map<String, dynamic>?;
    return trafficData?['congestion_level'] as String? ?? 'Normal';
  }

  IconData _getTrafficIcon(Map<String, dynamic> conditions) {
    final condition = _getTrafficCondition(conditions).toLowerCase();
    switch (condition) {
      case 'severe':
      case 'heavy':
        return Icons.traffic;
      case 'moderate':
        return Icons.warning;
      default:
        return Icons.check_circle;
    }
  }

  Color _getTrafficColor(ThemeData theme, Map<String, dynamic> conditions) {
    final condition = _getTrafficCondition(conditions).toLowerCase();
    switch (condition) {
      case 'severe':
        return Colors.red;
      case 'heavy':
        return Colors.orange;
      case 'moderate':
        return Colors.yellow[700]!;
      default:
        return Colors.green;
    }
  }

  String _getWeatherCondition(Map<String, dynamic> conditions) {
    final weatherData = conditions['weather'] as Map<String, dynamic>?;
    return weatherData?['condition'] as String? ?? 'Clear';
  }

  IconData _getWeatherIcon(Map<String, dynamic> conditions) {
    final condition = _getWeatherCondition(conditions).toLowerCase();
    switch (condition) {
      case 'thunderstorm':
        return Icons.thunderstorm;
      case 'heavy_rain':
      case 'rain':
        return Icons.water_drop;
      case 'fog':
        return Icons.foggy;
      default:
        return Icons.wb_sunny;
    }
  }

  Color _getWeatherColor(ThemeData theme, Map<String, dynamic> conditions) {
    final condition = _getWeatherCondition(conditions).toLowerCase();
    switch (condition) {
      case 'thunderstorm':
        return Colors.red;
      case 'heavy_rain':
        return Colors.blue[700]!;
      case 'rain':
        return Colors.blue;
      case 'fog':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  double _calculateTotalImpact(Map<String, dynamic> conditions) {
    double impact = 0.0;
    
    // Traffic impact
    final trafficCondition = _getTrafficCondition(conditions).toLowerCase();
    switch (trafficCondition) {
      case 'severe':
        impact += 40;
        break;
      case 'heavy':
        impact += 30;
        break;
      case 'moderate':
        impact += 20;
        break;
      case 'light':
        impact += 10;
        break;
    }

    // Weather impact
    final weatherCondition = _getWeatherCondition(conditions).toLowerCase();
    switch (weatherCondition) {
      case 'thunderstorm':
        impact += 30;
        break;
      case 'heavy_rain':
        impact += 25;
        break;
      case 'rain':
        impact += 15;
        break;
      case 'fog':
        impact += 20;
        break;
    }

    // Order changes impact
    if (conditions['order_changes'] == true) {
      impact += 30;
    }

    return impact.clamp(0.0, 100.0);
  }

  Color _getImpactColor(ThemeData theme, double impact) {
    if (impact >= 50) return Colors.red;
    if (impact >= 30) return Colors.orange;
    if (impact >= 15) return Colors.yellow[700]!;
    return Colors.green;
  }

  Color _getAdjustmentStatusColor(ThemeData theme, RouteAdjustmentStatus status) {
    switch (status) {
      case RouteAdjustmentStatus.adjustmentCalculated:
        return Colors.green;
      case RouteAdjustmentStatus.noAdjustmentNeeded:
        return theme.colorScheme.primary;
      case RouteAdjustmentStatus.error:
        return theme.colorScheme.error;
    }
  }

  IconData _getAdjustmentStatusIcon(RouteAdjustmentStatus status) {
    switch (status) {
      case RouteAdjustmentStatus.adjustmentCalculated:
        return Icons.check_circle;
      case RouteAdjustmentStatus.noAdjustmentNeeded:
        return Icons.info;
      case RouteAdjustmentStatus.error:
        return Icons.error;
    }
  }
}
