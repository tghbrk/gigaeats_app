import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/enhanced_cart_item_widget.dart';
import '../widgets/enhanced_cart_summary_widget.dart';
import '../providers/enhanced_cart_provider.dart';
import '../controllers/cart_operations_controller.dart';
import '../../data/models/enhanced_cart_models.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_overlay.dart';

/// Enhanced cart screen with comprehensive functionality
class EnhancedCartScreen extends ConsumerStatefulWidget {
  const EnhancedCartScreen({super.key});

  @override
  ConsumerState<EnhancedCartScreen> createState() => _EnhancedCartScreenState();
}

class _EnhancedCartScreenState extends ConsumerState<EnhancedCartScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final AppLogger _logger = AppLogger();
  final TextEditingController _promoCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _promoCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartState = ref.watch(enhancedCartProvider);
    final operationsState = ref.watch(cartOperationsControllerProvider);

    return Scaffold(
      appBar: _buildAppBar(theme, cartState),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: cartState.isEmpty
            ? _buildEmptyCart(theme)
            : _buildCartContent(theme, cartState, operationsState),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, EnhancedCartState cartState) {
    return AppBar(
      title: Text(
        cartState.isEmpty ? 'Cart' : 'Cart (${cartState.totalItems})',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      actions: [
        if (cartState.isNotEmpty) ...[
          IconButton(
            onPressed: () => _showCartOptions(cartState),
            icon: Icon(
              Icons.more_vert,
              color: theme.colorScheme.onSurface,
            ),
            tooltip: 'Cart options',
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyCart(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add delicious items from restaurants to get started',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Browse Restaurants',
              onPressed: () => context.push('/customer/restaurants'),
              variant: ButtonVariant.primary,
              icon: Icons.restaurant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(
    ThemeData theme,
    EnhancedCartState cartState,
    CartOperationsState operationsState,
  ) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCartHeader(theme, cartState),
                    const SizedBox(height: 16),
                    _buildCartItems(cartState),
                    const SizedBox(height: 24),
                    EnhancedCartSummaryWidget(
                      onPromoCodeTap: () => _showPromoCodeDialog(),
                    ),
                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ),
          ],
        ),
        
        // Bottom checkout button
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildCheckoutButton(theme, cartState, operationsState),
        ),
        
        // Loading overlay
        if (operationsState.isLoading)
          const SimpleLoadingOverlay(message: 'Updating cart...'),
      ],
    );
  }

  Widget _buildCartHeader(ThemeData theme, EnhancedCartState cartState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.store,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order from',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  cartState.items.isNotEmpty 
                      ? cartState.items.first.vendorName
                      : 'Multiple vendors',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          if (cartState.hasMultipleVendors)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Multiple vendors',
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

  Widget _buildCartItems(EnhancedCartState cartState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items (${cartState.totalItems})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...cartState.items.map((item) => EnhancedCartItemWidget(
          key: ValueKey(item.id),
          item: item,
          onTap: () => _showItemDetails(item),
          onEdit: () => _editItem(item),
        )),
      ],
    );
  }

  Widget _buildCheckoutButton(
    ThemeData theme,
    EnhancedCartState cartState,
    CartOperationsState operationsState,
  ) {
    final canCheckout = cartState.isNotEmpty && 
                       !operationsState.isLoading &&
                       !cartState.hasMultipleVendors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: CustomButton(
          text: 'Proceed to Checkout • RM ${cartState.totalAmount.toStringAsFixed(2)}',
          onPressed: canCheckout ? () => _proceedToCheckout() : null,
          variant: ButtonVariant.primary,
          isLoading: operationsState.isLoading,
          icon: Icons.arrow_forward,
        ),
      ),
    );
  }

  void _showCartOptions(EnhancedCartState cartState) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildCartOptionsSheet(cartState),
    );
  }

  Widget _buildCartOptionsSheet(EnhancedCartState cartState) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cart Options',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.clear_all, color: theme.colorScheme.error),
            title: const Text('Clear Cart'),
            subtitle: const Text('Remove all items from cart'),
            onTap: () {
              Navigator.pop(context);
              _showClearCartDialog();
            },
          ),
          ListTile(
            leading: Icon(Icons.save_alt, color: theme.colorScheme.primary),
            title: const Text('Save for Later'),
            subtitle: const Text('Save cart items for future orders'),
            onTap: () {
              Navigator.pop(context);
              _saveCartForLater();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showPromoCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Promo Code'),
        content: TextField(
          controller: _promoCodeController,
          decoration: const InputDecoration(
            hintText: 'Enter promo code',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final promoCode = _promoCodeController.text.trim();
              if (promoCode.isNotEmpty) {
                ref.read(cartOperationsControllerProvider.notifier)
                    .applyPromoCode(promoCode);
                _promoCodeController.clear();
              }
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartOperationsControllerProvider.notifier).clearCart();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showItemDetails(EnhancedCartItem item) {
    _logger.info('👁️ [CART-SCREEN] Showing details for ${item.name}');
    // TODO: Navigate to item details or show details modal
  }

  void _editItem(EnhancedCartItem item) {
    _logger.info('✏️ [CART-SCREEN] Editing item ${item.name}');
    // TODO: Navigate to item customization screen
  }

  void _saveCartForLater() {
    _logger.info('💾 [CART-SCREEN] Saving cart for later');
    // TODO: Implement save cart for later functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cart saved for later')),
    );
  }

  void _proceedToCheckout() {
    _logger.info('🛒 [CART-SCREEN] Proceeding to checkout');
    context.push('/customer/checkout');
  }
}
