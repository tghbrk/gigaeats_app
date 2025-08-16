import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/enhanced_address_picker.dart';
import '../widgets/enhanced_address_form.dart';
import '../../../user_management/domain/customer_profile.dart';
import '../../../user_management/presentation/providers/customer_address_provider.dart';
import '../../../core/utils/logger.dart';
import '../../../../design_system/widgets/buttons/ge_button.dart';

/// Enhanced address management screen with GPS support
class EnhancedAddressManagementScreen extends ConsumerStatefulWidget {
  final bool isSelectionMode;
  final CustomerAddress? selectedAddress;
  final ValueChanged<CustomerAddress?>? onAddressSelected;

  const EnhancedAddressManagementScreen({
    super.key,
    this.isSelectionMode = false,
    this.selectedAddress,
    this.onAddressSelected,
  });

  @override
  ConsumerState<EnhancedAddressManagementScreen> createState() => _EnhancedAddressManagementScreenState();
}

class _EnhancedAddressManagementScreenState extends ConsumerState<EnhancedAddressManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  CustomerAddress? _selectedAddress;
  final AppLogger _logger = AppLogger();

  @override
  void initState() {
    super.initState();
    
    _tabController = TabController(length: 2, vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _selectedAddress = widget.selectedAddress;
    
    // Load addresses and start animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerAddressesProvider.notifier).loadAddresses();
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final addressesState = ref.watch(customerAddressesProvider);

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.isSelectionMode
            ? _buildSelectionMode(theme, addressesState)
            : _buildManagementMode(theme, addressesState),
      ),
      bottomNavigationBar: widget.isSelectionMode 
          ? _buildSelectionBottomBar(theme)
          : null,
      floatingActionButton: !widget.isSelectionMode 
          ? _buildFloatingActionButton(theme)
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Text(
        widget.isSelectionMode ? 'Select Address' : 'Manage Addresses',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Icon(
          Icons.arrow_back,
          color: theme.colorScheme.onSurface,
        ),
      ),
      actions: [
        if (!widget.isSelectionMode)
          IconButton(
            onPressed: () => _refreshAddresses(),
            icon: Icon(
              Icons.refresh,
              color: theme.colorScheme.onSurface,
            ),
            tooltip: 'Refresh addresses',
          ),
      ],
      bottom: !widget.isSelectionMode 
          ? TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'My Addresses', icon: Icon(Icons.location_on)),
                Tab(text: 'Add New', icon: Icon(Icons.add_location)),
              ],
            )
          : null,
    );
  }

  Widget _buildSelectionMode(ThemeData theme, CustomerAddressesState addressesState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSelectionHeader(theme),
          const SizedBox(height: 24),
          EnhancedAddressPicker(
            selectedAddress: _selectedAddress,
            onAddressChanged: (address) {
              setState(() {
                _selectedAddress = address;
              });
            },
            allowCurrentLocation: true,
            allowAddNew: true,
            showValidation: true,
          ),
        ],
      ),
    );
  }

  Widget _buildManagementMode(ThemeData theme, CustomerAddressesState addressesState) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildAddressListTab(theme, addressesState),
        _buildAddAddressTab(theme),
      ],
    );
  }

  Widget _buildSelectionHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Delivery Address',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select where you\'d like your order delivered. You can use your current location or choose from saved addresses.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressListTab(ThemeData theme, CustomerAddressesState addressesState) {
    if (addressesState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (addressesState.error != null) {
      return _buildErrorState(theme, addressesState.error!);
    }

    if (addressesState.addresses.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: addressesState.addresses.length,
      itemBuilder: (context, index) {
        final address = addressesState.addresses[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildAddressCard(theme, address),
        );
      },
    );
  }

  Widget _buildAddAddressTab(ThemeData theme) {
    return SingleChildScrollView(
      child: EnhancedAddressForm(
        onAddressSaved: (address) {
          _logger.info('💾 [ADDRESS-MANAGEMENT] Address saved successfully');
          
          // Add address to provider
          ref.read(customerAddressesProvider.notifier).addAddress(address);
          
          // Switch to address list tab
          _tabController.animateTo(0);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address saved successfully')),
          );
        },
        showGPSButton: true,
        validateOnSave: true,
      ),
    );
  }

  Widget _buildAddressCard(ThemeData theme, CustomerAddress address) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
                    _getAddressIcon(address.label),
                    size: 20,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            address.label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (address.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Default',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address.fullAddress,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) => _handleAddressAction(action, address),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    if (!address.isDefault)
                      const PopupMenuItem(
                        value: 'set_default',
                        child: Row(
                          children: [
                            Icon(Icons.star),
                            SizedBox(width: 8),
                            Text('Set as Default'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (address.deliveryInstructions != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        address.deliveryInstructions!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (address.latitude != null && address.longitude != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'GPS coordinates available',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No addresses saved',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first delivery address to get started with orders',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GEButton.primary(
              text: 'Add Address',
              onPressed: () => _tabController.animateTo(1),
              icon: Icons.add_location,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GEButton.outline(
              text: 'Retry',
              onPressed: _refreshAddresses,
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionBottomBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: GEButton.primary(
          text: _selectedAddress != null
              ? 'Use This Address'
              : 'Select an Address',
          onPressed: _selectedAddress != null ? _confirmSelection : null,
          icon: Icons.check,
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(ThemeData theme) {
    return FloatingActionButton.extended(
      onPressed: () => _tabController.animateTo(1),
      icon: const Icon(Icons.add_location),
      label: const Text('Add Address'),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
    );
  }

  IconData _getAddressIcon(String? addressType) {
    switch (addressType?.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'work':
      case 'office':
        return Icons.business;
      case 'hotel':
        return Icons.hotel;
      default:
        return Icons.location_on;
    }
  }

  void _refreshAddresses() {
    _logger.info('🔄 [ADDRESS-MANAGEMENT] Refreshing addresses');
    ref.read(customerAddressesProvider.notifier).loadAddresses();
  }

  void _handleAddressAction(String action, CustomerAddress address) {
    _logger.info('🏠 [ADDRESS-MANAGEMENT] Handling action: $action for address: ${address.id}');

    switch (action) {
      case 'edit':
        _editAddress(address);
        break;
      case 'set_default':
        _setDefaultAddress(address);
        break;
      case 'delete':
        _deleteAddress(address);
        break;
    }
  }

  void _editAddress(CustomerAddress address) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EnhancedAddressForm(
        initialAddress: address,
        onAddressSaved: (updatedAddress) {
          ref.read(customerAddressesProvider.notifier).updateAddress(address.id!, updatedAddress);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address updated successfully')),
          );
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _setDefaultAddress(CustomerAddress address) {
    ref.read(customerAddressesProvider.notifier).setDefaultAddress(address.id!);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Default address updated')),
    );
  }

  void _deleteAddress(CustomerAddress address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Are you sure you want to delete "${address.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(customerAddressesProvider.notifier).deleteAddress(address.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Address deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmSelection() {
    if (_selectedAddress != null && widget.onAddressSelected != null) {
      widget.onAddressSelected!(_selectedAddress);
      context.pop(_selectedAddress);
    }
  }
}
