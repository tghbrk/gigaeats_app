import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/menu_export_import.dart';
import '../../providers/menu_import_export_providers.dart';

/// Dialog for importing menu data with file picker and conflict resolution
class MenuImportDialog extends ConsumerStatefulWidget {
  final String vendorId;
  final Function(MenuImportResult) onImportComplete;

  const MenuImportDialog({
    super.key,
    required this.vendorId,
    required this.onImportComplete,
  });

  @override
  ConsumerState<MenuImportDialog> createState() => _MenuImportDialogState();
}

class _MenuImportDialogState extends ConsumerState<MenuImportDialog> {
  ImportConflictResolution _conflictResolution = ImportConflictResolution.skip;
  bool _isImporting = false;
  ImportStatus? _currentStatus;
  String? _selectedFileName;
  String? _errorMessage;
  MenuImportResult? _previewResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.upload,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Text('Import Menu'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isImporting) ...[
              _buildProgressSection(),
            ] else if (_previewResult != null) ...[
              _buildPreviewSection(),
            ] else ...[
              _buildFileSelectionSection(),
              const SizedBox(height: 24),
              _buildConflictResolutionSection(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                _buildErrorSection(),
              ],
            ],
          ],
        ),
      ),
      actions: [
        if (!_isImporting) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (_previewResult != null) ...[
            TextButton(
              onPressed: () {
                setState(() {
                  _previewResult = null;
                  _selectedFileName = null;
                });
              },
              child: const Text('Back'),
            ),
            FilledButton.icon(
              onPressed: _startImport,
              icon: const Icon(Icons.upload),
              label: const Text('Import'),
            ),
          ] else ...[
            FilledButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.file_upload),
              label: const Text('Select File'),
            ),
          ],
        ] else ...[
          TextButton(
            onPressed: _currentStatus == ImportStatus.completed || _currentStatus == ImportStatus.failed
                ? () => Navigator.of(context).pop()
                : null,
            child: Text(_currentStatus == ImportStatus.completed ? 'Done' : 'Close'),
          ),
        ],
      ],
    );
  }

  Widget _buildFileSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select File',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).dividerColor,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                _selectedFileName ?? 'No file selected',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Supported formats: JSON, CSV, Excel (.xlsx, .xls)',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConflictResolutionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conflict Resolution',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'How should existing menu items be handled?',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        ...ImportConflictResolution.values.map((resolution) => RadioListTile<ImportConflictResolution>(
          title: Text(resolution.displayName),
          subtitle: Text(_getResolutionDescription(resolution)),
          value: resolution,
          groupValue: _conflictResolution,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _conflictResolution = value;
              });
            }
          },
          contentPadding: EdgeInsets.zero,
        )),
      ],
    );
  }

  Widget _buildPreviewSection() {
    final result = _previewResult!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Import Preview',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        
        // Summary cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Items',
                result.totalRows.toString(),
                Icons.restaurant_menu,
                colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                'Valid',
                result.validRows.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                'Errors',
                result.errorRows.toString(),
                Icons.error,
                Colors.red,
              ),
            ),
          ],
        ),
        
        if (result.hasErrors || result.hasWarnings) ...[
          const SizedBox(height: 16),
          _buildValidationIssues(result),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
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
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildValidationIssues(MenuImportResult result) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.hasErrors) ...[
              Text(
                'Errors (${result.errors.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              ...result.errors.take(5).map((error) => _buildValidationItem(error, true)),
              if (result.errors.length > 5)
                Text(
                  '... and ${result.errors.length - 5} more errors',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
            if (result.hasWarnings) ...[
              if (result.hasErrors) const SizedBox(height: 16),
              Text(
                'Warnings (${result.warnings.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              ...result.warnings.take(3).map((warning) => _buildValidationItem(warning, false)),
              if (result.warnings.length > 3)
                Text(
                  '... and ${result.warnings.length - 3} more warnings',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildValidationItem(ImportValidationError item, bool isError) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error : Icons.warning,
            size: 16,
            color: isError ? Colors.red : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Row ${item.row}: ${item.message}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        if (_currentStatus != null) ...[
          Row(
            children: [
              if (_currentStatus == ImportStatus.completed)
                Icon(Icons.check_circle, color: colorScheme.primary)
              else if (_currentStatus == ImportStatus.failed)
                Icon(Icons.error, color: colorScheme.error)
              else
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _currentStatus!.displayName,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (_currentStatus != ImportStatus.completed && _currentStatus != ImportStatus.failed)
          LinearProgressIndicator(
            color: colorScheme.primary,
            backgroundColor: colorScheme.surfaceContainerHighest,
          ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          _buildErrorSection(),
        ],
      ],
    );
  }

  Widget _buildErrorSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getResolutionDescription(ImportConflictResolution resolution) {
    switch (resolution) {
      case ImportConflictResolution.skip:
        return 'Keep existing items, only add new ones';
      case ImportConflictResolution.update:
        return 'Update existing items with new data';
      case ImportConflictResolution.replace:
        return 'Replace existing items completely';
    }
  }

  Future<void> _pickFile() async {
    try {
      debugPrint('🍽️ [IMPORT-UI] Picking file for vendor: ${widget.vendorId}');

      final importNotifier = ref.read(menuImportProvider.notifier);
      final result = await importNotifier.pickAndProcessFile(
        vendorId: widget.vendorId,
        conflictResolution: _conflictResolution,
      );

      if (result != null) {
        setState(() {
          _selectedFileName = result.fileName;
          _previewResult = result;
          _errorMessage = null;
        });
      }

    } catch (e) {
      debugPrint('❌ [IMPORT-UI] File picking failed: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _startImport() async {
    if (_previewResult == null) return;

    setState(() {
      _isImporting = true;
      _currentStatus = ImportStatus.importing;
      _errorMessage = null;
    });

    try {
      debugPrint('🍽️ [IMPORT-UI] Starting import for vendor: ${widget.vendorId}');

      // The import was already processed during file picking, so we just need to complete it
      final completedResult = _previewResult!.copyWith(
        status: ImportStatus.completed,
        importedRows: _previewResult!.validRows,
        completedAt: DateTime.now(),
      );

      setState(() {
        _currentStatus = ImportStatus.completed;
        _isImporting = false;
      });

      widget.onImportComplete(completedResult);

    } catch (e) {
      debugPrint('❌ [IMPORT-UI] Import failed: $e');
      setState(() {
        _currentStatus = ImportStatus.failed;
        _errorMessage = e.toString();
        _isImporting = false;
      });
    }
  }
}

extension on MenuImportResult {
  MenuImportResult copyWith({
    String? id,
    String? vendorId,
    String? fileName,
    ImportStatus? status,
    int? totalRows,
    int? validRows,
    int? importedRows,
    int? skippedRows,
    int? errorRows,
    List<ImportValidationError>? errors,
    List<ImportValidationError>? warnings,
    ImportConflictResolution? conflictResolution,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return MenuImportResult(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      fileName: fileName ?? this.fileName,
      status: status ?? this.status,
      totalRows: totalRows ?? this.totalRows,
      validRows: validRows ?? this.validRows,
      importedRows: importedRows ?? this.importedRows,
      skippedRows: skippedRows ?? this.skippedRows,
      errorRows: errorRows ?? this.errorRows,
      errors: errors ?? this.errors,
      warnings: warnings ?? this.warnings,
      conflictResolution: conflictResolution ?? this.conflictResolution,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }
}
