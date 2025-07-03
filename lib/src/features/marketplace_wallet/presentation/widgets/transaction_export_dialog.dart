import 'package:flutter/material.dart';

/// Dialog for exporting transaction data
class TransactionExportDialog extends StatefulWidget {
  final VoidCallback onExport;

  const TransactionExportDialog({
    super.key,
    required this.onExport,
  });

  @override
  State<TransactionExportDialog> createState() => _TransactionExportDialogState();
}

class _TransactionExportDialogState extends State<TransactionExportDialog> {
  String _selectedFormat = 'csv';
  String _selectedPeriod = 'all';
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.download,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('Export Transactions'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose export options for your transaction history.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Export format selection
          Text(
            'Format',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          _buildFormatOptions(theme),
          
          const SizedBox(height: 20),
          
          // Time period selection
          Text(
            'Time Period',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          _buildPeriodOptions(theme),
          
          const SizedBox(height: 16),
          
          // Export info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Export will include transaction details, amounts, dates, and references.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isExporting ? null : _handleExport,
          child: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Export'),
        ),
      ],
    );
  }

  Widget _buildFormatOptions(ThemeData theme) {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text('CSV (Comma Separated Values)'),
          subtitle: const Text('Compatible with Excel and Google Sheets'),
          value: 'csv',
          groupValue: _selectedFormat,
          onChanged: (value) {
            setState(() {
              _selectedFormat = value!;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<String>(
          title: const Text('PDF Report'),
          subtitle: const Text('Formatted document for printing'),
          value: 'pdf',
          groupValue: _selectedFormat,
          onChanged: (value) {
            setState(() {
              _selectedFormat = value!;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildPeriodOptions(ThemeData theme) {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text('All Transactions'),
          subtitle: const Text('Complete transaction history'),
          value: 'all',
          groupValue: _selectedPeriod,
          onChanged: (value) {
            setState(() {
              _selectedPeriod = value!;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<String>(
          title: const Text('Last 30 Days'),
          subtitle: const Text('Recent transactions only'),
          value: '30_days',
          groupValue: _selectedPeriod,
          onChanged: (value) {
            setState(() {
              _selectedPeriod = value!;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<String>(
          title: const Text('Last 90 Days'),
          subtitle: const Text('Quarterly transactions'),
          value: '90_days',
          groupValue: _selectedPeriod,
          onChanged: (value) {
            setState(() {
              _selectedPeriod = value!;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<String>(
          title: const Text('Current Year'),
          subtitle: const Text('Year-to-date transactions'),
          value: 'current_year',
          groupValue: _selectedPeriod,
          onChanged: (value) {
            setState(() {
              _selectedPeriod = value!;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Future<void> _handleExport() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Simulate export process
      await Future.delayed(const Duration(seconds: 2));
      
      widget.onExport();
      
      if (mounted) {
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Transactions exported successfully as ${_selectedFormat.toUpperCase()}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Open exported file
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
