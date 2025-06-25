import 'package:flutter/material.dart';
import '../../data/models/loyalty_program.dart';

class LoyaltyTierCard extends StatelessWidget {
  final LoyaltyTier currentTier;
  final LoyaltyTier? nextTier;
  final int pointsToNextTier;

  const LoyaltyTierCard({
    super.key,
    required this.currentTier,
    this.nextTier,
    required this.pointsToNextTier,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: _getTierColor(currentTier.name),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Tier',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Current tier info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getTierColor(currentTier.name).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getTierColor(currentTier.name).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getTierIcon(currentTier.name),
                    color: _getTierColor(currentTier.name),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentTier.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getTierColor(currentTier.name),
                          ),
                        ),
                        if (currentTier.description != null)
                          Text(
                            currentTier.description!,
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Progress to next tier
            if (nextTier != null) ...[
              const SizedBox(height: 16),
              Text(
                'Progress to ${nextTier!.name}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              
              LinearProgressIndicator(
                value: _calculateProgress(),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getTierColor(nextTier!.name),
                ),
              ),
              const SizedBox(height: 8),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$pointsToNextTier points to go',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    '${nextTier!.minimumPoints} points needed',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Congratulations! You\'ve reached the highest tier!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _calculateProgress() {
    if (nextTier == null) return 1.0;
    
    final currentPoints = nextTier!.minimumPoints - pointsToNextTier;
    final totalNeeded = nextTier!.minimumPoints - currentTier.minimumPoints;
    
    if (totalNeeded <= 0) return 1.0;
    
    return (currentPoints - currentTier.minimumPoints) / totalNeeded;
  }

  Color _getTierColor(String tierName) {
    switch (tierName.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'platinum':
        return const Color(0xFFE5E4E2);
      case 'diamond':
        return const Color(0xFFB9F2FF);
      default:
        return Colors.grey;
    }
  }

  IconData _getTierIcon(String tierName) {
    switch (tierName.toLowerCase()) {
      case 'bronze':
        return Icons.looks_3;
      case 'silver':
        return Icons.looks_two;
      case 'gold':
        return Icons.looks_one;
      case 'platinum':
        return Icons.star;
      case 'diamond':
        return Icons.diamond;
      default:
        return Icons.star_border;
    }
  }
}
