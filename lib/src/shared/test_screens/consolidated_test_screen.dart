import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/customers/data/models/customer.dart';
// TODO: Restore unused import - commented out for analyzer cleanup
// import '../../features/sales_agent/presentation/providers/cart_provider.dart';
import 'test_cart_helper.dart';
import 'delivery_proof_test_screen.dart';

class ConsolidatedTestScreen extends ConsumerStatefulWidget {
  const ConsolidatedTestScreen({super.key});

  @override
  ConsumerState<ConsolidatedTestScreen> createState() => _ConsolidatedTestScreenState();
}

class _ConsolidatedTestScreenState extends ConsumerState<ConsolidatedTestScreen> {
  final List<String> _logs = [];

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  void _testCustomerParsing() {
    debugPrint('🧪 Testing Customer.fromJson with sample database data...');
    _addLog('🧪 Testing Customer.fromJson with sample database data...');

    // Sample data from the actual database
    final sampleCustomerData = {
      'id': '550e8400-e29b-41d4-a716-446655440301',
      'sales_agent_id': '550e8400-e29b-41d4-a716-446655440001',
      'organization_name': 'Tech Solutions Sdn Bhd',
      'contact_person_name': 'Ahmad Rahman',
      'email': 'ahmad@techsolutions.com',
      'phone_number': '+60123456793',
      'alternate_phone_number': null,
      'address': {
        'city': 'Kuala Lumpur',
        'state': 'Kuala Lumpur',
        'street': '789 Jalan Tech',
        'country': 'Malaysia',
        'postal_code': '50000'
      },
      'customer_type': 'corporate',
      'business_info': {},
      'preferences': {},
      'total_spent': '1250.00',
      'total_orders': 8,
      'average_order_value': '0.00',
      'last_order_date': null,
      'is_active': true,
      'is_verified': true,
      'notes': null,
      'tags': [],
      'created_at': '2025-05-28 08:19:47.351839+00',
      'updated_at': '2025-05-28 08:19:47.351839+00'
    };

    try {
      debugPrint('🔄 Attempting to parse customer data...');
      _addLog('🔄 Attempting to parse customer data...');
      final customer = Customer.fromJson(sampleCustomerData);
      debugPrint('✅ Customer parsing successful!');
      _addLog('✅ Customer parsing successful!');
      _addLog('   ID: ${customer.id}');
      _addLog('   Organization: ${customer.organizationName}');
      _addLog('   Contact: ${customer.contactPersonName}');
      _addLog('   Email: ${customer.email}');
      _addLog('   Address: ${customer.address.fullAddress}');
      _addLog('   Type: ${customer.type}');

      // Show success message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Customer parsing test successful! Check logs for details.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Customer parsing failed: $e');
      debugPrint('   Stack trace: $stackTrace');
      _addLog('❌ Customer parsing failed: $e');
      _addLog('   Stack trace: $stackTrace');

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Customer parsing test failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // TODO: Restore undefined identifier - commented out for analyzer cleanup
    // final cartState = ref.watch(cartProvider);
    final cartState = <String, dynamic>{}; // Placeholder

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Tools & Testing'),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearLogs,
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'GigaEats Testing Suite',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Consolidated testing tools for development and debugging',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),

            // Cart Testing Section
            _buildTestSection(
              title: '🛒 Cart Testing',
              children: [
                _buildTestCard(
                  title: 'Add Test Items to Cart',
                  description: 'Adds sample Malaysian food items to cart for testing',
                  buttonText: 'Add Test Cart',
                  onPressed: () {
                    TestCartHelper.addTestItemsToCart(ref);
                    _addLog('🛒 Test items added to cart');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Test items added to cart!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icons.add_shopping_cart,
                  color: Colors.blue,
                ),
                _buildTestCard(
                  title: 'Clear Cart',
                  description: 'Removes all items from the current cart',
                  buttonText: 'Clear Cart',
                  onPressed: () {
                    TestCartHelper.clearCart(ref);
                    _addLog('🗑️ Cart cleared');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cart cleared!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icons.clear,
                  color: Colors.red,
                ),
                _buildInfoCard(
                  'Current Cart Status',
                  cartState.isEmpty
                    ? 'Cart is empty'
                    // TODO: Restore undefined getters - commented out for analyzer cleanup
                    // : 'Cart has ${cartState.totalItems} items (RM ${cartState.totalAmount.toStringAsFixed(2)})',
                    : 'Cart has ${cartState['totalItems'] ?? 0} items (RM ${(cartState['totalAmount'] ?? 0.0).toStringAsFixed(2)})',
                  cartState.isEmpty ? Colors.grey : Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Order Testing Section
            _buildTestSection(
              title: '📋 Order Testing',
              children: [
                _buildTestCard(
                  title: 'Order Creation Test',
                  description: 'Comprehensive order creation testing with multiple scenarios',
                  buttonText: 'Open Order Test',
                  onPressed: () {
                    context.push('/test-order-creation');
                  },
                  icon: Icons.science,
                  color: Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Customer Testing Section
            _buildTestSection(
              title: '👥 Customer Testing',
              children: [
                _buildTestCard(
                  title: 'Customer Data Parsing',
                  description: 'Tests Customer.fromJson with real database sample data',
                  buttonText: 'Test Parsing',
                  onPressed: _testCustomerParsing,
                  icon: Icons.person_search,
                  color: Colors.purple,
                ),
                _buildTestCard(
                  title: 'Customer Selector Test',
                  description: 'Tests customer selection UI components and functionality',
                  buttonText: 'Open Selector Test',
                  onPressed: () {
                    context.push('/test-customer-selector');
                  },
                  icon: Icons.loop,
                  color: Colors.orange,
                ),
                _buildTestCard(
                  title: 'Customer Infinite Loop Test',
                  description: 'Tests for infinite loops in customer data loading',
                  buttonText: 'Open Loop Test',
                  onPressed: () {
                    context.push('/test-customer-infinite-loop');
                  },
                  icon: Icons.refresh,
                  color: Colors.teal,
                ),
                _buildTestCard(
                  title: 'Customer Selection Text Color Fix',
                  description: 'Tests customer selection cards with proper text contrast and color',
                  buttonText: 'Test Text Colors',
                  onPressed: () {
                    context.push('/test-customer-selection');
                  },
                  icon: Icons.color_lens,
                  color: Colors.deepPurple,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Delivery Testing Section
            _buildTestSection(
              title: '🚚 Delivery Testing',
              children: [
                _buildTestCard(
                  title: 'Delivery Proof Test',
                  description: 'Test complete delivery proof workflow with camera, GPS, and backend storage',
                  buttonText: 'Open Delivery Test',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DeliveryProofTestScreen(),
                      ),
                    );
                  },
                  icon: Icons.camera_alt,
                  color: Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Data & Integration Testing Section
            _buildTestSection(
              title: '🔧 Data & Integration Testing',
              children: [
                _buildTestCard(
                  title: 'Data Integration Test',
                  description: 'Comprehensive data fetching and integration testing',
                  buttonText: 'Open Data Test',
                  onPressed: () {
                    context.push('/test-data');
                  },
                  icon: Icons.storage,
                  color: Colors.indigo,
                ),
                _buildTestCard(
                  title: 'Test Menu',
                  description: 'General testing menu with various utilities',
                  buttonText: 'Open Test Menu',
                  onPressed: () {
                    context.push('/test-menu');
                  },
                  icon: Icons.menu,
                  color: Colors.brown,
                ),
                _buildTestCard(
                  title: 'Enhanced Features Test',
                  description: 'Test enhanced order management, payments, commission tracking, and menu versioning',
                  buttonText: 'Open Enhanced Test',
                  onPressed: () {
                    context.push('/test-enhanced-features');
                  },
                  icon: Icons.auto_awesome,
                  color: Colors.indigo,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Logs Section
            if (_logs.isNotEmpty) ...[
              Text(
                '📝 Test Logs',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _logs.join('\n'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection({
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildTestCard({
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String info, Color color) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: color,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    info,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}