import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/promotional_credit.dart';

/// Promotional credits card widget
class PromotionalCreditsCard extends StatelessWidget {
  final List<PromotionalCredit> promotionalCredits;

  const PromotionalCreditsCard({
    super.key,
    required this.promotionalCredits,
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
                    color: AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_offer,
                    color: AppTheme.warningColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Promotional Credits',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (promotionalCredits.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${promotionalCredits.length}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (promotionalCredits.isEmpty)
              _buildEmptyState(context)
            else
              _buildCreditsList(context),
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
          Icons.local_offer_outlined,
          size: 32,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 8),
        Text(
          'No active promotions',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Check back later for special offers',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildCreditsList(BuildContext context) {
    final theme = Theme.of(context);
    final displayCredits = promotionalCredits.take(3).toList();

    return Column(
      children: [
        ...displayCredits.map((credit) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildCreditItem(context, credit),
        )),
        if (promotionalCredits.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+${promotionalCredits.length - 3} more credits',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.warningColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        
        // Total available credits
        if (promotionalCredits.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.successColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: AppTheme.successColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Available',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          _getTotalAvailableCredits(),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCreditItem(BuildContext context, PromotionalCredit credit) {
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
              color: _getCreditTypeColor(credit.creditType).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCreditTypeIcon(credit.creditType),
              color: _getCreditTypeColor(credit.creditType),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  credit.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      credit.formattedRemainingAmount,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${credit.formattedExpiration}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Active',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.successColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTotalAvailableCredits() {
    final total = promotionalCredits.fold<double>(
      0.0,
      (sum, credit) => sum + credit.remainingAmount,
    );
    return 'RM ${total.toStringAsFixed(2)}';
  }

  Color _getCreditTypeColor(PromotionalCreditType type) {
    switch (type) {
      case PromotionalCreditType.welcomeBonus:
        return AppTheme.primaryColor;
      case PromotionalCreditType.seasonalPromo:
        return AppTheme.warningColor;
      case PromotionalCreditType.vendorPromo:
        return AppTheme.infoColor;
      case PromotionalCreditType.loyaltyBonus:
        return AppTheme.successColor;
      case PromotionalCreditType.referralBonus:
        return Colors.purple;
      case PromotionalCreditType.compensationCredit:
        return AppTheme.errorColor;
      case PromotionalCreditType.birthdayBonus:
        return Colors.pink;
      case PromotionalCreditType.anniversaryBonus:
        return Colors.orange;
    }
  }

  IconData _getCreditTypeIcon(PromotionalCreditType type) {
    switch (type) {
      case PromotionalCreditType.welcomeBonus:
        return Icons.waving_hand;
      case PromotionalCreditType.seasonalPromo:
        return Icons.celebration;
      case PromotionalCreditType.vendorPromo:
        return Icons.store;
      case PromotionalCreditType.loyaltyBonus:
        return Icons.stars;
      case PromotionalCreditType.referralBonus:
        return Icons.people;
      case PromotionalCreditType.compensationCredit:
        return Icons.support_agent;
      case PromotionalCreditType.birthdayBonus:
        return Icons.cake;
      case PromotionalCreditType.anniversaryBonus:
        return Icons.emoji_events;
    }
  }
}
