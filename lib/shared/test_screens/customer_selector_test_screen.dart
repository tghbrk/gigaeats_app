import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/customers/data/models/customer.dart';
import '../../features/orders/widgets/customer_selector.dart';

/// Test screen to verify that the CustomerSelector infinite loop issue has been resolved
class CustomerSelectorTestScreen extends ConsumerStatefulWidget {
  const CustomerSelectorTestScreen({super.key});

  @override
  ConsumerState<CustomerSelectorTestScreen> createState() => _CustomerSelectorTestScreenState();
}

class _CustomerSelectorTestScreenState extends ConsumerState<CustomerSelectorTestScreen> {
  Customer? _selectedCustomer;
  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    debugPrint('🏗️ CustomerSelectorTestScreen: build() called (count: $_buildCount)');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Customer Selector Test (Build: $_buildCount)'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test info card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Selector Infinite Loop Test',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This test verifies that the CustomerSelector component no longer has infinite loop issues when fetching customers.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Build count: $_buildCount (should remain stable)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _buildCount > 5 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Customer Selector Widget
            CustomerSelector(
              selectedCustomer: _selectedCustomer,
              onCustomerSelected: (customer) {
                debugPrint('🎯 CustomerSelectorTestScreen: Customer selected: ${customer?.organizationName}');
                setState(() {
                  _selectedCustomer = customer;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Selected customer info
            if (_selectedCustomer != null)
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Customer',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Organization: ${_selectedCustomer!.organizationName}'),
                      Text('Contact: ${_selectedCustomer!.contactPersonName}'),
                      Text('Phone: ${_selectedCustomer!.phoneNumber}'),
                      Text('Email: ${_selectedCustomer!.email}'),
                      Text('Type: ${_selectedCustomer!.type.displayName}'),
                    ],
                  ),
                ),
              ),
            
            // Manual entry info - TEMPORARILY COMMENTED OUT
            // if (_manualCustomerName.isNotEmpty || _manualCustomerPhone.isNotEmpty || _manualCustomerEmail.isNotEmpty)
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manual Entry',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Manual customer entry temporarily disabled for quick launch'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
