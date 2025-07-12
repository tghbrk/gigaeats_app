import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../drivers/data/models/driver_order.dart';
import '../../../drivers/data/models/pickup_confirmation.dart';
import '../../../drivers/data/models/delivery_confirmation.dart';
import '../../../drivers/data/services/pickup_confirmation_service.dart';
import '../../../drivers/data/services/delivery_confirmation_service.dart';
import '../../data/models/driver_error.dart';
import '../providers/driver_realtime_providers.dart';
import '../widgets/driver_delivery_confirmation_dialog.dart';
import '../widgets/vendor_pickup_confirmation_dialog.dart';
import 'pre_navigation_overview_screen.dart' as nav;

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
        return 0; // Start journey to vendor
      case DriverOrderStatus.onRouteToVendor:
        return 1; // En route to vendor
      case DriverOrderStatus.arrivedAtVendor:
        return 2; // Arrived at vendor
      case DriverOrderStatus.pickedUp:
        return 3; // Order picked up
      case DriverOrderStatus.onRouteToCustomer:
        return 4; // En route to customer
      case DriverOrderStatus.arrivedAtCustomer:
        return 5; // Arrived at customer
      case DriverOrderStatus.delivered:
        return 6; // Delivery completed
      default:
        return 0;
    }
  }

  // Enhanced 7-step delivery workflow
  static const List<DeliveryStep> _deliverySteps = [
    DeliveryStep(
      title: 'Start Journey',
      description: 'Begin navigation to the restaurant',
      icon: Icons.play_arrow,
      color: Colors.blue,
    ),
    DeliveryStep(
      title: 'En Route to Restaurant',
      description: 'Driving to the vendor location',
      icon: Icons.directions_car,
      color: Colors.orange,
    ),
    DeliveryStep(
      title: 'Arrived at Restaurant',
      description: 'Mark arrival and prepare for pickup',
      icon: Icons.restaurant,
      color: Colors.amber,
    ),
    DeliveryStep(
      title: 'Order Picked Up',
      description: 'Confirm order collection from vendor',
      icon: Icons.check_circle,
      color: Colors.green,
    ),
    DeliveryStep(
      title: 'En Route to Customer',
      description: 'Driving to customer delivery location',
      icon: Icons.navigation,
      color: Colors.purple,
    ),
    DeliveryStep(
      title: 'Arrived at Customer',
      description: 'Mark arrival at delivery location',
      icon: Icons.location_on,
      color: Colors.indigo,
    ),
    DeliveryStep(
      title: 'Delivery Complete',
      description: 'Confirm delivery with photo proof',
      icon: Icons.camera_alt,
      color: Colors.teal,
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
      case 0: // Start journey (assigned)
        return _buildStartJourneyActions(context, ref, order);
      case 1: // En route to vendor (on_route_to_vendor)
        return _buildEnRouteToVendorActions(context, ref, order);
      case 2: // Arrived at vendor (arrived_at_vendor)
        return _buildArrivedAtVendorActions(context, ref, order);
      case 3: // Order picked up (picked_up)
        return _buildOrderPickedUpActions(context, ref, order);
      case 4: // En route to customer (on_route_to_customer)
        return _buildEnRouteToCustomerActions(context, ref, order);
      case 5: // Arrived at customer (arrived_at_customer)
        return _buildArrivedAtCustomerActions(context, ref, order);
      case 6: // Delivery complete (delivered)
        return _buildDeliveryCompleteActions(context, ref, order);
      default:
        return const SizedBox.shrink();
    }
  }

  // Step 0: Start journey (assigned)
  Widget _buildStartJourneyActions(BuildContext context, WidgetRef ref, DriverOrder order) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _startNavigationToVendor(context, ref, order),
            icon: const Icon(Icons.directions),
            label: const Text('Start Navigation to Restaurant'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue,
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
                label: const Text('Call Restaurant'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _reportIssue(context, ref, order),
                icon: const Icon(Icons.report_problem),
                label: const Text('Report Issue'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 1: En route to vendor (on_route_to_vendor)
  Widget _buildEnRouteToVendorActions(BuildContext context, WidgetRef ref, DriverOrder order) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange),
          ),
          child: Row(
            children: [
              Icon(Icons.directions_car, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'En route to restaurant. Mark arrival when you reach the location.',
                  style: TextStyle(color: Colors.orange[800]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _markArrivedAtPickup(context, ref, order),
            icon: const Icon(Icons.location_on),
            label: const Text('Mark Arrived at Restaurant'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.orange,
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
                label: const Text('Call Restaurant'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _reportIssue(context, ref, order),
                icon: const Icon(Icons.report_problem),
                label: const Text('Report Issue'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 2: Arrived at vendor (arrived_at_vendor)
  Widget _buildArrivedAtVendorActions(BuildContext context, WidgetRef ref, DriverOrder order) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber),
          ),
          child: Row(
            children: [
              Icon(Icons.restaurant, color: Colors.amber[800]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You have arrived at the restaurant. Confirm pickup when you receive the order.',
                  style: TextStyle(color: Colors.amber[800]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _confirmPickup(context, ref, order),
            icon: const Icon(Icons.check_circle),
            label: const Text('Confirm Order Pickup'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
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
                label: const Text('Call Restaurant'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _reportIssue(context, ref, order),
                icon: const Icon(Icons.report_problem),
                label: const Text('Report Issue'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 3: Order picked up (picked_up)
  Widget _buildOrderPickedUpActions(BuildContext context, WidgetRef ref, DriverOrder order) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Order picked up successfully! Start navigation to customer.',
                  style: TextStyle(color: Colors.green[800]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _startNavigationToCustomer(context, ref, order),
            icon: const Icon(Icons.navigation),
            label: const Text('Start Navigation to Customer'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.purple,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _callCustomer(order.customerPhone ?? ''),
                icon: const Icon(Icons.phone),
                label: const Text('Call Customer'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _reportIssue(context, ref, order),
                icon: const Icon(Icons.report_problem),
                label: const Text('Report Issue'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 4: En route to customer (on_route_to_customer)
  Widget _buildEnRouteToCustomerActions(BuildContext context, WidgetRef ref, DriverOrder order) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple),
          ),
          child: Row(
            children: [
              Icon(Icons.navigation, color: Colors.purple),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'En route to customer. Mark arrival when you reach the delivery location.',
                  style: TextStyle(color: Colors.purple[800]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _markArrivedAtCustomer(context, ref, order),
            icon: const Icon(Icons.location_on),
            label: const Text('Mark Arrived at Customer'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.indigo,
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
                onPressed: () => _reportIssue(context, ref, order),
                icon: const Icon(Icons.report_problem),
                label: const Text('Report Issue'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 5: Arrived at customer (arrived_at_customer)
  Widget _buildArrivedAtCustomerActions(BuildContext context, WidgetRef ref, DriverOrder order) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.indigo),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, color: Colors.indigo),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You have arrived at the customer location. Complete delivery with photo proof.',
                  style: TextStyle(color: Colors.indigo[800]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _confirmDelivery(context, ref, order),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Complete Delivery with Photo'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.teal,
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
                onPressed: () => _reportIssue(context, ref, order),
                icon: const Icon(Icons.report_problem),
                label: const Text('Report Issue'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 6: Delivery complete (delivered)
  Widget _buildDeliveryCompleteActions(BuildContext context, WidgetRef ref, DriverOrder order) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green, width: 2),
          ),
          child: Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 12),
              Text(
                'Delivery Completed Successfully!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Thank you for completing this delivery. You can now accept new orders.',
                style: TextStyle(color: Colors.green[700]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.home),
            label: const Text('Return to Dashboard'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue,
            ),
          ),
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
      case DriverOrderStatus.failed:
        return Colors.red.shade800;
    }
  }



  /// Start navigation to vendor and update status to on_route_to_vendor
  Future<void> _startNavigationToVendor(BuildContext context, WidgetRef ref, DriverOrder order) async {
    try {
      debugPrint('DriverDeliveryWorkflow: Starting navigation to vendor for order ${order.id}');

      // Show pre-navigation overview screen
      if (context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => nav.PreNavigationOverviewScreen(
              order: order,
              destination: nav.DriverNavigationDestination.vendor,
              onNavigationStarted: () async {
                // Update order status to on route to vendor when navigation actually starts
                final actions = ref.read(realtimeDriverOrderActionsProvider);
                final result = await actions.updateOrderStatus(order.id, DriverOrderStatus.onRouteToVendor);

                result.when(
                  success: (success) {
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
              },
              onCancel: () {
                // User cancelled navigation, no status update needed
                debugPrint('DriverDeliveryWorkflow: Navigation to vendor cancelled');
              },
            ),
          ),
        );
      }
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
      debugPrint('DriverDeliveryWorkflow: Starting navigation to customer for order ${order.id}');
      debugPrint('DriverDeliveryWorkflow: Current order status: ${order.status.displayName}');

      // Check if we can start navigation to customer
      if (order.status == DriverOrderStatus.pickedUp || order.status == DriverOrderStatus.onRouteToCustomer) {
        // Show pre-navigation overview screen
        if (context.mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => nav.PreNavigationOverviewScreen(
                order: order,
                destination: nav.DriverNavigationDestination.customer,
                onNavigationStarted: () async {
                  // Update order status to on route to customer if needed
                  if (order.status == DriverOrderStatus.pickedUp) {
                    final actions = ref.read(realtimeDriverOrderActionsProvider);
                    final result = await actions.updateOrderStatus(order.id, DriverOrderStatus.onRouteToCustomer);

                    result.when(
                      success: (success) {
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
                  } else {
                    // Already on route, just show success message
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Navigation opened to customer'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                  }
                },
                onCancel: () {
                  // User cancelled navigation, no status update needed
                  debugPrint('DriverDeliveryWorkflow: Navigation to customer cancelled');
                },
              ),
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

  /// Mandatory pickup confirmation with verification checklist
  /// This method cannot be bypassed and enforces order verification
  Future<void> _confirmPickup(BuildContext context, WidgetRef ref, DriverOrder order) async {
    try {
      debugPrint('DriverDeliveryWorkflow: Starting mandatory pickup confirmation for order ${order.id}');

      // Show mandatory pickup confirmation dialog
      // This dialog cannot be dismissed without completing the verification checklist
      await showDialog<void>(
        context: context,
        barrierDismissible: false, // Cannot be dismissed by tapping outside
        builder: (context) => VendorPickupConfirmationDialog(
          order: order,
          onConfirmed: (confirmation) async {
            await _processPickupConfirmation(context, ref, confirmation);
          },
          onCancelled: () {
            // User cancelled pickup confirmation - no action taken
            debugPrint('DriverDeliveryWorkflow: Pickup confirmation cancelled by user');
          },
        ),
      );
    } catch (e) {
      debugPrint('DriverDeliveryWorkflow: Error showing pickup confirmation dialog: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error showing pickup confirmation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Process the pickup confirmation after verification checklist is completed
  Future<void> _processPickupConfirmation(
    BuildContext context,
    WidgetRef ref,
    PickupConfirmation confirmation
  ) async {
    try {
      debugPrint('DriverDeliveryWorkflow: Processing pickup confirmation for order ${confirmation.orderId}');

      // Submit pickup confirmation through the service
      final pickupService = ref.read(pickupConfirmationServiceProvider);
      final result = await pickupService.submitPickupConfirmation(confirmation);

      if (result.isSuccess) {
        debugPrint('DriverDeliveryWorkflow: Pickup confirmation submitted successfully');

        // Update order status using the enhanced workflow provider
        final actions = ref.read(realtimeDriverOrderActionsProvider);
        final statusResult = await actions.confirmPickup(confirmation.orderId);

        statusResult.when(
          success: (success) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pickup confirmed successfully! Order verification completed.'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            }

            // Refresh the order details to show updated status
            ref.invalidate(realtimeOrderDetailsProvider(confirmation.orderId));
          },
          error: (error) {
            debugPrint('DriverDeliveryWorkflow: Failed to update order status: ${error.userFriendlyMessage}');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Pickup confirmed but status update failed: ${error.userFriendlyMessage}'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
        );
      } else {
        debugPrint('DriverDeliveryWorkflow: Failed to submit pickup confirmation: ${result.errorMessage}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to confirm pickup: ${result.errorMessage}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('DriverDeliveryWorkflow: Error processing pickup confirmation: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing pickup confirmation: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }



  /// Mandatory delivery confirmation with photo capture and GPS verification
  /// This method enforces delivery proof requirements and cannot be bypassed
  Future<void> _confirmDelivery(BuildContext context, WidgetRef ref, DriverOrder order) async {
    try {
      debugPrint('DriverDeliveryWorkflow: Starting mandatory delivery confirmation for order ${order.id}');

      // Show mandatory delivery confirmation dialog with photo capture and GPS verification
      // This dialog cannot be dismissed without completing all requirements
      await showDialog<void>(
        context: context,
        barrierDismissible: false, // Cannot be dismissed by tapping outside
        builder: (context) => DriverDeliveryConfirmationDialog(
          order: order,
          onConfirmed: (confirmation) async {
            await _processDeliveryConfirmation(context, ref, confirmation);
          },
          onCancelled: () {
            // User cancelled delivery confirmation - no action taken
            debugPrint('DriverDeliveryWorkflow: Delivery confirmation cancelled by user');
          },
        ),
      );
    } catch (e) {
      debugPrint('DriverDeliveryWorkflow: Error showing delivery confirmation dialog: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error showing delivery confirmation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Process the delivery confirmation after photo capture and GPS verification
  Future<void> _processDeliveryConfirmation(
    BuildContext context,
    WidgetRef ref,
    DeliveryConfirmation confirmation
  ) async {
    try {
      debugPrint('DriverDeliveryWorkflow: Processing delivery confirmation for order ${confirmation.orderId}');
      debugPrint('DriverDeliveryWorkflow: Photo URL: ${confirmation.photoUrl}');
      debugPrint('DriverDeliveryWorkflow: GPS Location: ${confirmation.location.latitude}, ${confirmation.location.longitude}');

      // Submit delivery confirmation through the service
      final deliveryService = ref.read(deliveryConfirmationServiceProvider);
      final result = await deliveryService.submitDeliveryConfirmation(confirmation);

      if (result.isSuccess) {
        debugPrint('DriverDeliveryWorkflow: Delivery confirmation submitted successfully');

        // Complete delivery using the enhanced workflow provider with photo proof
        final actions = ref.read(realtimeDriverOrderActionsProvider);
        final statusResult = await actions.completeDeliveryWithPhoto(
          confirmation.orderId,
          confirmation.photoUrl
        );

        statusResult.when(
          success: (success) {
            debugPrint('DriverDeliveryWorkflow: Delivery completed successfully with photo proof');

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 Delivery completed successfully! Photo proof uploaded.'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 4),
                ),
              );
            }

            // Refresh the order details to show updated status
            ref.invalidate(realtimeOrderDetailsProvider(confirmation.orderId));

            // Navigate back to dashboard after successful delivery
            if (context.mounted) {
              context.go('/driver');
            }
          },
          error: (error) {
            debugPrint('DriverDeliveryWorkflow: Failed to update order status: ${error.userFriendlyMessage}');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Delivery confirmed but status update failed: ${error.userFriendlyMessage}'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
        );
      } else {
        debugPrint('DriverDeliveryWorkflow: Failed to submit delivery confirmation: ${result.errorMessage}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to confirm delivery: ${result.errorMessage}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('DriverDeliveryWorkflow: Error processing delivery confirmation: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing delivery confirmation: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }



  /// Report issue with order (generic method for all workflow steps)
  Future<void> _reportIssue(BuildContext context, WidgetRef ref, DriverOrder order) async {
    // Show issue reporting dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Issue'),
        content: const Text('Issue reporting functionality will be implemented in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Mark arrived at customer (on_route_to_customer → arrived_at_customer)
  Future<void> _markArrivedAtCustomer(BuildContext context, WidgetRef ref, DriverOrder order) async {
    try {
      final actions = ref.read(realtimeDriverOrderActionsProvider);

      debugPrint('DriverDeliveryWorkflow: Marking arrived at customer for order ${order.id}');

      // Update order status to arrived at customer
      final result = await actions.markArrivedAtCustomer(order.id);

      result.when(
        success: (success) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Marked as arrived at customer'),
                backgroundColor: Colors.indigo,
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
      debugPrint('DriverDeliveryWorkflow: Error marking arrived at customer: $e');
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
