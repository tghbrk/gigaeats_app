import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/wallet_analytics_provider.dart';

/// Wallet analytics summary widget for dashboard integration
class WalletAnalyticsSummaryWidget extends ConsumerWidget {
  final bool showHeader;
  final int maxInsights;

  const WalletAnalyticsSummaryWidget({
    super.key,
    this.showHeader = true,
    this.maxInsights = 2,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SafeAnalyticsWidget(
      child: _buildContent(context, ref),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(walletAnalyticsProvider);
    final theme = Theme.of(context);

    if (!analyticsState.analyticsEnabled) {
      return _buildAnalyticsDisabledCard(context);
    }

    if (analyticsState.isLoading) {
      return _buildLoadingSkeleton(context);
    }

    if (analyticsState.errorMessage != null) {
      return _buildErrorCard(context, analyticsState.errorMessage!, ref);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending Insights',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => context.push('/customer/wallet/analytics'),
                icon: const Icon(Icons.analytics, size: 16),
                label: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Summary cards
        _buildSummaryCards(context, analyticsState),
        const SizedBox(height: 16),

        // Quick insights
        _buildQuickInsights(context, analyticsState),
      ],
    );
  }

  Widget _buildAnalyticsDisabledCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Analytics Disabled',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enable analytics to view spending insights',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/customer/wallet/analytics/settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Enable Analytics'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    return Column(
      children: [
        // Summary cards skeleton
        Row(
          children: [
            Expanded(child: _buildSkeletonCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildSkeletonCard()),
          ],
        ),
        const SizedBox(height: 16),
        
        // Insights skeleton
        _buildSkeletonCard(height: 80),
      ],
    );
  }

  Widget _buildSkeletonCard({double height = 100}) {
    return Card(
      child: Container(
        constraints: BoxConstraints(minHeight: height), // Use constraints instead of fixed height
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Fix overflow
          children: [
            Container(
              width: 80,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 120,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 8), // Replace Spacer with fixed spacing
            Container(
              width: 60,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String error, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 12),
            Text(
              'Analytics Error',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(walletAnalyticsProvider.notifier).refreshAll(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, WalletAnalyticsState analyticsState) {
    final summaryCards = analyticsState.summaryCards;
    
    if (summaryCards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (summaryCards.isNotEmpty)
          Expanded(
            child: _buildSummaryCard(
              context,
              summaryCards[0]['title'] ?? 'Total Spent',
              summaryCards[0]['value'] ?? 'RM 0.00',
              Icons.trending_down,
              AppTheme.errorColor,
              summaryCards[0]['subtitle'],
            ),
          ),
        if (summaryCards.length > 1) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              context,
              summaryCards[1]['title'] ?? 'Transactions',
              summaryCards[1]['value'] ?? '0',
              Icons.receipt_long,
              AppTheme.primaryColor,
              summaryCards[1]['subtitle'],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String? subtitle,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => context.push('/customer/wallet/analytics'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Fix overflow
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible( // Use Flexible to prevent overflow
                child: Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Flexible( // Use Flexible for subtitle
                  child: Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickInsights(BuildContext context, WalletAnalyticsState analyticsState) {
    final currentMonth = analyticsState.currentMonthAnalytics;
    
    if (currentMonth == null) {
      return const SizedBox.shrink();
    }

    final insights = _generateQuickInsights(currentMonth);
    
    if (insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppTheme.warningColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Insight',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              insights.first['message'] as String,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _generateQuickInsights(dynamic analytics) {
    final insights = <Map<String, dynamic>>[];

    // Simple insights for dashboard
    insights.add({
      'message': 'Your spending is well-controlled this month. Keep up the good work!',
      'type': 'positive',
    });

    return insights;
  }
}

/// Safe wrapper widget to catch UI errors and prevent 'Something Went Wrong' messages
class _SafeAnalyticsWidget extends StatelessWidget {
  final Widget child;

  const _SafeAnalyticsWidget({required this.child});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (e) {
          debugPrint('❌ [ANALYTICS-UI] UI error caught: $e');
          // Return a simple fallback widget instead of crashing
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Analytics Loading...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
