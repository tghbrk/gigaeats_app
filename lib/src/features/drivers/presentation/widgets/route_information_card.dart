import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/services/enhanced_route_service.dart';

/// Widget that displays comprehensive route information including distance, ETA, and turn-by-turn summary
class RouteInformationCard extends StatelessWidget {
  final DetailedRouteInfo routeInfo;
  final String destinationName;
  final String destinationAddress;

  const RouteInformationCard({
    super.key,
    required this.routeInfo,
    required this.destinationName,
    required this.destinationAddress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with destination info
            _buildDestinationHeader(theme),
            const SizedBox(height: 16),
            
            // Route metrics
            _buildRouteMetrics(theme),
            const SizedBox(height: 16),
            
            // Turn-by-turn summary
            if (routeInfo.keyTurns.isNotEmpty) ...[
              _buildTurnByTurnSummary(theme),
              const SizedBox(height: 16),
            ],
            
            // Additional info
            _buildAdditionalInfo(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.location_on,
            color: theme.colorScheme.onPrimaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                destinationName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                destinationAddress,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRouteMetrics(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricItem(
              theme,
              Icons.straighten,
              'Distance',
              routeInfo.distanceText,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _buildMetricItem(
              theme,
              Icons.schedule,
              'Duration',
              routeInfo.durationText,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _buildMetricItem(
              theme,
              Icons.access_time,
              'ETA',
              routeInfo.estimatedArrival != null
                  ? DateFormat('HH:mm').format(routeInfo.estimatedArrival!)
                  : '--:--',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(ThemeData theme, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTurnByTurnSummary(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.turn_right,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Key Turns',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...routeInfo.keyTurns.take(4).map((step) => _buildTurnStep(theme, step)),
        if (routeInfo.steps.length > 4)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+ ${routeInfo.steps.length - 4} more steps',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTurnStep(ThemeData theme, RouteStep step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getManeuverIcon(step.maneuver),
              color: theme.colorScheme.onSecondaryContainer,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.instruction,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (step.roadName != null)
                  Text(
                    'on ${step.roadName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            step.distance < 1 
                ? '${(step.distance * 1000).round()}m'
                : '${step.distance.toStringAsFixed(1)}km',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo(ThemeData theme) {
    final infoItems = <Widget>[];

    // Traffic condition
    if (routeInfo.trafficCondition != null) {
      infoItems.add(_buildInfoChip(
        theme,
        Icons.traffic,
        routeInfo.trafficCondition!,
        _getTrafficColor(routeInfo.trafficCondition!),
      ));
    }

    // Elevation changes
    if (routeInfo.hasElevationChanges) {
      infoItems.add(_buildInfoChip(
        theme,
        Icons.terrain,
        'Hilly route',
        Colors.orange,
      ));
    }

    // Warnings
    if (routeInfo.warnings != null) {
      infoItems.add(_buildInfoChip(
        theme,
        Icons.warning,
        routeInfo.warnings!,
        Colors.amber,
      ));
    }

    if (infoItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Route Conditions',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: infoItems,
        ),
      ],
    );
  }

  Widget _buildInfoChip(ThemeData theme, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getManeuverIcon(String maneuver) {
    switch (maneuver.toLowerCase()) {
      case 'turn-left':
        return Icons.turn_left;
      case 'turn-right':
        return Icons.turn_right;
      case 'turn-sharp-left':
        return Icons.turn_sharp_left;
      case 'turn-sharp-right':
        return Icons.turn_sharp_right;
      case 'turn-slight-left':
        return Icons.turn_slight_left;
      case 'turn-slight-right':
        return Icons.turn_slight_right;
      case 'merge':
        return Icons.merge;
      case 'fork-left':
      case 'fork-right':
        return Icons.call_split;
      case 'roundabout-left':
      case 'roundabout-right':
        return Icons.roundabout_left;
      case 'uturn-left':
      case 'uturn-right':
        return Icons.u_turn_left;
      default:
        return Icons.straight;
    }
  }

  Color _getTrafficColor(String trafficCondition) {
    switch (trafficCondition.toLowerCase()) {
      case 'light traffic':
        return Colors.green;
      case 'moderate traffic':
        return Colors.orange;
      case 'heavy traffic':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
