import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../enhanced_delivery_method_picker.dart';
import '../customer/schedule_time_picker.dart';
import '../../providers/enhanced_cart_provider.dart';
import '../../providers/checkout_flow_provider.dart';
import '../../providers/checkout_defaults_provider.dart';
import '../../../data/models/customer_delivery_method.dart';
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

  CustomerDeliveryMethod _selectedMethod = CustomerDeliveryMethod.customerPickup;
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

  void _onDeliveryMethodChanged(CustomerDeliveryMethod method) {
    _logger.info('🚚 [DELIVERY-DETAILS] Method changed to: ${method.value}');

    setState(() {
      _selectedMethod = method;
    });

    ref.read(checkoutFlowProvider.notifier).setDeliveryMethod(method);

    // Auto-populate address if new method requires it and we don't have one
    if (method.requiresDriver && _selectedAddress == null) {
      _autoPopulateAddressForMethod(method);
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
