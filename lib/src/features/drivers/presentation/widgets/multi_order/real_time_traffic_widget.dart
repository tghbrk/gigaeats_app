import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/navigation_models.dart';
import '../../providers/enhanced_navigation_provider.dart';

/// Real-time traffic integration widget with Phase 2 enhancements
/// Provides comprehensive traffic condition monitoring, alerts, and route optimization suggestions
class RealTimeTrafficWidget extends ConsumerStatefulWidget {
  final bool showTrafficAlerts;
  final bool showRouteAlternatives;
  final VoidCallback? onRouteRecalculation;
  final Function(String alertId)? onDismissAlert;

  const RealTimeTrafficWidget({
    super.key,
    this.showTrafficAlerts = true,
    this.showRouteAlternatives = true,
    this.onRouteRecalculation,
    this.onDismissAlert,
  });

  @override
  ConsumerState<RealTimeTrafficWidget> createState() => _RealTimeTrafficWidgetState();
}

class _RealTimeTrafficWidgetState extends ConsumerState<RealTimeTrafficWidget>
    with TickerProviderStateMixin {
  late AnimationController _alertAnimationController;
  late Animation<double> _alertSlideAnimation;
  late Animation<double> _alertFadeAnimation;
  
  final Set<String> _dismissedAlerts = {};

  @override
  void initState() {
    super.initState();
    
    debugPrint('🚦 [TRAFFIC-WIDGET] Initializing real-time traffic widget (Phase 2)');
    
    _alertAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _alertSlideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _alertAnimationController,
      curve: Curves.easeOutBack,
    ));
    
    _alertFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _alertAnimationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _alertAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navState = ref.watch(enhancedNavigationProvider);

    if (!navState.isNavigating) {
      return const SizedBox.shrink();
    }

    final currentInstruction = navState.currentInstruction;
    if (currentInstruction == null) {
      return const SizedBox.shrink();
    }

    debugPrint('🚦 [TRAFFIC-WIDGET] Building traffic widget - Traffic condition: ${currentInstruction.trafficCondition}');

    return Stack(
      children: [
        // Traffic condition indicator
        _buildTrafficConditionIndicator(theme, currentInstruction),
        
        // Traffic alerts
        if (widget.showTrafficAlerts && _shouldShowTrafficAlert(currentInstruction))
          _buildTrafficAlert(theme, currentInstruction),
        
        // Route alternatives panel
        if (widget.showRouteAlternatives && _shouldShowRouteAlternatives(currentInstruction))
          _buildRouteAlternativesPanel(theme, navState),
      ],
    );
  }

  /// Build traffic condition indicator
  Widget _buildTrafficConditionIndicator(ThemeData theme, NavigationInstruction instruction) {
    final condition = instruction.trafficCondition;
    
    if (condition == TrafficCondition.unknown) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _getTrafficConditionColor(condition).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getTrafficConditionColor(condition).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getTrafficConditionIcon(condition),
                color: _getTrafficConditionColor(condition),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                _getTrafficConditionText(condition),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _getTrafficConditionColor(condition),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build traffic alert
  Widget _buildTrafficAlert(ThemeData theme, NavigationInstruction instruction) {
    final alertId = 'traffic_${instruction.id}';
    
    if (_dismissedAlerts.contains(alertId)) {
      return const SizedBox.shrink();
    }

    // Trigger animation when alert appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _alertAnimationController.forward();
      }
    });

    return AnimatedBuilder(
      animation: _alertAnimationController,
      builder: (context, child) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 80,
          left: 16,
          right: 16,
          child: Transform.translate(
            offset: Offset(_alertSlideAnimation.value * 300, 0),
            child: Opacity(
              opacity: _alertFadeAnimation.value,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.orange.shade300,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: Colors.orange.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Traffic Alert',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _dismissAlert(alertId),
                            iconSize: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getTrafficAlertMessage(instruction.trafficCondition),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                debugPrint('🚦 [TRAFFIC-WIDGET] Requesting route recalculation');
                                widget.onRouteRecalculation?.call();
                                _dismissAlert(alertId);
                              },
                              icon: const Icon(Icons.alt_route),
                              label: const Text('Find Alternative'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange.shade700,
                                side: BorderSide(color: Colors.orange.shade300),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () => _dismissAlert(alertId),
                            child: const Text('Continue'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build route alternatives panel
  Widget _buildRouteAlternativesPanel(ThemeData theme, EnhancedNavigationState navState) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 100,
      left: 16,
      right: 16,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.alt_route,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Route Alternatives',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Alternative route options (placeholder)
              _buildAlternativeRouteOption(
                theme,
                'Fastest Route',
                '2 min faster',
                'Avoid highway traffic',
                Icons.speed,
                Colors.green,
              ),
              
              const SizedBox(height: 8),
              
              _buildAlternativeRouteOption(
                theme,
                'Shortest Route',
                '1.2 km shorter',
                'Through city center',
                Icons.straighten,
                Colors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build alternative route option
  Widget _buildAlternativeRouteOption(
    ThemeData theme,
    String title,
    String benefit,
    String description,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () {
        debugPrint('🚦 [TRAFFIC-WIDGET] Selected alternative route: $title');
        widget.onRouteRecalculation?.call();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          benefit,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }

  /// Helper methods for traffic condition handling

  /// Check if traffic alert should be shown
  bool _shouldShowTrafficAlert(NavigationInstruction instruction) {
    final condition = instruction.trafficCondition;
    return condition == TrafficCondition.heavy || condition == TrafficCondition.severe;
  }

  /// Check if route alternatives should be shown
  bool _shouldShowRouteAlternatives(NavigationInstruction instruction) {
    return instruction.trafficCondition == TrafficCondition.severe;
  }

  /// Get traffic condition color
  Color _getTrafficConditionColor(TrafficCondition condition) {
    switch (condition) {
      case TrafficCondition.light:
        return Colors.green;
      case TrafficCondition.moderate:
        return Colors.orange;
      case TrafficCondition.heavy:
        return Colors.red;
      case TrafficCondition.severe:
        return Colors.red.shade800;
      default:
        return Colors.grey;
    }
  }

  /// Get traffic condition icon
  IconData _getTrafficConditionIcon(TrafficCondition condition) {
    switch (condition) {
      case TrafficCondition.light:
        return Icons.trending_up;
      case TrafficCondition.moderate:
        return Icons.trending_flat;
      case TrafficCondition.heavy:
        return Icons.trending_down;
      case TrafficCondition.severe:
        return Icons.warning;
      default:
        return Icons.help_outline;
    }
  }

  /// Get traffic condition text
  String _getTrafficConditionText(TrafficCondition condition) {
    switch (condition) {
      case TrafficCondition.light:
        return 'Light Traffic';
      case TrafficCondition.moderate:
        return 'Moderate Traffic';
      case TrafficCondition.heavy:
        return 'Heavy Traffic';
      case TrafficCondition.severe:
        return 'Severe Traffic';
      default:
        return 'Unknown';
    }
  }

  /// Get traffic alert message
  String _getTrafficAlertMessage(TrafficCondition condition) {
    switch (condition) {
      case TrafficCondition.heavy:
        return 'Heavy traffic detected ahead. You may experience delays of 5-10 minutes. Consider taking an alternative route.';
      case TrafficCondition.severe:
        return 'Severe traffic congestion ahead. Significant delays expected (10+ minutes). Alternative route strongly recommended.';
      default:
        return 'Traffic conditions have changed on your route.';
    }
  }

  /// Dismiss traffic alert
  void _dismissAlert(String alertId) {
    setState(() {
      _dismissedAlerts.add(alertId);
    });

    _alertAnimationController.reverse().then((_) {
      widget.onDismissAlert?.call(alertId);
    });

    debugPrint('🚦 [TRAFFIC-WIDGET] Dismissed traffic alert: $alertId');
  }
}
