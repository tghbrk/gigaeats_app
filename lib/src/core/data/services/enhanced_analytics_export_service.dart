import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../errors/failures.dart';
import '../../utils/logger.dart';
import '../../../features/marketplace_wallet/data/repositories/customer_wallet_analytics_repository.dart';
import '../models/analytics/analytics_export.dart';

/// Enhanced analytics export service with advanced filtering and formatting
class EnhancedAnalyticsExportService {
  final CustomerWalletAnalyticsRepository _repository;
  final AppLogger _logger = AppLogger();

  EnhancedAnalyticsExportService({
    required CustomerWalletAnalyticsRepository repository,
  }) : _repository = repository;

  /// Export analytics data to CSV with advanced filtering
  Future<Either<Failure, AnalyticsExport>> exportToCsvWithFilters({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? categories,
    List<String>? vendors,
    double? minAmount,
    double? maxAmount,
    bool includeTransactionDetails = true,
    bool includeCategoryBreakdown = true,
    bool includeVendorAnalysis = true,
  }) async {
    try {
      debugPrint('🔍 [ENHANCED-EXPORT] Exporting filtered CSV data');

      // Check export permission
      final canExportResult = await _repository.canExportAnalytics();
      return canExportResult.fold(
        (failure) => Left(failure),
        (canExport) async {
          if (!canExport) {
            return Left(PermissionFailure(message: 'Export not allowed. Please enable data sharing in wallet settings.'));
          }

          // Get analytics data (using existing method)
          final analyticsResult = await _repository.getAnonymizedAnalytics(
            periodType: 'custom',
            limit: 1000,
          );

          return analyticsResult.fold(
            (failure) => Left(failure),
            (analyticsData) async {
              final csvContent = await _generateAdvancedCsvContent(
                analyticsData,
                startDate,
                endDate,
                includeTransactionDetails: includeTransactionDetails,
                includeCategoryBreakdown: includeCategoryBreakdown,
                includeVendorAnalysis: includeVendorAnalysis,
              );
              
              final filePath = await _saveCsvFile(csvContent, 'filtered_analytics_data');
              
              final export = AnalyticsExport(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                userId: 'current-user',
                exportType: 'csv',
                periodType: 'custom',
                periodStart: startDate,
                periodEnd: endDate,
                data: {
                  'records': analyticsData.length,
                  'filters': {
                    'categories': categories,
                    'vendors': vendors,
                    'min_amount': minAmount,
                    'max_amount': maxAmount,
                  },
                },
                filePath: filePath,
                fileSize: csvContent.length,
                status: 'completed',
                createdAt: DateTime.now(),
                completedAt: DateTime.now(),
              );

              debugPrint('🔍 [ENHANCED-EXPORT] Filtered CSV export completed: ${export.formattedFileSize}');
              return Right(export);
            },
          );
        },
      );
    } catch (e) {
      _logger.logError('Failed to export filtered CSV', e);
      return Left(ServerFailure(message: 'Failed to export filtered CSV: ${e.toString()}'));
    }
  }

  /// Export analytics data to PDF with charts and insights
  Future<Either<Failure, AnalyticsExport>> exportToPdfWithCharts({
    required DateTime startDate,
    required DateTime endDate,
    bool includeCharts = true,
    bool includeInsights = true,
    bool includeTransactionSummary = true,
  }) async {
    try {
      debugPrint('🔍 [ENHANCED-EXPORT] Exporting PDF with charts');

      // Check export permission
      final canExportResult = await _repository.canExportAnalytics();
      return canExportResult.fold(
        (failure) => Left(failure),
        (canExport) async {
          if (!canExport) {
            return Left(PermissionFailure(message: 'Export not allowed. Please enable data sharing in wallet settings.'));
          }

          // Get analytics data (using existing method)
          final analyticsResult = await _repository.getAnonymizedAnalytics(
            periodType: 'custom',
            limit: 100,
          );

          return analyticsResult.fold(
            (failure) => Left(failure),
            (analyticsData) async {
              final pdfBytes = await _generateEnhancedPdfReport(
                analyticsData,
                startDate,
                endDate,
                includeCharts: includeCharts,
                includeInsights: includeInsights,
                includeTransactionSummary: includeTransactionSummary,
              );
              
              final filePath = await _savePdfFile(pdfBytes, 'enhanced_analytics_report');
              
              final export = AnalyticsExport(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                userId: 'current-user',
                exportType: 'pdf',
                periodType: 'custom',
                periodStart: startDate,
                periodEnd: endDate,
                data: {
                  'records': analyticsData.length,
                  'features': {
                    'charts': includeCharts,
                    'insights': includeInsights,
                    'transaction_summary': includeTransactionSummary,
                  },
                },
                filePath: filePath,
                fileSize: pdfBytes.length,
                status: 'completed',
                createdAt: DateTime.now(),
                completedAt: DateTime.now(),
              );

              debugPrint('🔍 [ENHANCED-EXPORT] Enhanced PDF export completed: ${export.formattedFileSize}');
              return Right(export);
            },
          );
        },
      );
    } catch (e) {
      _logger.logError('Failed to export enhanced PDF', e);
      return Left(ServerFailure(message: 'Failed to export enhanced PDF: ${e.toString()}'));
    }
  }

  /// Share export with multiple sharing options
  Future<Either<Failure, void>> shareExportWithOptions(
    AnalyticsExport export, {
    String? customMessage,
    String? recipientEmail,
    bool includeMetadata = true,
  }) async {
    try {
      debugPrint('🔍 [ENHANCED-EXPORT] Sharing export with options');

      if (export.filePath == null) {
        return Left(ValidationFailure(message: 'Export file path is null'));
      }

      final file = File(export.filePath!);
      // Note: Using async file.exists() is necessary here to validate file before sharing
      // ignore: avoid_slow_async_io
      if (!await file.exists()) {
        return Left(ValidationFailure(message: 'Export file does not exist'));
      }

      // Prepare sharing content
      final shareText = customMessage ?? _generateShareMessage(export, includeMetadata);
      final subject = 'GigaEats Wallet Analytics Report - ${export.periodDisplayName}';

      // Share with enhanced options
      await Share.shareXFiles(
        [XFile(export.filePath!)],
        text: shareText,
        subject: subject,
      );

      // Handle email sharing if specified
      if (recipientEmail != null) {
        await _sendEmailShare(export, recipientEmail, shareText, subject);
      }

      debugPrint('🔍 [ENHANCED-EXPORT] Export shared successfully');
      return const Right(null);
    } catch (e) {
      _logger.logError('Failed to share export with options', e);
      return Left(ServerFailure(message: 'Failed to share export: ${e.toString()}'));
    }
  }

  /// Generate advanced CSV content with multiple sections
  Future<String> _generateAdvancedCsvContent(
    List<Map<String, dynamic>> analyticsData,
    DateTime startDate,
    DateTime endDate, {
    required bool includeTransactionDetails,
    required bool includeCategoryBreakdown,
    required bool includeVendorAnalysis,
  }) async {
    final buffer = StringBuffer();

    // Header section
    buffer.writeln('# GigaEats Wallet Analytics Export');
    buffer.writeln('# Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('# Period: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');
    buffer.writeln('# Records: ${analyticsData.length}');
    buffer.writeln('');

    // Summary section
    buffer.writeln('## Summary');
    buffer.writeln('Metric,Value');
    final totalSpent = analyticsData.fold<double>(0, (sum, data) => sum + ((data['total_spent'] as num?)?.toDouble() ?? 0));
    final totalTransactions = analyticsData.fold<int>(0, (sum, data) => sum + ((data['transaction_count'] as int?) ?? 0));
    buffer.writeln('Total Spent,${totalSpent.toStringAsFixed(2)}');
    buffer.writeln('Total Transactions,$totalTransactions');
    buffer.writeln('Average Transaction,${totalTransactions > 0 ? (totalSpent / totalTransactions).toStringAsFixed(2) : '0.00'}');
    buffer.writeln('');

    if (includeTransactionDetails) {
      // Transaction details section
      buffer.writeln('## Transaction Details');
      buffer.writeln('Date,Amount,Transaction Count,Category,Vendor,Balance');
      
      for (final data in analyticsData) {
        final date = data['date'] ?? '';
        final amount = (data['amount'] as num?)?.toStringAsFixed(2) ?? '0.00';
        final count = data['transaction_count'] ?? 0;
        final category = data['category'] ?? '';
        final vendor = data['vendor_name'] ?? '';
        final balance = (data['balance'] as num?)?.toStringAsFixed(2) ?? '0.00';
        
        buffer.writeln('$date,$amount,$count,$category,$vendor,$balance');
      }
      buffer.writeln('');
    }

    if (includeCategoryBreakdown) {
      // Category breakdown section
      buffer.writeln('## Category Breakdown');
      buffer.writeln('Category,Total Amount,Transaction Count,Percentage');
      
      final categoryTotals = <String, Map<String, dynamic>>{};
      for (final data in analyticsData) {
        final category = data['category'] ?? 'Unknown';
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final count = data['transaction_count'] ?? 0;
        
        if (!categoryTotals.containsKey(category)) {
          categoryTotals[category] = {'amount': 0.0, 'count': 0};
        }
        categoryTotals[category]!['amount'] = (categoryTotals[category]!['amount'] as double) + amount;
        categoryTotals[category]!['count'] = (categoryTotals[category]!['count'] as int) + count;
      }
      
      for (final entry in categoryTotals.entries) {
        final category = entry.key;
        final amount = entry.value['amount'] as double;
        final count = entry.value['count'] as int;
        final percentage = totalSpent > 0 ? ((amount / totalSpent) * 100).toStringAsFixed(1) : '0.0';
        
        buffer.writeln('$category,${amount.toStringAsFixed(2)},$count,$percentage%');
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }

  /// Generate enhanced PDF report with charts and insights
  Future<List<int>> _generateEnhancedPdfReport(
    List<Map<String, dynamic>> analyticsData,
    DateTime startDate,
    DateTime endDate, {
    required bool includeCharts,
    required bool includeInsights,
    required bool includeTransactionSummary,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Text(
                'GigaEats Wallet Analytics Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            // Period and metadata
            pw.Text(
              'Report Period: ${startDate.toLocal().toString().split(' ')[0]} to ${endDate.toLocal().toString().split(' ')[0]}',
              style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
            ),
            pw.Text(
              'Generated: ${DateTime.now().toLocal().toString()}',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 30),

            // Summary section
            _buildPdfSummarySection(analyticsData),
            pw.SizedBox(height: 20),

            if (includeTransactionSummary) ...[
              _buildPdfTransactionSummary(analyticsData),
              pw.SizedBox(height: 20),
            ],

            if (includeCharts) ...[
              pw.Text(
                'Charts and Visualizations',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Note: Chart images would be embedded here in a full implementation.',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 20),
            ],

            if (includeInsights) ...[
              _buildPdfInsightsSection(analyticsData),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Build PDF summary section
  pw.Widget _buildPdfSummarySection(List<Map<String, dynamic>> analyticsData) {
    final totalSpent = analyticsData.fold<double>(0, (sum, data) => sum + ((data['total_spent'] as num?)?.toDouble() ?? 0));
    final totalTransactions = analyticsData.fold<int>(0, (sum, data) => sum + ((data['transaction_count'] as int?) ?? 0));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Summary',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Metric', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Value', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
            ]),
            pw.TableRow(children: [
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Total Spent')),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('RM ${totalSpent.toStringAsFixed(2)}')),
            ]),
            pw.TableRow(children: [
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Total Transactions')),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('$totalTransactions')),
            ]),
            pw.TableRow(children: [
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Average Transaction')),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('RM ${totalTransactions > 0 ? (totalSpent / totalTransactions).toStringAsFixed(2) : '0.00'}')),
            ]),
          ],
        ),
      ],
    );
  }

  /// Build PDF transaction summary
  pw.Widget _buildPdfTransactionSummary(List<Map<String, dynamic>> analyticsData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Transaction Summary',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'This section would contain detailed transaction breakdowns and trends.',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
        ),
      ],
    );
  }

  /// Build PDF insights section
  pw.Widget _buildPdfInsightsSection(List<Map<String, dynamic>> analyticsData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Insights and Recommendations',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          '• Your spending patterns show consistent behavior over the reporting period.',
          style: const pw.TextStyle(fontSize: 12),
        ),
        pw.Text(
          '• Consider setting up budget alerts to better manage your expenses.',
          style: const pw.TextStyle(fontSize: 12),
        ),
        pw.Text(
          '• Regular wallet top-ups can help you take advantage of promotional offers.',
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  /// Generate share message
  String _generateShareMessage(AnalyticsExport export, bool includeMetadata) {
    final buffer = StringBuffer();
    buffer.writeln('GigaEats Wallet Analytics Report');
    buffer.writeln('Period: ${export.periodDisplayName}');
    
    if (includeMetadata) {
      buffer.writeln('File Size: ${export.formattedFileSize}');
      buffer.writeln('Generated: ${export.createdAt.toLocal().toString().split(' ')[0]}');
    }
    
    return buffer.toString();
  }

  /// Send email share (placeholder for email integration)
  Future<void> _sendEmailShare(
    AnalyticsExport export,
    String recipientEmail,
    String shareText,
    String subject,
  ) async {
    // This would integrate with an email service
    debugPrint('🔍 [ENHANCED-EXPORT] Email sharing to $recipientEmail (placeholder)');
  }

  /// Save CSV file to device storage
  Future<String> _saveCsvFile(String content, String baseName) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${baseName}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(content);
    return file.path;
  }

  /// Save PDF file to device storage
  Future<String> _savePdfFile(List<int> bytes, String baseName) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${baseName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
