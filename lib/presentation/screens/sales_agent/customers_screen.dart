import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  String _searchQuery = '';
  CustomerType? _selectedType;
  bool? _isActiveFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load customers on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomers(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _loadCustomers({bool refresh = false}) {
    final authState = ref.read(authStateProvider);
    final salesAgentId = authState.user?.id;

    ref.read(customersProvider.notifier).loadCustomers(
      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      type: _selectedType,
      salesAgentId: salesAgentId,
      isActive: _isActiveFilter,
      refresh: refresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customerState = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showFilterDialog(),
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter customers',
          ),
          IconButton(
            onPressed: () => _loadCustomers(refresh: true),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            setState(() {
              switch (index) {
                case 0:
                  _selectedType = null;
                  _isActiveFilter = null;
                  break;
                case 1:
                  _selectedType = null;
                  _isActiveFilter = true;
                  break;
                case 2:
                  _selectedType = CustomerType.corporate;
                  _isActiveFilter = null;
                  break;
                case 3:
                  _selectedType = CustomerType.school;
                  _isActiveFilter = null;
                  break;
              }
            });
            _loadCustomers(refresh: true);
          },
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Corporate'),
            Tab(text: 'Schools'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surface,
            child: SearchBarWidget(
              controller: _searchController,
              hintText: 'Search customers by name, email, or phone...',
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchQuery == value) {
                    _loadCustomers(refresh: true);
                  }
                });
              },
              onClear: () {
                setState(() {
                  _searchQuery = '';
                });
                _loadCustomers(refresh: true);
              },
            ),
          ),

          // Customer List
          Expanded(
            child: _buildCustomerList(customerState),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "customers_add_customer_fab",
        onPressed: () => _navigateToCreateCustomer(),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer'),
      ),
    );
  }

  Widget _buildCustomerList(CustomerState customerState) {
    if (customerState.isLoading && customerState.customers.isEmpty) {
      return const LoadingWidget(message: 'Loading customers...');
    }

    if (customerState.errorMessage != null && customerState.customers.isEmpty) {
      return CustomErrorWidget(
        message: customerState.errorMessage!,
        onRetry: () => _loadCustomers(refresh: true),
      );
    }

    if (customerState.customers.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async => _loadCustomers(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: customerState.customers.length + 
                   (customerState.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == customerState.customers.length) {
            // Load more indicator
            if (customerState.isLoading) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            } else {
              // Load more button
              return Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => _loadCustomers(),
                  child: const Text('Load More'),
                ),
              );
            }
          }

          final customer = customerState.customers[index];
          return _buildCustomerCard(customer);
        },
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToCustomerDetails(customer.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    radius: 24,
                    child: Text(
                      customer.organizationName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Customer Info
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
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer.phoneNumber,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status and Actions
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: customer.isActive
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          customer.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: customer.isActive ? Colors.green : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      PopupMenuButton<String>(
                        onSelected: (value) => _handleCustomerAction(value, customer),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility),
                                SizedBox(width: 8),
                                Text('View Details'),
                              ],
                            ),
                          ),
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
                ],
              ),

              const SizedBox(height: 12),

              // Customer Stats
              Row(
                children: [
                  _buildStatChip(
                    icon: Icons.shopping_bag,
                    label: '${customer.totalOrders} orders',
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    icon: Icons.attach_money,
                    label: 'RM ${customer.totalSpent.toStringAsFixed(0)}',
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No customers found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by adding your first customer',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreateCustomer(),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Customer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    // TODO: Implement filter dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filter dialog coming soon!')),
    );
  }

  void _handleCustomerAction(String action, Customer customer) {
    switch (action) {
      case 'view':
        _navigateToCustomerDetails(customer.id);
        break;
      case 'edit':
        _navigateToEditCustomer(customer.id);
        break;
      case 'orders':
        // TODO: Navigate to customer orders
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer orders view coming soon!')),
        );
        break;
      case 'activate':
      case 'deactivate':
        _toggleCustomerStatus(customer);
        break;
    }
  }

  void _toggleCustomerStatus(Customer customer) async {
    final success = await ref.read(customersProvider.notifier).updateCustomer(
      customerId: customer.id,
      isActive: !customer.isActive,
    );

    if (success != null) {
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

  void _navigateToCustomerDetails(String customerId) {
    context.push('/sales-agent/customers/$customerId');
  }

  void _navigateToEditCustomer(String customerId) {
    context.push('/sales-agent/customers/$customerId/edit');
  }

  void _navigateToCreateCustomer() {
    context.push('/sales-agent/customers/create');
  }
}
