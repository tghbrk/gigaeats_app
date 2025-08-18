import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../user_management/presentation/screens/vendor/widgets/standard_vendor_header.dart';

import '../../providers/customization_template_providers.dart';
import '../../../../../shared/widgets/loading_widget.dart';
import '../../../../../design_system/widgets/buttons/ge_button.dart';
import '../../widgets/vendor/template_card.dart';
import 'template_form_screen.dart';
import 'template_analytics_dashboard_screen.dart';

/// Main screen for vendor template management
class TemplateManagementScreen extends ConsumerStatefulWidget {
  final String vendorId;

  const TemplateManagementScreen({
    super.key,
    required this.vendorId,
  });

  @override
  ConsumerState<TemplateManagementScreen> createState() => _TemplateManagementScreenState();
}

class _TemplateManagementScreenState extends ConsumerState<TemplateManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String? _searchQuery;
  bool? _activeFilter;

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
        title: 'Template Management',
        titleIcon: Icons.layers,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Templates', icon: Icon(Icons.layers)),
            Tab(text: 'Usage', icon: Icon(Icons.link)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCreateTemplate(),
            tooltip: 'Create Template',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshData(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTemplatesTab(),
          _buildUsageTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildTemplatesTab() {
    final templatesAsync = ref.watch(vendorTemplatesProvider(VendorTemplatesParams(
      vendorId: widget.vendorId,
      isActive: _activeFilter,
      searchQuery: _searchQuery,
    )));

    return Column(
      children: [
        // Search and Filter Bar
        _buildSearchAndFilterBar(),
        
        // Templates List
        Expanded(
          child: templatesAsync.when(
            data: (templates) {
              if (templates.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: () async => _refreshData(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    return TemplateCard(
                      template: template,
                      onTap: () => _navigateToEditTemplate(template.id),
                      onEdit: () => _navigateToEditTemplate(template.id),
                      onDuplicate: () => _duplicateTemplate(template),
                      onDelete: () => _showDeleteConfirmation(template),
                      onToggleActive: () => _toggleTemplateActive(template),
                    );
                  },
                ),
              );
            },
            loading: () => const LoadingWidget(message: 'Loading templates...'),
            error: (error, stack) => _buildErrorState(error.toString()),
          ),
        ),
      ],
    );
  }

  Widget _buildUsageTab() {
    // TODO: Implement usage overview showing which menu items use which templates
    return const Center(
      child: Text('Template Usage Overview\n(Coming Soon)', textAlign: TextAlign.center),
    );
  }

  Widget _buildAnalyticsTab() {
    return TemplateAnalyticsTabContent(vendorId: widget.vendorId);
  }

  Widget _buildSearchAndFilterBar() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search templates...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.isEmpty ? null : value;
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Filter Chips
          Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _activeFilter == null,
                onSelected: (selected) {
                  setState(() {
                    _activeFilter = selected ? null : _activeFilter;
                  });
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Active'),
                selected: _activeFilter == true,
                onSelected: (selected) {
                  setState(() {
                    _activeFilter = selected ? true : null;
                  });
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Inactive'),
                selected: _activeFilter == false,
                onSelected: (selected) {
                  setState(() {
                    _activeFilter = selected ? false : null;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.layers_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Templates Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create reusable customization templates to streamline your menu management.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            GEButton.primary(
              text: 'Create First Template',
              onPressed: () => _navigateToCreateTemplate(),
              icon: Icons.add,
            ),
          ],
        ),
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
              'Error Loading Templates',
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
            const SizedBox(height: 24),
            GEButton.secondary(
              text: 'Retry',
              onPressed: () => _refreshData(),
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateTemplate() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TemplateFormScreen(vendorId: widget.vendorId),
      ),
    ).then((result) {
      if (result == true) {
        _refreshData();
      }
    });
  }

  void _navigateToEditTemplate(String templateId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TemplateFormScreen(
          vendorId: widget.vendorId,
          templateId: templateId,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _refreshData();
      }
    });
  }

  void _duplicateTemplate(template) {
    // TODO: Implement template duplication
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template duplication coming soon')),
    );
  }

  void _toggleTemplateActive(template) {
    // TODO: Implement template active/inactive toggle
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Toggle template status coming soon')),
    );
  }

  void _showDeleteConfirmation(template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Are you sure you want to delete "${template.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTemplate(template.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteTemplate(String templateId) {
    final notifier = ref.read(templateManagementProvider.notifier);
    notifier.deleteTemplate(templateId).then((success) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete template')),
        );
      }
    });
  }

  void _refreshData() {
    ref.invalidate(vendorTemplatesProvider);
  }
}
