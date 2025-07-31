import 'package:flutter/material.dart';

import '../../../data/models/driver_withdrawal_limits.dart';

/// Widget displaying withdrawal limits and current usage
class WithdrawalLimitsInfo extends StatelessWidget {
  final DriverWithdrawalLimits? limits;
  final Map<String, dynamic>? currentUsage;

  const WithdrawalLimitsInfo({
    super.key,
    this.limits,
    this.currentUsage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (limits == null || currentUsage == null) {
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
                  Icons.security,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Withdrawal Limits',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _buildRiskLevelChip(context, limits!.riskLevel),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Daily limit
            _buildLimitRow(
              context,
              title: 'Daily Limit',
              used: currentUsage!['daily_used']?.toDouble() ?? 0.0,
              limit: limits!.dailyLimit,
              remaining: currentUsage!['daily_remaining']?.toDouble() ?? 0.0,
              icon: Icons.today,
            ),
            
            const SizedBox(height: 12),
            
            // Weekly limit
            _buildLimitRow(
              context,
              title: 'Weekly Limit',
              used: currentUsage!['weekly_used']?.toDouble() ?? 0.0,
              limit: limits!.weeklyLimit,
              remaining: currentUsage!['weekly_remaining']?.toDouble() ?? 0.0,
              icon: Icons.date_range,
            ),
            
            const SizedBox(height: 12),
            
            // Monthly limit
            _buildLimitRow(
              context,
              title: 'Monthly Limit',
              used: currentUsage!['monthly_used']?.toDouble() ?? 0.0,
              limit: limits!.monthlyLimit,
              remaining: currentUsage!['monthly_remaining']?.toDouble() ?? 0.0,
              icon: Icons.calendar_month,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitRow(
    BuildContext context, {
    required String title,
    required double used,
    required double limit,
    required double remaining,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final usagePercentage = limit > 0 ? (used / limit).clamp(0.0, 1.0) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              'RM ${used.toStringAsFixed(2)} / RM ${limit.toStringAsFixed(2)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Progress bar
        LinearProgressIndicator(
          value: usagePercentage,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getProgressColor(theme, usagePercentage),
          ),
        ),
        
        const SizedBox(height: 4),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(usagePercentage * 100).toStringAsFixed(1)}% used',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'RM ${remaining.toStringAsFixed(2)} remaining',
              style: theme.textTheme.bodySmall?.copyWith(
                color: remaining > 0 
                    ? Colors.green 
                    : theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRiskLevelChip(BuildContext context, String riskLevel) {
    final theme = Theme.of(context);
    final color = _getRiskLevelColor(riskLevel);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getRiskLevelIcon(riskLevel),
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${riskLevel.toUpperCase()} RISK',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(ThemeData theme, double percentage) {
    if (percentage < 0.7) {
      return Colors.green;
    } else if (percentage < 0.9) {
      return Colors.orange;
    } else {
      return theme.colorScheme.error;
    }
  }

  Color _getRiskLevelColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getRiskLevelIcon(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return Icons.check_circle;
      case 'medium':
        return Icons.warning;
      case 'high':
        return Icons.error;
      default:
        return Icons.info;
    }
  }
}
