import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/advanced_pricing.dart';

/// Advanced pricing management widget with promotional, time-based, and dynamic pricing
class AdvancedPricingManagement extends ConsumerStatefulWidget {
  final AdvancedPricingConfig pricingConfig;
  final Function(AdvancedPricingConfig) onPricingConfigChanged;
  final bool showVisualCalculator;

  const AdvancedPricingManagement({
    super.key,
    required this.pricingConfig,
    required this.onPricingConfigChanged,
    this.showVisualCalculator = true,
  });

  @override
  ConsumerState<AdvancedPricingManagement> createState() => _AdvancedPricingManagementState();
}

class _AdvancedPricingManagementState extends ConsumerState<AdvancedPricingManagement>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late AdvancedPricingConfig _pricingConfig;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _pricingConfig = widget.pricingConfig;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AdvancedPricingManagement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pricingConfig != widget.pricingConfig) {
      _pricingConfig = widget.pricingConfig;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        if (widget.showVisualCalculator) ...[
          _buildPricingCalculator(),
          const SizedBox(height: 16),
        ],
        _buildTabBar(),
        const SizedBox(height: 16),
        Expanded(
          child: _buildTabContent(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Advanced Pricing Management',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Configure bulk pricing, promotions, and time-based rules',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        _buildQuickActions(),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _previewPricing,
          icon: const Icon(Icons.preview),
          tooltip: 'Preview pricing',
        ),
        IconButton(
          onPressed: _resetToDefaults,
          icon: const Icon(Icons.refresh),
          tooltip: 'Reset to defaults',
        ),
      ],
    );
  }

  Widget _buildPricingCalculator() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calculate_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Live Pricing Calculator',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCalculatorControls(),
            const SizedBox(height: 16),
            _buildCalculatorResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorControls() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: 'Quantity',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              setState(() {
                // Trigger calculator update
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: 'Order Time',
              border: OutlineInputBorder(),
              isDense: true,
              suffixIcon: Icon(Icons.access_time),
            ),
            readOnly: true,
            onTap: _selectOrderTime,
          ),
        ),
      ],
    );
  }

  Widget _buildCalculatorResults() {
    // Sample calculation for demonstration
    final result = _pricingConfig.calculateEffectivePrice(quantity: 10);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildResultRow('Base Price', 'RM ${result.basePrice.toStringAsFixed(2)}'),
          _buildResultRow('Effective Price', 'RM ${result.effectivePrice.toStringAsFixed(2)}'),
          _buildResultRow('Total Price', 'RM ${result.totalPrice.toStringAsFixed(2)}'),
          if (result.totalDiscount > 0)
            _buildResultRow('Total Discount', '-RM ${result.totalDiscount.toStringAsFixed(2)}', isDiscount: true),
          if (result.totalSavings > 0)
            _buildResultRow('Total Savings', 'RM ${result.totalSavings.toStringAsFixed(2)} (${result.savingsPercentage.toStringAsFixed(1)}%)', isDiscount: true),
          if (result.appliedRules.isNotEmpty) ...[
            const Divider(),
            ...result.appliedRules.map((rule) => 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rule,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDiscount ? Colors.green[600] : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(icon: Icon(Icons.layers), text: 'Bulk Pricing'),
        Tab(icon: Icon(Icons.local_offer), text: 'Promotions'),
        Tab(icon: Icon(Icons.schedule), text: 'Time-Based'),
        Tab(icon: Icon(Icons.tune), text: 'Settings'),
      ],
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildBulkPricingTab(),
        _buildPromotionalPricingTab(),
        _buildTimeBasedPricingTab(),
        _buildSettingsTab(),
      ],
    );
  }

  Widget _buildBulkPricingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bulk Pricing Tiers',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addBulkPricingTier,
                icon: const Icon(Icons.add),
                label: const Text('Add Tier'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_pricingConfig.bulkPricingTiers.isEmpty)
            _buildEmptyBulkPricingState()
          else
            ..._pricingConfig.bulkPricingTiers.asMap().entries.map((entry) {
              final index = entry.key;
              final tier = entry.value;
              return _buildBulkPricingTierCard(tier, index);
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyBulkPricingState() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        child: Column(
          children: [
            Icon(Icons.layers, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Bulk Pricing Tiers',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add bulk pricing tiers to offer discounts for larger quantities',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addBulkPricingTier,
              icon: const Icon(Icons.add),
              label: const Text('Add First Tier'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkPricingTierCard(EnhancedBulkPricingTier tier, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tier ${index + 1}: ${tier.minimumQuantity}+ items',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'RM ${tier.pricePerUnit.toStringAsFixed(2)} per unit',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (tier.discountPercentage != null)
                        Text(
                          '${tier.discountPercentage!.toStringAsFixed(1)}% discount',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _editBulkPricingTier(index),
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit tier',
                    ),
                    IconButton(
                      onPressed: () => _deleteBulkPricingTier(index),
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete tier',
                    ),
                  ],
                ),
              ],
            ),
            if (tier.description != null) ...[
              const SizedBox(height: 8),
              Text(
                tier.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (!tier.isCurrentlyValid) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Inactive or expired',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionalPricingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Promotional Pricing',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addPromotionalPricing,
                icon: const Icon(Icons.add),
                label: const Text('Add Promotion'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_pricingConfig.promotionalPricing.isEmpty)
            _buildEmptyPromotionalState()
          else
            ..._pricingConfig.promotionalPricing.asMap().entries.map((entry) {
              final index = entry.key;
              final promotion = entry.value;
              return _buildPromotionalPricingCard(promotion, index);
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyPromotionalState() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        child: Column(
          children: [
            Icon(Icons.local_offer, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Promotional Pricing',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create promotional campaigns to attract customers with special offers',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addPromotionalPricing,
              icon: const Icon(Icons.add),
              label: const Text('Create Promotion'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionalPricingCard(PromotionalPricing promotion, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promotion.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        promotion.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPromotionDetails(promotion),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _editPromotionalPricing(index),
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit promotion',
                    ),
                    IconButton(
                      onPressed: () => _deletePromotionalPricing(index),
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete promotion',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionDetails(PromotionalPricing promotion) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _buildPromotionChip(
          _getPromotionTypeLabel(promotion.type),
          _getPromotionValueText(promotion),
          Colors.blue,
        ),
        if (promotion.isCurrentlyValid)
          _buildPromotionChip('Active', '', Colors.green)
        else
          _buildPromotionChip('Inactive', '', Colors.grey),
        _buildPromotionChip(
          'Valid',
          '${_formatDate(promotion.validFrom)} - ${_formatDate(promotion.validUntil)}',
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildPromotionChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value.isEmpty ? label : '$label: $value',
        style: TextStyle(
          fontSize: 12,
          color: color.withValues(alpha: 0.8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTimeBasedPricingTab() {
    return const Center(
      child: Text('Time-based pricing coming soon'),
    );
  }

  Widget _buildSettingsTab() {
    return const Center(
      child: Text('Pricing settings coming soon'),
    );
  }

  // Helper methods
  String _getPromotionTypeLabel(PromotionalPricingType type) {
    switch (type) {
      case PromotionalPricingType.percentage:
        return 'Percentage';
      case PromotionalPricingType.fixedAmount:
        return 'Fixed Amount';
      case PromotionalPricingType.buyXGetY:
        return 'Buy X Get Y';
    }
  }

  String _getPromotionValueText(PromotionalPricing promotion) {
    switch (promotion.type) {
      case PromotionalPricingType.percentage:
        return '${promotion.value}%';
      case PromotionalPricingType.fixedAmount:
        return 'RM ${promotion.value.toStringAsFixed(2)}';
      case PromotionalPricingType.buyXGetY:
        return 'Buy ${promotion.value.toInt()} Get 1';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Event handlers
  void _addBulkPricingTier() {
    // TODO: Show bulk pricing tier dialog
  }

  void _editBulkPricingTier(int index) {
    // TODO: Show edit bulk pricing tier dialog
  }

  void _deleteBulkPricingTier(int index) {
    // TODO: Show confirmation dialog and delete
  }

  void _addPromotionalPricing() {
    // TODO: Show promotional pricing dialog
  }

  void _editPromotionalPricing(int index) {
    // TODO: Show edit promotional pricing dialog
  }

  void _deletePromotionalPricing(int index) {
    // TODO: Show confirmation dialog and delete
  }

  void _selectOrderTime() {
    // TODO: Show date/time picker
  }

  void _previewPricing() {
    // TODO: Show pricing preview dialog
  }

  void _resetToDefaults() {
    // TODO: Reset pricing configuration to defaults
  }
}
