import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../drivers/data/models/driver_order.dart';
import '../../../drivers/data/models/pickup_confirmation.dart';
import '../../../drivers/data/models/delivery_confirmation.dart';
import '../../../orders/data/models/driver_order_state_machine.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/enhanced_driver_workflow_providers.dart';
import '../providers/driver_dashboard_providers.dart' hide currentDriverOrderProvider;
import 'vendor_pickup_confirmation_dialog.dart';
import 'driver_delivery_confirmation_dialog.dart';
import 'pickup_instruction_widget.dart';
import 'delivery_instruction_widget.dart';


/// Enhanced action buttons for driver order management with granular workflow support
/// Supports mandatory confirmations and prevents status skipping
class OrderActionButtons extends ConsumerStatefulWidget {
  final DriverOrder order;

  const OrderActionButtons({
    super.key,
    required this.order,
  });

  @override
  ConsumerState<OrderActionButtons> createState() => _OrderActionButtonsState();
}

class _OrderActionButtonsState extends ConsumerState<OrderActionButtons> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = _getAvailableActions();

    if (actions.isEmpty) {
      return _buildNoActionsAvailable(theme);
    }

    return Column(
      children: [
        // Show driver instructions for current status
        _buildStatusInstructions(theme),
        const SizedBox(height: 12),

        // Show action buttons
        if (actions.length == 1)
          _buildSingleActionButton(theme, actions.first)
        else
          _buildMultipleActionButtons(theme, actions),

        // Show loading indicator when updating
        if (_isUpdating) ...[
          const SizedBox(height: 12),
          _buildLoadingIndicator(theme),
        ],
      ],
    );
  }

  Widget _buildNoActionsAvailable(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getStatusMessage(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInstructions(ThemeData theme) {
    final instructions = DriverOrderStateMachine.getDriverInstructions(widget.order.status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              instructions,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Updating order status...',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSingleActionButton(ThemeData theme, EnhancedOrderAction action) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isUpdating ? null : () => _handleAction(action),
        icon: Icon(action.icon),
        label: Text(action.label),
        style: ElevatedButton.styleFrom(
          backgroundColor: action.isPrimary ? theme.colorScheme.primary : action.color,
          foregroundColor: action.isPrimary ? theme.colorScheme.onPrimary : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: action.isPrimary ? 2 : 1,
        ),
      ),
    );
  }

  Widget _buildMultipleActionButtons(ThemeData theme, List<EnhancedOrderAction> actions) {
    // Separate primary and secondary actions
    final primaryActions = actions.where((a) => a.isPrimary).toList();
    final secondaryActions = actions.where((a) => !a.isPrimary).toList();

    return Column(
      children: [
        // Primary actions (full width)
        ...primaryActions.map((action) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildSingleActionButton(theme, action),
        )),

        // Secondary actions (in a row)
        if (secondaryActions.isNotEmpty)
          Row(
            children: secondaryActions.map((action) {
              final isLast = action == secondaryActions.last;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 8),
                  child: OutlinedButton.icon(
                    onPressed: _isUpdating ? null : () => _handleAction(action),
                    icon: Icon(action.icon, size: 18),
                    label: Text(
                      action.label,
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: action.color,
                      side: BorderSide(color: action.color),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  List<EnhancedOrderAction> _getAvailableActions() {
    final actions = <EnhancedOrderAction>[];
    final currentStatus = widget.order.status;

    // Get available actions from state machine
    final driverActions = DriverOrderStateMachine.getAvailableActions(currentStatus);

    for (final driverAction in driverActions) {
      final enhancedAction = _mapDriverActionToEnhancedAction(driverAction);
      if (enhancedAction != null) {
        actions.add(enhancedAction);
      }
    }

    return actions;
  }

  EnhancedOrderAction? _mapDriverActionToEnhancedAction(DriverOrderAction driverAction) {
    switch (driverAction) {
      case DriverOrderAction.navigateToVendor:
        return EnhancedOrderAction(
          driverAction: driverAction,
          label: 'Start Navigation',
          icon: Icons.navigation,
          color: Colors.blue,
          isPrimary: true,
          requiresConfirmation: false,
          description: 'Start GPS navigation to restaurant',
        );

      case DriverOrderAction.arrivedAtVendor:
        return EnhancedOrderAction(
          driverAction: driverAction,
          label: 'Mark Arrived',
          icon: Icons.location_on,
          color: Colors.orange,
          isPrimary: true,
          requiresConfirmation: false,
          description: 'Mark as arrived at restaurant',
        );

      case DriverOrderAction.confirmPickup:
        return EnhancedOrderAction(
          driverAction: driverAction,
          label: 'Confirm Pickup',
          icon: Icons.check_circle,
          color: Colors.green,
          isPrimary: true,
          requiresConfirmation: true,
          description: 'Confirm order pickup with verification',
        );

      case DriverOrderAction.navigateToCustomer:
        return EnhancedOrderAction(
          driverAction: driverAction,
          label: 'Navigate to Customer',
          icon: Icons.navigation,
          color: Colors.blue,
          isPrimary: true,
          requiresConfirmation: false,
          description: 'Start GPS navigation to customer',
        );

      case DriverOrderAction.arrivedAtCustomer:
        return EnhancedOrderAction(
          driverAction: driverAction,
          label: 'Mark Arrived',
          icon: Icons.location_on,
          color: Colors.orange,
          isPrimary: true,
          requiresConfirmation: false,
          description: 'Mark as arrived at customer location',
        );

      case DriverOrderAction.confirmDeliveryWithPhoto:
        return EnhancedOrderAction(
          driverAction: driverAction,
          label: 'Complete Delivery',
          icon: Icons.camera_alt,
          color: Colors.purple,
          isPrimary: true,
          requiresConfirmation: true,
          description: 'Complete delivery with photo proof',
        );

      case DriverOrderAction.cancel:
        return EnhancedOrderAction(
          driverAction: driverAction,
          label: 'Cancel Order',
          icon: Icons.cancel,
          color: Colors.red,
          isPrimary: false,
          requiresConfirmation: true,
          description: 'Cancel this order',
        );

      case DriverOrderAction.reportIssue:
        return EnhancedOrderAction(
          driverAction: driverAction,
          label: 'Report Issue',
          icon: Icons.report_problem,
          color: Colors.orange,
          isPrimary: false,
          requiresConfirmation: true,
          description: 'Report an issue with this order',
        );

      default:
        // Legacy actions or unsupported actions
        return null;
    }
  }

  String _getStatusMessage() {
    switch (widget.order.status) {
      case DriverOrderStatus.delivered:
        return 'Order has been delivered successfully';
      case DriverOrderStatus.cancelled:
        return 'Order has been cancelled';
      case DriverOrderStatus.failed:
        return 'Order delivery failed';
      default:
        return 'No actions available for current status';
    }
  }

  Future<void> _handleAction(EnhancedOrderAction action) async {
    // Validate transition before proceeding
    final validation = DriverOrderStateMachine.validateTransition(
      widget.order.status,
      action.driverAction.targetStatus,
    );

    if (!validation.isValid) {
      _showError('Invalid action: ${validation.errorMessage}');
      return;
    }

    // Handle special actions that require custom dialogs
    switch (action.driverAction) {
      case DriverOrderAction.confirmPickup:
        await _handlePickupConfirmation();
        return;
      case DriverOrderAction.confirmDeliveryWithPhoto:
        await _handleDeliveryConfirmation();
        return;
      case DriverOrderAction.navigateToVendor:
      case DriverOrderAction.navigateToCustomer:
        await _handleNavigation(action);
        return;
      default:
        break;
    }

    // Handle regular actions with optional confirmation
    if (action.requiresConfirmation) {
      final confirmed = await _showConfirmationDialog(action);
      if (!confirmed) return;
    }

    await _updateOrderStatus(action);
  }

  Future<void> _handlePickupConfirmation() async {
    // Show pickup instruction first if needed
    final shouldProceed = await _showPickupInstructions();
    if (!shouldProceed) return;

    // Show mandatory pickup confirmation dialog
    if (mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => VendorPickupConfirmationDialog(
          order: widget.order,
          onConfirmed: (confirmation) async {
            await _submitPickupConfirmation(confirmation);
          },
          onCancelled: () {
            // User cancelled pickup confirmation
          },
        ),
      );
    }
  }

  Future<void> _handleDeliveryConfirmation() async {
    // Show delivery instruction first if needed
    final shouldProceed = await _showDeliveryInstructions();
    if (!shouldProceed) return;

    // Show mandatory delivery confirmation dialog
    if (mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => DriverDeliveryConfirmationDialog(
          order: widget.order,
          onConfirmed: (confirmation) async {
            await _submitDeliveryConfirmation(confirmation);
          },
          onCancelled: () {
            // User cancelled delivery confirmation
          },
        ),
      );
    }
  }

  Future<void> _handleNavigation(EnhancedOrderAction action) async {
    // TODO: Integrate with navigation service
    // For now, just update the status
    await _updateOrderStatus(action);

    // Show navigation hint
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigation started. ${action.description}'),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Open Maps',
            textColor: Colors.white,
            onPressed: () {
              // TODO: Open external navigation app
            },
          ),
        ),
      );
    }
  }

  Future<bool> _showPickupInstructions() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        child: PickupInstructionWidget(
          order: widget.order,
          onProceedToConfirmation: () => Navigator.of(context).pop(true),
        ),
      ),
    ) ?? false;
  }

  Future<bool> _showDeliveryInstructions() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        child: DeliveryInstructionWidget(
          order: widget.order,
          onProceedToConfirmation: () => Navigator.of(context).pop(true),
        ),
      ),
    ) ?? false;
  }

  Future<void> _submitPickupConfirmation(PickupConfirmation confirmation) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final service = ref.read(pickupConfirmationServiceProvider);
      final result = await service.submitPickupConfirmation(confirmation);

      if (result.isSuccess) {
        // Process enhanced workflow integration
        await _processWorkflowIntegration(
          fromStatus: widget.order.status,
          toStatus: DriverOrderStatus.pickedUp,
          additionalData: {'pickup_confirmation': confirmation.toJson()},
        );

        _showSuccess('Pickup confirmed successfully');
        _refreshData();
      } else {
        _showError('Failed to confirm pickup: ${result.errorMessage}');
      }
    } catch (e) {
      _showError('Failed to confirm pickup: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _submitDeliveryConfirmation(DeliveryConfirmation confirmation) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final service = ref.read(deliveryConfirmationServiceProvider);
      final result = await service.submitDeliveryConfirmation(confirmation);

      if (result.isSuccess) {
        // Process enhanced workflow integration
        await _processWorkflowIntegration(
          fromStatus: widget.order.status,
          toStatus: DriverOrderStatus.delivered,
          additionalData: {'delivery_confirmation': confirmation.toJson()},
        );

        _showSuccess('Delivery completed successfully');
        _refreshData();
      } else {
        _showError('Failed to complete delivery: ${result.errorMessage}');
      }
    } catch (e) {
      _showError('Failed to complete delivery: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _updateOrderStatus(EnhancedOrderAction action) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      // Use the enhanced RPC function for status updates
      final supabase = Supabase.instance.client;
      final result = await supabase.rpc(
        'update_driver_order_status_v2',
        params: {
          'p_order_id': widget.order.id,
          'p_new_status': action.driverAction.targetStatus.value,
          'p_notes': action.description,
        },
      );

      if (result == null || result == false) {
        throw Exception('Failed to update order status via RPC function');
      }

      _showSuccess('${action.label} completed successfully');
      _refreshData();

    } catch (e) {
      _showError('Failed to ${action.label.toLowerCase()}: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }
  Future<bool> _showConfirmationDialog(EnhancedOrderAction action) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm ${action.label}'),
        content: Text(
          'Are you sure you want to ${action.description.toLowerCase()}?\n\n'
          'Order: #${widget.order.orderNumber}\n'
          'Customer: ${widget.order.customerName}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: action.color,
              foregroundColor: Colors.white,
            ),
            child: Text(action.label),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Process enhanced workflow integration
  Future<void> _processWorkflowIntegration({
    required DriverOrderStatus fromStatus,
    required DriverOrderStatus toStatus,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final integrationService = ref.read(enhancedWorkflowIntegrationServiceProvider);

      // Get driver ID
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId == null) return;

      final supabase = Supabase.instance.client;
      final driverResponse = await supabase
          .from('drivers')
          .select('id')
          .eq('user_id', userId)
          .single();

      final driverId = driverResponse['id'] as String;

      // Process workflow integration
      await integrationService.processOrderStatusChange(
        orderId: widget.order.id,
        fromStatus: fromStatus,
        toStatus: toStatus,
        driverId: driverId,
        additionalData: additionalData,
      );
    } catch (e) {
      debugPrint('❌ [ORDER-ACTIONS] Failed to process workflow integration: $e');
      // Don't fail the main workflow for integration issues
    }
  }

  void _refreshData() {
    // Refresh all relevant providers including enhanced ones
    ref.invalidate(enhancedCurrentDriverOrderProvider);
    ref.invalidate(todayEarningsProvider);
    ref.invalidate(enhancedTodayEarningsProvider);
    ref.invalidate(enhancedAvailableOrdersProvider);
  }
}

/// Enhanced order action with granular workflow support
class EnhancedOrderAction {
  final DriverOrderAction driverAction;
  final String label;
  final IconData icon;
  final Color color;
  final bool isPrimary;
  final bool requiresConfirmation;
  final String description;

  const EnhancedOrderAction({
    required this.driverAction,
    required this.label,
    required this.icon,
    required this.color,
    required this.isPrimary,
    required this.requiresConfirmation,
    required this.description,
  });
}
