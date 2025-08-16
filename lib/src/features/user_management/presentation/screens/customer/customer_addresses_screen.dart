import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/customer_profile.dart';
import '../../providers/customer_address_provider.dart';
import '../../widgets/address_form_dialog.dart';
import '../../../../../design_system/widgets/buttons/ge_button.dart';
import '../../../../../core/utils/logger.dart';

class CustomerAddressesScreen extends ConsumerStatefulWidget {
  const CustomerAddressesScreen({super.key});

  @override
  ConsumerState<CustomerAddressesScreen> createState() => _CustomerAddressesScreenState();
}

class _CustomerAddressesScreenState extends ConsumerState<CustomerAddressesScreen> {
  final AppLogger _logger = AppLogger();

  @override
  void initState() {
    super.initState();
    // Load addresses when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logger.info('🏠 [ADDRESSES-SCREEN] Loading addresses');
      ref.read(customerAddressesProvider.notifier).loadAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final addressesState = ref.watch(customerAddressesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort addresses',
            onSelected: (value) => _handleSortOption(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'default_first',
                child: Row(
                  children: [
                    Icon(Icons.star),
                    SizedBox(width: 8),
                    Text('Default First'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'alphabetical',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha),
                    SizedBox(width: 8),
                    Text('Alphabetical'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'recently_added',
                child: Row(
                  children: [
                    Icon(Icons.access_time),
                    SizedBox(width: 8),
                    Text('Recently Added'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _logger.info('🔄 [ADDRESSES-SCREEN] Refreshing addresses');
              ref.read(customerAddressesProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: _buildBody(addressesState, theme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAddressDialog(),
        icon: const Icon(Icons.add_location),
        label: const Text('Add Address'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildBody(CustomerAddressesState state, ThemeData theme) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading addresses...'),
          ],
        ),
      );
    }

    if (state.error != null) {
      return _buildErrorState(state.error!, theme);
    }

    if (state.addresses.isEmpty) {
      return _buildEmptyState(theme);
    }

    return _buildAddressList(state.addresses, theme);
  }

  void _handleSortOption(String sortOption) {
    _logger.info('🏠 [ADDRESSES-SCREEN] Sort option selected: $sortOption');

    // Note: Addresses are already optimally sorted by the repository:
    // 1. Default address first
    // 2. Then by creation time (newest first)
    // This provides the best user experience for address selection

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Addresses are sorted by ${_getSortDisplayName(sortOption)}'),
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  String _getSortDisplayName(String sortOption) {
    switch (sortOption) {
      case 'default_first':
        return 'default first';
      case 'alphabetical':
        return 'alphabetical order';
      case 'recently_added':
        return 'recently added';
      default:
        return sortOption;
    }
  }

  Widget _buildAddressList(List<CustomerAddress> addresses, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(customerAddressesProvider.notifier).refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: addresses.length,
        itemBuilder: (context, index) {
          final address = addresses[index];
          return _buildDismissibleAddressCard(address, theme);
        },
      ),
    );
  }

  Widget _buildDismissibleAddressCard(CustomerAddress address, ThemeData theme) {
    return Dismissible(
      key: Key('address_${address.id}'),
      direction: address.isDefault
          ? DismissDirection.none // Prevent swiping default address
          : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete,
              color: theme.colorScheme.onError,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              'Delete',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onError,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (address.isDefault) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cannot delete default address'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
          return false;
        }

        return await _showQuickDeleteConfirmation(address);
      },
      onDismissed: (direction) {
        _deleteAddress(address);
      },
      child: _buildAddressCard(address, theme),
    );
  }

  Widget _buildAddressCard(CustomerAddress address, ThemeData theme) {
    final isDefault = address.isDefault;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDefault ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDefault
            ? BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 1.5,
              )
            : BorderSide.none,
      ),
      child: Container(
        decoration: isDefault
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.02),
                    theme.colorScheme.primary.withValues(alpha: 0.05),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            address.label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (address.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.primary.withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Default',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
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
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                address.deliveryInstructions!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      _buildAddressMetadata(address, theme),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleAddressAction(value, address),
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
            const SizedBox(height: 12),
            _buildQuickActionButtons(address, theme),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildAddressMetadata(CustomerAddress address, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            size: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            '${address.city}, ${address.state}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
          const Spacer(),
          if (address.isDefault) ...[
            Icon(
              Icons.verified,
              size: 12,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'Primary',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            Icon(
              Icons.access_time,
              size: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 4),
            Text(
              'Available',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons(CustomerAddress address, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showEditAddressDialog(address),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              side: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (!address.isDefault) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _setDefaultAddress(address),
              icon: const Icon(Icons.star, size: 16),
              label: const Text('Set Default'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        SizedBox(
          width: 80,
          child: OutlinedButton.icon(
            onPressed: () => _showDeleteConfirmation(address),
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('Delete'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(
                color: theme.colorScheme.error.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
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
              'Error Loading Addresses',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            GEButton.primary(
              text: 'Retry',
              onPressed: () {
                _logger.info('🔄 [ADDRESSES-SCREEN] Retrying address load');
                ref.read(customerAddressesProvider.notifier).clearError();
                ref.read(customerAddressesProvider.notifier).loadAddresses();
              },
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
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No Addresses Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first delivery address to get started with ordering food.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            GEButton.primary(
              text: 'Add Your First Address',
              onPressed: () => _showAddAddressDialog(),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAddressDialog() {
    _logger.info('🏠 [ADDRESSES-SCREEN] Opening add address dialog');

    showDialog(
      context: context,
      builder: (context) => AddressFormDialog(
        onSuccess: () {
          _logger.info('🏠 [ADDRESSES-SCREEN] Address added successfully');
        },
      ),
    );
  }

  void _handleAddressAction(String action, CustomerAddress address) {
    _logger.info('🏠 [ADDRESSES-SCREEN] Handling action: $action for address: ${address.id}');

    switch (action) {
      case 'edit':
        _showEditAddressDialog(address);
        break;
      case 'set_default':
        _setDefaultAddress(address);
        break;
      case 'delete':
        _showDeleteConfirmation(address);
        break;
    }
  }

  void _showEditAddressDialog(CustomerAddress address) {
    _logger.info('🏠 [ADDRESSES-SCREEN] Opening edit address dialog for: ${address.id}');

    showDialog(
      context: context,
      builder: (context) => AddressFormDialog(
        address: address,
        onSuccess: () {
          _logger.info('🏠 [ADDRESSES-SCREEN] Address updated successfully');
        },
      ),
    );
  }

  Future<void> _setDefaultAddress(CustomerAddress address) async {
    try {
      _logger.info('🏠 [ADDRESSES-SCREEN] Setting default address: ${address.id}');

      final success = await ref.read(customerAddressesProvider.notifier)
          .setDefaultAddress(address.id!);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${address.label} set as default address'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      _logger.error('❌ [ADDRESSES-SCREEN] Error setting default address', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting default address: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(CustomerAddress address) {
    final addressCount = ref.read(customerAddressesProvider).addresses.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${address.label}"?'),
            if (address.isDefault && addressCount > 1) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is your default address. Another address will be automatically set as default.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (addressCount == 1) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is your only address. You should add another address before deleting this one.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAddress(address);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAddress(CustomerAddress address) async {
    try {
      _logger.info('🏠 [ADDRESSES-SCREEN] Deleting address: ${address.id}');

      final success = await ref.read(customerAddressesProvider.notifier)
          .deleteAddress(address.id!);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${address.label} deleted successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      _logger.error('❌ [ADDRESSES-SCREEN] Error deleting address', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting address: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<bool> _showQuickDeleteConfirmation(CustomerAddress address) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this address?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.fullAddress,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }
}
