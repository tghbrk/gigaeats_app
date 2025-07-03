import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/custom_error_widget.dart';
import '../../data/models/admin_activity_log.dart';
import '../providers/admin_providers_index.dart';
import '../widgets/audit_log_widgets.dart';

class AdminAuditLogsScreen extends ConsumerStatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  ConsumerState<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends ConsumerState<AdminAuditLogsScreen> {
  ActivityLogFilter _currentFilter = const ActivityLogFilter();
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    
    // Load initial logs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLogs();
    });

    // Setup infinite scroll
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadLogs({bool refresh = false}) {
    if (refresh) {
      _currentFilter = _currentFilter.copyWith(offset: 0);
    }
    
    ref.read(adminActivityLogsProvider(_currentFilter).future);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreLogs();
    }
  }

  Future<void> _loadMoreLogs() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final currentLogs = await ref.read(adminActivityLogsProvider(_currentFilter).future);
      if (currentLogs.length >= _currentFilter.limit) {
        final newFilter = _currentFilter.copyWith(
          offset: _currentFilter.offset + _currentFilter.limit,
        );
        
        setState(() {
          _currentFilter = newFilter;
        });
        
        ref.read(adminActivityLogsProvider(newFilter).future);
      }
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
            tooltip: 'Filter Logs',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(adminActivityLogsProvider);
              _loadLogs(refresh: true);
            },
            tooltip: 'Refresh Logs',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _showExportDialog(context),
            tooltip: 'Export Logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Summary
          if (_hasActiveFilters())
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Text(
                    'Active Filters:',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ..._buildFilterChips(),
                  ActionChip(
                    label: const Text('Clear All'),
                    onPressed: () {
                      setState(() {
                        _currentFilter = const ActivityLogFilter();
                      });
                      _loadLogs(refresh: true);
                    },
                  ),
                ],
              ),
            ),
          
          // Logs List
          Expanded(
            child: _buildLogsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList() {
    final logsAsync = ref.watch(adminActivityLogsProvider(_currentFilter));

    return logsAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No audit logs found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _hasActiveFilters()
                      ? 'Try adjusting your filter criteria'
                      : 'No admin activities have been logged yet',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: logs.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= logs.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final log = logs[index];
            return AuditLogCard(
              log: log,
              onTap: () => _showLogDetails(context, log),
            );
          },
        );
      },
      loading: () => const LoadingWidget(message: 'Loading audit logs...'),
      error: (error, stack) => CustomErrorWidget(
        message: 'Failed to load audit logs: $error',
        onRetry: () {
          ref.invalidate(adminActivityLogsProvider);
          _loadLogs(refresh: true);
        },
      ),
    );
  }

  bool _hasActiveFilters() {
    return _currentFilter.actionType != null ||
           _currentFilter.targetType != null ||
           _currentFilter.adminUserId != null ||
           _currentFilter.startDate != null ||
           _currentFilter.endDate != null;
  }

  List<Widget> _buildFilterChips() {
    final chips = <Widget>[];

    if (_currentFilter.actionType != null) {
      chips.add(Chip(
        label: Text('Action: ${_currentFilter.actionType}'),
        onDeleted: () {
          setState(() {
            _currentFilter = _currentFilter.copyWith(actionType: null);
          });
          _loadLogs(refresh: true);
        },
      ));
    }

    if (_currentFilter.targetType != null) {
      chips.add(Chip(
        label: Text('Target: ${_currentFilter.targetType}'),
        onDeleted: () {
          setState(() {
            _currentFilter = _currentFilter.copyWith(targetType: null);
          });
          _loadLogs(refresh: true);
        },
      ));
    }

    if (_currentFilter.adminUserId != null) {
      chips.add(Chip(
        label: Text('Admin: ${_currentFilter.adminUserId}'),
        onDeleted: () {
          setState(() {
            _currentFilter = _currentFilter.copyWith(adminUserId: null);
          });
          _loadLogs(refresh: true);
        },
      ));
    }

    if (_currentFilter.startDate != null || _currentFilter.endDate != null) {
      final dateRange = '${_currentFilter.startDate?.toString().split(' ')[0] ?? 'Start'} - ${_currentFilter.endDate?.toString().split(' ')[0] ?? 'End'}';
      chips.add(Chip(
        label: Text('Date: $dateRange'),
        onDeleted: () {
          setState(() {
            _currentFilter = _currentFilter.copyWith(
              startDate: null,
              endDate: null,
            );
          });
          _loadLogs(refresh: true);
        },
      ));
    }

    return chips;
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AuditLogFilterDialog(
        currentFilter: _currentFilter,
        onApplyFilter: (filter) {
          setState(() {
            _currentFilter = filter;
          });
          _loadLogs(refresh: true);
        },
      ),
    );
  }

  void _showLogDetails(BuildContext context, AdminActivityLog log) {
    showDialog(
      context: context,
      builder: (context) => AuditLogDetailsDialog(log: log),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Audit Logs'),
        content: const Text('Export filtered audit logs to a file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportLogs();
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _exportLogs() {
    // TODO: Implement audit logs export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon')),
    );
  }
}
