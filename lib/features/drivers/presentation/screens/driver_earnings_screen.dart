import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/custom_error_widget.dart';
import '../providers/driver_earnings_provider.dart';
import '../widgets/earnings_charts_widget.dart';
import '../widgets/driver_performance_dashboard.dart';
import '../widgets/earnings_notifications_widget.dart';
import '../widgets/earnings_overview_cards.dart';

/// Driver earnings screen with analytics and payment history
/// Phase 2: Provider integration with Consumer widgets to prevent infinite rebuilds
class DriverEarningsScreen extends ConsumerStatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  ConsumerState<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends ConsumerState<DriverEarningsScreen>
    with TickerProviderStateMixin {
  // Phase 4: Enhanced state management with animations
  String _selectedPeriod = 'this_month';
  int _selectedTabIndex = 0; // 0: Summary, 1: Breakdown, 2: History, 3: Performance, 4: Charts

  // Phase 4: Animation controllers for enhanced UI
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Phase 4: Real-time notifications state
  bool _showNotifications = true;

  @override
  void initState() {
    super.initState();
    debugPrint('💰 DriverEarningsScreen: Phase 4 - initState() called');

    // Phase 4: Initialize animations safely
    _initializeAnimations();
  }

  @override
  void dispose() {
    debugPrint('💰 DriverEarningsScreen: Phase 4 - dispose() called');

    // Phase 4: Dispose animations safely
    _fadeController.dispose();

    super.dispose();
  }

  /// Phase 4: Initialize animations safely to prevent infinite loops
  void _initializeAnimations() {
    try {
      _fadeController = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );

      _fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ));

      // Start fade animation
      _fadeController.forward();

      debugPrint('💰 DriverEarningsScreen: Phase 4 - Animations initialized successfully');
    } catch (e) {
      debugPrint('💰 DriverEarningsScreen: Phase 4 - Animation initialization failed: $e');
    }
  }



  /// Refresh all earnings data
  Future<void> _refreshData() async {
    debugPrint('💰 DriverEarningsScreen: Phase 3 - Refreshing all data');

    // Invalidate all providers
    ref.invalidate(driverEarningsSummaryProvider);
    ref.invalidate(driverEarningsBreakdownProvider);
    ref.invalidate(driverEarningsHistoryProvider);
    ref.invalidate(currentDriverIdProvider);

    debugPrint('💰 DriverEarningsScreen: Phase 3 - Refresh completed');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('💰 DriverEarningsScreen: Phase 3 - build() called at ${DateTime.now()}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Earnings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          // Phase 4: Notification toggle button
          IconButton(
            icon: Icon(_showNotifications ? Icons.notifications : Icons.notifications_off),
            onPressed: () {
              setState(() {
                _showNotifications = !_showNotifications;
              });
              debugPrint('💰 Notifications toggled: $_showNotifications');
            },
            tooltip: _showNotifications ? 'Hide notifications' : 'Show notifications',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh earnings data',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Column(
          children: [
            // Phase 3: Period selector
            _buildPeriodSelector(),

            // Phase 3: Simple navigation tabs
            _buildNavigationTabs(),

            // Phase 3: Content based on selected tab
            Expanded(
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  /// Build period selector widget
  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text(
            'Period: ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedPeriod,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'today', child: Text('Today')),
                DropdownMenuItem(value: 'this_week', child: Text('This Week')),
                DropdownMenuItem(value: 'this_month', child: Text('This Month')),
                DropdownMenuItem(value: 'last_month', child: Text('Last Month')),
                DropdownMenuItem(value: 'all_time', child: Text('All Time')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPeriod = value;
                  });
                  debugPrint('💰 Period changed to: $value');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Phase 4: Enhanced navigation tabs with advanced features
  Widget _buildNavigationTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTabButton('Summary', Icons.dashboard, 0),
            _buildTabButton('Breakdown', Icons.pie_chart, 1),
            _buildTabButton('History', Icons.history, 2),
            _buildTabButton('Performance', Icons.analytics, 3),
            _buildTabButton('Charts', Icons.bar_chart, 4),
          ],
        ),
      ),
    );
  }

  /// Build individual tab button
  Widget _buildTabButton(String title, IconData icon, int index) {
    final isSelected = _selectedTabIndex == index;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
        debugPrint('💰 Tab changed to: $title (index: $index)');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Phase 4: Enhanced tab content with advanced features
  Widget _buildTabContent() {
    // Wrap content in FadeTransition for smooth animations
    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildTabContentInternal(),
    );
  }

  /// Internal tab content builder
  Widget _buildTabContentInternal() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildEarningsSummary();
      case 1:
        return _buildEarningsBreakdown();
      case 2:
        return _buildEarningsHistory();
      case 3:
        return _buildPerformanceDashboard();
      case 4:
        return _buildChartsView();
      default:
        return _buildEarningsSummary();
    }
  }

  /// Build earnings summary with Consumer widget to isolate provider watching
  Widget _buildEarningsSummary() {
    return Consumer(
      builder: (context, ref, child) {
        debugPrint('💰 Consumer builder called for earnings summary');

        final driverIdAsync = ref.watch(currentDriverIdProvider);

        return driverIdAsync.when(
          loading: () {
            debugPrint('💰 Loading driver ID...');
            return const Center(child: LoadingWidget());
          },
          error: (error, stack) {
            debugPrint('💰 Driver ID error: $error');
            return Center(
              child: CustomErrorWidget(
                message: 'Failed to load driver information',
                onRetry: () {
                  ref.invalidate(currentDriverIdProvider);
                },
              ),
            );
          },
          data: (driverId) {
            if (driverId == null) {
              return const Center(
                child: Text('Driver information not available'),
              );
            }

            // Create earnings parameters
            final now = DateTime.now();
            DateTime? startDate;
            DateTime? endDate;

            switch (_selectedPeriod) {
              case 'today':
                startDate = DateTime(now.year, now.month, now.day);
                endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
                break;
              case 'this_week':
                final weekday = now.weekday;
                final weekStart = now.subtract(Duration(days: weekday - 1));
                startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
                endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
                break;
              case 'this_month':
                startDate = DateTime(now.year, now.month, 1);
                endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
                break;
              case 'last_month':
                final lastMonth = DateTime(now.year, now.month - 1, 1);
                startDate = lastMonth;
                endDate = DateTime(now.year, now.month, 1).subtract(const Duration(days: 1));
                endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
                break;
              case 'all_time':
                startDate = null;
                endDate = null;
                break;
            }

            final stableKey = '${_selectedPeriod}_${startDate?.millisecondsSinceEpoch ?? 0}_${endDate?.millisecondsSinceEpoch ?? 0}';

            final earningsParams = EarningsParams(
              driverId: driverId,
              startDate: startDate,
              endDate: endDate,
              period: _selectedPeriod,
              stableKey: stableKey,
            );

            final summaryAsync = ref.watch(driverEarningsSummaryProvider(earningsParams));

            return summaryAsync.when(
              loading: () {
                debugPrint('💰 Earnings summary loading...');
                return const Center(child: LoadingWidget());
              },
              error: (error, stack) {
                debugPrint('💰 Earnings summary error: $error');
                return Center(
                  child: CustomErrorWidget(
                    message: 'Failed to load earnings summary',
                    onRetry: () {
                      ref.invalidate(driverEarningsSummaryProvider);
                    },
                  ),
                );
              },
              data: (summary) {
                debugPrint('💰 Earnings summary loaded: $summary');
                return _buildSummaryContent(summary, startDate, endDate);
              },
            );
          },
        );
      },
    );
  }

  /// Phase 4: Enhanced summary content with advanced overview cards
  Widget _buildSummaryContent(Map<String, dynamic> summary, DateTime? startDate, DateTime? endDate) {
    final totalEarnings = summary['total_net_earnings'] as double? ?? 0.0;
    final totalDeliveries = summary['total_deliveries'] as int? ?? 0;
    final averagePerDelivery = summary['average_earnings_per_delivery'] as double? ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Phase 4: Real-time notifications and enhanced overview cards
          // These will be shown when driver ID is available via provider
          Consumer(
            builder: (context, ref, child) {
              final driverIdAsync = ref.watch(currentDriverIdProvider);
              return driverIdAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (error, stack) => const SizedBox.shrink(),
                data: (driverId) {
                  if (driverId == null) return const SizedBox.shrink();

                  return Column(
                    children: [
                      // Phase 4: Real-time notifications (if enabled)
                      if (_showNotifications) ...[
                        EarningsNotificationsWidget(
                          driverId: driverId,
                          showUnreadOnly: true,
                          maxNotifications: 3,
                          onNotificationTap: () {
                            debugPrint('💰 Summary notification tapped');
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Phase 4: Enhanced overview cards with animations
                      EnhancedEarningsOverviewCards(
                        driverId: driverId,
                        startDate: startDate,
                        endDate: endDate,
                        period: _selectedPeriod,
                        showComparison: true,
                        onCardTap: () {
                          debugPrint('💰 Summary overview card tapped');
                          // Switch to charts tab
                          setState(() {
                            _selectedTabIndex = 4;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              );
            },
          ),

          // Traditional total earnings card (fallback)
          Card(
            elevation: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Earnings',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'RM ${totalEarnings.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'For $_selectedPeriod',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Quick stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Deliveries',
                  totalDeliveries.toString(),
                  Icons.local_shipping,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Avg. per Delivery',
                  'RM ${averagePerDelivery.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build stat card widget
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build earnings breakdown with Consumer widget
  Widget _buildEarningsBreakdown() {
    return Consumer(
      builder: (context, ref, child) {
        debugPrint('💰 Consumer builder called for earnings breakdown');

        final driverIdAsync = ref.watch(currentDriverIdProvider);

        return driverIdAsync.when(
          loading: () {
            debugPrint('💰 Loading driver ID...');
            return const Center(child: LoadingWidget());
          },
          error: (error, stack) {
            debugPrint('💰 Driver ID error: $error');
            return Center(
              child: CustomErrorWidget(
                message: 'Failed to load driver information',
                onRetry: () {
                  ref.invalidate(currentDriverIdProvider);
                },
              ),
            );
          },
          data: (driverId) {
            if (driverId == null) {
              return const Center(
                child: Text('Driver information not available'),
              );
            }

            // Create earnings parameters
            final now = DateTime.now();
            DateTime? startDate;
            DateTime? endDate;

            switch (_selectedPeriod) {
              case 'today':
                startDate = DateTime(now.year, now.month, now.day);
                endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
                break;
              case 'this_week':
                final weekday = now.weekday;
                final weekStart = now.subtract(Duration(days: weekday - 1));
                startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
                endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
                break;
              case 'this_month':
                startDate = DateTime(now.year, now.month, 1);
                endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
                break;
              case 'last_month':
                final lastMonth = DateTime(now.year, now.month - 1, 1);
                startDate = lastMonth;
                endDate = DateTime(now.year, now.month, 1).subtract(const Duration(days: 1));
                endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
                break;
              case 'all_time':
                startDate = null;
                endDate = null;
                break;
            }

            final stableKey = '${_selectedPeriod}_${startDate?.millisecondsSinceEpoch ?? 0}_${endDate?.millisecondsSinceEpoch ?? 0}';

            final earningsParams = EarningsParams(
              driverId: driverId,
              startDate: startDate,
              endDate: endDate,
              period: _selectedPeriod,
              stableKey: stableKey,
            );

            final breakdownAsync = ref.watch(driverEarningsBreakdownProvider(earningsParams));

            return breakdownAsync.when(
              loading: () {
                debugPrint('💰 Earnings breakdown loading...');
                return const Center(child: LoadingWidget());
              },
              error: (error, stack) {
                debugPrint('💰 Earnings breakdown error: $error');
                return Center(
                  child: CustomErrorWidget(
                    message: 'Failed to load earnings breakdown',
                    onRetry: () {
                      ref.invalidate(driverEarningsBreakdownProvider);
                    },
                  ),
                );
              },
              data: (breakdown) {
                debugPrint('💰 Earnings breakdown loaded: $breakdown');
                return _buildBreakdownContent(breakdown);
              },
            );
          },
        );
      },
    );
  }

  /// Build breakdown content widget
  Widget _buildBreakdownContent(Map<String, double> breakdown) {
    if (breakdown.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No earnings breakdown available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Complete some deliveries to see your earnings breakdown',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earnings Breakdown',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Breakdown cards
          Expanded(
            child: ListView(
              children: breakdown.entries.map((entry) {
                return _buildBreakdownCard(
                  _formatEarningsType(entry.key),
                  entry.value,
                  _getEarningsTypeIcon(entry.key),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual breakdown card
  Widget _buildBreakdownCard(String title, double amount, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RM ${amount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format earnings type for display
  String _formatEarningsType(String type) {
    switch (type.toLowerCase()) {
      case 'delivery_fee':
        return 'Delivery Fees';
      case 'tip':
        return 'Tips';
      case 'bonus':
        return 'Bonuses';
      case 'commission':
        return 'Commission';
      case 'peak_hour_bonus':
        return 'Peak Hour Bonus';
      case 'completion_bonus':
        return 'Completion Bonus';
      case 'rating_bonus':
        return 'Rating Bonus';
      default:
        return type.replaceAll('_', ' ').split(' ').map((word) =>
          word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word
        ).join(' ');
    }
  }

  /// Get icon for earnings type
  IconData _getEarningsTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'delivery_fee':
        return Icons.local_shipping;
      case 'tip':
        return Icons.volunteer_activism;
      case 'bonus':
        return Icons.star;
      case 'commission':
        return Icons.percent;
      case 'peak_hour_bonus':
        return Icons.trending_up;
      case 'completion_bonus':
        return Icons.check_circle;
      case 'rating_bonus':
        return Icons.thumb_up;
      default:
        return Icons.account_balance_wallet;
    }
  }

  /// Build earnings history with Consumer widget
  Widget _buildEarningsHistory() {
    return Consumer(
      builder: (context, ref, child) {
        debugPrint('💰 Consumer builder called for earnings history');

        const historyParams = {
          'page': 1,
          'limit': 20,
        };
        final historyAsync = ref.watch(driverEarningsHistoryProvider(historyParams));

        return historyAsync.when(
          loading: () {
            debugPrint('💰 Earnings history loading...');
            return const Center(child: LoadingWidget());
          },
          error: (error, stack) {
            debugPrint('💰 Earnings history error: $error');
            return Center(
              child: CustomErrorWidget(
                message: 'Failed to load earnings history',
                onRetry: () {
                  ref.invalidate(driverEarningsHistoryProvider);
                },
              ),
            );
          },
          data: (history) {
            debugPrint('💰 Earnings history loaded: ${history.length} records');
            return _buildHistoryContent(history);
          },
        );
      },
    );
  }

  /// Build history content widget
  Widget _buildHistoryContent(List<Map<String, dynamic>> history) {
    if (history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No earnings history available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Your completed deliveries will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earnings History',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // History list
          Expanded(
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final earning = history[index];
                return _buildHistoryCard(earning);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual history card
  Widget _buildHistoryCard(Map<String, dynamic> earning) {
    final amount = (earning['net_earnings'] as num?)?.toDouble() ?? 0.0;
    final earningsType = earning['earnings_type'] as String? ?? 'delivery_fee';
    final createdAt = DateTime.tryParse(earning['created_at'] as String? ?? '') ?? DateTime.now();
    final orderNumber = earning['order_number'] as String? ?? 'N/A';
    final vendorName = earning['vendor_name'] as String? ?? 'Unknown Vendor';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getEarningsTypeIcon(earningsType),
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatEarningsType(earningsType),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Order #$orderNumber • $vendorName',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'RM ${amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Phase 4: Build performance dashboard with advanced metrics
  Widget _buildPerformanceDashboard() {
    debugPrint('💰 DriverEarningsScreen: _buildPerformanceDashboard() called at ${DateTime.now()}');

    return Consumer(
      builder: (context, ref, child) {
        debugPrint('💰 Consumer builder called for performance dashboard');

        final driverIdAsync = ref.watch(currentDriverIdProvider);

        return driverIdAsync.when(
          loading: () {
            debugPrint('💰 Performance dashboard - Driver ID loading...');
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading driver information...'),
                ],
              ),
            );
          },
          error: (error, stack) {
            debugPrint('💰 Performance dashboard - Driver ID error: $error');
            return Center(
              child: CustomErrorWidget(
                message: 'Failed to load driver information',
                onRetry: () {
                  ref.invalidate(currentDriverIdProvider);
                },
              ),
            );
          },
          data: (driverId) {
            debugPrint('💰 Performance dashboard - Driver ID loaded: $driverId');
            if (driverId == null) {
              return const Center(
                child: Text('Driver profile not found'),
              );
            }
            return const DriverPerformanceDashboard();
          },
        );
      },
    );
  }

  /// Phase 4: Build charts view with interactive analytics
  Widget _buildChartsView() {
    debugPrint('💰 DriverEarningsScreen: _buildChartsView() called at ${DateTime.now()}');

    return Consumer(
      builder: (context, ref, child) {
        debugPrint('💰 Consumer builder called for charts view');

        final driverIdAsync = ref.watch(currentDriverIdProvider);

        return driverIdAsync.when(
          loading: () {
            debugPrint('💰 Charts view - Driver ID loading...');
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading driver information...'),
                ],
              ),
            );
          },
          error: (error, stack) {
            debugPrint('💰 Charts view - Driver ID error: $error');
            return Center(
              child: CustomErrorWidget(
                message: 'Failed to load driver information',
                onRetry: () {
                  ref.invalidate(currentDriverIdProvider);
                },
              ),
            );
          },
          data: (driverId) {
            debugPrint('💰 Charts view - Driver ID loaded: $driverId');
            if (driverId == null) {
              return const Center(
                child: Text('Driver profile not found'),
              );
            }

            // Calculate date range for charts
            final now = DateTime.now();
            DateTime? startDate;
            DateTime? endDate;

            switch (_selectedPeriod) {
              case 'today':
                startDate = DateTime(now.year, now.month, now.day);
                endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
                break;
              case 'this_week':
                final weekday = now.weekday;
                final weekStart = now.subtract(Duration(days: weekday - 1));
                startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
                endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
                break;
              case 'this_month':
                startDate = DateTime(now.year, now.month, 1);
                endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
                break;
              case 'last_month':
                final lastMonth = DateTime(now.year, now.month - 1, 1);
                startDate = lastMonth;
                endDate = DateTime(now.year, now.month, 1).subtract(const Duration(days: 1));
                endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
                break;
              case 'all_time':
                startDate = null;
                endDate = null;
                break;
            }

            debugPrint('💰 DriverEarningsScreen: Charts tab - Building charts for driver: $driverId');
            debugPrint('💰 DriverEarningsScreen: Charts tab - Date range: $startDate to $endDate');

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Phase 4: Real-time notifications widget
                  if (_showNotifications) ...[
                    EarningsNotificationsWidget(
                      driverId: driverId,
                      showUnreadOnly: false,
                      maxNotifications: 5,
                      onNotificationTap: () {
                        debugPrint('💰 Notification tapped');
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Phase 4: Enhanced overview cards with animations
                  EnhancedEarningsOverviewCards(
                    driverId: driverId,
                    startDate: startDate,
                    endDate: endDate,
                    period: _selectedPeriod,
                    showComparison: true,
                    onCardTap: () {
                      debugPrint('💰 Overview card tapped');
                    },
                  ),

                  const SizedBox(height: 16),

                  // Phase 4: Interactive charts widget
                  EarningsChartsWidget(
                    driverId: driverId,
                    startDate: startDate,
                    endDate: endDate,
                    showLegend: true,
                    height: 350,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
