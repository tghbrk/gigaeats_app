import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/enhanced_route_service.dart';

/// Enhanced traffic condition indicator with real-time updates and detailed information
class TrafficConditionIndicator extends ConsumerStatefulWidget {
  final DetailedRouteInfo routeInfo;
  final bool showDetails;
  final bool showRefreshButton;
  final VoidCallback? onRefresh;

  const TrafficConditionIndicator({
    super.key,
    required this.routeInfo,
    this.showDetails = true,
    this.showRefreshButton = false,
    this.onRefresh,
  });

  @override
  ConsumerState<TrafficConditionIndicator> createState() => _TrafficConditionIndicatorState();
}

class _TrafficConditionIndicatorState extends ConsumerState<TrafficConditionIndicator> {
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trafficCondition = widget.routeInfo.trafficCondition ?? 'Unknown';
    final trafficColor = _getTrafficColor(trafficCondition);
    final trafficIcon = _getTrafficIcon(trafficCondition);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme, trafficIcon, trafficColor),
            if (widget.showDetails) ...[
              const SizedBox(height: 12),
              _buildTrafficDetails(theme, trafficCondition, trafficColor),
            ],
            if (widget.routeInfo.warnings != null) ...[
              const SizedBox(height: 12),
              _buildWarnings(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Traffic Conditions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                widget.routeInfo.trafficCondition ?? 'No traffic data available',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (widget.showRefreshButton)
          IconButton(
            onPressed: _isRefreshing ? null : _refreshTrafficData,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh traffic data',
          ),
      ],
    );
  }

  Widget _buildTrafficDetails(ThemeData theme, String condition, Color color) {
    final delayMinutes = _getEstimatedDelay(condition);
    final alternativeTime = widget.routeInfo.duration + delayMinutes;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  theme,
                  Icons.schedule,
                  'Current ETA',
                  '${widget.routeInfo.duration} min',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildDetailItem(
                  theme,
                  Icons.add_road,
                  'Traffic Delay',
                  delayMinutes > 0 ? '+$delayMinutes min' : 'None',
                ),
              ),
            ],
          ),
          if (delayMinutes > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Estimated arrival: $alternativeTime min',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(ThemeData theme, IconData icon, String label, String value) {
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
          style: theme.textTheme.titleSmall?.copyWith(
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

  Widget _buildWarnings(ThemeData theme) {
    final warnings = widget.routeInfo.warnings!.split(',');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.warning,
              color: Colors.amber,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Route Warnings',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...warnings.map((warning) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  warning.trim(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Future<void> _refreshTrafficData() async {
    if (widget.onRefresh == null) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      widget.onRefresh!();
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Color _getTrafficColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'light traffic':
      case 'light':
        return Colors.green;
      case 'moderate traffic':
      case 'moderate':
        return Colors.orange;
      case 'heavy traffic':
      case 'heavy':
        return Colors.red;
      case 'severe traffic':
      case 'severe':
        return Colors.red.shade800;
      default:
        return Colors.grey;
    }
  }

  IconData _getTrafficIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'light traffic':
      case 'light':
        return Icons.traffic;
      case 'moderate traffic':
      case 'moderate':
        return Icons.traffic;
      case 'heavy traffic':
      case 'heavy':
        return Icons.traffic;
      case 'severe traffic':
      case 'severe':
        return Icons.report_problem;
      default:
        return Icons.help_outline;
    }
  }

  int _getEstimatedDelay(String condition) {
    switch (condition.toLowerCase()) {
      case 'light traffic':
      case 'light':
        return 0;
      case 'moderate traffic':
      case 'moderate':
        return 5;
      case 'heavy traffic':
      case 'heavy':
        return 15;
      case 'severe traffic':
      case 'severe':
        return 30;
      default:
        return 0;
    }
  }
}
