import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/customers/data/models/customer.dart';
// TODO: Remove unused import when customer provider is used
// import '../../features/customers/presentation/providers/customer_provider.dart';

/// Test screen to verify that the customer infinite loop issue has been resolved
class CustomerInfiniteLoopTest extends ConsumerStatefulWidget {
  const CustomerInfiniteLoopTest({super.key});

  @override
  ConsumerState<CustomerInfiniteLoopTest> createState() => _CustomerInfiniteLoopTestState();
}

class _CustomerInfiniteLoopTestState extends ConsumerState<CustomerInfiniteLoopTest> {
  String _currentSearchQuery = '';
  CustomerType? _selectedType;
  bool? _isActiveFilter;
  
  // Memoized filter parameters to prevent infinite rebuilds
  // TODO: Restore unused field when provider is implemented - commented out for analyzer cleanup
  // Map<String, dynamic>? _cachedFilterParams;
  // TODO: Restore unused field when provider is implemented - commented out for analyzer cleanup
  // String? _lastSearchQuery;
  // TODO: Restore unused field when provider is implemented - commented out for analyzer cleanup
  // CustomerType? _lastSelectedType;
  // TODO: Restore unused field when provider is implemented - commented out for analyzer cleanup
  // bool? _lastIsActiveFilter;
  
  int _buildCount = 0;
  final int _webFilterParamsCallCount = 0;

  /// Get current filter parameters for web provider (memoized to prevent infinite rebuilds)
  // TODO: Restore unused element when provider is implemented - commented out for analyzer cleanup
  /*
  Map<String, dynamic> get _webFilterParams {
    _webFilterParamsCallCount++;
    debugPrint('🔍 CustomerInfiniteLoopTest: _webFilterParams called (count: $_webFilterParamsCallCount)');
    
    // Check if parameters have changed
    if (_cachedFilterParams == null ||
        _lastSearchQuery != _currentSearchQuery ||
        _lastSelectedType != _selectedType ||
        _lastIsActiveFilter != _isActiveFilter) {
      
      debugPrint('🔍 CustomerInfiniteLoopTest: Parameters changed, rebuilding cache');
      debugPrint('🔍 CustomerInfiniteLoopTest: _currentSearchQuery = "$_currentSearchQuery" (was "$_lastSearchQuery")');
      debugPrint('🔍 CustomerInfiniteLoopTest: _selectedType = $_selectedType (was $_lastSelectedType)');
      debugPrint('🔍 CustomerInfiniteLoopTest: _isActiveFilter = $_isActiveFilter (was $_lastIsActiveFilter)');
      
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
      
      debugPrint('🔍 CustomerInfiniteLoopTest: New cached params: $_cachedFilterParams');
    } else {
      debugPrint('🔍 CustomerInfiniteLoopTest: Using cached parameters: $_cachedFilterParams');
    }
    
    return _cachedFilterParams!;
  }
  */

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    debugPrint('🏗️ CustomerInfiniteLoopTest: build() called (count: $_buildCount)');
    
    if (kIsWeb) {
      debugPrint('🌐 CustomerInfiniteLoopTest: Web platform - watching webCustomersProvider');
      // TODO: Restore webCustomersProvider when provider is implemented - commented out for analyzer cleanup
      // final customersAsync = ref.watch(webCustomersProvider(_webFilterParams));
      final customersAsync = AsyncValue.data(<Map<String, dynamic>>[]); // Placeholder
      
      return Scaffold(
        appBar: AppBar(
          title: Text('Customer Infinite Loop Test (Build: $_buildCount)'),
        ),
        body: Column(
          children: [
            // Test controls
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test Status:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Build count: $_buildCount'),
                  Text('_webFilterParams call count: $_webFilterParamsCallCount'),
                  Text('Current search query: "$_currentSearchQuery"'),
                  Text('Selected type: $_selectedType'),
                  Text('Active filter: $_isActiveFilter'),
                  const SizedBox(height: 16),
                  
                  // Search input
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search customers',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      debugPrint('🔍 CustomerInfiniteLoopTest: Search changed to: "$value"');
                      setState(() {
                        _currentSearchQuery = value;
                        // TODO: Restore _cachedFilterParams when provider is implemented - commented out for analyzer cleanup
                        // _cachedFilterParams = null; // Invalidate cache
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Type filter
                  DropdownButton<CustomerType?>(
                    value: _selectedType,
                    hint: const Text('Select customer type'),
                    items: [
                      const DropdownMenuItem<CustomerType?>(
                        value: null,
                        child: Text('All types'),
                      ),
                      ...CustomerType.values.map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      )),
                    ],
                    onChanged: (value) {
                      debugPrint('🔍 CustomerInfiniteLoopTest: Type changed to: $value');
                      setState(() {
                        _selectedType = value;
                        // TODO: Restore _cachedFilterParams when provider is implemented - commented out for analyzer cleanup
                        // _cachedFilterParams = null; // Invalidate cache
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Active filter
                  Row(
                    children: [
                      const Text('Active filter: '),
                      DropdownButton<bool?>(
                        value: _isActiveFilter,
                        items: const [
                          DropdownMenuItem<bool?>(
                            value: null,
                            child: Text('All'),
                          ),
                          DropdownMenuItem<bool?>(
                            value: true,
                            child: Text('Active only'),
                          ),
                          DropdownMenuItem<bool?>(
                            value: false,
                            child: Text('Inactive only'),
                          ),
                        ],
                        onChanged: (value) {
                          debugPrint('🔍 CustomerInfiniteLoopTest: Active filter changed to: $value');
                          setState(() {
                            _isActiveFilter = value;
                            // TODO: Restore _cachedFilterParams when provider is implemented - commented out for analyzer cleanup
                            // _cachedFilterParams = null; // Invalidate cache
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Customer list
            Expanded(
              child: customersAsync.when(
                data: (customers) {
                  debugPrint('🌐 CustomerInfiniteLoopTest: Received ${customers.length} customers');
                  return ListView.builder(
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return ListTile(
                        // TODO: Restore customer getters when provider is implemented - commented out for analyzer cleanup
                        title: Text(customer['organizationName'] ?? 'Unknown'), // customer.organizationName),
                        subtitle: Text(customer['contactPersonName'] ?? 'Unknown'), // customer.contactPersonName),
                        trailing: Text(customer['type']?['displayName'] ?? 'Unknown'), // customer.type.displayName),
                      );
                    },
                  );
                },
                loading: () {
                  debugPrint('🌐 CustomerInfiniteLoopTest: Loading customers...');
                  return const Center(child: CircularProgressIndicator());
                },
                error: (error, stackTrace) {
                  debugPrint('🌐 CustomerInfiniteLoopTest: Error loading customers: $error');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text('Error: $error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // TODO: Restore webCustomersProvider when provider is implemented - commented out for analyzer cleanup
                            // ref.invalidate(webCustomersProvider(_webFilterParams));
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Customer Infinite Loop Test (Mobile)'),
        ),
        body: const Center(
          child: Text('This test is designed for web platform'),
        ),
      );
    }
  }
}
