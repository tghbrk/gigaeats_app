import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/menu_validation_providers.dart';
import '../../widgets/menu_validation_widgets.dart';
import '../../../data/models/menu_item.dart';

import '../../../data/models/advanced_pricing.dart';
import '../../../data/models/menu_organization.dart';
import '../../../data/validation/menu_validation_service.dart';
import '../../../../../core/errors/menu_exceptions.dart';

/// Demo screen showcasing comprehensive validation and error handling
class MenuValidationDemoScreen extends ConsumerStatefulWidget {
  const MenuValidationDemoScreen({super.key});

  @override
  ConsumerState<MenuValidationDemoScreen> createState() => _MenuValidationDemoScreenState();
}

class _MenuValidationDemoScreenState extends ConsumerState<MenuValidationDemoScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  
  // Demo data for validation
  late MenuItem _demoMenuItem;
  late AdvancedPricingConfig _demoPricingConfig;
  late MenuOrganizationConfig _demoOrganizationConfig;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeDemoData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeDemoData() {
    // Create demo menu item with validation issues
    _demoMenuItem = MenuItem(
      id: 'demo-item-1',
      vendorId: 'demo-vendor-1',
      name: '', // Invalid: empty name
      description: 'Short', // Invalid: too short
      category: 'demo-category',
      basePrice: -5.0, // Invalid: negative price
      imageUrls: ['invalid-url'], // Invalid: bad URL format
      dietaryTypes: [DietaryType.halal],
      isHalalCertified: false, // Warning: halal but not certified
      allergens: [],
      tags: [],
      availableQuantity: -10, // Invalid: negative stock (using correct property name)
      preparationTimeMinutes: 200, // Warning: very long prep time
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Create demo pricing config with validation issues
    _demoPricingConfig = AdvancedPricingConfig(
      menuItemId: 'demo-item-1',
      basePrice: 15.0,
      bulkPricingTiers: [
        EnhancedBulkPricingTier(
          id: 'tier-1',
          minimumQuantity: 0, // Invalid: zero minimum
          maximumQuantity: 5,
          pricePerUnit: 20.0, // Warning: higher than base price
          discountPercentage: null,
          description: 'Invalid tier',
          isActive: true,
          validFrom: null,
          validUntil: null,

        ),
        EnhancedBulkPricingTier(
          id: 'tier-2',
          minimumQuantity: 3, // Invalid: overlaps with tier 1
          maximumQuantity: 10,
          pricePerUnit: 12.0,
          discountPercentage: null,
          description: 'Overlapping tier',
          isActive: true,
          validFrom: null,
          validUntil: null,

        ),
      ],
      promotionalPricing: [
        PromotionalPricing(
          id: 'promo-1',
          name: '', // Invalid: empty name
          description: 'Demo promotion',
          type: PromotionalPricingType.percentage,
          value: 150.0, // Invalid: over 100%
          minimumOrderAmount: null,
          minimumQuantity: null,
          validFrom: DateTime.now().add(const Duration(days: 1)),
          validUntil: DateTime.now(), // Invalid: end before start
          applicableDays: ['invalid-day'], // Invalid: bad day name
          startTime: null,
          endTime: null,
          isActive: true,
          usageLimit: 0, // Invalid: zero limit
          currentUsage: 5, // Invalid: usage exceeds limit

        ),
      ],
      timeBasedRules: [
        TimeBasedPricingRule(
          id: 'time-rule-1',
          name: '', // Invalid: empty name
          description: 'Demo time rule',
          type: TimePricingType.peakHours,
          multiplier: 0.0, // Invalid: zero multiplier
          applicableDays: ['monday', 'invalid-day'], // Invalid: bad day
          startTime: const TimeOfDay(hour: 14, minute: 0),
          endTime: const TimeOfDay(hour: 12, minute: 0), // Invalid: end before start
          isActive: true,
          priority: -1, // Invalid: negative priority
        ),
      ],
      enableDynamicPricing: true,
      minimumPrice: 20.0, // Warning: higher than base price
      maximumPrice: 10.0, // Invalid: lower than base price
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Create demo organization config with validation issues
    _demoOrganizationConfig = MenuOrganizationConfig(
      vendorId: 'demo-vendor-1',
      categories: [
        EnhancedMenuCategory(
          id: 'cat-1',
          vendorId: 'demo-vendor-1',
          name: '', // Invalid: empty name
          description: 'A' * 250, // Invalid: too long
          imageUrl: 'invalid-url', // Invalid: bad URL
          iconName: 'invalid-icon', // Warning: invalid icon
          sortOrder: -1, // Invalid: negative sort order
          isActive: true,
          isVisible: true,
          isFeatured: false,
          parentCategoryId: null,
          displaySettings: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        EnhancedMenuCategory(
          id: 'cat-2',
          vendorId: 'demo-vendor-1',
          name: 'Beverages',
          description: 'Drinks and beverages',
          imageUrl: null,
          iconName: 'local_drink',
          sortOrder: 0,
          isActive: true,
          isVisible: true,
          isFeatured: false,
          parentCategoryId: 'cat-1', // Valid parent reference
          displaySettings: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        EnhancedMenuCategory(
          id: 'cat-3',
          vendorId: 'demo-vendor-1',
          name: 'Circular',
          description: 'Category with circular reference',
          imageUrl: null,
          iconName: 'category',
          sortOrder: 1,
          isActive: true,
          isVisible: true,
          isFeatured: false,
          parentCategoryId: 'cat-3', // Invalid: self-reference
          displaySettings: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ],
      itemPositions: [
        MenuItemPosition(
          menuItemId: 'item-1',
          categoryId: 'cat-1',
          sortOrder: -5, // Invalid: negative sort order
          isFeatured: true,
          isRecommended: true,
          isNew: true,
          isPopular: true, // Warning: too many badges
          displayTags: {},
          updatedAt: DateTime.now(),
        ),
        MenuItemPosition(
          menuItemId: 'item-1',
          categoryId: 'cat-1', // Invalid: duplicate position
          sortOrder: 0,
          isFeatured: false,
          isRecommended: false,
          isNew: false,
          isPopular: false,
          displayTags: {},
          updatedAt: DateTime.now(),
        ),
      ],
      displayStyle: MenuDisplayStyle.grid,
      enableCategoryImages: true,
      enableSubcategories: true, // Warning: enabled but no subcategories
      enableDragAndDrop: true,
      showItemCounts: true,
      groupByAvailability: false,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation & Error Handling'),
        // Note: AppBar doesn't have subtitle parameter
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Menu Items'),
            Tab(icon: Icon(Icons.attach_money), text: 'Pricing'),
            Tab(icon: Icon(Icons.reorder), text: 'Organization'),
            Tab(icon: Icon(Icons.error_outline), text: 'Error Recovery'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMenuItemValidationTab(),
          _buildPricingValidationTab(),
          _buildOrganizationValidationTab(),
          _buildErrorRecoveryTab(),
        ],
      ),
    );
  }

  Widget _buildMenuItemValidationTab() {
    final validationResult = ref.watch(menuItemValidationProvider(_demoMenuItem));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Menu Item Validation',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This demo shows validation for menu item data with various validation errors and warnings.',
          ),
          const SizedBox(height: 16),
          
          // Validation feedback
          MenuValidationFeedback(
            validationResult: validationResult,
            showWarnings: true,
          ),
          
          const SizedBox(height: 16),
          
          // Form fields with validation
          _buildMenuItemForm(validationResult),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _fixMenuItemIssues(),
                child: const Text('Fix Issues'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => _resetMenuItemData(),
                child: const Text('Reset Data'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingValidationTab() {
    final validationResult = ref.watch(advancedPricingValidationProvider(_demoPricingConfig));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advanced Pricing Validation',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This demo shows validation for advanced pricing configurations including bulk pricing, promotions, and time-based rules.',
          ),
          const SizedBox(height: 16),
          
          // Validation feedback
          MenuValidationFeedback(
            validationResult: validationResult,
            showWarnings: true,
          ),
          
          const SizedBox(height: 16),
          
          // Pricing configuration summary
          _buildPricingConfigSummary(),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _fixPricingIssues(),
                child: const Text('Fix Issues'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => _resetPricingData(),
                child: const Text('Reset Data'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizationValidationTab() {
    final validationResult = ref.watch(menuOrganizationValidationProvider(_demoOrganizationConfig));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Menu Organization Validation',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This demo shows validation for menu organization including categories, hierarchy, and item positioning.',
          ),
          const SizedBox(height: 16),
          
          // Validation feedback
          MenuValidationFeedback(
            validationResult: validationResult,
            showWarnings: true,
          ),
          
          const SizedBox(height: 16),
          
          // Organization summary
          _buildOrganizationSummary(),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _fixOrganizationIssues(),
                child: const Text('Fix Issues'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => _resetOrganizationData(),
                child: const Text('Reset Data'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorRecoveryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Error Recovery Examples',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This demo shows different types of menu exceptions and their recovery suggestions.',
          ),
          const SizedBox(height: 16),
          
          // Different error types
          _buildErrorExample('Not Found Error', const MenuNotFoundException('Menu item not found')),
          const SizedBox(height: 16),
          _buildErrorExample('Unauthorized Error', const MenuUnauthorizedException('You do not have permission to edit this menu')),
          const SizedBox(height: 16),
          _buildErrorExample('Validation Error', const MenuValidationException('Invalid menu item data', fieldErrors: {'name': 'Name is required', 'price': 'Price must be positive'})),
          const SizedBox(height: 16),
          _buildErrorExample('Pricing Error', const PricingCalculationException('Failed to calculate effective price due to conflicting rules')),
          const SizedBox(height: 16),
          _buildErrorExample('Real-time Error', const MenuRealtimeException('Connection to real-time updates lost')),
        ],
      ),
    );
  }

  Widget _buildMenuItemForm(MenuValidationResult validationResult) {
    return Column(
      children: [
        ValidatedFormField(
          fieldName: 'name',
          validationResult: validationResult,
          child: TextFormField(
            initialValue: _demoMenuItem.name,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _demoMenuItem = _demoMenuItem.copyWith(name: value);
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        ValidatedFormField(
          fieldName: 'description',
          validationResult: validationResult,
          child: TextFormField(
            initialValue: _demoMenuItem.description,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) {
              setState(() {
                _demoMenuItem = _demoMenuItem.copyWith(description: value);
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        ValidatedFormField(
          fieldName: 'basePrice',
          validationResult: validationResult,
          child: TextFormField(
            initialValue: _demoMenuItem.basePrice.toString(),
            decoration: const InputDecoration(
              labelText: 'Base Price (RM)',
              border: OutlineInputBorder(),
              prefixText: 'RM ',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final price = double.tryParse(value) ?? 0.0;
              setState(() {
                _demoMenuItem = _demoMenuItem.copyWith(basePrice: price);
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPricingConfigSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pricing Configuration Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text('Base Price: RM ${_demoPricingConfig.basePrice.toStringAsFixed(2)}'),
            Text('Bulk Pricing Tiers: ${_demoPricingConfig.bulkPricingTiers.length}'),
            Text('Promotional Pricing: ${_demoPricingConfig.promotionalPricing.length}'),
            Text('Time-based Rules: ${_demoPricingConfig.timeBasedRules.length}'),
            if (_demoPricingConfig.minimumPrice != null)
              Text('Minimum Price: RM ${_demoPricingConfig.minimumPrice!.toStringAsFixed(2)}'),
            if (_demoPricingConfig.maximumPrice != null)
              Text('Maximum Price: RM ${_demoPricingConfig.maximumPrice!.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizationSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Organization Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text('Categories: ${_demoOrganizationConfig.categories.length}'),
            Text('Item Positions: ${_demoOrganizationConfig.itemPositions.length}'),
            Text('Display Style: ${_demoOrganizationConfig.displayStyle.name}'),
            Text('Subcategories Enabled: ${_demoOrganizationConfig.enableSubcategories}'),
            Text('Category Images Enabled: ${_demoOrganizationConfig.enableCategoryImages}'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorExample(String title, MenuException exception) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        MenuErrorRecovery(
          exception: exception,
          onRetry: () => _showSnackBar('Retry action triggered'),
          onCancel: () => _showSnackBar('Cancel action triggered'),
          customActions: {
            'Contact Support': () => _showSnackBar('Contact support action triggered'),
          },
        ),
      ],
    );
  }

  void _fixMenuItemIssues() {
    setState(() {
      _demoMenuItem = _demoMenuItem.copyWith(
        name: 'Nasi Lemak Special',
        description: 'Traditional coconut rice with sambal, anchovies, peanuts, and egg',
        basePrice: 15.00,
        imageUrls: ['https://example.com/nasi-lemak.jpg'],
        isHalalCertified: true,
        availableQuantity: 50,
        preparationTimeMinutes: 20,
      );
    });
    _showSnackBar('Menu item issues fixed!');
  }

  void _resetMenuItemData() {
    _initializeDemoData();
    setState(() {});
    _showSnackBar('Menu item data reset to demo state');
  }

  void _fixPricingIssues() {
    setState(() {
      _demoPricingConfig = _demoPricingConfig.copyWith(
        bulkPricingTiers: [
          EnhancedBulkPricingTier(
            id: 'tier-1',
            minimumQuantity: 5,
            maximumQuantity: 10,
            pricePerUnit: 12.0,
            discountPercentage: null,
            description: 'Bulk discount tier',
            isActive: true,
            validFrom: null,
            validUntil: null,

          ),
        ],
        promotionalPricing: [
          PromotionalPricing(
            id: 'promo-1',
            name: 'Weekend Special',
            description: 'Weekend promotion',
            type: PromotionalPricingType.percentage,
            value: 20.0,
            minimumOrderAmount: null,
            minimumQuantity: null,
            validFrom: DateTime.now(),
            validUntil: DateTime.now().add(const Duration(days: 7)),
            applicableDays: ['saturday', 'sunday'],
            startTime: null,
            endTime: null,
            isActive: true,
            usageLimit: 100,
            currentUsage: 0,

          ),
        ],
        timeBasedRules: [
          TimeBasedPricingRule(
            id: 'time-rule-1',
            name: 'Peak Hours',
            description: 'Peak hour pricing',
            type: TimePricingType.peakHours,
            multiplier: 1.2,
            applicableDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
            startTime: const TimeOfDay(hour: 12, minute: 0),
            endTime: const TimeOfDay(hour: 14, minute: 0),
            isActive: true,
            priority: 1,
          ),
        ],
        minimumPrice: 10.0,
        maximumPrice: 25.0,
      );
    });
    _showSnackBar('Pricing issues fixed!');
  }

  void _resetPricingData() {
    _initializeDemoData();
    setState(() {});
    _showSnackBar('Pricing data reset to demo state');
  }

  void _fixOrganizationIssues() {
    setState(() {
      _demoOrganizationConfig = _demoOrganizationConfig.copyWith(
        categories: [
          EnhancedMenuCategory(
            id: 'cat-1',
            vendorId: 'demo-vendor-1',
            name: 'Main Dishes',
            description: 'Traditional Malaysian main dishes',
            imageUrl: 'https://example.com/main-dishes.jpg',
            iconName: 'restaurant',
            sortOrder: 0,
            isActive: true,
            isVisible: true,
            isFeatured: false,
            parentCategoryId: null,
            displaySettings: {},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          EnhancedMenuCategory(
            id: 'cat-2',
            vendorId: 'demo-vendor-1',
            name: 'Beverages',
            description: 'Drinks and beverages',
            imageUrl: 'https://example.com/beverages.jpg',
            iconName: 'local_drink',
            sortOrder: 1,
            isActive: true,
            isVisible: true,
            isFeatured: false,
            parentCategoryId: null,
            displaySettings: {},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
        itemPositions: [
          MenuItemPosition(
            menuItemId: 'item-1',
            categoryId: 'cat-1',
            sortOrder: 0,
            isFeatured: true,
            isRecommended: false,
            isNew: false,
            isPopular: false,
            displayTags: {},
            updatedAt: DateTime.now(),
          ),
        ],
        enableSubcategories: false,
      );
    });
    _showSnackBar('Organization issues fixed!');
  }

  void _resetOrganizationData() {
    _initializeDemoData();
    setState(() {});
    _showSnackBar('Organization data reset to demo state');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
