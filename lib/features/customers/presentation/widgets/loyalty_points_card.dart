import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/loyalty_account.dart';

class LoyaltyPointsCard extends StatelessWidget {
  final LoyaltyAccount? loyaltyAccount;

  const LoyaltyPointsCard({
    super.key,
    this.loyaltyAccount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loyaltyAccount == null) {
      return _buildEmptyCard(context);
    }

    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with tier and points
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loyalty Points',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loyaltyAccount!.formattedAvailablePoints,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getTierIcon(loyaltyAccount!.currentTier),
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          loyaltyAccount!.tierDisplayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tier Progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress to ${_getNextTierName(loyaltyAccount!.currentTier)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      Text(
                        '${loyaltyAccount!.tierProgress}/${loyaltyAccount!.nextTierRequirement}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: loyaltyAccount!.tierProgressPercentage,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Points breakdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildPointsStat(
                        context,
                        'Total Earned',
                        loyaltyAccount!.lifetimeEarnedPoints,
                        Icons.trending_up,
                        Colors.green,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    Expanded(
                      child: _buildPointsStat(
                        context,
                        'Total Redeemed',
                        loyaltyAccount!.lifetimeRedeemedPoints,
                        Icons.redeem,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.stars_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Loyalty Account Not Found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start ordering to earn loyalty points and unlock rewards',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsStat(
    BuildContext context,
    String label,
    int value,
    IconData icon,
    Color iconColor,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  IconData _getTierIcon(LoyaltyTier tier) {
    switch (tier) {
      case LoyaltyTier.bronze:
        return Icons.looks_one;
      case LoyaltyTier.silver:
        return Icons.looks_two;
      case LoyaltyTier.gold:
        return Icons.looks_3;
      case LoyaltyTier.platinum:
        return Icons.looks_4;
      case LoyaltyTier.diamond:
        return Icons.looks_5;
    }
  }

  String _getNextTierName(LoyaltyTier currentTier) {
    switch (currentTier) {
      case LoyaltyTier.bronze:
        return 'Silver';
      case LoyaltyTier.silver:
        return 'Gold';
      case LoyaltyTier.gold:
        return 'Platinum';
      case LoyaltyTier.platinum:
        return 'Diamond';
      case LoyaltyTier.diamond:
        return 'Max Level';
    }
  }
}
