import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/template_analytics_provider.dart';
import '../../widgets/vendor/template_analytics_summary_cards.dart';
import '../../widgets/vendor/template_performance_chart.dart';
import '../../widgets/vendor/template_usage_chart.dart';
import '../../widgets/vendor/template_insights_widget.dart';
import '../../widgets/vendor/template_performance_list.dart';
import '../../../../../shared/widgets/loading_widget.dart';
import '../../../../../shared/widgets/custom_button.dart';

/// Comprehensive template analytics dashboard for vendors
class TemplateAnalyticsDashboardScreen extends ConsumerStatefulWidget {
  final String vendorId;

  const TemplateAnalyticsDashboardScreen({
    super.key,
    required this.vendorId,
  });

  @override
  ConsumerState<TemplateAnalyticsDashboardScreen> createState() => _TemplateAnalyticsDashboardScreenState();
}

class _TemplateAnalyticsDashboardScreenState extends ConsumerState<TemplateAnalyticsDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Set default date range to last 30 days
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(templateAnalyticsProvider(widget.vendorId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Template Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshAnalytics(),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Performance', icon: Icon(Icons.trending_up)),
            Tab(text: 'Usage', icon: Icon(Icons.analytics)),
            Tab(text: 'Insights', icon: Icon(Icons.lightbulb)),
          ],
        ),
      ),
      body: analyticsState.isLoading
          ? const LoadingWidget(message: 'Loading analytics...')
          : analyticsState.errorMessage != null
              ? _buildErrorState(analyticsState.errorMessage!)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildPerformanceTab(),
                    _buildUsageTab(),
                    _buildInsightsTab(),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab() {
    final summary = ref.watch(templateAnalyticsSummaryProvider(widget.vendorId));

    return RefreshIndicator(
      onRefresh: _refreshAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Display
            _buildDateRangeHeader(),
            
            const SizedBox(height: 16),
            
            // Summary Cards
            if (summary != null) ...[
              TemplateAnalyticsSummaryCards(summary: summary),
              const SizedBox(height: 24),
            ],
            
            // Quick Stats
            _buildQuickStats(),
            
            const SizedBox(height: 24),
            
            // Top Performing Templates Preview
            _buildTopTemplatesPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return RefreshIndicator(
      onRefresh: _refreshAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Performance Chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revenue Performance',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TemplatePerformanceChart(vendorId: widget.vendorId),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Performance List
            TemplatePerformanceList(vendorId: widget.vendorId),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageTab() {
    return RefreshIndicator(
      onRefresh: _refreshAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Usage Chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Template Usage Trends',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TemplateUsageChart(vendorId: widget.vendorId),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Usage Statistics
            _buildUsageStatistics(),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsTab() {
    return RefreshIndicator(
      onRefresh: _refreshAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Insights Widget
            TemplateInsightsWidget(vendorId: widget.vendorId),
            
            const SizedBox(height: 16),
            
            // Recommendations
            _buildRecommendations(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeHeader() {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.date_range, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Period: ${dateFormat.format(_selectedDateRange!.start)} - ${dateFormat.format(_selectedDateRange!.end)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _selectDateRange,
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final analyticsState = ref.watch(templateAnalyticsProvider(widget.vendorId));
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Statistics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Templates',
                    '${analyticsState.performanceMetrics.length}',
                    Icons.layers,
                    theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Active Templates',
                    '${analyticsState.summary?.activeTemplates ?? 0}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Orders',
                    '${analyticsState.summary?.totalOrdersWithTemplates ?? 0}',
                    Icons.shopping_cart,
                    theme.colorScheme.secondary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total Revenue',
                    'RM ${(analyticsState.summary?.totalRevenueFromTemplates ?? 0).toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTopTemplatesPreview() {
    final topTemplates = ref.watch(topPerformingTemplatesProvider(widget.vendorId));
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Top Performing Templates',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (topTemplates.isEmpty)
              const Center(
                child: Text('No performance data available'),
              )
            else
              ...topTemplates.take(3).map((template) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getGradeColor(template.performanceGrade),
                  child: Text(
                    template.performanceGrade,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(template.templateName),
                subtitle: Text('${template.ordersCount} orders • RM ${template.revenueGenerated.toStringAsFixed(2)}'),
                trailing: Text(
                  '${template.performanceScore.toStringAsFixed(0)}%',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageStatistics() {
    // Implementation for usage statistics
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Usage statistics will be implemented here'),
      ),
    );
  }

  Widget _buildRecommendations() {
    // Implementation for recommendations
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Recommendations will be implemented here'),
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
              'Error Loading Analytics',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Retry',
              onPressed: _refreshAnalytics,
              type: ButtonType.primary,
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.red;
      case 'F':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });

      // Update analytics with new date range
      await ref.read(templateAnalyticsProvider(widget.vendorId).notifier).updateDateRange(
        vendorId: widget.vendorId,
        startDate: picked.start,
        endDate: picked.end,
      );
    }
  }

  Future<void> _refreshAnalytics() async {
    await ref.read(templateAnalyticsProvider(widget.vendorId).notifier).refresh(widget.vendorId);
  }
}

/// Tab content widget for template analytics (without Scaffold)
/// Used within TemplateManagementScreen as a tab
class TemplateAnalyticsTabContent extends ConsumerStatefulWidget {
  final String vendorId;

  const TemplateAnalyticsTabContent({
    super.key,
    required this.vendorId,
  });

  @override
  ConsumerState<TemplateAnalyticsTabContent> createState() => _TemplateAnalyticsTabContentState();
}

class _TemplateAnalyticsTabContentState extends ConsumerState<TemplateAnalyticsTabContent>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Set default date range to last 30 days
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(templateAnalyticsProvider(widget.vendorId));

    return Column(
      children: [
        // Date Range and Refresh Controls
        _buildControlsHeader(),

        // Tab Bar
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Performance', icon: Icon(Icons.trending_up)),
            Tab(text: 'Usage', icon: Icon(Icons.analytics)),
            Tab(text: 'Insights', icon: Icon(Icons.lightbulb)),
          ],
        ),

        // Tab Content
        Expanded(
          child: analyticsState.isLoading
              ? const LoadingWidget(message: 'Loading analytics...')
              : analyticsState.errorMessage != null
                  ? _buildErrorState(analyticsState.errorMessage!)
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(),
                        _buildPerformanceTab(),
                        _buildUsageTab(),
                        _buildInsightsTab(),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildControlsHeader() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Date Range Display
          Expanded(
            child: _buildDateRangeHeader(),
          ),

          // Action Buttons
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshAnalytics(),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeHeader() {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics Period',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _selectedDateRange != null
              ? '${dateFormat.format(_selectedDateRange!.start)} - ${dateFormat.format(_selectedDateRange!.end)}'
              : 'Last 30 days',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
              'Error Loading Analytics',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Retry',
              onPressed: () => _refreshAnalytics(),
              type: ButtonType.primary,
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  // Copy the tab building methods from the original class
  Widget _buildOverviewTab() {
    final summary = ref.watch(templateAnalyticsSummaryProvider(widget.vendorId));

    return RefreshIndicator(
      onRefresh: _refreshAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            if (summary != null) ...[
              TemplateAnalyticsSummaryCards(summary: summary),
              const SizedBox(height: 24),
            ],

            // Quick Stats
            _buildQuickStats(),

            const SizedBox(height: 24),

            // Top Performing Templates Preview
            _buildTopTemplatesPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return RefreshIndicator(
      onRefresh: _refreshAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Performance Chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revenue Performance',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TemplatePerformanceChart(vendorId: widget.vendorId),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Performance List
            TemplatePerformanceList(vendorId: widget.vendorId),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageTab() {
    return RefreshIndicator(
      onRefresh: _refreshAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Usage Trends Chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Template Usage Trends',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TemplateUsageChart(vendorId: widget.vendorId),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsTab() {
    return RefreshIndicator(
      onRefresh: _refreshAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TemplateInsightsWidget(vendorId: widget.vendorId),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final analyticsState = ref.watch(templateAnalyticsProvider(widget.vendorId));
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Statistics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Templates',
                    '${analyticsState.performanceMetrics.length}',
                    Icons.layers,
                    theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Active Templates',
                    '${analyticsState.summary?.activeTemplates ?? 0}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTopTemplatesPreview() {
    final analyticsState = ref.watch(templateAnalyticsProvider(widget.vendorId));
    final performanceMetrics = analyticsState.performanceMetrics;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Performing Templates',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            analyticsState.isLoading
                ? const LoadingWidget(message: 'Loading top templates...')
                : analyticsState.errorMessage != null
                    ? Text(
                        'Error loading top templates: ${analyticsState.errorMessage}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      )
                    : performanceMetrics.isEmpty
                        ? Text(
                            'No performance data available',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        : Column(
                            children: performanceMetrics.take(3).map((metric) => ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.layers,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              title: Text(metric.templateName),
                              subtitle: Text('Revenue: RM ${metric.revenueGenerated.toStringAsFixed(2)}'),
                              trailing: Text(
                                '${metric.usageCount} uses',
                                style: theme.textTheme.bodySmall,
                              ),
                            )).toList(),
                          ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });

      // Update analytics with new date range
      await ref.read(templateAnalyticsProvider(widget.vendorId).notifier).updateDateRange(
        vendorId: widget.vendorId,
        startDate: picked.start,
        endDate: picked.end,
      );
    }
  }

  Future<void> _refreshAnalytics() async {
    await ref.read(templateAnalyticsProvider(widget.vendorId).notifier).refresh(widget.vendorId);
  }
}
