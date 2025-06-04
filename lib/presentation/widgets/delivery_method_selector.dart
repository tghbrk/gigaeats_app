import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/delivery_method.dart';
import '../providers/cart_provider.dart';

class DeliveryMethodSelector extends ConsumerWidget {
  final DeliveryMethod selectedMethod;
  final Function(DeliveryMethod) onMethodSelected;
  final double subtotal;

  const DeliveryMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodSelected,
    required this.subtotal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Method',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Delivery method options
            ...DeliveryMethod.values.map((method) => _buildMethodOption(
              context,
              method,
              _getMethodIcon(method),
              _getMethodDescription(method),
              _calculateFee(method, subtotal),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodOption(
    BuildContext context,
    DeliveryMethod method,
    IconData icon,
    String description,
    double fee,
  ) {
    final theme = Theme.of(context);
    final isSelected = selectedMethod == method;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => onMethodSelected(method),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected 
                ? theme.colorScheme.primary 
                : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected 
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : null,
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Method details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected 
                          ? theme.colorScheme.primary 
                          : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fee == 0 ? 'FREE' : 'RM ${fee.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: fee == 0 
                        ? Colors.green 
                        : isSelected 
                          ? theme.colorScheme.primary 
                          : null,
                    ),
                  ),
                  if (fee == 0 && !method.isPickup) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Min RM ${_getFreeDeliveryThreshold(method)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              
              // Selection indicator
              const SizedBox(width: 12),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.outline,
                    width: 2,
                  ),
                  color: isSelected 
                    ? theme.colorScheme.primary 
                    : null,
                ),
                child: isSelected 
                  ? Icon(
                      Icons.check,
                      size: 12,
                      color: theme.colorScheme.onPrimary,
                    )
                  : null,
              ),
            ],
          ),
        ),
      ),
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
        return Icons.person_pin_circle;
    }
  }

  String _getMethodDescription(DeliveryMethod method) {
    switch (method) {
      case DeliveryMethod.lalamove:
        return 'Fast delivery via Lalamove service';
      case DeliveryMethod.ownFleet:
        return 'Standard delivery by our team';
      case DeliveryMethod.customerPickup:
        return 'Customer picks up from vendor location';
      case DeliveryMethod.salesAgentPickup:
        return 'Sales agent will collect and deliver';
    }
  }

  double _calculateFee(DeliveryMethod method, double subtotal) {
    // Pickup methods have no delivery fee
    if (method.isPickup) return 0.0;
    
    switch (method) {
      case DeliveryMethod.lalamove:
        // Premium pricing for Lalamove
        if (subtotal >= 200) return 0.0;
        if (subtotal >= 100) return 15.0;
        return 20.0;
        
      case DeliveryMethod.ownFleet:
        // Standard pricing for own fleet
        if (subtotal >= 200) return 0.0;
        if (subtotal >= 100) return 5.0;
        return 10.0;
        
      case DeliveryMethod.customerPickup:
      case DeliveryMethod.salesAgentPickup:
        return 0.0;
    }
  }

  int _getFreeDeliveryThreshold(DeliveryMethod method) {
    switch (method) {
      case DeliveryMethod.lalamove:
      case DeliveryMethod.ownFleet:
        return 200;
      case DeliveryMethod.customerPickup:
      case DeliveryMethod.salesAgentPickup:
        return 0;
    }
  }
}
