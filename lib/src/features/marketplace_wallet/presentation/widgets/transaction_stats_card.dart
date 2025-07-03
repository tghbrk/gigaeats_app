import 'package:flutter/material.dart';

/// Transaction statistics card widget
class TransactionStatsCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const TransactionStatsCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Transaction Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Statistics grid
            _buildStatsGrid(theme),
            
            const SizedBox(height: 16),
            
            // Transaction breakdown by type
            if (stats['by_type'] != null && (stats['by_type'] as Map).isNotEmpty) ...[
              _buildTransactionBreakdown(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(ThemeData theme) {
    return Row(
      children: [
        // Total transactions
        Expanded(
          child: _buildStatItem(
            theme,
            'Total',
            '${stats['total_transactions'] ?? 0}',
            'transactions',
            Icons.receipt_long,
            theme.colorScheme.primary,
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Total spent
        Expanded(
          child: _buildStatItem(
            theme,
            'Spent',
            'RM ${(stats['total_spent'] ?? 0.0).toStringAsFixed(2)}',
            'total',
            Icons.trending_down,
            theme.colorScheme.error,
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Total received
        Expanded(
          child: _buildStatItem(
            theme,
            'Received',
            'RM ${(stats['total_received'] ?? 0.0).toStringAsFixed(2)}',
            'total',
            Icons.trending_up,
            theme.colorScheme.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
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
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionBreakdown(ThemeData theme) {
    final byType = stats['by_type'] as Map<String, int>;
    final sortedEntries = byType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Breakdown by Type',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 8),
        
        ...sortedEntries.take(5).map((entry) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              // Type indicator
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getTypeColor(theme, entry.key),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Type name
              Expanded(
                child: Text(
                  entry.key,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              
              // Count
              Text(
                '${entry.value}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
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
        return theme.colorScheme.outline;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}
