import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/custom_error_widget.dart';
import '../../data/models/driver_earnings.dart';
import '../providers/driver_earnings_provider.dart';

/// Enhanced earnings history widget with advanced filtering, date range picker, and pagination
class EarningsHistoryWidget extends ConsumerStatefulWidget {
  final String driverId;
  final bool showFilters;
  final int itemsPerPage;

  const EarningsHistoryWidget({
    super.key,
    required this.driverId,
    this.showFilters = true,
    this.itemsPerPage = 20,
  });

  @override
  ConsumerState<EarningsHistoryWidget> createState() => _EarningsHistoryWidgetState();
}

class _EarningsHistoryWidgetState extends ConsumerState<EarningsHistoryWidget>
    with TickerProviderStateMixin {
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;
  
  // Filter state
  DateTime? _startDate;
  DateTime? _endDate;
  EarningsStatus? _selectedStatus;
  String _sortBy = 'date_desc';
  bool _showFilters = false;
  
  // Pagination state
  int _currentPage = 0;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();
  
  // Search state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );
    
    _scrollController.addListener(_onScroll);
    
    debugPrint('EarningsHistoryWidget: Initialized for driver ${widget.driverId}');
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Handle scroll for pagination
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  /// Load more data for pagination
  void _loadMoreData() {
    if (_hasMoreData) {
      setState(() {
        _currentPage++;
      });
    }
  }

  /// Toggle filter panel
  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
    
    if (_showFilters) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  /// Show date range picker
  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
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
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _applyFilters();
    }
  }

  /// Clear date filter
  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _applyFilters();
  }

  /// Apply filters and refresh data
  void _applyFilters() {
    setState(() {
      _currentPage = 0;
      _hasMoreData = true;
    });
    
    // Invalidate provider to refresh data
    ref.invalidate(driverEarningsHistoryProvider);
  }

  /// Clear all filters
  void _clearAllFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedStatus = null;
      _sortBy = 'date_desc';
      _searchQuery = '';
      _searchController.clear();
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Build filter parameters
    final filterParams = {
      'driverId': widget.driverId,
      'startDate': _startDate,
      'endDate': _endDate,
      'status': _selectedStatus,
      'sortBy': _sortBy,
      'searchQuery': _searchQuery,
      'page': _currentPage,
      'limit': widget.itemsPerPage,
    };

    final earningsAsync = ref.watch(driverEarningsHistoryProvider(filterParams));

    return Column(
      children: [
        // Header with search and filter toggle
        _buildHeader(theme),
        
        // Filter panel
        if (widget.showFilters)
          AnimatedBuilder(
            animation: _filterAnimation,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor: _filterAnimation,
                child: _buildFilterPanel(theme),
              );
            },
          ),
        
        // Earnings list
        Expanded(
          child: earningsAsync.when(
            loading: () => const LoadingWidget(),
            error: (error, stack) => CustomErrorWidget(
              message: error.toString(),
              onRetry: () => ref.invalidate(driverEarningsHistoryProvider),
            ),
            data: (earnings) => _buildEarningsList(theme, _convertToDriverEarnings(earnings)),
          ),
        ),
      ],
    );
  }

  /// Build header with search and filter controls
  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search earnings...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        _applyFilters();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              // Debounce search
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_searchQuery == value) {
                  _applyFilters();
                }
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Filter controls
          if (widget.showFilters)
            Row(
              children: [
                // Filter toggle button
                ElevatedButton.icon(
                  onPressed: _toggleFilters,
                  icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
                  label: Text(_showFilters ? 'Hide Filters' : 'Show Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _showFilters 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.surfaceContainerHighest,
                    foregroundColor: _showFilters 
                        ? theme.colorScheme.onPrimary 
                        : theme.colorScheme.onSurface,
                  ),
                ),
                
                const Spacer(),
                
                // Active filter indicators
                if (_hasActiveFilters()) ...[
                  Chip(
                    label: Text('${_getActiveFilterCount()} filters'),
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    deleteIcon: const Icon(Icons.clear, size: 18),
                    onDeleted: _clearAllFilters,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  /// Check if there are active filters
  bool _hasActiveFilters() {
    return _startDate != null || 
           _endDate != null || 
           _selectedStatus != null || 
           _searchQuery.isNotEmpty ||
           _sortBy != 'date_desc';
  }

  /// Get count of active filters
  int _getActiveFilterCount() {
    int count = 0;
    if (_startDate != null || _endDate != null) count++;
    if (_selectedStatus != null) count++;
    if (_searchQuery.isNotEmpty) count++;
    if (_sortBy != 'date_desc') count++;
    return count;
  }

  /// Build filter panel
  Widget _buildFilterPanel(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range filter
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date Range',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _showDateRangePicker,
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        _startDate != null && _endDate != null
                            ? '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}'
                            : 'Select Date Range',
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40),
                      ),
                    ),
                  ],
                ),
              ),
              if (_startDate != null || _endDate != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _clearDateFilter,
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear date filter',
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Status and sort filters
          Row(
            children: [
              // Status filter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<EarningsStatus?>(
                      value: _selectedStatus,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<EarningsStatus?>(
                          value: null,
                          child: Text('All Status'),
                        ),
                        ...EarningsStatus.values.map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(_getStatusDisplayName(status)),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value;
                        });
                        _applyFilters();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Sort filter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sort By',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _sortBy,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'date_desc',
                          child: Text('Newest First'),
                        ),
                        DropdownMenuItem(
                          value: 'date_asc',
                          child: Text('Oldest First'),
                        ),
                        DropdownMenuItem(
                          value: 'amount_desc',
                          child: Text('Highest Amount'),
                        ),
                        DropdownMenuItem(
                          value: 'amount_asc',
                          child: Text('Lowest Amount'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _sortBy = value;
                          });
                          _applyFilters();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Get display name for earnings status
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

  /// Convert Map data to DriverEarnings objects
  List<DriverEarnings> _convertToDriverEarnings(List<Map<String, dynamic>> earningsData) {
    return earningsData.map((data) => DriverEarnings.fromJson(data)).toList();
  }

  /// Build earnings list with pagination
  Widget _buildEarningsList(ThemeData theme, List<DriverEarnings> earnings) {
    if (earnings.isEmpty) {
      return _buildEmptyState(theme);
    }

    return RefreshIndicator(
      onRefresh: () async {
        _applyFilters();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: earnings.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == earnings.length) {
            // Loading indicator for pagination
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final earning = earnings[index];
          return _buildEarningCard(theme, earning, index);
        },
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No earnings found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasActiveFilters()
                ? 'Try adjusting your filters'
                : 'Your earnings will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          if (_hasActiveFilters()) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearAllFilters,
              child: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  /// Build individual earning card
  Widget _buildEarningCard(ThemeData theme, DriverEarnings earning, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showEarningDetails(earning),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Earning type and order info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getEarningTypeDisplayName(earning.earningsType),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (earning.orderId != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Order #${earning.orderId!.substring(0, 8)}...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Amount and status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'RM ${earning.netAmount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getAmountColor(theme, earning.netAmount),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusChip(theme, earning.status),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Details row
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(earning.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                  if (earning.description != null) ...[
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        earning.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get display name for earning type
  String _getEarningTypeDisplayName(EarningsType type) {
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

  /// Get color for amount based on value
  Color _getAmountColor(ThemeData theme, double amount) {
    if (amount > 0) {
      return Colors.green;
    } else if (amount < 0) {
      return Colors.red;
    } else {
      return theme.colorScheme.onSurface;
    }
  }

  /// Build status chip
  Widget _buildStatusChip(ThemeData theme, EarningsStatus status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case EarningsStatus.pending:
        backgroundColor = Colors.orange.withValues(alpha: 0.2);
        textColor = Colors.orange;
        break;
      case EarningsStatus.confirmed:
        backgroundColor = Colors.blue.withValues(alpha: 0.2);
        textColor = Colors.blue;
        break;
      case EarningsStatus.paid:
        backgroundColor = Colors.green.withValues(alpha: 0.2);
        textColor = Colors.green;
        break;
      case EarningsStatus.disputed:
        backgroundColor = Colors.red.withValues(alpha: 0.2);
        textColor = Colors.red;
        break;
      case EarningsStatus.cancelled:
        backgroundColor = Colors.grey.withValues(alpha: 0.2);
        textColor = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusDisplayName(status),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Format date and time for display
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  /// Show earning details dialog
  void _showEarningDetails(DriverEarnings earning) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getEarningTypeDisplayName(earning.earningsType)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Amount', 'RM ${earning.amount.toStringAsFixed(2)}'),
            _buildDetailRow('Platform Fee', 'RM ${earning.platformFee.toStringAsFixed(2)}'),
            _buildDetailRow('Net Amount', 'RM ${earning.netAmount.toStringAsFixed(2)}'),
            _buildDetailRow('Status', _getStatusDisplayName(earning.status)),
            _buildDetailRow('Date', _formatDateTime(earning.createdAt)),
            if (earning.orderId != null)
              _buildDetailRow('Order ID', earning.orderId!),
            if (earning.description != null)
              _buildDetailRow('Description', earning.description!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Build detail row for dialog
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
