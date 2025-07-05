# Enhanced Menu Form Components Design

## 🧩 Reusable Component Architecture

This document details the reusable components for the enhanced menu form, building upon the existing solid foundation.

## 1. 📋 Enhanced Tabbed Form Container

### `EnhancedMenuFormContainer`
```dart
class EnhancedMenuFormContainer extends ConsumerStatefulWidget {
  final String? menuItemId;
  final VoidCallback? onSaved;
  
  const EnhancedMenuFormContainer({
    super.key,
    this.menuItemId,
    this.onSaved,
  });
}

class _EnhancedMenuFormContainerState extends ConsumerState<EnhancedMenuFormContainer>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  final PageController _pageController = PageController();
  
  // Tab definitions
  static const List<Tab> _tabs = [
    Tab(icon: Icon(Icons.info_outline), text: 'Basic Info'),
    Tab(icon: Icon(Icons.tune), text: 'Customizations'),
    Tab(icon: Icon(Icons.attach_money), text: 'Pricing'),
    Tab(icon: Icon(Icons.category), text: 'Organization'),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.menuItemId != null ? 'Edit Menu Item' : 'Add Menu Item'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          onTap: _onTabTapped,
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          BasicInfoTab(),
          CustomizationsTab(),
          PricingTab(),
          OrganizationTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
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
            child: OutlinedButton(
              onPressed: _onCancel,
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: _onSaveDraft,
              child: const Text('Save Draft'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: _onPreview,
              child: const Text('Preview'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _onSaveAndPublish,
              child: const Text('Save & Publish'),
            ),
          ),
        ],
      ),
    );
  }
}
```

## 2. 🎛️ Enhanced Customization Components

### `EnhancedCustomizationGroupCard`
```dart
class EnhancedCustomizationGroupCard extends StatelessWidget {
  final MenuItemCustomization customization;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReorder;
  final Function(CustomizationOption) onAddOption;
  final bool showPricingPreview;
  final double basePrice;
  
  const EnhancedCustomizationGroupCard({
    super.key,
    required this.customization,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    required this.onReorder,
    required this.onAddOption,
    this.showPricingPreview = true,
    this.basePrice = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Column(
        children: [
          // Header with drag handle and actions
          _buildHeader(context),
          // Expandable content
          _buildExpandableContent(context),
        ],
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Drag handle
          Icon(
            Icons.drag_handle,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          
          // Group info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customization.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildTypeChip(),
                    const SizedBox(width: 8),
                    _buildRequiredChip(),
                    if (showPricingPreview) ...[
                      const SizedBox(width: 8),
                      _buildPricingPreview(),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Action buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }
  
  Widget _buildTypeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: customization.type == 'single' 
            ? Colors.blue[100] 
            : Colors.green[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        customization.type == 'single' ? 'Single Choice' : 'Multiple Choice',
        style: TextStyle(
          fontSize: 12,
          color: customization.type == 'single' 
              ? Colors.blue[800] 
              : Colors.green[800],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  Widget _buildRequiredChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: customization.isRequired 
            ? Colors.orange[100] 
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        customization.isRequired ? 'Required' : 'Optional',
        style: TextStyle(
          fontSize: 12,
          color: customization.isRequired 
              ? Colors.orange[800] 
              : Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  Widget _buildPricingPreview() {
    final minPrice = customization.options
        .map((opt) => opt.additionalPrice)
        .fold(0.0, (min, price) => price < min ? price : min);
    final maxPrice = customization.options
        .map((opt) => opt.additionalPrice)
        .fold(0.0, (max, price) => price > max ? price : max);
    
    if (minPrice == maxPrice && minPrice == 0) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        minPrice == maxPrice 
            ? '+RM ${maxPrice.toStringAsFixed(2)}'
            : '+RM ${minPrice.toStringAsFixed(2)} - ${maxPrice.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 12,
          color: Colors.purple[800],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit group',
          iconSize: 20,
        ),
        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete group',
          iconSize: 20,
        ),
      ],
    );
  }
  
  Widget _buildExpandableContent(BuildContext context) {
    return ExpansionTile(
      title: const SizedBox.shrink(),
      children: [
        // Options list
        ...customization.options.map((option) => 
          _buildOptionTile(context, option)
        ),
        
        // Add option button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onAddOption(
                CustomizationOption(
                  name: '',
                  additionalPrice: 0.0,
                  isDefault: false,
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Option'),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildOptionTile(BuildContext context, CustomizationOption option) {
    return ListTile(
      leading: option.isDefault 
          ? Icon(Icons.star, color: Colors.amber[600], size: 20)
          : Icon(Icons.star_border, color: Colors.grey[400], size: 20),
      title: Text(option.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (option.additionalPrice > 0)
            Text(
              '+RM ${option.additionalPrice.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.green[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              // Edit option
            },
            icon: const Icon(Icons.edit_outlined),
            iconSize: 16,
          ),
          IconButton(
            onPressed: () {
              // Delete option
            },
            icon: const Icon(Icons.delete_outline),
            iconSize: 16,
          ),
        ],
      ),
    );
  }
}
```

## 3. 💰 Real-time Pricing Calculator

### `PricingCalculatorWidget`
```dart
class PricingCalculatorWidget extends ConsumerWidget {
  final double basePrice;
  final List<MenuItemCustomization> customizations;
  final List<BulkPricingTier> bulkTiers;
  final bool showDetailedBreakdown;
  
  const PricingCalculatorWidget({
    super.key,
    required this.basePrice,
    this.customizations = const [],
    this.bulkTiers = const [],
    this.showDetailedBreakdown = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
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
                  'Pricing Calculator',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Base price
            _buildPriceRow(
              'Base Price',
              basePrice,
              isBase: true,
            ),
            
            // Customization impact
            if (customizations.isNotEmpty) ...[
              const Divider(),
              Text(
                'Customization Impact',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...customizations.map((customization) => 
                _buildCustomizationImpact(context, customization)
              ),
            ],
            
            // Bulk pricing
            if (bulkTiers.isNotEmpty) ...[
              const Divider(),
              Text(
                'Bulk Pricing Tiers',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...bulkTiers.map((tier) => 
                _buildBulkTierRow(context, tier)
              ),
            ],
            
            // Total range
            const Divider(),
            _buildTotalPriceRange(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPriceRow(String label, double price, {bool isBase = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBase ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            'RM ${price.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBase ? FontWeight.w600 : FontWeight.normal,
              color: isBase ? null : Colors.green[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCustomizationImpact(BuildContext context, MenuItemCustomization customization) {
    final minPrice = customization.options.isEmpty ? 0.0 :
        customization.options
            .map((opt) => opt.additionalPrice)
            .reduce((min, price) => price < min ? price : min);
    final maxPrice = customization.options.isEmpty ? 0.0 :
        customization.options
            .map((opt) => opt.additionalPrice)
            .reduce((max, price) => price > max ? price : max);
    
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              customization.name,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            minPrice == maxPrice 
                ? (minPrice == 0 ? 'Free' : '+RM ${maxPrice.toStringAsFixed(2)}')
                : '+RM ${minPrice.toStringAsFixed(2)} - ${maxPrice.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              color: minPrice == 0 && maxPrice == 0 ? Colors.grey[600] : Colors.green[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBulkTierRow(BuildContext context, BulkPricingTier tier) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${tier.minimumQuantity}+ items',
            style: const TextStyle(fontSize: 14),
          ),
          Row(
            children: [
              Text(
                'RM ${tier.pricePerUnit.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14),
              ),
              if (tier.discountPercentage != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '-${tier.discountPercentage!.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTotalPriceRange(BuildContext context) {
    final minCustomizationPrice = customizations.isEmpty ? 0.0 :
        customizations
            .map((c) => c.options.isEmpty ? 0.0 : 
                c.options.map((o) => o.additionalPrice).reduce((min, p) => p < min ? p : min))
            .fold(0.0, (sum, price) => sum + price);
    
    final maxCustomizationPrice = customizations.isEmpty ? 0.0 :
        customizations
            .map((c) => c.options.isEmpty ? 0.0 : 
                c.options.map((o) => o.additionalPrice).reduce((max, p) => p > max ? p : max))
            .fold(0.0, (sum, price) => sum + price);
    
    final minTotal = basePrice + minCustomizationPrice;
    final maxTotal = basePrice + maxCustomizationPrice;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Price Range',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            minTotal == maxTotal 
                ? 'RM ${minTotal.toStringAsFixed(2)}'
                : 'RM ${minTotal.toStringAsFixed(2)} - ${maxTotal.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
```
