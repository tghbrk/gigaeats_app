import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/delivery_method.dart';
import '../../data/models/delivery_fee_calculation.dart';
import '../../data/services/delivery_fee_service.dart';
import '../widgets/enhanced_delivery_method_selector.dart';
import '../../../../design_system/widgets/buttons/ge_button.dart';

/// Test screen for delivery fee calculation functionality
class DeliveryFeeTestScreen extends ConsumerStatefulWidget {
  const DeliveryFeeTestScreen({super.key});

  @override
  ConsumerState<DeliveryFeeTestScreen> createState() => _DeliveryFeeTestScreenState();
}

class _DeliveryFeeTestScreenState extends ConsumerState<DeliveryFeeTestScreen> {
  final _subtotalController = TextEditingController(text: '150.00');
  final _latitudeController = TextEditingController(text: '3.1390');
  final _longitudeController = TextEditingController(text: '101.6869');
  
  DeliveryMethod _selectedMethod = DeliveryMethod.ownFleet;
  DeliveryFeeCalculation? _calculation;
  bool _isCalculating = false;
  String? _error;

  // Test vendor ID (you can replace with actual vendor ID)
  final String _testVendorId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

  @override
  void dispose() {
    _subtotalController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _calculateDeliveryFee() async {
    setState(() {
      _isCalculating = true;
      _error = null;
    });

    try {
      final deliveryFeeService = DeliveryFeeService();
      final subtotal = double.tryParse(_subtotalController.text) ?? 0.0;
      final latitude = double.tryParse(_latitudeController.text);
      final longitude = double.tryParse(_longitudeController.text);

      final calculation = await deliveryFeeService.calculateDeliveryFee(
        deliveryMethod: _selectedMethod,
        vendorId: _testVendorId,
        subtotal: subtotal,
        deliveryLatitude: latitude,
        deliveryLongitude: longitude,
      );

      setState(() {
        _calculation = calculation;
        _isCalculating = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isCalculating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Fee Test'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test Parameters Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Parameters',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Subtotal input
                    TextFormField(
                      controller: _subtotalController,
                      decoration: const InputDecoration(
                        labelText: 'Subtotal (RM)',
                        border: OutlineInputBorder(),
                        prefixText: 'RM ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Latitude input
                    TextFormField(
                      controller: _latitudeController,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Latitude',
                        border: OutlineInputBorder(),
                        hintText: '3.1390 (KL Central)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Longitude input
                    TextFormField(
                      controller: _longitudeController,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Longitude',
                        border: OutlineInputBorder(),
                        hintText: '101.6869 (KL Central)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Delivery Method Selector
            EnhancedDeliveryMethodSelector(
              selectedMethod: _selectedMethod,
              onMethodSelected: (method) {
                setState(() {
                  _selectedMethod = method;
                });
              },
              subtotal: double.tryParse(_subtotalController.text) ?? 0.0,
              vendorId: _testVendorId,
              deliveryLatitude: double.tryParse(_latitudeController.text),
              deliveryLongitude: double.tryParse(_longitudeController.text),
            ),
            
            const SizedBox(height: 16),
            
            // Calculate Button
            SizedBox(
              width: double.infinity,
              child: GEButton.primary(
                text: 'Calculate Delivery Fee',
                onPressed: _isCalculating ? null : _calculateDeliveryFee,
                isLoading: _isCalculating,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Results Card
            if (_calculation != null || _error != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calculation Result',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Error: $_error',
                                  style: TextStyle(
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_calculation != null) ...[
                        // Final Fee
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Final Delivery Fee',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              Text(
                                _calculation!.formattedFee,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Breakdown
                        Text(
                          'Fee Breakdown',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        ..._calculation!.displayBreakdown.entries.map((entry) => 
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Text(
                                  entry.value,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Technical Details
                        ExpansionTile(
                          title: const Text('Technical Details'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailRow('Base Fee', 'RM${_calculation!.baseFee.toStringAsFixed(2)}'),
                                  _buildDetailRow('Distance Fee', 'RM${_calculation!.distanceFee.toStringAsFixed(2)}'),
                                  _buildDetailRow('Distance', '${_calculation!.distanceKm.toStringAsFixed(1)} km'),
                                  _buildDetailRow('Surge Multiplier', '${_calculation!.surgeMultiplier.toStringAsFixed(2)}x'),
                                  _buildDetailRow('Discount', 'RM${_calculation!.discountAmount.toStringAsFixed(2)}'),
                                  if (_calculation!.configId != null)
                                    _buildDetailRow('Config ID', _calculation!.configId!),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
