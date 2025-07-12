import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/enhanced_cart_models.dart';
import '../providers/enhanced_cart_provider.dart';
import '../controllers/cart_operations_controller.dart';
import '../providers/delivery_pricing_provider.dart';
import '../../../core/utils/logger.dart';

/// Enhanced cart summary widget with comprehensive pricing breakdown
class EnhancedCartSummaryWidget extends ConsumerWidget {
  final bool showPromoCode;
  final bool showDeliveryFee;
  final bool showTaxBreakdown;
  final bool isCompact;
  final VoidCallback? onPromoCodeTap;

  const EnhancedCartSummaryWidget({
    super.key,
    this.showPromoCode = true,
    this.showDeliveryFee = true,
    this.showTaxBreakdown = true,
    this.isCompact = false,
    this.onPromoCodeTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cartState = ref.watch(enhancedCartProvider);
    final operationsState = ref.watch(cartOperationsControllerProvider);

    if (cartState.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            SizedBox(height: isCompact ? 8 : 12),
            _buildOrderSummary(theme, cartState),
            if (showPromoCode) ...[
              SizedBox(height: isCompact ? 8 : 12),
              _buildPromoCodeSection(theme, operationsState),
            ],
            if (showDeliveryFee) ...[
              SizedBox(height: isCompact ? 8 : 12),
              _buildDeliverySection(theme, cartState),
            ],
            if (showTaxBreakdown) ...[
              SizedBox(height: isCompact ? 8 : 12),
              _buildTaxSection(theme, cartState),
            ],
            SizedBox(height: isCompact ? 8 : 12),
            _buildDivider(theme),
            SizedBox(height: isCompact ? 8 : 12),
            _buildTotalSection(theme, cartState),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.receipt_long,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'Order Summary',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(ThemeData theme, EnhancedCartState cartState) {
    return Column(
      children: [
        _buildSummaryRow(
          theme,
          'Subtotal (${cartState.totalItems} items)',
          'RM ${cartState.subtotal.toStringAsFixed(2)}',
        ),
        if (cartState.customizationTotal > 0) ...[
          const SizedBox(height: 4),
          _buildSummaryRow(
            theme,
            'Customizations',
            '+RM ${cartState.customizationTotal.toStringAsFixed(2)}',
            isSecondary: true,
          ),
        ],
      ],
    );
  }

  Widget _buildPromoCodeSection(ThemeData theme, CartOperationsState operationsState) {
    final appliedPromoCode = operationsState.appliedPromoCode;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appliedPromoCode != null
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: appliedPromoCode != null
            ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: appliedPromoCode != null
          ? _buildAppliedPromoCode(theme, appliedPromoCode)
          : _buildPromoCodeInput(theme),
    );
  }

  Widget _buildAppliedPromoCode(ThemeData theme, String promoCode) {
    return Row(
      children: [
        Icon(
          Icons.local_offer,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Promo Code Applied',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                promoCode.toUpperCase(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _removePromoCode(),
          icon: Icon(
            Icons.close,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        ),
      ],
    );
  }

  Widget _buildPromoCodeInput(ThemeData theme) {
    return InkWell(
      onTap: onPromoCodeTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Add promo code',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySection(ThemeData theme, EnhancedCartState cartState) {
    return Consumer(
      builder: (context, ref, child) {
        // Watch the delivery pricing provider for consistency
        final pricingState = ref.watch(deliveryPricingProvider);

        // Use pricing provider data if available, otherwise fall back to cart state
        final deliveryFee = pricingState.calculation?.finalFee ?? cartState.deliveryFee;
        final isFree = deliveryFee <= 0;

        return Column(
          children: [
            _buildSummaryRow(
              theme,
              'Delivery Fee',
              isFree ? 'FREE' : 'RM ${deliveryFee.toStringAsFixed(2)}',
              isHighlight: isFree,
            ),
            // Show calculation status if pricing is being calculated
            if (pricingState.isCalculating) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Updating...',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTaxSection(ThemeData theme, EnhancedCartState cartState) {
    return _buildSummaryRow(
      theme,
      'SST (6%)',
      'RM ${cartState.sstAmount.toStringAsFixed(2)}',
      isSecondary: true,
    );
  }

  Widget _buildTotalSection(ThemeData theme, EnhancedCartState cartState) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Total Amount',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            'RM ${cartState.totalAmount.toStringAsFixed(2)}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    ThemeData theme,
    String label,
    String value, {
    bool isSecondary = false,
    bool isHighlight = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: isSecondary
                ? theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )
                : theme.textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: isHighlight
              ? theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                )
              : isSecondary
                  ? theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )
                  : theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
        ),
      ],
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Container(
      height: 1,
      color: theme.colorScheme.outline.withValues(alpha: 0.2),
    );
  }

  void _removePromoCode() {
    // TODO: Implement promo code removal
    AppLogger().info('🎫 [CART-SUMMARY] Removing promo code');
  }
}

/// Compact cart summary for bottom sheets or small spaces
class CompactCartSummary extends StatelessWidget {
  final EnhancedCartState cartState;
  final VoidCallback? onTap;

  const CompactCartSummary({
    super.key,
    required this.cartState,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (cartState.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.shopping_cart,
                size: 20,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${cartState.totalItems} items',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'RM ${cartState.totalAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
