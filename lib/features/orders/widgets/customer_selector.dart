import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../customers/data/models/customer.dart';
import '../../customers/presentation/providers/customer_provider.dart';

class CustomerSelector extends ConsumerStatefulWidget {
  final Customer? selectedCustomer;
  final Function(Customer?) onCustomerSelected;
  final bool enabled;

  const CustomerSelector({
    super.key,
    this.selectedCustomer,
    required this.onCustomerSelected,
    this.enabled = true,
  });

  @override
  ConsumerState<CustomerSelector> createState() => _CustomerSelectorState();
}

class _CustomerSelectorState extends ConsumerState<CustomerSelector> {
  final TextEditingController _searchController = TextEditingController();
  bool _isExpanded = false;
  List<Customer> _filteredCustomers = [];

  @override
  void initState() {
    super.initState();
    if (widget.selectedCustomer != null) {
      _searchController.text = widget.selectedCustomer!.organizationName;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCustomers(List<Customer> customers, String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = customers.take(10).toList();
      } else {
        _filteredCustomers = customers
            .where((customer) =>
                customer.organizationName.toLowerCase().contains(query.toLowerCase()) ||
                customer.contactPersonName.toLowerCase().contains(query.toLowerCase()) ||
                customer.email.toLowerCase().contains(query.toLowerCase()))
            .take(10)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(simpleWebCustomersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Customer',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              TextFormField(
                controller: _searchController,
                enabled: widget.enabled,
                decoration: InputDecoration(
                  hintText: 'Search customers...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: widget.enabled
                      ? IconButton(
                          icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                          onPressed: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                onChanged: (value) {
                  customersAsync.whenData((customers) {
                    _filterCustomers(customers, value);
                  });
                  if (!_isExpanded) {
                    setState(() {
                      _isExpanded = true;
                    });
                  }
                },
                onTap: () {
                  if (widget.enabled && !_isExpanded) {
                    setState(() {
                      _isExpanded = true;
                    });
                    customersAsync.whenData((customers) {
                      _filterCustomers(customers, _searchController.text);
                    });
                  }
                },
              ),
              if (_isExpanded && widget.enabled)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: customersAsync.when(
                    data: (customers) {
                      if (_filteredCustomers.isEmpty && _searchController.text.isNotEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No customers found'),
                        );
                      }
                      
                      final displayCustomers = _filteredCustomers.isEmpty 
                          ? customers.take(10).toList() 
                          : _filteredCustomers;

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: displayCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = displayCustomers[index];
                          return ListTile(
                            title: Text(customer.organizationName),
                            subtitle: Text('${customer.contactPersonName} • ${customer.email}'),
                            onTap: () {
                              widget.onCustomerSelected(customer);
                              _searchController.text = customer.organizationName;
                              setState(() {
                                _isExpanded = false;
                              });
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error loading customers: $error'),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (widget.selectedCustomer != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selected: ${widget.selectedCustomer!.organizationName}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (widget.enabled)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      widget.onCustomerSelected(null);
                      _searchController.clear();
                    },
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
