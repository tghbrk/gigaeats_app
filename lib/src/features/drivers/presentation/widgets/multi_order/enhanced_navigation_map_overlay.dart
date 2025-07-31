import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../providers/enhanced_navigation_provider.dart';
import '../../providers/multi_order_batch_provider.dart';
import '../../providers/enhanced_location_provider.dart';

/// Enhanced navigation map overlay with Phase 2 improvements
/// Provides comprehensive in-app navigation UI with Google Maps integration,
/// voice guidance controls, real-time traffic integration, and multi-waypoint support
class EnhancedNavigationMapOverlay extends ConsumerStatefulWidget {
  final GoogleMapController? mapController;
  final bool showNavigationControls;
  final bool showTrafficLayer;
  final bool showVoiceControls;
  final VoidCallback? onToggleVoice;
  final VoidCallback? onToggleTraffic;
  final VoidCallback? onCenterOnLocation;
  final VoidCallback? onStopNavigation;

  const EnhancedNavigationMapOverlay({
    super.key,
    this.mapController,
    this.showNavigationControls = true,
    this.showTrafficLayer = true,
    this.showVoiceControls = true,
    this.onToggleVoice,
    this.onToggleTraffic,
    this.onCenterOnLocation,
    this.onStopNavigation,
  });

  @override
  ConsumerState<EnhancedNavigationMapOverlay> createState() => _EnhancedNavigationMapOverlayState();
}

class _EnhancedNavigationMapOverlayState extends ConsumerState<EnhancedNavigationMapOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsSlideAnimation;
  late Animation<double> _controlsFadeAnimation;

  @override
  void initState() {
    super.initState();
    
    debugPrint('🗺️ [NAV-MAP-OVERLAY] Initializing enhanced navigation map overlay (Phase 2)');
    
    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _controlsSlideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controlsAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _controlsFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controlsAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Show controls initially
    _controlsAnimationController.reverse();
  }

  @override
  void dispose() {
    _controlsAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navState = ref.watch(enhancedNavigationProvider);
    final locationState = ref.watch(enhancedLocationProvider);
    final batchState = ref.watch(multiOrderBatchProvider);

    if (!navState.isNavigating) {
      return const SizedBox.shrink();
    }

    debugPrint('🗺️ [NAV-MAP-OVERLAY] Building enhanced navigation map overlay');

    return Stack(
      children: [
        // Navigation controls panel (bottom)
        if (widget.showNavigationControls)
          _buildNavigationControlsPanel(theme, navState, locationState),
        
        // Speed and ETA display (top right)
        _buildSpeedAndETADisplay(theme, navState, locationState),
        
        // Multi-waypoint progress indicator (top left)
        if (batchState.hasActiveBatch)
          _buildMultiWaypointProgressIndicator(theme, navState, batchState),
        
        // Map controls (right side)
        _buildMapControls(theme, navState),
        
        // Traffic layer toggle (if enabled)
        if (widget.showTrafficLayer)
          _buildTrafficLayerToggle(theme, navState),
      ],
    );
  }

  /// Build navigation controls panel at bottom
  Widget _buildNavigationControlsPanel(
    ThemeData theme, 
    EnhancedNavigationState navState,
    EnhancedLocationState locationState,
  ) {
    return AnimatedBuilder(
      animation: _controlsAnimationController,
      builder: (context, child) {
        return Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 20,
          left: 16,
          right: 16,
          child: Transform.translate(
            offset: Offset(0, _controlsSlideAnimation.value * 100),
            child: Opacity(
              opacity: _controlsFadeAnimation.value,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Voice control
                      if (widget.showVoiceControls)
                        _buildVoiceControlButton(theme, navState),
                      
                      const SizedBox(width: 12),
                      
                      // Center on location
                      _buildCenterLocationButton(theme),
                      
                      const SizedBox(width: 12),
                      
                      // Traffic toggle
                      if (widget.showTrafficLayer)
                        _buildTrafficToggleButton(theme, navState),
                      
                      const Spacer(),
                      
                      // Stop navigation
                      _buildStopNavigationButton(theme),
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

  /// Build enhanced speed and ETA display with improved visual hierarchy
  Widget _buildSpeedAndETADisplay(
    ThemeData theme,
    EnhancedNavigationState navState,
    EnhancedLocationState locationState,
  ) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        shadowColor: Colors.black.withValues(alpha: 0.15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surface.withValues(alpha: 0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Enhanced current speed display
              if (locationState.currentPosition?.speed != null && locationState.currentPosition!.speed > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getSpeedColor(theme, locationState.currentPosition!.speed * 3.6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.speed_rounded,
                        size: 18,
                        color: _getSpeedColor(theme, locationState.currentPosition!.speed * 3.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${(locationState.currentPosition!.speed * 3.6).toInt()}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getSpeedColor(theme, locationState.currentPosition!.speed * 3.6),
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'km/h',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Enhanced remaining distance display
              if (navState.remainingDistance != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.straighten_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDistanceValue(navState.remainingDistance!),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _getDistanceUnit(navState.remainingDistance!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Enhanced ETA display
              if (navState.estimatedArrival != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getETAColor(theme, navState.estimatedArrival!).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: _getETAColor(theme, navState.estimatedArrival!),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatETA(navState.estimatedArrival!),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getETAColor(theme, navState.estimatedArrival!),
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

  /// Build multi-waypoint progress indicator
  Widget _buildMultiWaypointProgressIndicator(
    ThemeData theme,
    EnhancedNavigationState navState,
    MultiOrderBatchState batchState,
  ) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.route,
                    color: theme.colorScheme.secondary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Multi-Order',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${batchState.completedDeliveries + 1} of ${batchState.totalOrders}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build map controls (zoom, compass, etc.)
  Widget _buildMapControls(ThemeData theme, EnhancedNavigationState navState) {
    return Positioned(
      right: 16,
      top: MediaQuery.of(context).padding.top + 200,
      child: Column(
        children: [
          // Zoom in
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _zoomIn(),
                tooltip: 'Zoom In',
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Zoom out
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () => _zoomOut(),
                tooltip: 'Zoom Out',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build traffic layer toggle
  Widget _buildTrafficLayerToggle(ThemeData theme, EnhancedNavigationState navState) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 140,
      right: 16,
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(
              Icons.traffic,
              color: widget.showTrafficLayer
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
            onPressed: widget.onToggleTraffic,
            tooltip: 'Toggle Traffic Layer',
          ),
        ),
      ),
    );
  }

  /// Build voice control button
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

  /// Build center location button
  Widget _buildCenterLocationButton(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.outline.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(
          Icons.my_location,
          color: theme.colorScheme.primary,
        ),
        onPressed: widget.onCenterOnLocation,
        tooltip: 'Center on Location',
      ),
    );
  }

  /// Build traffic toggle button
  Widget _buildTrafficToggleButton(ThemeData theme, EnhancedNavigationState navState) {
    return Container(
      decoration: BoxDecoration(
        color: widget.showTrafficLayer
            ? theme.colorScheme.secondary.withValues(alpha: 0.15)
            : theme.colorScheme.outline.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(
          Icons.traffic,
          color: widget.showTrafficLayer
              ? theme.colorScheme.secondary
              : theme.colorScheme.outline,
        ),
        onPressed: widget.onToggleTraffic,
        tooltip: 'Toggle Traffic',
      ),
    );
  }

  /// Build stop navigation button
  Widget _buildStopNavigationButton(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(
          Icons.stop,
          color: Colors.red.shade700,
        ),
        onPressed: () {
          _showStopNavigationDialog();
        },
        tooltip: 'Stop Navigation',
      ),
    );
  }

  /// Show stop navigation confirmation dialog
  void _showStopNavigationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Navigation'),
        content: const Text('Are you sure you want to stop navigation? You can restart it anytime.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onStopNavigation?.call();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }



  /// Zoom in on map
  void _zoomIn() {
    widget.mapController?.animateCamera(
      CameraUpdate.zoomIn(),
    );
  }

  /// Zoom out on map
  void _zoomOut() {
    widget.mapController?.animateCamera(
      CameraUpdate.zoomOut(),
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

  /// Get appropriate color for speed display based on value
  Color _getSpeedColor(ThemeData theme, double speedKmh) {
    if (speedKmh > 80) return theme.colorScheme.error;
    if (speedKmh > 60) return Colors.orange;
    if (speedKmh > 30) return theme.colorScheme.primary;
    return theme.colorScheme.secondary;
  }

  /// Format distance value for better readability
  String _formatDistanceValue(double distanceMeters) {
    if (distanceMeters >= 1000) {
      return (distanceMeters / 1000).toStringAsFixed(1);
    } else {
      return distanceMeters.toStringAsFixed(0);
    }
  }

  /// Get appropriate distance unit
  String _getDistanceUnit(double distanceMeters) {
    return distanceMeters >= 1000 ? 'km' : 'm';
  }

  /// Get ETA color based on time remaining and traffic conditions
  Color _getETAColor(ThemeData theme, DateTime eta) {
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
}
