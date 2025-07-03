import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/customer_profile.dart';
import '../../providers/customer_address_provider.dart' as address_provider;
import '../../widgets/address_form_dialog.dart';
import '../../../../../core/utils/logger.dart';

/// Screen for selecting a delivery address during order placement
class CustomerAddressSelectionScreen extends ConsumerStatefulWidget {
  final String? selectedAddressId;
  final bool allowAddNew;

  const CustomerAddressSelectionScreen({
    super.key,
    this.selectedAddressId,
    this.allowAddNew = true,
  });

  @override
  ConsumerState<CustomerAddressSelectionScreen> createState() => _CustomerAddressSelectionScreenState();
}

class _CustomerAddressSelectionScreenState extends ConsumerState<CustomerAddressSelectionScreen> {
  final AppLogger _logger = AppLogger();
  String? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    _selectedAddressId = widget.selectedAddressId;
    
    // Load addresses when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(address_provider.customerAddressesProvider.notifier).loadAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final addressesState = ref.watch(address_provider.customerAddressesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Delivery Address'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          if (widget.allowAddNew)
            IconButton(
              icon: const Icon(Icons.add_location),
              onPressed: () => _showAddAddressDialog(),
              tooltip: 'Add New Address',
            ),
        ],
      ),
      body: _buildBody(addressesState, theme),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  Widget _buildBody(address_provider.CustomerAddressesState addressesState, ThemeData theme) {
    if (addressesState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (addressesState.error != null) {
      return _buildErrorState(addressesState.error!, theme);
    }

    if (addressesState.addresses.isEmpty) {
      return _buildEmptyState(theme);
    }

    return _buildAddressList(addressesState.addresses, theme);
  }

  Widget _buildErrorState(String error, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load addresses',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(address_provider.customerAddressesProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No addresses found',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first delivery address to continue with your order',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddAddressDialog(),
              icon: const Icon(Icons.add_location),
              label: const Text('Add Address'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressList(List<CustomerAddress> addresses, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: addresses.length + (widget.allowAddNew ? 1 : 0),
      itemBuilder: (context, index) {
        if (widget.allowAddNew && index == addresses.length) {
          return _buildAddNewAddressCard(theme);
        }
        
        final address = addresses[index];
        return _buildAddressCard(address, theme);
      },
    );
  }

  Widget _buildAddressCard(CustomerAddress address, ThemeData theme) {
    final isSelected = _selectedAddressId == address.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected 
            ? BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _selectAddress(address),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: isSelected 
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.05),
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                    ],
                  ),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        address.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? theme.colorScheme.primary : null,
                        ),
                      ),
                    ),
                    if (address.isDefault) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 12,
                              color: theme.colorScheme.onPrimary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Default',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  address.fullAddress,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                if (address.deliveryInstructions?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            address.deliveryInstructions!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              fontStyle: FontStyle.italic,
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
      ),
    );
  }

  Widget _buildAddNewAddressCard(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: InkWell(
        onTap: () => _showAddAddressDialog(),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add_location,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New Address',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create a new delivery address',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    final hasSelection = _selectedAddressId != null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: hasSelection ? _confirmSelection : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            hasSelection ? 'Use This Address' : 'Select an Address',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }

  void _selectAddress(CustomerAddress address) {
    setState(() {
      _selectedAddressId = address.id;
    });
    
    // Update the selected address in the provider
    ref.read(address_provider.customerAddressesProvider.notifier).selectAddress(address);
    
    _logger.info('🏠 [ADDRESS-SELECTION] Address selected: ${address.label}');
  }

  void _confirmSelection() {
    if (_selectedAddressId != null) {
      _logger.info('🏠 [ADDRESS-SELECTION] Confirming address selection: $_selectedAddressId');
      context.pop(_selectedAddressId);
    }
  }

  void _showAddAddressDialog() {
    _logger.info('🏠 [ADDRESS-SELECTION] Opening add address dialog');
    
    showDialog(
      context: context,
      builder: (context) => AddressFormDialog(
        onSuccess: () {
          _logger.info('🏠 [ADDRESS-SELECTION] Address added successfully, refreshing list');
          // The provider will automatically refresh, so we don't need to do anything
        },
      ),
    );
  }
}
