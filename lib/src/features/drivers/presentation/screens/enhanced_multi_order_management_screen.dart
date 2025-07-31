import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/user_role.dart';
import '../../../../shared/widgets/auth_guard.dart';
import '../../../../core/constants/app_constants.dart';
import '../widgets/multi_order/enhanced_batch_overview_card.dart';
import '../widgets/multi_order/real_time_route_adjustment_panel.dart';
import '../widgets/multi_order/multi_order_action_controls.dart';
import '../widgets/multi_order/batch_performance_metrics.dart';
import '../providers/multi_order_batch_provider.dart';
import '../providers/route_optimization_provider.dart';
import '../providers/driver_earnings_provider.dart';

import '../../data/models/route_optimization_models.dart';

/// Enhanced Multi-Order Management Screen for Phase 3
/// Provides comprehensive interface for managing multiple orders with real-time route optimization,
/// dynamic batch management, and advanced driver controls
class EnhancedMultiOrderManagementScreen extends ConsumerStatefulWidget {
  const EnhancedMultiOrderManagementScreen({super.key});

  @override
  ConsumerState<EnhancedMultiOrderManagementScreen> createState() => _EnhancedMultiOrderManagementScreenState();
}

class _EnhancedMultiOrderManagementScreenState extends ConsumerState<EnhancedMultiOrderManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _animationController.forward();
    _initializeScreen();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _initializeScreen() {
    debugPrint('🚛 [ENHANCED-MULTI-ORDER] Initializing enhanced multi-order management screen');

    // Get actual driver ID from provider
    final driverIdAsync = ref.read(currentDriverIdProvider);
    driverIdAsync.when(
      data: (driverId) {
        if (driverId != null) {
          debugPrint('🚛 [ENHANCED-MULTI-ORDER] Loading batch for driver: $driverId');
          ref.read(multiOrderBatchProvider.notifier).loadActiveBatch(driverId);
        } else {
          debugPrint('🚛 [ENHANCED-MULTI-ORDER] No driver ID found');
        }
      },
      loading: () => debugPrint('🚛 [ENHANCED-MULTI-ORDER] Loading driver ID...'),
      error: (error, stack) => debugPrint('🚛 [ENHANCED-MULTI-ORDER] Error getting driver ID: $error'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final batchState = ref.watch(multiOrderBatchProvider);
    final routeState = ref.watch(routeOptimizationProvider);
    final realTimeState = ref.watch(realTimeRouteProvider);

    return AuthGuard(
      allowedRoles: const [UserRole.driver, UserRole.admin],
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: _buildAppBar(theme, batchState),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Real-time route adjustment notification
              if (realTimeState.needsAdjustment)
                _buildRouteAdjustmentNotification(theme, realTimeState),
              
              // Tab bar
              _buildTabBar(theme),
              
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBatchOverviewTab(theme, batchState, routeState),
                    _buildRouteManagementTab(theme, batchState, routeState, realTimeState),
                    _buildPerformanceTab(theme, batchState),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(theme, batchState),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, MultiOrderBatchState batchState) {
    return AppBar(
      title: const Text('Multi-Order Management'),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          debugPrint('🔙 [ENHANCED-MULTI-ORDER] Navigating back to driver dashboard using GoRouter');
          context.go(AppRoutes.driverDashboard);
        },
        tooltip: 'Back to Driver Dashboard',
      ),
      actions: [
        if (batchState.activeBatch != null)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
            tooltip: 'Refresh batch data',
          ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: _showBatchSettings,
          tooltip: 'Batch settings',
        ),
      ],
    );
  }

  Widget _buildRouteAdjustmentNotification(ThemeData theme, RealTimeRouteState realTimeState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      color: theme.colorScheme.primaryContainer,
      child: Row(
        children: [
          Icon(
            Icons.route,
            color: theme.colorScheme.onPrimaryContainer,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Route adjustment recommended based on current conditions',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: _handleRouteAdjustment,
            child: Text(
              'ADJUST',
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Batch Overview', icon: Icon(Icons.dashboard)),
          Tab(text: 'Route Management', icon: Icon(Icons.route)),
          Tab(text: 'Performance', icon: Icon(Icons.analytics)),
        ],
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        indicatorColor: theme.colorScheme.primary,
        indicatorWeight: 3,
      ),
    );
  }

  Widget _buildBatchOverviewTab(
    ThemeData theme,
    MultiOrderBatchState batchState,
    RouteOptimizationState routeState,
  ) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced batch overview card
            EnhancedBatchOverviewCard(
              batch: batchState.activeBatch,
              batchSummary: batchState.batchSummary,
              isLoading: batchState.isLoading,
              error: batchState.error,
            ),
            
            const SizedBox(height: 16),
            
            // Multi-order action controls
            MultiOrderActionControls(
              batch: batchState.activeBatch,
              batchOrders: batchState.batchOrders,
              onAddOrder: _handleAddOrder,
              onRemoveOrder: _handleRemoveOrder,
              onReorderBatch: _handleReorderBatch,
            ),
            
            const SizedBox(height: 16),
            
            // Order list with enhanced controls
            if (batchState.batchOrders.isNotEmpty)
              _buildOrderList(theme, batchState),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteManagementTab(
    ThemeData theme,
    MultiOrderBatchState batchState,
    RouteOptimizationState routeState,
    RealTimeRouteState realTimeState,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Real-time route adjustment panel
          RealTimeRouteAdjustmentPanel(
            currentRoute: routeState.currentRoute,
            realTimeState: realTimeState,
            onCalculateAdjustment: _handleCalculateRouteAdjustment,
            onApplyAdjustment: _handleApplyRouteAdjustment,
          ),
          
          const SizedBox(height: 16),
          
          // Route optimization controls
          _buildRouteOptimizationControls(theme, routeState),
          
          const SizedBox(height: 16),
          
          // Route preview map (placeholder)
          _buildRoutePreviewMap(theme, routeState),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab(ThemeData theme, MultiOrderBatchState batchState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Batch performance metrics
          BatchPerformanceMetrics(
            batch: batchState.activeBatch,
            batchSummary: batchState.batchSummary,
          ),
          
          const SizedBox(height: 16),
          
          // Performance charts and analytics (placeholder)
          _buildPerformanceCharts(theme, batchState),
        ],
      ),
    );
  }

  Widget _buildOrderList(ThemeData theme, MultiOrderBatchState batchState) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Orders in Batch (${batchState.batchOrders.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: batchState.batchOrders.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final batchOrder = batchState.batchOrders[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                title: Text(batchOrder.order.vendorName),
                subtitle: Text(batchOrder.order.customerName),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) => _handleOrderAction(value, batchOrder.batchOrder.orderId),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Text('View Details'),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove from Batch'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRouteOptimizationControls(ThemeData theme, RouteOptimizationState routeState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Route Optimization',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: routeState.isOptimizing ? null : _handleOptimizeRoute,
                    icon: routeState.isOptimizing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.route),
                    label: Text(routeState.isOptimizing ? 'Optimizing...' : 'Optimize Route'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _handleStartNavigation,
                    icon: const Icon(Icons.navigation),
                    label: const Text('Start Navigation'),
                  ),
                ),
              ],
            ),
            if (routeState.currentRoute != null) ...[
              const SizedBox(height: 12),
              _buildRouteMetrics(theme, routeState.currentRoute!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRouteMetrics(ThemeData theme, OptimizedRoute route) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(
            theme,
            'Distance',
            '${route.totalDistanceKm.toStringAsFixed(1)} km',
            Icons.straighten,
          ),
          _buildMetricItem(
            theme,
            'Duration',
            '${route.totalDuration.inMinutes} min',
            Icons.access_time,
          ),
          _buildMetricItem(
            theme,
            'Score',
            '${route.optimizationScore.toStringAsFixed(0)}%',
            Icons.star,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(ThemeData theme, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
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

  Widget _buildRoutePreviewMap(ThemeData theme, RouteOptimizationState routeState) {
    return Card(
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map,
                size: 48,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 8),
              Text(
                'Route Preview Map',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Interactive map will be displayed here',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceCharts(ThemeData theme, MultiOrderBatchState batchState) {
    return Card(
      child: Container(
        height: 200,
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Analytics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.analytics,
                      size: 48,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Performance charts will be displayed here',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton(ThemeData theme, MultiOrderBatchState batchState) {
    if (batchState.activeBatch == null) {
      return FloatingActionButton.extended(
        onPressed: _handleCreateBatch,
        icon: const Icon(Icons.add),
        label: const Text('Create Batch'),
      );
    }
    return null;
  }

  // Event handlers
  Future<void> _handleRefresh() async {
    debugPrint('🚛 [ENHANCED-MULTI-ORDER] Refreshing batch data');

    final driverIdAsync = ref.read(currentDriverIdProvider);
    driverIdAsync.when(
      data: (driverId) {
        if (driverId != null) {
          ref.read(multiOrderBatchProvider.notifier).loadActiveBatch(driverId);
        }
      },
      loading: () {},
      error: (error, stack) {},
    );
  }

  void _showBatchSettings() {
    debugPrint('🚛 [ENHANCED-MULTI-ORDER] Showing batch settings');
    // TODO: Implement batch settings dialog
  }

  void _handleRouteAdjustment() {
    debugPrint('🚛 [ENHANCED-MULTI-ORDER] Handling route adjustment');
    // TODO: Implement route adjustment logic
  }

  void _handleAddOrder() {
    debugPrint('🚛 [ENHANCED-MULTI-ORDER] Adding order to batch');
    // TODO: Implement add order logic
  }

  void _handleRemoveOrder(String orderId) {
    debugPrint('🚛 [ENHANCED-MULTI-ORDER] Removing order from batch: $orderId');
    // TODO: Implement remove order logic
  }

  void _handleReorderBatch() {
    debugPrint('🚛 [ENHANCED-MULTI-ORDER] Reordering batch');
    // TODO: Implement batch reorder logic
  }

  void _handleCalculateRouteAdjustment() {
    debugPrint('🚛 [ENHANCED-MULTI-ORDER] Calculating route adjustment');
    // TODO: Implement route adjustment calculation
  }

  void _handleApplyRouteAdjustment() {
    debugPrint('🚛 [ENHANCED-MULTI-ORDER] Applying route adjustment');
    // TODO: Implement route adjustment application
  }

  void _handleOptimizeRoute() {
    debugPrint('🚛 [ENHANCED-MULTI-ORDER] Optimizing route');
    // TODO: Implement route optimization
  }

  void _handleStartNavigation() {
    debugPrint('🚛 [ENHANCED-MULTI-ORDER] Starting navigation');
    // TODO: Implement navigation start
  }

  void _handleOrderAction(String action, String orderId) {
    debugPrint('🚛 [ENHANCED-MULTI-ORDER] Order action: $action for order: $orderId');
    // TODO: Implement order actions
  }

  void _handleCreateBatch() {
    debugPrint('🚛 [ENHANCED-MULTI-ORDER] Creating new batch');
    // TODO: Implement batch creation
  }
}
