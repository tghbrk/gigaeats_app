import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../data/models/admin_dashboard_stats.dart';
import '../../../user_management/domain/admin_user.dart';

/// Export options dialog
class ExportOptionsDialog extends ConsumerWidget {
  final String title;
  final List<String> availableFormats;
  final Function(String format, DateTimeRange? dateRange) onExport;

  const ExportOptionsDialog({
    super.key,
    required this.title,
    this.availableFormats = const ['CSV', 'Excel'],
    required this.onExport,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text('Export $title'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select export format:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          // Format selection
          ...availableFormats.map((format) => ListTile(
            leading: Icon(_getFormatIcon(format)),
            title: Text(format),
            subtitle: Text(_getFormatDescription(format)),
            onTap: () => _showDateRangeDialog(context, format),
          )),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  IconData _getFormatIcon(String format) {
    switch (format.toLowerCase()) {
      case 'csv':
        return Icons.table_chart;
      case 'excel':
        return Icons.grid_on;
      case 'pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.file_download;
    }
  }

  String _getFormatDescription(String format) {
    switch (format.toLowerCase()) {
      case 'csv':
        return 'Comma-separated values file';
      case 'excel':
        return 'Microsoft Excel spreadsheet';
      case 'pdf':
        return 'Portable Document Format';
      default:
        return 'Data export file';
    }
  }

  void _showDateRangeDialog(BuildContext context, String format) {
    showDialog(
      context: context,
      builder: (context) => DateRangePickerDialog(
        title: 'Select Date Range',
        onDateRangeSelected: (dateRange) {
          Navigator.of(context).pop(); // Close date dialog
          Navigator.of(context).pop(); // Close export dialog
          onExport(format, dateRange);
        },
      ),
    );
  }
}

/// Date range picker dialog
class DateRangePickerDialog extends StatefulWidget {
  final String title;
  final Function(DateTimeRange?) onDateRangeSelected;

  const DateRangePickerDialog({
    super.key,
    required this.title,
    required this.onDateRangeSelected,
  });

  @override
  State<DateRangePickerDialog> createState() => _DateRangePickerDialogState();
}

class _DateRangePickerDialogState extends State<DateRangePickerDialog> {
  DateTimeRange? _selectedRange;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick date range options
          ListTile(
            title: const Text('Last 7 days'),
            onTap: () => _selectQuickRange(7),
          ),
          ListTile(
            title: const Text('Last 30 days'),
            onTap: () => _selectQuickRange(30),
          ),
          ListTile(
            title: const Text('Last 90 days'),
            onTap: () => _selectQuickRange(90),
          ),
          const Divider(),
          ListTile(
            title: const Text('Custom range'),
            onTap: _selectCustomRange,
          ),
          
          if (_selectedRange != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Selected: ${DateFormat('MMM dd, yyyy').format(_selectedRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedRange!.end)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => widget.onDateRangeSelected(null),
          child: const Text('All Time'),
        ),
        if (_selectedRange != null)
          FilledButton(
            onPressed: () => widget.onDateRangeSelected(_selectedRange),
            child: const Text('Export'),
          ),
      ],
    );
  }

  void _selectQuickRange(int days) {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    setState(() {
      _selectedRange = DateTimeRange(start: start, end: end);
    });
  }

  Future<void> _selectCustomRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedRange,
    );
    
    if (range != null) {
      setState(() {
        _selectedRange = range;
      });
    }
  }
}

/// Analytics data export service
class AnalyticsExportService {
  static Future<void> exportDashboardStats({
    required AdminDashboardStats stats,
    required String format,
    DateTimeRange? dateRange,
  }) async {
    try {
      final fileName = 'dashboard_stats_${DateFormat('yyyy_MM_dd').format(DateTime.now())}';
      
      switch (format.toLowerCase()) {
        case 'csv':
          await _exportStatsToCSV(stats, fileName);
          break;
        case 'excel':
          await _exportStatsToExcel(stats, fileName);
          break;
        default:
          throw UnsupportedError('Format $format not supported');
      }
    } catch (e) {
      throw Exception('Failed to export dashboard stats: $e');
    }
  }

  static Future<void> exportDailyAnalytics({
    required List<DailyAnalytics> analytics,
    required String format,
    DateTimeRange? dateRange,
  }) async {
    try {
      // Filter by date range if provided
      List<DailyAnalytics> filteredData = analytics;
      if (dateRange != null) {
        filteredData = analytics.where((item) {
          return item.date.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
                 item.date.isBefore(dateRange.end.add(const Duration(days: 1)));
        }).toList();
      }

      final fileName = 'daily_analytics_${DateFormat('yyyy_MM_dd').format(DateTime.now())}';
      
      switch (format.toLowerCase()) {
        case 'csv':
          await _exportAnalyticsToCSV(filteredData, fileName);
          break;
        case 'excel':
          await _exportAnalyticsToExcel(filteredData, fileName);
          break;
        default:
          throw UnsupportedError('Format $format not supported');
      }
    } catch (e) {
      throw Exception('Failed to export daily analytics: $e');
    }
  }

  static Future<void> exportVendorPerformance({
    required List<VendorPerformance> vendors,
    required String format,
  }) async {
    try {
      final fileName = 'vendor_performance_${DateFormat('yyyy_MM_dd').format(DateTime.now())}';
      
      switch (format.toLowerCase()) {
        case 'csv':
          await _exportVendorsToCSV(vendors, fileName);
          break;
        case 'excel':
          await _exportVendorsToExcel(vendors, fileName);
          break;
        default:
          throw UnsupportedError('Format $format not supported');
      }
    } catch (e) {
      throw Exception('Failed to export vendor performance: $e');
    }
  }

  // CSV Export Methods
  static Future<void> _exportStatsToCSV(AdminDashboardStats stats, String fileName) async {
    final List<List<dynamic>> rows = [
      ['Metric', 'Value'],
      ['Total Users', stats.totalUsers],
      ['New Users Today', stats.newUsersToday],
      ['Total Orders', stats.totalOrders],
      ['Today Orders', stats.todayOrders],
      ['Total Revenue', stats.totalRevenue],
      ['Today Revenue', stats.todayRevenue],
      ['Active Vendors', stats.activeVendors],
      ['Pending Vendors', stats.pendingVendors],
      ['Total Customers', stats.totalCustomers],
      ['Total Drivers', stats.totalDrivers],
      ['Active Sales Agents', stats.activeSalesAgents],
      ['Completed Orders Today', stats.completedOrdersToday],
      ['Cancelled Orders Today', stats.cancelledOrdersToday],
      ['Average Order Value', stats.averageOrderValue],
      ['Conversion Rate', stats.conversionRate],
      ['Customer Satisfaction Score', stats.customerSatisfactionScore],
    ];

    await _saveAndShareCSV(rows, fileName);
  }

  static Future<void> _exportAnalyticsToCSV(List<DailyAnalytics> analytics, String fileName) async {
    final List<List<dynamic>> rows = [
      ['Date', 'Completed Orders', 'Cancelled Orders', 'Daily Revenue', 'Unique Customers', 'Active Vendors', 'Avg Order Value'],
      ...analytics.map((item) => [
        DateFormat('yyyy-MM-dd').format(item.date),
        item.completedOrders,
        item.cancelledOrders,
        item.dailyRevenue,
        item.uniqueCustomers,
        item.activeVendors,
        item.avgOrderValue,
      ]),
    ];

    await _saveAndShareCSV(rows, fileName);
  }

  static Future<void> _exportVendorsToCSV(List<VendorPerformance> vendors, String fileName) async {
    final List<List<dynamic>> rows = [
      ['Business Name', 'Rating', 'Total Orders', 'Orders Last 30 Days', 'Revenue Last 30 Days', 'Avg Order Value', 'Cancelled Orders'],
      ...vendors.map((vendor) => [
        vendor.businessName,
        vendor.rating,
        vendor.totalOrders,
        vendor.ordersLast30Days,
        vendor.revenueLast30Days,
        vendor.avgOrderValue,
        vendor.cancelledOrdersLast30Days,
      ]),
    ];

    await _saveAndShareCSV(rows, fileName);
  }

  static Future<void> _saveAndShareCSV(List<List<dynamic>> rows, String fileName) async {
    final csv = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.csv');
    await file.writeAsString(csv);
    
    await Share.shareXFiles([XFile(file.path)], text: 'Analytics Export');
  }

  // Excel Export Methods (simplified - would need more complex implementation for full Excel features)
  static Future<void> _exportStatsToExcel(AdminDashboardStats stats, String fileName) async {
    final excel = Excel.createExcel();
    final sheet = excel['Dashboard Stats'];

    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Metric');
    sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Value');
    
    final metrics = [
      ['Total Users', stats.totalUsers],
      ['New Users Today', stats.newUsersToday],
      ['Total Orders', stats.totalOrders],
      ['Today Orders', stats.todayOrders],
      ['Total Revenue', stats.totalRevenue],
      ['Today Revenue', stats.todayRevenue],
      ['Active Vendors', stats.activeVendors],
      ['Pending Vendors', stats.pendingVendors],
    ];

    for (int i = 0; i < metrics.length; i++) {
      sheet.cell(CellIndex.indexByString('A${i + 2}')).value = TextCellValue(metrics[i][0].toString());
      sheet.cell(CellIndex.indexByString('B${i + 2}')).value = TextCellValue(metrics[i][1].toString());
    }

    await _saveAndShareExcel(excel, fileName);
  }

  static Future<void> _exportAnalyticsToExcel(List<DailyAnalytics> analytics, String fileName) async {
    final excel = Excel.createExcel();
    final sheet = excel['Daily Analytics'];
    
    // Headers
    final headers = ['Date', 'Completed Orders', 'Cancelled Orders', 'Daily Revenue', 'Unique Customers', 'Active Vendors', 'Avg Order Value'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = TextCellValue(headers[i]);
    }

    // Data
    for (int row = 0; row < analytics.length; row++) {
      final item = analytics[row];
      final rowData = [
        DateFormat('yyyy-MM-dd').format(item.date),
        item.completedOrders.toString(),
        item.cancelledOrders.toString(),
        item.dailyRevenue.toString(),
        item.uniqueCustomers.toString(),
        item.activeVendors.toString(),
        item.avgOrderValue.toString(),
      ];

      for (int col = 0; col < rowData.length; col++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1)).value = TextCellValue(rowData[col]);
      }
    }

    await _saveAndShareExcel(excel, fileName);
  }

  static Future<void> _exportVendorsToExcel(List<VendorPerformance> vendors, String fileName) async {
    final excel = Excel.createExcel();
    final sheet = excel['Vendor Performance'];
    
    // Headers
    final headers = ['Business Name', 'Rating', 'Total Orders', 'Orders Last 30 Days', 'Revenue Last 30 Days', 'Avg Order Value', 'Cancelled Orders'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = TextCellValue(headers[i]);
    }

    // Data
    for (int row = 0; row < vendors.length; row++) {
      final vendor = vendors[row];
      final rowData = [
        vendor.businessName,
        vendor.rating.toString(),
        vendor.totalOrders.toString(),
        vendor.ordersLast30Days.toString(),
        vendor.revenueLast30Days.toString(),
        vendor.avgOrderValue.toString(),
        vendor.cancelledOrdersLast30Days.toString(),
      ];

      for (int col = 0; col < rowData.length; col++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1)).value = TextCellValue(rowData[col]);
      }
    }

    await _saveAndShareExcel(excel, fileName);
  }

  static Future<void> _saveAndShareExcel(Excel excel, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.xlsx');
    final bytes = excel.save();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Analytics Export');
    }
  }
}
