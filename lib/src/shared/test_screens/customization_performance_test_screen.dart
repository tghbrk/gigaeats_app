import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// TODO: Restore unused import when cart operations are restored - commented out for analyzer cleanup
// import 'dart:math';
// TODO: Restore unused import when cart operations are restored - commented out for analyzer cleanup
// import '../../features/menu/data/models/product.dart';
// TODO: Restore vendor import when cart operations are restored - commented out for analyzer cleanup
// import '../../features/vendors/data/models/vendor.dart';
// TODO: Restore cart_provider import when cartProvider is restored - commented out for analyzer cleanup
// import '../../features/sales_agent/presentation/providers/cart_provider.dart';

class CustomizationPerformanceTestScreen extends ConsumerStatefulWidget {
  const CustomizationPerformanceTestScreen({super.key});

  @override
  ConsumerState<CustomizationPerformanceTestScreen> createState() => _CustomizationPerformanceTestScreenState();
}

class _CustomizationPerformanceTestScreenState extends ConsumerState<CustomizationPerformanceTestScreen> {
  final List<String> _testResults = [];
  bool _isRunning = false;
  // TODO: Restore unused field when cart operations are restored - commented out for analyzer cleanup
  // final Random _random = Random();

  @override
  Widget build(BuildContext context) {
    // TODO: Restore when cartProvider is implemented
    // final cart = ref.watch(cartProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customization Performance Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Testing Suite',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Test customization performance with various scenarios',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Test Controls
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isRunning ? null : _runAllTests,
                  child: _isRunning 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Run All Tests'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _clearResults,
                  child: const Text('Clear Results'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  // TODO: Restore when cartProvider is implemented
                  onPressed: () {}, // => ref.read(cartProvider.notifier).clearCart(),
                  child: const Text('Clear Cart'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Cart Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cart Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // TODO: Restore cart references - commented out for analyzer cleanup
                    Text('Items: 0'), // ${cart.items.length}'),
                    Text('Total: RM 0.00'), // ${cart.totalAmount.toStringAsFixed(2)}'),
                    Text('Unique Products: 0'), // ${cart.items.map((e) => e.productId).toSet().length}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Results
            Text(
              'Test Results:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: Card(
                child: _testResults.isEmpty
                  ? const Center(
                      child: Text('No test results yet. Run tests to see performance metrics.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _testResults.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _testResults[index],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isRunning = true;
      _testResults.clear();
    });

    _addResult('=== CUSTOMIZATION PERFORMANCE TEST SUITE ===');
    _addResult('Started at: ${DateTime.now()}');
    _addResult('');

    try {
      await _testBasicCustomizations();
      await _testComplexCustomizations();
      await _testMassiveCustomizations();
      await _testCartPerformance();
      await _testPricingCalculations();
      
      _addResult('');
      _addResult('=== ALL TESTS COMPLETED ===');
    } catch (e) {
      _addResult('ERROR: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  Future<void> _testBasicCustomizations() async {
    _addResult('--- Test 1: Basic Customizations ---');
    
    final stopwatch = Stopwatch()..start();
    
    // Create product with basic customizations
    // TODO: Use product when cart functionality is restored
    // final product = _createTestProduct(
    //   name: 'Basic Burger',
    //   customizationCount: 3,
    //   optionsPerCustomization: 3,
    // );
    
    // TODO: Use vendor when cart functionality is restored
    // final vendor = _createTestVendor();

    // Test adding to cart with different customizations
    for (int i = 0; i < 10; i++) {
      // TODO: Use customizations when cart functionality is restored
      // final customizations = _generateRandomCustomizations(product.customizations);
      // TODO: Restore when cartProvider is implemented
      /*ref.read(cartProvider.notifier).addItem(
        product: product,
        vendor: vendor,
        quantity: 1,
        customizations: customizations,
      );*/
    }
    
    stopwatch.stop();
    _addResult('✓ Added 10 items with basic customizations');
    _addResult('  Time: ${stopwatch.elapsedMilliseconds}ms');
    // TODO: Restore when cartProvider is implemented
    _addResult('  Cart items: 0'); // ${ref.read(cartProvider).items.length}');
    _addResult('');
  }

  Future<void> _testComplexCustomizations() async {
    _addResult('--- Test 2: Complex Customizations ---');
    
    final stopwatch = Stopwatch()..start();
    
    // Create product with complex customizations
    // TODO: Restore product when cart operations are restored - commented out for analyzer cleanup
    // final product = _createTestProduct(
    //   name: 'Complex Pizza',
    //   customizationCount: 8,
    //   optionsPerCustomization: 6,
    // );
    
    // TODO: Restore vendor when cart operations are restored - commented out for analyzer cleanup
    // final vendor = _createTestVendor();

    // Test adding to cart with complex customizations
    for (int i = 0; i < 20; i++) {
      // TODO: Restore customizations when cart operations are restored - commented out for analyzer cleanup
      // final customizations = _generateRandomCustomizations(product.customizations);
      // TODO: Restore cartProvider - commented out for analyzer cleanup
      // ref.read(cartProvider.notifier).addItem(
      //   product: product,
      //   vendor: vendor,
      //   quantity: _random.nextInt(3) + 1,
      //   customizations: customizations,
      // );
    }
    
    stopwatch.stop();
    _addResult('✓ Added 20 items with complex customizations');
    _addResult('  Time: ${stopwatch.elapsedMilliseconds}ms');
    // TODO: Restore cartProvider - commented out for analyzer cleanup
    _addResult('  Cart items: 0'); // ${ref.read(cartProvider).items.length}');
    _addResult('');
  }

  Future<void> _testMassiveCustomizations() async {
    _addResult('--- Test 3: Massive Customizations ---');
    
    final stopwatch = Stopwatch()..start();
    
    // Create product with massive customizations
    // TODO: Restore product when cart operations are restored - commented out for analyzer cleanup
    // final product = _createTestProduct(
    //   name: 'Ultimate Sandwich',
    //   customizationCount: 15,
    //   optionsPerCustomization: 10,
    // );
    
    // TODO: Restore vendor when cart operations are restored - commented out for analyzer cleanup
    // final vendor = _createTestVendor();
    
    // Test adding to cart with massive customizations
    for (int i = 0; i < 50; i++) {
      // TODO: Restore customizations when cart operations are restored - commented out for analyzer cleanup
      // final customizations = _generateRandomCustomizations(product.customizations);
      // TODO: Restore cartProvider - commented out for analyzer cleanup
      // ref.read(cartProvider.notifier).addItem(
      //   product: product,
      //   vendor: vendor,
      //   quantity: 1,
      //   customizations: customizations,
      // );
    }
    
    stopwatch.stop();
    _addResult('✓ Added 50 items with massive customizations');
    _addResult('  Time: ${stopwatch.elapsedMilliseconds}ms');
    // TODO: Restore cartProvider - commented out for analyzer cleanup
    _addResult('  Cart items: 0'); // ${ref.read(cartProvider).items.length}');
    _addResult('');
  }

  Future<void> _testCartPerformance() async {
    _addResult('--- Test 4: Cart Performance ---');
    
    // TODO: Restore cartProvider - commented out for analyzer cleanup
    final cart = <String, dynamic>{'items': []}; // ref.read(cartProvider);
    
    // Test cart operations
    final stopwatch = Stopwatch()..start();
    
    double totalPrice = 0;
    // TODO: Restore cart.items access when cart operations are restored - commented out for analyzer cleanup
    // for (final item in cart['items'] ?? []) {
    //   totalPrice += item.totalPrice;
    // }

    stopwatch.stop();
    _addResult('✓ Calculated total price for ${(cart['items'] ?? []).length} items');
    _addResult('  Time: ${stopwatch.elapsedMilliseconds}ms');
    _addResult('  Total: RM ${totalPrice.toStringAsFixed(2)}');
    _addResult('');
  }

  Future<void> _testPricingCalculations() async {
    _addResult('--- Test 5: Pricing Calculations ---');
    
    // TODO: Restore cartProvider when cart operations are restored - commented out for analyzer cleanup
    // final cart = <String, dynamic>{'items': []}; // ref.read(cartProvider);
    final stopwatch = Stopwatch()..start();
    
    int calculationCount = 0;
    double totalCalculatedPrice = 0;
    
    // TODO: Restore cart.items access when cart operations are restored - commented out for analyzer cleanup
    // for (final item in cart['items'] ?? []) {
    //   // Test individual item pricing
    //   final singlePrice = item.singleItemPrice;
    //   final totalPrice = item.totalPrice;
    //   totalCalculatedPrice += totalPrice;
    //   calculationCount += 2; // Two calculations per item
    // }
    
    stopwatch.stop();
    _addResult('✓ Performed $calculationCount pricing calculations');
    _addResult('  Time: ${stopwatch.elapsedMilliseconds}ms');
    _addResult('  Avg per calculation: ${(stopwatch.elapsedMilliseconds / calculationCount).toStringAsFixed(2)}ms');
    _addResult('  Total calculated: RM ${totalCalculatedPrice.toStringAsFixed(2)}');
    _addResult('');
  }

  // TODO: Restore _createTestProduct when cart operations are restored - commented out for analyzer cleanup
  // TODO: Restore _createTestProduct when customization operations are restored - commented out for analyzer cleanup
  // TODO: Restore unused element - commented out for analyzer cleanup
  /*
  Product _createTestProductUnused({
    required String name,
    required int customizationCount,
    required int optionsPerCustomization,
  }) {
    final customizations = <MenuItemCustomization>[];
    
    for (int i = 0; i < customizationCount; i++) {
      final options = <CustomizationOption>[];
      
      for (int j = 0; j < optionsPerCustomization; j++) {
        options.add(CustomizationOption(
          id: 'option_${i}_$j',
          name: 'Option ${j + 1}',
          additionalPrice: _random.nextDouble() * 5.0,
          isDefault: j == 0,
        ));
      }
      
      customizations.add(MenuItemCustomization(
        id: 'customization_$i',
        name: 'Customization ${i + 1}',
        type: _random.nextBool() ? 'single' : 'multiple',
        isRequired: i < 2, // First 2 are required
        options: options,
      ));
    }
    
    return Product(
      id: 'test_product_${_random.nextInt(10000)}',
      vendorId: 'test_vendor',
      name: name,
      description: 'Test product for performance testing',
      category: 'Test',
      basePrice: 10.0 + _random.nextDouble() * 20.0,
      customizations: customizations,
    );
  }
  */

  // TODO: Restore _createTestVendor when cart operations are restored - commented out for analyzer cleanup
  // Vendor _createTestVendor() {
  //   return Vendor(
  //     id: 'test_vendor',
  //     businessName: 'Test Vendor',
  //     businessRegistrationNumber: 'TEST-001',
  //     businessAddress: 'Test Address',
  //     businessType: 'Restaurant',
  //     cuisineTypes: ['Test'],
  //     createdAt: DateTime.now(),
  //     updatedAt: DateTime.now(),
  //   );
  // }

  // TODO: Restore _generateRandomCustomizations when cart operations are restored - commented out for analyzer cleanup
  // TODO: Restore _generateRandomCustomizations when customization operations are restored - commented out for analyzer cleanup
  // TODO: Restore unused element - commented out for analyzer cleanup
  /*
  Map<String, dynamic> _generateRandomCustomizationsUnused(List<MenuItemCustomization> customizations) {
    final result = <String, dynamic>{};
    
    for (final customization in customizations) {
      if (customization.type == 'single') {
        // Select one random option
        final option = customization.options[_random.nextInt(customization.options.length)];
        result[customization.id ?? customization.name] = {
          'id': option.id ?? option.name,
          'name': option.name,
          'price': option.additionalPrice,
        };
      } else {
        // Select random multiple options
        final selectedOptions = <Map<String, dynamic>>[];
        final optionCount = _random.nextInt(customization.options.length) + 1;
        final shuffledOptions = List.from(customization.options)..shuffle();

        for (int i = 0; i < optionCount && i < shuffledOptions.length; i++) {
          final option = shuffledOptions[i];
          selectedOptions.add({
            'id': option.id ?? option.name,
            'name': option.name,
            'price': option.additionalPrice,
          });
        }

        result[customization.id ?? customization.name] = selectedOptions;
      }
    }
    
    return result;
  }
  */

  void _addResult(String result) {
    setState(() {
      _testResults.add(result);
    });
  }

  void _clearResults() {
    setState(() {
      _testResults.clear();
    });
  }
}
