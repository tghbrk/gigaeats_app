import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/delivery_method.dart';
import '../../data/models/delivery_fee_calculation.dart';

import '../../../../presentation/providers/repository_providers.dart';

/// Enhanced delivery method selector with real-time fee calculation
class EnhancedDeliveryMethodSelector extends ConsumerStatefulWidget {
  final DeliveryMethod selectedMethod;
  final Function(DeliveryMethod) onMethodSelected;
  final double subtotal;
  final String? vendorId;
  final double? deliveryLatitude;
  final double? deliveryLongitude;

  const EnhancedDeliveryMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodSelected,
    required this.subtotal,
    this.vendorId,
    this.deliveryLatitude,
    this.deliveryLongitude,
  });

  @override
  ConsumerState<EnhancedDeliveryMethodSelector> createState() => _EnhancedDeliveryMethodSelectorState();
}

class _EnhancedDeliveryMethodSelectorState extends ConsumerState<EnhancedDeliveryMethodSelector> {
  final Map<DeliveryMethod, DeliveryFeeCalculation?> _feeCalculations = {};
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _calculateAllFees();
  }

  @override
  void didUpdateWidget(EnhancedDeliveryMethodSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Recalculate fees if relevant parameters changed
    if (oldWidget.subtotal != widget.subtotal ||
        oldWidget.vendorId != widget.vendorId ||
        oldWidget.deliveryLatitude != widget.deliveryLatitude ||
        oldWidget.deliveryLongitude != widget.deliveryLongitude) {
      _calculateAllFees();
    }
  }

  Future<void> _calculateAllFees() async {
    if (widget.vendorId == null || _isCalculating) return;

    setState(() {
      _isCalculating = true;
    });

    final deliveryFeeService = ref.read(deliveryFeeServiceProvider);

    // Calculate fees for all delivery methods
    for (final method in DeliveryMethod.values) {
      try {
        final calculation = await deliveryFeeService.calculateDeliveryFee(
          deliveryMethod: method,
          vendorId: widget.vendorId!,
          subtotal: widget.subtotal,
          deliveryLatitude: widget.deliveryLatitude,
          deliveryLongitude: widget.deliveryLongitude,
        );

        if (mounted) {
          setState(() {
            _feeCalculations[method] = calculation;
          });
        }
      } catch (e) {
        // Use fallback calculation on error
        if (mounted) {
          setState(() {
            _feeCalculations[method] = _getFallbackCalculation(method);
          });
        }
      }
    }

    if (mounted) {
      setState(() {
        _isCalculating = false;
      });
    }
  }

  DeliveryFeeCalculation _getFallbackCalculation(DeliveryMethod method) {
    if (method.isPickup) {
      return DeliveryFeeCalculation.pickup(method.value);
    }

    double fee = 0.0;
    switch (method) {
      case DeliveryMethod.lalamove:
        if (widget.subtotal >= 200) {
          fee = 0.0;
        } else if (widget.subtotal >= 100) {
          fee = 15.0;
        } else {
          fee = 20.0;
        }
        break;
      case DeliveryMethod.ownFleet:
        if (widget.subtotal >= 200) {
          fee = 0.0;
        } else if (widget.subtotal >= 100) {
          fee = 5.0;
        } else {
          fee = 10.0;
        }
        break;
      case DeliveryMethod.customerPickup:
      case DeliveryMethod.salesAgentPickup:
        fee = 0.0;
        break;
    }

    return DeliveryFeeCalculation(
      finalFee: fee,
      baseFee: fee,
      distanceFee: 0.0,
      surgeMultiplier: 1.0,
      discountAmount: 0.0,
      distanceKm: 0.0,
      breakdown: {
        'method': method.value,
        'calculation_type': 'fallback',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Delivery Method',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isCalculating) ...[
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            
            // Delivery method options - Only show Own Fleet and pickup options
            ...DeliveryMethod.values
                .where((method) => method != DeliveryMethod.lalamove) // Remove Lalamove option
                .map((method) => _buildMethodOption(
              context,
              method,
              _getMethodIcon(method),
              _getMethodDescription(method),
              _feeCalculations[method],
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
    DeliveryFeeCalculation? calculation,
  ) {
    final theme = Theme.of(context);
    final isSelected = widget.selectedMethod == method;
    final fee = calculation?.finalFee ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => widget.onMethodSelected(method),
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
          child: Column(
            children: [
              Row(
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
                        calculation?.formattedFee ?? 'RM${fee.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: fee == 0 
                            ? Colors.green 
                            : isSelected 
                              ? theme.colorScheme.primary 
                              : null,
                        ),
                      ),
                      if (calculation?.hasDiscount == true) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Saved RM${calculation!.discountAmount.toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
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
              
              // Fee breakdown (if available and selected)
              if (isSelected && calculation != null && calculation.finalFee > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fee Breakdown',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...calculation.displayBreakdown.entries.map((entry) => 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                entry.value,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: entry.key == 'Total' 
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
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
        return 'Reliable delivery by our own fleet with GPS tracking';
      case DeliveryMethod.customerPickup:
        return 'Customer picks up from vendor location';
      case DeliveryMethod.salesAgentPickup:
        return 'Sales agent will collect and deliver';
    }
  }
}
