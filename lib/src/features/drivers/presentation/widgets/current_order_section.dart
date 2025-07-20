import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../drivers/data/models/driver_order.dart';
import '../../../orders/data/models/driver_order_state_machine.dart';
import '../providers/enhanced_driver_workflow_providers.dart';
import 'order_action_buttons.dart';

/// Enhanced section displaying the driver's current assigned order with granular progress tracking
/// Supports the complete driver workflow with mandatory confirmation steps
class CurrentOrderSection extends ConsumerWidget {
  const CurrentOrderSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentOrderAsync = ref.watch(enhancedCurrentDriverOrderProvider);

    return currentOrderAsync.when(
      data: (order) {
        if (order != null) {
          debugPrint('🚗 [CURRENT-ORDER] Displaying current order: ${order.orderNumber} (ID: ${order.id.substring(0, 8)}...)');
          debugPrint('🚗 [CURRENT-ORDER] Order status: ${order.status.value} (${order.status.displayName})');
          return _buildCurrentOrderCard(theme, order);
        } else {
          debugPrint('🚗 [CURRENT-ORDER] No current order found');
          return _buildNoOrderCard(theme);
        }
      },
      loading: () {
        debugPrint('🚗 [CURRENT-ORDER] Loading current order...');
        return _buildLoadingCard(theme);
      },
      error: (error, stack) {
        debugPrint('❌ [CURRENT-ORDER] Error loading current order: $error');
        return _buildErrorCard(theme, error.toString());
      },
    );
  }

  Widget _buildCurrentOrderCard(ThemeData theme, DriverOrder order) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primaryContainer,
                theme.colorScheme.primaryContainer.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status and estimated time
                _buildOrderHeader(theme, order),

                const SizedBox(height: 16),

                // Order Details
                _buildOrderInfo(theme, order),

                const SizedBox(height: 16),

                // Enhanced Progress Tracking with granular steps
                _buildEnhancedProgressTracking(theme, order),

                const SizedBox(height: 16),

                // Current step instructions
                _buildCurrentStepInstructions(theme, order),

                const SizedBox(height: 16),

                // Action Buttons
                OrderActionButtons(order: order),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoOrderCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          child: Column(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No Active Order',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You currently have no assigned orders.\nCheck available orders to start delivering.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHeader(ThemeData theme, DriverOrder order) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Order',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getEstimatedTimeText(order),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        _buildEnhancedStatusChip(theme, order.status),
      ],
    );
  }

  Widget _buildEnhancedStatusChip(ThemeData theme, DriverOrderStatus status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case DriverOrderStatus.assigned:
        backgroundColor = Colors.blue.withValues(alpha: 0.2);
        textColor = Colors.blue;
        icon = Icons.assignment;
        break;
      case DriverOrderStatus.onRouteToVendor:
        backgroundColor = Colors.orange.withValues(alpha: 0.2);
        textColor = Colors.orange;
        icon = Icons.navigation;
        break;
      case DriverOrderStatus.arrivedAtVendor:
        backgroundColor = Colors.amber.withValues(alpha: 0.2);
        textColor = Colors.amber.shade700;
        icon = Icons.location_on;
        break;
      case DriverOrderStatus.pickedUp:
        backgroundColor = Colors.green.withValues(alpha: 0.2);
        textColor = Colors.green;
        icon = Icons.shopping_bag;
        break;
      case DriverOrderStatus.onRouteToCustomer:
        backgroundColor = Colors.purple.withValues(alpha: 0.2);
        textColor = Colors.purple;
        icon = Icons.local_shipping;
        break;
      case DriverOrderStatus.arrivedAtCustomer:
        backgroundColor = Colors.indigo.withValues(alpha: 0.2);
        textColor = Colors.indigo;
        icon = Icons.home;
        break;
      case DriverOrderStatus.delivered:
        backgroundColor = Colors.teal.withValues(alpha: 0.2);
        textColor = Colors.teal;
        icon = Icons.check_circle;
        break;
      default:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurfaceVariant;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getEstimatedTimeText(DriverOrder order) {
    // TODO: Calculate estimated time based on current status and location
    switch (order.status) {
      case DriverOrderStatus.assigned:
        return 'Start navigation to restaurant';
      case DriverOrderStatus.onRouteToVendor:
        return 'Estimated arrival: 5-10 min';
      case DriverOrderStatus.arrivedAtVendor:
        return 'Confirm pickup to proceed';
      case DriverOrderStatus.pickedUp:
        return 'Start navigation to customer';
      case DriverOrderStatus.onRouteToCustomer:
        return 'Estimated delivery: 10-15 min';
      case DriverOrderStatus.arrivedAtCustomer:
        return 'Complete delivery with photo';
      case DriverOrderStatus.delivered:
        return 'Order completed successfully';
      default:
        return 'Order in progress';
    }
  }

  Widget _buildOrderInfo(ThemeData theme, DriverOrder order) {
    return Column(
      children: [
        // Order Number and Vendor
        Row(
          children: [
            Icon(
              Icons.receipt_long,
              color: theme.colorScheme.onPrimaryContainer,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.orderNumber}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    order.vendorName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'RM${order.orderTotal.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${order.orderItemsCount} items',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Customer and Delivery Address
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.location_on,
              color: theme.colorScheme.onPrimaryContainer,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.customerName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    order.deliveryDetails.address,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (order.deliveryDetails.phone != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 14,
                          color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          order.deliveryDetails.phone!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnhancedProgressTracking(ThemeData theme, DriverOrder order) {
    final steps = _getDriverProgressSteps(order);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Delivery Progress',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                '${_getCompletedStepsCount(steps)}/${steps.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress steps in a vertical layout for better granular display
          Column(
            children: steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isLast = index == steps.length - 1;

              return _buildEnhancedProgressStep(theme, step, isLast, index);
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<EnhancedProgressStep> _getDriverProgressSteps(DriverOrder order) {
    return [
      EnhancedProgressStep(
        status: DriverOrderStatus.assigned,
        title: 'Order Assigned',
        subtitle: 'Order assigned to you',
        icon: Icons.assignment,
        isCompleted: _isStatusCompleted(order.status, DriverOrderStatus.assigned),
        isCurrent: order.status == DriverOrderStatus.assigned,
        requiresAction: order.status == DriverOrderStatus.assigned,
      ),
      EnhancedProgressStep(
        status: DriverOrderStatus.onRouteToVendor,
        title: 'En Route to Restaurant',
        subtitle: 'Navigating to pickup location',
        icon: Icons.navigation,
        isCompleted: _isStatusCompleted(order.status, DriverOrderStatus.onRouteToVendor),
        isCurrent: order.status == DriverOrderStatus.onRouteToVendor,
        requiresAction: false,
      ),
      EnhancedProgressStep(
        status: DriverOrderStatus.arrivedAtVendor,
        title: 'Arrived at Restaurant',
        subtitle: 'Ready for pickup confirmation',
        icon: Icons.location_on,
        isCompleted: _isStatusCompleted(order.status, DriverOrderStatus.arrivedAtVendor),
        isCurrent: order.status == DriverOrderStatus.arrivedAtVendor,
        requiresAction: order.status == DriverOrderStatus.arrivedAtVendor,
        isMandatory: true,
      ),
      EnhancedProgressStep(
        status: DriverOrderStatus.pickedUp,
        title: 'Order Picked Up',
        subtitle: 'Confirmed with restaurant',
        icon: Icons.shopping_bag,
        isCompleted: _isStatusCompleted(order.status, DriverOrderStatus.pickedUp),
        isCurrent: order.status == DriverOrderStatus.pickedUp,
        requiresAction: order.status == DriverOrderStatus.pickedUp,
      ),
      EnhancedProgressStep(
        status: DriverOrderStatus.onRouteToCustomer,
        title: 'En Route to Customer',
        subtitle: 'Delivering to customer',
        icon: Icons.local_shipping,
        isCompleted: _isStatusCompleted(order.status, DriverOrderStatus.onRouteToCustomer),
        isCurrent: order.status == DriverOrderStatus.onRouteToCustomer,
        requiresAction: false,
      ),
      EnhancedProgressStep(
        status: DriverOrderStatus.arrivedAtCustomer,
        title: 'Arrived at Customer',
        subtitle: 'Ready for delivery confirmation',
        icon: Icons.home,
        isCompleted: _isStatusCompleted(order.status, DriverOrderStatus.arrivedAtCustomer),
        isCurrent: order.status == DriverOrderStatus.arrivedAtCustomer,
        requiresAction: order.status == DriverOrderStatus.arrivedAtCustomer,
        isMandatory: true,
      ),
      EnhancedProgressStep(
        status: DriverOrderStatus.delivered,
        title: 'Order Delivered',
        subtitle: 'Delivery completed successfully',
        icon: Icons.check_circle,
        isCompleted: order.status == DriverOrderStatus.delivered,
        isCurrent: order.status == DriverOrderStatus.delivered,
        requiresAction: false,
      ),
    ];
  }

  bool _isStatusCompleted(DriverOrderStatus currentStatus, DriverOrderStatus checkStatus) {
    // Define the order of statuses
    const statusOrder = [
      DriverOrderStatus.assigned,
      DriverOrderStatus.onRouteToVendor,
      DriverOrderStatus.arrivedAtVendor,
      DriverOrderStatus.pickedUp,
      DriverOrderStatus.onRouteToCustomer,
      DriverOrderStatus.arrivedAtCustomer,
      DriverOrderStatus.delivered,
    ];

    final currentIndex = statusOrder.indexOf(currentStatus);
    final checkIndex = statusOrder.indexOf(checkStatus);

    return currentIndex >= checkIndex;
  }

  int _getCompletedStepsCount(List<EnhancedProgressStep> steps) {
    return steps.where((step) => step.isCompleted).length;
  }

  Widget _buildEnhancedProgressStep(ThemeData theme, EnhancedProgressStep step, bool isLast, int index) {
    Color stepColor;
    Color backgroundColor;

    if (step.isCompleted) {
      stepColor = Colors.green;
      backgroundColor = Colors.green.withValues(alpha: 0.1);
    } else if (step.isCurrent) {
      stepColor = theme.colorScheme.primary;
      backgroundColor = theme.colorScheme.primaryContainer.withValues(alpha: 0.3);
    } else {
      stepColor = theme.colorScheme.outline;
      backgroundColor = Colors.transparent;
    }

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          // Step indicator
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: step.isCompleted
                      ? Colors.green
                      : step.isCurrent
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: step.isMandatory
                      ? Border.all(color: Colors.red, width: 2)
                      : null,
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        step.isCompleted ? Icons.check : step.icon,
                        size: 20,
                        color: step.isCompleted
                            ? Colors.white
                            : step.isCurrent
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (step.isMandatory && !step.isCompleted)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.priority_high,
                            size: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 20,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: step.isCompleted
                      ? Colors.green
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Step content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: step.isCurrent
                    ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          step.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: stepColor,
                            fontWeight: step.isCurrent ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (step.requiresAction && !step.isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'ACTION REQUIRED',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: stepColor.withValues(alpha: 0.8),
                    ),
                  ),
                  if (step.isMandatory && !step.isCompleted) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Mandatory confirmation required',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepInstructions(ThemeData theme, DriverOrder order) {
    final instructions = DriverOrderStateMachine.getDriverInstructions(order.status);
    final requiresConfirmation = DriverOrderStateMachine.requiresMandatoryConfirmation(order.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                requiresConfirmation ? Icons.warning : Icons.info,
                color: requiresConfirmation ? Colors.orange : theme.colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                requiresConfirmation ? 'Action Required' : 'Current Step',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: requiresConfirmation ? Colors.orange : theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            instructions,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          if (requiresConfirmation) ...[
            const SizedBox(height: 8),
            Text(
              'You must complete this step before proceeding to the next stage.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                height: 20,
                width: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme, String error) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed to load current order: $error',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Enhanced progress step for granular driver workflow tracking
class EnhancedProgressStep {
  final DriverOrderStatus status;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isCompleted;
  final bool isCurrent;
  final bool requiresAction;
  final bool isMandatory;

  const EnhancedProgressStep({
    required this.status,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isCompleted,
    required this.isCurrent,
    this.requiresAction = false,
    this.isMandatory = false,
  });
}
