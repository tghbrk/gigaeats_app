import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/delivery_pricing_provider.dart';
import '../../providers/enhanced_cart_provider.dart';

/// Reusable pricing display widget for consistent delivery fee display across the app
class PricingDisplayWidget extends ConsumerWidget {
  final bool showCalculatingState;
  final bool isCompact;
  final TextStyle? labelStyle;
  final TextStyle? priceStyle;
  final String label;

  const PricingDisplayWidget({
    super.key,
    this.showCalculatingState = true,
    this.isCompact = false,
    this.labelStyle,
    this.priceStyle,
    this.label = 'Delivery Fee',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pricingState = ref.watch(deliveryPricingProvider);
    final cartState = ref.watch(enhancedCartProvider);
    
    // Use pricing provider data if available, otherwise fall back to cart state
    final deliveryFee = pricingState.calculation?.finalFee ?? cartState.deliveryFee;
    final isFree = deliveryFee <= 0;
    final isCalculating = pricingState.isCalculating && showCalculatingState;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: labelStyle ?? theme.textTheme.bodyMedium,
            ),
            if (isCalculating) ...[
              Row(
                children: [
                  SizedBox(
                    width: isCompact ? 10 : 12,
                    height: isCompact ? 10 : 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Calculating...',
                    style: (priceStyle ?? theme.textTheme.bodyMedium)?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: isCompact ? 12 : null,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                isFree ? 'FREE' : 'RM ${deliveryFee.toStringAsFixed(2)}',
                style: (priceStyle ?? theme.textTheme.bodyMedium)?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isFree ? theme.colorScheme.tertiary : null,
                ),
              ),
            ],
          ],
        ),
        if (isCalculating && !isCompact) ...[
          const SizedBox(height: 2),
          LinearProgressIndicator(
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ],
      ],
    );
  }
}

/// Compact version of pricing display for tight spaces
class CompactPricingDisplayWidget extends StatelessWidget {
  final TextStyle? style;

  const CompactPricingDisplayWidget({
    super.key,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return PricingDisplayWidget(
      isCompact: true,
      showCalculatingState: false,
      labelStyle: style,
      priceStyle: style,
    );
  }
}

/// Pricing display with breakdown for detailed views
class DetailedPricingDisplayWidget extends ConsumerWidget {
  final bool showBreakdown;
  final VoidCallback? onBreakdownTap;

  const DetailedPricingDisplayWidget({
    super.key,
    this.showBreakdown = true,
    this.onBreakdownTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pricingState = ref.watch(deliveryPricingProvider);
    
    return Column(
      children: [
        const PricingDisplayWidget(),
        if (showBreakdown && 
            pricingState.calculation != null && 
            pricingState.calculation!.finalFee > 0) ...[
          const SizedBox(height: 4),
          InkWell(
            onTap: onBreakdownTap,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 12,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'View breakdown',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Helper methods for pricing consistency
class PricingDisplayHelper {
  /// Format delivery fee amount consistently across the app
  static String formatDeliveryFee(double amount) {
    if (amount <= 0) return 'FREE';
    return 'RM ${amount.toStringAsFixed(2)}';
  }

  /// Get color for delivery fee display
  static Color? getDeliveryFeeColor(BuildContext context, double amount) {
    if (amount <= 0) {
      return Theme.of(context).colorScheme.tertiary;
    }
    return null;
  }

  /// Get text style for delivery fee display
  static TextStyle? getDeliveryFeeStyle(
    BuildContext context, 
    double amount, {
    TextStyle? baseStyle,
    bool isBold = false,
  }) {
    final theme = Theme.of(context);
    return (baseStyle ?? theme.textTheme.bodyMedium)?.copyWith(
      fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
      color: getDeliveryFeeColor(context, amount),
    );
  }
}
