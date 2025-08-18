import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/product.dart';
import '../../providers/customization_template_providers.dart';
import '../../../../../presentation/providers/repository_providers.dart';
import '../../widgets/vendor/bulk_menu_item_selector.dart';
import '../../widgets/vendor/bulk_template_selector.dart';
import '../../widgets/vendor/bulk_operation_progress.dart';
import '../../../../../shared/widgets/loading_widget.dart';
import '../../../../../design_system/widgets/buttons/ge_button.dart';
import '../../../../user_management/presentation/screens/vendor/widgets/standard_vendor_header.dart';

// Provider for vendor menu items (reused from menu management)
final vendorMenuItemsProvider = FutureProvider.family<List<Product>, String>((ref, vendorId) async {
  final menuItemRepository = ref.read(menuItemRepositoryProvider);
  return menuItemRepository.getMenuItems(vendorId);
});

/// Screen for bulk applying templates to multiple menu items
class BulkTemplateApplicationScreen extends ConsumerStatefulWidget {
  final String vendorId;

  const BulkTemplateApplicationScreen({
    super.key,
    required this.vendorId,
  });

  @override
  ConsumerState<BulkTemplateApplicationScreen> createState() => _BulkTemplateApplicationScreenState();
}

class _BulkTemplateApplicationScreenState extends ConsumerState<BulkTemplateApplicationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Selection state
  List<String> _selectedMenuItemIds = [];
  List<String> _selectedTemplateIds = [];
  
  // Operation state
  bool _isProcessing = false;
  double _progress = 0.0;
  String? _currentOperation;
  final List<String> _processedItems = [];
  final List<String> _failedItems = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardVendorHeader(
        title: 'Bulk Template Application',
        titleIcon: Icons.auto_awesome,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Select Items', icon: Icon(Icons.restaurant_menu)),
            Tab(text: 'Select Templates', icon: Icon(Icons.layers)),
            Tab(text: 'Apply & Progress', icon: Icon(Icons.play_arrow)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMenuItemSelectionTab(),
          _buildTemplateSelectionTab(),
          _buildApplicationTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildMenuItemSelectionTab() {
    final menuItemsAsync = ref.watch(vendorMenuItemsProvider(widget.vendorId));

    return Column(
      children: [
        // Header with selection summary
        _buildSelectionHeader(
          'Menu Items',
          _selectedMenuItemIds.length,
          Icons.restaurant_menu,
        ),
        
        // Menu items list
        Expanded(
          child: menuItemsAsync.when(
            data: (menuItems) => BulkMenuItemSelector(
              menuItems: menuItems,
              selectedItemIds: _selectedMenuItemIds,
              onSelectionChanged: (selectedIds) {
                setState(() {
                  _selectedMenuItemIds = selectedIds;
                });
              },
            ),
            loading: () => const LoadingWidget(message: 'Loading menu items...'),
            error: (error, stack) => _buildErrorState('Failed to load menu items: $error'),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateSelectionTab() {
    final templatesAsync = ref.watch(vendorTemplatesProvider(VendorTemplatesParams(
      vendorId: widget.vendorId,
      isActive: true,
    )));

    return Column(
      children: [
        // Header with selection summary
        _buildSelectionHeader(
          'Templates',
          _selectedTemplateIds.length,
          Icons.layers,
        ),
        
        // Templates list
        Expanded(
          child: templatesAsync.when(
            data: (templates) => BulkTemplateSelector(
              templates: templates,
              selectedTemplateIds: _selectedTemplateIds,
              onSelectionChanged: (selectedIds) {
                setState(() {
                  _selectedTemplateIds = selectedIds;
                });
              },
            ),
            loading: () => const LoadingWidget(message: 'Loading templates...'),
            error: (error, stack) => _buildErrorState('Failed to load templates: $error'),
          ),
        ),
      ],
    );
  }

  Widget _buildApplicationTab() {
    return Column(
      children: [
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Operation Summary
                _buildOperationSummary(),

                const SizedBox(height: 24),

                // Progress Section
                if (_isProcessing) ...[
                  BulkOperationProgress(
                    progress: _progress,
                    currentOperation: _currentOperation,
                    processedCount: _processedItems.length,
                    totalCount: _selectedMenuItemIds.length,
                    failedCount: _failedItems.length,
                  ),
                  const SizedBox(height: 24),
                ],

                // Results Section
                if (_processedItems.isNotEmpty || _failedItems.isNotEmpty) ...[
                  _buildResultsSection(),
                  const SizedBox(height: 24),
                ],

                // Add some bottom padding to ensure content doesn't get hidden behind action buttons
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),

        // Fixed action buttons at bottom
        if (!_isProcessing) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: _buildActionButtons(),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectionHeader(String title, int count, IconData icon) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: count > 0 
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$count selected',
              style: theme.textTheme.labelMedium?.copyWith(
                color: count > 0 
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationSummary() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Operation Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Menu Items',
                    '${_selectedMenuItemIds.length}',
                    Icons.restaurant_menu,
                    theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    'Templates',
                    '${_selectedTemplateIds.length}',
                    Icons.layers,
                    theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will apply ${_selectedTemplateIds.length} template${_selectedTemplateIds.length == 1 ? '' : 's'} to ${_selectedMenuItemIds.length} menu item${_selectedMenuItemIds.length == 1 ? '' : 's'}.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Results',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            if (_processedItems.isNotEmpty)
              _buildResultItem(
                'Successfully Applied',
                _processedItems.length,
                Icons.check_circle,
                Colors.green,
              ),
            
            if (_failedItems.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildResultItem(
                'Failed',
                _failedItems.length,
                Icons.error,
                Colors.red,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(String label, int count, IconData icon, Color color) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          count.toString(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final canApply = _selectedMenuItemIds.isNotEmpty && _selectedTemplateIds.isNotEmpty;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: GEButton.primary(
            text: 'Apply Templates',
            onPressed: canApply ? _applyTemplates : null,
            icon: Icons.play_arrow,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: GEButton.secondary(
            text: 'Reset Selection',
            onPressed: _resetSelection,
            icon: Icons.refresh,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_tabController.index > 0)
            Expanded(
              child: GEButton.secondary(
                text: 'Previous',
                onPressed: () {
                  _tabController.animateTo(_tabController.index - 1);
                },
                icon: Icons.arrow_back,
              ),
            ),
          
          if (_tabController.index > 0) const SizedBox(width: 16),
          
          if (_tabController.index < 2)
            Expanded(
              child: GEButton.primary(
                text: 'Next',
                onPressed: _canProceedToNext() ? () {
                  _tabController.animateTo(_tabController.index + 1);
                } : null,
                icon: Icons.arrow_forward,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceedToNext() {
    switch (_tabController.index) {
      case 0:
        return _selectedMenuItemIds.isNotEmpty;
      case 1:
        return _selectedTemplateIds.isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _applyTemplates() async {
    if (_selectedMenuItemIds.isEmpty || _selectedTemplateIds.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _processedItems.clear();
      _failedItems.clear();
    });

    try {
      final linkingNotifier = ref.read(templateLinkingProvider.notifier);
      final total = _selectedMenuItemIds.length;

      for (int i = 0; i < _selectedMenuItemIds.length; i++) {
        final menuItemId = _selectedMenuItemIds[i];
        
        setState(() {
          _currentOperation = 'Applying templates to menu item ${i + 1} of $total';
          _progress = (i / total);
        });

        try {
          final success = await linkingNotifier.bulkLinkTemplates(
            menuItemIds: [menuItemId],
            templateIds: _selectedTemplateIds,
          );

          if (success) {
            _processedItems.add(menuItemId);
          } else {
            _failedItems.add(menuItemId);
          }
        } catch (e) {
          _failedItems.add(menuItemId);
        }

        // Small delay to show progress
        await Future.delayed(const Duration(milliseconds: 100));
      }

      setState(() {
        _progress = 1.0;
        _currentOperation = 'Completed';
      });

      // Show completion message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Applied templates to ${_processedItems.length} menu items. ${_failedItems.length} failed.',
            ),
            backgroundColor: _failedItems.isEmpty ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error applying templates: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _resetSelection() {
    setState(() {
      _selectedMenuItemIds.clear();
      _selectedTemplateIds.clear();
      _processedItems.clear();
      _failedItems.clear();
      _progress = 0.0;
      _currentOperation = null;
    });
    
    _tabController.animateTo(0);
  }
}
