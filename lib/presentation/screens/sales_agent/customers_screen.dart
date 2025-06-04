import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/customer_card.dart';
import '../../widgets/search_bar_widget.dart';

import '../../../core/utils/responsive_utils.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  CustomerType? _selectedType;
  bool? _isActiveFilter;
  Timer? _debounceTimer;
  String _currentSearchQuery = '';

  // Memoized filter parameters to prevent infinite rebuilds
  Map<String, dynamic>? _cachedFilterParams;
  String? _lastSearchQuery;
  CustomerType? _lastSelectedType;
  bool? _lastIsActiveFilter;

  @override
  void initState() {
    super.initState();
    debugPrint('🔄 CustomersScreen: initState() called');

    // Load customers when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🔄 CustomersScreen: PostFrameCallback executed');
      if (!kIsWeb) {
        debugPrint('🔄 CustomersScreen: Mobile platform - loading customers via notifier');
        // For mobile, use the notifier
        ref.read(customerProvider.notifier).loadCustomers();
      } else {
        debugPrint('🔄 CustomersScreen: Web platform - provider will be watched automatically');
      }
      // For web, the provider will be watched automatically
    });
  }

  /// Get current filter parameters for web provider (memoized to prevent infinite rebuilds)
  Map<String, dynamic> get _webFilterParams {
    // Check if parameters have changed
    if (_cachedFilterParams == null ||
        _lastSearchQuery != _currentSearchQuery ||
        _lastSelectedType != _selectedType ||
        _lastIsActiveFilter != _isActiveFilter) {

      debugPrint('🔍 CustomersScreen: _webFilterParams - parameters changed, rebuilding cache');
      debugPrint('🔍 CustomersScreen: _currentSearchQuery = "$_currentSearchQuery" (was "$_lastSearchQuery")');
      debugPrint('🔍 CustomersScreen: _selectedType = $_selectedType (was $_lastSelectedType)');
      debugPrint('🔍 CustomersScreen: _isActiveFilter = $_isActiveFilter (was $_lastIsActiveFilter)');

      // Update cached values
      _lastSearchQuery = _currentSearchQuery;
      _lastSelectedType = _selectedType;
      _lastIsActiveFilter = _isActiveFilter;

      // Build new parameters
      _cachedFilterParams = {
        'searchQuery': _currentSearchQuery.isNotEmpty ? _currentSearchQuery : null,
        'type': _selectedType,
        'isActive': _isActiveFilter,
        'limit': 50,
        'offset': 0,
      };

      debugPrint('🔍 CustomersScreen: New cached params: $_cachedFilterParams');
    } else {
      debugPrint('🔍 CustomersScreen: _webFilterParams - using cached parameters: $_cachedFilterParams');
    }

    return _cachedFilterParams!;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏗️ CustomersScreen: build() called');
    debugPrint('🏗️ CustomersScreen: kIsWeb = $kIsWeb');

    // Use platform-aware data fetching
    if (kIsWeb) {
      debugPrint('🏗️ CustomersScreen: Building web layout');
      return _buildWebLayout();
    } else {
      debugPrint('🏗️ CustomersScreen: Building mobile layout');
      return _buildMobileLayout();
    }
  }

  Widget _buildWebLayout() {
    debugPrint('🌐 CustomersScreen: _buildWebLayout() called');
    debugPrint('🌐 CustomersScreen: About to watch webCustomersProvider with params: $_webFilterParams');

    final customersAsync = ref.watch(webCustomersProvider(_webFilterParams));

    debugPrint('🌐 CustomersScreen: webCustomersProvider watched, state: ${customersAsync.runtimeType}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(webCustomersProvider(_webFilterParams));
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: customersAsync.when(
        data: (customers) => _buildCustomersList(customers),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(error.toString()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "customers_add_customer_fab",
        onPressed: () {
          context.push('/sales-agent/customers/add');
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer'),
      ),
    );
  }

  Widget _buildMobileLayout() {
    final customersState = ref.watch(customerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(customerProvider.notifier).loadCustomers();
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: customersState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : customersState.errorMessage != null
              ? _buildErrorState(customersState.errorMessage!)
              : _buildCustomersList(customersState.customers),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "customers_add_customer_fab_mobile",
        onPressed: () {
          context.push('/sales-agent/customers/add');
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer'),
      ),
    );
  }

  Widget _buildCustomersList(List<Customer> customers) {
    if (customers.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (kIsWeb) {
          ref.invalidate(webCustomersProvider(_webFilterParams));
        } else {
          ref.read(customerProvider.notifier).loadCustomers();
        }
      },
      child: ResponsiveContainer(
        child: Column(
          children: [
            // Search and filters
            Padding(
              padding: context.responsivePadding,
              child: Column(
                children: [
                  SearchBarWidget(
                    controller: _searchController,
                    hintText: 'Search customers...',
                    onChanged: _onSearchChanged,
                    onClear: _onSearchCleared,
                  ),
                  if (_hasActiveFilters()) ...[
                    const SizedBox(height: 8),
                    _buildActiveFilters(),
                  ],
                ],
              ),
            ),
            
            // Customer list
            Expanded(
              child: context.isDesktop
                  ? _buildDesktopCustomersList(customers)
                  : _buildMobileCustomersList(customers),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCustomersList(List<Customer> customers) {
    return ListView.builder(
      padding: context.responsivePadding,
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return CustomerCard(
          customer: customer,
          onEdit: () => _editCustomer(customer),
          onDelete: () => _deleteCustomer(customer),
        );
      },
    );
  }

  Widget _buildDesktopCustomersList(List<Customer> customers) {
    return GridView.builder(
      padding: context.responsivePadding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.gridColumns,
        childAspectRatio: _getCardAspectRatio(context),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return CustomerCard(
          customer: customer,
          onEdit: () => _editCustomer(customer),
          onDelete: () => _deleteCustomer(customer),
        );
      },
    );
  }

  double _getCardAspectRatio(BuildContext context) {
    // Adjust aspect ratio based on grid columns to ensure proper card height
    final columns = context.gridColumns;
    if (columns >= 4) return 2.8; // Large desktop - more compact
    if (columns == 3) return 3.2; // Desktop - balanced
    return 2.5; // Tablet - taller cards
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: context.responsivePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No customers found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first customer to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/sales-agent/customers/add');
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Add Customer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: context.responsivePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading customers',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (kIsWeb) {
                  ref.invalidate(webCustomersProvider(_webFilterParams));
                } else {
                  ref.read(customerProvider.notifier).loadCustomers();
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilters() {
    final chips = <Widget>[];

    if (_selectedType != null) {
      chips.add(
        FilterChip(
          label: Text(_selectedType!.displayName),
          selected: true,
          onSelected: (_) {},
          onDeleted: () {
            setState(() {
              _selectedType = null;
            });
            _applyFilters();
          },
        ),
      );
    }

    if (_isActiveFilter != null) {
      chips.add(
        FilterChip(
          label: Text(_isActiveFilter! ? 'Active Only' : 'Inactive Only'),
          selected: true,
          onSelected: (_) {},
          onDeleted: () {
            setState(() {
              _isActiveFilter = null;
            });
            _applyFilters();
          },
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  bool _hasActiveFilters() {
    return _selectedType != null || _isActiveFilter != null;
  }

  void _onSearchChanged(String query) {
    debugPrint('🔍 CustomersScreen: _onSearchChanged called with query: "$query"');
    debugPrint('🔍 CustomersScreen: Current _currentSearchQuery: "$_currentSearchQuery"');
    debugPrint('🔍 CustomersScreen: kIsWeb = $kIsWeb');

    if (kIsWeb) {
      debugPrint('🔍 CustomersScreen: Web platform - setting up debounced search');

      // Cancel previous timer
      _debounceTimer?.cancel();
      debugPrint('🔍 CustomersScreen: Previous timer cancelled');

      // Set up new timer for debounced search
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        debugPrint('🔍 CustomersScreen: Debounce timer fired for query: "$query"');
        if (mounted) {
          debugPrint('🔍 CustomersScreen: Widget still mounted, calling setState');
          setState(() {
            _currentSearchQuery = query;
            debugPrint('🔍 CustomersScreen: _currentSearchQuery updated to: "$_currentSearchQuery"');
          });
        } else {
          debugPrint('🔍 CustomersScreen: Widget not mounted, skipping setState');
        }
      });
      debugPrint('🔍 CustomersScreen: New debounce timer set');
    } else {
      debugPrint('🔍 CustomersScreen: Mobile platform - calling searchCustomers');
      ref.read(customerProvider.notifier).searchCustomers(query);
    }
  }

  void _onSearchCleared() {
    debugPrint('🧹 CustomersScreen: _onSearchCleared called');
    _searchController.clear();

    if (kIsWeb) {
      debugPrint('🧹 CustomersScreen: Web platform - clearing search and invalidating cache');
      _debounceTimer?.cancel();
      _cachedFilterParams = null; // Invalidate cache
      setState(() {
        _currentSearchQuery = '';
      });
    } else {
      debugPrint('🧹 CustomersScreen: Mobile platform - clearing search via _onSearchChanged');
      _onSearchChanged('');
    }
  }

  void _applyFilters() {
    debugPrint('🔧 CustomersScreen: _applyFilters called');

    if (kIsWeb) {
      debugPrint('🔧 CustomersScreen: Web platform - invalidating cache and triggering rebuild');
      // Invalidate cache to force new parameters
      _cachedFilterParams = null;

      // For web, trigger a rebuild with new filter parameters
      setState(() {
        // The _webFilterParams getter will include the updated filters
      });
    } else {
      debugPrint('🔧 CustomersScreen: Mobile platform - applying filters via notifier');
      final notifier = ref.read(customerProvider.notifier);
      notifier.filterByType(_selectedType);
      notifier.filterByActiveStatus(_isActiveFilter);
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CustomerFiltersBottomSheet(
        selectedType: _selectedType,
        isActiveFilter: _isActiveFilter,
        onTypeChanged: (type) {
          setState(() {
            _selectedType = type;
          });
          _applyFilters();
        },
        onActiveFilterChanged: (isActive) {
          setState(() {
            _isActiveFilter = isActive;
          });
          _applyFilters();
        },
        onClearFilters: () {
          setState(() {
            _selectedType = null;
            _isActiveFilter = null;
          });
          _applyFilters();
        },
      ),
    );
  }

  void _editCustomer(Customer customer) {
    debugPrint('🔧 CustomersScreen: _editCustomer called for ${customer.organizationName} (${customer.id})');
    context.push('/sales-agent/customers/${customer.id}/edit');
  }

  void _deleteCustomer(Customer customer) {
    debugPrint('🔧 CustomersScreen: _deleteCustomer called for ${customer.organizationName} (${customer.id})');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.organizationName}?'),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('🔧 CustomersScreen: Delete cancelled');
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              debugPrint('🔧 CustomersScreen: Delete confirmed, calling repository...');
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();
              final success = await ref.read(customerProvider.notifier).deleteCustomer(customer.id);
              debugPrint('🔧 CustomersScreen: Delete result: $success');
              if (success && mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Customer deleted successfully')),
                );
              } else if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Failed to delete customer. Please try again.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class CustomerFiltersBottomSheet extends StatelessWidget {
  final CustomerType? selectedType;
  final bool? isActiveFilter;
  final ValueChanged<CustomerType?> onTypeChanged;
  final ValueChanged<bool?> onActiveFilterChanged;
  final VoidCallback onClearFilters;

  const CustomerFiltersBottomSheet({
    super.key,
    this.selectedType,
    this.isActiveFilter,
    required this.onTypeChanged,
    required this.onActiveFilterChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Customers',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () {
                  onClearFilters();
                  Navigator.of(context).pop();
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Customer Type Filter
          Text(
            'Customer Type',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('All Types'),
                selected: selectedType == null,
                onSelected: (_) {
                  onTypeChanged(null);
                  Navigator.of(context).pop();
                },
              ),
              ...CustomerType.values.map((type) => FilterChip(
                label: Text(type.displayName),
                selected: selectedType == type,
                onSelected: (_) {
                  onTypeChanged(type);
                  Navigator.of(context).pop();
                },
              )),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Active Status Filter
          Text(
            'Status',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: isActiveFilter == null,
                onSelected: (_) {
                  onActiveFilterChanged(null);
                  Navigator.of(context).pop();
                },
              ),
              FilterChip(
                label: const Text('Active Only'),
                selected: isActiveFilter == true,
                onSelected: (_) {
                  onActiveFilterChanged(true);
                  Navigator.of(context).pop();
                },
              ),
              FilterChip(
                label: const Text('Inactive Only'),
                selected: isActiveFilter == false,
                onSelected: (_) {
                  onActiveFilterChanged(false);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
