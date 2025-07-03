import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/presentation/providers/customer_spending_analytics_provider.dart';
import '../../../../user_management/presentation/providers/customer_budget_provider.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../providers/wallet_analytics_provider.dart';
import '../../../../../core/widgets/analytics/spending_analytics_widgets.dart';
import '../../widgets/wallet_analytics_widgets.dart';

class CustomerSpendingAnalyticsScreen extends ConsumerStatefulWidget {
  const CustomerSpendingAnalyticsScreen({super.key});

  @override
  ConsumerState<CustomerSpendingAnalyticsScreen> createState() => _CustomerSpendingAnalyticsScreenState();
}

class _CustomerSpendingAnalyticsScreenState extends ConsumerState<CustomerSpendingAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'monthly';

  @override
  void initState() {
    super.initState();
    debugPrint('🔍 [ANALYTICS-SCREEN] initState() called');
    _tabController = TabController(length: 5, vsync: this);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🔍 [ANALYTICS-SCREEN] Post-frame callback executing, loading initial data...');
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    debugPrint('🔍 [ANALYTICS-SCREEN] _loadInitialData() called');
    try {
      // Check auth state first
      final authState = ref.read(authStateProvider);
      debugPrint('🔍 [ANALYTICS-SCREEN] Auth state - user: ${authState.user?.id}, status: ${authState.status}');

      if (authState.status != AuthStatus.authenticated || authState.user == null) {
        debugPrint('❌ [ANALYTICS-SCREEN] User not authenticated, skipping data load');
        return;
      }

      debugPrint('🔍 [ANALYTICS-SCREEN] Refreshing customerSpendingAnalyticsProvider...');
      ref.read(customerSpendingAnalyticsProvider.notifier).refreshAll();

      debugPrint('🔍 [ANALYTICS-SCREEN] Setting up real-time refresh...');
      ref.read(customerSpendingAnalyticsProvider.notifier).setupRealtimeRefresh();

      debugPrint('🔍 [ANALYTICS-SCREEN] Refreshing customerBudgetProvider...');
      ref.read(customerBudgetProvider.notifier).refreshAll();

      debugPrint('🔍 [ANALYTICS-SCREEN] Refreshing walletAnalyticsProvider...');
      ref.read(walletAnalyticsProvider.notifier).refreshAll();

      debugPrint('✅ [ANALYTICS-SCREEN] All providers refreshed successfully');
    } catch (e, stack) {
      debugPrint('❌ [ANALYTICS-SCREEN] Error in _loadInitialData: $e');
      debugPrint('❌ [ANALYTICS-SCREEN] Stack trace: $stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔍 [ANALYTICS-SCREEN] build() called');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Analytics'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Analytics Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard, size: 20)),
            Tab(text: 'Trends', icon: Icon(Icons.trending_up, size: 20)),
            Tab(text: 'Categories', icon: Icon(Icons.pie_chart, size: 20)),
            Tab(text: 'Wallet', icon: Icon(Icons.account_balance_wallet, size: 20)),
            Tab(text: 'Budgets', icon: Icon(Icons.savings, size: 20)),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    debugPrint('🔍 [ANALYTICS-SCREEN] _buildBody() called - using tab-specific error handling');

    return Column(
      children: [
        // Period selector
        _buildPeriodSelector(),

        // Tab content with individual error handling
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildTrendsTab(),
              _buildCategoriesTab(),
              _buildWalletAnalyticsTab(),
              _buildBudgetsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Period: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPeriodChip('weekly', 'This Week'),
                  const SizedBox(width: 8),
                  _buildPeriodChip('monthly', 'This Month'),
                  const SizedBox(width: 8),
                  _buildPeriodChip('quarterly', 'This Quarter'),
                  const SizedBox(width: 8),
                  _buildPeriodChip('yearly', 'This Year'),
                  const SizedBox(width: 8),
                  _buildCustomDateButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String period, String label) {
    final isSelected = _selectedPeriod == period;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedPeriod = period);
          ref.read(customerSpendingAnalyticsProvider.notifier).changePeriod(period);
        }
      },
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildCustomDateButton() {
    return OutlinedButton.icon(
      onPressed: _showDateRangePicker,
      icon: const Icon(Icons.date_range, size: 16),
      label: const Text('Custom'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final analyticsState = ref.watch(customerSpendingAnalyticsProvider);
    debugPrint('🔍 [ANALYTICS-SCREEN] Overview tab - isLoading: ${analyticsState.isLoading}, errorMessage: ${analyticsState.errorMessage}');
    debugPrint('🔍 [ANALYTICS-SCREEN] Overview tab - analytics: ${analyticsState.analytics != null ? "loaded" : "null"}, trends: ${analyticsState.trends.length}, categories: ${analyticsState.categories.length}');

    if (analyticsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (analyticsState.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Overview Unavailable',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                analyticsState.errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.read(customerSpendingAnalyticsProvider.notifier).refreshAll(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards - now using real data from providers
          const SpendingSummaryCards(),
          const SizedBox(height: 24),

          // Quick insights - now using real data from providers
          const SpendingInsightsWidget(),
          const SizedBox(height: 24),

          // Top merchants - now using real data from providers
          const TopMerchantsWidget(),
          const SizedBox(height: 24),

          // Recent trends chart - now using real data from providers
          const SpendingTrendsChart(),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    final analyticsState = ref.watch(customerSpendingAnalyticsProvider);
    debugPrint('🔍 [ANALYTICS-SCREEN] Trends tab - isLoading: ${analyticsState.isLoading}, errorMessage: ${analyticsState.errorMessage}');

    if (analyticsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (analyticsState.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.trending_up,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Trends Unavailable',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                analyticsState.errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.read(customerSpendingAnalyticsProvider.notifier).refreshAll(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main trends chart - now using real data from providers
          const SpendingTrendsChart(height: 300),
          const SizedBox(height: 24),

          // Comparison with previous period - now using real data from providers
          const SpendingComparisonWidget(),
          const SizedBox(height: 24),

          // Spending frequency analysis - now using real data from providers
          const SpendingFrequencyWidget(),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    final analyticsState = ref.watch(customerSpendingAnalyticsProvider);
    debugPrint('🔍 [ANALYTICS-SCREEN] Categories tab - isLoading: ${analyticsState.isLoading}, errorMessage: ${analyticsState.errorMessage}');

    if (analyticsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (analyticsState.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Categories Unavailable',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                analyticsState.errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.read(customerSpendingAnalyticsProvider.notifier).refreshAll(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category pie chart - now using real data from providers
          const CategorySpendingChart(height: 300),
          const SizedBox(height: 24),

          // Category breakdown list - now using real data from providers
          const CategoryBreakdownList(),
          const SizedBox(height: 24),

          // Category trends - now using real data from providers
          const CategoryTrendsWidget(),
        ],
      ),
    );
  }

  Widget _buildWalletAnalyticsTab() {
    debugPrint('🔍 [ANALYTICS-SCREEN] _buildWalletAnalyticsTab() called');

    final walletAnalyticsState = ref.watch(walletAnalyticsProvider);
    debugPrint('🔍 [ANALYTICS-SCREEN] Wallet analytics state - enabled: ${walletAnalyticsState.analyticsEnabled}');
    debugPrint('🔍 [ANALYTICS-SCREEN] Wallet analytics state - isLoading: ${walletAnalyticsState.isLoading}');
    debugPrint('🔍 [ANALYTICS-SCREEN] Wallet analytics state - errorMessage: ${walletAnalyticsState.errorMessage}');

    // Handle loading state for wallet analytics
    if (walletAnalyticsState.isLoading) {
      debugPrint('🔍 [ANALYTICS-SCREEN] Wallet analytics loading, showing spinner');
      return const Center(child: CircularProgressIndicator());
    }

    // Handle wallet analytics specific errors
    if (walletAnalyticsState.errorMessage != null) {
      debugPrint('❌ [ANALYTICS-SCREEN] Wallet analytics error: ${walletAnalyticsState.errorMessage}');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Wallet Analytics Error',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                walletAnalyticsState.errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.read(walletAnalyticsProvider.notifier).refreshAll(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!walletAnalyticsState.analyticsEnabled) {
      debugPrint('⚠️ [ANALYTICS-SCREEN] Wallet analytics disabled, showing enable prompt');
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Wallet Analytics Disabled',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enable wallet analytics in settings to view detailed spending insights and trends.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/customer/wallet/settings'),
              child: const Text('Enable Analytics'),
            ),
          ],
        ),
      );
    }

    debugPrint('✅ [ANALYTICS-SCREEN] Wallet analytics enabled, building content');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wallet analytics summary cards
          const WalletAnalyticsSummaryCards(),
          const SizedBox(height: 24),

          // Wallet spending trends chart (enhanced)
          const WalletSpendingTrendsChart(height: 300, showComparison: true),
          const SizedBox(height: 24),

          // Wallet balance history chart
          const WalletBalanceHistoryChart(height: 250),
          const SizedBox(height: 24),

          // Wallet category spending chart
          const WalletCategorySpendingChart(height: 300),
          const SizedBox(height: 24),

          // Top vendors chart
          const WalletTopVendorsChart(height: 250),
          const SizedBox(height: 24),

          // Category breakdown list
          const WalletCategoryBreakdownList(),
          const SizedBox(height: 24),

          // Analytics insights
          const WalletAnalyticsInsightsWidget(),
        ],
      ),
    );
  }

  Widget _buildBudgetsTab() {
    final budgetState = ref.watch(customerBudgetProvider);
    debugPrint('🔍 [ANALYTICS-SCREEN] Budgets tab - isLoading: ${budgetState.isLoading}, errorMessage: ${budgetState.errorMessage}');

    if (budgetState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (budgetState.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.savings,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Budgets Unavailable',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                budgetState.errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.read(customerBudgetProvider.notifier).refreshAll(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Budget overview cards
          const _BudgetOverviewCards(),
          const SizedBox(height: 24),

          // Active budgets list
          const _ActiveBudgetsList(),
          const SizedBox(height: 24),

          // Financial goals
          const _FinancialGoalsWidget(),
          const SizedBox(height: 24),

          // Create budget button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showCreateBudgetDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create New Budget'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _showExportDialog();
        break;
      case 'settings':
        _navigateToAnalyticsSettings();
        break;
    }
  }

  Future<void> _showDateRangePicker() async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
    );

    if (dateRange != null) {
      setState(() => _selectedPeriod = 'custom');
      ref.read(customerSpendingAnalyticsProvider.notifier)
          .setDateRange(dateRange.start, dateRange.end);
    }
  }

  void _showExportDialog() {
    // Show wallet analytics export dialog if on wallet tab
    if (_tabController.index == 3) {
      showDialog(
        context: context,
        builder: (context) => const WalletAnalyticsExportDialog(),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => const _ExportDataDialog(),
      );
    }
  }

  void _showCreateBudgetDialog() {
    showDialog(
      context: context,
      builder: (context) => const _CreateBudgetDialog(),
    );
  }

  void _navigateToAnalyticsSettings() {
    // Navigate to analytics settings screen
    context.push('/customer/wallet/analytics/settings');
  }
}

// Placeholder widgets for budget functionality
class _BudgetOverviewCards extends StatelessWidget {
  const _BudgetOverviewCards();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text('Budget Overview Cards - Coming Soon'),
        ),
      ),
    );
  }
}

class _ActiveBudgetsList extends StatelessWidget {
  const _ActiveBudgetsList();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text('Active Budgets List - Coming Soon'),
        ),
      ),
    );
  }
}

class _FinancialGoalsWidget extends StatelessWidget {
  const _FinancialGoalsWidget();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text('Financial Goals - Coming Soon'),
        ),
      ),
    );
  }
}

class _ExportDataDialog extends StatelessWidget {
  const _ExportDataDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Data'),
      content: const Text('Export functionality coming soon'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _CreateBudgetDialog extends StatelessWidget {
  const _CreateBudgetDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Budget'),
      content: const Text('Budget creation functionality coming soon'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}


