import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../data/models/driver_order.dart';
import '../../data/models/driver_error.dart';
import '../providers/driver_realtime_providers.dart';
import '../widgets/delivery_confirmation_dialog.dart';

/// Driver delivery workflow screen with step-by-step process
class DriverDeliveryWorkflowScreen extends ConsumerWidget {
  final String orderId;

  const DriverDeliveryWorkflowScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(realtimeOrderDetailsProvider(orderId));

    return orderAsync.when(
      data: (order) => order == null
          ? _buildOrderNotFound(context)
          : _buildWorkflowScreen(context, ref, order),
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Delivery Workflow'),
          elevation: 0,
        ),
        body: const LoadingWidget(message: 'Loading delivery details...'),
      ),
      error: (error, stack) {
        final driverError = error is DriverException
            ? error
            : DriverException.fromException(error);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Delivery Workflow'),
            elevation: 0,
          ),
          body: CustomErrorWidget(
            message: driverError.userFriendlyMessage,
            onRetry: () => ref.invalidate(realtimeOrderDetailsProvider(orderId)),
          ),
        );
      },
    );
  }

  Widget _buildOrderNotFound(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Workflow'),
        elevation: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Order not found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowScreen(BuildContext context, WidgetRef ref, DriverOrder order) {
    final currentStep = _determineCurrentStep(order);

    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery #${order.orderNumber}'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(realtimeOrderDetailsProvider(orderId)),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(realtimeOrderDetailsProvider(orderId));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary Header
              _buildOrderSummaryHeader(context, order),

              const SizedBox(height: 24),

              // Progress Indicator
              _buildProgressIndicator(context, currentStep),

              const SizedBox(height: 24),

              // Current Step Card
              _buildCurrentStepCard(context, ref, order, currentStep),

              const SizedBox(height: 24),

              // All Steps List
              _buildStepsList(context, currentStep),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  int _determineCurrentStep(DriverOrder order) {
    switch (order.status) {
      case DriverOrderStatus.assigned:
        return 0; // Navigate to pickup
      case DriverOrderStatus.onRouteToVendor:
        return 0; // Navigate to pickup
      case DriverOrderStatus.arrivedAtVendor:
        return 1; // Confirm pickup
      case DriverOrderStatus.pickedUp:
        return 2; // Navigate to customer
      case DriverOrderStatus.onRouteToCustomer:
        return 2; // Navigate to customer
      case DriverOrderStatus.arrivedAtCustomer:
        return 3; // Confirm delivery
      case DriverOrderStatus.delivered:
        return 4; // Completed
      default:
        return 0;
    }
  }

  // Delivery workflow steps
  static const List<DeliveryStep> _deliverySteps = [
    DeliveryStep(
      title: 'Navigate to Pickup',
      description: 'Drive to the vendor location to collect the order',
      icon: Icons.restaurant,
      color: Colors.orange,
    ),
    DeliveryStep(
      title: 'Confirm Pickup',
      description: 'Confirm you have collected the order from the vendor',
      icon: Icons.check_circle_outline,
      color: Colors.blue,
    ),
    DeliveryStep(
      title: 'Navigate to Customer',
      description: 'Drive to the customer delivery location',
      icon: Icons.navigation,
      color: Colors.purple,
    ),
    DeliveryStep(
      title: 'Confirm Delivery',
      description: 'Confirm delivery and capture proof of delivery',
      icon: Icons.camera_alt,
      color: Colors.green,
    ),
  ];

  Widget _buildOrderSummaryHeader(BuildContext context, DriverOrder order) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor(order.status)),
                  ),
                  child: Text(
                    order.status.displayName,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: _getStatusColor(order.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'RM ${order.deliveryFee.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Order #${order.orderNumber}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.restaurant, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.vendorName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.customerName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, int currentStep) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Progress',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(_deliverySteps.length, (index) {
                final isCompleted = index < currentStep;
                final isCurrent = index == currentStep;

                return Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green
                              : isCurrent
                                  ? _deliverySteps[index].color
                                  : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompleted
                              ? Icons.check
                              : isCurrent
                                  ? _deliverySteps[index].icon
                                  : Icons.circle,
                          color: isCompleted || isCurrent ? Colors.white : Colors.grey[600],
                          size: 16,
                        ),
                      ),
                      if (index < _deliverySteps.length - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: index < currentStep ? Colors.green : Colors.grey[300],
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            Text(
              '$currentStep of ${_deliverySteps.length} steps completed',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepCard(BuildContext context, WidgetRef ref, DriverOrder order, int currentStepIndex) {
    if (currentStepIndex >= _deliverySteps.length) {
      return _buildCompletedCard(context);
    }

    final currentStep = _deliverySteps[currentStepIndex];
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: currentStep.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    currentStep.icon,
                    color: currentStep.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Step',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentStep.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              currentStep.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 20),
            _buildCurrentStepActions(context, ref, order, currentStepIndex),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepActions(BuildContext context, WidgetRef ref, DriverOrder order, int currentStepIndex) {
    switch (currentStepIndex) {
      case 0: // Navigate to pickup
        return _buildNavigateToPickupActions(context, ref, order);
      case 1: // Confirm pickup
        return _buildConfirmPickupActions(context, ref, order);
      case 2: // Navigate to customer
        return _buildNavigateToCustomerActions(context, ref, order);
      case 3: // Confirm delivery
        return _buildConfirmDeliveryActions(context, ref, order);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavigateToPickupActions(BuildContext context, WidgetRef ref, DriverOrder order) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _startNavigationToVendor(context, ref, order),
            icon: const Icon(Icons.directions),
            label: const Text('Start Navigation to Vendor'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _callVendor(context),
                icon: const Icon(Icons.phone),
                label: const Text('Call Vendor'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _markArrivedAtPickup(context, ref, order),
                icon: const Icon(Icons.location_on),
                label: const Text('Arrived'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmPickupActions(BuildContext context, WidgetRef ref, DriverOrder order) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _confirmPickup(context, ref, order),
            icon: const Icon(Icons.check_circle),
            label: const Text('Confirm Pickup'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _reportPickupIssue(context),
          icon: const Icon(Icons.report_problem),
          label: const Text('Report Issue'),
        ),
      ],
    );
  }

  Widget _buildNavigateToCustomerActions(BuildContext context, WidgetRef ref, DriverOrder order) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _startNavigationToCustomer(context, ref, order),
            icon: const Icon(Icons.directions),
            label: const Text('Start Navigation to Customer'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: order.customerPhone != null ? () => _callCustomer(order.customerPhone!) : null,
                icon: const Icon(Icons.phone),
                label: const Text('Call Customer'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _markArrivedAtDelivery(context, ref, order),
                icon: const Icon(Icons.location_on),
                label: const Text('Arrived'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmDeliveryActions(BuildContext context, WidgetRef ref, DriverOrder order) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _confirmDelivery(context, ref, order),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Confirm Delivery & Take Photo'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _reportDeliveryIssue(context),
          icon: const Icon(Icons.report_problem),
          label: const Text('Report Delivery Issue'),
        ),
      ],
    );
  }

  Widget _buildCompletedCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Delivery Completed!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Great job! You have successfully completed this delivery.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.home),
                label: const Text('Back to Dashboard'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsList(BuildContext context, int currentStepIndex) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Steps',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(_deliverySteps.length, (index) {
              final step = _deliverySteps[index];
              final isCompleted = index < currentStepIndex;
              final isCurrent = index == currentStepIndex;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green
                            : isCurrent
                                ? step.color
                                : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : step.icon,
                        color: isCompleted || isCurrent ? Colors.white : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isCompleted || isCurrent ? null : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(DriverOrderStatus status) {
    switch (status) {
      case DriverOrderStatus.available:
        return Colors.blue;
      case DriverOrderStatus.assigned:
        return Colors.orange;
      case DriverOrderStatus.onRouteToVendor:
        return Colors.orange;
      case DriverOrderStatus.arrivedAtVendor:
        return Colors.blue;
      case DriverOrderStatus.pickedUp:
        return Colors.purple;
      case DriverOrderStatus.onRouteToCustomer:
        return Colors.indigo;
      case DriverOrderStatus.arrivedAtCustomer:
        return Colors.indigo;
      case DriverOrderStatus.delivered:
        return Colors.green;
      case DriverOrderStatus.cancelled:
        return Colors.red;
    }
  }

  Future<void> _openMaps(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final url = 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error opening maps: $e');
    }
  }

  /// Start navigation to vendor and update status to on_route_to_vendor
  Future<void> _startNavigationToVendor(BuildContext context, WidgetRef ref, DriverOrder order) async {
    try {
      final actions = ref.read(realtimeDriverOrderActionsProvider);

      debugPrint('DriverDeliveryWorkflow: Starting navigation to vendor for order ${order.id}');

      // Update order status to on route to vendor
      final result = await actions.updateOrderStatus(order.id, DriverOrderStatus.onRouteToVendor);

      result.when(
        success: (success) async {
          // Open maps for navigation
          await _openMaps(order.vendorAddress ?? order.vendorName);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Navigation started to vendor'),
                backgroundColor: Colors.blue,
              ),
            );
          }

          // Refresh the order details
          ref.invalidate(realtimeOrderDetailsProvider(order.id));
        },
        error: (error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${error.userFriendlyMessage}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } catch (e) {
      debugPrint('DriverDeliveryWorkflow: Error starting navigation to vendor: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting navigation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Start navigation to customer and update status to on_route_to_customer if needed
  Future<void> _startNavigationToCustomer(BuildContext context, WidgetRef ref, DriverOrder order) async {
    try {
      final actions = ref.read(realtimeDriverOrderActionsProvider);

      debugPrint('DriverDeliveryWorkflow: Starting navigation to customer for order ${order.id}');
      debugPrint('DriverDeliveryWorkflow: Current order status: ${order.status.displayName}');

      // Check if we need to update the status
      if (order.status == DriverOrderStatus.pickedUp) {
        // Update order status to on route to customer
        final result = await actions.updateOrderStatus(order.id, DriverOrderStatus.onRouteToCustomer);

        result.when(
          success: (success) async {
            // Open maps for navigation
            await _openMaps(order.deliveryAddress);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Navigation started to customer'),
                  backgroundColor: Colors.blue,
                ),
              );
            }

            // Refresh the order details
            ref.invalidate(realtimeOrderDetailsProvider(order.id));
          },
          error: (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${error.userFriendlyMessage}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      } else if (order.status == DriverOrderStatus.onRouteToCustomer) {
        // Already on route to customer, just open maps
        await _openMaps(order.deliveryAddress);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Navigation opened to customer'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        // Invalid status for this action
        debugPrint('DriverDeliveryWorkflow: Invalid status for navigation to customer: ${order.status.displayName}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot start navigation from current status: ${order.status.displayName}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('DriverDeliveryWorkflow: Error starting navigation to customer: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting navigation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _callCustomer(String phoneNumber) async {
    final url = 'tel:$phoneNumber';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      debugPrint('Error making phone call: $e');
    }
  }

  void _callVendor(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vendor contact information not available')),
    );
  }

  Future<void> _markArrivedAtPickup(BuildContext context, WidgetRef ref, DriverOrder order) async {
    try {
      final actions = ref.read(realtimeDriverOrderActionsProvider);

      debugPrint('DriverDeliveryWorkflow: Marking arrived at pickup for order ${order.id}');

      // Update order status to arrived at vendor
      final result = await actions.updateOrderStatus(order.id, DriverOrderStatus.arrivedAtVendor);

      result.when(
        success: (success) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Marked as arrived at pickup location'),
                backgroundColor: Colors.blue,
              ),
            );
          }
          // Refresh the order details
          ref.invalidate(realtimeOrderDetailsProvider(order.id));
        },
        error: (error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${error.userFriendlyMessage}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } catch (e) {
      debugPrint('DriverDeliveryWorkflow: Error marking arrived at pickup: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking arrival: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmPickup(BuildContext context, WidgetRef ref, DriverOrder order) async {
    try {
      // Use the realtime driver order actions provider
      final actions = ref.read(realtimeDriverOrderActionsProvider);

      debugPrint('DriverDeliveryWorkflow: Confirming pickup for order ${order.id}');

      // Update order status to picked up using the actions provider
      final result = await actions.updateOrderStatus(order.id, DriverOrderStatus.pickedUp);

      if (result.isSuccess) {
        debugPrint('DriverDeliveryWorkflow: Pickup confirmed successfully');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pickup confirmed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Refresh the order details
        ref.invalidate(realtimeOrderDetailsProvider(order.id));
      } else {
        debugPrint('DriverDeliveryWorkflow: Failed to confirm pickup: ${result.error?.message}');
        throw Exception(result.error?.message ?? 'Failed to confirm pickup');
      }
    } catch (e) {
      debugPrint('DriverDeliveryWorkflow: Error confirming pickup: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error confirming pickup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _reportPickupIssue(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pickup issue reporting - Coming soon!')),
    );
  }

  Future<void> _markArrivedAtDelivery(BuildContext context, WidgetRef ref, DriverOrder order) async {
    try {
      final actions = ref.read(realtimeDriverOrderActionsProvider);

      debugPrint('DriverDeliveryWorkflow: Marking arrived at delivery for order ${order.id}');

      // Update order status to arrived at customer
      final result = await actions.updateOrderStatus(order.id, DriverOrderStatus.arrivedAtCustomer);

      result.when(
        success: (success) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Marked as arrived at delivery location'),
                backgroundColor: Colors.blue,
              ),
            );
          }
          // Refresh the order details
          ref.invalidate(realtimeOrderDetailsProvider(order.id));
        },
        error: (error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${error.userFriendlyMessage}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } catch (e) {
      debugPrint('DriverDeliveryWorkflow: Error marking arrived at delivery: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking arrival: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelivery(BuildContext context, WidgetRef ref, DriverOrder order) async {
    try {
      // Show delivery confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => DeliveryConfirmationDialog(
          order: order,
          onConfirm: (notes) async {
            // Use the realtime driver order actions provider
            final actions = ref.read(realtimeDriverOrderActionsProvider);

            debugPrint('DriverDeliveryWorkflow: Confirming delivery for order ${order.id}');

            // Update order status to delivered
            final result = await actions.updateOrderStatus(order.id, DriverOrderStatus.delivered);

            return result.when(
              success: (success) {
                debugPrint('DriverDeliveryWorkflow: Delivery confirmed successfully');
                return true;
              },
              error: (error) {
                debugPrint('DriverDeliveryWorkflow: Failed to confirm delivery: ${error.message}');
                throw Exception(error.userFriendlyMessage);
              },
            );
          },
        ),
      );

      if (confirmed == true) {
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Delivery confirmed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Refresh the order details - realtime subscriptions will handle the rest
        ref.invalidate(realtimeOrderDetailsProvider(order.id));

        // Navigate back to dashboard after successful delivery
        if (context.mounted) {
          context.go('/driver');
        }
      }
    } catch (e) {
      debugPrint('DriverDeliveryWorkflow: Error confirming delivery: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error confirming delivery: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _reportDeliveryIssue(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delivery issue reporting - Coming soon!')),
    );
  }
}

/// Delivery step model
class DeliveryStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const DeliveryStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
