import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class CustomerDetailsScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailsScreen({
    super.key,
    required this.customerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerProvider(customerId));

    return Scaffold(
      body: customerAsync.when(
        data: (customer) {
          if (customer == null) {
            return const CustomErrorWidget(
              message: 'Customer not found',
            );
          }
          return _buildCustomerDetails(context, ref, customer);
        },
        loading: () => const LoadingWidget(message: 'Loading customer details...'),
        error: (error, stack) => CustomErrorWidget(
          message: 'Error loading customer: $error',
          onRetry: () => ref.invalidate(customerProvider(customerId)),
        ),
      ),
    );
  }

  Widget _buildCustomerDetails(BuildContext context, WidgetRef ref, Customer customer) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              customer.organizationName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 3,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    customer.organizationName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) => _handleAction(context, ref, value, customer),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit Customer'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'orders',
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long),
                      SizedBox(width: 8),
                      Text('View Orders'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'create_order',
                  child: Row(
                    children: [
                      Icon(Icons.add_shopping_cart),
                      SizedBox(width: 8),
                      Text('Create Order'),
                    ],
                  ),
                ),
                if (customer.isActive)
                  const PopupMenuItem(
                    value: 'deactivate',
                    child: Row(
                      children: [
                        Icon(Icons.block, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Deactivate', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  )
                else
                  const PopupMenuItem(
                    value: 'activate',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Activate', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status and Type
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: customer.isActive
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            customer.isActive ? Icons.check_circle : Icons.block,
                            size: 16,
                            color: customer.isActive ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            customer.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: customer.isActive ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        customer.type.displayName,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (customer.isVerified) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 24),

                // Statistics Cards
                _buildStatisticsCards(customer),

                const SizedBox(height: 24),

                // Contact Information
                _buildSectionCard(
                  title: 'Contact Information',
                  icon: Icons.contact_phone,
                  child: _buildContactInfo(customer),
                ),

                const SizedBox(height: 16),

                // Address Information
                _buildSectionCard(
                  title: 'Address',
                  icon: Icons.location_on,
                  child: _buildAddressInfo(customer.address),
                ),

                const SizedBox(height: 16),

                // Business Information
                if (customer.businessInfo != null)
                  Column(
                    children: [
                      _buildSectionCard(
                        title: 'Business Information',
                        icon: Icons.business,
                        child: _buildBusinessInfo(customer.businessInfo!),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Preferences
                _buildSectionCard(
                  title: 'Preferences',
                  icon: Icons.settings,
                  child: _buildPreferences(customer.preferences),
                ),

                const SizedBox(height: 16),

                // Notes and Tags
                if (customer.notes != null || customer.tags.isNotEmpty)
                  _buildSectionCard(
                    title: 'Notes & Tags',
                    icon: Icons.note,
                    child: _buildNotesAndTags(customer),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCards(Customer customer) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Orders',
            value: customer.totalOrders.toString(),
            icon: Icons.shopping_bag,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Total Spent',
            value: 'RM ${customer.totalSpent.toStringAsFixed(0)}',
            icon: Icons.attach_money,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Avg Order',
            value: 'RM ${customer.averageOrderValue.toStringAsFixed(0)}',
            icon: Icons.trending_up,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(Customer customer) {
    return Column(
      children: [
        _buildInfoRow('Contact Person', customer.contactPersonName),
        _buildInfoRow('Email', customer.email),
        _buildInfoRow('Phone', customer.phoneNumber),
        if (customer.alternatePhoneNumber != null)
          _buildInfoRow('Alternate Phone', customer.alternatePhoneNumber!),
      ],
    );
  }

  Widget _buildAddressInfo(CustomerAddress address) {
    return Column(
      children: [
        _buildInfoRow('Street', address.street),
        _buildInfoRow('City', address.city),
        _buildInfoRow('State', address.state),
        _buildInfoRow('Postcode', address.postcode),
        if (address.buildingName != null)
          _buildInfoRow('Building', address.buildingName!),
        if (address.floor != null)
          _buildInfoRow('Floor', address.floor!),
        if (address.deliveryInstructions != null)
          _buildInfoRow('Delivery Instructions', address.deliveryInstructions!),
      ],
    );
  }

  Widget _buildBusinessInfo(CustomerBusinessInfo businessInfo) {
    return Column(
      children: [
        if (businessInfo.companyRegistrationNumber != null)
          _buildInfoRow('Registration No.', businessInfo.companyRegistrationNumber!),
        if (businessInfo.taxId != null)
          _buildInfoRow('Tax ID', businessInfo.taxId!),
        _buildInfoRow('Industry', businessInfo.industry),
        _buildInfoRow('Employees', businessInfo.employeeCount.toString()),
        if (businessInfo.website != null)
          _buildInfoRow('Website', businessInfo.website!),
        if (businessInfo.businessHours.isNotEmpty)
          _buildInfoRow('Business Hours', businessInfo.businessHours.join(', ')),
      ],
    );
  }

  Widget _buildPreferences(CustomerPreferences preferences) {
    return Column(
      children: [
        if (preferences.preferredCuisines.isNotEmpty)
          _buildInfoRow('Preferred Cuisines', preferences.preferredCuisines.join(', ')),
        if (preferences.dietaryRestrictions.isNotEmpty)
          _buildInfoRow('Dietary Restrictions', preferences.dietaryRestrictions.join(', ')),
        if (preferences.halalOnly)
          _buildInfoRow('Halal Only', 'Yes'),
        if (preferences.vegetarianOptions)
          _buildInfoRow('Vegetarian Options', 'Required'),
        _buildInfoRow(
          'Budget Range',
          'RM ${preferences.budgetRangeMin} - RM ${preferences.budgetRangeMax}',
        ),
        if (preferences.preferredDeliveryTimes.isNotEmpty)
          _buildInfoRow(
            'Preferred Delivery Times',
            preferences.preferredDeliveryTimes.join(', '),
          ),
      ],
    );
  }

  Widget _buildNotesAndTags(Customer customer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (customer.notes != null) ...[
          const Text(
            'Notes:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(customer.notes!),
          const SizedBox(height: 16),
        ],
        if (customer.tags.isNotEmpty) ...[
          const Text(
            'Tags:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: customer.tags.map((tag) {
              return Chip(
                label: Text(tag),
                backgroundColor: Colors.grey.withValues(alpha: 0.1),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action, Customer customer) {
    switch (action) {
      case 'edit':
        context.push('/sales-agent/customers/${customer.id}/edit');
        break;
      case 'orders':
        // TODO: Navigate to customer orders
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer orders view coming soon!')),
        );
        break;
      case 'create_order':
        // TODO: Navigate to create order with pre-selected customer
        context.push('/sales-agent/create-order');
        break;
      case 'activate':
      case 'deactivate':
        _toggleCustomerStatus(context, ref, customer);
        break;
    }
  }

  void _toggleCustomerStatus(BuildContext context, WidgetRef ref, Customer customer) async {
    final success = await ref.read(customersProvider.notifier).updateCustomer(
      customerId: customer.id,
      isActive: !customer.isActive,
    );

    if (success != null) {
      // Refresh the customer data
      ref.invalidate(customerProvider(customer.id));

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Customer ${customer.isActive ? 'deactivated' : 'activated'} successfully',
            ),
          ),
        );
      }
    } else {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update customer status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
