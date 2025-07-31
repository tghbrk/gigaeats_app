import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/driver_wallet_transaction.dart';
import '../../providers/driver_wallet_transaction_provider.dart';

/// Statistics card for driver wallet transactions
class DriverTransactionStatsCard extends ConsumerWidget {
  const DriverTransactionStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final transactionState = ref.watch(driverWalletTransactionProvider);

    final stats = _calculateStats(transactionState.transactions);

    debugPrint('📊 [DRIVER-TRANSACTION-STATS] Building stats card');
    debugPrint('📊 [DRIVER-TRANSACTION-STATS] Transaction count: ${stats['totalCount']}');
    debugPrint('📊 [DRIVER-TRANSACTION-STATS] Total credits: ${stats['totalCredits']}');
    debugPrint('📊 [DRIVER-TRANSACTION-STATS] Total debits: ${stats['totalDebits']}');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Transaction Statistics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Stats grid - Fixed aspect ratio to prevent overflow
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.2, // Reduced from 2.5 to 2.2 to provide more height
              children: [
                _buildStatItem(
                  theme,
                  'Total Transactions',
                  stats['totalCount'].toString(),
                  Icons.receipt_long,
                  theme.colorScheme.primary,
                ),
                _buildStatItem(
                  theme,
                  'Total Credits',
                  'RM ${stats['totalCredits'].toStringAsFixed(2)}',
                  Icons.add_circle,
                  Colors.green,
                ),
                _buildStatItem(
                  theme,
                  'Total Debits',
                  'RM ${stats['totalDebits'].toStringAsFixed(2)}',
                  Icons.remove_circle,
                  Colors.red,
                ),
                _buildStatItem(
                  theme,
                  'Average Amount',
                  'RM ${stats['averageAmount'].toStringAsFixed(2)}',
                  Icons.trending_up,
                  Colors.blue,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Transaction type breakdown
            _buildTransactionTypeBreakdown(theme, stats['typeBreakdown']),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    debugPrint('📊 [DRIVER-TRANSACTION-STATS] Building stat item: $label = $value');

    return Container(
      padding: const EdgeInsets.all(10), // Reduced padding from 12 to 10
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Added to prevent overflow
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 14, // Reduced icon size from 16 to 14
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontSize: 11, // Reduced font size for better fit
                  ),
                  maxLines: 2, // Allow 2 lines for longer labels
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2), // Reduced spacing from 4 to 2
          Flexible( // Added Flexible to prevent overflow
            child: Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith( // Changed from titleMedium to titleSmall
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13, // Explicit smaller font size
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTypeBreakdown(
    ThemeData theme,
    Map<DriverWalletTransactionType, int> breakdown,
  ) {
    if (breakdown.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Types',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        ...breakdown.entries.map((entry) {
          final type = entry.key;
          final count = entry.value;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text(
                  type.icon,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    type.displayName,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Map<String, dynamic> _calculateStats(List<DriverWalletTransaction> transactions) {
    if (transactions.isEmpty) {
      return {
        'totalCount': 0,
        'totalCredits': 0.0,
        'totalDebits': 0.0,
        'averageAmount': 0.0,
        'typeBreakdown': <DriverWalletTransactionType, int>{},
      };
    }

    double totalCredits = 0.0;
    double totalDebits = 0.0;
    final typeBreakdown = <DriverWalletTransactionType, int>{};

    for (final transaction in transactions) {
      if (transaction.isCredit) {
        totalCredits += transaction.amount;
      } else {
        totalDebits += transaction.amount.abs();
      }

      typeBreakdown[transaction.transactionType] = 
          (typeBreakdown[transaction.transactionType] ?? 0) + 1;
    }

    final totalAmount = totalCredits + totalDebits;
    final averageAmount = totalAmount / transactions.length;

    return {
      'totalCount': transactions.length,
      'totalCredits': totalCredits,
      'totalDebits': totalDebits,
      'averageAmount': averageAmount,
      'typeBreakdown': typeBreakdown,
    };
  }
}
