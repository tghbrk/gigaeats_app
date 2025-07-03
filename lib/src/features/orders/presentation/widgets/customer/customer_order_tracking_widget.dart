import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// TODO: Restore unused import when tracking functionality is implemented
// import 'package:go_router/go_router.dart';
// TODO: Restore when customer delivery tracking provider is implemented
// import '../providers/customer_delivery_tracking_provider.dart';
// TODO: Restore when order tracking functionality is implemented
// import '../../../orders/data/models/order.dart';

/// Compact order tracking widget for embedding in order cards
class CustomerOrderTrackingWidget extends ConsumerWidget {
  final String orderId;
  // TODO: Restore when OrderStatus is implemented
  final dynamic orderStatus;

  const CustomerOrderTrackingWidget({
    super.key,
    required this.orderId,
    required this.orderStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final theme = Theme.of(context); // Unused variable

    // Only show tracking for orders that are out for delivery
    // TODO: Restore when OrderStatus is implemented
    // if (orderStatus != OrderStatus.outForDelivery) {
    if (orderStatus != 'out_for_delivery') { // Placeholder string comparison
      return const SizedBox.shrink();
    }

    return Consumer(
      builder: (context, ref, child) {
        // TODO: Restore when orderTrackableProvider is implemented
        // final trackableAsync = ref.watch(orderTrackableProvider(orderId));
        // final trackableAsync = false;
        
        // TODO: Restore when orderTrackableProvider is implemented
        // if (!trackableAsync) return const SizedBox.shrink();

        // TODO: Restore when order tracking functionality is implemented
        // return _buildTrackingWidget(context, ref, theme);
        return const SizedBox.shrink(); // Placeholder

        // TODO: Restore dead code when order tracking functionality is implemented
        // return trackableAsync.when(
        //   data: (isTrackable) {
        //     if (!isTrackable) return const SizedBox.shrink();
        //
        //     return _buildTrackingWidget(context, ref, theme);
        //   },
        //   loading: () => const SizedBox.shrink(),
        //   error: (_, _) => const SizedBox.shrink(),
        // );
      },
    );
  }

  // TODO: Restore unused method _buildTrackingWidget when delivery providers are implemented
  // Widget _buildTrackingWidget(BuildContext context, WidgetRef ref, ThemeData theme) {
  //   // TODO: Restore when delivery providers are implemented
  //   // final etaAsync = ref.watch(deliveryETAProvider(orderId));
  //   // final isDriverTracking = ref.watch(isDriverTrackingProvider(orderId));
  //   // TODO: Restore unused variables when delivery providers are implemented
  //   // final etaAsync = null; // Placeholder
  //   // final isDriverTracking = false; // Placeholder

  //   return Container(
  //     margin: const EdgeInsets.only(top: 8),
  //     padding: const EdgeInsets.all(12),
  //     decoration: BoxDecoration(
  //       color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
  //       borderRadius: BorderRadius.circular(8),
  //       border: Border.all(
  //         color: theme.colorScheme.primary.withValues(alpha: 0.3),
  //       ),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             // TODO: Restore dead code when driver tracking is implemented
  //             // Icon(
  //             //   isDriverTracking ? Icons.gps_fixed : Icons.delivery_dining,
  //             //   size: 16,
  //             //   color: theme.colorScheme.primary,
  //             // ),
  //             // const SizedBox(width: 8),
  //             // Expanded(
  //             //   child: Text(
  //             //     isDriverTracking ? 'Live tracking available' : 'Out for delivery',
  //             //     style: theme.textTheme.bodySmall?.copyWith(
  //             //       fontWeight: FontWeight.w600,
  //             //       color: theme.colorScheme.primary,
  //             //     ),
  //             //   ),
  //             // ),
  //             // TODO: Restore ETA display when delivery providers are implemented
  //             // if (etaAsync != null) ...[
  //             //   Icon(
  //             //     Icons.schedule,
  //             //     size: 14,
  //             //     color: theme.colorScheme.onPrimaryContainer,
  //             //   ),
  //             //   const SizedBox(width: 4),
  //             //   Text(
  //             //     etaAsync,
  //             //     style: theme.textTheme.labelSmall?.copyWith(
  //             //       color: theme.colorScheme.onPrimaryContainer,
  //             //       fontWeight: FontWeight.w500,
  //             //     ),
  //             //   ),
  //             // ],
  //           ],
  //         ),
  //         const SizedBox(height: 8),
  //         SizedBox(
  //           width: double.infinity,
  //           child: OutlinedButton.icon(
  //             onPressed: () => _openTrackingScreen(context),
  //             icon: const Icon(Icons.map, size: 16),
  //             label: const Text('Track on Map'),
  //             style: OutlinedButton.styleFrom(
  //               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //               minimumSize: const Size(0, 32),
  //               side: BorderSide(color: theme.colorScheme.primary),
  //               foregroundColor: theme.colorScheme.primary,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // TODO: Restore unused method _openTrackingScreen when tracking functionality is implemented
  // void _openTrackingScreen(BuildContext context) {
  //   context.push('/customer/orders/$orderId/track');
  // }
}

/// Live tracking indicator for order status
class LiveTrackingIndicator extends ConsumerWidget {
  final String orderId;

  const LiveTrackingIndicator({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Restore unused theme variable when live tracking is implemented
    // final theme = Theme.of(context);
    // TODO: Restore when isDriverTrackingProvider is implemented
    // final isDriverTracking = ref.watch(isDriverTrackingProvider(orderId));
    // final isDriverTracking = false; // Placeholder

    // TODO: Restore dead code when driver tracking is implemented
    // if (!isDriverTracking) return const SizedBox.shrink();

    // return Container(
    //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    //   decoration: BoxDecoration(
    //     color: Colors.green.shade100,
    //     borderRadius: BorderRadius.circular(12),
    //   ),
    //   child: Row(
    //     mainAxisSize: MainAxisSize.min,
    //     children: [
    //       Container(
    //         width: 6,
    //         height: 6,
    //         decoration: const BoxDecoration(
    //           color: Colors.green,
    //           shape: BoxShape.circle,
    //         ),
    //       ),
    //       const SizedBox(width: 6),
    //       Text(
    //         'Live',
    //         style: theme.textTheme.labelSmall?.copyWith(
    //           color: Colors.green.shade800,
    //           fontWeight: FontWeight.w600,
    //         ),
    //       ),
    //     ],
    //   ),
    // );
    return const SizedBox.shrink(); // Placeholder
  }
}

/// Delivery progress indicator
class DeliveryProgressIndicator extends ConsumerWidget {
  final String orderId;
  // TODO: Restore when OrderStatus is implemented
  // final OrderStatus currentStatus;
  final dynamic currentStatus; // Placeholder

  const DeliveryProgressIndicator({
    super.key,
    required this.orderId,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final steps = [
      // TODO: Restore when OrderStatus is implemented
      _DeliveryStep(
        icon: Icons.restaurant,
        label: 'Confirmed',
        status: 'confirmed', // was: OrderStatus.confirmed
      ),
      _DeliveryStep(
        icon: Icons.kitchen,
        label: 'Preparing',
        status: 'preparing', // was: OrderStatus.preparing
      ),
      _DeliveryStep(
        icon: Icons.check_circle,
        label: 'Ready',
        status: 'ready', // was: OrderStatus.ready
      ),
      _DeliveryStep(
        icon: Icons.delivery_dining,
        label: 'Out for Delivery',
        status: 'out_for_delivery', // was: OrderStatus.outForDelivery
      ),
      _DeliveryStep(
        icon: Icons.home,
        label: 'Delivered',
        status: 'delivered', // was: OrderStatus.delivered
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Progress',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isCompleted = _isStepCompleted(step.status, currentStatus);
              final isCurrent = step.status == currentStatus;

              return Expanded(
                child: Row(
                  children: [
                    _buildStepIndicator(
                      step: step,
                      isCompleted: isCompleted,
                      isCurrent: isCurrent,
                      theme: theme,
                    ),
                    if (index < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isCompleted
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required _DeliveryStep step,
    required bool isCompleted,
    required bool isCurrent,
    required ThemeData theme,
  }) {
    Color backgroundColor;
    Color iconColor;
    Color textColor;

    if (isCompleted) {
      backgroundColor = theme.colorScheme.primary;
      iconColor = theme.colorScheme.onPrimary;
      textColor = theme.colorScheme.primary;
    } else if (isCurrent) {
      backgroundColor = theme.colorScheme.primaryContainer;
      iconColor = theme.colorScheme.onPrimaryContainer;
      textColor = theme.colorScheme.onPrimaryContainer;
    } else {
      backgroundColor = theme.colorScheme.outline.withValues(alpha: 0.3);
      iconColor = theme.colorScheme.outline;
      textColor = theme.colorScheme.outline;
    }

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            step.icon,
            size: 16,
            color: iconColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          step.label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: textColor,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // TODO: Restore when OrderStatus is implemented
  // bool _isStepCompleted(OrderStatus stepStatus, OrderStatus currentStatus) {
  bool _isStepCompleted(dynamic stepStatus, dynamic currentStatus) {
    // TODO: Restore when OrderStatus enum is implemented
    // final statusOrder = [
    //   OrderStatus.pending,
    //   OrderStatus.confirmed,
    //   OrderStatus.preparing,
    //   OrderStatus.ready,
    //   OrderStatus.outForDelivery,
    //   OrderStatus.delivered,
    // ];
    final statusOrder = [
      'pending',
      'confirmed',
      'preparing',
      'ready',
      'out_for_delivery',
      'delivered',
    ];

    final stepIndex = statusOrder.indexOf(stepStatus);
    final currentIndex = statusOrder.indexOf(currentStatus);

    return stepIndex <= currentIndex;
  }
}

class _DeliveryStep {
  final IconData icon;
  final String label;
  // TODO: Restore when OrderStatus is implemented
  // final OrderStatus status;
  final dynamic status; // Placeholder

  const _DeliveryStep({
    required this.icon,
    required this.label,
    required this.status,
  });
}
