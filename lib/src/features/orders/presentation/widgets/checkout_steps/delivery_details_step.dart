import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../enhanced_delivery_method_picker.dart';
import '../customer/schedule_time_picker.dart';
import '../../providers/enhanced_cart_provider.dart';
import '../../providers/checkout_flow_provider.dart';
import '../../providers/checkout_defaults_provider.dart';
import '../../providers/delivery_pricing_provider.dart';
import '../../../data/models/customer_delivery_method.dart';
import '../../../data/models/delivery_fee_calculation.dart';
import '../../../../user_management/domain/customer_profile.dart';
import '../../../../core/utils/logger.dart';
import '../../../../../shared/widgets/custom_text_field.dart';

/// Delivery details step in checkout flow
class DeliveryDetailsStep extends ConsumerStatefulWidget {
  const DeliveryDetailsStep({super.key});

  @override
  ConsumerState<DeliveryDetailsStep> createState() => _DeliveryDetailsStepState();
}

class _DeliveryDetailsStepState extends ConsumerState<DeliveryDetailsStep>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _instructionsController = TextEditingController();
  final AppLogger _logger = AppLogger();

  CustomerDeliveryMethod _selectedMethod = CustomerDeliveryMethod.pickup;
  CustomerAddress? _selectedAddress;
  DateTime? _scheduledTime;
  bool _isAutoPopulating = false;
  bool _hasAutoPopulated = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // Initialize from checkout state and auto-populate defaults
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDeliveryDetails();
    });
  }

  /// Initialize delivery details with auto-population
  Future<void> _initializeDeliveryDetails() async {
    final checkoutState = ref.read(checkoutFlowProvider);

    // First, load existing checkout state
    if (checkoutState.selectedDeliveryMethod != null) {
      setState(() {
        _selectedMethod = checkoutState.selectedDeliveryMethod!;
      });
    }

    if (checkoutState.selectedDeliveryAddress != null) {
      setState(() {
        _selectedAddress = checkoutState.selectedDeliveryAddress;
      });
    }

    if (checkoutState.scheduledDeliveryTime != null) {
      setState(() {
        _scheduledTime = checkoutState.scheduledDeliveryTime;
      });
    }

    if (checkoutState.specialInstructions != null) {
      _instructionsController.text = checkoutState.specialInstructions!;
    }

    // Auto-populate defaults if not already set
    if (!_hasAutoPopulated) {
      await _autoPopulateDefaults();
    }
  }

  /// Auto-populate default address if delivery method requires it
  Future<void> _autoPopulateDefaults() async {
    if (_hasAutoPopulated || _isAutoPopulating) {
      return;
    }

    setState(() {
      _isAutoPopulating = true;
    });

    try {
      _logger.info('🔄 [DELIVERY-DETAILS] Auto-populating defaults');

      // Only auto-populate address if delivery method requires it and we don't have one
      if (_selectedMethod.requiresDriver && _selectedAddress == null) {
        final defaults = ref.read(checkoutDefaultsProvider);

        if (defaults.hasAddress && defaults.defaultAddress != null) {
          setState(() {
            _selectedAddress = defaults.defaultAddress;
          });

          // Update checkout flow provider
          ref.read(checkoutFlowProvider.notifier).setDeliveryAddress(_selectedAddress);

          _logger.info('✅ [DELIVERY-DETAILS] Auto-populated default address: ${defaults.defaultAddress!.label}');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Using default address: ${defaults.defaultAddress!.label}'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: 'Change',
                  textColor: Colors.white,
                  onPressed: () => _selectAddress(),
                ),
              ),
            );
          }
        }
      }

      setState(() {
        _hasAutoPopulated = true;
      });

    } catch (e, stack) {
      _logger.error('❌ [DELIVERY-DETAILS] Error auto-populating defaults', e, stack);
    } finally {
      setState(() {
        _isAutoPopulating = false;
      });
    }
  }

  /// Manually refresh defaults
  Future<void> _refreshDefaults() async {
    setState(() {
      _hasAutoPopulated = false;
    });
    await _autoPopulateDefaults();
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final theme = Theme.of(context);
    final cartState = ref.watch(enhancedCartProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 24),
          _buildDeliveryMethodSection(theme, cartState),
          const SizedBox(height: 24),
          if (_selectedMethod.requiresDriver) ...[
            _buildAddressSection(theme),
            const SizedBox(height: 24),
          ],
          if (_selectedMethod == CustomerDeliveryMethod.scheduled) ...[
            _buildSchedulingSection(theme),
            const SizedBox(height: 24),
          ],
          _buildInstructionsSection(theme),
          const SizedBox(height: 24),
          _buildDeliverySummary(theme),
          const SizedBox(height: 100), // Space for bottom navigation
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.local_shipping,
                size: 24,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Details',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Choose how and when you\'d like to receive your order',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeliveryMethodSection(ThemeData theme, dynamic cartState) {
    // Debug logging for widget parameters
    _logger.debug('🔧 [DELIVERY-DETAILS] Building delivery method section');
    _logger.debug('🔧 [DELIVERY-DETAILS] VendorId: ${cartState.primaryVendorId ?? 'null'}');
    _logger.debug('🔧 [DELIVERY-DETAILS] Subtotal: ${cartState.subtotal}');
    _logger.debug('🔧 [DELIVERY-DETAILS] Address: ${_selectedAddress?.fullAddress ?? 'null'}');
    _logger.debug('🔧 [DELIVERY-DETAILS] Scheduled time: ${_scheduledTime?.toString() ?? 'null'}');

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
        EnhancedDeliveryMethodPicker(
          selectedMethod: _selectedMethod,
          onMethodChanged: _onDeliveryMethodChanged,
          vendorId: cartState.primaryVendorId ?? '',
          subtotal: cartState.subtotal,
          deliveryAddress: _selectedAddress,
          scheduledTime: _scheduledTime,
          showEstimatedTime: true,
          showFeatureComparison: false,
        ),
      ],
    );
  }

  Widget _buildAddressSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Delivery Address',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (_isAutoPopulating)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                onPressed: () => _refreshDefaults(),
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh default address',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: _selectedAddress != null
              ? _buildSelectedAddress(theme)
              : _buildAddressSelector(theme),
        ),
      ],
    );
  }

  Widget _buildSelectedAddress(ThemeData theme) {
    final address = _selectedAddress!;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.location_on,
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
                  address.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address.fullAddress,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _selectAddress,
            child: Text(
              'Change',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSelector(ThemeData theme) {
    return InkWell(
      onTap: _selectAddress,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.add_location,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Delivery Address',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Choose where you\'d like your order delivered',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulingSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scheduled Delivery',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: _selectScheduledTime,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.schedule,
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
                          _scheduledTime != null 
                              ? 'Scheduled for'
                              : 'Select Delivery Time',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _scheduledTime != null
                              ? _formatScheduledTime(_scheduledTime!)
                              : 'Choose when you\'d like your order delivered',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Special Instructions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Any special requests for your order or delivery',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _instructionsController,
          hintText: 'e.g., Leave at door, Call when arrived, Extra spicy...',
          maxLines: 3,
          onChanged: _onInstructionsChanged,
        ),
      ],
    );
  }

  Widget _buildDeliverySummary(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Summary',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(theme, 'Method', _selectedMethod.displayName),
          _buildPricingRow(theme),
          if (_selectedAddress != null)
            _buildSummaryRow(theme, 'Address', _selectedAddress!.fullAddress),
          if (_scheduledTime != null)
            _buildSummaryRow(theme, 'Time', _formatScheduledTime(_scheduledTime!)),
          if (_instructionsController.text.isNotEmpty)
            _buildSummaryRow(theme, 'Instructions', _instructionsController.text),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingRow(ThemeData theme) {
    return Consumer(
      builder: (context, ref, child) {
        final pricingState = ref.watch(deliveryPricingProvider);
        final cartState = ref.watch(enhancedCartProvider);

        // Trigger pricing calculation when method changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (cartState.items.isNotEmpty) {
            final vendorId = cartState.primaryVendorId ?? '';
            ref.read(deliveryPricingProvider.notifier).calculateDeliveryFee(
              deliveryMethod: _selectedMethod,
              vendorId: vendorId,
              subtotal: cartState.subtotal,
              deliveryAddress: _selectedAddress,
              scheduledTime: _scheduledTime,
            );
          }
        });

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  'Fee:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: _buildPricingContent(theme, pricingState),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPricingContent(ThemeData theme, DeliveryPricingState pricingState) {
    if (pricingState.isCalculating) {
      return Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Calculating...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final calculation = pricingState.calculation;
    if (calculation == null) {
      return Text(
        'Not available',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final isFree = calculation.finalFee <= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isFree ? 'FREE' : 'RM ${calculation.finalFee.toStringAsFixed(2)}',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isFree ? theme.colorScheme.tertiary : theme.colorScheme.primary,
          ),
        ),
        if (!isFree && calculation.breakdown.isNotEmpty) ...[
          const SizedBox(height: 4),
          _buildFeeBreakdown(theme, calculation),
          const SizedBox(height: 4),
          _buildPricingExplanation(theme, calculation),
        ],
      ],
    );
  }

  Widget _buildFeeBreakdown(ThemeData theme, DeliveryFeeCalculation calculation) {
    final breakdown = <Widget>[];

    if (calculation.baseFee > 0) {
      breakdown.add(_buildBreakdownItem(
        theme,
        'Base fee',
        'RM ${calculation.baseFee.toStringAsFixed(2)}',
      ));
    }

    if (calculation.distanceFee > 0) {
      breakdown.add(_buildBreakdownItem(
        theme,
        'Distance (${calculation.distanceKm.toStringAsFixed(1)}km)',
        'RM ${calculation.distanceFee.toStringAsFixed(2)}',
      ));
    }

    if (calculation.hasSurge) {
      breakdown.add(_buildBreakdownItem(
        theme,
        'Peak time surcharge',
        'RM ${calculation.surgeFee.toStringAsFixed(2)}',
      ));
    }

    if (calculation.hasDiscount) {
      breakdown.add(_buildBreakdownItem(
        theme,
        'Discount',
        '-RM ${calculation.discountAmount.toStringAsFixed(2)}',
        isDiscount: true,
      ));
    }

    if (breakdown.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: breakdown,
      ),
    );
  }

  Widget _buildBreakdownItem(
    ThemeData theme,
    String label,
    String amount, {
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            amount,
            style: theme.textTheme.labelSmall?.copyWith(
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

  Widget _buildPricingExplanation(ThemeData theme, DeliveryFeeCalculation calculation) {
    return InkWell(
      onTap: () => _showPricingDetailsDialog(calculation),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 12,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'How is this calculated?',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPricingDetailsDialog(DeliveryFeeCalculation calculation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.receipt_long,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Delivery Fee Breakdown'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailedBreakdown(Theme.of(context), calculation),
              const SizedBox(height: 16),
              _buildPricingExplanationText(Theme.of(context)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedBreakdown(ThemeData theme, DeliveryFeeCalculation calculation) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          if (calculation.baseFee > 0)
            _buildDetailedBreakdownRow(
              theme,
              'Base Delivery Fee',
              'RM ${calculation.baseFee.toStringAsFixed(2)}',
              'Standard fee for delivery service',
            ),
          if (calculation.distanceFee > 0)
            _buildDetailedBreakdownRow(
              theme,
              'Distance Charge',
              'RM ${calculation.distanceFee.toStringAsFixed(2)}',
              '${calculation.distanceKm.toStringAsFixed(1)}km from vendor',
            ),
          if (calculation.hasSurge)
            _buildDetailedBreakdownRow(
              theme,
              'Peak Time Surcharge',
              'RM ${calculation.surgeFee.toStringAsFixed(2)}',
              '${((calculation.surgeMultiplier - 1) * 100).toStringAsFixed(0)}% increase during busy hours',
            ),
          if (calculation.hasDiscount)
            _buildDetailedBreakdownRow(
              theme,
              'Discount Applied',
              '-RM ${calculation.discountAmount.toStringAsFixed(2)}',
              'Promotional discount',
              isDiscount: true,
            ),
          const Divider(),
          _buildDetailedBreakdownRow(
            theme,
            'Total Delivery Fee',
            'RM ${calculation.finalFee.toStringAsFixed(2)}',
            '',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedBreakdownRow(
    ThemeData theme,
    String label,
    String amount,
    String description, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(
                amount,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                  color: isDiscount
                      ? theme.colorScheme.tertiary
                      : isTotal
                          ? theme.colorScheme.primary
                          : null,
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                description,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPricingExplanationText(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How delivery fees work:',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildExplanationPoint(
          theme,
          'Base Fee',
          'Standard charge for delivery service',
        ),
        _buildExplanationPoint(
          theme,
          'Distance',
          'Additional charge based on distance from vendor',
        ),
        _buildExplanationPoint(
          theme,
          'Peak Hours',
          'Higher rates during busy periods to ensure availability',
        ),
        _buildExplanationPoint(
          theme,
          'Free Delivery',
          'Available for pickup orders or qualifying order amounts',
        ),
      ],
    );
  }

  Widget _buildExplanationPoint(ThemeData theme, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodySmall,
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onDeliveryMethodChanged(CustomerDeliveryMethod method) {
    _logger.info('🚚 [DELIVERY-DETAILS] Method changed to: ${method.value}');

    setState(() {
      _selectedMethod = method;
    });

    ref.read(checkoutFlowProvider.notifier).setDeliveryMethod(method);

    // Update pricing provider with new delivery method
    ref.read(deliveryPricingProvider.notifier).updateDeliveryMethod(method);

    // Trigger immediate pricing calculation
    _triggerPricingCalculation(method);

    // Auto-populate address if new method requires it and we don't have one
    if (method.requiresDriver && _selectedAddress == null) {
      _autoPopulateAddressForMethod(method);
    }
  }

  /// Trigger pricing calculation for current parameters
  void _triggerPricingCalculation(CustomerDeliveryMethod method) {
    final cartState = ref.read(enhancedCartProvider);

    if (cartState.items.isNotEmpty) {
      final vendorId = cartState.primaryVendorId ?? '';

      _logger.debug('💰 [DELIVERY-DETAILS] Triggering pricing calculation for method: ${method.value}');

      ref.read(deliveryPricingProvider.notifier).calculateDeliveryFee(
        deliveryMethod: method,
        vendorId: vendorId,
        subtotal: cartState.subtotal,
        deliveryAddress: _selectedAddress,
        scheduledTime: _scheduledTime,
      );
    }
  }

  /// Auto-populate address when delivery method changes to one that requires it
  Future<void> _autoPopulateAddressForMethod(CustomerDeliveryMethod method) async {
    try {
      _logger.debug('🔄 [DELIVERY-DETAILS] Auto-populating address for method: ${method.value}');

      final defaults = ref.read(checkoutDefaultsProvider);

      if (defaults.hasAddress && defaults.defaultAddress != null) {
        setState(() {
          _selectedAddress = defaults.defaultAddress;
        });

        // Update checkout flow provider
        ref.read(checkoutFlowProvider.notifier).setDeliveryAddress(_selectedAddress);

        _logger.info('✅ [DELIVERY-DETAILS] Auto-populated address for method change');

        // Trigger pricing recalculation with auto-populated address
        _triggerPricingCalculation(method);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Using default address: ${defaults.defaultAddress!.label}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: 'Change',
                textColor: Colors.white,
                onPressed: () => _selectAddress(),
              ),
            ),
          );
        }
      }

    } catch (e, stack) {
      _logger.error('❌ [DELIVERY-DETAILS] Error auto-populating address for method', e, stack);
    }
  }

  void _selectAddress() {
    _logger.info('📍 [DELIVERY-DETAILS] Selecting delivery address');
    // TODO: Navigate to address selection screen
    // For now, create a mock address
    setState(() {
      _selectedAddress = CustomerAddress(
        id: 'mock-address',
        label: 'Home',
        addressLine1: '123 Main Street',
        city: 'Kuala Lumpur',
        state: 'Selangor',
        postalCode: '50000',
        country: 'Malaysia',
        latitude: 3.1390,
        longitude: 101.6869,
        isDefault: true,
      );
    });

    ref.read(checkoutFlowProvider.notifier).setDeliveryAddress(_selectedAddress);

    // Trigger pricing recalculation with new address
    _triggerPricingCalculation(_selectedMethod);
  }

  void _selectScheduledTime() {
    _logger.info('⏰ [DELIVERY-DETAILS] Selecting scheduled time');

    // Import the enhanced ScheduleTimePicker
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ScheduleTimePicker(
        initialDateTime: _scheduledTime,
        onDateTimeSelected: (dateTime) {
          if (dateTime != null) {
            setState(() {
              _scheduledTime = dateTime;
            });

            ref.read(checkoutFlowProvider.notifier).setScheduledDeliveryTime(dateTime);
            _logger.info('⏰ [DELIVERY-DETAILS] Scheduled time set: $dateTime');

            // Trigger pricing recalculation with new scheduled time
            _triggerPricingCalculation(_selectedMethod);
          }
        },
        onCancel: () {
          _logger.info('🚫 [DELIVERY-DETAILS] Schedule delivery cancelled');
        },
        title: 'Schedule Delivery',
        subtitle: 'Choose your preferred delivery time',
        showBusinessHours: true,
        minimumAdvanceHours: 2,
        maxDaysAhead: 7,
      ),
    );
  }

  void _onInstructionsChanged(String value) {
    ref.read(checkoutFlowProvider.notifier).setSpecialInstructions(
      value.trim().isEmpty ? null : value.trim(),
    );
  }

  String _formatScheduledTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now).inDays;
    
    String dateStr;
    if (difference == 0) {
      dateStr = 'Today';
    } else if (difference == 1) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    
    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    
    return '$dateStr at $timeStr';
  }
}
