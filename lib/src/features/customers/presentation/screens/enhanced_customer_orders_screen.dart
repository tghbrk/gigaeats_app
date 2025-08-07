import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/enhanced_customer_order_history_providers.dart';
import '../providers/customer_order_filter_providers.dart';
import '../widgets/date_filter/customer_date_filter_components.dart';
import '../widgets/order_history/customer_order_history_widgets.dart';
import '../../data/models/customer_order_history_models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Enhanced customer orders screen with daily grouping and advanced filtering
class EnhancedCustomerOrdersScreen extends ConsumerStatefulWidget {
  const EnhancedCustomerOrdersScreen({super.key});

  @override
  ConsumerState<EnhancedCustomerOrdersScreen> createState() => _EnhancedCustomerOrdersScreenState();
}

class _EnhancedCustomerOrdersScreenState extends ConsumerState<EnhancedCustomerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();
    
    // Initialize lazy loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLazyLoading();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeLazyLoading() {
    final currentFilter = ref.read(currentCustomerOrderFilterProvider);
    ref.read(customerOrderHistoryLazyProvider(currentFilter).notifier).loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    
    // Check authentication
    if (authState.user == null) {
      return _buildUnauthenticatedState(theme);
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(theme),
      body: Column(
        children: [
          // Filter bar
          _buildFilterBar(),
          
          // Tab bar
          _buildTabBar(theme),
          
          // Tab content
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: const Text('Order History'),
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      actions: [
        // Filter summary button
        Consumer(
          builder: (context, ref, child) {
            final hasActiveFilters = ref.watch(hasActiveCustomerOrderFiltersProvider);
            
            return IconButton(
              onPressed: () => _showFilterDialog(),
              icon: Badge(
                isLabelVisible: hasActiveFilters,
                child: const Icon(Icons.tune),
              ),
              tooltip: 'Filter orders',
            );
          },
        ),
        
        // Refresh button
        IconButton(
          onPressed: _refreshOrders,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh orders',
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return CustomerCompactDateFilterBar(
      showOrderCount: true,
      showSpendingTotal: true,
      onFilterChanged: _onFilterChanged,
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(
            icon: Icon(Icons.all_inclusive),
            text: 'All Orders',
          ),
          Tab(
            icon: Icon(Icons.check_circle),
            text: 'Completed',
          ),
          Tab(
            icon: Icon(Icons.cancel),
            text: 'Cancelled',
          ),
        ],
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        indicatorColor: theme.colorScheme.primary,
        indicatorWeight: 3,
        labelStyle: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: theme.textTheme.titleSmall,
        onTap: _onTabChanged,
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        // All orders
        _buildOrderHistoryView(CustomerOrderFilterStatus.all),
        
        // Completed orders
        _buildOrderHistoryView(CustomerOrderFilterStatus.completed),
        
        // Cancelled orders
        _buildOrderHistoryView(CustomerOrderFilterStatus.cancelled),
      ],
    );
  }

  Widget _buildOrderHistoryView(CustomerOrderFilterStatus statusFilter) {
    return Consumer(
      builder: (context, ref, child) {
        // Get current filter and apply status filter
        final currentFilter = ref.watch(currentCustomerOrderFilterProvider);
        final filteredFilter = currentFilter.copyWith(statusFilter: statusFilter);
        
        // Watch the lazy loading state
        final lazyState = ref.watch(customerOrderHistoryLazyProvider(filteredFilter));
        
        debugPrint('🛒 Enhanced Orders Screen: Building view for status: ${statusFilter.displayName}');
        debugPrint('🛒 Enhanced Orders Screen: Lazy state - ${lazyState.items.length} groups, loading: ${lazyState.isLoading}');
        
        if (lazyState.items.isEmpty && lazyState.isLoading) {
          return _buildLoadingState();
        }
        
        if (lazyState.items.isEmpty && !lazyState.isLoading) {
          return _buildEmptyState(statusFilter);
        }
        
        if (lazyState.error != null) {
          return _buildErrorState(lazyState.error!);
        }
        
        return CustomerOrderHistoryListView(
          groupedHistory: lazyState.items,
          statusFilter: statusFilter,
          isLoading: lazyState.isLoading,
          hasMore: lazyState.hasMore,
          onLoadMore: () => _loadMoreOrders(filteredFilter),
          onRefresh: () => _refreshOrdersForStatus(statusFilter),
          scrollController: _scrollController,
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading your orders...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState(CustomerOrderFilterStatus statusFilter) {
    final theme = Theme.of(context);
    
    String title;
    String subtitle;
    IconData icon;
    
    switch (statusFilter) {
      case CustomerOrderFilterStatus.all:
        title = 'No orders found';
        subtitle = 'You haven\'t placed any orders yet. Start exploring restaurants!';
        icon = Icons.shopping_bag_outlined;
        break;
      case CustomerOrderFilterStatus.completed:
        title = 'No completed orders';
        subtitle = 'You don\'t have any completed orders in the selected time period.';
        icon = Icons.check_circle_outline;
        break;
      case CustomerOrderFilterStatus.cancelled:
        title = 'No cancelled orders';
        subtitle = 'You don\'t have any cancelled orders in the selected time period.';
        icon = Icons.cancel_outlined;
        break;
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (statusFilter == CustomerOrderFilterStatus.all)
              FilledButton.icon(
                onPressed: () => context.go('/customer/restaurants'),
                icon: const Icon(Icons.restaurant),
                label: const Text('Browse Restaurants'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading orders',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _refreshOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnauthenticatedState(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.login,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Please log in',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You need to be logged in to view your order history.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/auth/login'),
                icon: const Icon(Icons.login),
                label: const Text('Log In'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showCustomerDateFilterDialog(
      context,
      onFilterApplied: _onFilterChanged,
    );
  }

  void _onFilterChanged() {
    debugPrint('🛒 Enhanced Orders Screen: Filter changed, refreshing data');
    _refreshOrders();
  }

  void _onTabChanged(int index) {
    debugPrint('🛒 Enhanced Orders Screen: Tab changed to index: $index');
    // Tab content will automatically update based on the TabBarView
  }

  Future<void> _refreshOrders() async {
    debugPrint('🛒 Enhanced Orders Screen: Refreshing all orders');
    final currentFilter = ref.read(currentCustomerOrderFilterProvider);
    await ref.read(customerOrderHistoryLazyProvider(currentFilter).notifier).refresh();
  }

  Future<void> _refreshOrdersForStatus(CustomerOrderFilterStatus statusFilter) async {
    debugPrint('🛒 Enhanced Orders Screen: Refreshing orders for status: ${statusFilter.displayName}');
    final currentFilter = ref.read(currentCustomerOrderFilterProvider);
    final filteredFilter = currentFilter.copyWith(statusFilter: statusFilter);
    await ref.read(customerOrderHistoryLazyProvider(filteredFilter).notifier).refresh();
  }

  Future<void> _loadMoreOrders(CustomerDateRangeFilter filter) async {
    debugPrint('🛒 Enhanced Orders Screen: Loading more orders');
    await ref.read(customerOrderHistoryLazyProvider(filter).notifier).loadMore();
  }
}
