import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/enhanced_order_placement_provider.dart';
import '../../data/services/enhanced_order_placement_service.dart';
import '../../data/models/order.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/widgets/custom_button.dart';

/// Enhanced order confirmation screen with comprehensive order details
class EnhancedOrderConfirmationScreen extends ConsumerStatefulWidget {
  final String? orderId;
  final OrderConfirmation? confirmation;

  const EnhancedOrderConfirmationScreen({
    super.key,
    this.orderId,
    this.confirmation,
  });

  @override
  ConsumerState<EnhancedOrderConfirmationScreen> createState() => _EnhancedOrderConfirmationScreenState();
}

class _EnhancedOrderConfirmationScreenState extends ConsumerState<EnhancedOrderConfirmationScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  final AppLogger _logger = AppLogger();

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orderConfirmation = widget.confirmation ?? ref.watch(lastOrderConfirmationProvider);
    final lastOrder = ref.watch(lastOrderProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildSuccessHeader(theme),
                const SizedBox(height: 32),
                if (orderConfirmation != null) ...[
                  _buildOrderSummary(theme, orderConfirmation),
                  const SizedBox(height: 24),
                  if (lastOrder != null) _buildOrderDetails(theme, lastOrder),
                  const SizedBox(height: 24),
                  _buildDeliveryInfo(theme, orderConfirmation),
                  const SizedBox(height: 24),
                  _buildTrackingInfo(theme, orderConfirmation),
                ] else ...[
                  _buildNoOrderInfo(theme),
                ],
                const SizedBox(height: 40),
                _buildActionButtons(theme),
                const SizedBox(height: 24),
                _buildFooterMessage(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessHeader(ThemeData theme) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.check_circle,
              size: 60,
              color: theme.colorScheme.onTertiary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Order Confirmed!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Thank you for your order. We\'re preparing it now!',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(ThemeData theme, OrderConfirmation confirmation) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Order Summary',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(theme, 'Order Number', confirmation.orderNumber),
          _buildSummaryRow(theme, 'Restaurant', confirmation.vendorName),
          _buildSummaryRow(theme, 'Customer', confirmation.customerName),
          _buildSummaryRow(theme, 'Total Amount', 'RM ${confirmation.totalAmount.toStringAsFixed(2)}'),
          _buildSummaryRow(theme, 'Order Time', _formatDateTime(confirmation.createdAt)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(ThemeData theme, Order order) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shopping_bag,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Order Items',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...order.items.map((item) => _buildOrderItem(theme, item)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(ThemeData theme, OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.quantity}x ${item.name}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.description.isNotEmpty)
                  Text(
                    item.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (item.customizations?.isNotEmpty == true)
                  Text(
                    'Customizations: ${item.customizations!.values.join(', ')}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            'RM ${item.totalPrice.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo(ThemeData theme, OrderConfirmation confirmation) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.delivery_dining,
                color: theme.colorScheme.tertiary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Delivery Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Estimated Delivery:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatDateTime(confirmation.estimatedDeliveryTime),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            confirmation.confirmationMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingInfo(ThemeData theme, OrderConfirmation confirmation) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.track_changes,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Track Your Order',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'You can track your order status in real-time using the tracking link below.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Track Order',
            onPressed: () => _trackOrder(confirmation.trackingUrl),
            variant: ButtonVariant.outlined,
            icon: Icons.open_in_new,
          ),
        ],
      ),
    );
  }

  Widget _buildNoOrderInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Order Information Not Available',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'We couldn\'t load your order confirmation details. Please check your order history.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        CustomButton(
          text: 'View Order History',
          onPressed: _viewOrderHistory,
          variant: ButtonVariant.primary,
          icon: Icons.history,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'Continue Shopping',
          onPressed: _continueShopping,
          variant: ButtonVariant.outlined,
          icon: Icons.shopping_cart,
        ),
      ],
    );
  }

  Widget _buildFooterMessage(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You will receive SMS and push notifications about your order status.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final orderDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (orderDay == today) {
      dateStr = 'Today';
    } else if (orderDay == today.add(const Duration(days: 1))) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    
    return '$dateStr at $timeStr';
  }

  void _trackOrder(String trackingUrl) {
    _logger.info('📱 [ORDER-CONFIRMATION] Opening tracking URL: $trackingUrl');
    
    // TODO: Implement deep link handling or web view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tracking URL: $trackingUrl'),
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () {
            // TODO: Copy to clipboard
          },
        ),
      ),
    );
  }

  void _viewOrderHistory() {
    _logger.info('📋 [ORDER-CONFIRMATION] Navigating to customer order history');
    // Navigate to the enhanced customer orders screen
    context.go('/customer/orders');
  }

  void _continueShopping() {
    _logger.info('🛒 [ORDER-CONFIRMATION] Continuing shopping');
    context.go('/vendors');
  }
}
