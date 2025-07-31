import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/route_optimization_models.dart';
import '../../../data/models/navigation_models.dart';
import '../../providers/route_optimization_provider.dart';

/// Enhanced route optimization controls for managing route calculation and preferences (Phase 3.5)
/// Provides advanced interface for optimization criteria, real-time updates, and manual reoptimization
///
/// Phase 3.5 Features:
/// - Advanced visualization with real-time route updates
/// - Enhanced optimization criteria controls with live preview
/// - Interactive optimization score display
/// - Real-time route metrics and performance indicators
class RouteOptimizationControls extends ConsumerStatefulWidget {
  final OptimizedRoute? optimizedRoute;
  final bool isOptimizing;
  final VoidCallback? onOptimize;
  final VoidCallback? onReoptimize;
  final VoidCallback? onReorder;

  const RouteOptimizationControls({
    super.key,
    this.optimizedRoute,
    this.isOptimizing = false,
    this.onOptimize,
    this.onReoptimize,
    this.onReorder,
  });

  @override
  ConsumerState<RouteOptimizationControls> createState() => _RouteOptimizationControlsState();
}

class _RouteOptimizationControlsState extends ConsumerState<RouteOptimizationControls>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _showAdvancedControls = false;
  bool _showRealTimeUpdates = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routeState = ref.watch(routeOptimizationProvider);

    // Start pulse animation when optimizing
    if (widget.isOptimizing && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isOptimizing && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }

    // Start fade animation when expanding
    if (_isExpanded && !_animationController.isCompleted) {
      _animationController.forward();
    } else if (!_isExpanded && _animationController.isCompleted) {
      _animationController.reverse();
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isOptimizing ? _pulseAnimation.value : 1.0,
          child: Card(
            elevation: widget.isOptimizing ? 4 : 1,
            child: Column(
              children: [
                _buildEnhancedHeader(theme, routeState),
                if (_isExpanded)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildEnhancedExpandedContent(theme, routeState),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // TODO: Use for collapsible header
  // ignore: unused_element
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

  // TODO: Use for expanded content view
  // ignore: unused_element
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
        
        // Display criteria as read-only indicators
        _buildCriteriaIndicator(theme, 'Distance Priority', criteria.distanceWeight, Colors.blue),
        _buildCriteriaIndicator(theme, 'Preparation Time Priority', criteria.preparationTimeWeight, Colors.green),
        _buildCriteriaIndicator(theme, 'Traffic Priority', criteria.trafficWeight, Colors.orange),
        _buildCriteriaIndicator(theme, 'Delivery Window Priority', criteria.deliveryWindowWeight, Colors.purple),
      ],
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

  // ============================================================================
  // PHASE 3.5: ENHANCED UI METHODS
  // ============================================================================

  /// Enhanced header with real-time optimization status and metrics (Phase 3.5)
  Widget _buildEnhancedHeader(ThemeData theme, RouteOptimizationState routeState) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Enhanced status indicator with animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getStatusColor(theme, routeState).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: widget.isOptimizing
                    ? Border.all(color: theme.colorScheme.primary, width: 2)
                    : null,
              ),
              child: widget.isOptimizing
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : Icon(
                      _getStatusIcon(routeState),
                      color: _getStatusColor(theme, routeState),
                      size: 24,
                    ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Route Optimization',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.optimizedRoute != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.optimizedRoute!.optimizationScoreText,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusText(routeState),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  if (widget.optimizedRoute != null && _showRealTimeUpdates) ...[
                    const SizedBox(height: 4),
                    _buildRealTimeIndicators(theme, routeState),
                  ],
                ],
              ),
            ),

            // Enhanced action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.optimizedRoute != null && !widget.isOptimizing)
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

  /// Enhanced expanded content with advanced controls (Phase 3.5)
  Widget _buildEnhancedExpandedContent(ThemeData theme, RouteOptimizationState routeState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRealTimeMetrics(theme, routeState),
          const SizedBox(height: 16),
          _buildEnhancedOptimizationCriteria(theme, routeState.criteria),
          if (_showAdvancedControls) ...[
            const SizedBox(height: 16),
            _buildAdvancedControls(theme, routeState),
          ],
          const SizedBox(height: 16),
          _buildEnhancedActionButtons(theme, routeState),
        ],
      ),
    );
  }

  /// Real-time metrics display (Phase 3.5)
  Widget _buildRealTimeMetrics(ThemeData theme, RouteOptimizationState routeState) {
    if (widget.optimizedRoute == null) {
      return const SizedBox.shrink();
    }

    final route = widget.optimizedRoute!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route Metrics',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  theme,
                  'Distance',
                  route.totalDistanceText,
                  Icons.straighten,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  theme,
                  'Duration',
                  route.totalDurationText,
                  Icons.access_time,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  theme,
                  'Efficiency',
                  route.optimizationScoreText,
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build individual metric item
  Widget _buildMetricItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
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

  /// Enhanced optimization criteria controls (Phase 3.5)
  Widget _buildEnhancedOptimizationCriteria(ThemeData theme, OptimizationCriteria criteria) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Optimization Criteria',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => setState(() => _showAdvancedControls = !_showAdvancedControls),
              icon: Icon(_showAdvancedControls ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
              label: Text(_showAdvancedControls ? 'Less' : 'Advanced'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildCriteriaSlider(
          'Distance Priority',
          criteria.distanceWeight,
          (value) => _updateCriteria(criteria, distanceWeight: value),
        ),
        _buildCriteriaSlider(
          'Preparation Time Priority',
          criteria.preparationTimeWeight,
          (value) => _updateCriteria(criteria, preparationTimeWeight: value),
        ),
        _buildCriteriaSlider(
          'Traffic Priority',
          criteria.trafficWeight,
          (value) => _updateCriteria(criteria, trafficWeight: value),
        ),
        _buildCriteriaSlider(
          'Delivery Window Priority',
          criteria.deliveryWindowWeight,
          (value) => _updateCriteria(criteria, deliveryWindowWeight: value),
        ),
      ],
    );
  }

  /// Build criteria slider
  Widget _buildCriteriaSlider(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Slider(
              value: value,
              onChanged: onChanged,
              min: 0.0,
              max: 1.0,
              divisions: 10,
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${(value * 100).round()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  /// Advanced controls (Phase 3.5)
  Widget _buildAdvancedControls(ThemeData theme, RouteOptimizationState routeState) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advanced Settings',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Real-time Updates'),
            subtitle: const Text('Show live route metrics'),
            value: _showRealTimeUpdates,
            onChanged: (value) => setState(() => _showRealTimeUpdates = value),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('Auto-reoptimize'),
            subtitle: const Text('Automatically reoptimize on changes'),
            value: false, // TODO: Add autoReoptimize to RouteOptimizationState
            onChanged: (value) {
              // TODO: Implement auto-reoptimize functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Auto-reoptimize feature coming soon')),
              );
            },
            dense: true,
          ),
        ],
      ),
    );
  }

  /// Enhanced action buttons (Phase 3.5)
  Widget _buildEnhancedActionButtons(ThemeData theme, RouteOptimizationState routeState) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: widget.isOptimizing ? null : widget.onOptimize,
            icon: widget.isOptimizing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.route),
            label: Text(widget.isOptimizing ? 'Optimizing...' : 'Optimize Route'),
          ),
        ),
        const SizedBox(width: 8),
        if (widget.optimizedRoute != null)
          ElevatedButton.icon(
            onPressed: widget.onReorder,
            icon: const Icon(Icons.reorder),
            label: const Text('Reorder'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              foregroundColor: theme.colorScheme.onSurface,
            ),
          ),
      ],
    );
  }

  /// Real-time indicators (Phase 3.5)
  Widget _buildRealTimeIndicators(ThemeData theme, RouteOptimizationState routeState) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'Live updates active',
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.green,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // PHASE 3.5: HELPER METHODS
  // ============================================================================

  /// Get status color based on route state
  Color _getStatusColor(ThemeData theme, RouteOptimizationState routeState) {
    if (widget.isOptimizing) {
      return theme.colorScheme.primary;
    } else if (widget.optimizedRoute != null) {
      return Colors.green;
    } else {
      return theme.colorScheme.outline;
    }
  }

  /// Get status icon based on route state
  IconData _getStatusIcon(RouteOptimizationState routeState) {
    if (widget.optimizedRoute != null) {
      return Icons.check_circle;
    } else {
      return Icons.route;
    }
  }

  /// Get status text based on route state
  String _getStatusText(RouteOptimizationState routeState) {
    if (widget.isOptimizing) {
      return 'Optimizing route...';
    } else if (widget.optimizedRoute != null) {
      final route = widget.optimizedRoute!;
      return 'Route optimized • ${route.totalDistanceText} • ${route.totalDurationText}';
    } else {
      return 'Tap to optimize route';
    }
  }

  /// Update optimization criteria with new values
  void _updateCriteria(
    OptimizationCriteria currentCriteria, {
    double? distanceWeight,
    double? preparationTimeWeight,
    double? trafficWeight,
    double? deliveryWindowWeight,
  }) {
    final newCriteria = OptimizationCriteria(
      distanceWeight: distanceWeight ?? currentCriteria.distanceWeight,
      preparationTimeWeight: preparationTimeWeight ?? currentCriteria.preparationTimeWeight,
      trafficWeight: trafficWeight ?? currentCriteria.trafficWeight,
      deliveryWindowWeight: deliveryWindowWeight ?? currentCriteria.deliveryWindowWeight,
    );

    // Normalize weights to ensure they sum to 1.0
    final totalWeight = newCriteria.distanceWeight +
                       newCriteria.preparationTimeWeight +
                       newCriteria.trafficWeight +
                       newCriteria.deliveryWindowWeight;

    if (totalWeight > 0) {
      final normalizedCriteria = OptimizationCriteria(
        distanceWeight: newCriteria.distanceWeight / totalWeight,
        preparationTimeWeight: newCriteria.preparationTimeWeight / totalWeight,
        trafficWeight: newCriteria.trafficWeight / totalWeight,
        deliveryWindowWeight: newCriteria.deliveryWindowWeight / totalWeight,
      );

      ref.read(routeOptimizationProvider.notifier).updateOptimizationCriteria(normalizedCriteria);
    }
  }

  /// Build criteria indicator (read-only display)
  Widget _buildCriteriaIndicator(ThemeData theme, String label, double value, Color color) {
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
}
