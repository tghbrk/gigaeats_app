import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/enhanced_cart_provider.dart';
import '../../providers/checkout_flow_provider.dart';
import '../../../data/models/customer_delivery_method.dart';


/// Order confirmation step in checkout flow
class OrderConfirmationStep extends ConsumerStatefulWidget {
  const OrderConfirmationStep({super.key});

  @override
  ConsumerState<OrderConfirmationStep> createState() => _OrderConfirmationStepState();
}

class _OrderConfirmationStepState extends ConsumerState<OrderConfirmationStep>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late AnimationController _successController;
  late Animation<double> _successAnimation;


  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    _successController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _successAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
    
    // Start success animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _successController.forward();
    });
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

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
          _buildSuccessHeader(theme),
          const SizedBox(height: 32),
          _buildOrderDetails(theme, cartState, checkoutState),
          const SizedBox(height: 24),
          _buildDeliveryDetails(theme, checkoutState),
          const SizedBox(height: 24),
          _buildPaymentDetails(theme, checkoutState),
          const SizedBox(height: 24),
          _buildOrderSummary(theme, cartState),
          const SizedBox(height: 24),
          _buildNextSteps(theme),
          const SizedBox(height: 100), // Space for bottom navigation
        ],
      ),
    );
  }

  Widget _buildSuccessHeader(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _successAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _successAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 40,
                    color: theme.colorScheme.onTertiary,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Order Confirmed!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.tertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your order has been successfully placed',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Order #GE${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(ThemeData theme, dynamic cartState, CheckoutFlowState checkoutState) {
    return _buildSection(
      theme,
      'Order Details',
      Icons.receipt,
      [
        _buildDetailRow(theme, 'Items', '${cartState.totalItems} items'),
        _buildDetailRow(theme, 'Vendor', cartState.items.first.vendorName),
        _buildDetailRow(theme, 'Order Time', _formatDateTime(DateTime.now())),
        if (checkoutState.specialInstructions != null)
          _buildDetailRow(theme, 'Instructions', checkoutState.specialInstructions!),
      ],
    );
  }

  Widget _buildDeliveryDetails(ThemeData theme, CheckoutFlowState checkoutState) {
    final deliveryMethod = checkoutState.selectedDeliveryMethod;
    final deliveryAddress = checkoutState.selectedDeliveryAddress;
    final scheduledTime = checkoutState.scheduledDeliveryTime;

    return _buildSection(
      theme,
      'Delivery Details',
      Icons.local_shipping,
      [
        _buildDetailRow(theme, 'Method', deliveryMethod?.displayName ?? 'Not specified'),
        if (deliveryAddress != null)
          _buildDetailRow(theme, 'Address', deliveryAddress.fullAddress),
        if (scheduledTime != null)
          _buildDetailRow(theme, 'Scheduled', _formatDateTime(scheduledTime))
        else
          _buildDetailRow(theme, 'Estimated', _getEstimatedDeliveryTime(deliveryMethod)),
      ],
    );
  }

  Widget _buildPaymentDetails(ThemeData theme, CheckoutFlowState checkoutState) {
    final paymentMethod = checkoutState.selectedPaymentMethod;
    
    return _buildSection(
      theme,
      'Payment Details',
      Icons.payment,
      [
        _buildDetailRow(theme, 'Method', _getPaymentMethodName(paymentMethod)),
        _buildDetailRow(theme, 'Status', 'Confirmed', valueColor: theme.colorScheme.tertiary),
      ],
    );
  }

  Widget _buildOrderSummary(ThemeData theme, dynamic cartState) {
    return _buildSection(
      theme,
      'Order Summary',
      Icons.calculate,
      [
        _buildDetailRow(theme, 'Subtotal', 'RM ${cartState.subtotal.toStringAsFixed(2)}'),
        _buildDetailRow(theme, 'Delivery Fee', cartState.deliveryFee > 0 ? 'RM ${cartState.deliveryFee.toStringAsFixed(2)}' : 'FREE'),
        _buildDetailRow(theme, 'SST (6%)', 'RM ${cartState.sstAmount.toStringAsFixed(2)}'),
        const Divider(),
        _buildDetailRow(
          theme,
          'Total Amount',
          'RM ${cartState.totalAmount.toStringAsFixed(2)}',
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildNextSteps(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
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
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'What\'s Next?',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildNextStepItem(theme, '1. Order Preparation', 'The vendor will start preparing your order'),
          _buildNextStepItem(theme, '2. Real-time Updates', 'You\'ll receive notifications about your order status'),
          _buildNextStepItem(theme, '3. Delivery/Pickup', 'Your order will be delivered or ready for pickup'),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.notifications_active,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'We\'ll send you notifications to keep you updated',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    String label,
    String value, {
    Color? valueColor,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: isTotal
                  ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)
                  : theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: isTotal
                  ? theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    )
                  : theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: valueColor,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepItem(ThemeData theme, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now).inDays;
    
    String dateStr;
    if (difference == 0) {
      dateStr = 'Today';
    } else if (difference == 1) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    
    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    
    return '$dateStr at $timeStr';
  }

  String _getEstimatedDeliveryTime(dynamic deliveryMethod) {
    if (deliveryMethod == null) return 'To be confirmed';
    
    switch (deliveryMethod.toString()) {
      case 'CustomerDeliveryMethod.customerPickup':
        return '15-30 minutes';
      case 'CustomerDeliveryMethod.salesAgentPickup':
        return '30-45 minutes';
      case 'CustomerDeliveryMethod.ownFleet':
        return '45-60 minutes';
      default:
        return '30-60 minutes';
    }
  }

  String _getPaymentMethodName(String? method) {
    switch (method) {
      case 'card':
        return 'Credit/Debit Card';
      case 'wallet':
        return 'Digital Wallet';
      case 'cash':
        return 'Cash on Delivery';
      default:
        return 'Not specified';
    }
  }
}
