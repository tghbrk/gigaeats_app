import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/customer_transaction_management_provider.dart';

/// Wallet statistics overview widget
class WalletStatisticsOverview extends ConsumerWidget {
  final VoidCallback? onViewDetailsPressed;

  const WalletStatisticsOverview({
    super.key,
    this.onViewDetailsPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stats = ref.watch(customerTransactionStatsProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'This Month',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onViewDetailsPressed != null)
                  TextButton(
                    onPressed: onViewDetailsPressed,
                    child: const Text('View Details'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Statistics grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  theme: theme,
                  title: 'Total Spent',
                  value: 'RM ${(stats['total_spent'] ?? 0.0).toStringAsFixed(2)}',
                  icon: Icons.trending_down,
                  color: theme.colorScheme.error,
                ),
                _buildStatCard(
                  theme: theme,
                  title: 'Total Received',
                  value: 'RM ${(stats['total_received'] ?? 0.0).toStringAsFixed(2)}',
                  icon: Icons.trending_up,
                  color: theme.colorScheme.primary,
                ),
                _buildStatCard(
                  theme: theme,
                  title: 'Transactions',
                  value: '${stats['total_transactions'] ?? 0}',
                  icon: Icons.receipt_long,
                  color: theme.colorScheme.secondary,
                ),
                _buildStatCard(
                  theme: theme,
                  title: 'Average',
                  value: 'RM ${(stats['average_transaction'] ?? 0.0).toStringAsFixed(2)}',
                  icon: Icons.analytics,
                  color: theme.colorScheme.tertiary,
                ),
              ],
            ),
            
            if (stats['by_type'] != null && (stats['by_type'] as Map).isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildTransactionBreakdown(theme, stats['by_type'] as Map<String, int>),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required ThemeData theme,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionBreakdown(ThemeData theme, Map<String, int> byType) {
    final sortedEntries = byType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Types',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...sortedEntries.take(4).map((entry) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getTypeColor(theme, entry.key),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.key,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${entry.value}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Color _getTypeColor(ThemeData theme, String typeName) {
    switch (typeName.toLowerCase()) {
      case 'top up':
        return theme.colorScheme.primary;
      case 'order payment':
        return theme.colorScheme.error;
      case 'refund':
        return theme.colorScheme.tertiary;
      case 'transfer':
        return theme.colorScheme.secondary;
      case 'adjustment':
        return Colors.orange;
      default:
        return theme.colorScheme.outline;
    }
  }
}
