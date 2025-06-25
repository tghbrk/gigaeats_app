import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/reward_program.dart';

/// Rewards catalog card widget
class RewardsCatalogCard extends StatelessWidget {
  final List<RewardProgram> featuredRewards;
  final VoidCallback? onViewAll;

  const RewardsCatalogCard({
    super.key,
    required this.featuredRewards,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.redeem,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rewards',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onViewAll != null)
                  Flexible(
                    child: TextButton(
                      onPressed: onViewAll,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'View All',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (featuredRewards.isEmpty)
              _buildEmptyState(context)
            else
              _buildRewardsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          Icons.redeem_outlined,
          size: 32,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 8),
        Text(
          'No rewards available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildRewardsList(BuildContext context) {
    final theme = Theme.of(context);
    final displayRewards = featuredRewards.take(3).toList();

    return Column(
      children: [
        ...displayRewards.map((reward) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildRewardItem(context, reward),
        )),
        if (featuredRewards.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+${featuredRewards.length - 3} more rewards',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRewardItem(BuildContext context, RewardProgram reward) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getRewardTypeColor(reward.rewardType).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getRewardTypeIcon(reward.rewardType),
              color: _getRewardTypeColor(reward.rewardType),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  reward.formattedPointsCost,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (reward.isCurrentlyAvailable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Available',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Unavailable',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getRewardTypeColor(RewardType type) {
    switch (type) {
      case RewardType.discount:
        return AppTheme.primaryColor;
      case RewardType.cashback:
        return AppTheme.successColor;
      case RewardType.freeItem:
        return AppTheme.warningColor;
      case RewardType.pointsMultiplier:
        return AppTheme.infoColor;
      case RewardType.tierUpgrade:
        return Colors.purple;
      case RewardType.freeDelivery:
        return Colors.orange;
      case RewardType.voucher:
        return Colors.teal;
    }
  }

  IconData _getRewardTypeIcon(RewardType type) {
    switch (type) {
      case RewardType.discount:
        return Icons.percent;
      case RewardType.cashback:
        return Icons.account_balance_wallet;
      case RewardType.freeItem:
        return Icons.free_breakfast;
      case RewardType.pointsMultiplier:
        return Icons.trending_up;
      case RewardType.tierUpgrade:
        return Icons.upgrade;
      case RewardType.freeDelivery:
        return Icons.local_shipping;
      case RewardType.voucher:
        return Icons.card_giftcard;
    }
  }
}
