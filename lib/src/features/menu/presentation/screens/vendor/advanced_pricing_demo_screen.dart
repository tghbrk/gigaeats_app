import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/advanced_pricing.dart' as pricing;
import '../../widgets/advanced_pricing_management.dart';

/// Demo screen showcasing advanced pricing management capabilities
class AdvancedPricingDemoScreen extends ConsumerStatefulWidget {
  const AdvancedPricingDemoScreen({super.key});

  @override
  ConsumerState<AdvancedPricingDemoScreen> createState() => _AdvancedPricingDemoScreenState();
}

class _AdvancedPricingDemoScreenState extends ConsumerState<AdvancedPricingDemoScreen> {
  late pricing.AdvancedPricingConfig _pricingConfig;

  @override
  void initState() {
    super.initState();
    _initializeDemoData();
  }

  void _initializeDemoData() {
    // Create sample advanced pricing configuration
    _pricingConfig = pricing.AdvancedPricingConfig(
      menuItemId: 'demo-item-1',
      basePrice: 15.00,
      bulkPricingTiers: [
        pricing.EnhancedBulkPricingTier(
          id: 'tier-1',
          minimumQuantity: 10,
          maximumQuantity: 24,
          pricePerUnit: 13.50,
          discountPercentage: 10.0,
          description: 'Small bulk discount for 10-24 items',
          isActive: true,
        ),
        pricing.EnhancedBulkPricingTier(
          id: 'tier-2',
          minimumQuantity: 25,
          maximumQuantity: 49,
          pricePerUnit: 12.00,
          discountPercentage: 20.0,
          description: 'Medium bulk discount for 25-49 items',
          isActive: true,
        ),
        pricing.EnhancedBulkPricingTier(
          id: 'tier-3',
          minimumQuantity: 50,
          pricePerUnit: 10.50,
          discountPercentage: 30.0,
          description: 'Large bulk discount for 50+ items',
          isActive: true,
        ),
      ],
      promotionalPricing: [
        pricing.PromotionalPricing(
          id: 'promo-1',
          name: 'Weekend Special',
          description: '15% off on weekends',
          type: pricing.PromotionalPricingType.percentage,
          value: 15.0,
          validFrom: DateTime.now().subtract(const Duration(days: 1)),
          validUntil: DateTime.now().add(const Duration(days: 30)),
          applicableDays: ['saturday', 'sunday'],
          isActive: true,
        ),
        pricing.PromotionalPricing(
          id: 'promo-2',
          name: 'Lunch Rush Deal',
          description: 'RM 3 off during lunch hours',
          type: pricing.PromotionalPricingType.fixedAmount,
          value: 3.0,
          minimumOrderAmount: 20.0,
          validFrom: DateTime.now().subtract(const Duration(days: 7)),
          validUntil: DateTime.now().add(const Duration(days: 60)),
          applicableDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          startTime: const pricing.TimeOfDay(hour: 11, minute: 30),
          endTime: const pricing.TimeOfDay(hour: 14, minute: 30),
          isActive: true,
        ),
        pricing.PromotionalPricing(
          id: 'promo-3',
          name: 'Buy 3 Get 1 Free',
          description: 'Perfect for group orders',
          type: pricing.PromotionalPricingType.buyXGetY,
          value: 3.0, // Buy 3 get 1 free
          minimumQuantity: 4,
          validFrom: DateTime.now().subtract(const Duration(days: 3)),
          validUntil: DateTime.now().add(const Duration(days: 45)),
          isActive: true,
          usageLimit: 100,
          currentUsage: 23,
        ),
      ],
      timeBasedRules: [
        pricing.TimeBasedPricingRule(
          id: 'time-1',
          name: 'Peak Hour Surcharge',
          description: '20% surcharge during peak dinner hours',
          type: pricing.TimePricingType.peakHours,
          multiplier: 1.2,
          applicableDays: ['friday', 'saturday', 'sunday'],
          startTime: const pricing.TimeOfDay(hour: 18, minute: 0),
          endTime: const pricing.TimeOfDay(hour: 21, minute: 0),
          isActive: true,
          priority: 1,
        ),
        pricing.TimeBasedPricingRule(
          id: 'time-2',
          name: 'Happy Hour Discount',
          description: '10% discount during off-peak hours',
          type: pricing.TimePricingType.happyHour,
          multiplier: 0.9,
          applicableDays: ['monday', 'tuesday', 'wednesday', 'thursday'],
          startTime: const pricing.TimeOfDay(hour: 15, minute: 0),
          endTime: const pricing.TimeOfDay(hour: 17, minute: 0),
          isActive: true,
          priority: 0,
        ),
      ],
      enableDynamicPricing: true,
      minimumPrice: 8.0,
      maximumPrice: 25.0,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Advanced Pricing Management'),
            Text(
              'Demo: Nasi Lemak Special Set',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showPricingAnalytics,
            icon: const Icon(Icons.analytics),
            tooltip: 'View pricing analytics',
          ),
          IconButton(
            onPressed: _exportPricingConfig,
            icon: const Icon(Icons.download),
            tooltip: 'Export configuration',
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick stats header
          _buildQuickStatsHeader(),
          
          // Main pricing management interface
          Expanded(
            child: AdvancedPricingManagement(
              pricingConfig: _pricingConfig,
              onPricingConfigChanged: (config) {
                setState(() {
                  _pricingConfig = config;
                });
              },
              showVisualCalculator: true,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildQuickStatsHeader() {
    final stats = _calculatePricingStats();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Base Price',
              'RM ${_pricingConfig.basePrice.toStringAsFixed(2)}',
              Icons.attach_money,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Bulk Tiers',
              '${_pricingConfig.bulkPricingTiers.length}',
              Icons.layers,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Active Promos',
              '${stats.activePromotions}',
              Icons.local_offer,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Max Savings',
              '${stats.maxSavingsPercentage.toStringAsFixed(1)}%',
              Icons.trending_down,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _previewCustomerView,
              icon: const Icon(Icons.preview),
              label: const Text('Preview Customer View'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _testPricingScenarios,
              icon: const Icon(Icons.science),
              label: const Text('Test Scenarios'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _savePricingConfiguration,
              icon: const Icon(Icons.save),
              label: const Text('Save Configuration'),
            ),
          ),
        ],
      ),
    );
  }

  PricingStats _calculatePricingStats() {
    final activePromotions = _pricingConfig.promotionalPricing
        .where((promo) => promo.isCurrentlyValid)
        .length;

    // Calculate maximum possible savings
    double maxSavings = 0.0;
    
    // Check bulk pricing savings
    if (_pricingConfig.bulkPricingTiers.isNotEmpty) {
      final bestBulkTier = _pricingConfig.bulkPricingTiers
          .where((tier) => tier.isCurrentlyValid)
          .fold<pricing.EnhancedBulkPricingTier?>(null, (best, tier) {
            if (best == null || (tier.discountPercentage ?? 0) > (best.discountPercentage ?? 0)) {
              return tier;
            }
            return best;
          });
      
      if (bestBulkTier?.discountPercentage != null) {
        maxSavings = bestBulkTier!.discountPercentage!;
      }
    }

    // Check promotional savings
    for (final promo in _pricingConfig.promotionalPricing) {
      if (promo.isCurrentlyValid && promo.type == pricing.PromotionalPricingType.percentage) {
        if (promo.value > maxSavings) {
          maxSavings = promo.value;
        }
      }
    }

    return PricingStats(
      activePromotions: activePromotions,
      maxSavingsPercentage: maxSavings,
    );
  }

  void _showPricingAnalytics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pricing Analytics'),
        content: const Text('Detailed pricing analytics and performance metrics would be displayed here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _exportPricingConfig() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pricing configuration exported successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _previewCustomerView() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer View Preview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildCustomerPricingPreview(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerPricingPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Menu item card as customer would see it
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.restaurant, size: 40),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nasi Lemak Special Set',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Traditional Malaysian coconut rice with sambal, anchovies, peanuts, and egg',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'RM ${_pricingConfig.basePrice.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_pricingConfig.bulkPricingTiers.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Bulk discounts available',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Active promotions display
                if (_pricingConfig.promotionalPricing.any((p) => p.isCurrentlyValid)) ...[
                  const Divider(),
                  Text(
                    'Active Promotions',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._pricingConfig.promotionalPricing
                      .where((p) => p.isCurrentlyValid)
                      .map((promo) => Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.local_offer, size: 16, color: Colors.orange[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                promo.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _testPricingScenarios() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Pricing Scenarios'),
        content: const Text('Interactive pricing scenario testing would be available here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _savePricingConfiguration() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Advanced pricing configuration saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

/// Helper class for pricing statistics
class PricingStats {
  final int activePromotions;
  final double maxSavingsPercentage;

  const PricingStats({
    required this.activePromotions,
    required this.maxSavingsPercentage,
  });
}
