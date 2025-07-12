import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/customization_template.dart';

import '../../widgets/vendor/enhanced_customization_section.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../presentation/providers/repository_providers.dart';
import '../../providers/customization_template_providers.dart';
import '../../utils/template_debug_logger.dart';

/// Enhanced menu item form screen demonstrating the new customization management
class EnhancedMenuItemFormScreen extends ConsumerStatefulWidget {
  final String? menuItemId;

  const EnhancedMenuItemFormScreen({
    super.key,
    this.menuItemId,
  });

  @override
  ConsumerState<EnhancedMenuItemFormScreen> createState() => _EnhancedMenuItemFormScreenState();
}

class _EnhancedMenuItemFormScreenState extends ConsumerState<EnhancedMenuItemFormScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _basePriceController = TextEditingController();
  
  // Form state - template-only
  List<CustomizationTemplate> _linkedTemplates = [];
  double get _basePrice => double.tryParse(_basePriceController.text) ?? 0.0;
  String get _menuItemName => _nameController.text.trim().isEmpty ? 'New Menu Item' : _nameController.text.trim();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _basePriceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Load existing data if editing
    if (widget.menuItemId != null) {
      final session = TemplateDebugLogger.createSession('enhanced_menu_form_load_data');
      session.addEvent('Loading data for menu item: ${widget.menuItemId}');

      try {
        // Load existing menu item data
        final menuItemRepository = ref.read(menuItemRepositoryProvider);
        final menuItem = await menuItemRepository.getMenuItemById(widget.menuItemId!);

        if (menuItem != null) {
          session.addEvent('Menu item loaded: ${menuItem.name}');

          // Populate form fields
          _nameController.text = menuItem.name;
          _descriptionController.text = menuItem.description ?? '';
          _basePriceController.text = menuItem.basePrice.toString();

          session.addEvent('Form fields populated');

          // Load existing templates
          debugPrint('🔧 [ENHANCED-MENU-FORM] About to load templates for menu item: ${widget.menuItemId}');
          final templates = await ref.read(menuItemTemplatesProvider(widget.menuItemId!).future);

          debugPrint('🔧 [ENHANCED-MENU-FORM] Templates loaded from provider: ${templates.length}');
          for (final template in templates) {
            debugPrint('🔧 [ENHANCED-MENU-FORM] Template: ${template.name} (${template.id}) with ${template.options.length} options');
          }

          setState(() {
            _linkedTemplates = templates;
          });

          debugPrint('🔧 [ENHANCED-MENU-FORM] State updated with ${_linkedTemplates.length} templates');

          session.addEvent('Templates loaded: ${templates.length}');

          TemplateDebugLogger.logSuccess(
            operation: 'enhanced_menu_form_load_data',
            message: 'Successfully loaded menu item and ${templates.length} templates',
            data: {
              'menuItemId': widget.menuItemId,
              'menuItemName': menuItem.name,
              'templatesCount': templates.length,
            },
          );

          session.complete('success');
        } else {
          session.addEvent('❌ Menu item not found');
          session.complete('error: menu item not found');
        }
      } catch (e, stackTrace) {
        TemplateDebugLogger.logError(
          operation: 'enhanced_menu_form_load_data',
          error: e,
          stackTrace: stackTrace,
          context: {'menuItemId': widget.menuItemId},
        );

        session.complete('error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.menuItemId != null ? 'Edit Menu Item' : 'Add Menu Item'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'Basic Info'),
            Tab(icon: Icon(Icons.tune), text: 'Customizations'),
            Tab(icon: Icon(Icons.attach_money), text: 'Pricing'),
            Tab(icon: Icon(Icons.category), text: 'Organization'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBasicInfoTab(),
          _buildCustomizationsTab(),
          _buildPricingTab(),
          _buildOrganizationTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Item Name *',
                        hintText: 'e.g., Nasi Lemak Special Set',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.restaurant_menu),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter item name';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        hintText: 'Describe your menu item...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter description';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Base Price
                    TextFormField(
                      controller: _basePriceController,
                      decoration: const InputDecoration(
                        labelText: 'Base Price (RM) *',
                        hintText: '0.00',
                        border: OutlineInputBorder(),
                        prefixText: 'RM ',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        setState(() {}); // Trigger rebuild for pricing preview
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Invalid price';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomizationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<String?>(
        future: _getVendorId(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text('Error loading vendor information: ${snapshot.error}'),
            );
          }

          debugPrint('🔧 [ENHANCED-MENU-FORM] Building EnhancedCustomizationSection with ${_linkedTemplates.length} linked templates');
          for (int i = 0; i < _linkedTemplates.length; i++) {
            final template = _linkedTemplates[i];
            debugPrint('🔧 [ENHANCED-MENU-FORM] Passing template $i: ${template.name} (${template.id}) with ${template.options.length} options');
          }

          return EnhancedCustomizationSection(
            vendorId: snapshot.data!,
            linkedTemplates: _linkedTemplates,
            menuItemName: _menuItemName,
            basePrice: _basePrice,
            onTemplatesChanged: (templates) {
              debugPrint('🔧 [ENHANCED-MENU-FORM] Templates changed: ${templates.length}');
              setState(() {
                _linkedTemplates = templates;
              });
            },
          );
        },
      ),
    );
  }

  Future<String?> _getVendorId() async {
    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;

      if (userId == null) return null;

      final vendorRepository = ref.read(vendorRepositoryProvider);
      final vendor = await vendorRepository.getVendorByUserId(userId);

      return vendor?.id;
    } catch (e) {
      return null;
    }
  }

  Widget _buildPricingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
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
                        'Pricing Summary',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildPricingSummaryRow('Base Price', _basePrice),
                  
                  if (_linkedTemplates.isNotEmpty) ...[
                    const Divider(),
                    Text(
                      'Template Pricing Impact',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._linkedTemplates.map((template) =>
                      _buildTemplatePricingRow(template)
                    ),
                    const Divider(),
                    _buildTotalPriceRange(),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Bulk Pricing Section (placeholder)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.trending_down,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bulk Pricing (Coming Soon)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure volume discounts for larger orders',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizationTab() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.category, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Organization Features',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Category management and menu organization features will be implemented in the next phase.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingSummaryRow(String label, double price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            'RM ${price.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatePricingRow(CustomizationTemplate template) {
    final options = template.options;
    if (options.isEmpty) return const SizedBox.shrink();

    final minPrice = options.map((opt) => opt.additionalPrice).reduce((min, price) => price < min ? price : min);
    final maxPrice = options.map((opt) => opt.additionalPrice).reduce((max, price) => price > max ? price : max);

    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  template.isSingleSelection ? Icons.radio_button_checked : Icons.check_box,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    template.name,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                if (template.isRequired)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'Required',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
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

  Widget _buildTotalPriceRange() {
    double minTotal = _basePrice;
    double maxTotal = _basePrice;

    for (final template in _linkedTemplates) {
      if (template.options.isNotEmpty) {
        final minOptionPrice = template.options
            .map((opt) => opt.additionalPrice)
            .reduce((min, price) => price < min ? price : min);
        final maxOptionPrice = template.options
            .map((opt) => opt.additionalPrice)
            .reduce((max, price) => price > max ? price : max);

        if (template.isRequired) {
          // For required templates, add minimum price to minTotal
          minTotal += minOptionPrice;
        }

        if (template.isSingleSelection) {
          // For single choice, take the maximum
          maxTotal += maxOptionPrice;
        } else {
          // For multiple choice, sum all options for max
          maxTotal += template.options
              .map((opt) => opt.additionalPrice)
              .fold(0.0, (sum, price) => sum + price);
        }
      }
    }

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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: _saveDraft,
              child: const Text('Save Draft'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _saveAndPublish,
              child: const Text('Save & Publish'),
            ),
          ),
        ],
      ),
    );
  }

  void _saveDraft() {
    // TODO: Implement save draft functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved successfully!')),
    );
  }

  void _saveAndPublish() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement save and publish functionality
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menu item published successfully!')),
      );
      Navigator.of(context).pop();
    }
  }
}
