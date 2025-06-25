import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/wallet_analytics_provider.dart';
import '../../data/services/enhanced_analytics_export_service.dart';

/// Enhanced analytics export dialog with advanced options
class EnhancedAnalyticsExportDialog extends ConsumerStatefulWidget {
  const EnhancedAnalyticsExportDialog({super.key});

  @override
  ConsumerState<EnhancedAnalyticsExportDialog> createState() => _EnhancedAnalyticsExportDialogState();
}

class _EnhancedAnalyticsExportDialogState extends ConsumerState<EnhancedAnalyticsExportDialog> {
  String _selectedFormat = 'csv';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isExporting = false;
  
  // CSV options
  bool _includeTransactionDetails = true;
  bool _includeCategoryBreakdown = true;
  bool _includeVendorAnalysis = true;
  
  // PDF options
  bool _includeCharts = true;
  bool _includeInsights = true;
  bool _includeTransactionSummary = true;
  
  // Filtering options
  final List<String> _selectedCategories = [];
  final List<String> _selectedVendors = [];
  double? _minAmount;
  double? _maxAmount;
  
  // Sharing options
  bool _shareAfterExport = false;
  String? _recipientEmail;
  String? _customMessage;

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(walletAnalyticsProvider);
    
    if (!analyticsState.exportEnabled) {
      return _buildExportDisabledDialog(context);
    }

    return AlertDialog(
      title: const Text('Export Analytics Data'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Format selection
              _buildFormatSelection(),
              const SizedBox(height: 16),
              
              // Date range selection
              _buildDateRangeSelection(),
              const SizedBox(height: 16),
              
              // Format-specific options
              if (_selectedFormat == 'csv') _buildCsvOptions(),
              if (_selectedFormat == 'pdf') _buildPdfOptions(),
              const SizedBox(height: 16),
              
              // Filtering options
              _buildFilteringOptions(),
              const SizedBox(height: 16),
              
              // Sharing options
              _buildSharingOptions(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isExporting ? null : _exportData,
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

  Widget _buildExportDisabledDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Disabled'),
      content: const Text('Export functionality is disabled in your privacy settings. Enable it in wallet settings to export analytics data.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Navigate to settings
          },
          child: const Text('Settings'),
        ),
      ],
    );
  }

  Widget _buildFormatSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export Format',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'csv',
              label: Text('CSV Data'),
              icon: Icon(Icons.table_chart),
            ),
            ButtonSegment(
              value: 'pdf',
              label: Text('PDF Report'),
              icon: Icon(Icons.picture_as_pdf),
            ),
          ],
          selected: {_selectedFormat},
          onSelectionChanged: (Set<String> selection) {
            setState(() => _selectedFormat = selection.first);
          },
        ),
      ],
    );
  }

  Widget _buildDateRangeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectStartDate(),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _startDate != null
                      ? DateFormat('MMM dd, yyyy').format(_startDate!)
                      : 'Start Date',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectEndDate(),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _endDate != null
                      ? DateFormat('MMM dd, yyyy').format(_endDate!)
                      : 'End Date',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCsvOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CSV Options',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Transaction Details'),
          subtitle: const Text('Include individual transaction records'),
          value: _includeTransactionDetails,
          onChanged: (value) {
            setState(() => _includeTransactionDetails = value ?? true);
          },
          dense: true,
        ),
        CheckboxListTile(
          title: const Text('Category Breakdown'),
          subtitle: const Text('Include spending by category analysis'),
          value: _includeCategoryBreakdown,
          onChanged: (value) {
            setState(() => _includeCategoryBreakdown = value ?? true);
          },
          dense: true,
        ),
        CheckboxListTile(
          title: const Text('Vendor Analysis'),
          subtitle: const Text('Include vendor spending patterns'),
          value: _includeVendorAnalysis,
          onChanged: (value) {
            setState(() => _includeVendorAnalysis = value ?? true);
          },
          dense: true,
        ),
      ],
    );
  }

  Widget _buildPdfOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PDF Options',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Include Charts'),
          subtitle: const Text('Add visual charts and graphs'),
          value: _includeCharts,
          onChanged: (value) {
            setState(() => _includeCharts = value ?? true);
          },
          dense: true,
        ),
        CheckboxListTile(
          title: const Text('Include Insights'),
          subtitle: const Text('Add AI-powered insights and recommendations'),
          value: _includeInsights,
          onChanged: (value) {
            setState(() => _includeInsights = value ?? true);
          },
          dense: true,
        ),
        CheckboxListTile(
          title: const Text('Transaction Summary'),
          subtitle: const Text('Include detailed transaction summaries'),
          value: _includeTransactionSummary,
          onChanged: (value) {
            setState(() => _includeTransactionSummary = value ?? true);
          },
          dense: true,
        ),
      ],
    );
  }

  Widget _buildFilteringOptions() {
    return ExpansionTile(
      title: Text(
        'Advanced Filters',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Amount range
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Min Amount',
                        prefixText: 'RM ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _minAmount = double.tryParse(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Max Amount',
                        prefixText: 'RM ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _maxAmount = double.tryParse(value);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSharingOptions() {
    return ExpansionTile(
      title: Text(
        'Sharing Options',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CheckboxListTile(
                title: const Text('Share After Export'),
                subtitle: const Text('Open share dialog after export completes'),
                value: _shareAfterExport,
                onChanged: (value) {
                  setState(() => _shareAfterExport = value ?? false);
                },
                dense: true,
              ),
              if (_shareAfterExport) ...[
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Custom Message (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onChanged: (value) {
                    _customMessage = value.isEmpty ? null : value;
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);

    try {
      final enhancedExportService = ref.read(enhancedAnalyticsExportServiceProvider);
      
      final startDate = _startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final endDate = _endDate ?? DateTime.now();

      // Export based on format
      final result = _selectedFormat == 'pdf'
          ? await enhancedExportService.exportToPdfWithCharts(
              startDate: startDate,
              endDate: endDate,
              includeCharts: _includeCharts,
              includeInsights: _includeInsights,
              includeTransactionSummary: _includeTransactionSummary,
            )
          : await enhancedExportService.exportToCsvWithFilters(
              startDate: startDate,
              endDate: endDate,
              categories: _selectedCategories.isEmpty ? null : _selectedCategories,
              vendors: _selectedVendors.isEmpty ? null : _selectedVendors,
              minAmount: _minAmount,
              maxAmount: _maxAmount,
              includeTransactionDetails: _includeTransactionDetails,
              includeCategoryBreakdown: _includeCategoryBreakdown,
              includeVendorAnalysis: _includeVendorAnalysis,
            );

      await result.fold(
        (failure) async {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Export failed: ${failure.message}'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        (export) async {
          if (mounted) {
            Navigator.of(context).pop();
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Analytics exported: ${export.formattedFileSize}'),
                backgroundColor: AppTheme.successColor,
                action: SnackBarAction(
                  label: 'Share',
                  onPressed: () => _shareExport(export),
                ),
              ),
            );

            // Auto-share if requested
            if (_shareAfterExport) {
              await _shareExport(export);
            }
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _shareExport(dynamic export) async {
    final enhancedExportService = ref.read(enhancedAnalyticsExportServiceProvider);
    
    final shareResult = await enhancedExportService.shareExportWithOptions(
      export,
      customMessage: _customMessage,
      recipientEmail: _recipientEmail,
      includeMetadata: true,
    );
    
    shareResult.fold(
      (failure) => debugPrint('Share failed: ${failure.message}'),
      (_) => debugPrint('Export shared successfully'),
    );
  }
}

/// Provider for enhanced analytics export service
final enhancedAnalyticsExportServiceProvider = Provider<EnhancedAnalyticsExportService>((ref) {
  final repository = ref.watch(customerWalletAnalyticsRepositoryProvider);
  return EnhancedAnalyticsExportService(repository: repository);
});
