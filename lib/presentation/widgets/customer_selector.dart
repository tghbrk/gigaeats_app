import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/customer.dart';
import '../providers/customer_provider.dart';
import '../providers/auth_provider.dart';
import 'search_bar_widget.dart';

class CustomerSelector extends ConsumerStatefulWidget {
  final Customer? selectedCustomer;
  final ValueChanged<Customer?> onCustomerSelected;
  final bool allowQuickCreate;

  const CustomerSelector({
    super.key,
    this.selectedCustomer,
    required this.onCustomerSelected,
    this.allowQuickCreate = true,
  });

  @override
  ConsumerState<CustomerSelector> createState() => _CustomerSelectorState();
}

class _CustomerSelectorState extends ConsumerState<CustomerSelector> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showCreateForm = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final salesAgentId = authState.user?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Expanded(
              child: Text(
                'Select Customer',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (widget.allowQuickCreate)
              TextButton.icon(
                onPressed: () => setState(() => _showCreateForm = !_showCreateForm),
                icon: Icon(_showCreateForm ? Icons.close : Icons.add),
                label: Text(_showCreateForm ? 'Cancel' : 'New Customer'),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Selected Customer Display
        if (widget.selectedCustomer != null && !_showCreateForm)
          _buildSelectedCustomer(),

        // Search Bar (only show if no customer selected or creating new)
        if (widget.selectedCustomer == null || _showCreateForm)
          Column(
            children: [
              SearchBarWidget(
                controller: _searchController,
                hintText: 'Search customers by name, email, or phone...',
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                onClear: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
          ),

        // Quick Create Form
        if (_showCreateForm)
          _buildQuickCreateForm()
        // Customer List
        else if (widget.selectedCustomer == null)
          _buildCustomerList(salesAgentId),
      ],
    );
  }

  Widget _buildSelectedCustomer() {
    final customer = widget.selectedCustomer!;
    final theme = Theme.of(context);

    return Card(
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
                      Text(
                        customer.organizationName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customer.contactPersonName,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customer.phoneNumber,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => widget.onCustomerSelected(null),
                  icon: const Icon(Icons.close),
                  tooltip: 'Remove selection',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                customer.type.displayName,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerList(String? salesAgentId) {
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResults(salesAgentId);
    } else {
      return _buildRecentCustomers(salesAgentId);
    }
  }

  Widget _buildSearchResults(String? salesAgentId) {
    final searchParams = {
      'query': _searchQuery,
      'salesAgentId': salesAgentId,
    };

    final searchResults = ref.watch(customerSearchProvider(searchParams));

    return searchResults.when(
      data: (customers) {
        if (customers.isEmpty) {
          return _buildEmptyState('No customers found matching "$_searchQuery"');
        }

        return _buildCustomerListView(customers);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState('Error searching customers: $error'),
    );
  }

  Widget _buildRecentCustomers(String? salesAgentId) {
    final recentCustomers = ref.watch(recentCustomersProvider(salesAgentId));

    return recentCustomers.when(
      data: (customers) {
        if (customers.isEmpty) {
          return _buildEmptyState('No customers found');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Customers',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildCustomerListView(customers),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState('Error loading customers: $error'),
    );
  }

  Widget _buildCustomerListView(List<Customer> customers) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return _buildCustomerTile(customer);
      },
    );
  }

  Widget _buildCustomerTile(Customer customer) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            customer.organizationName.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          customer.organizationName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customer.contactPersonName),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    customer.type.displayName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${customer.totalOrders} orders',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => widget.onCustomerSelected(customer),
      ),
    );
  }

  Widget _buildQuickCreateForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Create Customer',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'For detailed customer creation, use the customer management section.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to full customer creation form
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Full customer creation form coming soon!'),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create New Customer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
