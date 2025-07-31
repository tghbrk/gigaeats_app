import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/navigation_models.dart';
import '../../providers/enhanced_navigation_provider.dart';

/// Enhanced overlay widget for displaying turn-by-turn navigation instructions
/// Phase 2 enhancements: Multi-waypoint support, voice guidance controls, real-time traffic integration
/// Provides comprehensive navigation UI with Material Design 3 patterns and batch delivery support
class NavigationInstructionOverlay extends ConsumerStatefulWidget {
  final bool showVoiceControls;
  final bool showTrafficAlerts;
  final bool showMultiWaypointInfo;
  final VoidCallback? onDismiss;
  final VoidCallback? onToggleVoice;
  final VoidCallback? onToggleTraffic;
  final Function(String orderId)? onWaypointSelected;

  const NavigationInstructionOverlay({
    super.key,
    this.showVoiceControls = true,
    this.showTrafficAlerts = true,
    this.showMultiWaypointInfo = true,
    this.onDismiss,
    this.onToggleVoice,
    this.onToggleTraffic,
    this.onWaypointSelected,
  });

  @override
  ConsumerState<NavigationInstructionOverlay> createState() => _NavigationInstructionOverlayState();
}

class _NavigationInstructionOverlayState extends ConsumerState<NavigationInstructionOverlay>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _trafficAlertController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _trafficAlertAnimation;

  bool _showTrafficDetails = false;

  @override
  void initState() {
    super.initState();

    debugPrint('🧭 [NAV-OVERLAY] Initializing enhanced navigation instruction overlay (Phase 2)');

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _trafficAlertController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _trafficAlertAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _trafficAlertController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _trafficAlertController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navState = ref.watch(enhancedNavigationProvider);

    if (!navState.isNavigating || navState.currentInstruction == null) {
      return const SizedBox.shrink();
    }

    debugPrint('🧭 [NAV-OVERLAY] Building enhanced navigation overlay - Current instruction: ${navState.currentInstruction?.text}');

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Stack(
              children: [
                // Main instruction card
                _buildEnhancedInstructionCard(theme, navState),

                // Traffic alert overlay (if enabled and traffic detected)
                if (widget.showTrafficAlerts && _hasTrafficAlert(navState))
                  _buildTrafficAlertOverlay(theme, navState),

                // Multi-waypoint info panel (if enabled and batch active)
                if (widget.showMultiWaypointInfo && _hasBatchNavigation(navState))
                  _buildMultiWaypointPanel(theme, navState),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Enhanced instruction card with Phase 2 improvements
  Widget _buildEnhancedInstructionCard(ThemeData theme, EnhancedNavigationState navState) {
    final instruction = navState.currentInstruction!;

    debugPrint('🧭 [NAV-OVERLAY] Building enhanced instruction card for: ${instruction.text}');

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(20),
        shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.3),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              width: 2,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Enhanced header with navigation status and controls
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getInstructionIcon(instruction.type),
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Turn-by-Turn Navigation',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        if (navState.currentSession?.batchId != null)
                          Text(
                            'Multi-Order Delivery',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Enhanced controls
                  _buildNavigationControls(theme, navState),
                ],
              ),

              const SizedBox(height: 20),

              // Enhanced main instruction with traffic info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getInstructionIcon(instruction.type),
                            color: theme.colorScheme.onPrimary,
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                instruction.text,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              if (instruction.streetName != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'on ${instruction.streetName}',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              // Traffic condition indicator
                              if (instruction.trafficCondition != TrafficCondition.unknown) ...[
                                const SizedBox(height: 8),
                                _buildTrafficConditionChip(theme, instruction.trafficCondition),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Enhanced distance and navigation info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Distance to next instruction
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.straighten,
                            size: 16,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            instruction.distanceText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // ETA info
                    if (navState.estimatedArrival != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: theme.colorScheme.onTertiaryContainer,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatETA(navState.estimatedArrival!),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const Spacer(),

                    // Enhanced voice controls
                    if (widget.showVoiceControls)
                      _buildVoiceControlButton(theme, navState),
                  ],
                ),
              ),

              // Enhanced next instruction preview
              if (navState.nextInstruction != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outline.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getInstructionIcon(navState.nextInstruction!.type),
                          color: theme.colorScheme.outline,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Next',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              navState.nextInstruction!.text,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Helper methods for Phase 2 enhancements

  /// Check if current navigation has traffic alerts
  bool _hasTrafficAlert(EnhancedNavigationState navState) {
    final instruction = navState.currentInstruction;
    if (instruction == null) return false;

    return instruction.trafficCondition == TrafficCondition.heavy ||
           instruction.trafficCondition == TrafficCondition.severe;
  }

  /// Check if current navigation is part of a batch delivery
  bool _hasBatchNavigation(EnhancedNavigationState navState) {
    return navState.currentSession?.batchId != null;
  }

  /// Build navigation controls (voice, traffic, dismiss)
  Widget _buildNavigationControls(ThemeData theme, EnhancedNavigationState navState) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Traffic toggle
        if (widget.showTrafficAlerts)
          IconButton(
            icon: Icon(
              Icons.traffic,
              color: _showTrafficDetails
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
            onPressed: () {
              setState(() {
                _showTrafficDetails = !_showTrafficDetails;
              });
              if (_showTrafficDetails) {
                _trafficAlertController.forward();
              } else {
                _trafficAlertController.reverse();
              }
              widget.onToggleTraffic?.call();
            },
            tooltip: 'Toggle Traffic Info',
          ),

        // Voice toggle
        if (widget.showVoiceControls)
          IconButton(
            icon: Icon(
              navState.isVoiceEnabled ? Icons.volume_up : Icons.volume_off,
              color: navState.isVoiceEnabled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
            onPressed: widget.onToggleVoice,
            tooltip: navState.isVoiceEnabled ? 'Mute Voice' : 'Enable Voice',
          ),

        // Dismiss button
        if (widget.onDismiss != null)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onDismiss,
            iconSize: 20,
            tooltip: 'Close Navigation',
          ),
      ],
    );
  }

  /// Build traffic condition chip
  Widget _buildTrafficConditionChip(ThemeData theme, TrafficCondition condition) {
    Color chipColor;
    IconData chipIcon;
    String chipText;

    switch (condition) {
      case TrafficCondition.light:
        chipColor = Colors.green;
        chipIcon = Icons.trending_up;
        chipText = 'Light Traffic';
        break;
      case TrafficCondition.moderate:
        chipColor = Colors.orange;
        chipIcon = Icons.trending_flat;
        chipText = 'Moderate Traffic';
        break;
      case TrafficCondition.heavy:
        chipColor = Colors.red;
        chipIcon = Icons.trending_down;
        chipText = 'Heavy Traffic';
        break;
      case TrafficCondition.severe:
        chipColor = Colors.red.shade800;
        chipIcon = Icons.warning;
        chipText = 'Severe Traffic';
        break;
      default:
        chipColor = theme.colorScheme.outline;
        chipIcon = Icons.help_outline;
        chipText = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, size: 14, color: chipColor),
          const SizedBox(width: 4),
          Text(
            chipText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Format ETA time
  String _formatETA(DateTime eta) {
    final now = DateTime.now();
    final difference = eta.difference(now);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min';
    } else {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      return '${hours}h ${minutes}min';
    }
  }

  /// Build enhanced voice control button
  Widget _buildVoiceControlButton(ThemeData theme, EnhancedNavigationState navState) {
    return Container(
      decoration: BoxDecoration(
        color: navState.isVoiceEnabled
            ? theme.colorScheme.primary.withValues(alpha: 0.15)
            : theme.colorScheme.outline.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(
          navState.isVoiceEnabled ? Icons.volume_up : Icons.volume_off,
          color: navState.isVoiceEnabled
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
        ),
        onPressed: widget.onToggleVoice,
        tooltip: navState.isVoiceEnabled ? 'Mute Voice' : 'Enable Voice',
      ),
    );
  }

  /// Build traffic alert overlay
  Widget _buildTrafficAlertOverlay(ThemeData theme, EnhancedNavigationState navState) {
    final instruction = navState.currentInstruction!;

    return AnimatedBuilder(
      animation: _trafficAlertController,
      builder: (context, child) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 200,
          left: 16,
          right: 16,
          child: Transform.scale(
            scale: _trafficAlertAnimation.value,
            child: Opacity(
              opacity: _trafficAlertAnimation.value,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                color: Colors.red.shade50,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning,
                            color: Colors.red.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Traffic Alert',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _trafficAlertController.reverse();
                              setState(() {
                                _showTrafficDetails = false;
                              });
                            },
                            iconSize: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _getTrafficAlertMessage(instruction.trafficCondition),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.red.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Implement route recalculation
                                debugPrint('🧭 [NAV-OVERLAY] Recalculating route to avoid traffic');
                              },
                              icon: const Icon(Icons.alt_route),
                              label: const Text('Find Alternative'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                side: BorderSide(color: Colors.red.shade300),
                              ),
                            ),
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

  /// Build multi-waypoint navigation panel
  Widget _buildMultiWaypointPanel(ThemeData theme, EnhancedNavigationState navState) {
    // This would integrate with the multi-order batch provider
    // For now, showing a placeholder implementation

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
              color: theme.colorScheme.secondary.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.route,
                    color: theme.colorScheme.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Multi-Order Route',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // TODO: Show full route details
                      debugPrint('🧭 [NAV-OVERLAY] Showing full route details');
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Placeholder for waypoint list
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Current: ${navState.currentSession?.destinationName ?? "Destination"}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '1 of 3',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get traffic alert message based on condition
  String _getTrafficAlertMessage(TrafficCondition condition) {
    switch (condition) {
      case TrafficCondition.heavy:
        return 'Heavy traffic detected ahead. Consider taking an alternative route to save time.';
      case TrafficCondition.severe:
        return 'Severe traffic congestion ahead. Significant delays expected. Alternative route strongly recommended.';
      default:
        return 'Traffic conditions have changed on your route.';
    }
  }

  IconData _getInstructionIcon(NavigationInstructionType type) {
    switch (type) {
      case NavigationInstructionType.turnLeft:
        return Icons.turn_left;
      case NavigationInstructionType.turnRight:
        return Icons.turn_right;
      case NavigationInstructionType.turnSlightLeft:
        return Icons.turn_slight_left;
      case NavigationInstructionType.turnSlightRight:
        return Icons.turn_slight_right;
      case NavigationInstructionType.turnSharpLeft:
        return Icons.turn_sharp_left;
      case NavigationInstructionType.turnSharpRight:
        return Icons.turn_sharp_right;
      case NavigationInstructionType.uturnLeft:
      case NavigationInstructionType.uturnRight:
        return Icons.u_turn_left;
      case NavigationInstructionType.straight:
        return Icons.straight;
      case NavigationInstructionType.rampLeft:
      case NavigationInstructionType.rampRight:
        return Icons.ramp_left;
      case NavigationInstructionType.merge:
        return Icons.merge;
      case NavigationInstructionType.forkLeft:
      case NavigationInstructionType.forkRight:
        return Icons.call_split;
      case NavigationInstructionType.roundaboutLeft:
      case NavigationInstructionType.roundaboutRight:
        return Icons.roundabout_left;
      case NavigationInstructionType.destination:
        return Icons.location_on;
      default:
        return Icons.navigation;
    }
  }
}
