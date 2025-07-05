import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/vendor_profile_edit_providers.dart';
import '../../../../shared/widgets/custom_text_field.dart';

/// Widget for managing vendor pricing settings
class PricingSettingsSection extends ConsumerStatefulWidget {
  const PricingSettingsSection({super.key});

  @override
  ConsumerState<PricingSettingsSection> createState() => _PricingSettingsSectionState();
}

class _PricingSettingsSectionState extends ConsumerState<PricingSettingsSection> {
  late TextEditingController _minimumOrderController;
  late TextEditingController _deliveryFeeController;
  late TextEditingController _freeDeliveryController;

  @override
  void initState() {
    super.initState();
    _minimumOrderController = TextEditingController();
    _deliveryFeeController = TextEditingController();
    _freeDeliveryController = TextEditingController();
  }

  @override
  void dispose() {
    _minimumOrderController.dispose();
    _deliveryFeeController.dispose();
    _freeDeliveryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editState = ref.watch(vendorProfileEditProvider);

    // Update controllers when state changes
    _updateControllers(editState);

    debugPrint('💰 [PRICING-SETTINGS] Building pricing settings section');
    debugPrint('💰 [PRICING-SETTINGS] Min order: RM ${editState.minimumOrderAmount}');
    debugPrint('💰 [PRICING-SETTINGS] Delivery fee: RM ${editState.deliveryFee}');
    debugPrint('💰 [PRICING-SETTINGS] Free delivery: RM ${editState.freeDeliveryThreshold}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Minimum Order Amount
        CustomTextField(
          controller: _minimumOrderController,
          label: 'Minimum Order Amount *',
          hintText: '50.00',
          prefixIcon: Icons.shopping_cart,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          errorText: ref.watch(fieldErrorProvider('minimumOrderAmount')),
          onChanged: (value) {
            final amount = double.tryParse(value) ?? 0.0;
            ref.read(vendorProfileEditProvider.notifier).updateMinimumOrderAmount(amount);
          },
          validator: (value) => _validateCurrency(value, 'minimum order amount', 0, 1000),
        ),
        
        const SizedBox(height: 8),
        
        // Helper text for minimum order
        Text(
          'The minimum order value customers must reach to place an order',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Delivery Fee
        CustomTextField(
          controller: _deliveryFeeController,
          label: 'Delivery Fee *',
          hintText: '15.00',
          prefixIcon: Icons.delivery_dining,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          errorText: ref.watch(fieldErrorProvider('deliveryFee')),
          onChanged: (value) {
            final fee = double.tryParse(value) ?? 0.0;
            ref.read(vendorProfileEditProvider.notifier).updateDeliveryFee(fee);
          },
          validator: (value) => _validateCurrency(value, 'delivery fee', 0, 100),
        ),
        
        const SizedBox(height: 8),
        
        // Helper text for delivery fee
        Text(
          'Standard delivery charge for orders (set to 0 for free delivery)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Free Delivery Threshold
        CustomTextField(
          controller: _freeDeliveryController,
          label: 'Free Delivery Threshold *',
          hintText: '200.00',
          prefixIcon: Icons.local_shipping,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          errorText: ref.watch(fieldErrorProvider('freeDeliveryThreshold')),
          onChanged: (value) {
            final threshold = double.tryParse(value) ?? 0.0;
            ref.read(vendorProfileEditProvider.notifier).updateFreeDeliveryThreshold(threshold);
          },
          validator: (value) => _validateCurrency(value, 'free delivery threshold', 0, 2000),
        ),
        
        const SizedBox(height: 8),
        
        // Helper text for free delivery threshold
        Text(
          'Order value above which delivery becomes free (set to 0 to disable)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Pricing summary card
        _buildPricingSummaryCard(theme, editState),
      ],
    );
  }

  /// Update controllers when state changes
  void _updateControllers(VendorProfileEditState state) {
    if (_minimumOrderController.text != state.minimumOrderAmount.toStringAsFixed(2)) {
      _minimumOrderController.text = state.minimumOrderAmount.toStringAsFixed(2);
    }
    if (_deliveryFeeController.text != state.deliveryFee.toStringAsFixed(2)) {
      _deliveryFeeController.text = state.deliveryFee.toStringAsFixed(2);
    }
    if (_freeDeliveryController.text != state.freeDeliveryThreshold.toStringAsFixed(2)) {
      _freeDeliveryController.text = state.freeDeliveryThreshold.toStringAsFixed(2);
    }
  }

  /// Validate currency input
  String? _validateCurrency(String? value, String fieldName, double min, double max) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    
    if (amount < min || amount > max) {
      return '${fieldName.substring(0, 1).toUpperCase()}${fieldName.substring(1)} must be between RM $min and RM $max';
    }
    
    return null;
  }

  /// Build pricing summary card
  Widget _buildPricingSummaryCard(ThemeData theme, VendorProfileEditState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Pricing Summary',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Pricing details
          _buildPricingRow(
            theme,
            'Minimum Order',
            'RM ${state.minimumOrderAmount.toStringAsFixed(2)}',
            Icons.shopping_cart_outlined,
          ),
          
          const SizedBox(height: 8),
          
          _buildPricingRow(
            theme,
            'Delivery Fee',
            state.deliveryFee == 0 
                ? 'Free' 
                : 'RM ${state.deliveryFee.toStringAsFixed(2)}',
            Icons.delivery_dining_outlined,
          ),
          
          const SizedBox(height: 8),
          
          _buildPricingRow(
            theme,
            'Free Delivery Above',
            state.freeDeliveryThreshold == 0 
                ? 'Disabled' 
                : 'RM ${state.freeDeliveryThreshold.toStringAsFixed(2)}',
            Icons.local_shipping_outlined,
          ),
        ],
      ),
    );
  }

  /// Build pricing row
  Widget _buildPricingRow(ThemeData theme, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
