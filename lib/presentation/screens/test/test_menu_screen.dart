import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

import '../../providers/repository_providers.dart';
import '../../../data/models/product.dart';

class TestMenuScreen extends ConsumerStatefulWidget {
  const TestMenuScreen({super.key});

  @override
  ConsumerState<TestMenuScreen> createState() => _TestMenuScreenState();
}

class _TestMenuScreenState extends ConsumerState<TestMenuScreen> {
  final List<String> _logs = [];
  bool _isInitialized = false;
  int _buildCount = 0;

  // Create stable parameters to prevent provider recreation
  static const testVendorId = '550e8400-e29b-41d4-a716-446655440101';
  static final _providerParams = {
    'vendorId': testVendorId,
    'isAvailable': true,
    'useStream': !kIsWeb,
  };

  void _addLog(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '$timestamp: $message';

    // Use Flutter's debugging tools
    debugPrint('[TestMenuScreen] $message');
    developer.log(message, name: 'TestMenuScreen', time: DateTime.now());

    // Only add logs after initial build to prevent infinite rebuilds
    if (_isInitialized) {
      setState(() {
        _logs.add(logMessage);
      });
    } else {
      _logs.add(logMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    debugPrint('[TestMenuScreen] *** BUILD #$_buildCount ***');
    developer.log('*** BUILD #$_buildCount ***', name: 'TestMenuScreen', time: DateTime.now(), sequenceNumber: _buildCount);

    // Use platform-aware menu items provider with stable parameters
    final productsAsync = ref.watch(platformMenuItemsProvider(_providerParams));

    // Mark as initialized after first build
    if (!_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _isInitialized = true;
          _logs.add('${DateTime.now().toIso8601String()}: TestMenuScreen: Screen initialized');
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Test Menu Loading ${kIsWeb ? "(Web)" : "(Mobile)"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              debugPrint('[TestMenuScreen] Refreshing menu items...');
              developer.log('Refreshing menu items...', name: 'TestMenuScreen');
              ref.invalidate(platformMenuItemsProvider(_providerParams));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Platform: ${kIsWeb ? "Web" : "Mobile"}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'Vendor ID: $testVendorId',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            // Debug logs section
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('Debug Logs', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _logs.clear();
                            });
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        return Text(
                          _logs[index],
                          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: productsAsync.when(
                data: (products) {
                  // Use post-frame callback to avoid rebuild during build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _addLog('TestMenuScreen: Got ${products.length} menu items');
                  });

                  if (products.isEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _addLog('TestMenuScreen: No products found, showing empty state');
                    });
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No menu items found'),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(product.name),
                          subtitle: Text(
                            'RM ${product.basePrice.toStringAsFixed(2)}\n${product.description}',
                          ),
                          trailing: (product.isAvailable ?? false)
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : const Icon(Icons.cancel, color: Colors.red),
                          isThreeLine: true,
                        ),
                      );
                    },
                  );
                },
                loading: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _addLog('TestMenuScreen: Menu items loading...');
                  });
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading menu items...'),
                      ],
                    ),
                  );
                },
                error: (error, stack) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _addLog('TestMenuScreen: Menu items error: $error');
                  });
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error loading menu: $error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            _addLog('TestMenuScreen: Retrying menu items load...');
                            ref.invalidate(platformMenuItemsProvider(_providerParams));
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
      ),
    );
  }
}
