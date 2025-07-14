import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/menu_service.dart';
import '../../widgets/vendor/menu_export_dialog.dart';
import '../../widgets/vendor/menu_import_dialog.dart';
import '../../widgets/vendor/category_management_interface.dart';
import '../../widgets/vendor/category_dialogs.dart';

// Provider for menu service (keeping for categories)
final menuServiceProvider = Provider<MenuService>((ref) => MenuService());

// Provider for menu statistics
final vendorMenuStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, vendorId) async {
  final menuService = ref.read(menuServiceProvider);
  return await menuService.getVendorMenuStats(vendorId);
});

class MenuManagementScreen extends ConsumerStatefulWidget {
  final String vendorId;

  const MenuManagementScreen({
    super.key,
    required this.vendorId,
  });

  @override
  ConsumerState<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {

  @override
  Widget build(BuildContext context) {

    final menuStatsAsync = ref.watch(vendorMenuStatsProvider(widget.vendorId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              debugPrint('🏷️ [CATEGORY-MANAGEMENT] Overflow menu item selected: $value');
              switch (value) {
                case 'add_category':
                  _showAddCategoryDialog();
                  break;
                case 'import_menu':
                  _showImportMenuDialog();
                  break;
                case 'export_menu':
                  _showExportMenuDialog();
                  break;
              }
            },
            itemBuilder: (context) {
              debugPrint('🏷️ [CATEGORY-MANAGEMENT] Building overflow menu items');
              return _buildOverflowMenuItems();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Summary Card
          menuStatsAsync.when(
            data: (stats) => _buildStatsCard(stats),
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
          ),
          
          // Category Management Content
          Expanded(
            child: _buildCategoriesTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> stats) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Total Items',
              '${stats['totalItems']}',
              Icons.restaurant_menu,
              Colors.blue,
            ),
            _buildStatItem(
              'Categories',
              '${stats['totalCategories']}',
              Icons.category,
              Colors.green,
            ),
            _buildStatItem(
              'Available',
              '${stats['availableItems']}',
              Icons.check_circle,
              Colors.orange,
            ),
            _buildStatItem(
              'Halal Items',
              '${stats['halalItems']}',
              Icons.verified,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }







  Widget _buildCategoriesTab() {
    debugPrint('🏷️ [MENU-MANAGEMENT] Building categories tab with comprehensive interface');
    return CategoryManagementInterface(vendorId: widget.vendorId);
  }





  /// Show export menu dialog
  void _showExportMenuDialog() {
    debugPrint('🍽️ [MENU-MANAGEMENT] Showing export dialog for vendor: ${widget.vendorId}');

    showDialog(
      context: context,
      builder: (context) => MenuExportDialog(
        vendorId: widget.vendorId,
        vendorName: 'Current Vendor', // TODO: Get actual vendor name
        onExportComplete: (result) {
          debugPrint('🍽️ [MENU-MANAGEMENT] Export completed: ${result.fileName}');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result.isSuccessful
                    ? 'Menu exported successfully! ${result.totalItems} items exported.'
                    : 'Export failed: ${result.errorMessage}',
                ),
                backgroundColor: result.isSuccessful ? Colors.green : Colors.red,
                action: result.isSuccessful ? SnackBarAction(
                  label: 'Share',
                  onPressed: () {
                    // TODO: Implement sharing through provider
                    debugPrint('🍽️ [MENU-MANAGEMENT] Share export file: ${result.filePath}');
                  },
                ) : null,
              ),
            );
          }
        },
      ),
    );
  }

  /// Show import menu dialog
  void _showImportMenuDialog() {
    debugPrint('🍽️ [MENU-MANAGEMENT] Showing import dialog for vendor: ${widget.vendorId}');

    showDialog(
      context: context,
      builder: (context) => MenuImportDialog(
        vendorId: widget.vendorId,
        onImportComplete: (result) {
          debugPrint('🍽️ [MENU-MANAGEMENT] Import completed: ${result.fileName}');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result.isSuccessful
                    ? 'Menu imported successfully! ${result.importedRows} items imported.'
                    : 'Import failed: ${result.errorMessage}',
                ),
                backgroundColor: result.isSuccessful ? Colors.green : Colors.red,
              ),
            );

            // Refresh menu data after successful import
            if (result.isSuccessful) {
              ref.invalidate(vendorMenuStatsProvider(widget.vendorId));
            }
          }
        },
      ),
    );
  }

  /// Build overflow menu items for category management
  List<PopupMenuEntry<String>> _buildOverflowMenuItems() {
    return [
      const PopupMenuItem(
        value: 'add_category',
        child: ListTile(
          leading: Icon(Icons.add),
          title: Text('Add Category'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
      const PopupMenuDivider(),
      const PopupMenuItem(
        value: 'import_menu',
        child: ListTile(
          leading: Icon(Icons.upload),
          title: Text('Import Menu'),
          subtitle: Text('Upload menu items from CSV or JSON'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
      const PopupMenuItem(
        value: 'export_menu',
        child: ListTile(
          leading: Icon(Icons.download),
          title: Text('Export Menu'),
          subtitle: Text('Download your menu data'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    ];
  }

  /// Show add category dialog
  void _showAddCategoryDialog() {
    debugPrint('🏷️ [MENU-MANAGEMENT] Adding new category');
    showDialog(
      context: context,
      builder: (context) => CategoryFormDialog(
        vendorId: widget.vendorId,
        onCategoryCreated: (newCategory) {
          debugPrint('🏷️ [MENU-MANAGEMENT] Category created: ${newCategory.name}');
        },
      ),
    );
  }
}
