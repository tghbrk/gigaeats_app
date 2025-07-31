import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/driver_withdrawal_request.dart';
import '../../providers/driver_withdrawal_provider.dart';

/// Statistics card widget for withdrawal history
class WithdrawalHistoryStatsCard extends ConsumerWidget {
  const WithdrawalHistoryStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final withdrawalState = ref.watch(driverWithdrawalProvider);
    final stats = _calculateStats(withdrawalState.withdrawalRequests ?? []);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Withdrawal Statistics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Statistics grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5,
              children: [
                _buildStatItem(
                  context,
                  title: 'Total Requests',
                  value: stats['totalRequests'].toString(),
                  icon: Icons.receipt_long,
                  color: theme.colorScheme.primary,
                ),
                _buildStatItem(
                  context,
                  title: 'Total Amount',
                  value: 'RM ${stats['totalAmount'].toStringAsFixed(2)}',
                  icon: Icons.account_balance_wallet,
                  color: Colors.green,
                ),
                _buildStatItem(
                  context,
                  title: 'Completed',
                  value: stats['completedRequests'].toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                _buildStatItem(
                  context,
                  title: 'Pending',
                  value: stats['pendingRequests'].toString(),
                  icon: Icons.schedule,
                  color: Colors.orange,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Status breakdown
            _buildStatusBreakdown(context, stats),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBreakdown(BuildContext context, Map<String, dynamic> stats) {
    final theme = Theme.of(context);
    final totalRequests = stats['totalRequests'] as int;
    
    if (totalRequests == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status Breakdown',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        // Status indicators
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildStatusIndicator(
              context,
              status: 'Completed',
              count: stats['completedRequests'],
              total: totalRequests,
              color: Colors.green,
            ),
            _buildStatusIndicator(
              context,
              status: 'Pending',
              count: stats['pendingRequests'],
              total: totalRequests,
              color: Colors.orange,
            ),
            _buildStatusIndicator(
              context,
              status: 'Processing',
              count: stats['processingRequests'],
              total: totalRequests,
              color: Colors.blue,
            ),
            _buildStatusIndicator(
              context,
              status: 'Failed',
              count: stats['failedRequests'],
              total: totalRequests,
              color: Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(
    BuildContext context, {
    required String status,
    required int count,
    required int total,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final percentage = total > 0 ? (count / total * 100).round() : 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$status ($count)',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          '$percentage%',
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _calculateStats(List<DriverWithdrawalRequest> requests) {
    if (requests.isEmpty) {
      return {
        'totalRequests': 0,
        'totalAmount': 0.0,
        'completedRequests': 0,
        'pendingRequests': 0,
        'processingRequests': 0,
        'failedRequests': 0,
        'cancelledRequests': 0,
      };
    }

    final totalRequests = requests.length;
    final totalAmount = requests.fold<double>(0.0, (sum, request) => sum + request.amount);
    
    final completedRequests = requests.where((r) => r.status == DriverWithdrawalStatus.completed).length;
    final pendingRequests = requests.where((r) => r.status == DriverWithdrawalStatus.pending).length;
    final processingRequests = requests.where((r) => r.status == DriverWithdrawalStatus.processing).length;
    final failedRequests = requests.where((r) => r.status == DriverWithdrawalStatus.failed).length;
    final cancelledRequests = requests.where((r) => r.status == DriverWithdrawalStatus.cancelled).length;

    return {
      'totalRequests': totalRequests,
      'totalAmount': totalAmount,
      'completedRequests': completedRequests,
      'pendingRequests': pendingRequests,
      'processingRequests': processingRequests,
      'failedRequests': failedRequests,
      'cancelledRequests': cancelledRequests,
    };
  }
}
