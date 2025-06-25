import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/orders/data/models/order.dart';
import '../../features/payments/presentation/screens/payment_screen.dart';
import '../../core/constants/app_constants.dart';

class PaymentTestScreen extends ConsumerStatefulWidget {
  const PaymentTestScreen({super.key});

  @override
  ConsumerState<PaymentTestScreen> createState() => _PaymentTestScreenState();
}

class _PaymentTestScreenState extends ConsumerState<PaymentTestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Integration Test'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildTestScenarios(),
            const SizedBox(height: 24),
            _buildTestCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: AppConstants.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Stripe Payment Testing',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Test the newly integrated Stripe payment system with various scenarios.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Stripe SDK initialized and payment functions deployed',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestScenarios() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Test Scenarios',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildTestScenarioCard(
          'Successful Payment',
          'Test successful credit card payment flow',
          'Card: 4242 4242 4242 4242',
          Colors.green,
          () => _navigateToPayment('success'),
        ),
        const SizedBox(height: 8),
        _buildTestScenarioCard(
          'Declined Payment',
          'Test payment decline handling',
          'Card: 4000 0000 0000 0002',
          Colors.red,
          () => _navigateToPayment('declined'),
        ),
        const SizedBox(height: 8),
        _buildTestScenarioCard(
          '3D Secure Payment',
          'Test 3D Secure authentication flow',
          'Card: 4000 0025 0000 3155',
          Colors.orange,
          () => _navigateToPayment('3ds'),
        ),
        const SizedBox(height: 8),
        _buildTestScenarioCard(
          'Insufficient Funds',
          'Test insufficient funds scenario',
          'Card: 4000 0000 0000 9995',
          Colors.purple,
          () => _navigateToPayment('insufficient'),
        ),
      ],
    );
  }

  Widget _buildTestScenarioCard(
    String title,
    String description,
    String testCard,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      testCard,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Test Card Numbers',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Use these test cards in the payment screen:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              _buildTestCardRow('Success', '4242 4242 4242 4242', Colors.green),
              _buildTestCardRow('Declined', '4000 0000 0000 0002', Colors.red),
              _buildTestCardRow('3D Secure', '4000 0025 0000 3155', Colors.orange),
              _buildTestCardRow('Insufficient', '4000 0000 0000 9995', Colors.purple),
              const SizedBox(height: 12),
              const Text(
                'Expiry: Any future date (e.g., 12/25)\nCVC: Any 3 digits (e.g., 123)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestCardRow(String label, String cardNumber, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
          Text(
            cardNumber,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPayment(String scenario) {
    // Create a mock order for testing
    final mockOrder = Order(
      id: 'test-order-$scenario',
      orderNumber: 'TEST-${scenario.toUpperCase()}-001',
      status: OrderStatus.pending,
      items: [],
      vendorId: 'test-vendor',
      vendorName: 'Test Vendor Restaurant',
      customerId: 'test-customer',
      customerName: 'Test Customer',
      deliveryDate: DateTime.now().add(const Duration(days: 1)),
      deliveryAddress: const Address(
        street: '123 Test Street',
        city: 'Kuala Lumpur',
        state: 'Selangor',
        postalCode: '50000',
        country: 'Malaysia',
      ),
      subtotal: 25.00,
      deliveryFee: 5.00,
      sstAmount: 1.50,
      totalAmount: 31.50,
      commissionAmount: 1.75,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Navigate to payment screen with the mock order
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentScreen(order: mockOrder),
      ),
    );
  }
}
