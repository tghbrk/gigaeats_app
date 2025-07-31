import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/enhanced_history_orders_tab.dart';
import '../widgets/date_filter/date_filter_components.dart';
import '../widgets/order_history_statistics.dart';

/// Enhanced driver orders screen with improved history functionality
class EnhancedDriverOrdersScreen extends ConsumerStatefulWidget {
  const EnhancedDriverOrdersScreen({super.key});

  @override
  ConsumerState<EnhancedDriverOrdersScreen> createState() => _EnhancedDriverOrdersScreenState();
}

class _EnhancedDriverOrdersScreenState extends ConsumerState<EnhancedDriverOrdersScreen>
    with TickerProviderStateMixin, DateFilterMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {
      _currentTabIndex = _tabController.index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          // Filter button (only show on history and statistics tabs)
          if (_currentTabIndex >= 2)
            IconButton(
              icon: Icon(
                hasActiveFilter() ? Icons.filter_alt : Icons.filter_list,
                color: hasActiveFilter() ? theme.colorScheme.primary : null,
              ),
              onPressed: () => showFilterOptions(context),
              tooltip: 'Filter orders',
            ),
          
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshCurrentTab(),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.local_shipping),
              text: 'Available',
            ),
            Tab(
              icon: Icon(Icons.assignment),
              text: 'Active',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'History',
            ),
            Tab(
              icon: Icon(Icons.analytics),
              text: 'Statistics',
            ),
          ],
          isScrollable: false,
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: theme.textTheme.labelMedium,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Available Orders Tab
          _buildAvailableOrdersTab(),
          
          // Active Orders Tab
          _buildActiveOrdersTab(),
          
          // Enhanced History Tab
          const EnhancedHistoryOrdersTab(),
          
          // Statistics Tab
          _buildStatisticsTab(),
        ],
      ),
    );
  }

  Widget _buildAvailableOrdersTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Available Orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Available orders will appear here when vendors mark them as ready for pickup.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrdersTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Active Orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your currently assigned orders will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Filter summary at top
          if (hasActiveFilter())
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_alt,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Showing statistics for: ${getCurrentFilterDescription()}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => resetFilters(),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          
          // Statistics widget
          const OrderHistoryStatistics(
            showDetailedStats: true,
          ),
          
          const SizedBox(height: 16),
          
          // Additional insights card
          _buildInsightsCard(),
          
          const SizedBox(height: 80), // Bottom padding for FAB
        ],
      ),
    );
  }

  Widget _buildInsightsCard() {
    final theme = Theme.of(context);
    final combinedFilter = ref.watch(combinedDateFilterProvider);
    final summaryAsync = ref.watch(orderHistorySummaryProvider(combinedFilter));
    
    return summaryAsync.when(
      data: (summary) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Insights',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Performance insights
                if (summary.deliverySuccessRate >= 0.95)
                  _buildInsightItem(
                    theme,
                    Icons.star,
                    'Excellent Performance!',
                    'You have a ${(summary.deliverySuccessRate * 100).toStringAsFixed(1)}% success rate. Keep up the great work!',
                    Colors.green,
                  )
                else if (summary.deliverySuccessRate >= 0.85)
                  _buildInsightItem(
                    theme,
                    Icons.trending_up,
                    'Good Performance',
                    'Your success rate is ${(summary.deliverySuccessRate * 100).toStringAsFixed(1)}%. Consider focusing on timely deliveries to improve further.',
                    Colors.orange,
                  )
                else
                  _buildInsightItem(
                    theme,
                    Icons.warning,
                    'Room for Improvement',
                    'Your success rate is ${(summary.deliverySuccessRate * 100).toStringAsFixed(1)}%. Focus on completing more deliveries successfully.',
                    theme.colorScheme.error,
                  ),
                
                const SizedBox(height: 12),
                
                // Earnings insights
                if (summary.averageEarningsPerOrder > 15)
                  _buildInsightItem(
                    theme,
                    Icons.payments,
                    'High Value Orders',
                    'Your average earnings per order is RM ${summary.averageEarningsPerOrder.toStringAsFixed(2)}. You\'re handling valuable deliveries!',
                    Colors.green,
                  )
                else
                  _buildInsightItem(
                    theme,
                    Icons.info,
                    'Earnings Opportunity',
                    'Average earnings: RM ${summary.averageEarningsPerOrder.toStringAsFixed(2)} per order. Consider taking on more premium deliveries.',
                    theme.colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildInsightItem(
    ThemeData theme,
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _refreshCurrentTab() {
    debugPrint('🚗 EnhancedDriverOrdersScreen: Refreshing tab $_currentTabIndex');
    
    switch (_currentTabIndex) {
      case 0:
        // Refresh available orders
        // TODO: Implement when available orders provider is ready
        break;
      case 1:
        // Refresh active orders
        // TODO: Implement when active orders provider is ready
        break;
      case 2:
        // Refresh history
        final combinedFilter = ref.read(combinedDateFilterProvider);
        ref.invalidate(groupedOrderHistoryProvider(combinedFilter));
        ref.invalidate(orderCountByDateProvider(combinedFilter));
        break;
      case 3:
        // Refresh statistics
        final combinedFilter = ref.read(combinedDateFilterProvider);
        ref.invalidate(orderHistorySummaryProvider(combinedFilter));
        break;
    }
  }
}
