import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/user_role.dart';
import '../../../../shared/widgets/auth_guard.dart';
import '../../../../core/constants/app_constants.dart';
import '../widgets/multi_order/batch_overview_card.dart';
import '../widgets/multi_order/order_sequence_card.dart';
import '../widgets/multi_order/route_optimization_controls.dart';
import '../widgets/multi_order/batch_progress_indicator.dart';
import '../widgets/multi_order/quick_actions_panel.dart';
import '../providers/multi_order_batch_provider.dart';
import '../providers/route_optimization_provider.dart';

import '../providers/driver_earnings_provider.dart';
import '../../data/models/delivery_batch.dart';
import '../../data/models/batch_operation_results.dart';

/// Multi-order driver dashboard for batch delivery management
/// Provides comprehensive interface for managing multiple orders with route optimization
class MultiOrderDriverDashboard extends ConsumerStatefulWidget {
  const MultiOrderDriverDashboard({super.key});

  @override
  ConsumerState<MultiOrderDriverDashboard> createState() => _MultiOrderDriverDashboardState();
}

class _MultiOrderDriverDashboardState extends ConsumerState<MultiOrderDriverDashboard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    debugPrint('🚛 [MULTI-ORDER-DASHBOARD] MultiOrderDriverDashboard initState called');
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
    
    // Initialize dashboard data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDashboard();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeDashboard() {
    debugPrint('🚛 [MULTI-ORDER-DASHBOARD] Initializing dashboard');

    // Get actual driver ID from provider
    final driverIdAsync = ref.read(currentDriverIdProvider);
    driverIdAsync.when(
      data: (driverId) {
        if (driverId != null) {
          debugPrint('🚛 [MULTI-ORDER-DASHBOARD] Loading batch for driver: $driverId');
          ref.read(multiOrderBatchProvider.notifier).loadActiveBatch(driverId);
        } else {
          debugPrint('🚛 [MULTI-ORDER-DASHBOARD] No driver ID found');
        }
      },
      loading: () => debugPrint('🚛 [MULTI-ORDER-DASHBOARD] Loading driver ID...'),
      error: (error, stack) => debugPrint('🚛 [MULTI-ORDER-DASHBOARD] Error getting driver ID: $error'),
    );

    // Check for active route optimization
    final routeState = ref.read(routeOptimizationProvider);
    if (routeState.currentRoute != null) {
      debugPrint('🗺️ [MULTI-ORDER-DASHBOARD] Active route found: ${routeState.currentRoute!.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final batchState = ref.watch(multiOrderBatchProvider);
    final routeState = ref.watch(routeOptimizationProvider);

    return AuthGuard(
      allowedRoles: const [UserRole.driver, UserRole.admin],
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: _buildAppBar(theme, batchState),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            child: CustomScrollView(
              slivers: [
                // Batch Progress Indicator
                if (batchState.activeBatch != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: BatchProgressIndicator(
                        batch: batchState.activeBatch!,
                        routeProgress: routeState.routeProgress,
                      ),
                    ),
                  ),

                // Batch Overview Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: BatchOverviewCard(
                      batch: batchState.activeBatch,
                      isLoading: batchState.isLoading,
                      error: batchState.error,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Route Optimization Controls
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: RouteOptimizationControls(
                      optimizedRoute: routeState.currentRoute,
                      isOptimizing: routeState.isOptimizing,
                      onOptimize: _handleRouteOptimization,
                      onReoptimize: _handleReoptimization,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Order Sequence Cards
                if (batchState.batchOrders.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final batchOrder = batchState.batchOrders[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4.0,
                          ),
                          child: OrderSequenceCard(
                            batchOrder: batchOrder,
                            sequence: index + 1,
                            isActive: _isOrderActive(batchOrder, routeState),
                            onReorder: _handleOrderReorder,
                            onOrderAction: _handleOrderAction,
                          ),
                        );
                      },
                      childCount: batchState.batchOrders.length,
                    ),
                  ),

                // Empty State
                if (batchState.activeBatch == null && !batchState.isLoading)
                  SliverFillRemaining(
                    child: _buildEmptyState(theme),
                  ),

                // Bottom padding for FAB
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(theme, batchState),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, MultiOrderBatchState batchState) {
    return AppBar(
      title: const Text('Multi-Order Dashboard'),
      elevation: 0,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          debugPrint('🔙 [MULTI-ORDER-DASHBOARD] Navigating back to driver dashboard using GoRouter');
          context.go(AppRoutes.driverDashboard);
        },
        tooltip: 'Back to Driver Dashboard',
      ),
      actions: [
        // Batch status indicator
        if (batchState.activeBatch != null)
          Container(
            margin: const EdgeInsets.only(right: 8.0),
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: _getBatchStatusColor(batchState.activeBatch!.status),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Text(
              batchState.activeBatch!.status.displayName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        
        // Refresh button
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _handleRefresh,
          tooltip: 'Refresh Dashboard',
        ),
        
        // Settings menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'optimization_settings',
              child: ListTile(
                leading: Icon(Icons.tune),
                title: Text('Optimization Settings'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'batch_history',
              child: ListTile(
                leading: Icon(Icons.history),
                title: Text('Batch History'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'help',
              child: ListTile(
                leading: Icon(Icons.help_outline),
                title: Text('Help'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.route,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No Active Batch',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a new batch to start multi-order delivery',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _handleCreateBatch,
                icon: const Icon(Icons.add),
                label: const Text('Create Batch'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton(ThemeData theme, MultiOrderBatchState batchState) {
    if (batchState.activeBatch == null) return null;

    return FloatingActionButton.extended(
      onPressed: _handleQuickActions,
      icon: const Icon(Icons.flash_on),
      label: const Text('Quick Actions'),
      backgroundColor: theme.colorScheme.secondary,
      foregroundColor: theme.colorScheme.onSecondary,
    );
  }

  Color _getBatchStatusColor(BatchStatus status) {
    switch (status) {
      case BatchStatus.planned:
        return Colors.blue;
      case BatchStatus.active:
        return Colors.green;
      case BatchStatus.paused:
        return Colors.orange;
      case BatchStatus.completed:
        return Colors.purple;
      case BatchStatus.cancelled:
        return Colors.red;
    }
  }

  bool _isOrderActive(BatchOrderWithDetails batchOrder, RouteOptimizationState routeState) {
    if (routeState.currentWaypoint == null) return false;
    return routeState.currentWaypoint!.orderId == batchOrder.order.id;
  }

  Future<void> _handleRefresh() async {
    debugPrint('🔄 [MULTI-ORDER-DASHBOARD] Refreshing dashboard');

    // Get actual driver ID from provider
    final driverIdAsync = ref.read(currentDriverIdProvider);
    await driverIdAsync.when(
      data: (driverId) async {
        if (driverId != null) {
          debugPrint('🔄 [MULTI-ORDER-DASHBOARD] Refreshing batch for driver: $driverId');
          await ref.read(multiOrderBatchProvider.notifier).loadActiveBatch(driverId);
        } else {
          debugPrint('🔄 [MULTI-ORDER-DASHBOARD] No driver ID found for refresh');
        }
      },
      loading: () async => debugPrint('🔄 [MULTI-ORDER-DASHBOARD] Loading driver ID for refresh...'),
      error: (error, stack) async => debugPrint('🔄 [MULTI-ORDER-DASHBOARD] Error getting driver ID for refresh: $error'),
    );
  }

  void _handleRouteOptimization() {
    debugPrint('🗺️ [MULTI-ORDER-DASHBOARD] Starting route optimization');
    
    final batchState = ref.read(multiOrderBatchProvider);
    if (batchState.activeBatch == null) {
      _showSnackBar('No active batch to optimize');
      return;
    }

    // TODO: Implement route optimization trigger
    _showSnackBar('Route optimization started');
  }

  void _handleReoptimization() {
    debugPrint('🔄 [MULTI-ORDER-DASHBOARD] Starting route reoptimization');
    
    ref.read(routeOptimizationProvider.notifier).reoptimizeRoute();
  }

  void _handleOrderReorder(String orderId, int newPosition) {
    debugPrint('📋 [MULTI-ORDER-DASHBOARD] Reordering order $orderId to position $newPosition');
    
    // TODO: Implement order reordering logic
    _showSnackBar('Order reordered successfully');
  }

  void _handleOrderAction(String orderId, String action) {
    debugPrint('⚡ [MULTI-ORDER-DASHBOARD] Order action: $action for order $orderId');
    
    // TODO: Implement order action handling
    _showSnackBar('Order action: $action');
  }

  void _handleCreateBatch() {
    debugPrint('➕ [MULTI-ORDER-DASHBOARD] Creating new batch');

    // Show dialog to create a new batch
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Batch'),
        content: const Text('Would you like to create a new delivery batch with available orders?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _createNewBatch();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewBatch() async {
    try {
      debugPrint('🚛 [MULTI-ORDER-DASHBOARD] Starting batch creation process');

      // Get the current driver ID from provider
      final driverIdAsync = ref.read(currentDriverIdProvider);
      final driverId = await driverIdAsync.when(
        data: (id) async => id,
        loading: () async => throw Exception('Loading driver ID...'),
        error: (error, stack) async => throw Exception('Error getting driver ID: $error'),
      );

      if (driverId == null) {
        _showSnackBar('Error: Driver not found');
        return;
      }

      debugPrint('🚛 [MULTI-ORDER-DASHBOARD] Creating batch for driver: $driverId');

      // Trigger batch creation through the provider
      await ref.read(multiOrderBatchProvider.notifier).createOptimizedBatch(
        driverId: driverId,
        orderIds: [], // Will auto-select available orders
      );

      _showSnackBar('Batch creation initiated');

    } catch (e) {
      debugPrint('❌ [MULTI-ORDER-DASHBOARD] Error creating batch: $e');
      _showSnackBar('Error creating batch: $e');
    }
  }

  void _handleQuickActions() {
    debugPrint('⚡ [MULTI-ORDER-DASHBOARD] Opening quick actions');
    
    showModalBottomSheet(
      context: context,
      builder: (context) => const QuickActionsPanel(),
    );
  }

  void _handleMenuAction(String action) {
    debugPrint('📋 [MULTI-ORDER-DASHBOARD] Menu action: $action');
    
    switch (action) {
      case 'optimization_settings':
        // TODO: Navigate to optimization settings
        _showSnackBar('Optimization settings not implemented yet');
        break;
      case 'batch_history':
        // TODO: Navigate to batch history
        _showSnackBar('Batch history not implemented yet');
        break;
      case 'help':
        // TODO: Show help dialog
        _showSnackBar('Help not implemented yet');
        break;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
