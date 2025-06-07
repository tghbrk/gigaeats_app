import 'package:flutter/material.dart';

import '../data/models/delivery_method.dart';
import '../../customers/data/models/customer.dart';

class DeliveryInformationSection extends StatefulWidget {
  final DeliveryMethod? deliveryMethod;
  final Customer? selectedCustomer;
  final Map<String, dynamic> deliveryInfo;
  final Function(Map<String, dynamic>) onDeliveryInfoChanged;
  final bool enabled;

  const DeliveryInformationSection({
    super.key,
    this.deliveryMethod,
    this.selectedCustomer,
    required this.deliveryInfo,
    required this.onDeliveryInfoChanged,
    this.enabled = true,
  });

  @override
  State<DeliveryInformationSection> createState() => _DeliveryInformationSectionState();
}

class _DeliveryInformationSectionState extends State<DeliveryInformationSection> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateControllers();
  }

  @override
  void didUpdateWidget(DeliveryInformationSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCustomer != widget.selectedCustomer ||
        oldWidget.deliveryMethod != widget.deliveryMethod) {
      _updateControllers();
    }
  }

  void _updateControllers() {
    _notesController.text = widget.deliveryInfo['notes'] ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _updateDeliveryInfo() {
    final updatedInfo = Map<String, dynamic>.from(widget.deliveryInfo);
    // Address and contact info are now auto-populated from customer data
    if (widget.selectedCustomer != null) {
      updatedInfo['address'] = widget.selectedCustomer!.address.fullAddress;
      updatedInfo['contact'] = widget.selectedCustomer!.phoneNumber;
    }
    updatedInfo['notes'] = _notesController.text;
    widget.onDeliveryInfoChanged(updatedInfo);
  }

  Widget _buildDeliveryAddressInfo() {
    if (widget.selectedCustomer == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border.all(color: Colors.orange.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_outlined, color: Colors.orange.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Please select a customer to auto-populate delivery address.',
                style: TextStyle(color: Colors.orange.shade700),
              ),
            ),
          ],
        ),
      );
    }

    final customer = widget.selectedCustomer!;
    final address = customer.address;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Delivery Address Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.grey.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Delivery Address',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Auto-filled',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                address.fullAddress,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (address.deliveryInstructions != null && address.deliveryInstructions!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Instructions: ${address.deliveryInstructions}',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Contact Information Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.phone, color: Colors.grey.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Contact Information',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Auto-filled',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                customer.phoneNumber,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (customer.alternatePhoneNumber != null && customer.alternatePhoneNumber!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Alt: ${customer.alternatePhoneNumber}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.deliveryMethod == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        if (widget.deliveryMethod == DeliveryMethod.customerPickup) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Customer will collect the order from the vendor location. No delivery address required.',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Auto-populated Delivery Information (Read-only)
          _buildDeliveryAddressInfo(),
          const SizedBox(height: 16),

          // Delivery Method Specific Info
          if (widget.deliveryMethod == DeliveryMethod.lalamove) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_shipping, color: Colors.orange.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Lalamove delivery will be arranged. Delivery fee will be calculated based on distance.',
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (widget.deliveryMethod == DeliveryMethod.ownFleet) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.delivery_dining, color: Colors.green.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Order will be delivered by our own delivery team.',
                      style: TextStyle(color: Colors.green.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],

        // Delivery Notes
        TextFormField(
          controller: _notesController,
          enabled: widget.enabled,
          decoration: const InputDecoration(
            labelText: 'Delivery Notes (Optional)',
            hintText: 'Any special instructions for delivery',
            prefixIcon: Icon(Icons.note),
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (_) => _updateDeliveryInfo(),
        ),
      ],
    );
  }
}
