import 'package:flutter/material.dart';
import '../../data/models/loyalty_program.dart';

class LoyaltyRewardCard extends StatelessWidget {
  final LoyaltyReward reward;
  final bool canAfford;
  final VoidCallback onRedeem;

  const LoyaltyRewardCard({
    super.key,
    required this.reward,
    required this.canAfford,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: canAfford ? 2 : 1,
      child: Opacity(
        opacity: canAfford ? 1.0 : 0.6,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Reward icon/image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getRewardTypeColor(reward.rewardType.name).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getRewardTypeIcon(reward.rewardType.name),
                      color: _getRewardTypeColor(reward.rewardType.name),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Reward details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reward.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reward.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        
                        // Points required
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.stars,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${reward.pointsRequired} points',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Reward value and action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Reward value
                  if (reward.discountValue != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        reward.discountType == 'percentage'
                            ? '${reward.discountValue!.toInt()}% OFF'
                            : 'RM ${reward.discountValue!.toStringAsFixed(2)} OFF',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  
                  // Redeem button
                  ElevatedButton(
                    onPressed: canAfford ? onRedeem : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAfford 
                          ? theme.colorScheme.primary 
                          : Colors.grey,
                      foregroundColor: canAfford 
                          ? theme.colorScheme.onPrimary 
                          : Colors.grey[600],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      canAfford ? 'Redeem' : 'Not enough points',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Expiry info
              if (reward.expiresAt != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Expires ${_formatDate(reward.expiresAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ],
              
              // Terms and conditions
              if (reward.termsAndConditions != null) ...[
                const SizedBox(height: 8),
                ExpansionTile(
                  title: Text(
                    'Terms & Conditions',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        reward.termsAndConditions!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getRewardTypeColor(String rewardType) {
    switch (rewardType.toLowerCase()) {
      case 'discount':
        return Colors.green;
      case 'free_delivery':
        return Colors.blue;
      case 'cashback':
        return Colors.purple;
      case 'free_item':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getRewardTypeIcon(String rewardType) {
    switch (rewardType.toLowerCase()) {
      case 'discount':
        return Icons.local_offer;
      case 'free_delivery':
        return Icons.delivery_dining;
      case 'cashback':
        return Icons.account_balance_wallet;
      case 'free_item':
        return Icons.card_giftcard;
      default:
        return Icons.redeem;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'today';
    } else if (difference == 1) {
      return 'tomorrow';
    } else if (difference < 7) {
      return 'in $difference days';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
