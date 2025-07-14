import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/menu_export_import.dart';
import '../../providers/menu_import_export_providers.dart';

/// Dialog for exporting menu data with format selection and progress tracking
class MenuExportDialog extends ConsumerStatefulWidget {
  final String vendorId;
  final String vendorName;
  final Function(MenuExportResult) onExportComplete;

  const MenuExportDialog({
    super.key,
    required this.vendorId,
    required this.vendorName,
    required this.onExportComplete,
  });

  @override
  ConsumerState<MenuExportDialog> createState() => _MenuExportDialogState();
}

class _MenuExportDialogState extends ConsumerState<MenuExportDialog> {
  ExportFormat _selectedFormat = ExportFormat.csv;
  bool _includeInactiveItems = false;
  bool _userFriendlyFormat = true; // Default to user-friendly format
  final List<String> _selectedCategories = [];
  bool _isExporting = false;
  ExportStatus? _currentStatus;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    debugPrint('🍽️ [MENU-EXPORT-DIALOG] Building dialog for vendor: ${widget.vendorId}');

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final exportState = ref.watch(menuExportProvider);

    debugPrint('🍽️ [MENU-EXPORT-DIALOG] Export state: isExporting=${exportState.isExporting}, status=${exportState.status}');

    // Update local state based on provider state
    if (exportState.isExporting && !_isExporting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _isExporting = true;
          _currentStatus = exportState.status;
        });
      });
    } else if (!exportState.isExporting && _isExporting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _isExporting = false;
          _currentStatus = exportState.status;
          _errorMessage = exportState.errorMessage;
        });
      });
    }

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.download,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Text('Export Menu'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isExporting) ...[
              _buildProgressSection(),
            ] else ...[
              _buildFormatSelection(),
              const SizedBox(height: 24),
              _buildOptionsSection(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                _buildErrorSection(),
              ],
            ],
          ],
        ),
      ),
      actions: [
        if (!_isExporting) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: _startExport,
            icon: const Icon(Icons.download),
            label: const Text('Export'),
          ),
        ] else ...[
          TextButton(
            onPressed: _currentStatus == ExportStatus.completed || _currentStatus == ExportStatus.failed
                ? () => Navigator.of(context).pop()
                : null,
            child: Text(_currentStatus == ExportStatus.completed ? 'Done' : 'Close'),
          ),
        ],
      ],
    );
  }

  Widget _buildFormatSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export Format',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ...ExportFormat.values.map((format) => RadioListTile<ExportFormat>(
          title: Text(format.displayName),
          subtitle: Text(_getFormatDescription(format)),
          value: format,
          groupValue: _selectedFormat,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedFormat = value;
              });
            }
          },
          contentPadding: EdgeInsets.zero,
        )),
      ],
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export Options',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          title: const Text('Include inactive items'),
          subtitle: const Text('Export items that are currently unavailable'),
          value: _includeInactiveItems,
          onChanged: (value) {
            setState(() {
              _includeInactiveItems = value ?? false;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        if (_selectedFormat == ExportFormat.csv) ...[
          CheckboxListTile(
            title: const Text('User-friendly format'),
            subtitle: const Text('Simplified CSV format for easy editing (recommended)'),
            value: _userFriendlyFormat,
            onChanged: (value) {
              setState(() {
                _userFriendlyFormat = value ?? false;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Categories',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _selectedCategories.isEmpty
                ? 'All categories will be exported'
                : 'Selected: ${_selectedCategories.join(', ')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
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
              if (_currentStatus == ExportStatus.completed)
                Icon(Icons.check_circle, color: colorScheme.primary)
              else if (_currentStatus == ExportStatus.failed)
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
        if (_currentStatus != ExportStatus.completed && _currentStatus != ExportStatus.failed)
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

  String _getFormatDescription(ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        return 'Complete data with customizations (for system backup)';
      case ExportFormat.csv:
        return _userFriendlyFormat
          ? 'Simplified spreadsheet format for easy editing (recommended)'
          : 'Technical spreadsheet format with all system data';
    }
  }

  Future<void> _startExport() async {
    setState(() {
      _isExporting = true;
      _currentStatus = ExportStatus.preparing;
      _errorMessage = null;
    });

    try {
      debugPrint('🍽️ [EXPORT-UI] Starting export for vendor: ${widget.vendorId}');

      final exportNotifier = ref.read(menuExportProvider.notifier);
      final result = await exportNotifier.exportMenu(
        vendorId: widget.vendorId,
        vendorName: widget.vendorName,
        format: _selectedFormat,
        includeInactiveItems: _includeInactiveItems,
        categoryFilter: _selectedCategories.isEmpty ? null : _selectedCategories,
        userFriendlyFormat: _userFriendlyFormat,
      );

      if (result != null) {
        setState(() {
          _currentStatus = result.status;
          _isExporting = false;
        });

        widget.onExportComplete(result);
      }

    } catch (e) {
      debugPrint('❌ [EXPORT-UI] Export failed: $e');
      setState(() {
        _currentStatus = ExportStatus.failed;
        _errorMessage = e.toString();
        _isExporting = false;
      });
    }
  }
}
