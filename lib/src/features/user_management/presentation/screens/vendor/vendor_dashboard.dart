import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../presentation/providers/repository_providers.dart' show
    vendorDashboardMetricsProvider,
    vendorTotalOrdersProvider,
    vendorRatingMetricsProvider,
    vendorNotificationsProvider,
    currentVendorProvider;
import '../../../../../design_system/design_system.dart';
import '../../../../../data/models/user_role.dart';
import '../../../../../shared/widgets/quick_action_button.dart';
import '../../../orders/presentation/screens/vendor/vendor_orders_screen.dart';
import '../../../menu/presentation/screens/vendor/vendor_menu_screen.dart';
import 'vendor_analytics_screen.dart';
import 'vendor_profile_screen.dart';

class VendorDashboard extends ConsumerStatefulWidget {
  const VendorDashboard({super.key});

  @override
  ConsumerState<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends ConsumerState<VendorDashboard> {
  int _selectedIndex = 0;
  
  // Use GE navigation configuration for vendor role
  final _navigationConfig = GERoleNavigationConfig.vendor;

  @override
  Widget build(BuildContext context) {
    return GEScreen(
      body: _buildCurrentTab(),
      bottomNavigationBar: GEBottomNavigation.navigationBar(
        destinations: _navigationConfig.destinations,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        userRole: UserRole.vendor,
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_selectedIndex) {
      case 0:
        return _VendorDashboardTab(onNavigateToTab: (index) {
          setState(() {
            _selectedIndex = index;
          });
        });
      case 1:
        return const VendorOrdersScreen();
      case 2:
        return const VendorMenuScreen();
      case 3:
        return const VendorAnalyticsScreen();
      case 4:
        return const VendorProfileScreen();
      default:
        return _VendorDashboardTab(onNavigateToTab: (index) {
          setState(() {
            _selectedIndex = index;
          });
        });
    }
  }
}

class _VendorDashboardTab extends ConsumerWidget {
  final Function(int)? onNavigateToTab;

  const _VendorDashboardTab({this.onNavigateToTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get notification count for app bar
    final notificationsAsync = ref.watch(vendorNotificationsProvider(true)); // unread only
    final notificationCount = notificationsAsync.maybeWhen(
      data: (notifications) => notifications.length,
      orElse: () => null,
    );
    
    return GEScreen.scrollable(
      appBar: GEAppBar.withRole(
        title: 'Vendor Dashboard',
        userRole: UserRole.vendor,
        backgroundColor: Colors.green,
        onNotificationTap: () => _showNotificationsBottomSheet(context, ref),
        notificationCount: notificationCount,
        onProfileTap: () => onNavigateToTab?.call(4), // Navigate to profile tab
        actions: [
          IconButton(
            icon: const Icon(Icons.developer_mode),
            onPressed: () {
              context.push('/test-consolidated');
            },
            tooltip: 'Vendor Developer Tools',
          ),
        ],
      ),
      onRefresh: () async {
        // Refresh all dashboard data
        ref.invalidate(vendorDashboardMetricsProvider);
        ref.invalidate(vendorTotalOrdersProvider);
        ref.invalidate(vendorRatingMetricsProvider);
        ref.invalidate(vendorNotificationsProvider);
        await Future.delayed(const Duration(milliseconds: 500));
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          _buildWelcomeHeader(ref),

          // Today's Metrics Section
          GESection(
            title: 'Today\'s Performance',
            subtitle: 'Key metrics for today',
            child: _buildTodayMetrics(ref),
          ),

          // Weekly Performance Section
          GESection(
            title: 'Weekly Performance',
            subtitle: 'Last 7 days overview',
            child: _buildWeeklyPerformance(ref),
          ),

          // Overall Statistics Section
          GESection(
            title: 'Overall Statistics',
            subtitle: 'All-time performance data',
            child: _buildOverallStats(ref),
          ),

          // Quick Actions Section
          GESection(
            title: 'Quick Actions',
            subtitle: 'Common vendor tasks',
            child: _buildQuickActions(),
          ),
        ],
      ),
    );
  }

  /// Build welcome header with vendor information
  Widget _buildWelcomeHeader(WidgetRef ref) {
    final vendorAsync = ref.watch(currentVendorProvider);

    return vendorAsync.when(
      data: (vendor) {
        if (vendor == null) return const SizedBox.shrink();

        final now = DateTime.now();
        final greeting = _getTimeBasedGreeting(now);

        return Builder(
          builder: (context) => Container(
            padding: const EdgeInsets.all(GESpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: GETypography.semiBold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: GESpacing.xs),
                Text(
                  'Welcome back to ${vendor.businessName}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: GESpacing.sm),
                Text(
                  _getFormattedDate(now),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  /// Build today's metrics section with GE components
  Widget _buildTodayMetrics(WidgetRef ref) {
    final metricsAsync = ref.watch(vendorDashboardMetricsProvider);

    return metricsAsync.when(
      data: (metrics) {
        final todayRevenue = metrics['today_revenue'] ?? 0.0;
        final activeOrders = (metrics['pending_orders'] ?? 0) +
                           (metrics['confirmed_orders'] ?? 0) +
                           (metrics['preparing_orders'] ?? 0) +
                           (metrics['ready_orders'] ?? 0) +
                           (metrics['out_for_delivery_orders'] ?? 0);
        final yesterdayRevenue = metrics['yesterday_revenue'] ?? 0.0;
        final todayOrders = metrics['today_orders'] ?? 0;

        // Calculate trend for revenue
        final revenueTrend = _calculateTrend(todayRevenue, yesterdayRevenue);
        final isPositiveTrend = revenueTrend.startsWith('+');

        return Row(
          children: [
            Expanded(
              child: GEDashboardCard(
                title: 'Today\'s Revenue',
                value: 'RM ${todayRevenue.toStringAsFixed(2)}',
                subtitle: '$todayOrders orders today',
                icon: Icons.trending_up,
                trend: revenueTrend,
                isPositiveTrend: isPositiveTrend,
                iconColor: isPositiveTrend ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: GESpacing.md),
            Expanded(
              child: GEDashboardCard(
                title: 'Active Orders',
                value: '$activeOrders',
                subtitle: activeOrders > 0 ? 'Orders in progress' : 'No active orders',
                icon: Icons.receipt_long,
                iconColor: activeOrders > 0 ? Colors.blue : Colors.grey,
                onTap: () => onNavigateToTab?.call(1), // Navigate to orders tab
              ),
            ),
          ],
        );
      },
      loading: () => const Row(
        children: [
          Expanded(
            child: GEDashboardCard(
              title: 'Today\'s Revenue',
              value: 'RM 0.00',
              subtitle: 'Loading...',
              icon: Icons.trending_up,
              isLoading: true,
            ),
          ),
          SizedBox(width: GESpacing.md),
          Expanded(
            child: GEDashboardCard(
              title: 'Active Orders',
              value: '0',
              subtitle: 'Loading...',
              icon: Icons.receipt_long,
              isLoading: true,
            ),
          ),
        ],
      ),
      error: (_, _) => const Row(
        children: [
          Expanded(
            child: GEDashboardCard(
              title: 'Today\'s Revenue',
              value: 'RM 0.00',
              subtitle: 'Error loading data',
              icon: Icons.trending_up,
            ),
          ),
          SizedBox(width: GESpacing.md),
          Expanded(
            child: GEDashboardCard(
              title: 'Active Orders',
              value: '0',
              subtitle: 'Error loading data',
              icon: Icons.receipt_long,
            ),
          ),
        ],
      ),
    );
  }

  /// Build weekly performance section with GE components
  Widget _buildWeeklyPerformance(WidgetRef ref) {
    final metricsAsync = ref.watch(vendorDashboardMetricsProvider);

    return metricsAsync.when(
      data: (metrics) {
        final weeklyRevenue = metrics['weekly_revenue'] ?? 0.0;
        final weeklyOrders = metrics['weekly_orders'] ?? 0;
        final avgOrderValue = weeklyOrders > 0 ? weeklyRevenue / weeklyOrders : 0.0;

        return Row(
          children: [
            Expanded(
              child: GEDashboardCard(
                title: 'Weekly Revenue',
                value: 'RM ${weeklyRevenue.toStringAsFixed(2)}',
                subtitle: '$weeklyOrders orders this week',
                icon: Icons.calendar_today,
                iconColor: Colors.blue,
              ),
            ),
            const SizedBox(width: GESpacing.md),
            Expanded(
              child: GEDashboardCard(
                title: 'Avg Order Value',
                value: 'RM ${avgOrderValue.toStringAsFixed(2)}',
                subtitle: 'Per order average',
                icon: Icons.receipt,
                iconColor: Colors.purple,
              ),
            ),
          ],
        );
      },
      loading: () => const Row(
        children: [
          Expanded(
            child: GEDashboardCard(
              title: 'Weekly Revenue',
              value: 'RM 0.00',
              subtitle: 'Loading...',
              icon: Icons.calendar_today,
              isLoading: true,
            ),
          ),
          SizedBox(width: GESpacing.md),
          Expanded(
            child: GEDashboardCard(
              title: 'Avg Order Value',
              value: 'RM 0.00',
              subtitle: 'Loading...',
              icon: Icons.receipt,
              isLoading: true,
            ),
          ),
        ],
      ),
      error: (_, _) => const Row(
        children: [
          Expanded(
            child: GEDashboardCard(
              title: 'Weekly Revenue',
              value: 'RM 0.00',
              subtitle: 'Error loading data',
              icon: Icons.calendar_today,
            ),
          ),
          SizedBox(width: GESpacing.md),
          Expanded(
            child: GEDashboardCard(
              title: 'Avg Order Value',
              value: 'RM 0.00',
              subtitle: 'Error loading data',
              icon: Icons.receipt,
            ),
          ),
        ],
      ),
    );
  }

  /// Build overall statistics section with GE components
  Widget _buildOverallStats(WidgetRef ref) {
    final totalOrdersAsync = ref.watch(vendorTotalOrdersProvider);
    final ratingMetricsAsync = ref.watch(vendorRatingMetricsProvider);

    return Row(
      children: [
        // Total Orders Card
        Expanded(
          child: totalOrdersAsync.when(
            data: (totalOrders) => GEDashboardCard(
              title: 'Total Orders',
              value: '$totalOrders',
              subtitle: 'All time',
              icon: Icons.receipt_long,
              iconColor: Colors.blue,
            ),
            loading: () => const GEDashboardCard(
              title: 'Total Orders',
              value: '0',
              subtitle: 'Loading...',
              icon: Icons.receipt_long,
              isLoading: true,
            ),
            error: (_, _) => const GEDashboardCard(
              title: 'Total Orders',
              value: '0',
              subtitle: 'Error loading data',
              icon: Icons.receipt_long,
            ),
          ),
        ),

        const SizedBox(width: GESpacing.md),

        // Rating Card
        Expanded(
          child: ratingMetricsAsync.when(
            data: (metrics) {
              final rating = metrics['rating'] ?? 0.0;
              final totalReviews = metrics['total_reviews'] ?? 0;
              final completionRate = metrics['completion_rate'] ?? 0.0;
              final ratingColor = _getRatingColor(rating);

              return GEDashboardCard(
                title: 'Customer Rating',
                value: rating > 0 ? '${rating.toStringAsFixed(1)} ⭐' : 'No rating',
                subtitle: totalReviews > 0
                    ? '$totalReviews reviews • ${completionRate.toStringAsFixed(1)}% completion'
                    : 'No reviews yet',
                icon: Icons.star,
                iconColor: ratingColor,
              );
            },
            loading: () => const GEDashboardCard(
              title: 'Customer Rating',
              value: '0.0',
              subtitle: 'Loading...',
              icon: Icons.star,
              isLoading: true,
            ),
            error: (_, _) => const GEDashboardCard(
              title: 'Customer Rating',
              value: 'N/A',
              subtitle: 'Error loading data',
              icon: Icons.star,
            ),
          ),
        ),
      ],
    );
  }

  /// Build quick actions section
  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: QuickActionButton(
            icon: Icons.add_circle,
            label: 'Add Menu Item',
            color: Colors.green,
            onTap: () => onNavigateToTab?.call(2), // Navigate to menu tab
          ),
        ),
        const SizedBox(width: GESpacing.sm),
        Expanded(
          child: QuickActionButton(
            icon: Icons.inventory,
            label: 'Update Stock',
            color: Colors.orange,
            onTap: () => onNavigateToTab?.call(2), // Navigate to menu tab
          ),
        ),
        const SizedBox(width: GESpacing.sm),
        Expanded(
          child: QuickActionButton(
            icon: Icons.analytics,
            label: 'View Reports',
            color: Colors.purple,
            onTap: () => onNavigateToTab?.call(3), // Navigate to analytics tab
          ),
        ),
      ],
    );
  }

  /// Show notifications bottom sheet
  void _showNotificationsBottomSheet(BuildContext context, WidgetRef ref) {
    // TODO: Implement notifications bottom sheet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications feature coming soon!')),
    );
  }

  /// Calculate trend percentage between current and previous values
  String _calculateTrend(double current, double previous) {
    if (previous == 0) {
      return current > 0 ? '+100%' : '0%';
    }

    final percentage = ((current - previous) / previous * 100);
    final sign = percentage >= 0 ? '+' : '';
    return '$sign${percentage.toStringAsFixed(1)}%';
  }

  /// Get color based on rating value
  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 4.0) return Colors.lightGreen;
    if (rating >= 3.5) return Colors.orange;
    if (rating >= 3.0) return Colors.deepOrange;
    return Colors.red;
  }

  /// Get time-based greeting
  String _getTimeBasedGreeting(DateTime now) {
    final hour = now.hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  /// Get formatted date string
  String _getFormattedDate(DateTime date) {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
                   'July', 'August', 'September', 'October', 'November', 'December'];

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];

    return '$weekday, $month ${date.day}, ${date.year}';
  }
}
