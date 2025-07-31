import 'package:flutter/material.dart';

/// Dialog for exporting driver wallet transaction data
class DriverTransactionExportDialog extends StatefulWidget {
  final Function(String format, String period) onExport;

  const DriverTransactionExportDialog({
    super.key,
    required this.onExport,
  });

  @override
  State<DriverTransactionExportDialog> createState() => _DriverTransactionExportDialogState();
}

class _DriverTransactionExportDialogState extends State<DriverTransactionExportDialog> {
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
          // Export format selection
          Text(
            'Export Format',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          _buildFormatOptions(theme),
          
          const SizedBox(height: 16),
          
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
                    'Export will include transaction details, amounts, dates, order references, and earnings breakdown.',
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
        ElevatedButton.icon(
          onPressed: _isExporting ? null : _handleExport,
          icon: _isExporting 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download),
          label: Text(_isExporting ? 'Exporting...' : 'Export'),
        ),
      ],
    );
  }

  Widget _buildFormatOptions(ThemeData theme) {
    return Column(
      children: [
        RadioListTile<String>(
          title: Row(
            children: [
              const Icon(Icons.table_chart, size: 20),
              const SizedBox(width: 8),
              const Text('CSV'),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Recommended',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          subtitle: const Text('Comma-separated values, compatible with Excel'),
          value: 'csv',
          groupValue: _selectedFormat,
          onChanged: (value) {
            setState(() {
              _selectedFormat = value!;
            });
          },
          dense: true,
        ),
        RadioListTile<String>(
          title: const Row(
            children: [
              Icon(Icons.code, size: 20),
              SizedBox(width: 8),
              Text('JSON'),
            ],
          ),
          subtitle: const Text('JavaScript Object Notation, for developers'),
          value: 'json',
          groupValue: _selectedFormat,
          onChanged: (value) {
            setState(() {
              _selectedFormat = value!;
            });
          },
          dense: true,
        ),
        RadioListTile<String>(
          title: const Row(
            children: [
              Icon(Icons.description, size: 20),
              SizedBox(width: 8),
              Text('PDF'),
            ],
          ),
          subtitle: const Text('Formatted report, ready for printing'),
          value: 'pdf',
          groupValue: _selectedFormat,
          onChanged: (value) {
            setState(() {
              _selectedFormat = value!;
            });
          },
          dense: true,
        ),
      ],
    );
  }

  Widget _buildPeriodOptions(ThemeData theme) {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text('All Transactions'),
          subtitle: const Text('Export complete transaction history'),
          value: 'all',
          groupValue: _selectedPeriod,
          onChanged: (value) {
            setState(() {
              _selectedPeriod = value!;
            });
          },
          dense: true,
        ),
        RadioListTile<String>(
          title: const Text('Last 30 Days'),
          subtitle: const Text('Export transactions from the last month'),
          value: '30days',
          groupValue: _selectedPeriod,
          onChanged: (value) {
            setState(() {
              _selectedPeriod = value!;
            });
          },
          dense: true,
        ),
        RadioListTile<String>(
          title: const Text('Last 90 Days'),
          subtitle: const Text('Export transactions from the last quarter'),
          value: '90days',
          groupValue: _selectedPeriod,
          onChanged: (value) {
            setState(() {
              _selectedPeriod = value!;
            });
          },
          dense: true,
        ),
        RadioListTile<String>(
          title: const Text('This Year'),
          subtitle: const Text('Export transactions from current year'),
          value: 'year',
          groupValue: _selectedPeriod,
          onChanged: (value) {
            setState(() {
              _selectedPeriod = value!;
            });
          },
          dense: true,
        ),
      ],
    );
  }

  Future<void> _handleExport() async {
    setState(() {
      _isExporting = true;
    });

    try {
      debugPrint('📤 [DRIVER-TRANSACTION-EXPORT] Starting export');
      debugPrint('📤 [DRIVER-TRANSACTION-EXPORT] Format: $_selectedFormat');
      debugPrint('📤 [DRIVER-TRANSACTION-EXPORT] Period: $_selectedPeriod');
      
      // Simulate export process
      await Future.delayed(const Duration(seconds: 2));

      widget.onExport(_selectedFormat, _selectedPeriod);
      
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
                debugPrint('📤 [DRIVER-TRANSACTION-EXPORT] View exported file requested');
                // TODO: Open exported file
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [DRIVER-TRANSACTION-EXPORT] Export failed: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Export failed. Please try again.'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
}
