import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/customer.dart';
import '../providers/customer_provider.dart';
import '../../../../core/widgets/search_bar_widget.dart';
import 'customer_card.dart';

class CustomerSelector extends ConsumerStatefulWidget {
  final Customer? selectedCustomer;
  final Function(Customer?) onCustomerSelected;
  final bool allowManualEntry;
  final String? manualCustomerName;
  final String? manualCustomerPhone;
  final String? manualCustomerEmail;
  final Function(String name, String phone, String email)? onManualEntryChanged;

  const CustomerSelector({
    super.key,
    this.selectedCustomer,
    required this.onCustomerSelected,
    this.allowManualEntry = true,
    this.manualCustomerName,
    this.manualCustomerPhone,
    this.manualCustomerEmail,
    this.onManualEntryChanged,
  });

  @override
  ConsumerState<CustomerSelector> createState() => _CustomerSelectorState();
}

class _CustomerSelectorState extends ConsumerState<CustomerSelector> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isManualEntry = false;
  CustomerType? _selectedType;
  Timer? _debounceTimer;
  String _currentSearchQuery = '';

  // Memoized filter parameters to prevent infinite rebuilds
  Map<String, dynamic>? _cachedFilterParams;
  String? _lastSearchQuery;
  CustomerType? _lastSelectedType;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.manualCustomerName ?? '';
    _phoneController.text = widget.manualCustomerPhone ?? '';
    _emailController.text = widget.manualCustomerEmail ?? '';
    
    // If no customer is selected and manual entry data exists, start in manual mode
    if (widget.selectedCustomer == null && widget.manualCustomerName?.isNotEmpty == true) {
      _isManualEntry = true;
    }
  }

  /// Get current filter parameters for web provider (memoized to prevent infinite rebuilds)
  Map<String, dynamic> get _webFilterParams {
    // Check if parameters have changed
    if (_cachedFilterParams == null ||
        _lastSearchQuery != _currentSearchQuery ||
        _lastSelectedType != _selectedType) {

      debugPrint('🔍 CustomerSelector: _webFilterParams - parameters changed, rebuilding cache');
      debugPrint('🔍 CustomerSelector: _currentSearchQuery = "$_currentSearchQuery" (was "$_lastSearchQuery")');
      debugPrint('🔍 CustomerSelector: _selectedType = $_selectedType (was $_lastSelectedType)');

      // Update cached values
      _lastSearchQuery = _currentSearchQuery;
      _lastSelectedType = _selectedType;

      // Build new parameters
      _cachedFilterParams = {
        'searchQuery': _currentSearchQuery.isNotEmpty ? _currentSearchQuery : null,
        'type': _selectedType,
        'isActive': true,
        'limit': 50,
        'offset': 0,
      };

      debugPrint('🔍 CustomerSelector: New cached params: $_cachedFilterParams');
    } else {
      debugPrint('🔍 CustomerSelector: _webFilterParams - using cached parameters: $_cachedFilterParams');
    }

    return _cachedFilterParams!;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with toggle
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.allowManualEntry) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text('Select Existing'),
                          icon: Icon(Icons.search),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text('Manual Entry'),
                          icon: Icon(Icons.edit),
                        ),
                      ],
                      selected: {_isManualEntry},
                      onSelectionChanged: (Set<bool> selection) {
                        setState(() {
                          _isManualEntry = selection.first;
                          if (_isManualEntry) {
                            widget.onCustomerSelected(null);
                          } else {
                            _nameController.clear();
                            _phoneController.clear();
                            _emailController.clear();
                            widget.onManualEntryChanged?.call('', '', '');
                          }
                        });
                      },
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Content based on mode
            if (_isManualEntry)
              _buildManualEntryForm()
            else
              _buildCustomerSelection(),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntryForm() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Customer Name *',
            hintText: 'Enter customer or company name',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            widget.onManualEntryChanged?.call(
              value,
              _phoneController.text,
              _emailController.text,
            );
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number *',
            hintText: '+60123456789',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          onChanged: (value) {
            widget.onManualEntryChanged?.call(
              _nameController.text,
              value,
              _emailController.text,
            );
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'customer@company.com',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) {
            widget.onManualEntryChanged?.call(
              _nameController.text,
              _phoneController.text,
              value,
            );
          },
        ),
      ],
    );
  }

  Widget _buildCustomerSelection() {
    return Column(
      children: [
        // Search and filters
        SearchBarWidget(
          hintText: 'Search customers...',
          onChanged: _onSearchChanged,
        ),
        const SizedBox(height: 8),

        // Type filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('All Types'),
                selected: _selectedType == null,
                onSelected: (_) {
                  setState(() {
                    _selectedType = null;
                    _cachedFilterParams = null; // Invalidate cache
                  });
                },
              ),
              const SizedBox(width: 8),
              ...CustomerType.values.map((type) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(type.displayName),
                  selected: _selectedType == type,
                  onSelected: (_) {
                    setState(() {
                      _selectedType = _selectedType == type ? null : type;
                      _cachedFilterParams = null; // Invalidate cache
                    });
                  },
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Selected customer display
        if (widget.selectedCustomer != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected: ${widget.selectedCustomer!.organizationName}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.selectedCustomer!.contactPersonName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        widget.selectedCustomer!.phoneNumber,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => widget.onCustomerSelected(null),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                  tooltip: 'Clear selection',
                ),
              ],
            ),
          )
        else
          // Customer list
          SizedBox(
            height: 300,
            child: _buildCustomerList(),
          ),

        const SizedBox(height: 16),

        // Add new customer button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              context.push('/sales-agent/customers/add');
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Add New Customer'),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerList() {
    if (kIsWeb) {
      final customersAsync = ref.watch(webCustomersProvider(_webFilterParams));
      
      return customersAsync.when(
        data: (customers) => _buildCustomerListView(customers),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(height: 8),
              Text('Error: $error'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(webCustomersProvider(_webFilterParams));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    } else {
      final customerState = ref.watch(customerProvider);
      
      if (customerState.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (customerState.errorMessage != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(height: 8),
              Text('Error: ${customerState.errorMessage}'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  ref.read(customerProvider.notifier).loadCustomers();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
      
      return _buildCustomerListView(customerState.customers);
    }
  }

  Widget _buildCustomerListView(List<Customer> customers) {
    if (customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No customers found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return CustomerCard(
          customer: customer,
          onTap: () => widget.onCustomerSelected(customer),
          showActions: false,
        );
      },
    );
  }

  void _onSearchChanged(String query) {
    debugPrint('🔍 CustomerSelector: _onSearchChanged called with query: "$query"');
    debugPrint('🔍 CustomerSelector: Current _currentSearchQuery: "$_currentSearchQuery"');
    debugPrint('🔍 CustomerSelector: kIsWeb = $kIsWeb');

    if (kIsWeb) {
      debugPrint('🔍 CustomerSelector: Web platform - setting up debounced search');

      // Cancel previous timer
      _debounceTimer?.cancel();
      debugPrint('🔍 CustomerSelector: Previous timer cancelled');

      // Set up new timer for debounced search
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        debugPrint('🔍 CustomerSelector: Debounce timer fired for query: "$query"');
        if (mounted) {
          debugPrint('🔍 CustomerSelector: Widget still mounted, calling setState');
          setState(() {
            _currentSearchQuery = query;
            debugPrint('🔍 CustomerSelector: _currentSearchQuery updated to: "$_currentSearchQuery"');
          });
        } else {
          debugPrint('🔍 CustomerSelector: Widget not mounted, skipping setState');
        }
      });
      debugPrint('🔍 CustomerSelector: New debounce timer set');
    } else {
      debugPrint('🔍 CustomerSelector: Mobile platform - calling searchCustomers');
      ref.read(customerProvider.notifier).searchCustomers(query);
    }
  }


}
