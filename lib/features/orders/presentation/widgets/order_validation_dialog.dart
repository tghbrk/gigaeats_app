import 'package:flutter/material.dart';
import '../../data/models/order.dart';
import '../../data/utils/order_validation_utils.dart';

/// Dialog widget for showing order status validation errors and suggestions
class OrderValidationDialog extends StatelessWidget {
  final OrderStatus currentStatus;
  final OrderStatus attemptedStatus;
  final String userRole;
  final OrderValidationResult validationResult;

  const OrderValidationDialog({
    super.key,
    required this.currentStatus,
    required this.attemptedStatus,
    required this.userRole,
    required this.validationResult,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text('Invalid Status Update'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error message
          Text(
            validationResult.errorMessage ?? 'Unknown validation error',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          
          const SizedBox(height: 16),
          
          // Current status info
          _buildStatusInfo(
            context,
            'Current Status',
            currentStatus,
            _getStatusColor(currentStatus),
          ),
          
          const SizedBox(height: 8),
          
          // Attempted status info
          _buildStatusInfo(
            context,
            'Attempted Status',
            attemptedStatus,
            Colors.red.withOpacity(0.7),
          ),
          
          const SizedBox(height: 16),
          
          // Valid next statuses
          _buildValidNextStatuses(context),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _buildStatusInfo(
    BuildContext context,
    String label,
    OrderStatus status,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          status.displayName,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildValidNextStatuses(BuildContext context) {
    final validStatuses = OrderValidationUtils.getValidNextStatuses(currentStatus);
    
    if (validStatuses.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Valid Next Actions:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No further status changes allowed (final state)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Valid Next Statuses:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...validStatuses.map((status) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                Icons.arrow_forward,
                size: 16,
                color: _getStatusColor(status),
              ),
              const SizedBox(width: 8),
              Text(
                status.displayName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _getStatusColor(status),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.ready:
        return Colors.teal;
      case OrderStatus.outForDelivery:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  /// Show validation dialog for order status update errors
  static Future<void> showValidationError(
    BuildContext context, {
    required OrderStatus currentStatus,
    required OrderStatus attemptedStatus,
    required String userRole,
    required OrderValidationResult validationResult,
  }) {
    return showDialog(
      context: context,
      builder: (context) => OrderValidationDialog(
        currentStatus: currentStatus,
        attemptedStatus: attemptedStatus,
        userRole: userRole,
        validationResult: validationResult,
      ),
    );
  }

  /// Show a simple error dialog with just the error message
  static Future<void> showSimpleError(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
