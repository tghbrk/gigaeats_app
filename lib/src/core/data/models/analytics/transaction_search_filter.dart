import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../../../features/marketplace_wallet/data/models/wallet_transaction.dart';

part 'transaction_search_filter.g.dart';

/// Enum for transaction sort options
enum TransactionSortBy {
  @JsonValue('created_at')
  createdAt,
  @JsonValue('amount')
  amount,
  @JsonValue('transaction_type')
  transactionType,
  @JsonValue('processed_at')
  processedAt,
}

/// Enum for sort order
enum SortOrder {
  @JsonValue('asc')
  ascending,
  @JsonValue('desc')
  descending,
}

/// Enhanced transaction search filter model
@JsonSerializable()
class TransactionSearchFilter extends Equatable {
  final String? searchQuery;
  final List<WalletTransactionType>? transactionTypes;
  final double? amountMin;
  final double? amountMax;
  final DateTime? startDate;
  final DateTime? endDate;
  final TransactionSortBy sortBy;
  final SortOrder sortOrder;
  final int limit;
  final int offset;

  const TransactionSearchFilter({
    this.searchQuery,
    this.transactionTypes,
    this.amountMin,
    this.amountMax,
    this.startDate,
    this.endDate,
    this.sortBy = TransactionSortBy.createdAt,
    this.sortOrder = SortOrder.descending,
    this.limit = 20,
    this.offset = 0,
  });

  factory TransactionSearchFilter.fromJson(Map<String, dynamic> json) =>
      _$TransactionSearchFilterFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionSearchFilterToJson(this);

  TransactionSearchFilter copyWith({
    String? searchQuery,
    List<WalletTransactionType>? transactionTypes,
    double? amountMin,
    double? amountMax,
    DateTime? startDate,
    DateTime? endDate,
    TransactionSortBy? sortBy,
    SortOrder? sortOrder,
    int? limit,
    int? offset,
  }) {
    return TransactionSearchFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      transactionTypes: transactionTypes ?? this.transactionTypes,
      amountMin: amountMin ?? this.amountMin,
      amountMax: amountMax ?? this.amountMax,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  @override
  List<Object?> get props => [
        searchQuery,
        transactionTypes,
        amountMin,
        amountMax,
        startDate,
        endDate,
        sortBy,
        sortOrder,
        limit,
        offset,
      ];

  /// Check if any filters are applied
  bool get hasFilters {
    return searchQuery != null ||
        (transactionTypes != null && transactionTypes!.isNotEmpty) ||
        amountMin != null ||
        amountMax != null ||
        startDate != null ||
        endDate != null;
  }

  /// Check if search query is applied
  bool get hasSearchQuery => searchQuery != null && searchQuery!.isNotEmpty;

  /// Check if amount range filter is applied
  bool get hasAmountFilter => amountMin != null || amountMax != null;

  /// Check if date range filter is applied
  bool get hasDateFilter => startDate != null || endDate != null;

  /// Check if transaction type filter is applied
  bool get hasTypeFilter => transactionTypes != null && transactionTypes!.isNotEmpty;

  /// Get formatted amount range display
  String? get formattedAmountRange {
    if (!hasAmountFilter) return null;
    
    final min = amountMin != null ? 'RM ${amountMin!.toStringAsFixed(2)}' : 'RM 0.00';
    final max = amountMax != null ? 'RM ${amountMax!.toStringAsFixed(2)}' : 'No limit';
    
    return '$min - $max';
  }

  /// Get formatted date range display
  String? get formattedDateRange {
    if (!hasDateFilter) return null;
    
    final start = startDate != null ? '${startDate!.day}/${startDate!.month}/${startDate!.year}' : 'Start';
    final end = endDate != null ? '${endDate!.day}/${endDate!.month}/${endDate!.year}' : 'End';
    
    return '$start - $end';
  }

  /// Get sort display name
  String get sortDisplayName {
    switch (sortBy) {
      case TransactionSortBy.createdAt:
        return 'Date';
      case TransactionSortBy.amount:
        return 'Amount';
      case TransactionSortBy.transactionType:
        return 'Type';
      case TransactionSortBy.processedAt:
        return 'Processed Date';
    }
  }

  /// Get sort order display name
  String get sortOrderDisplayName {
    switch (sortOrder) {
      case SortOrder.ascending:
        return 'Ascending';
      case SortOrder.descending:
        return 'Descending';
    }
  }

  /// Get full sort display
  String get fullSortDisplay => '$sortDisplayName ($sortOrderDisplayName)';

  /// Get active filter count
  int get activeFilterCount {
    int count = 0;
    if (hasSearchQuery) count++;
    if (hasTypeFilter) count++;
    if (hasAmountFilter) count++;
    if (hasDateFilter) count++;
    return count;
  }

  /// Clear all filters
  TransactionSearchFilter clearFilters() {
    return const TransactionSearchFilter();
  }

  /// Clear specific filter
  TransactionSearchFilter clearSearchQuery() {
    return copyWith(searchQuery: null);
  }

  TransactionSearchFilter clearTransactionTypes() {
    return copyWith(transactionTypes: null);
  }

  TransactionSearchFilter clearAmountFilter() {
    return copyWith(amountMin: null, amountMax: null);
  }

  TransactionSearchFilter clearDateFilter() {
    return copyWith(startDate: null, endDate: null);
  }

  /// Reset pagination
  TransactionSearchFilter resetPagination() {
    return copyWith(offset: 0);
  }

  /// Next page
  TransactionSearchFilter nextPage() {
    return copyWith(offset: offset + limit);
  }

  /// Previous page
  TransactionSearchFilter previousPage() {
    return copyWith(offset: (offset - limit).clamp(0, double.infinity).toInt());
  }

  /// Convert to API parameters
  Map<String, dynamic> toApiParams() {
    final params = <String, dynamic>{
      'sort_by': sortBy.name,
      'sort_order': sortOrder.name,
      'limit': limit,
      'offset': offset,
    };

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      params['search_query'] = searchQuery;
    }

    if (transactionTypes != null && transactionTypes!.isNotEmpty) {
      params['transaction_types'] = transactionTypes!.map((type) => type.value).toList();
    }

    if (amountMin != null) {
      params['amount_min'] = amountMin;
    }

    if (amountMax != null) {
      params['amount_max'] = amountMax;
    }

    if (startDate != null) {
      params['start_date'] = startDate!.toIso8601String();
    }

    if (endDate != null) {
      params['end_date'] = endDate!.toIso8601String();
    }

    return params;
  }

  /// Create filter for today's transactions
  factory TransactionSearchFilter.today() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return TransactionSearchFilter(
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  /// Create filter for this week's transactions
  factory TransactionSearchFilter.thisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    return TransactionSearchFilter(
      startDate: startOfDay,
      endDate: now,
    );
  }

  /// Create filter for this month's transactions
  factory TransactionSearchFilter.thisMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    return TransactionSearchFilter(
      startDate: startOfMonth,
      endDate: now,
    );
  }

  /// Create filter for last 30 days
  factory TransactionSearchFilter.last30Days() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    return TransactionSearchFilter(
      startDate: thirtyDaysAgo,
      endDate: now,
    );
  }

  /// Create filter for specific transaction type
  factory TransactionSearchFilter.byType(WalletTransactionType type) {
    return TransactionSearchFilter(
      transactionTypes: [type],
    );
  }

  /// Create filter for amount range
  factory TransactionSearchFilter.byAmountRange(double min, double max) {
    return TransactionSearchFilter(
      amountMin: min,
      amountMax: max,
    );
  }

  /// Create test filter for development
  factory TransactionSearchFilter.test({
    String? searchQuery,
    List<WalletTransactionType>? transactionTypes,
  }) {
    return TransactionSearchFilter(
      searchQuery: searchQuery ?? 'test',
      transactionTypes: transactionTypes ?? [WalletTransactionType.credit],
      amountMin: 10.0,
      amountMax: 1000.0,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
    );
  }
}

/// Transaction search result model
@JsonSerializable()
class TransactionSearchResult extends Equatable {
  final List<dynamic> transactions; // WalletTransaction list
  final TransactionSearchPagination pagination;
  final TransactionSearchFilter filtersApplied;

  const TransactionSearchResult({
    required this.transactions,
    required this.pagination,
    required this.filtersApplied,
  });

  factory TransactionSearchResult.fromJson(Map<String, dynamic> json) =>
      _$TransactionSearchResultFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionSearchResultToJson(this);

  @override
  List<Object?> get props => [transactions, pagination, filtersApplied];

  /// Check if there are more results
  bool get hasMore => pagination.hasMore;

  /// Check if this is the first page
  bool get isFirstPage => pagination.currentPage == 0;

  /// Check if this is the last page
  bool get isLastPage => !hasMore;

  /// Get total transaction count
  int get totalCount => pagination.total;

  /// Get current page transaction count
  int get currentPageCount => transactions.length;
}

/// Transaction search pagination model
@JsonSerializable()
class TransactionSearchPagination extends Equatable {
  final int offset;
  final int limit;
  final int total;
  final bool hasMore;
  final int currentPage;
  final int totalPages;

  const TransactionSearchPagination({
    required this.offset,
    required this.limit,
    required this.total,
    required this.hasMore,
    required this.currentPage,
    required this.totalPages,
  });

  factory TransactionSearchPagination.fromJson(Map<String, dynamic> json) =>
      _$TransactionSearchPaginationFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionSearchPaginationToJson(this);

  @override
  List<Object?> get props => [offset, limit, total, hasMore, currentPage, totalPages];

  /// Get pagination display text
  String get displayText {
    final start = offset + 1;
    final end = (offset + limit).clamp(0, total);
    return '$start-$end of $total';
  }

  /// Check if can go to next page
  bool get canGoNext => hasMore;

  /// Check if can go to previous page
  bool get canGoPrevious => currentPage > 0;
}
