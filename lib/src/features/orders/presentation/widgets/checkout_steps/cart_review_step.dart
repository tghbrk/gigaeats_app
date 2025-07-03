import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../enhanced_cart_item_widget.dart';
import '../enhanced_cart_summary_widget.dart';
import '../../providers/enhanced_cart_provider.dart';
import '../../providers/checkout_flow_provider.dart';
import '../../../../core/utils/logger.dart';

/// Cart review step in checkout flow
class CartReviewStep extends ConsumerStatefulWidget {
  const CartReviewStep({super.key});

  @override
  ConsumerState<CartReviewStep> createState() => _CartReviewStepState();
}

class _CartReviewStepState extends ConsumerState<CartReviewStep>
    with AutomaticKeepAliveClientMixin {
  final AppLogger _logger = AppLogger();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final theme = Theme.of(context);
    final cartState = ref.watch(enhancedCartProvider);
    final checkoutState = ref.watch(checkoutFlowProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 24),
          _buildVendorInfo(theme, cartState),
          const SizedBox(height: 24),
          _buildCartItems(theme, cartState),
          const SizedBox(height: 24),
          _buildCartSummary(theme),
          const SizedBox(height: 24),
          _buildValidationStatus(theme, checkoutState),
          const SizedBox(height: 100), // Space for bottom navigation
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.shopping_cart,
                size: 24,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review Your Order',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Check your items and quantities before proceeding',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVendorInfo(ThemeData theme, dynamic cartState) {
    if (cartState.isEmpty) return const SizedBox.shrink();

    final vendorName = cartState.items.first.vendorName;
    final hasMultipleVendors = cartState.hasMultipleVendors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasMultipleVendors
            ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
            : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasMultipleVendors
              ? theme.colorScheme.error.withValues(alpha: 0.3)
              : theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasMultipleVendors ? Icons.warning : Icons.store,
            color: hasMultipleVendors 
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasMultipleVendors ? 'Multiple Vendors' : 'Order from',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  hasMultipleVendors 
                      ? 'Please checkout vendors separately'
                      : vendorName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: hasMultipleVendors 
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          if (hasMultipleVendors)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Action Required',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartItems(ThemeData theme, dynamic cartState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Items (${cartState.totalItems})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _editCart(),
              icon: Icon(
                Icons.edit,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              label: Text(
                'Edit Cart',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...cartState.items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: EnhancedCartItemWidget(
            key: ValueKey(item.id),
            item: item,
            showQuantityControls: false, // Read-only in review
            showRemoveButton: false,
            onTap: () => _showItemDetails(item),
          ),
        )),
      ],
    );
  }

  Widget _buildCartSummary(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Summary',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        const EnhancedCartSummaryWidget(
          showPromoCode: false, // Promo codes handled in payment step
          isCompact: false,
        ),
      ],
    );
  }

  Widget _buildValidationStatus(ThemeData theme, CheckoutFlowState checkoutState) {
    final isValid = checkoutState.isCartValid;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isValid
            ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid
              ? theme.colorScheme.tertiary.withValues(alpha: 0.3)
              : theme.colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.error,
            color: isValid 
                ? theme.colorScheme.tertiary
                : theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isValid ? 'Order Ready' : 'Issues Found',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isValid 
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.error,
                  ),
                ),
                Text(
                  isValid 
                      ? 'Your order is ready to proceed to delivery details'
                      : 'Please resolve the issues above before continuing',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editCart() {
    _logger.info('✏️ [CART-REVIEW] Navigating to cart for editing');
    // Navigate back to cart screen for editing
    Navigator.of(context).pushNamed('/customer/cart');
  }

  void _showItemDetails(dynamic item) {
    _logger.info('👁️ [CART-REVIEW] Showing item details for: ${item.name}');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildItemDetailsSheet(item),
    );
  }

  Widget _buildItemDetailsSheet(dynamic item) {
    final theme = Theme.of(context);
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Item Details',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Item details
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EnhancedCartItemWidget(
                    item: item,
                    showQuantityControls: false,
                    showRemoveButton: false,
                    showCustomizations: true,
                  ),
                  const SizedBox(height: 16),
                  if (item.notes != null && item.notes!.isNotEmpty) ...[
                    Text(
                      'Special Instructions',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.notes!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
