import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/route_optimization_models.dart';
import '../../../data/models/navigation_models.dart';

/// Route optimization controls for managing route calculation and preferences
/// Provides interface for optimization criteria and manual reoptimization
class RouteOptimizationControls extends ConsumerStatefulWidget {
  final OptimizedRoute? optimizedRoute;
  final bool isOptimizing;
  final VoidCallback? onOptimize;
  final VoidCallback? onReoptimize;

  const RouteOptimizationControls({
    super.key,
    this.optimizedRoute,
    this.isOptimizing = false,
    this.onOptimize,
    this.onReoptimize,
  });

  @override
  ConsumerState<RouteOptimizationControls> createState() => _RouteOptimizationControlsState();
}

class _RouteOptimizationControlsState extends ConsumerState<RouteOptimizationControls> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      child: Column(
        children: [
          _buildHeader(theme),
          if (_isExpanded) _buildExpandedContent(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.optimizedRoute != null
                    ? Colors.green.withValues(alpha: 0.1)
                    : theme.colorScheme.outline.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.route,
                color: widget.optimizedRoute != null
                    ? Colors.green
                    : theme.colorScheme.outline,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route Optimization',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.optimizedRoute != null
                        ? 'Optimized route available (${widget.optimizedRoute!.optimizationScoreText} efficiency)'
                        : 'No optimized route',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            
            if (widget.isOptimizing)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.optimizedRoute != null)
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: widget.onReoptimize,
                      tooltip: 'Reoptimize Route',
                    ),
                  IconButton(
                    icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                    tooltip: _isExpanded ? 'Collapse' : 'Expand',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 16),
          
          if (widget.optimizedRoute != null) ...[
            _buildRouteMetrics(theme),
            const SizedBox(height: 16),
          ],
          
          _buildOptimizationCriteria(theme),
          const SizedBox(height: 16),
          
          _buildActionButtons(theme),
        ],
      ),
    );
  }

  Widget _buildRouteMetrics(ThemeData theme) {
    final route = widget.optimizedRoute!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Route Metrics',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                theme,
                icon: Icons.straighten,
                label: 'Distance',
                value: route.totalDistanceText,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                theme,
                icon: Icons.access_time,
                label: 'Duration',
                value: route.totalDurationText,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                theme,
                icon: Icons.trending_up,
                label: 'Efficiency',
                value: route.optimizationScoreText,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Traffic condition indicator
        Row(
          children: [
            Icon(
              Icons.traffic,
              size: 16,
              color: _getTrafficColor(route.overallTrafficCondition),
            ),
            const SizedBox(width: 8),
            Text(
              'Traffic: ${route.overallTrafficCondition.name.toUpperCase()}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _getTrafficColor(route.overallTrafficCondition),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              'Calculated ${_getTimeAgo(route.calculatedAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
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
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationCriteria(ThemeData theme) {
    final criteria = widget.optimizedRoute?.criteria ?? OptimizationCriteria.balanced();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Optimization Criteria',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        _buildCriteriaSlider(
          theme,
          label: 'Distance Priority',
          value: criteria.distanceWeight,
          color: Colors.blue,
        ),
        
        _buildCriteriaSlider(
          theme,
          label: 'Preparation Time Priority',
          value: criteria.preparationTimeWeight,
          color: Colors.green,
        ),
        
        _buildCriteriaSlider(
          theme,
          label: 'Traffic Priority',
          value: criteria.trafficWeight,
          color: Colors.orange,
        ),
        
        _buildCriteriaSlider(
          theme,
          label: 'Delivery Window Priority',
          value: criteria.deliveryWindowWeight,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildCriteriaSlider(
    ThemeData theme, {
    required String label,
    required double value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '${(value * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showOptimizationSettings,
            icon: const Icon(Icons.tune),
            label: const Text('Settings'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: widget.isOptimizing
                ? null
                : (widget.optimizedRoute != null
                    ? widget.onReoptimize
                    : widget.onOptimize),
            icon: widget.isOptimizing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(widget.optimizedRoute != null
                    ? Icons.refresh
                    : Icons.route),
            label: Text(
              widget.isOptimizing
                  ? 'Optimizing...'
                  : (widget.optimizedRoute != null
                      ? 'Reoptimize'
                      : 'Optimize'),
            ),
          ),
        ),
      ],
    );
  }

  Color _getTrafficColor(TrafficCondition condition) {
    switch (condition) {
      case TrafficCondition.clear:
        return Colors.green;
      case TrafficCondition.light:
        return Colors.lightGreen;
      case TrafficCondition.moderate:
        return Colors.orange;
      case TrafficCondition.heavy:
        return Colors.red;
      case TrafficCondition.severe:
        return Colors.red.shade800;
      case TrafficCondition.unknown:
        return Colors.grey;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showOptimizationSettings() {
    // TODO: Show optimization settings dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Optimization settings not implemented yet'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
