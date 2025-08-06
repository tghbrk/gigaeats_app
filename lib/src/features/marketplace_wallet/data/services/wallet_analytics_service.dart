import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:dartz/dartz.dart';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../repositories/customer_wallet_analytics_repository.dart';
import '../models/wallet_analytics.dart';
import '../../../../core/data/models/analytics/analytics_export.dart';

/// Comprehensive wallet analytics service providing business logic and calculations
class WalletAnalyticsService {
  final CustomerWalletAnalyticsRepository _repository;
  final AppLogger _logger = AppLogger();

  WalletAnalyticsService({
    required CustomerWalletAnalyticsRepository repository,
  }) : _repository = repository;

  /// Get comprehensive analytics summary with privacy validation
  Future<Either<Failure, List<WalletAnalytics>>> getAnalyticsSummary({
    required String periodType,
    int limit = 12,
  }) async {
    try {
      debugPrint('🔍 [ANALYTICS-SERVICE] Getting analytics summary for period: $periodType');

      // Check analytics permission first
      final permissionResult = await _repository.hasAnalyticsPermission();
      return permissionResult.fold(
        (failure) => Left(failure),
        (hasPermission) async {
          if (!hasPermission) {
            return Left(PermissionFailure(message: 'Analytics access denied. Please enable analytics in wallet settings.'));
          }

          // Get analytics data
          final analyticsResult = await _repository.getAnalyticsSummary(
            periodType: periodType,
            limit: limit,
          );

          return analyticsResult.fold(
            (failure) => Left(failure),
            (analyticsData) {
              final analytics = analyticsData
                  .map((data) => _mapToWalletAnalytics(data))
                  .toList();

              debugPrint('🔍 [ANALYTICS-SERVICE] Analytics summary retrieved: ${analytics.length} records');
              return Right(analytics);
            },
          );
        },
      );
    } catch (e) {
      _logger.logError('Failed to get analytics summary', e);
      return Left(ServerFailure(message: 'Failed to get analytics summary: ${e.toString()}'));
    }
  }

  /// Get spending trends with calculation enhancements
  Future<Either<Failure, List<SpendingTrendData>>> getSpendingTrends({
    int days = 30,
  }) async {
    try {
      debugPrint('🔍 [ANALYTICS-SERVICE] Getting spending trends for $days days');

      final trendsResult = await _repository.getSpendingTrends(days: days);
      return trendsResult.fold(
        (failure) => Left(failure),
        (trendsData) {
          final trends = trendsData
              .map((data) => _mapToSpendingTrendData(data))
              .toList();

          // Sort by date
          trends.sort((a, b) => a.datePeriod.compareTo(b.datePeriod));

          debugPrint('🔍 [ANALYTICS-SERVICE] Spending trends retrieved: ${trends.length} data points');
          return Right(trends);
        },
      );
    } catch (e) {
      _logger.logError('Failed to get spending trends', e);
      return Left(ServerFailure(message: 'Failed to get spending trends: ${e.toString()}'));
    }
  }

  /// Get spending categories with enhanced categorization
  Future<Either<Failure, List<TransactionCategoryData>>> getSpendingCategories({
    int days = 30,
  }) async {
    try {
      debugPrint('🔍 [ANALYTICS-SERVICE] Getting spending categories for $days days');

      final categoriesResult = await _repository.getSpendingCategories(days: days);
      return categoriesResult.fold(
        (failure) => Left(failure),
        (categoriesData) {
          final categories = categoriesData
              .map((data) => _mapToTransactionCategoryData(data))
              .toList();

          // Sort by total amount descending
          categories.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

          debugPrint('🔍 [ANALYTICS-SERVICE] Spending categories retrieved: ${categories.length} categories');
          return Right(categories);
        },
      );
    } catch (e) {
      _logger.logError('Failed to get spending categories', e);
      return Left(ServerFailure(message: 'Failed to get spending categories: ${e.toString()}'));
    }
  }

  /// Get current month analytics from optimized view
  Future<Either<Failure, WalletAnalytics?>> getCurrentMonthAnalytics() async {
    try {
      debugPrint('🔍 [ANALYTICS-SERVICE] Getting current month analytics');

      final analyticsResult = await _repository.getCurrentMonthAnalytics();
      return analyticsResult.fold(
        (failure) => Left(failure),
        (analyticsData) {
          if (analyticsData == null) {
            debugPrint('🔍 [ANALYTICS-SERVICE] No current month analytics found');
            return const Right(null);
          }

          final analytics = _mapToWalletAnalytics(analyticsData);
          debugPrint('🔍 [ANALYTICS-SERVICE] Current month analytics retrieved');
          return Right(analytics);
        },
      );
    } catch (e) {
      _logger.logError('Failed to get current month analytics', e);
      return Left(ServerFailure(message: 'Failed to get current month analytics: ${e.toString()}'));
    }
  }

  /// Generate analytics insights and recommendations
  Future<Either<Failure, List<AnalyticsInsight>>> generateInsights() async {
    try {
      debugPrint('🔍 [ANALYTICS-SERVICE] Generating analytics insights');

      // Get current month analytics
      final currentMonthResult = await getCurrentMonthAnalytics();
      
      return currentMonthResult.fold(
        (failure) => Left(failure),
        (currentMonth) async {
          if (currentMonth == null) {
            return const Right(<AnalyticsInsight>[]);
          }

          // Get previous month for comparison
          final previousMonthResult = await getAnalyticsSummary(
            periodType: 'monthly',
            limit: 2,
          );

          return previousMonthResult.fold(
            (failure) => Left(failure),
            (analytics) {
              final insights = _calculateInsights(currentMonth, analytics);
              debugPrint('🔍 [ANALYTICS-SERVICE] Generated ${insights.length} insights');
              return Right(insights);
            },
          );
        },
      );
    } catch (e) {
      _logger.logError('Failed to generate insights', e);
      return Left(ServerFailure(message: 'Failed to generate insights: ${e.toString()}'));
    }
  }

  /// Create analytics summary cards for dashboard
  Future<Either<Failure, List<AnalyticsSummaryCard>>> getSummaryCards() async {
    try {
      debugPrint('🔍 [ANALYTICS-SERVICE] Getting summary cards');

      final currentMonthResult = await getCurrentMonthAnalytics();
      return currentMonthResult.fold(
        (failure) => Left(failure),
        (currentMonth) async {
          if (currentMonth == null) {
            return Right(_getDefaultSummaryCards());
          }

          // Get previous month for trend calculation
          final previousMonthResult = await getAnalyticsSummary(
            periodType: 'monthly',
            limit: 2,
          );

          return previousMonthResult.fold(
            (failure) => Right(_createSummaryCards(currentMonth, null)),
            (analytics) {
              final previousMonth = analytics.length > 1 ? analytics[1] : null;
              final cards = _createSummaryCards(currentMonth, previousMonth);
              debugPrint('🔍 [ANALYTICS-SERVICE] Created ${cards.length} summary cards');
              return Right(cards);
            },
          );
        },
      );
    } catch (e) {
      _logger.logError('Failed to get summary cards', e);
      return Left(ServerFailure(message: 'Failed to get summary cards: ${e.toString()}'));
    }
  }

  /// Export analytics data to PDF
  Future<Either<Failure, AnalyticsExport>> exportToPdf({
    required String periodType,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      debugPrint('🔍 [ANALYTICS-SERVICE] Exporting analytics to PDF');

      // Check export permission
      final canExportResult = await _repository.canExportAnalytics();
      return canExportResult.fold(
        (failure) => Left(failure),
        (canExport) async {
          if (!canExport) {
            return Left(PermissionFailure(message: 'Export not allowed. Please enable data sharing in wallet settings.'));
          }

          // Get analytics data
          final analyticsResult = await _repository.getAnonymizedAnalytics(
            periodType: periodType,
            limit: 50,
          );

          return analyticsResult.fold(
            (failure) => Left(failure),
            (analyticsData) async {
              final pdfBytes = await _generatePdfReport(analyticsData, startDate, endDate);
              final filePath = await _savePdfFile(pdfBytes, 'analytics_report');

              final export = AnalyticsExport(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                userId: 'current-user', // Will be set by repository
                exportType: 'pdf',
                periodType: periodType,
                periodStart: startDate,
                periodEnd: endDate,
                data: {'records': analyticsData.length},
                filePath: filePath,
                fileSize: pdfBytes.length,
                status: 'completed',
                createdAt: DateTime.now(),
                completedAt: DateTime.now(),
              );

              debugPrint('🔍 [ANALYTICS-SERVICE] PDF export completed: ${export.formattedFileSize}');
              return Right(export);
            },
          );
        },
      );
    } catch (e) {
      _logger.logError('Failed to export to PDF', e);
      return Left(ServerFailure(message: 'Failed to export to PDF: ${e.toString()}'));
    }
  }

  /// Export analytics data to CSV
  Future<Either<Failure, AnalyticsExport>> exportToCsv({
    required String periodType,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      debugPrint('🔍 [ANALYTICS-SERVICE] Exporting analytics to CSV');

      // Check export permission
      final canExportResult = await _repository.canExportAnalytics();
      return canExportResult.fold(
        (failure) => Left(failure),
        (canExport) async {
          if (!canExport) {
            return Left(PermissionFailure(message: 'Export not allowed. Please enable data sharing in wallet settings.'));
          }

          // Get analytics data
          final analyticsResult = await _repository.getAnonymizedAnalytics(
            periodType: periodType,
            limit: 1000,
          );

          return analyticsResult.fold(
            (failure) => Left(failure),
            (analyticsData) async {
              final csvContent = _generateCsvContent(analyticsData);
              final filePath = await _saveCsvFile(csvContent, 'analytics_data');

              final export = AnalyticsExport(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                userId: 'current-user', // Will be set by repository
                exportType: 'csv',
                periodType: periodType,
                periodStart: startDate,
                periodEnd: endDate,
                data: {'records': analyticsData.length},
                filePath: filePath,
                fileSize: csvContent.length,
                status: 'completed',
                createdAt: DateTime.now(),
                completedAt: DateTime.now(),
              );

              debugPrint('🔍 [ANALYTICS-SERVICE] CSV export completed: ${export.formattedFileSize}');
              return Right(export);
            },
          );
        },
      );
    } catch (e) {
      _logger.logError('Failed to export to CSV', e);
      return Left(ServerFailure(message: 'Failed to export to CSV: ${e.toString()}'));
    }
  }

  /// Share analytics export file
  Future<Either<Failure, void>> shareExport(AnalyticsExport export) async {
    try {
      debugPrint('🔍 [ANALYTICS-SERVICE] Sharing export file: ${export.exportType}');

      if (export.filePath == null) {
        return Left(ValidationFailure(message: 'Export file path is null'));
      }

      final file = File(export.filePath!);
      // Note: Using async file.exists() is necessary here to validate file before sharing
      // ignore: avoid_slow_async_io
      if (!await file.exists()) {
        return Left(ValidationFailure(message: 'Export file does not exist'));
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(export.filePath!)],
          text: 'GigaEats Wallet Analytics Report - ${export.periodDisplayName}',
          subject: 'Wallet Analytics Report',
        ),
      );

      debugPrint('🔍 [ANALYTICS-SERVICE] Export file shared successfully');
      return const Right(null);
    } catch (e) {
      _logger.logError('Failed to share export', e);
      return Left(ServerFailure(message: 'Failed to share export: ${e.toString()}'));
    }
  }

  /// Validate analytics access and permissions
  Future<Either<Failure, bool>> validateAnalyticsAccess() async {
    try {
      debugPrint('🔍 [ANALYTICS-SERVICE] Validating analytics access');

      final permissionResult = await _repository.hasAnalyticsPermission();
      return permissionResult.fold(
        (failure) => Left(failure),
        (hasPermission) {
          debugPrint('🔍 [ANALYTICS-SERVICE] Analytics access validation: $hasPermission');
          return Right(hasPermission);
        },
      );
    } catch (e) {
      _logger.logError('Failed to validate analytics access', e);
      return Left(ServerFailure(message: 'Failed to validate analytics access: ${e.toString()}'));
    }
  }

  /// Map database response to WalletAnalytics model
  WalletAnalytics _mapToWalletAnalytics(Map<String, dynamic> data) {
    return WalletAnalytics(
      id: data['id'] ?? '',
      userId: data['user_id'] ?? '',
      walletId: data['wallet_id'] ?? '',
      periodType: data['period_type'] ?? 'monthly',
      periodStart: DateTime.parse(data['period_start']),
      periodEnd: DateTime.parse(data['period_end']),
      totalSpent: (data['total_spent'] as num?)?.toDouble() ?? 0.0,
      totalTransactions: data['total_transactions'] ?? 0,
      avgTransactionAmount: (data['avg_transaction_amount'] as num?)?.toDouble() ?? 0.0,
      maxTransactionAmount: (data['max_transaction_amount'] as num?)?.toDouble() ?? 0.0,
      minTransactionAmount: (data['min_transaction_amount'] as num?)?.toDouble() ?? 0.0,
      totalToppedUp: (data['total_topped_up'] as num?)?.toDouble() ?? 0.0,
      topupTransactions: data['topup_transactions'] ?? 0,
      avgTopupAmount: (data['avg_topup_amount'] as num?)?.toDouble() ?? 0.0,
      totalTransferredOut: (data['total_transferred_out'] as num?)?.toDouble() ?? 0.0,
      totalTransferredIn: (data['total_transferred_in'] as num?)?.toDouble() ?? 0.0,
      transferOutCount: data['transfer_out_count'] ?? 0,
      transferInCount: data['transfer_in_count'] ?? 0,
      periodStartBalance: (data['period_start_balance'] as num?)?.toDouble() ?? 0.0,
      periodEndBalance: (data['period_end_balance'] as num?)?.toDouble() ?? 0.0,
      avgBalance: (data['avg_balance'] as num?)?.toDouble() ?? 0.0,
      maxBalance: (data['max_balance'] as num?)?.toDouble() ?? 0.0,
      minBalance: (data['min_balance'] as num?)?.toDouble() ?? 0.0,
      uniqueVendorsCount: data['unique_vendors_count'] ?? 0,
      topVendorId: data['top_vendor_id'],
      topVendorSpent: (data['top_vendor_spent'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] ?? 'MYR',
      createdAt: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(data['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Map database response to SpendingTrendData model
  SpendingTrendData _mapToSpendingTrendData(Map<String, dynamic> data) {
    try {
      Map<String, double>? categoryBreakdown;
      if (data['category_breakdown'] != null) {
        final breakdown = data['category_breakdown'] as Map<String, dynamic>;
        categoryBreakdown = breakdown.map((key, value) => MapEntry(key, (value as num).toDouble()));
      }

      // Handle date parsing safely
      DateTime datePeriod;
      try {
        datePeriod = DateTime.parse(data['date_period'] ?? DateTime.now().toIso8601String());
      } catch (e) {
        debugPrint('Error parsing date_period: ${data['date_period']}, using current date');
        datePeriod = DateTime.now();
      }

      return SpendingTrendData(
        datePeriod: datePeriod,
        dailySpent: (data['total_amount'] as num?)?.toDouble() ?? 0.0,
        dailyTransactions: data['transaction_count'] ?? 0,
        runningBalance: (data['avg_amount'] as num?)?.toDouble() ?? 0.0, // Use avg_amount as running balance for now
        categoryBreakdown: categoryBreakdown,
      );
    } catch (e) {
      debugPrint('Error mapping spending trend data: $e');
      // Return default data to prevent crashes
      return SpendingTrendData(
        datePeriod: DateTime.now(),
        dailySpent: 0.0,
        dailyTransactions: 0,
        runningBalance: 0.0,
        categoryBreakdown: null,
      );
    }
  }

  /// Map database response to TransactionCategoryData model
  TransactionCategoryData _mapToTransactionCategoryData(Map<String, dynamic> data) {
    try {
      return TransactionCategoryData(
        categoryType: data['category_id'] ?? data['category_type'] ?? '',
        categoryName: data['category_name'] ?? 'Unknown Category',
        totalAmount: (data['total_amount'] as num?)?.toDouble() ?? 0.0,
        transactionCount: data['transaction_count'] ?? 0,
        avgAmount: (data['avg_amount'] as num?)?.toDouble() ?? 0.0,
        percentageOfTotal: (data['percentage_of_total'] as num?)?.toDouble() ?? 0.0,
        vendorId: data['vendor_id'],
        vendorName: data['vendor_name'],
      );
    } catch (e) {
      debugPrint('Error mapping transaction category data: $e');
      // Return default data to prevent crashes
      return const TransactionCategoryData(
        categoryType: 'unknown',
        categoryName: 'Unknown Category',
        totalAmount: 0.0,
        transactionCount: 0,
        avgAmount: 0.0,
        percentageOfTotal: 0.0,
        vendorId: null,
        vendorName: null,
      );
    }
  }

  /// Calculate insights from analytics data
  List<AnalyticsInsight> _calculateInsights(WalletAnalytics currentMonth, List<WalletAnalytics> analytics) {
    final insights = <AnalyticsInsight>[];
    final now = DateTime.now();

    // Compare with previous month if available
    if (analytics.length > 1) {
      final previousMonth = analytics[1];
      final spendingChange = currentMonth.totalSpent - previousMonth.totalSpent;
      final spendingChangePercent = previousMonth.totalSpent > 0
          ? (spendingChange / previousMonth.totalSpent) * 100
          : 0.0;

      // Spending pattern insight
      if (spendingChangePercent.abs() > 10) {
        final isIncrease = spendingChange > 0;
        insights.add(AnalyticsInsight(
          id: 'spending-pattern-${now.millisecondsSinceEpoch}',
          userId: currentMonth.userId,
          type: 'spending_pattern',
          title: isIncrease ? 'Spending Increase Detected' : 'Spending Decrease Detected',
          description: 'Your spending has ${isIncrease ? 'increased' : 'decreased'} by ${spendingChangePercent.abs().toStringAsFixed(1)}% compared to last month.',
          actionText: 'View Budget',
          actionRoute: '/wallet/budget',
          metadata: {
            'change_percentage': spendingChangePercent,
            'previous_amount': previousMonth.totalSpent,
            'current_amount': currentMonth.totalSpent,
          },
          priority: spendingChangePercent.abs() > 25 ? 'high' : 'medium',
          isRead: false,
          createdAt: now,
        ));
      }
    }

    // High spending frequency insight
    if (currentMonth.spendingFrequency > 2.0) {
      insights.add(AnalyticsInsight(
        id: 'frequency-${now.millisecondsSinceEpoch}',
        userId: currentMonth.userId,
        type: 'spending_pattern',
        title: 'High Spending Frequency',
        description: 'You\'re making ${currentMonth.spendingFrequency.toStringAsFixed(1)} transactions per day on average. Consider consolidating orders to save on delivery fees.',
        actionText: 'View Vendors',
        actionRoute: '/vendors',
        priority: 'low',
        isRead: false,
        createdAt: now,
      ));
    }

    // Vendor diversity insight
    if (currentMonth.uniqueVendorsCount < 3 && currentMonth.totalTransactions > 10) {
      insights.add(AnalyticsInsight(
        id: 'vendor-diversity-${now.millisecondsSinceEpoch}',
        userId: currentMonth.userId,
        type: 'vendor_recommendation',
        title: 'Explore New Vendors',
        description: 'You\'ve only ordered from ${currentMonth.uniqueVendorsCount} vendors this month. Discover new restaurants and cuisines!',
        actionText: 'Explore Vendors',
        actionRoute: '/vendors/explore',
        priority: 'low',
        isRead: false,
        createdAt: now,
      ));
    }

    return insights;
  }

  /// Create summary cards for dashboard
  List<AnalyticsSummaryCard> _createSummaryCards(WalletAnalytics currentMonth, WalletAnalytics? previousMonth) {
    final cards = <AnalyticsSummaryCard>[];

    // Total Spent Card
    double? spentTrendPercentage;
    if (previousMonth != null && previousMonth.totalSpent > 0) {
      spentTrendPercentage = ((currentMonth.totalSpent - previousMonth.totalSpent) / previousMonth.totalSpent) * 100;
    }

    cards.add(AnalyticsSummaryCard(
      title: 'Total Spent',
      value: currentMonth.formattedTotalSpent,
      subtitle: 'This month',
      trend: 'vs last month',
      trendPercentage: spentTrendPercentage,
      icon: 'account_balance_wallet',
      color: '#FF6B6B',
      isPositiveTrend: false, // Spending increase is negative
    ));

    // Balance Card
    double? balanceTrendPercentage;
    if (previousMonth != null && previousMonth.periodEndBalance > 0) {
      balanceTrendPercentage = ((currentMonth.periodEndBalance - previousMonth.periodEndBalance) / previousMonth.periodEndBalance) * 100;
    }

    cards.add(AnalyticsSummaryCard(
      title: 'Current Balance',
      value: currentMonth.formattedPeriodEndBalance,
      subtitle: 'Available funds',
      trend: 'vs last month',
      trendPercentage: balanceTrendPercentage,
      icon: 'account_balance',
      color: '#4ECDC4',
      isPositiveTrend: true, // Balance increase is positive
    ));

    // Transactions Card
    double? transactionsTrendPercentage;
    if (previousMonth != null && previousMonth.totalTransactions > 0) {
      transactionsTrendPercentage = ((currentMonth.totalTransactions - previousMonth.totalTransactions) / previousMonth.totalTransactions) * 100;
    }

    cards.add(AnalyticsSummaryCard(
      title: 'Transactions',
      value: currentMonth.totalTransactions.toString(),
      subtitle: 'This month',
      trend: 'vs last month',
      trendPercentage: transactionsTrendPercentage,
      icon: 'receipt',
      color: '#45B7D1',
      isPositiveTrend: false, // More transactions might be negative
    ));

    // Average Transaction Card
    cards.add(AnalyticsSummaryCard(
      title: 'Avg Transaction',
      value: currentMonth.formattedAvgTransactionAmount,
      subtitle: 'Per order',
      icon: 'trending_up',
      color: '#96CEB4',
    ));

    return cards;
  }

  /// Get default summary cards when no data is available
  List<AnalyticsSummaryCard> _getDefaultSummaryCards() {
    return [
      const AnalyticsSummaryCard(
        title: 'Total Spent',
        value: 'RM 0.00',
        subtitle: 'This month',
        icon: 'account_balance_wallet',
        color: '#FF6B6B',
      ),
      const AnalyticsSummaryCard(
        title: 'Current Balance',
        value: 'RM 0.00',
        subtitle: 'Available funds',
        icon: 'account_balance',
        color: '#4ECDC4',
      ),
      const AnalyticsSummaryCard(
        title: 'Transactions',
        value: '0',
        subtitle: 'This month',
        icon: 'receipt',
        color: '#45B7D1',
      ),
      const AnalyticsSummaryCard(
        title: 'Avg Transaction',
        value: 'RM 0.00',
        subtitle: 'Per order',
        icon: 'trending_up',
        color: '#96CEB4',
      ),
    ];
  }

  /// Generate PDF report from analytics data
  Future<List<int>> _generatePdfReport(List<Map<String, dynamic>> analyticsData, DateTime startDate, DateTime endDate) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Text(
                'GigaEats Wallet Analytics Report',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Period: ${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 20),

              // Summary
              pw.Text(
                'Summary',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),

              if (analyticsData.isNotEmpty) ...[
                pw.Text('Total Records: ${analyticsData.length}'),
                pw.SizedBox(height: 10),

                // Data table
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    // Header row
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Period', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Spending', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Transactions', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Balance', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    // Data rows
                    ...analyticsData.take(20).map((data) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(data['period_label'] ?? ''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('RM ${(data['spending_amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${data['transaction_count'] ?? 0}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(data['balance_trend'] ?? ''),
                        ),
                      ],
                    )),
                  ],
                ),
              ] else ...[
                pw.Text('No data available for the selected period.'),
              ],

              pw.SizedBox(height: 20),
              pw.Text(
                'Generated on: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generate CSV content from analytics data
  String _generateCsvContent(List<Map<String, dynamic>> analyticsData) {
    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln('Period,Spending Amount,Transaction Count,Average Amount,Balance Trend');

    // CSV Data
    for (final data in analyticsData) {
      final period = data['period_label'] ?? '';
      final spending = (data['spending_amount'] as num?)?.toStringAsFixed(2) ?? '0.00';
      final transactions = data['transaction_count'] ?? 0;
      final average = (data['avg_amount'] as num?)?.toStringAsFixed(2) ?? '0.00';
      final trend = data['balance_trend'] ?? '';

      buffer.writeln('$period,$spending,$transactions,$average,$trend');
    }

    return buffer.toString();
  }

  /// Save PDF file to device storage
  Future<String> _savePdfFile(List<int> pdfBytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/${fileName}_$timestamp.pdf');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  /// Save CSV file to device storage
  Future<String> _saveCsvFile(String csvContent, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/${fileName}_$timestamp.csv');
    await file.writeAsString(csvContent);
    return file.path;
  }
}
