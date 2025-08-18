import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../presentation/providers/repository_providers.dart';
import '../../../../../design_system/design_system.dart';
import '../../../../../data/models/user_role.dart';
import '../../../orders/presentation/screens/vendor/vendor_orders_screen.dart';
import '../../../menu/presentation/screens/vendor/vendor_menu_screen.dart';
import 'vendor_analytics_screen.dart';
import 'vendor_profile_screen.dart';
import 'widgets/vendor_dashboard_header.dart';
import 'widgets/vendor_greeting_card.dart';
import 'widgets/enhanced_dashboard_card.dart';
import 'widgets/dashboard_empty_state.dart';

/// Enhanced Vendor Dashboard
/// 
/// A redesigned vendor dashboard that matches the UI/UX mockup
/// while preserving all existing functionality and data integration.
class EnhancedVendorDashboard extends ConsumerStatefulWidget {
  const EnhancedVendorDashboard({super.key});

  @override
  ConsumerState<EnhancedVendorDashboard> createState() => _EnhancedVendorDashboardState();
}

class _EnhancedVendorDashboardState extends ConsumerState<EnhancedVendorDashboard> {
  int _selectedIndex = 0;
  
  // Use GE navigation configuration for vendor role
  final _navigationConfig = GERoleNavigationConfig.vendor;

  @override
  Widget build(BuildContext context) {
    debugPrint('🏪 [ENHANCED-VENDOR-DASHBOARD] Building dashboard with selectedIndex: $_selectedIndex');
    
    return GEScreen(
      backgroundColor: GEVendorColors.background,
      body: _buildCurrentTab(),
      bottomNavigationBar: GEBottomNavigation.navigationBar(
        destinations: _navigationConfig.destinations,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          debugPrint('🏪 [ENHANCED-VENDOR-DASHBOARD] Navigation selected: $index');
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
        return _EnhancedVendorDashboardTab(onNavigateToTab: (index) {
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
        return _EnhancedVendorDashboardTab(onNavigateToTab: (index) {
          setState(() {
            _selectedIndex = index;
          });
        });
    }
  }
}

/// Enhanced Vendor Dashboard Tab Content
class _EnhancedVendorDashboardTab extends ConsumerWidget {
  final Function(int)? onNavigateToTab;

  const _EnhancedVendorDashboardTab({this.onNavigateToTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('🏪 [ENHANCED-DASHBOARD-TAB] Building dashboard tab content');
    debugPrint('🏪 [ENHANCED-DASHBOARD-TAB] Screen size: ${MediaQuery.of(context).size}');
    debugPrint('🏪 [ENHANCED-DASHBOARD-TAB] Device pixel ratio: ${MediaQuery.of(context).devicePixelRatio}');

    final notificationsAsync = ref.watch(vendorNotificationsProvider(true));
    final notificationCount = notificationsAsync.when(
      data: (notifications) => notifications.length,
      loading: () => 0,
      error: (_, __) => 0,
    );
    
    return GEScreen.scrollable(
      appBar: VendorDashboardHeader(
        title: 'Vendor Dashboard',
        onNotificationTap: () => _showNotificationsBottomSheet(context, ref),
        notificationCount: notificationCount,
        onProfileTap: () => onNavigateToTab?.call(4), // Navigate to profile tab
        actions: [],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting Card
          VendorGreetingCard(
            onNavigateToTab: onNavigateToTab,
          ),

          // Today's Performance Section
          _buildSection(
            title: 'Today\'s Performance',
            subtitle: 'Key metrics for today',
            child: _buildTodayMetrics(ref),
          ),

          // Weekly Performance Section
          _buildSection(
            title: 'Weekly Performance',
            subtitle: 'Last 7 days overview',
            child: _buildWeeklyPerformance(ref),
          ),

          // Overall Statistics Section
          _buildSection(
            title: 'Overall Statistics',
            subtitle: 'All-time performance data',
            child: _buildOverallStats(ref),
          ),

          // Empty State (shown when no orders today)
          _buildEmptyStateIfNeeded(ref),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: GESpacing.screenPadding,
        vertical: GESpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: GEVendorColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: GEVendorColors.textSecondary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: GESpacing.md),
          
          // Section content
          child,
        ],
      ),
    );
  }

  Widget _buildTodayMetrics(WidgetRef ref) {
    final metricsAsync = ref.watch(vendorDashboardMetricsProvider);
    
    return metricsAsync.when(
      data: (metrics) {
        debugPrint('🏪 [ENHANCED-DASHBOARD] Today metrics loaded: $metrics');
        
        final todayRevenue = metrics['today_revenue'] ?? 0.0;
        final todayOrders = metrics['today_orders'] ?? 0;
        final activeOrders = metrics['pending_orders'] ?? 0;
        
        // Calculate trend (mock data for now)
        final revenueTrend = todayRevenue > 0 ? '+12%' : '0%';
        final isPositiveTrend = todayRevenue > 0;
        
        // Mock chart data for revenue
        final revenueChartData = [20.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
        
        return Row(
          children: [
            Expanded(
              child: EnhancedDashboardCard(
                title: 'Today\'s Revenue',
                value: 'RM ${todayRevenue.toStringAsFixed(2)}',
                subtitle: '$todayOrders orders today',
                icon: Icons.trending_up,
                metricType: 'revenue',
                trend: revenueTrend,
                isPositiveTrend: isPositiveTrend,
                trendValue: isPositiveTrend ? 12.0 : 0.0,
                chartData: revenueChartData,
                showChart: true,
                onTap: () => onNavigateToTab?.call(3), // Navigate to analytics
              ),
            ),
            const SizedBox(width: GESpacing.sm),
            Expanded(
              child: EnhancedDashboardCard(
                title: 'Active Orders',
                value: '$activeOrders',
                subtitle: activeOrders > 0 ? 'Orders in progress' : 'No active orders',
                icon: Icons.receipt_long,
                metricType: 'orders',
                progressValue: activeOrders > 0 ? (activeOrders / 10).clamp(0.0, 1.0) : 0.0,
                showProgress: true,
                onTap: () => onNavigateToTab?.call(1), // Navigate to orders tab
              ),
            ),
          ],
        );
      },
      loading: () => _buildLoadingMetrics(),
      error: (error, stack) {
        debugPrint('⚠️ [ENHANCED-DASHBOARD] Error loading today metrics: $error');
        return _buildErrorMetrics();
      },
    );
  }

  Widget _buildWeeklyPerformance(WidgetRef ref) {
    final metricsAsync = ref.watch(vendorDashboardMetricsProvider);
    
    return metricsAsync.when(
      data: (metrics) {
        final weeklyRevenue = metrics['weekly_revenue'] ?? 0.0;
        final weeklyOrders = metrics['weekly_orders'] ?? 0;
        final avgOrderValue = weeklyOrders > 0 ? weeklyRevenue / weeklyOrders : 0.0;
        
        // Mock chart data for weekly performance
        final weeklyChartData = [30.0, 10.0, 0.0, 0.0, 0.0, 0.0, 0.0];

        return Row(
          children: [
            Expanded(
              child: EnhancedDashboardCard(
                title: 'Weekly Revenue',
                value: 'RM ${weeklyRevenue.toStringAsFixed(2)}',
                subtitle: '$weeklyOrders orders this week',
                icon: Icons.calendar_today,
                metricType: 'orders',
                chartData: weeklyChartData,
                showChart: true,
              ),
            ),
            const SizedBox(width: GESpacing.sm),
            Expanded(
              child: EnhancedDashboardCard(
                title: 'Avg Order Value',
                value: 'RM ${avgOrderValue.toStringAsFixed(2)}',
                subtitle: 'Per order average',
                icon: Icons.attach_money,
                metricType: 'value',
                progressValue: avgOrderValue > 0 ? (avgOrderValue / 50).clamp(0.0, 1.0) : 0.0,
                showProgress: true,
              ),
            ),
          ],
        );
      },
      loading: () => _buildLoadingMetrics(),
      error: (_, __) => _buildErrorMetrics(),
    );
  }

  Widget _buildOverallStats(WidgetRef ref) {
    final totalOrdersAsync = ref.watch(vendorTotalOrdersProvider);
    final ratingMetricsAsync = ref.watch(vendorRatingMetricsProvider);

    return Row(
      children: [
        // Total Orders Card
        Expanded(
          child: totalOrdersAsync.when(
            data: (totalOrders) {
              // Mock chart data for total orders growth
              final ordersChartData = [60.0, 70.0, 80.0, 75.0, 85.0, 90.0, 84.0];
              
              return EnhancedDashboardCard(
                title: 'Total Orders',
                value: '$totalOrders',
                subtitle: 'All time',
                icon: Icons.receipt_long,
                metricType: 'orders',
                trend: '+5%',
                isPositiveTrend: true,
                trendValue: 5.0,
                chartData: ordersChartData,
                showChart: true,
              );
            },
            loading: () => const EnhancedDashboardCard(
              title: 'Total Orders',
              value: '0',
              subtitle: 'Loading...',
              icon: Icons.receipt_long,
              isLoading: true,
            ),
            error: (_, __) => const EnhancedDashboardCard(
              title: 'Total Orders',
              value: '0',
              subtitle: 'Error loading data',
              icon: Icons.receipt_long,
            ),
          ),
        ),

        const SizedBox(width: GESpacing.sm),

        // Rating Card
        Expanded(
          child: ratingMetricsAsync.when(
            data: (metrics) {
              final rating = metrics['rating'] ?? 0.0;
              final totalReviews = metrics['total_reviews'] ?? 0;
              final completionRate = metrics['completion_rate'] ?? 0.0;
              
              // Mock chart data for rating trend
              final ratingChartData = [3.8, 4.0, 4.1, 4.0, 4.2, 4.3, 4.2];

              return EnhancedDashboardCard(
                title: 'Customer Rating',
                value: rating > 0 ? '${rating.toStringAsFixed(1)}' : 'No rating',
                subtitle: totalReviews > 0
                    ? '$totalReviews reviews • ${completionRate.toStringAsFixed(1)}% completion'
                    : 'No reviews yet',
                icon: Icons.star,
                metricType: 'rating',
                trend: '+0.3',
                isPositiveTrend: true,
                trendValue: 0.3,
                chartData: ratingChartData,
                showChart: true,
              );
            },
            loading: () => const EnhancedDashboardCard(
              title: 'Customer Rating',
              value: '0.0',
              subtitle: 'Loading...',
              icon: Icons.star,
              isLoading: true,
            ),
            error: (_, __) => const EnhancedDashboardCard(
              title: 'Customer Rating',
              value: '0.0',
              subtitle: 'Error loading data',
              icon: Icons.star,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingMetrics() {
    return Row(
      children: [
        const Expanded(
          child: EnhancedDashboardCard(
            title: 'Loading...',
            value: '0',
            subtitle: 'Please wait',
            icon: Icons.hourglass_empty,
            isLoading: true,
          ),
        ),
        const SizedBox(width: GESpacing.sm),
        const Expanded(
          child: EnhancedDashboardCard(
            title: 'Loading...',
            value: '0',
            subtitle: 'Please wait',
            icon: Icons.hourglass_empty,
            isLoading: true,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMetrics() {
    return Row(
      children: [
        const Expanded(
          child: EnhancedDashboardCard(
            title: 'Error',
            value: '0',
            subtitle: 'Failed to load data',
            icon: Icons.error_outline,
          ),
        ),
        const SizedBox(width: GESpacing.sm),
        const Expanded(
          child: EnhancedDashboardCard(
            title: 'Error',
            value: '0',
            subtitle: 'Failed to load data',
            icon: Icons.error_outline,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStateIfNeeded(WidgetRef ref) {
    final metricsAsync = ref.watch(vendorDashboardMetricsProvider);

    return metricsAsync.when(
      data: (metrics) {
        final todayOrders = metrics['today_orders'] ?? 0;

        if (todayOrders == 0) {
          return DashboardEmptyState.noOrders(
            onGetMarketingTips: () {
              // TODO: Implement marketing tips functionality
              debugPrint('🏪 [ENHANCED-DASHBOARD] Marketing tips requested');
            },
          );
        }

        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showNotificationsBottomSheet(BuildContext context, WidgetRef ref) {
    // TODO: Implement notifications bottom sheet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications feature coming soon!'),
      ),
    );
  }
}
