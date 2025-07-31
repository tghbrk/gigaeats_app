import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/batch_operation_results.dart';
import '../../../data/models/delivery_batch.dart';
import '../../../../orders/data/models/order.dart';

/// Order sequence card with drag-and-drop functionality for reordering
/// Displays order details with pickup/delivery status and action buttons
class OrderSequenceCard extends ConsumerStatefulWidget {
  final BatchOrderWithDetails batchOrder;
  final int sequence;
  final bool isActive;
  final Function(String orderId, int newPosition)? onReorder;
  final Function(String orderId, String action)? onOrderAction;

  const OrderSequenceCard({
    super.key,
    required this.batchOrder,
    required this.sequence,
    this.isActive = false,
    this.onReorder,
    this.onOrderAction,
  });

  @override
  ConsumerState<OrderSequenceCard> createState() => _OrderSequenceCardState();
}

class _OrderSequenceCardState extends ConsumerState<OrderSequenceCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(OrderSequenceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = widget.batchOrder.order;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isActive ? _pulseAnimation.value : 1.0,
          child: Draggable<BatchOrderWithDetails>(
            data: widget.batchOrder,
            feedback: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 32,
                child: _buildCardContent(theme, order, isDragging: true),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.5,
              child: _buildCardContent(theme, order),
            ),
            child: DragTarget<BatchOrderWithDetails>(
              onAcceptWithDetails: (details) {
                if (details.data.order.id != widget.batchOrder.order.id) {
                  widget.onReorder?.call(details.data.order.id, widget.sequence);
                }
              },
              builder: (context, candidateData, rejectedData) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: candidateData.isNotEmpty
                        ? Border.all(
                            color: theme.colorScheme.primary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: _buildCardContent(theme, order),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardContent(ThemeData theme, Order order, {bool isDragging = false}) {
    return Card(
      elevation: isDragging ? 8 : 2,
      margin: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: widget.isActive
              ? Border.all(
                  color: theme.colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: Column(
          children: [
            _buildHeader(theme, order),
            if (_isExpanded) _buildExpandedContent(theme, order),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Order order) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Sequence number
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: widget.isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${widget.sequence}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: widget.isActive
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.outline,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Order info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Order #${order.orderNumber}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getPickupStatusColor(widget.batchOrder.pickupStatus),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getPickupStatusText(widget.batchOrder.pickupStatus),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.vendorName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${order.deliveryAddress.street}, ${order.deliveryAddress.city}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Status indicators
            Column(
              children: [
                _buildPickupStatusIndicator(
                  theme,
                  icon: Icons.store,
                  status: widget.batchOrder.pickupStatus,
                  label: 'Pickup',
                ),
                const SizedBox(height: 4),
                _buildDeliveryStatusIndicator(
                  theme,
                  icon: Icons.home,
                  status: widget.batchOrder.deliveryStatus,
                  label: 'Delivery',
                ),
              ],
            ),
            
            const SizedBox(width: 8),
            
            // Expand/collapse icon
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickupStatusIndicator(
    ThemeData theme, {
    required IconData icon,
    required BatchOrderPickupStatus status,
    required String label,
  }) {
    final color = _getPickupStatusColor(status);

    return Tooltip(
      message: '$label: ${_getPickupStatusText(status)}',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 16,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDeliveryStatusIndicator(
    ThemeData theme, {
    required IconData icon,
    required BatchOrderDeliveryStatus status,
    required String label,
  }) {
    final color = _getDeliveryStatusColor(status);

    return Tooltip(
      message: '$label: ${_getDeliveryStatusText(status)}',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 16,
          color: color,
        ),
      ),
    );
  }

  Widget _buildExpandedContent(ThemeData theme, Order order) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          
          // Order details
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  theme,
                  icon: Icons.shopping_bag,
                  label: 'Items',
                  value: '${order.items.length}',
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  theme,
                  icon: Icons.attach_money,
                  label: 'Total',
                  value: 'RM ${order.totalAmount.toStringAsFixed(2)}',
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  theme,
                  icon: Icons.access_time,
                  label: 'Est. Time',
                  value: _getEstimatedTime(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.onOrderAction?.call(order.id, 'navigate'),
                  icon: const Icon(Icons.navigation),
                  label: const Text('Navigate'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _getNextAction() != null
                      ? () => widget.onOrderAction?.call(order.id, _getNextAction()!)
                      : null,
                  icon: Icon(_getNextActionIcon()),
                  label: Text(_getNextActionText()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Color _getPickupStatusColor(BatchOrderPickupStatus status) {
    switch (status) {
      case BatchOrderPickupStatus.pending:
        return Colors.grey;
      case BatchOrderPickupStatus.inProgress:
        return Colors.blue;
      case BatchOrderPickupStatus.completed:
        return Colors.green;
      case BatchOrderPickupStatus.failed:
        return Colors.red;
    }
  }

  String _getPickupStatusText(BatchOrderPickupStatus status) {
    switch (status) {
      case BatchOrderPickupStatus.pending:
        return 'Pending';
      case BatchOrderPickupStatus.inProgress:
        return 'In Progress';
      case BatchOrderPickupStatus.completed:
        return 'Completed';
      case BatchOrderPickupStatus.failed:
        return 'Failed';
    }
  }

  Color _getDeliveryStatusColor(BatchOrderDeliveryStatus status) {
    switch (status) {
      case BatchOrderDeliveryStatus.pending:
        return Colors.grey;
      case BatchOrderDeliveryStatus.inProgress:
        return Colors.blue;
      case BatchOrderDeliveryStatus.completed:
        return Colors.green;
      case BatchOrderDeliveryStatus.failed:
        return Colors.red;
    }
  }

  String _getDeliveryStatusText(BatchOrderDeliveryStatus status) {
    switch (status) {
      case BatchOrderDeliveryStatus.pending:
        return 'Pending';
      case BatchOrderDeliveryStatus.inProgress:
        return 'In Progress';
      case BatchOrderDeliveryStatus.completed:
        return 'Completed';
      case BatchOrderDeliveryStatus.failed:
        return 'Failed';
    }
  }

  String? _getNextAction() {
    switch (widget.batchOrder.pickupStatus) {
      case BatchOrderPickupStatus.pending:
        return 'start_pickup';
      case BatchOrderPickupStatus.inProgress:
        return 'complete_pickup';
      case BatchOrderPickupStatus.completed:
        switch (widget.batchOrder.deliveryStatus) {
          case BatchOrderDeliveryStatus.pending:
            return 'start_delivery';
          case BatchOrderDeliveryStatus.inProgress:
            return 'complete_delivery';
          case BatchOrderDeliveryStatus.completed:
            return null;
          case BatchOrderDeliveryStatus.failed:
            return 'retry_delivery';
        }
      case BatchOrderPickupStatus.failed:
        return 'retry_pickup';
    }
  }

  IconData _getNextActionIcon() {
    final action = _getNextAction();
    switch (action) {
      case 'start_pickup':
        return Icons.play_arrow;
      case 'complete_pickup':
        return Icons.shopping_bag;
      case 'start_delivery':
        return Icons.local_shipping;
      case 'complete_delivery':
        return Icons.check;
      case 'retry_pickup':
        return Icons.refresh;
      case 'retry_delivery':
        return Icons.refresh;
      default:
        return Icons.check_circle;
    }
  }

  String _getNextActionText() {
    final action = _getNextAction();
    switch (action) {
      case 'start_pickup':
        return 'Start Pickup';
      case 'complete_pickup':
        return 'Complete Pickup';
      case 'start_delivery':
        return 'Start Delivery';
      case 'complete_delivery':
        return 'Complete Delivery';
      case 'retry_pickup':
        return 'Retry Pickup';
      case 'retry_delivery':
        return 'Retry Delivery';
      default:
        return 'Completed';
    }
  }

  /// Calculate estimated time based on order status and distance
  String _getEstimatedTime() {
    final batchOrder = widget.batchOrder.batchOrder;
    final order = widget.batchOrder.order;

    // If we have actual timing data, use it
    if (batchOrder.actualPickupTime != null && batchOrder.actualDeliveryTime != null) {
      return 'Completed';
    }

    // If pickup is completed, estimate delivery time
    if (batchOrder.pickupStatus == BatchOrderPickupStatus.completed) {
      if (batchOrder.estimatedDeliveryTime != null) {
        final now = DateTime.now();
        final diff = batchOrder.estimatedDeliveryTime!.difference(now);
        if (diff.inMinutes > 0) {
          return '${diff.inMinutes} min';
        }
      }
      return '8-12 min'; // Default delivery estimate
    }

    // If pickup is in progress, estimate pickup completion
    if (batchOrder.pickupStatus == BatchOrderPickupStatus.inProgress) {
      return '5-10 min';
    }

    // Base time calculation based on order status and travel time
    int baseTime = 15; // Default base time

    // Add travel time if available
    if (batchOrder.travelTimeFromPreviousMinutes != null) {
      baseTime += batchOrder.travelTimeFromPreviousMinutes!;
    }

    // Adjust based on order status
    switch (order.status) {
      case OrderStatus.pending:
        baseTime += 10;
        break;
      case OrderStatus.confirmed:
        baseTime += 5;
        break;
      case OrderStatus.preparing:
        baseTime += 2;
        break;
      case OrderStatus.ready:
        // No additional time
        break;
      case OrderStatus.delivered:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      default:
        break;
    }

    return '$baseTime-${baseTime + 5} min';
  }
}
