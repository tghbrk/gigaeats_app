import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../orders/presentation/providers/driver_orders_provider.dart';
import '../../../../presentation/widgets/loading_widget.dart';
import '../../../../presentation/widgets/custom_error_widget.dart';

/// Screen for viewing driver location history
/// Shows tracking history for different time periods
class DriverLocationHistoryScreen extends ConsumerStatefulWidget {
  const DriverLocationHistoryScreen({super.key});

  @override
  ConsumerState<DriverLocationHistoryScreen> createState() => _DriverLocationHistoryScreenState();
}

class _DriverLocationHistoryScreenState extends ConsumerState<DriverLocationHistoryScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  int _limit = 50;

  @override
  void initState() {
    super.initState();
    // Default to last 7 days
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 7));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final locationHistoryAsync = ref.watch(driverLocationHistoryProvider({
      'startDate': _startDate,
      'endDate': _endDate,
      'limit': _limit,
    }));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshData(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateRangeCard(theme),
          Expanded(
            child: locationHistoryAsync.when(
              data: (locations) => _buildLocationList(locations, theme),
              loading: () => const LoadingWidget(),
              error: (error, stack) => CustomErrorWidget(
                message: 'Failed to load location history: $error',
                onRetry: () => _refreshData(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeCard(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date Range',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    context,
                    'From: ${_formatDate(_startDate)}',
                    () => _selectStartDate(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDateButton(
                    context,
                    'To: ${_formatDate(_endDate)}',
                    () => _selectEndDate(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Showing last $_limit records',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton(BuildContext context, String text, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }

  Widget _buildLocationList(List<Map<String, dynamic>> locations, ThemeData theme) {
    if (locations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No location history found',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Location tracking data will appear here once you start tracking',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: locations.length,
      itemBuilder: (context, index) {
        final location = locations[index];
        return _buildLocationCard(location, theme);
      },
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> location, ThemeData theme) {
    final recordedAt = DateTime.parse(location['recorded_at']);
    final orderId = location['order_id'] as String?;
    final speed = location['speed'] as double?;
    final accuracy = location['accuracy'] as double?;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(
            Icons.location_on,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          _formatDateTime(recordedAt),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (orderId != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.receipt, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Order: ${orderId.substring(0, 8)}...',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                if (speed != null) ...[
                  Icon(Icons.speed, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${speed.toStringAsFixed(1)} m/s',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                ],
                if (accuracy != null) ...[
                  Icon(Icons.gps_fixed, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '±${accuracy.toStringAsFixed(0)}m',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.grey),
            const SizedBox(height: 2),
            Text(
              _formatTime(recordedAt),
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
        onTap: () => _showLocationDetails(context, location),
      ),
    );
  }

  void _showLocationDetails(BuildContext context, Map<String, dynamic> location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Recorded At', _formatDateTime(DateTime.parse(location['recorded_at']))),
            if (location['order_id'] != null)
              _buildDetailRow('Order ID', location['order_id']),
            if (location['speed'] != null)
              _buildDetailRow('Speed', '${(location['speed'] as double).toStringAsFixed(2)} m/s'),
            if (location['heading'] != null)
              _buildDetailRow('Heading', '${(location['heading'] as double).toStringAsFixed(1)}°'),
            if (location['accuracy'] != null)
              _buildDetailRow('Accuracy', '±${(location['accuracy'] as double).toStringAsFixed(1)}m'),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Last 24 hours'),
              onTap: () => _setDateRange(1),
            ),
            ListTile(
              title: const Text('Last 7 days'),
              onTap: () => _setDateRange(7),
            ),
            ListTile(
              title: const Text('Last 30 days'),
              onTap: () => _setDateRange(30),
            ),
            const Divider(),
            ListTile(
              title: const Text('Limit: 50 records'),
              trailing: _limit == 50 ? const Icon(Icons.check) : null,
              onTap: () => _setLimit(50),
            ),
            ListTile(
              title: const Text('Limit: 100 records'),
              trailing: _limit == 100 ? const Icon(Icons.check) : null,
              onTap: () => _setLimit(100),
            ),
            ListTile(
              title: const Text('Limit: 200 records'),
              trailing: _limit == 200 ? const Icon(Icons.check) : null,
              onTap: () => _setLimit(200),
            ),
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

  void _setDateRange(int days) {
    setState(() {
      _endDate = DateTime.now();
      _startDate = _endDate!.subtract(Duration(days: days));
    });
    Navigator.of(context).pop();
    _refreshData();
  }

  void _setLimit(int limit) {
    setState(() {
      _limit = limit;
    });
    Navigator.of(context).pop();
    _refreshData();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
      });
      _refreshData();
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
      });
      _refreshData();
    }
  }

  void _refreshData() {
    ref.invalidate(driverLocationHistoryProvider);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${_formatTime(date)}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
