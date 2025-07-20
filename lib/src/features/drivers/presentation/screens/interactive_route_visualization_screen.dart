import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../data/models/user_role.dart';
import '../providers/multi_order_batch_provider.dart';
import '../providers/route_optimization_provider.dart';
import '../providers/enhanced_navigation_provider.dart';
import '../widgets/multi_order/multi_order_route_map.dart';
import '../widgets/multi_order/navigation_instruction_overlay.dart';
import '../widgets/multi_order/route_reorder_dialog.dart';

/// Interactive route visualization screen for Phase 3.2
/// Integrates Google Maps with waypoint visualization, turn-by-turn navigation,
/// and interactive route management for multi-order delivery batches
class InteractiveRouteVisualizationScreen extends ConsumerStatefulWidget {
  const InteractiveRouteVisualizationScreen({super.key});

  @override
  ConsumerState<InteractiveRouteVisualizationScreen> createState() => _InteractiveRouteVisualizationScreenState();
}

class _InteractiveRouteVisualizationScreenState extends ConsumerState<InteractiveRouteVisualizationScreen> {
  String? _selectedOrderId;
  bool _showNavigationOverlay = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final batchState = ref.watch(multiOrderBatchProvider);
    final routeState = ref.watch(routeOptimizationProvider);
    final navState = ref.watch(enhancedNavigationProvider);

    // Check authentication and role
    if (authState.user == null || 
        (authState.user!.role != UserRole.driver && authState.user!.role != UserRole.admin)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Route Visualization'),
        ),
        body: const Center(
          child: Text('Access denied. Driver role required.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Route'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          // Route reorder button
          if (batchState.hasActiveBatch && batchState.batchOrders.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.reorder),
              onPressed: _showRouteReorderDialog,
              tooltip: 'Reorder Route',
            ),
          
          // Navigation toggle
          IconButton(
            icon: Icon(
              _showNavigationOverlay ? Icons.navigation : Icons.navigation_outlined,
            ),
            onPressed: () {
              setState(() {
                _showNavigationOverlay = !_showNavigationOverlay;
              });
            },
            tooltip: 'Toggle Navigation Overlay',
          ),
          
          // Voice toggle
          if (navState.isNavigating)
            IconButton(
              icon: Icon(
                navState.isVoiceEnabled ? Icons.volume_up : Icons.volume_off,
              ),
              onPressed: _toggleVoiceGuidance,
              tooltip: navState.isVoiceEnabled ? 'Mute Voice' : 'Enable Voice',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Main map view
          MultiOrderRouteMap(
            height: double.infinity,
            showControls: true,
            enableInteraction: true,
            onOrderSelected: (orderId) {
              setState(() {
                _selectedOrderId = orderId;
              });
            },
            onWaypointReorder: _showRouteReorderDialog,
          ),
          
          // Navigation instruction overlay
          if (_showNavigationOverlay && navState.isNavigating)
            NavigationInstructionOverlay(
              showVoiceControls: true,
              onDismiss: () {
                setState(() {
                  _showNavigationOverlay = false;
                });
              },
              onToggleVoice: _toggleVoiceGuidance,
            ),
          
          // Bottom action panel
          _buildBottomActionPanel(theme, batchState, routeState, navState),
          
          // Selected order details
          if (_selectedOrderId != null)
            _buildSelectedOrderDetails(theme),
        ],
      ),
    );
  }

  Widget _buildBottomActionPanel(
    ThemeData theme,
    MultiOrderBatchState batchState,
    RouteOptimizationState routeState,
    EnhancedNavigationState navState,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Batch status
            if (batchState.hasActiveBatch) ...[
              Row(
                children: [
                  Icon(
                    Icons.local_shipping,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Batch: ${batchState.activeBatch!.batchNumber}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${batchState.batchOrders.length} orders',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            
            // Action buttons
            Row(
              children: [
                // Start/Stop navigation
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: navState.isNavigating ? _stopNavigation : _startNavigation,
                    icon: Icon(navState.isNavigating ? Icons.stop : Icons.navigation),
                    label: Text(navState.isNavigating ? 'Stop Navigation' : 'Start Navigation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navState.isNavigating 
                          ? theme.colorScheme.error 
                          : theme.colorScheme.primary,
                      foregroundColor: navState.isNavigating 
                          ? theme.colorScheme.onError 
                          : theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Reoptimize route
                if (routeState.hasOptimizedRoute)
                  ElevatedButton.icon(
                    onPressed: routeState.isOptimizing ? null : _reoptimizeRoute,
                    icon: routeState.isOptimizing 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text('Reoptimize'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedOrderDetails(ThemeData theme) {
    final batchState = ref.watch(multiOrderBatchProvider);
    final selectedOrder = batchState.batchOrders
        .where((o) => o.order.id == _selectedOrderId)
        .firstOrNull;

    if (selectedOrder == null) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedOrder.order.vendorName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedOrderId = null;
                      });
                    },
                    iconSize: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Customer: ${selectedOrder.order.customerName}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Order #${selectedOrder.order.orderNumber}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.restaurant,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Pickup: ${selectedOrder.batchOrder.pickupSequence}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Delivery: ${selectedOrder.batchOrder.deliverySequence}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRouteReorderDialog() {
    final batchState = ref.read(multiOrderBatchProvider);
    final routeState = ref.read(routeOptimizationProvider);

    if (!batchState.hasActiveBatch || batchState.batchOrders.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => RouteReorderDialog(
        orders: batchState.batchOrders,
        currentRoute: routeState.currentRoute,
        onReorder: (newOrderSequence) {
          // Handle route reordering
          debugPrint('🔄 [ROUTE-VIZ] New order sequence: $newOrderSequence');
          // TODO: Implement route reordering logic
        },
      ),
    );
  }

  void _toggleVoiceGuidance() {
    final navNotifier = ref.read(enhancedNavigationProvider.notifier);
    navNotifier.toggleVoiceGuidance();
  }

  void _startNavigation() {
    // TODO: Implement navigation start logic
    debugPrint('🧭 [ROUTE-VIZ] Starting navigation');
  }

  void _stopNavigation() {
    final navNotifier = ref.read(enhancedNavigationProvider.notifier);
    navNotifier.stopNavigation();
  }

  void _reoptimizeRoute() {
    // TODO: Implement route reoptimization logic
    debugPrint('🔄 [ROUTE-VIZ] Reoptimizing route');
  }
}
