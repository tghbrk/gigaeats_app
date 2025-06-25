import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/menu_import_data.dart';
import '../../data/services/menu_import_service.dart';
import '../../data/services/menu_template_service.dart';
import '../widgets/import_file_picker.dart';
import '../widgets/import_instructions_card.dart';
import '../widgets/template_download_card.dart';
import 'import_preview_screen.dart';

/// Screen for bulk menu import functionality
class BulkMenuImportScreen extends ConsumerStatefulWidget {
  const BulkMenuImportScreen({super.key});

  @override
  ConsumerState<BulkMenuImportScreen> createState() => _BulkMenuImportScreenState();
}

class _BulkMenuImportScreenState extends ConsumerState<BulkMenuImportScreen> {
  final MenuImportService _importService = MenuImportService();
  final MenuTemplateService _templateService = MenuTemplateService();
  
  bool _isProcessing = false;
  MenuImportResult? _importResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Menu Import'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Import Your Menu',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload your complete menu catalog using CSV or Excel files. Save time by importing multiple items at once.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),

            // Template Download Section
            TemplateDownloadCard(
              onDownloadCsv: () => _downloadTemplate('csv'),
              onDownloadExcel: () => _downloadTemplate('excel'),
              onViewInstructions: _showInstructions,
            ),
            const SizedBox(height: 24),

            // File Upload Section
            ImportFilePickerCard(
              isProcessing: _isProcessing,
              onFileSelected: _processImportFile,
            ),
            const SizedBox(height: 24),

            // Instructions
            const ImportInstructionsCard(),
            
            // Import Result (if available)
            if (_importResult != null) ...[
              const SizedBox(height: 24),
              _buildImportResultCard(),
            ],
          ],
        ),
      ),
    );
  }

  /// Download template file
  Future<void> _downloadTemplate(String format) async {
    try {
      setState(() => _isProcessing = true);
      
      if (format == 'csv') {
        await _templateService.downloadCsvTemplate();
      } else {
        await _templateService.downloadExcelTemplate();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$format template downloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Show detailed instructions
  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Instructions'),
        content: SingleChildScrollView(
          child: Text(
            _templateService.getTemplateInstructions(),
            style: const TextStyle(fontFamily: 'monospace'),
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

  /// Process selected import file
  Future<void> _processImportFile() async {
    try {
      setState(() => _isProcessing = true);
      
      final result = await _importService.pickAndProcessFile();
      
      if (result != null) {
        setState(() => _importResult = result);
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'File processed: ${result.validRows}/${result.totalRows} valid items',
              ),
              backgroundColor: result.hasErrors ? Colors.orange : Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Build import result summary card
  Widget _buildImportResultCard() {
    final result = _importResult!;
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.hasErrors ? Icons.warning : Icons.check_circle,
                  color: result.hasErrors ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  'Import Results',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Statistics
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Items',
                    result.totalRows.toString(),
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Valid',
                    result.validRows.toString(),
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Errors',
                    result.errorRows.toString(),
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Warnings',
                    result.warningRows.toString(),
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Success rate
            LinearProgressIndicator(
              value: result.successRate,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                result.successRate >= 0.8 ? Colors.green : 
                result.successRate >= 0.5 ? Colors.orange : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Success Rate: ${(result.successRate * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.bodySmall,
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showImportDetails(result),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: result.canProceed ? () => _proceedToPreview(result) : null,
                    icon: const Icon(Icons.preview),
                    label: const Text('Preview & Import'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build statistic item
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Show detailed import results
  void _showImportDetails(MenuImportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Details'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('File: ${result.fileName}'),
                Text('Type: ${result.fileType}'),
                Text('Imported: ${result.importedAt}'),
                const SizedBox(height: 16),
                
                if (result.categories.isNotEmpty) ...[
                  const Text('Categories found:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...result.categories.map((cat) => Text('• $cat')),
                  const SizedBox(height: 16),
                ],
                
                // Show errors and warnings
                ...result.rows.where((row) => row.hasErrors || row.hasWarnings).map(
                  (row) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Row ${row.rowNumber}: ${row.name}'),
                          if (row.hasErrors) ...row.errors.map((error) => 
                            Text('❌ $error', style: const TextStyle(color: Colors.red))),
                          if (row.hasWarnings) ...row.warnings.map((warning) => 
                            Text('⚠️ $warning', style: const TextStyle(color: Colors.orange))),
                        ],
                      ),
                    ),
                  ),
                ),
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

  /// Proceed to preview screen
  void _proceedToPreview(MenuImportResult result) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImportPreviewScreen(importResult: result),
      ),
    ).then((imported) {
      if (imported == true && mounted) {
        // Import was successful, go back to menu management
        Navigator.of(context).pop(true);
      }
    });
  }
}
