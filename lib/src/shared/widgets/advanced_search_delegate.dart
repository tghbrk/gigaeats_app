import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/vendors/data/models/vendor.dart';
import '../../features/customers/data/models/customer.dart';
import '../../features/orders/data/models/order.dart';
// TODO: Restore when vendor_provider is implemented
// import '../../features/vendors/presentation/providers/vendor_provider.dart';
import '../../features/customers/presentation/providers/customer_provider.dart';
import '../../features/orders/presentation/providers/order_provider.dart';

class AdvancedSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;
  final String searchType; // 'vendors', 'products', 'customers', 'orders'

  AdvancedSearchDelegate({
    required this.ref,
    required this.searchType,
  });

  @override
  String get searchFieldLabel {
    switch (searchType) {
      case 'vendors':
        return 'Search vendors...';
      case 'products':
        return 'Search products...';
      case 'customers':
        return 'Search customers...';
      case 'orders':
        return 'Search orders...';
      default:
        return 'Search...';
    }
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: const Icon(Icons.clear),
      ),
      IconButton(
        onPressed: () => _showAdvancedFilters(context),
        icon: const Icon(Icons.tune),
        tooltip: 'Advanced Filters',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, '');
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return _buildEmptyState();
    }

    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildRecentSearches();
    }

    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    switch (searchType) {
      case 'vendors':
        return _buildVendorResults();
      case 'products':
        return _buildProductResults();
      case 'customers':
        return _buildCustomerResults();
      case 'orders':
        return _buildOrderResults();
      default:
        return _buildEmptyState();
    }
  }

  Widget _buildVendorResults() {
    return Consumer(
      builder: (context, ref, child) {
        // TODO: Restore when vendorsProvider is implemented
        // final vendorsState = ref.watch(vendorsProvider);
        final vendorsState = null;
        
        if (vendorsState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredVendors = vendorsState.vendors.where((vendor) {
          return vendor.businessName.toLowerCase().contains(query.toLowerCase()) ||
              (vendor.description?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
              vendor.cuisineTypes.any((cuisine) => 
                  cuisine.toLowerCase().contains(query.toLowerCase()));
        }).toList();

        if (filteredVendors.isEmpty) {
          return _buildNoResultsState();
        }

        return ListView.builder(
          itemCount: filteredVendors.length,
          itemBuilder: (context, index) {
            final vendor = filteredVendors[index];
            return _buildVendorTileWithContext(vendor, context);
          },
        );
      },
    );
  }

  Widget _buildProductResults() {
    // TODO: Implement product search when product provider is available
    return _buildComingSoonState('Product search');
  }

  Widget _buildCustomerResults() {
    return Consumer(
      builder: (context, ref, child) {
        final customersState = ref.watch(customerProvider);
        
        if (customersState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredCustomers = customersState.customers.where((customer) {
          return customer.businessName.toLowerCase().contains(query.toLowerCase()) ||
              customer.contactPerson.toLowerCase().contains(query.toLowerCase()) ||
              customer.email.toLowerCase().contains(query.toLowerCase()) ||
              customer.phoneNumber.contains(query);
        }).toList();

        if (filteredCustomers.isEmpty) {
          return _buildNoResultsState();
        }

        return ListView.builder(
          itemCount: filteredCustomers.length,
          itemBuilder: (context, index) {
            final customer = filteredCustomers[index];
            return _buildCustomerTileWithContext(customer, context);
          },
        );
      },
    );
  }

  Widget _buildOrderResults() {
    return Consumer(
      builder: (context, ref, child) {
        final ordersState = ref.watch(ordersProvider);
        
        if (ordersState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredOrders = ordersState.orders.where((order) {
          return order.orderNumber.toLowerCase().contains(query.toLowerCase()) ||
              order.customerName.toLowerCase().contains(query.toLowerCase()) ||
              order.vendorName.toLowerCase().contains(query.toLowerCase());
        }).toList();

        if (filteredOrders.isEmpty) {
          return _buildNoResultsState();
        }

        return ListView.builder(
          itemCount: filteredOrders.length,
          itemBuilder: (context, index) {
            final order = filteredOrders[index];
            return _buildOrderTileWithContext(order, context);
          },
        );
      },
    );
  }

  Widget _buildVendorTileWithContext(Vendor vendor, BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
        child: Icon(
          Icons.store,
          color: Colors.blue,
        ),
      ),
      title: Text(vendor.businessName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(vendor.description ?? 'No description available', maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.star, size: 16, color: Colors.amber),
              const SizedBox(width: 4),
              Text('${vendor.rating.toStringAsFixed(1)} (${vendor.totalReviews})'),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: vendor.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  vendor.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: vendor.isActive ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        close(context, 'vendor:${vendor.id}');
      },
    );
  }

  Widget _buildCustomerTileWithContext(Customer customer, BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.purple.withValues(alpha: 0.1),
        child: Icon(
          Icons.business,
          color: Colors.purple,
        ),
      ),
      title: Text(customer.businessName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(customer.contactPerson),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.email, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  customer.email,
                  style: TextStyle(color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: customer.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  customer.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: customer.isActive ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        close(context, 'customer:${customer.id}');
      },
    );
  }

  Widget _buildOrderTileWithContext(Order order, BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getStatusColor(order.status).withValues(alpha: 0.1),
        child: Icon(
          Icons.receipt_long,
          color: _getStatusColor(order.status),
        ),
      ),
      title: Text('Order #${order.orderNumber}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${order.customerName} • ${order.vendorName}'),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'RM ${order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.status.displayName,
                  style: TextStyle(
                    color: _getStatusColor(order.status),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        close(context, 'order:${order.id}');
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Start typing to search',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search for ${searchType.replaceAll('s', '')}s by name, description, or other details',
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms or filters',
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    // TODO: Implement recent searches from local storage
    return _buildEmptyState();
  }

  Widget _buildComingSoonState(String feature) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 80,
            color: Colors.orange[400],
          ),
          const SizedBox(height: 16),
          Text(
            '$feature coming soon!',
            style: TextStyle(
              fontSize: 18,
              color: Colors.orange[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.ready:
        return Colors.teal;
      case OrderStatus.outForDelivery:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  void _showAdvancedFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Advanced Filters',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: _buildAdvancedFiltersContent(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedFiltersContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advanced filters coming soon!',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Text(
          'This will include filters for:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ...{
          'vendors': ['Cuisine type', 'Rating', 'Distance', 'Halal certified'],
          'products': ['Category', 'Price range', 'Dietary restrictions', 'Availability'],
          'customers': ['Customer type', 'Location', 'Status', 'Registration date'],
          'orders': ['Status', 'Date range', 'Amount range', 'Vendor'],
        }[searchType]?.map((filter) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Text(filter),
            ],
          ),
        )) ?? [],
      ],
    );
  }
}
