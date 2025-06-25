import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transaction_export.g.dart';

/// Enum for export formats
enum ExportFormat {
  @JsonValue('csv')
  csv,
  @JsonValue('json')
  json,
  @JsonValue('pdf')
  pdf,
}

/// Transaction export model
@JsonSerializable()
class TransactionExport extends Equatable {
  final String content;
  final String contentType;
  final String filename;
  final int recordCount;
  final ExportFormat exportFormat;
  final DateTime generatedAt;

  const TransactionExport({
    required this.content,
    required this.contentType,
    required this.filename,
    required this.recordCount,
    required this.exportFormat,
    required this.generatedAt,
  });

  factory TransactionExport.fromJson(Map<String, dynamic> json) =>
      _$TransactionExportFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionExportToJson(this);

  @override
  List<Object?> get props => [
        content,
        contentType,
        filename,
        recordCount,
        exportFormat,
        generatedAt,
      ];

  /// Get file extension
  String get fileExtension {
    switch (exportFormat) {
      case ExportFormat.csv:
        return 'csv';
      case ExportFormat.json:
        return 'json';
      case ExportFormat.pdf:
        return 'pdf';
    }
  }

  /// Get formatted file size (approximate)
  String get formattedFileSize {
    final bytes = content.length;
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Get export summary
  String get exportSummary {
    return '$recordCount transactions exported as ${exportFormat.name.toUpperCase()} ($formattedFileSize)';
  }

  /// Check if export is empty
  bool get isEmpty => recordCount == 0;

  /// Get formatted generation date
  String get formattedGeneratedAt {
    return '${generatedAt.day}/${generatedAt.month}/${generatedAt.year} ${generatedAt.hour.toString().padLeft(2, '0')}:${generatedAt.minute.toString().padLeft(2, '0')}';
  }

  /// Create test export for development
  factory TransactionExport.test({
    ExportFormat? format,
    int? recordCount,
  }) {
    final exportFormat = format ?? ExportFormat.csv;
    final count = recordCount ?? 10;
    
    String content;
    String contentType;
    
    switch (exportFormat) {
      case ExportFormat.csv:
        content = 'Date,Type,Amount,Description\n2023-01-01,Credit,100.00,Test transaction';
        contentType = 'text/csv';
        break;
      case ExportFormat.json:
        content = '[{"date":"2023-01-01","type":"Credit","amount":"100.00","description":"Test transaction"}]';
        contentType = 'application/json';
        break;
      case ExportFormat.pdf:
        content = 'PDF content placeholder';
        contentType = 'application/pdf';
        break;
    }

    return TransactionExport(
      content: content,
      contentType: contentType,
      filename: 'transactions_test.${exportFormat.name}',
      recordCount: count,
      exportFormat: exportFormat,
      generatedAt: DateTime.now(),
    );
  }
}

/// Transaction search suggestions model
@JsonSerializable()
class TransactionSearchSuggestion extends Equatable {
  final String suggestion;
  final String suggestionType;
  final int count;

  const TransactionSearchSuggestion({
    required this.suggestion,
    required this.suggestionType,
    required this.count,
  });

  factory TransactionSearchSuggestion.fromJson(Map<String, dynamic> json) =>
      _$TransactionSearchSuggestionFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionSearchSuggestionToJson(this);

  @override
  List<Object?> get props => [suggestion, suggestionType, count];

  /// Get suggestion display text
  String get displayText {
    return '$suggestion ($count)';
  }

  /// Get suggestion type display name
  String get typeDisplayName {
    switch (suggestionType) {
      case 'description':
        return 'Description';
      case 'reference':
        return 'Reference';
      default:
        return suggestionType;
    }
  }

  /// Check if suggestion is for description
  bool get isDescription => suggestionType == 'description';

  /// Check if suggestion is for reference
  bool get isReference => suggestionType == 'reference';
}

/// Transaction statistics model
@JsonSerializable()
class TransactionStatistics extends Equatable {
  final int totalTransactions;
  final double totalCreditAmount;
  final double totalDebitAmount;
  final double totalFees;
  final double avgTransactionAmount;
  final String? mostCommonType;
  final int? dateRangeDays;

  const TransactionStatistics({
    required this.totalTransactions,
    required this.totalCreditAmount,
    required this.totalDebitAmount,
    required this.totalFees,
    required this.avgTransactionAmount,
    this.mostCommonType,
    this.dateRangeDays,
  });

  factory TransactionStatistics.fromJson(Map<String, dynamic> json) =>
      _$TransactionStatisticsFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionStatisticsToJson(this);

  @override
  List<Object?> get props => [
        totalTransactions,
        totalCreditAmount,
        totalDebitAmount,
        totalFees,
        avgTransactionAmount,
        mostCommonType,
        dateRangeDays,
      ];

  /// Get net amount (credits - debits)
  double get netAmount => totalCreditAmount - totalDebitAmount;

  /// Get formatted amounts
  String get formattedTotalCredit => 'RM ${totalCreditAmount.toStringAsFixed(2)}';
  String get formattedTotalDebit => 'RM ${totalDebitAmount.toStringAsFixed(2)}';
  String get formattedTotalFees => 'RM ${totalFees.toStringAsFixed(2)}';
  String get formattedAvgAmount => 'RM ${avgTransactionAmount.toStringAsFixed(2)}';
  String get formattedNetAmount => 'RM ${netAmount.toStringAsFixed(2)}';

  /// Get net amount color indicator
  String get netAmountColor {
    if (netAmount > 0) return 'green';
    if (netAmount < 0) return 'red';
    return 'grey';
  }

  /// Get average transactions per day
  double? get avgTransactionsPerDay {
    if (dateRangeDays == null || dateRangeDays! <= 0) return null;
    return totalTransactions / dateRangeDays!;
  }

  /// Get formatted average transactions per day
  String? get formattedAvgTransactionsPerDay {
    final avg = avgTransactionsPerDay;
    if (avg == null) return null;
    return avg.toStringAsFixed(1);
  }

  /// Get most common type display name
  String get mostCommonTypeDisplay {
    if (mostCommonType == null) return 'N/A';
    
    switch (mostCommonType!) {
      case 'credit':
        return 'Credit';
      case 'debit':
        return 'Debit';
      case 'commission':
        return 'Commission';
      case 'payout':
        return 'Payout';
      case 'transfer_in':
        return 'Transfer In';
      case 'transfer_out':
        return 'Transfer Out';
      default:
        return mostCommonType!;
    }
  }

  /// Check if statistics show positive activity
  bool get isPositiveActivity => netAmount >= 0;

  /// Get period description
  String get periodDescription {
    if (dateRangeDays == null) return 'All time';
    if (dateRangeDays! <= 1) return 'Today';
    if (dateRangeDays! <= 7) return 'This week';
    if (dateRangeDays! <= 30) return 'This month';
    return '$dateRangeDays days';
  }

  /// Create test statistics for development
  factory TransactionStatistics.test({
    int? totalTransactions,
    double? totalCredit,
    double? totalDebit,
  }) {
    final transactions = totalTransactions ?? 25;
    final credit = totalCredit ?? 1500.00;
    final debit = totalDebit ?? 800.00;

    return TransactionStatistics(
      totalTransactions: transactions,
      totalCreditAmount: credit,
      totalDebitAmount: debit,
      totalFees: 25.00,
      avgTransactionAmount: (credit + debit) / transactions,
      mostCommonType: 'credit',
      dateRangeDays: 30,
    );
  }
}

/// Combined search suggestions response
@JsonSerializable()
class TransactionSearchSuggestionsResponse extends Equatable {
  final List<TransactionSearchSuggestion> suggestions;
  final String query;

  const TransactionSearchSuggestionsResponse({
    required this.suggestions,
    required this.query,
  });

  factory TransactionSearchSuggestionsResponse.fromJson(Map<String, dynamic> json) =>
      _$TransactionSearchSuggestionsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionSearchSuggestionsResponseToJson(this);

  @override
  List<Object?> get props => [suggestions, query];

  /// Check if there are suggestions
  bool get hasSuggestions => suggestions.isNotEmpty;

  /// Get suggestions by type
  List<TransactionSearchSuggestion> getSuggestionsByType(String type) {
    return suggestions.where((s) => s.suggestionType == type).toList();
  }

  /// Get description suggestions
  List<TransactionSearchSuggestion> get descriptionSuggestions {
    return getSuggestionsByType('description');
  }

  /// Get reference suggestions
  List<TransactionSearchSuggestion> get referenceSuggestions {
    return getSuggestionsByType('reference');
  }
}

/// Transaction statistics response
@JsonSerializable()
class TransactionStatisticsResponse extends Equatable {
  final TransactionStatistics statistics;
  final Map<String, String>? dateRange;
  final DateTime generatedAt;

  const TransactionStatisticsResponse({
    required this.statistics,
    this.dateRange,
    required this.generatedAt,
  });

  factory TransactionStatisticsResponse.fromJson(Map<String, dynamic> json) =>
      _$TransactionStatisticsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionStatisticsResponseToJson(this);

  @override
  List<Object?> get props => [statistics, dateRange, generatedAt];

  /// Get formatted date range
  String? get formattedDateRange {
    if (dateRange == null) return null;
    final start = dateRange!['start_date'];
    final end = dateRange!['end_date'];
    if (start == null || end == null) return null;
    return '$start to $end';
  }

  /// Check if date range is specified
  bool get hasDateRange => dateRange != null;
}
