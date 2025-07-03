import 'package:flutter/material.dart';

import '../data/models/delivery_method.dart';

class DeliveryMethodSelector extends StatefulWidget {
  final DeliveryMethod? selectedMethod;
  final Function(DeliveryMethod?) onMethodSelected;
  final bool enabled;

  const DeliveryMethodSelector({
    super.key,
    this.selectedMethod,
    required this.onMethodSelected,
    this.enabled = true,
  });

  @override
  State<DeliveryMethodSelector> createState() => _DeliveryMethodSelectorState();
}

class _DeliveryMethodSelectorState extends State<DeliveryMethodSelector> {
  final List<DeliveryMethod> _deliveryMethods = [
    DeliveryMethod.customerPickup,
    DeliveryMethod.ownFleet,
    DeliveryMethod.thirdParty,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Method',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ..._deliveryMethods.map((method) => _buildMethodTile(method)),
      ],
    );
  }

  Widget _buildMethodTile(DeliveryMethod method) {
    final isSelected = widget.selectedMethod == method;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.05) : null,
      ),
      child: RadioListTile<DeliveryMethod>(
        value: method,
        groupValue: widget.selectedMethod,
        onChanged: widget.enabled ? widget.onMethodSelected : null,
        title: Text(
          _getMethodTitle(method),
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(_getMethodDescription(method)),
        secondary: Icon(
          _getMethodIcon(method),
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade600,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  String _getMethodTitle(DeliveryMethod method) {
    switch (method) {
      case DeliveryMethod.customerPickup:
        return 'Customer Pickup';
      case DeliveryMethod.ownFleet:
        return 'Own Delivery Fleet';
      case DeliveryMethod.thirdParty:
        return 'Lalamove Delivery';
      case DeliveryMethod.salesAgentPickup:
        return 'Sales Agent Pickup';
    }
  }

  String _getMethodDescription(DeliveryMethod method) {
    switch (method) {
      case DeliveryMethod.customerPickup:
        return 'Customer will collect the order from vendor location';
      case DeliveryMethod.ownFleet:
        return 'Delivered by our own delivery team';
      case DeliveryMethod.thirdParty:
        return 'Third-party delivery via Lalamove service';
      case DeliveryMethod.salesAgentPickup:
        return 'Sales agent will collect and deliver the order';
    }
  }

  IconData _getMethodIcon(DeliveryMethod method) {
    switch (method) {
      case DeliveryMethod.customerPickup:
        return Icons.store;
      case DeliveryMethod.ownFleet:
        return Icons.delivery_dining;
      case DeliveryMethod.thirdParty:
        return Icons.local_shipping;
      case DeliveryMethod.salesAgentPickup:
        return Icons.person;
    }
  }
}
