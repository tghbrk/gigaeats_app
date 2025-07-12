import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/customer_delivery_method.dart';
import '../../data/models/delivery_fee_calculation.dart';
import '../../data/services/delivery_fee_service.dart';
import '../../data/services/delivery_method_service.dart';
import '../../data/models/delivery_method.dart';
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
  final Map<CustomerDeliveryMethod, bool> _availabilityCache = {};
  bool _isCalculatingFees = false;
  bool _isCheckingAvailability = false;
  final AppLogger _logger = AppLogger();
  final DeliveryMethodService _deliveryMethodService = DeliveryMethodService();

  @override
  void initState() {
    super.initState();
    _logger.info('🚀 [DELIVERY-PICKER] Initializing widget with vendorId: ${widget.vendorId}, subtotal: ${widget.subtotal}');

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _logger.info('🔄 [DELIVERY-PICKER] Triggering initial fee calculation and availability checks');
    _clearAvailabilityCache(); // Clear cache to ensure fresh availability checks
    _calculateDeliveryFees();
    _checkAllMethodsAvailability();
    _animationController.forward();
  }

  @override
  void didUpdateWidget(EnhancedDeliveryMethodPicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Recalculate fees and availability if relevant parameters changed
    if (oldWidget.subtotal != widget.subtotal ||
        oldWidget.deliveryAddress != widget.deliveryAddress ||
        oldWidget.scheduledTime != widget.scheduledTime ||
        oldWidget.vendorId != widget.vendorId) {
      _logger.info('🔄 [DELIVERY-PICKER] Parameters changed, recalculating fees and availability');
      _clearAvailabilityCache(); // Clear cache when parameters change
      _calculateDeliveryFees();
      _checkAllMethodsAvailability();
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
                // Use LayoutBuilder for responsive layout
                LayoutBuilder(
                  builder: (context, constraints) {
                    _logger.debug('🎨 [DELIVERY-PICKER] Layout constraints: ${constraints.maxWidth}px for ${method.value}');

                    // Calculate space requirements
                    final iconWidth = 36.0; // 20 + 8*2 padding
                    final radioWidth = 40.0; // Approximate radio button width
                    final spacingWidth = 20.0; // SizedBox spacing
                    final unavailableBadgeWidth = !isAvailable ? 80.0 : 0.0; // Approximate badge width
                    final pricingWidth = 80.0; // Approximate pricing container width

                    final requiredWidth = iconWidth + radioWidth + spacingWidth + unavailableBadgeWidth + pricingWidth;
                    final availableContentWidth = constraints.maxWidth - requiredWidth;

                    _logger.debug('🎨 [DELIVERY-PICKER] Required: ${requiredWidth}px, Available content: ${availableContentWidth}px');

                    // Use adaptive layout based on available space
                    if (availableContentWidth < 100) {
                      // Very narrow: Use compact column layout
                      return _buildCompactColumnLayout(theme, method, calculation, isSelected, isAvailable);
                    } else {
                      // Normal: Use optimized row layout
                      return _buildOptimizedRowLayout(theme, method, calculation, isSelected, isAvailable, availableContentWidth);
                    }
                  },
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
            CustomerDeliveryMethod.delivery: true,
            CustomerDeliveryMethod.scheduled: true,
            CustomerDeliveryMethod.pickup: false,
          }),
          _buildFeatureRow(theme, 'Contactless delivery', {
            CustomerDeliveryMethod.delivery: true,
            CustomerDeliveryMethod.scheduled: true,
            CustomerDeliveryMethod.pickup: false,
          }),
          _buildFeatureRow(theme, 'Scheduled delivery', {
            CustomerDeliveryMethod.delivery: false,
            CustomerDeliveryMethod.scheduled: true,
            CustomerDeliveryMethod.pickup: false,
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

  /// Build compact column layout for very narrow constraints
  Widget _buildCompactColumnLayout(ThemeData theme, CustomerDeliveryMethod method,
      DeliveryFeeCalculation? calculation, bool isSelected, bool isAvailable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First row: Icon, title, and radio
        Row(
          children: [
            // Method icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _getMethodIcon(method),
                size: 16,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),

            // Method name
            Expanded(
              child: Text(
                method.displayName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isAvailable
                      ? null
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Radio button
            Radio<CustomerDeliveryMethod>(
              value: method,
              groupValue: widget.selectedMethod,
              onChanged: isAvailable ? (value) => _selectMethod(value!) : null,
              activeColor: theme.colorScheme.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),

        const SizedBox(height: 4),

        // Second row: Description, availability, and pricing
        Row(
          children: [
            // Description
            Expanded(
              child: Text(
                method.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),

            // Availability badge
            if (!isAvailable) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'N/A',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w500,
                    fontSize: 9,
                  ),
                ),
              ),
            ],

            const SizedBox(width: 4),

            // Pricing
            _buildCompactPricingInfo(theme, method, calculation),
          ],
        ),
      ],
    );
  }

  /// Build optimized row layout for normal constraints
  Widget _buildOptimizedRowLayout(ThemeData theme, CustomerDeliveryMethod method,
      DeliveryFeeCalculation? calculation, bool isSelected, bool isAvailable, double availableContentWidth) {
    return Row(
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

        // Method info - use calculated available width
        SizedBox(
          width: availableContentWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and availability badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      method.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isAvailable
                            ? null
                            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isAvailable) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Unavailable',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
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
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Pricing info
        _buildPricingInfo(theme, method, calculation),

        const SizedBox(width: 8),

        // Radio button
        Radio<CustomerDeliveryMethod>(
          value: method,
          groupValue: widget.selectedMethod,
          onChanged: isAvailable ? (value) => _selectMethod(value!) : null,
          activeColor: theme.colorScheme.primary,
        ),
      ],
    );
  }

  IconData _getMethodIcon(CustomerDeliveryMethod method) {
    switch (method) {
      case CustomerDeliveryMethod.pickup:
        return Icons.store;
      case CustomerDeliveryMethod.delivery:
        return Icons.local_shipping;
      case CustomerDeliveryMethod.scheduled:
        return Icons.schedule;
    }
  }

  /// Build compact pricing info for narrow layouts
  Widget _buildCompactPricingInfo(ThemeData theme, CustomerDeliveryMethod method, DeliveryFeeCalculation? calculation) {
    // Debug logging for pricing display
    _logger.debug('🎨 [DELIVERY-PICKER] Building compact pricing info for ${method.value}');

    if (calculation == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '...',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 9,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactPriceDisplay(theme, calculation),
        if (calculation.breakdown['estimated_time'] != null) ...[
          const SizedBox(height: 1),
          Text(
            calculation.breakdown['estimated_time'],
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 8,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildPricingInfo(ThemeData theme, CustomerDeliveryMethod method, DeliveryFeeCalculation? calculation) {
    // Debug logging for pricing display
    _logger.debug('🎨 [DELIVERY-PICKER] Building pricing info for ${method.value}');
    _logger.debug('🎨 [DELIVERY-PICKER] Calculation available: ${calculation != null}');
    if (calculation != null) {
      _logger.debug('🎨 [DELIVERY-PICKER] Final fee: ${calculation.finalFee}');
      _logger.debug('🎨 [DELIVERY-PICKER] Formatted fee: ${calculation.formattedFee}');
    }
    _logger.debug('🎨 [DELIVERY-PICKER] Is calculating: $_isCalculatingFees');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Pricing display
        _buildPriceDisplay(theme, method, calculation),

        // Estimated time
        if (widget.showEstimatedTime) ...[
          const SizedBox(height: 2),
          Text(
            _getEstimatedTime(method),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  /// Build compact price display for narrow layouts
  Widget _buildCompactPriceDisplay(ThemeData theme, DeliveryFeeCalculation calculation) {
    final priceText = calculation.finalFee == 0.0
        ? 'FREE'
        : 'RM${calculation.finalFee.toStringAsFixed(0)}';

    final priceColor = calculation.finalFee == 0.0
        ? theme.colorScheme.tertiary
        : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: calculation.finalFee == 0.0
            ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4)
            : theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: priceColor.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Text(
        priceText,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: priceColor,
          fontSize: 9,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPriceDisplay(ThemeData theme, CustomerDeliveryMethod method, DeliveryFeeCalculation? calculation) {
    _logger.debug('💰 [DELIVERY-PICKER] Building price display for ${method.value}');
    _logger.debug('💰 [DELIVERY-PICKER] _isCalculatingFees: $_isCalculatingFees, calculation: ${calculation != null}');

    // Show loading state if calculations are in progress
    if (_isCalculatingFees && calculation == null) {
      _logger.debug('💰 [DELIVERY-PICKER] Showing loading state for ${method.value}');
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Calculating...',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    // Determine pricing based on calculation or method type
    String priceText;
    Color priceColor;

    if (calculation != null) {
      // Use calculated fee
      _logger.debug('💰 [DELIVERY-PICKER] Using calculation for ${method.value}: ${calculation.finalFee}');
      if (calculation.finalFee > 0) {
        priceText = 'RM ${calculation.finalFee.toStringAsFixed(2)}';
        priceColor = theme.colorScheme.primary;
      } else {
        priceText = 'FREE';
        priceColor = theme.colorScheme.tertiary;
      }
    } else {
      // Fallback based on method type
      _logger.debug('💰 [DELIVERY-PICKER] No calculation available for ${method.value}, using fallback');
      if (method == CustomerDeliveryMethod.pickup) {
        priceText = 'FREE';
        priceColor = theme.colorScheme.tertiary;
      } else {
        priceText = 'Calculating...';
        priceColor = theme.colorScheme.onSurfaceVariant;
      }
    }

    _logger.debug('💰 [DELIVERY-PICKER] Final price text for ${method.value}: $priceText');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: priceText == 'FREE'
            ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4)
            : theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: priceColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        priceText,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: priceColor,
          fontSize: 12,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _getEstimatedTime(CustomerDeliveryMethod method) {
    switch (method) {
      case CustomerDeliveryMethod.pickup:
        return 'Ready in 15-30 min';
      case CustomerDeliveryMethod.delivery:
        return '45-60 min';
      case CustomerDeliveryMethod.scheduled:
        return 'At scheduled time';
    }
  }

  bool _isMethodAvailable(CustomerDeliveryMethod method) {
    // Use cached availability if available
    if (_availabilityCache.containsKey(method)) {
      final isAvailable = _availabilityCache[method]!;
      _logger.debug('🔍 [DELIVERY-PICKER] Using cached availability for ${method.value}: $isAvailable');
      return isAvailable;
    }

    // For pickup, always available (no complex checks needed)
    if (method == CustomerDeliveryMethod.pickup) {
      _availabilityCache[method] = true;
      return true;
    }

    // For delivery methods that require drivers, check if we have vendor ID
    if (method.requiresDriver && widget.vendorId.isEmpty) {
      _logger.warning('⚠️ [DELIVERY-PICKER] No vendor ID provided for ${method.value}');
      _availabilityCache[method] = false;
      return false;
    }

    // For delivery methods that require drivers, we need to check asynchronously
    // For now, return true and let the async check update the UI
    if (method.requiresDriver) {
      _checkMethodAvailabilityAsync(method);
      // Return true initially, will be updated by async check
      return true;
    }

    // Default to available
    _availabilityCache[method] = true;
    return true;
  }

  /// Asynchronously check method availability using DeliveryMethodService
  Future<void> _checkMethodAvailabilityAsync(CustomerDeliveryMethod method) async {
    if (_isCheckingAvailability) return;

    try {
      _isCheckingAvailability = true;
      _logger.info('🔍 [DELIVERY-PICKER] === ASYNC AVAILABILITY CHECK ===');
      _logger.info('🔍 [DELIVERY-PICKER] Method: ${method.value}');
      _logger.info('🔍 [DELIVERY-PICKER] Vendor ID: ${widget.vendorId}');
      _logger.info('🔍 [DELIVERY-PICKER] Order Amount: RM ${widget.subtotal.toStringAsFixed(2)}');
      _logger.info('🔍 [DELIVERY-PICKER] Delivery Address: ${widget.deliveryAddress != null ? 'Provided (${widget.deliveryAddress!.addressLine1}, ${widget.deliveryAddress!.city})' : 'Not provided'}');

      _logger.info('🔍 [DELIVERY-PICKER] Calling DeliveryMethodService.isMethodAvailable...');

      final isAvailable = await _deliveryMethodService.isMethodAvailable(
        method: method,
        vendorId: widget.vendorId,
        orderAmount: widget.subtotal,
        deliveryAddress: widget.deliveryAddress,
      );

      _logger.info('✅ [DELIVERY-PICKER] Service returned: $isAvailable for ${method.value}');

      // Update cache and trigger rebuild if availability changed
      if (_availabilityCache[method] != isAvailable) {
        _availabilityCache[method] = isAvailable;
        if (mounted) {
          setState(() {
            // Trigger rebuild to update UI
          });
        }
      }
    } catch (e) {
      _logger.error('❌ [DELIVERY-PICKER] Error checking availability for ${method.value}', e);
      // On error, assume unavailable for safety
      _availabilityCache[method] = false;
      if (mounted) {
        setState(() {
          // Trigger rebuild to show unavailable state
        });
      }
    } finally {
      _isCheckingAvailability = false;
    }
  }

  void _selectMethod(CustomerDeliveryMethod method) {
    _logger.info('🚚 [DELIVERY-PICKER] Selected delivery method: ${method.value}');

    // Log current pricing for debugging
    final calculation = _feeCalculations[method];
    if (calculation != null) {
      _logger.debug('💰 [DELIVERY-PICKER] Selected method pricing: ${calculation.formattedFee}');
    } else {
      _logger.warning('⚠️ [DELIVERY-PICKER] No pricing calculation available for ${method.value}');
    }

    widget.onMethodChanged(method);
  }

  /// Force refresh all delivery fee calculations and availability
  void refreshCalculations() {
    _logger.info('🔄 [DELIVERY-PICKER] Force refreshing delivery fee calculations and availability');
    _feeCalculations.clear();
    _clearAvailabilityCache();
    _calculateDeliveryFees();
    _checkAllMethodsAvailability();
  }

  /// Clear availability cache
  void _clearAvailabilityCache() {
    _availabilityCache.clear();
    _logger.debug('🧹 [DELIVERY-PICKER] Cleared availability cache');
  }

  /// Check availability for all delivery methods
  void _checkAllMethodsAvailability() {
    _logger.info('🔍 [DELIVERY-PICKER] Checking availability for all delivery methods');
    for (final method in CustomerDeliveryMethod.values) {
      if (method.requiresDriver) {
        _checkMethodAvailabilityAsync(method);
      }
    }
  }

  Future<void> _calculateDeliveryFees() async {
    if (_isCalculatingFees) return;

    setState(() {
      _isCalculatingFees = true;
    });

    try {
      _logger.info('💰 [DELIVERY-PICKER] Calculating delivery fees for all methods (cache will prevent redundant calls)');

      final deliveryFeeService = ref.read(deliveryFeeServiceProvider);

      for (final method in CustomerDeliveryMethod.values) {
        try {
          // For pickup methods, create immediate free calculation
          if (method == CustomerDeliveryMethod.pickup) {
            _feeCalculations[method] = DeliveryFeeCalculation.pickup(method.value);
            continue;
          }

          // Map CustomerDeliveryMethod to DeliveryMethod for service call
          final mappedMethod = _mapToDeliveryMethod(method);
          if (mappedMethod == null) {
            _logger.warning('No mapping found for delivery method: ${method.value}');
            _feeCalculations[method] = DeliveryFeeCalculation.pickup(method.value);
            continue;
          }

          final calculation = await deliveryFeeService.calculateDeliveryFee(
            deliveryMethod: mappedMethod,
            vendorId: widget.vendorId,
            subtotal: widget.subtotal,
            deliveryLatitude: widget.deliveryAddress?.latitude,
            deliveryLongitude: widget.deliveryAddress?.longitude,
            deliveryTime: widget.scheduledTime,
          );

          _feeCalculations[method] = calculation;
          _logger.debug('✅ [DELIVERY-PICKER] Fee calculated for ${method.value}: ${calculation.formattedFee}');
        } catch (e) {
          _logger.warning('Failed to calculate fee for ${method.value}: $e');
          // Set fallback calculation based on method type
          if (method == CustomerDeliveryMethod.pickup) {
            _feeCalculations[method] = DeliveryFeeCalculation.pickup(method.value);
          } else {
            _feeCalculations[method] = DeliveryFeeCalculation.error('Calculation failed: $e', fallbackFee: 10.0);
          }
        }
      }

      _logger.info('✅ [DELIVERY-PICKER] Fee calculation completed');

      // Debug log all calculated fees
      for (final entry in _feeCalculations.entries) {
        final method = entry.key;
        final calculation = entry.value;
        if (calculation != null) {
          _logger.debug('📊 [DELIVERY-PICKER] ${method.value}: ${calculation.formattedFee}');
        }
      }
    } catch (e) {
      _logger.error('❌ [DELIVERY-PICKER] Failed to calculate delivery fees', e);
    } finally {
      if (mounted) {
        setState(() {
          _isCalculatingFees = false;
        });
        _logger.info('🔄 [DELIVERY-PICKER] Fee calculation completed, widget rebuilt');
      }
    }
  }

  DeliveryMethod? _mapToDeliveryMethod(CustomerDeliveryMethod method) {
    switch (method) {
      case CustomerDeliveryMethod.pickup:
        return DeliveryMethod.customerPickup;
      case CustomerDeliveryMethod.delivery:
      case CustomerDeliveryMethod.scheduled:
        return DeliveryMethod.ownFleet; // Both delivery and scheduled use own fleet pricing
    }
  }
}

/// Delivery fee service provider
final deliveryFeeServiceProvider = Provider<DeliveryFeeService>((ref) {
  return DeliveryFeeService();
});
