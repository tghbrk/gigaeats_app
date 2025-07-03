import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/customer_delivery_method.dart';
import '../../data/models/delivery_fee_calculation.dart';
import '../../data/services/delivery_fee_service.dart';
import '../../../user_management/domain/customer_profile.dart';
import '../../../core/utils/logger.dart';
import '../../../../shared/widgets/loading_overlay.dart';

/// Enhanced delivery method picker with dynamic fee calculation
class EnhancedDeliveryMethodPicker extends ConsumerStatefulWidget {
  final CustomerDeliveryMethod selectedMethod;
  final ValueChanged<CustomerDeliveryMethod> onMethodChanged;
  final String vendorId;
  final double subtotal;
  final CustomerAddress? deliveryAddress;
  final DateTime? scheduledTime;
  final bool showEstimatedTime;
  final bool showFeatureComparison;

  const EnhancedDeliveryMethodPicker({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
    required this.vendorId,
    required this.subtotal,
    this.deliveryAddress,
    this.scheduledTime,
    this.showEstimatedTime = true,
    this.showFeatureComparison = false,
  });

  @override
  ConsumerState<EnhancedDeliveryMethodPicker> createState() => _EnhancedDeliveryMethodPickerState();
}

class _EnhancedDeliveryMethodPickerState extends ConsumerState<EnhancedDeliveryMethodPicker>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final Map<CustomerDeliveryMethod, DeliveryFeeCalculation?> _feeCalculations = {};
  bool _isCalculatingFees = false;
  final AppLogger _logger = AppLogger();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _calculateDeliveryFees();
    _animationController.forward();
  }

  @override
  void didUpdateWidget(EnhancedDeliveryMethodPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Recalculate fees if relevant parameters changed
    if (oldWidget.subtotal != widget.subtotal ||
        oldWidget.deliveryAddress != widget.deliveryAddress ||
        oldWidget.scheduledTime != widget.scheduledTime ||
        oldWidget.vendorId != widget.vendorId) {
      _calculateDeliveryFees();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 16),
                  _buildDeliveryMethods(theme),
                  if (widget.showFeatureComparison) ...[
                    const SizedBox(height: 16),
                    _buildFeatureComparison(theme),
                  ],
                ],
              ),
            ),
            if (_isCalculatingFees)
              const SimpleLoadingOverlay(
                message: 'Calculating delivery fees...',
                backgroundColor: Colors.transparent,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.local_shipping,
            size: 20,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery Method',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Choose how you\'d like to receive your order',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryMethods(ThemeData theme) {
    return Column(
      children: CustomerDeliveryMethod.values.map((method) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMethodOption(theme, method),
        );
      }).toList(),
    );
  }

  Widget _buildMethodOption(ThemeData theme, CustomerDeliveryMethod method) {
    final isSelected = widget.selectedMethod == method;
    final calculation = _feeCalculations[method];
    final isAvailable = _isMethodAvailable(method);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isAvailable ? () => _selectMethod(method) : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Method icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getMethodIcon(method),
                        size: 20,
                        color: isSelected 
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Method info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                method.displayName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isAvailable
                                      ? null
                                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                              if (!isAvailable) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Unavailable',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onErrorContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            method.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Fee and time info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (calculation != null) ...[
                          Text(
                            calculation.finalFee > 0 
                                ? 'RM ${calculation.finalFee.toStringAsFixed(2)}'
                                : 'FREE',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: calculation.finalFee > 0 
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.tertiary,
                            ),
                          ),
                          if (widget.showEstimatedTime) ...[
                            const SizedBox(height: 2),
                            Text(
                              _getEstimatedTime(method),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ] else if (_isCalculatingFees) ...[
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
                        ],
                      ],
                    ),
                    
                    // Selection indicator
                    const SizedBox(width: 8),
                    Radio<CustomerDeliveryMethod>(
                      value: method,
                      groupValue: widget.selectedMethod,
                      onChanged: isAvailable ? (value) => _selectMethod(value!) : null,
                      activeColor: theme.colorScheme.primary,
                    ),
                  ],
                ),
                
                // Additional info for selected method
                if (isSelected && calculation != null && calculation.finalFee > 0) ...[
                  const SizedBox(height: 12),
                  _buildFeeBreakdown(theme, calculation),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeeBreakdown(ThemeData theme, DeliveryFeeCalculation calculation) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          if (calculation.baseFee > 0)
            _buildFeeRow(theme, 'Base fee', calculation.baseFee),
          if (calculation.distanceFee > 0)
            _buildFeeRow(theme, 'Distance fee (${calculation.distanceKm.toStringAsFixed(1)}km)', calculation.distanceFee),
          if (calculation.surgeMultiplier > 1.0)
            _buildFeeRow(theme, 'Peak time surcharge', (calculation.finalFee - calculation.baseFee - calculation.distanceFee)),
          if (calculation.discountAmount > 0)
            _buildFeeRow(theme, 'Discount', -calculation.discountAmount, isDiscount: true),
        ],
      ),
    );
  }

  Widget _buildFeeRow(ThemeData theme, String label, double amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            '${isDiscount ? '-' : ''}RM ${amount.abs().toStringAsFixed(2)}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: isDiscount 
                  ? theme.colorScheme.tertiary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureComparison(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Features',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildFeatureRow(theme, 'Real-time tracking', {
            CustomerDeliveryMethod.ownFleet: true,
            CustomerDeliveryMethod.salesAgentPickup: true,
            CustomerDeliveryMethod.customerPickup: false,
          }),
          _buildFeatureRow(theme, 'Contactless delivery', {
            CustomerDeliveryMethod.ownFleet: true,
            CustomerDeliveryMethod.salesAgentPickup: false,
            CustomerDeliveryMethod.customerPickup: false,
          }),
          _buildFeatureRow(theme, 'Scheduled delivery', {
            CustomerDeliveryMethod.ownFleet: true,
            CustomerDeliveryMethod.salesAgentPickup: true,
            CustomerDeliveryMethod.customerPickup: true,
          }),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(ThemeData theme, String feature, Map<CustomerDeliveryMethod, bool> support) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              feature,
              style: theme.textTheme.bodySmall,
            ),
          ),
          ...CustomerDeliveryMethod.values.map((method) {
            final isSupported = support[method] ?? false;
            return Container(
              width: 60,
              alignment: Alignment.center,
              child: Icon(
                isSupported ? Icons.check : Icons.close,
                size: 16,
                color: isSupported
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _getMethodIcon(CustomerDeliveryMethod method) {
    switch (method) {
      case CustomerDeliveryMethod.customerPickup:
        return Icons.store;
      case CustomerDeliveryMethod.salesAgentPickup:
        return Icons.person;
      case CustomerDeliveryMethod.ownFleet:
        return Icons.local_shipping;
      case CustomerDeliveryMethod.delivery:
        return Icons.delivery_dining;
      case CustomerDeliveryMethod.scheduled:
        return Icons.schedule;
      case CustomerDeliveryMethod.pickup:
        return Icons.shopping_bag;
      case CustomerDeliveryMethod.lalamove:
        return Icons.motorcycle;
      case CustomerDeliveryMethod.thirdParty:
        return Icons.local_shipping;
    }
  }

  String _getEstimatedTime(CustomerDeliveryMethod method) {
    switch (method) {
      case CustomerDeliveryMethod.customerPickup:
        return 'Ready in 15-30 min';
      case CustomerDeliveryMethod.salesAgentPickup:
        return '30-45 min';
      case CustomerDeliveryMethod.ownFleet:
        return '45-60 min';
      default:
        return '30-60 min';
    }
  }

  bool _isMethodAvailable(CustomerDeliveryMethod method) {
    // TODO: Implement proper availability logic based on vendor settings, distance, etc.

    // Check if method requires driver but no address is provided
    if (method.requiresDriver && widget.deliveryAddress == null) {
      return false;
    }

    // Check minimum order amount for sales agent pickup
    if (method == CustomerDeliveryMethod.salesAgentPickup && widget.subtotal < 50.0) {
      return false;
    }

    return true;
  }

  void _selectMethod(CustomerDeliveryMethod method) {
    _logger.info('🚚 [DELIVERY-PICKER] Selected delivery method: ${method.value}');
    widget.onMethodChanged(method);
  }

  Future<void> _calculateDeliveryFees() async {
    if (_isCalculatingFees) return;

    setState(() {
      _isCalculatingFees = true;
    });

    try {
      _logger.info('💰 [DELIVERY-PICKER] Calculating delivery fees for all methods');

      final deliveryFeeService = ref.read(deliveryFeeServiceProvider);

      for (final method in CustomerDeliveryMethod.values) {
        try {
          // Map CustomerDeliveryMethod to DeliveryMethod for service call
          final mappedMethod = _mapToDeliveryMethod(method);
          if (mappedMethod == null) continue;

          final calculation = await deliveryFeeService.calculateDeliveryFee(
            deliveryMethod: mappedMethod,
            vendorId: widget.vendorId,
            subtotal: widget.subtotal,
            deliveryLatitude: widget.deliveryAddress?.latitude,
            deliveryLongitude: widget.deliveryAddress?.longitude,
            deliveryTime: widget.scheduledTime,
          );

          _feeCalculations[method] = calculation;
        } catch (e) {
          _logger.warning('Failed to calculate fee for ${method.value}: $e');
          // Set fallback calculation
          _feeCalculations[method] = DeliveryFeeCalculation.pickup(method.value);
        }
      }

      _logger.info('✅ [DELIVERY-PICKER] Fee calculation completed');
    } catch (e) {
      _logger.error('❌ [DELIVERY-PICKER] Failed to calculate delivery fees', e);
    } finally {
      if (mounted) {
        setState(() {
          _isCalculatingFees = false;
        });
      }
    }
  }

  dynamic _mapToDeliveryMethod(CustomerDeliveryMethod method) {
    // This is a temporary mapping - in a real implementation,
    // you'd want to use a proper enum mapping service
    switch (method) {
      case CustomerDeliveryMethod.customerPickup:
      case CustomerDeliveryMethod.pickup:
        return 'customer_pickup';
      case CustomerDeliveryMethod.salesAgentPickup:
        return 'sales_agent_pickup';
      case CustomerDeliveryMethod.ownFleet:
      case CustomerDeliveryMethod.delivery:
        return 'own_fleet';
      case CustomerDeliveryMethod.thirdParty:
      case CustomerDeliveryMethod.lalamove:
        return 'third_party';
      default:
        return null;
    }
  }
}

/// Delivery fee service provider
final deliveryFeeServiceProvider = Provider<DeliveryFeeService>((ref) {
  return DeliveryFeeService();
});
