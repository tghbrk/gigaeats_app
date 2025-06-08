import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/order.dart';
import '../../data/models/delivery_method.dart';

class DeliveryManagementDialog extends ConsumerStatefulWidget {
  final Order order;
  final Function(DeliveryInfo) onDeliveryArranged;

  const DeliveryManagementDialog({
    super.key,
    required this.order,
    required this.onDeliveryArranged,
  });

  @override
  ConsumerState<DeliveryManagementDialog> createState() => _DeliveryManagementDialogState();
}

class _DeliveryManagementDialogState extends ConsumerState<DeliveryManagementDialog> {
  DeliveryMethod _selectedMethod = DeliveryMethod.customerPickup;
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _vehicleInfoController = TextEditingController();
  final _specialInstructionsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _vehicleInfoController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_shipping,
                    color: theme.colorScheme.onPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Arrange Delivery',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Info
                    _buildOrderInfo(),
                    const SizedBox(height: 24),

                    // Delivery Method Selection
                    _buildDeliveryMethodSelection(),
                    const SizedBox(height: 20),

                    // Method-specific fields
                    _buildMethodSpecificFields(),
                    const SizedBox(height: 20),

                    // Special Instructions
                    _buildSpecialInstructions(),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _arrangeDelivery,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Arrange Delivery'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfo() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order #${widget.order.orderNumber}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customer: ${widget.order.customerName}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Total: RM ${widget.order.totalAmount.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Delivery Date: ${widget.order.deliveryDate.toString().split(' ')[0]}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryMethodSelection() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Method',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...DeliveryMethod.values.map((method) => _buildMethodOption(method)),
      ],
    );
  }

  Widget _buildMethodOption(DeliveryMethod method) {
    final theme = Theme.of(context);
    final isSelected = _selectedMethod == method;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedMethod = method),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected 
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : null,
          ),
          child: Row(
            children: [
              Radio<DeliveryMethod>(
                value: method,
                groupValue: _selectedMethod,
                onChanged: (value) => setState(() => _selectedMethod = value!),
              ),
              const SizedBox(width: 12),
              Icon(_getMethodIcon(method)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _getMethodDescription(method),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodSpecificFields() {
    switch (_selectedMethod) {
      case DeliveryMethod.lalamove:
        return _buildLalamoveFields();
      case DeliveryMethod.ownFleet:
        return _buildOwnFleetFields();
      case DeliveryMethod.customerPickup:
      case DeliveryMethod.salesAgentPickup:
        return _buildPickupFields();
    }
  }

  Widget _buildLalamoveFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Lalamove Integration',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Lalamove API integration will be available in Phase 2. For now, you can manually arrange Lalamove delivery and update the order status.',
          ),
        ],
      ),
    );
  }

  Widget _buildOwnFleetFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _driverNameController,
          decoration: const InputDecoration(
            labelText: 'Driver Name *',
            hintText: 'Enter driver name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _driverPhoneController,
          decoration: const InputDecoration(
            labelText: 'Driver Phone *',
            hintText: 'Enter driver phone number',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _vehicleInfoController,
          decoration: const InputDecoration(
            labelText: 'Vehicle Info',
            hintText: 'e.g., Honda City - ABC1234',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildPickupFields() {

    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              Text(
                _selectedMethod == DeliveryMethod.customerPickup 
                    ? 'Customer Pickup' 
                    : 'Sales Agent Pickup',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _selectedMethod == DeliveryMethod.customerPickup
                ? 'Customer will collect the order from your location. Please coordinate pickup time and provide clear instructions.'
                : 'Sales agent will collect the order and deliver to customer. Please coordinate pickup time.',
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialInstructions() {
    return TextField(
      controller: _specialInstructionsController,
      decoration: const InputDecoration(
        labelText: 'Special Instructions',
        hintText: 'Any special delivery instructions...',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  IconData _getMethodIcon(DeliveryMethod method) {
    switch (method) {
      case DeliveryMethod.lalamove:
        return Icons.delivery_dining;
      case DeliveryMethod.ownFleet:
        return Icons.local_shipping;
      case DeliveryMethod.customerPickup:
        return Icons.store;
      case DeliveryMethod.salesAgentPickup:
        return Icons.person;
    }
  }

  String _getMethodDescription(DeliveryMethod method) {
    switch (method) {
      case DeliveryMethod.lalamove:
        return 'Book delivery through Lalamove service';
      case DeliveryMethod.ownFleet:
        return 'Assign to your own delivery driver';
      case DeliveryMethod.customerPickup:
        return 'Customer will collect from your location';
      case DeliveryMethod.salesAgentPickup:
        return 'Sales agent will collect and deliver';
    }
  }

  void _arrangeDelivery() {
    // Validate required fields
    if (_selectedMethod == DeliveryMethod.ownFleet) {
      if (_driverNameController.text.trim().isEmpty || 
          _driverPhoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in driver name and phone number'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    // Create delivery info
    final deliveryInfo = DeliveryInfo(
      method: _selectedMethod,
      driverName: _selectedMethod == DeliveryMethod.ownFleet 
          ? _driverNameController.text.trim() 
          : null,
      driverPhone: _selectedMethod == DeliveryMethod.ownFleet 
          ? _driverPhoneController.text.trim() 
          : null,
      vehicleInfo: _selectedMethod == DeliveryMethod.ownFleet 
          ? _vehicleInfoController.text.trim() 
          : null,
      specialInstructions: _specialInstructionsController.text.trim().isNotEmpty 
          ? _specialInstructionsController.text.trim() 
          : null,
    );

    // Simulate processing delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pop();
        widget.onDeliveryArranged(deliveryInfo);
      }
    });
  }
}
