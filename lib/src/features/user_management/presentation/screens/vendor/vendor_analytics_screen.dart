import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: Restore when loading_widget is used
// import '../../../../shared/widgets/loading_widget.dart';
import '../../../../../presentation/providers/repository_providers.dart' show vendorDashboardMetricsProvider;

class VendorAnalyticsScreen extends ConsumerStatefulWidget {
  final ValueChanged<int>? onNavigateToTab;

  const VendorAnalyticsScreen({super.key, this.onNavigateToTab});

  @override
  ConsumerState<VendorAnalyticsScreen> createState() => _VendorAnalyticsScreenState();
}

class _VendorAnalyticsScreenState extends ConsumerState<VendorAnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Month';
  final bool _isLoading = false;
  Map<String, DateTime?>? _cachedDateRange;
  String? _cachedPeriod;

  final List<String> _periods = [
    'Today',
    'This Week',
    'This Month',
    'Last Month',
    'This Year',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }



  Map<String, DateTime?> _getDateRangeForPeriod(String period) {
    // Use cached date range if the period hasn't changed
    if (_cachedPeriod == period && _cachedDateRange != null) {
      return _cachedDateRange!;
    }

    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate = now;

    switch (period) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'This Week':
        final weekday = now.weekday;
        startDate = now.subtract(Duration(days: weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Last Month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        startDate = lastMonth;
        endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    final dateRange = {'startDate': startDate, 'endDate': endDate};

    // Cache the result
    _cachedPeriod = period;
    _cachedDateRange = dateRange;

    debugPrint('🔍 [ANALYTICS-FILTER] Period: $period, Start: ${startDate.toIso8601String()}, End: ${endDate.toIso8601String()}');

    return dateRange;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedPeriod,
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
                // Clear cache when period changes
                _cachedPeriod = null;
                _cachedDateRange = null;
              });
            },
            itemBuilder: (context) => _periods.map((period) {
              return PopupMenuItem(
                value: period,
                child: Text(period),
              );
            }).toList(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedPeriod,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Sales', icon: Icon(Icons.trending_up)),
            Tab(text: 'Products', icon: Icon(Icons.restaurant_menu)),
          ],
        ),
      ),
      body: _isLoading
          // TODO: Restore when LoadingWidget is implemented
          // ? const LoadingWidget(message: 'Loading analytics...')
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildSalesTab(),
                _buildProductsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Metrics
          Text(
            'Key Metrics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Metrics Grid
          Consumer(
            builder: (context, ref, child) {
              debugPrint('📊 [VENDOR-ANALYTICS] Building overview metrics...');
              // Use existing vendor dashboard metrics provider for now
              final metricsAsync = ref.watch(vendorDashboardMetricsProvider);

              return metricsAsync.when(
                data: (metrics) {
                  final totalRevenue = metrics['total_revenue'] ?? 0.0;
                  final totalOrders = metrics['total_orders'] ?? 0;
                  final avgOrderValue = metrics['avg_order_value'] ?? 0.0;
                  final rating = metrics['rating'] ?? 0.0;

                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildMetricCard(
                        title: 'Total Revenue',
                        value: 'RM ${totalRevenue.toStringAsFixed(2)}',
                        change: _selectedPeriod,
                        isPositive: true,
                        icon: Icons.attach_money,
                        color: Colors.green,
                      ),
                      _buildMetricCard(
                        title: 'Total Orders',
                        value: '$totalOrders',
                        change: _selectedPeriod,
                        isPositive: true,
                        icon: Icons.receipt_long,
                        color: Colors.blue,
                      ),
                      _buildMetricCard(
                        title: 'Avg Order Value',
                        value: 'RM ${avgOrderValue.toStringAsFixed(2)}',
                        change: _selectedPeriod,
                        isPositive: true,
                        icon: Icons.trending_up,
                        color: Colors.orange,
                      ),
                      _buildMetricCard(
                        title: 'Customer Rating',
                        value: rating.toStringAsFixed(1),
                        change: '${metrics['total_reviews'] ?? 0} reviews',
                        isPositive: true,
                        icon: Icons.star,
                        color: Colors.amber,
                      ),
                    ],
                  );
                },
                loading: () => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildMetricCard(
                      title: 'Today Revenue',
                      value: '...',
                      change: 'Loading...',
                      isPositive: true,
                      icon: Icons.attach_money,
                      color: Colors.green,
                    ),
                    _buildMetricCard(
                      title: 'Today Orders',
                      value: '...',
                      change: 'Loading...',
                      isPositive: true,
                      icon: Icons.receipt_long,
                      color: Colors.blue,
                    ),
                    _buildMetricCard(
                      title: 'Avg Order Value',
                      value: '...',
                      change: 'Loading...',
                      isPositive: true,
                      icon: Icons.trending_up,
                      color: Colors.orange,
                    ),
                    _buildMetricCard(
                      title: 'Customer Rating',
                      value: '...',
                      change: 'Loading...',
                      isPositive: true,
                      icon: Icons.star,
                      color: Colors.amber,
                    ),
                  ],
                ),
                error: (error, _) => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildMetricCard(
                      title: 'Today Revenue',
                      value: 'RM 0.00',
                      change: 'Error',
                      isPositive: false,
                      icon: Icons.attach_money,
                      color: Colors.green,
                    ),
                    _buildMetricCard(
                      title: 'Today Orders',
                      value: '0',
                      change: 'Error',
                      isPositive: false,
                      icon: Icons.receipt_long,
                      color: Colors.blue,
                    ),
                    _buildMetricCard(
                      title: 'Avg Order Value',
                      value: 'RM 0.00',
                      change: 'Error',
                      isPositive: false,
                      icon: Icons.trending_up,
                      color: Colors.orange,
                    ),
                    _buildMetricCard(
                      title: 'Customer Rating',
                      value: '0.0',
                      change: 'Error',
                      isPositive: false,
                      icon: Icons.star,
                      color: Colors.amber,
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Recent Performance
          Text(
            'Recent Performance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Consumer(
            builder: (context, ref, child) {
              // TODO: Restore unused variable - commented out for analyzer cleanup
              // final dateRange = _getDateRangeForPeriod(_selectedPeriod);
              // TODO: Restore undefined identifiers - commented out for analyzer cleanup
              // final metricsAsync = ref.watch(vendorFilteredMetricsProvider(dateRange));
              // final vendorAsync = ref.watch(currentVendorProvider);
              final metricsAsync = AsyncValue.data(<String, dynamic>{});
              final vendorAsync = AsyncValue.data(<String, dynamic>{});

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: metricsAsync.when(
                    data: (metrics) {
                      final totalOrders = metrics['total_orders'] ?? 0;
                      final totalRevenue = metrics['total_revenue'] ?? 0.0;
                      final pendingOrders = metrics['pending_orders'] ?? 0;

                      return Column(
                        children: [
                          _buildPerformanceRow('Orders ($_selectedPeriod)', '$totalOrders', Icons.today),
                          const Divider(),
                          _buildPerformanceRow('Revenue ($_selectedPeriod)', 'RM ${totalRevenue.toStringAsFixed(2)}', Icons.monetization_on),
                          const Divider(),
                          _buildPerformanceRow('Pending Orders', '$pendingOrders', Icons.pending_actions),
                          const Divider(),
                          vendorAsync.when(
                            // TODO: Restore undefined getter - commented out for analyzer cleanup
                            // data: (vendor) => _buildPerformanceRow('Total Orders', '${vendor?.totalOrders ?? 0}', Icons.restaurant_menu),
                            // TODO: Fix invalid null-aware operator - commented out for analyzer cleanup
                            // data: (vendor) => _buildPerformanceRow('Total Orders', '${vendor?['totalOrders'] ?? 0}', Icons.restaurant_menu),
                            data: (vendor) => _buildPerformanceRow('Total Orders', '${vendor['totalOrders'] ?? 0}', Icons.restaurant_menu),
                            loading: () => _buildPerformanceRow('Total Orders', '...', Icons.restaurant_menu),
                            error: (_, _) => _buildPerformanceRow('Total Orders', '0', Icons.restaurant_menu),
                          ),
                        ],
                      );
                    },
                    loading: () => Column(
                      children: [
                        _buildPerformanceRow('Orders Today', '...', Icons.today),
                        const Divider(),
                        _buildPerformanceRow('Revenue Today', '...', Icons.monetization_on),
                        const Divider(),
                        _buildPerformanceRow('Pending Orders', '...', Icons.pending_actions),
                        const Divider(),
                        _buildPerformanceRow('Total Orders', '...', Icons.restaurant_menu),
                      ],
                    ),
                    error: (error, _) => Column(
                      children: [
                        _buildPerformanceRow('Orders Today', '0', Icons.today),
                        const Divider(),
                        _buildPerformanceRow('Revenue Today', 'RM 0.00', Icons.monetization_on),
                        const Divider(),
                        _buildPerformanceRow('Pending Orders', '0', Icons.pending_actions),
                        const Divider(),
                        _buildPerformanceRow('Total Orders', '0', Icons.restaurant_menu),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'View Orders',
                  subtitle: 'Manage incoming orders',
                  icon: Icons.list_alt,
                  onTap: () {
                    // Navigate to orders tab (index 1)
                    widget.onNavigateToTab?.call(1);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  title: 'Update Menu',
                  subtitle: 'Add or edit menu items',
                  icon: Icons.edit,
                  onTap: () {
                    // Navigate to menu tab (index 2)
                    widget.onNavigateToTab?.call(2);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Additional Quick Actions Row
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'View Profile',
                  subtitle: 'Update restaurant info',
                  icon: Icons.store,
                  onTap: () {
                    // Navigate to profile tab (index 4)
                    widget.onNavigateToTab?.call(4);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  title: 'Export Data',
                  subtitle: 'Download reports',
                  icon: Icons.download,
                  onTap: () => _showExportOptions(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sales Summary
          Text(
            'Sales Summary',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Consumer(
            builder: (context, ref, child) {
              final dateRange = _getDateRangeForPeriod(_selectedPeriod);
              // TODO: Restore undefined method - commented out for analyzer cleanup
              // final salesSummaryAsync = ref.watch(vendorSalesSummaryProvider(dateRange));
              final salesSummaryAsync = AsyncValue.data(<String, dynamic>{});

              return salesSummaryAsync.when(
                data: (summary) {
                  final totalSales = summary['total_sales'] ?? 0.0;
                  final growthPercentage = summary['growth_percentage'] ?? 0.0;
                  final orderCount = summary['order_count'] ?? 0;
                  final isPositiveGrowth = growthPercentage >= 0;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Sales',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'RM ${totalSales.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    '$orderCount orders',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: (isPositiveGrowth ? Colors.green : Colors.red).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isPositiveGrowth ? Icons.trending_up : Icons.trending_down,
                                      size: 16,
                                      color: isPositiveGrowth ? Colors.green : Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${isPositiveGrowth ? '+' : ''}${growthPercentage.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color: isPositiveGrowth ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildRevenueTrendsChart(dateRange),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Sales',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  'Loading...',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '...',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                error: (error, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Sales',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  'RM 0.00',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'Error',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Error loading sales data',
                                  style: TextStyle(
                                    color: Colors.red[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Sales Breakdown
          Text(
            'Sales Breakdown',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildSalesBreakdownCards(),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Performing Products
          Text(
            'Top Performing Products',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildTopProductCards(),

          const SizedBox(height: 24),

          // Product Categories Performance
          Text(
            'Category Performance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildCategoryPerformanceCards(),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String change,
    required bool isPositive,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced padding from 16 to 12
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Use minimum space needed
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20), // Reduced icon size from 24 to 20
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), // Reduced padding
                  decoration: BoxDecoration(
                    color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6), // Reduced border radius
                  ),
                  child: Text(
                    change,
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontSize: 10, // Reduced font size from 12 to 10
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4), // Reduced spacing from 8 to 4
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith( // Changed from headlineSmall to titleMedium
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesBreakdownCards() {
    // TODO: Restore unused variable when implementing sales breakdown filtering
    // final dateRange = _getDateRangeForPeriod(_selectedPeriod);

    return Consumer(
      builder: (context, ref, child) {
        // TODO: Restore vendorSalesBreakdownProvider when provider is implemented - commented out for analyzer cleanup
        // final salesBreakdownAsync = ref.watch(vendorSalesBreakdownProvider(dateRange));
        final salesBreakdownAsync = AsyncValue.data(<Map<String, dynamic>>[]); // Placeholder

        return salesBreakdownAsync.when(
          data: (breakdownData) {
            if (breakdownData.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No sales data available',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'for $_selectedPeriod',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final colors = [Colors.blue, Colors.orange, Colors.green, Colors.purple, Colors.red];

            return Column(
              children: breakdownData.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                final color = colors[index % colors.length];

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['category'] ?? 'Unknown Category',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'RM ${(data['total_sales'] ?? 0.0).toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '${data['total_orders'] ?? 0} orders',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${(data['percentage'] ?? 0.0).toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error loading sales data',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.red[600],
                    ),
                  ),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopProductCards() {
    return Consumer(
      builder: (context, ref, child) {
        // TODO: Restore unused variable when implementing top products filtering
        // final dateRange = _getDateRangeForPeriod(_selectedPeriod);
        // TODO: Restore vendorTopProductsProvider when provider is implemented - commented out for analyzer cleanup
        // final topProductsAsync = ref.watch(vendorTopProductsProvider(VendorAnalyticsParams(
        //   startDate: dateRange['startDate'],
        //   endDate: dateRange['endDate'],
        //   limit: 10,
        // )));
        final topProductsAsync = AsyncValue.data(<Map<String, dynamic>>[]); // Placeholder

        return topProductsAsync.when(
          data: (topProducts) {
            if (topProducts.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.restaurant_menu_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No product data available',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'for $_selectedPeriod',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: topProducts.asMap().entries.map((entry) {
                final index = entry.key;
                final product = entry.value;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _getRankColor(index),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['product_name'] ?? 'Unknown Product',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${product['total_orders'] ?? 0} orders • ${product['total_quantity'] ?? 0} items',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (product['avg_rating'] != null && product['avg_rating'] > 0)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${(product['avg_rating'] ?? 0.0).toStringAsFixed(1)}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        Text(
                          'RM ${(product['total_sales'] ?? 0.0).toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error loading product data',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.red[600],
                    ),
                  ),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryPerformanceCards() {
    // TODO: Restore unused variable when implementing category performance filtering
    // final dateRange = _getDateRangeForPeriod(_selectedPeriod);

    return Consumer(
      builder: (context, ref, child) {
        // TODO: Restore vendorCategoryPerformanceProvider when provider is implemented - commented out for analyzer cleanup
        // final categoryPerformanceAsync = ref.watch(vendorCategoryPerformanceProvider(dateRange));
        final categoryPerformanceAsync = AsyncValue.data(<Map<String, dynamic>>[]); // Placeholder

        return categoryPerformanceAsync.when(
          data: (categories) {
            if (categories.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No category data available',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'for $_selectedPeriod',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: categories.map((category) {
                final growthPercentage = category['growth_percentage'] ?? 0.0;
                final isPositiveGrowth = growthPercentage >= 0;
                final growthColor = isPositiveGrowth ? Colors.green : Colors.red;
                final growthIcon = isPositiveGrowth ? Icons.trending_up : Icons.trending_down;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category['category'] ?? 'Unknown Category',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'RM ${(category['current_sales'] ?? 0.0).toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '${category['total_items'] ?? 0} items',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: growthColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                growthIcon,
                                size: 12,
                                color: growthColor,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${growthPercentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: growthColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error loading category data',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.red[600],
                    ),
                  ),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRevenueTrendsChart(Map<String, DateTime?> dateRange) {
    return Consumer(
      builder: (context, ref, child) {
        // TODO: Restore unused variables when implementing revenue trends filtering
        // Create stable parameters to prevent infinite rebuilds
        // final startDate = dateRange['startDate'];
        // final endDate = dateRange['endDate'];
        // final period = 'daily'; // Always use daily for consistency

        // TODO: Restore vendorRevenueTrendsProvider when provider is implemented - commented out for analyzer cleanup
        // final trendsAsync = ref.watch(vendorRevenueTrendsProvider(VendorRevenueTrendsParams(
        //   startDate: startDate,
        //   endDate: endDate,
        //   period: period,
        // )));
        final trendsAsync = AsyncValue.data(<Map<String, dynamic>>[]); // Placeholder

        return trendsAsync.when(
          data: (trends) {
            if (trends.isEmpty) {
              return Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.show_chart,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No revenue trends available',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'for $_selectedPeriod',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Simple bar chart representation
            final maxRevenue = trends.fold<double>(0.0, (max, trend) {
              final revenue = trend['revenue'] ?? 0.0;
              return revenue > max ? revenue : max;
            });

            return Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revenue Trends',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: trends.take(7).map((trend) {
                          final revenue = trend['revenue'] ?? 0.0;
                          final height = maxRevenue > 0 ? (revenue / maxRevenue * 120) : 0.0;
                          final date = DateTime.parse(trend['period_date']);

                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    height: height,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${date.day}/${date.month}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error loading trends',
                    style: TextStyle(
                      color: Colors.red[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey;
      case 2:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Data',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export Sales Report'),
              subtitle: Text('Export sales data for $_selectedPeriod'),
              onTap: () {
                Navigator.pop(context);
                _exportSalesReport();
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Export Order History'),
              subtitle: Text('Export order details for $_selectedPeriod'),
              onTap: () {
                Navigator.pop(context);
                _exportOrderHistory();
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Export Analytics Summary'),
              subtitle: Text('Export analytics overview for $_selectedPeriod'),
              onTap: () {
                Navigator.pop(context);
                _exportAnalyticsSummary();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportSalesReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting sales report for $_selectedPeriod...'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            // TODO: Open exported file
          },
        ),
      ),
    );
  }

  void _exportOrderHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting order history for $_selectedPeriod...'),
        backgroundColor: Colors.blue,
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            // TODO: Open exported file
          },
        ),
      ),
    );
  }

  void _exportAnalyticsSummary() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting analytics summary for $_selectedPeriod...'),
        backgroundColor: Colors.purple,
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            // TODO: Open exported file
          },
        ),
      ),
    );
  }
}
