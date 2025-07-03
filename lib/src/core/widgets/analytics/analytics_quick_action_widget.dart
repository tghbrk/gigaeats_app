import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../../../features/marketplace_wallet/presentation/providers/wallet_analytics_provider.dart';

/// Enhanced analytics quick action widget with preview data
class AnalyticsQuickActionWidget extends ConsumerWidget {
  final bool showPreview;
  final double height;

  const AnalyticsQuickActionWidget({
    super.key,
    this.showPreview = true,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(walletAnalyticsProvider);
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => context.push('/customer/wallet/analytics'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: height,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.1),
                AppTheme.successColor.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.analytics,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spending Analytics',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'View detailed insights',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
              
              if (showPreview) ...[
                const SizedBox(height: 12),
                _buildPreviewContent(context, analyticsState),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewContent(BuildContext context, WalletAnalyticsState analyticsState) {
    final theme = Theme.of(context);

    if (!analyticsState.analyticsEnabled) {
      return Row(
        children: [
          Icon(
            Icons.visibility_off,
            size: 16,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 8),
          Text(
            'Analytics disabled',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    if (analyticsState.isLoading) {
      return Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Loading insights...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      );
    }

    if (analyticsState.errorMessage != null) {
      return Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: AppTheme.errorColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Error loading data',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      );
    }

    // Show preview data
    final summaryCards = analyticsState.summaryCards;
    if (summaryCards.isNotEmpty) {
      return Row(
        children: [
          Expanded(
            child: _buildPreviewMetric(
              context,
              'This Month',
              summaryCards[0]['value'] ?? 'RM 0.00',
              Icons.trending_down,
              AppTheme.errorColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildPreviewMetric(
              context,
              'Transactions',
              summaryCards.length > 1 ? summaryCards[1]['value'] ?? '0' : '0',
              Icons.receipt_long,
              AppTheme.primaryColor,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(
          Icons.insights,
          size: 16,
          color: AppTheme.successColor,
        ),
        const SizedBox(width: 8),
        Text(
          'Tap to view detailed analytics',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.successColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 12,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Floating analytics action button
class AnalyticsFloatingActionButton extends ConsumerWidget {
  const AnalyticsFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(walletAnalyticsProvider);

    return FloatingActionButton.extended(
      onPressed: () => context.push('/customer/wallet/analytics'),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      icon: analyticsState.isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.analytics),
      label: const Text('Analytics'),
    );
  }
}

/// Analytics navigation rail item
class AnalyticsNavigationItem extends ConsumerWidget {
  final bool isSelected;
  final VoidCallback? onTap;

  const AnalyticsNavigationItem({
    super.key,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(walletAnalyticsProvider);
    final theme = Theme.of(context);

    return ListTile(
      leading: Stack(
        children: [
          Icon(
            Icons.analytics_outlined,
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
          ),
          if (analyticsState.isLoading)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.warningColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        'Analytics',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: analyticsState.analyticsEnabled
          ? Text(
              'View insights',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
            )
          : Text(
              'Disabled',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade400,
                fontStyle: FontStyle.italic,
              ),
            ),
      selected: isSelected,
      selectedTileColor: AppTheme.primaryColor.withValues(alpha: 0.1),
      onTap: onTap ?? () => context.push('/customer/wallet/analytics'),
    );
  }
}
