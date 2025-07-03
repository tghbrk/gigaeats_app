import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';

import '../../data/models/driver_earnings.dart';
import '../providers/driver_earnings_provider.dart';

/// Export format options
enum ExportFormat {
  pdf('PDF', 'pdf', Icons.picture_as_pdf),
  csv('CSV', 'csv', Icons.table_chart),
  excel('Excel', 'xlsx', Icons.grid_on);

  const ExportFormat(this.displayName, this.extension, this.icon);
  final String displayName;
  final String extension;
  final IconData icon;
}

/// Date range options for export
enum ExportDateRange {
  thisWeek('This Week'),
  thisMonth('This Month'),
  lastMonth('Last Month'),
  last3Months('Last 3 Months'),
  custom('Custom Range');

  const ExportDateRange(this.displayName);
  final String displayName;
}

/// Earnings export widget with PDF/CSV export capabilities
class EarningsExportWidget extends ConsumerStatefulWidget {
  final String driverId;
  final VoidCallback? onExportComplete;

  const EarningsExportWidget({
    super.key,
    required this.driverId,
    this.onExportComplete,
  });

  @override
  ConsumerState<EarningsExportWidget> createState() => _EarningsExportWidgetState();
}

class _EarningsExportWidgetState extends ConsumerState<EarningsExportWidget> {
  ExportFormat _selectedFormat = ExportFormat.pdf;
  ExportDateRange _selectedDateRange = ExportDateRange.thisMonth;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _isExporting = false;
  bool _includeCharts = true;
  bool _includeSummary = true;
  bool _includeBreakdown = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.file_download,
                  size: 28,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Export Earnings Report',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Export format selection
            Text(
              'Export Format',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: ExportFormat.values.map((format) {
                final isSelected = _selectedFormat == format;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedFormat = format),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.1)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withValues(alpha: 0.2),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              format.icon,
                              size: 32,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              format.displayName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Date range selection
            Text(
              'Date Range',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExportDateRange>(
              value: _selectedDateRange,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: ExportDateRange.values.map((range) {
                return DropdownMenuItem(
                  value: range,
                  child: Text(range.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedDateRange = value;
                    if (value != ExportDateRange.custom) {
                      _customStartDate = null;
                      _customEndDate = null;
                    }
                  });
                }
              },
            ),

            // Custom date range picker
            if (_selectedDateRange == ExportDateRange.custom) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectCustomDate(true),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _customStartDate != null
                            ? _formatDate(_customStartDate!)
                            : 'Start Date',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectCustomDate(false),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _customEndDate != null
                            ? _formatDate(_customEndDate!)
                            : 'End Date',
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Export options (only for PDF)
            if (_selectedFormat == ExportFormat.pdf) ...[
              Text(
                'Include in Report',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('Summary Statistics'),
                subtitle: const Text('Total earnings, deliveries, and averages'),
                value: _includeSummary,
                onChanged: (value) => setState(() => _includeSummary = value ?? true),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Earnings Breakdown'),
                subtitle: const Text('Detailed breakdown by type and date'),
                value: _includeBreakdown,
                onChanged: (value) => setState(() => _includeBreakdown = value ?? true),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Charts & Graphs'),
                subtitle: const Text('Visual representation of earnings data'),
                value: _includeCharts,
                onChanged: (value) => setState(() => _includeCharts = value ?? true),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
            ],

            // Export button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportEarnings,
                icon: _isExporting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : Icon(_selectedFormat.icon),
                label: Text(
                  _isExporting
                      ? 'Exporting...'
                      : 'Export ${_selectedFormat.displayName}',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Select custom date range
  Future<void> _selectCustomDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_customStartDate ?? DateTime.now().subtract(const Duration(days: 30)))
          : (_customEndDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _customStartDate = picked;
        } else {
          _customEndDate = picked;
        }
      });
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Get date range based on selection
  Map<String, DateTime?> _getDateRange() {
    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate = now;

    switch (_selectedDateRange) {
      case ExportDateRange.thisWeek:
        final weekday = now.weekday;
        startDate = now.subtract(Duration(days: weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case ExportDateRange.thisMonth:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case ExportDateRange.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        startDate = lastMonth;
        endDate = DateTime(now.year, now.month, 1).subtract(const Duration(days: 1));
        break;
      case ExportDateRange.last3Months:
        startDate = DateTime(now.year, now.month - 3, 1);
        break;
      case ExportDateRange.custom:
        startDate = _customStartDate;
        endDate = _customEndDate;
        break;
    }

    return {
      'startDate': startDate,
      'endDate': endDate,
    };
  }

  /// Export earnings data
  Future<void> _exportEarnings() async {
    if (_selectedDateRange == ExportDateRange.custom &&
        (_customStartDate == null || _customEndDate == null)) {
      _showErrorSnackBar('Please select both start and end dates for custom range');
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final dateRange = _getDateRange();

      // Create stable earnings parameters for data export
      final stableKey = 'export_${dateRange['startDate']?.millisecondsSinceEpoch ?? 0}_${dateRange['endDate']?.millisecondsSinceEpoch ?? 0}';

      final earningsParams = EarningsParams(
        driverId: widget.driverId,
        startDate: dateRange['startDate'],
        endDate: dateRange['endDate'],
        period: _selectedDateRange.name,
        stableKey: stableKey,
      );

      final earningsAsync = ref.read(driverEarningsStreamProvider.future);
      final summaryAsync = ref.read(driverEarningsSummaryProvider(earningsParams).future);

      final earnings = await earningsAsync;
      final summary = await summaryAsync;

      // Filter earnings by date range if needed
      final filteredEarnings = _filterEarningsByDateRange(earnings, dateRange);

      if (filteredEarnings.isEmpty) {
        _showErrorSnackBar('No earnings data found for the selected date range');
        return;
      }

      String filePath;
      switch (_selectedFormat) {
        case ExportFormat.pdf:
          filePath = await _generatePDF(filteredEarnings, summary, dateRange);
          break;
        case ExportFormat.csv:
          filePath = await _generateCSV(filteredEarnings, dateRange);
          break;
        case ExportFormat.excel:
          filePath = await _generateExcel(filteredEarnings, summary, dateRange);
          break;
      }

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Earnings Report - ${_selectedDateRange.displayName}',
        subject: 'GigaEats Driver Earnings Report',
      );

      _showSuccessSnackBar('Report exported successfully!');
      widget.onExportComplete?.call();

    } catch (e) {
      _showErrorSnackBar('Export failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  /// Filter earnings by date range
  List<DriverEarnings> _filterEarningsByDateRange(
    List<DriverEarnings> earnings,
    Map<String, DateTime?> dateRange,
  ) {
    final startDate = dateRange['startDate'];
    final endDate = dateRange['endDate'];

    return earnings.where((earning) {
      if (startDate != null && earning.createdAt.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && earning.createdAt.isAfter(endDate.add(const Duration(days: 1)))) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Generate PDF report
  Future<String> _generatePDF(
    List<DriverEarnings> earnings,
    Map<String, dynamic> summary,
    Map<String, DateTime?> dateRange,
  ) async {
    final pdf = pw.Document();

    // Add pages to PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            _buildPDFHeader(dateRange),
            pw.SizedBox(height: 20),

            // Summary section
            if (_includeSummary) ...[
              _buildPDFSummary(summary),
              pw.SizedBox(height: 20),
            ],

            // Breakdown section
            if (_includeBreakdown) ...[
              _buildPDFBreakdown(earnings),
              pw.SizedBox(height: 20),
            ],

            // Detailed earnings table
            _buildPDFEarningsTable(earnings),
          ];
        },
      ),
    );

    // Save PDF to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'earnings_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fileName');

    final pdfBytes = await pdf.save();
    await file.writeAsBytes(pdfBytes);

    return file.path;
  }

  /// Build PDF header
  pw.Widget _buildPDFHeader(Map<String, DateTime?> dateRange) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'GigaEats Driver Earnings Report',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Period: ${_selectedDateRange.displayName}',
          style: pw.TextStyle(fontSize: 16),
        ),
        if (dateRange['startDate'] != null && dateRange['endDate'] != null) ...[
          pw.Text(
            'From: ${_formatDate(dateRange['startDate']!)} To: ${_formatDate(dateRange['endDate']!)}',
            style: pw.TextStyle(fontSize: 14),
          ),
        ],
        pw.Text(
          'Generated: ${_formatDate(DateTime.now())} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
        ),
        pw.Divider(thickness: 2),
      ],
    );
  }

  /// Build PDF summary section
  pw.Widget _buildPDFSummary(Map<String, dynamic> summary) {
    final totalEarnings = (summary['total_net_earnings'] as double?) ?? 0.0;
    final totalDeliveries = (summary['total_deliveries'] as int?) ?? 0;
    final avgPerDelivery = (summary['average_earnings_per_delivery'] as double?) ?? 0.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Summary',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _buildPDFSummaryCard('Total Earnings', 'RM ${totalEarnings.toStringAsFixed(2)}'),
            _buildPDFSummaryCard('Total Deliveries', totalDeliveries.toString()),
            _buildPDFSummaryCard('Avg per Delivery', 'RM ${avgPerDelivery.toStringAsFixed(2)}'),
          ],
        ),
      ],
    );
  }

  /// Build PDF summary card
  pw.Widget _buildPDFSummaryCard(String title, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Build PDF breakdown section
  pw.Widget _buildPDFBreakdown(List<DriverEarnings> earnings) {
    // Calculate breakdown by type
    final Map<EarningsType, double> breakdown = {};
    for (final earning in earnings) {
      breakdown[earning.earningsType] =
          (breakdown[earning.earningsType] ?? 0) + earning.netAmount;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Earnings Breakdown',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'Type',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'Amount (RM)',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
            ...breakdown.entries.map((entry) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(_getEarningsTypeDisplayName(entry.key)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    entry.value.toStringAsFixed(2),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            )),
          ],
        ),
      ],
    );
  }

  /// Build PDF earnings table
  pw.Widget _buildPDFEarningsTable(List<DriverEarnings> earnings) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Detailed Earnings',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Date',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Type',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Gross (RM)',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Net (RM)',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Status',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                ),
              ],
            ),
            ...earnings.map((earning) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    _formatDate(earning.createdAt),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    _getEarningsTypeDisplayName(earning.earningsType),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    earning.amount.toStringAsFixed(2),
                    style: const pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    earning.netAmount.toStringAsFixed(2),
                    style: const pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    _getStatusDisplayName(earning.status),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
            )),
          ],
        ),
      ],
    );
  }

  /// Generate CSV report
  Future<String> _generateCSV(
    List<DriverEarnings> earnings,
    Map<String, DateTime?> dateRange,
  ) async {
    final List<List<String>> csvData = [
      // Header row
      ['Date', 'Type', 'Gross Amount (RM)', 'Platform Fee (RM)', 'Net Amount (RM)', 'Status', 'Description'],
      // Data rows
      ...earnings.map((earning) => [
        _formatDate(earning.createdAt),
        _getEarningsTypeDisplayName(earning.earningsType),
        earning.amount.toStringAsFixed(2),
        earning.platformFee.toStringAsFixed(2),
        earning.netAmount.toStringAsFixed(2),
        _getStatusDisplayName(earning.status),
        earning.description ?? '',
      ]),
    ];

    final csvString = const ListToCsvConverter().convert(csvData);

    // Save CSV to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'earnings_report_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${directory.path}/$fileName');

    await file.writeAsString(csvString);
    return file.path;
  }

  /// Generate Excel report (placeholder - would need excel package implementation)
  Future<String> _generateExcel(
    List<DriverEarnings> earnings,
    Map<String, dynamic> summary,
    Map<String, DateTime?> dateRange,
  ) async {
    // For now, generate CSV with .xlsx extension
    // In a real implementation, you would use the excel package
    return _generateCSV(earnings, dateRange);
  }

  /// Get earnings type display name
  String _getEarningsTypeDisplayName(EarningsType type) {
    switch (type) {
      case EarningsType.deliveryFee:
        return 'Delivery Fee';
      case EarningsType.tip:
        return 'Tip';
      case EarningsType.bonus:
        return 'Bonus';
      case EarningsType.commission:
        return 'Commission';
      case EarningsType.penalty:
        return 'Penalty';
    }
  }

  /// Get status display name
  String _getStatusDisplayName(EarningsStatus status) {
    switch (status) {
      case EarningsStatus.pending:
        return 'Pending';
      case EarningsStatus.confirmed:
        return 'Confirmed';
      case EarningsStatus.paid:
        return 'Paid';
      case EarningsStatus.disputed:
        return 'Disputed';
      case EarningsStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
