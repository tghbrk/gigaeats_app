import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/menu_import_data.dart';
import '../../data/services/menu_bulk_import_service.dart';
import '../widgets/import_preview_item_card.dart';
import '../widgets/import_summary_card.dart';

/// Screen for previewing and confirming bulk import
class ImportPreviewScreen extends ConsumerStatefulWidget {
  final MenuImportResult importResult;

  const ImportPreviewScreen({
    super.key,
    required this.importResult,
  });

  @override
  ConsumerState<ImportPreviewScreen> createState() => _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends ConsumerState<ImportPreviewScreen> {
  final MenuBulkImportService _bulkImportService = MenuBulkImportService();
  
  bool _isImporting = false;
  String _selectedFilter = 'all';
  
  List<MenuImportRow> get _filteredRows {
    switch (_selectedFilter) {
      case 'valid':
        return widget.importResult.rows.where((row) => row.isValid).toList();
      case 'errors':
        return widget.importResult.rows.where((row) => row.hasErrors).toList();
      case 'warnings':
        return widget.importResult.rows.where((row) => row.hasWarnings && !row.hasErrors).toList();
      default:
        return widget.importResult.rows;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Preview'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          if (!_isImporting)
            TextButton.icon(
              onPressed: widget.importResult.canProceed ? _performImport : null,
              icon: const Icon(Icons.upload),
              label: const Text('Import'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Summary card
          ImportSummaryCard(
            importResult: widget.importResult,
            selectedFilter: _selectedFilter,
            onFilterChanged: (filter) {
              setState(() => _selectedFilter = filter);
            },
          ),
          
          // Items list
          Expanded(
            child: _isImporting 
                ? _buildImportingState()
                : _buildItemsList(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  /// Build importing state
  Widget _buildImportingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Importing menu items...'),
          SizedBox(height: 8),
          Text(
            'This may take a few moments',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Build items list
  Widget _buildItemsList() {
    final filteredRows = _filteredRows;
    
    if (filteredRows.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No items match the current filter',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredRows.length,
      itemBuilder: (context, index) {
        final row = filteredRows[index];
        return ImportPreviewItemCard(
          importRow: row,
          onTap: () => _showItemDetails(row),
        );
      },
    );
  }

  /// Build bottom bar with import button
  Widget _buildBottomBar() {
    if (_isImporting) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.importResult.validRows} valid items ready to import',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.importResult.hasErrors)
                    Text(
                      '${widget.importResult.errorRows} items have errors and will be skipped',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: widget.importResult.canProceed ? _performImport : null,
              icon: const Icon(Icons.upload),
              label: const Text('Import Menu'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show detailed item information
  void _showItemDetails(MenuImportRow row) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Item Details - Row ${row.rowNumber}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Name', row.name),
                _buildDetailRow('Description', row.description ?? 'Not provided'),
                _buildDetailRow('Category', row.category),
                _buildDetailRow('Base Price', 'RM ${row.basePrice.toStringAsFixed(2)}'),
                _buildDetailRow('Unit', row.unit ?? 'pax'),
                
                if (row.minOrderQuantity != null)
                  _buildDetailRow('Min Order Qty', row.minOrderQuantity.toString()),
                if (row.maxOrderQuantity != null)
                  _buildDetailRow('Max Order Qty', row.maxOrderQuantity.toString()),
                if (row.preparationTimeMinutes != null)
                  _buildDetailRow('Prep Time', '${row.preparationTimeMinutes} minutes'),
                
                _buildDetailRow('Available', row.isAvailable == true ? 'Yes' : 'No'),
                _buildDetailRow('Halal', row.isHalal == true ? 'Yes' : 'No'),
                _buildDetailRow('Vegetarian', row.isVegetarian == true ? 'Yes' : 'No'),
                _buildDetailRow('Vegan', row.isVegan == true ? 'Yes' : 'No'),
                _buildDetailRow('Spicy', row.isSpicy == true ? 'Yes' : 'No'),
                
                if (row.spicyLevel != null)
                  _buildDetailRow('Spicy Level', row.spicyLevel.toString()),
                if (row.allergens != null)
                  _buildDetailRow('Allergens', row.allergens!),
                if (row.tags != null)
                  _buildDetailRow('Tags', row.tags!),
                
                if (row.bulkPrice != null)
                  _buildDetailRow('Bulk Price', 'RM ${row.bulkPrice!.toStringAsFixed(2)}'),
                if (row.bulkMinQuantity != null)
                  _buildDetailRow('Bulk Min Qty', row.bulkMinQuantity.toString()),
                
                if (row.hasErrors) ...[
                  const SizedBox(height: 16),
                  const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  ...row.errors.map((error) => Text('• $error', style: const TextStyle(color: Colors.red))),
                ],
                
                if (row.hasWarnings) ...[
                  const SizedBox(height: 16),
                  const Text('Warnings:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  ...row.warnings.map((warning) => Text('• $warning', style: const TextStyle(color: Colors.orange))),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /// Perform the actual import
  Future<void> _performImport() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Import'),
        content: Text(
          'Are you sure you want to import ${widget.importResult.validRows} menu items?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isImporting = true);
      
      await _bulkImportService.importMenuItems(widget.importResult);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported ${widget.importResult.validRows} menu items'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Return to previous screen with success flag
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
