import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/navigation_models.dart';
import '../../providers/enhanced_navigation_provider.dart';

/// Overlay widget for displaying turn-by-turn navigation instructions
/// Provides voice guidance integration and real-time instruction updates
class NavigationInstructionOverlay extends ConsumerStatefulWidget {
  final bool showVoiceControls;
  final VoidCallback? onDismiss;
  final VoidCallback? onToggleVoice;

  const NavigationInstructionOverlay({
    super.key,
    this.showVoiceControls = true,
    this.onDismiss,
    this.onToggleVoice,
  });

  @override
  ConsumerState<NavigationInstructionOverlay> createState() => _NavigationInstructionOverlayState();
}

class _NavigationInstructionOverlayState extends ConsumerState<NavigationInstructionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navState = ref.watch(enhancedNavigationProvider);

    if (!navState.isNavigating || navState.currentInstruction == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: _buildInstructionCard(theme, navState),
          ),
        );
      },
    );
  }

  Widget _buildInstructionCard(ThemeData theme, EnhancedNavigationState navState) {
    final instruction = navState.currentInstruction!;
    
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with dismiss button
              Row(
                children: [
                  Icon(
                    _getInstructionIcon(instruction.type),
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Navigation',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  if (widget.onDismiss != null)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onDismiss,
                      iconSize: 20,
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Main instruction
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getInstructionIcon(instruction.type),
                      color: theme.colorScheme.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          instruction.text,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (instruction.streetName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'on ${instruction.streetName}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Distance and next instruction
              Row(
                children: [
                  // Distance to next instruction
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      instruction.distanceText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Voice controls
                  if (widget.showVoiceControls) ...[
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
                  ],
                ],
              ),
              
              // Next instruction preview
              if (navState.nextInstruction != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getInstructionIcon(navState.nextInstruction!.type),
                        color: theme.colorScheme.outline,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Then ${navState.nextInstruction!.text}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
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
