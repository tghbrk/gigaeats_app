import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/customer_address_provider.dart';
import '../../domain/customer_profile.dart';
import '../../../../core/utils/logger.dart';

/// Widget that displays a summary of customer addresses for use in profile screens
class CustomerAddressSummary extends ConsumerWidget {
  final bool showAddButton;
  final bool showManageButton;
  final EdgeInsets? padding;

  const CustomerAddressSummary({
    super.key,
    this.showAddButton = true,
    this.showManageButton = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final addressesState = ref.watch(customerAddressesProvider);
    final logger = AppLogger();

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, context),
          const SizedBox(height: 16),
          addressesState.isLoading
              ? _buildLoadingState(theme)
              : addressesState.error != null
                  ? _buildErrorState(theme, addressesState.error!, ref)
                  : addressesState.addresses.isEmpty
                      ? _buildEmptyState(theme, context)
                      : _buildAddressList(theme, addressesState.addresses, context, logger),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Delivery Addresses',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (showManageButton)
          TextButton.icon(
            onPressed: () => context.push('/customer/addresses'),
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Manage'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Failed to load addresses',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => ref.read(customerAddressesProvider.notifier).refresh(),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
              ),
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_off,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No addresses added yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first delivery address to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          if (showAddButton) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/customer/addresses'),
                icon: const Icon(Icons.add_location),
                label: const Text('Add Address'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressList(ThemeData theme, List<CustomerAddress> addresses, BuildContext context, AppLogger logger) {
    final defaultAddress = addresses.where((addr) => addr.isDefault).firstOrNull;
    final otherAddresses = addresses.where((addr) => !addr.isDefault).toList();

    return Column(
      children: [
        if (defaultAddress != null) ...[
          _buildAddressCard(theme, defaultAddress, true, context, logger),
          if (otherAddresses.isNotEmpty) const SizedBox(height: 12),
        ],
        if (otherAddresses.isNotEmpty) ...[
          if (otherAddresses.length == 1)
            _buildAddressCard(theme, otherAddresses.first, false, context, logger)
          else
            _buildMultipleAddressesCard(theme, otherAddresses, context),
        ],
        if (showAddButton) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/customer/addresses'),
              icon: const Icon(Icons.add_location, size: 18),
              label: const Text('Add New Address'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAddressCard(ThemeData theme, CustomerAddress address, bool isDefault, BuildContext context, AppLogger logger) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDefault
            ? theme.colorScheme.primary.withValues(alpha: 0.05)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDefault
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
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
                  ),
                ),
              ),
              if (isDefault)
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
          ),
          const SizedBox(height: 8),
          Text(
            address.fullAddress,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleAddressesCard(ThemeData theme, List<CustomerAddress> addresses, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${addresses.length} other addresses',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  addresses.map((addr) => addr.label).join(', '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
