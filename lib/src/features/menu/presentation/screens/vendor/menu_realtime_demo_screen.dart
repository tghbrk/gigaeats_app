import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/menu_realtime_providers.dart';
import '../../widgets/menu_realtime_sync_widget.dart';
import '../../../data/services/menu_realtime_service.dart';


/// Demo screen showcasing real-time menu synchronization capabilities
class MenuRealtimeDemoScreen extends ConsumerStatefulWidget {
  const MenuRealtimeDemoScreen({super.key});

  @override
  ConsumerState<MenuRealtimeDemoScreen> createState() => _MenuRealtimeDemoScreenState();
}

class _MenuRealtimeDemoScreenState extends ConsumerState<MenuRealtimeDemoScreen>
    with TickerProviderStateMixin {

  final String _demoVendorId = 'demo-vendor-123';
  
  late TabController _tabController;
  final List<MenuRealtimeEvent> _recentEvents = [];
  int _totalEventsReceived = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MenuRealtimeSyncWidget(
      vendorId: _demoVendorId,
      showConnectionStatus: true,
      onMenuEvent: _handleMenuEvent,
      onConnectionLost: () => _showConnectionAlert('Connection Lost', 'Real-time updates are temporarily unavailable.'),
      onConnectionRestored: () => _showConnectionAlert('Connection Restored', 'Real-time updates are now active.'),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Real-time Menu Sync'),
          // Note: AppBar doesn't have subtitle parameter
          actions: [
            MenuRealtimeSyncIndicator(vendorId: _demoVendorId),
            const SizedBox(width: 16),
            IconButton(
              onPressed: _showRealtimeInfo,
              icon: const Icon(Icons.info_outline),
              tooltip: 'Real-time info',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
              Tab(icon: Icon(Icons.timeline), text: 'Events'),
              Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
              Tab(icon: Icon(Icons.settings), text: 'Settings'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildDashboardTab(),
            _buildEventsTab(),
            _buildAnalyticsTab(),
            _buildSettingsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _simulateMenuUpdate,
          icon: const Icon(Icons.sync),
          label: const Text('Simulate Update'),
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    final connectionState = ref.watch(menuRealtimeConnectionProvider);
    final syncState = ref.watch(menuSynchronizationNotifierProvider(_demoVendorId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConnectionStatusCard(connectionState, syncState),
          const SizedBox(height: 16),
          _buildRealtimeStreamsCard(),
          const SizedBox(height: 16),
          _buildEventSummaryCard(),
          const SizedBox(height: 16),
          _buildQuickActionsCard(),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusCard(
    MenuRealtimeConnectionState connectionState,
    MenuSynchronizationState syncState,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  connectionState.isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: connectionState.isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Connection Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusRow('Connection', connectionState.isConnected ? 'Connected' : 'Disconnected'),
            _buildStatusRow('Vendor ID', connectionState.vendorId ?? 'None'),
            _buildStatusRow('Events Received', '$_totalEventsReceived'),
            _buildStatusRow('Sync Count', '${syncState.syncCount}'),
            if (syncState.lastSyncTime != null)
              _buildStatusRow('Last Sync', _formatDateTime(syncState.lastSyncTime!)),
            if (connectionState.error != null || syncState.lastError != null)
              _buildStatusRow('Error', connectionState.error ?? syncState.lastError!, isError: true),
          ],
        ),
      ),
    );
  }

  Widget _buildRealtimeStreamsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Real-time Streams',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStreamStatus('Menu Items', ref.watch(menuItemsRealtimeProvider(_demoVendorId))),
            _buildStreamStatus('Categories', ref.watch(enhancedMenuCategoriesRealtimeProvider(_demoVendorId))),
            _buildStreamStatus('Bulk Pricing', ref.watch(bulkPricingTiersRealtimeProvider('demo-item-1'))),
            _buildStreamStatus('Promotional Pricing', ref.watch(promotionalPricingRealtimeProvider('demo-item-1'))),
            _buildStreamStatus('Organization Config', ref.watch(menuOrganizationConfigRealtimeProvider(_demoVendorId))),
          ],
        ),
      ),
    );
  }

  Widget _buildEventSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Events',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_recentEvents.isEmpty)
              const Text('No events received yet')
            else
              ..._recentEvents.take(5).map((event) => _buildEventTile(event)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _reconnectRealtime,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reconnect'),
                ),
                ElevatedButton.icon(
                  onPressed: _forceSynchronization,
                  icon: const Icon(Icons.sync),
                  label: const Text('Force Sync'),
                ),
                ElevatedButton.icon(
                  onPressed: _clearEvents,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Events'),
                ),
                ElevatedButton.icon(
                  onPressed: _exportEventLog,
                  icon: const Icon(Icons.download),
                  label: const Text('Export Log'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Real-time Events Log',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Total: $_totalEventsReceived',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _recentEvents.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timeline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No events received yet'),
                      SizedBox(height: 8),
                      Text('Events will appear here as they occur'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _recentEvents.length,
                  itemBuilder: (context, index) {
                    final event = _recentEvents[index];
                    return _buildDetailedEventTile(event);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    final syncState = ref.watch(menuSynchronizationNotifierProvider(_demoVendorId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Real-time Analytics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildAnalyticsCard('Connection Uptime', _calculateUptime()),
          const SizedBox(height: 12),
          _buildAnalyticsCard('Events per Minute', _calculateEventsPerMinute()),
          const SizedBox(height: 12),
          _buildAnalyticsCard('Sync Frequency', '${syncState.syncCount} syncs'),
          const SizedBox(height: 12),
          _buildAnalyticsCard('Data Freshness', _calculateDataFreshness(syncState)),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Real-time Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Real-time synchronization settings and preferences would be configured here.'),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Auto-reconnect'),
            subtitle: const Text('Automatically reconnect when connection is lost'),
            value: true,
            onChanged: (value) {},
          ),
          SwitchListTile(
            title: const Text('Show notifications'),
            subtitle: const Text('Display notifications for real-time events'),
            value: true,
            onChanged: (value) {},
          ),
          SwitchListTile(
            title: const Text('Debug logging'),
            subtitle: const Text('Enable detailed logging for troubleshooting'),
            value: false,
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? Colors.red : null,
                fontWeight: isError ? FontWeight.w500 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamStatus(String name, AsyncValue<dynamic> stream) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Icon(
            stream.when(
              data: (_) => Icons.check_circle,
              loading: () => Icons.sync,
              error: (_, _) => Icons.error,
            ),
            size: 16,
            color: stream.when(
              data: (_) => Colors.green,
              loading: () => Colors.orange,
              error: (_, _) => Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            stream.when(
              data: (_) => 'Active',
              loading: () => 'Loading',
              error: (_, _) => 'Error',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTile(MenuRealtimeEvent event) {
    return ListTile(
      dense: true,
      leading: Icon(
        _getEventIcon(event.type),
        color: _getEventColor(event.action),
        size: 20,
      ),
      title: Text(
        '${event.type.name} ${event.action.name}',
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        _formatDateTime(event.timestamp),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildDetailedEventTile(MenuRealtimeEvent event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: Icon(
          _getEventIcon(event.type),
          color: _getEventColor(event.action),
        ),
        title: Text('${event.type.name} ${event.action.name}'),
        subtitle: Text(_formatDateTime(event.timestamp)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event.subType != null)
                  Text('Sub-type: ${event.subType}'),
                const SizedBox(height: 8),
                Text('Data: ${event.data}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getEventIcon(MenuRealtimeEventType type) {
    switch (type) {
      case MenuRealtimeEventType.menuItem:
        return Icons.restaurant_menu;
      case MenuRealtimeEventType.category:
        return Icons.category;
      case MenuRealtimeEventType.pricing:
        return Icons.attach_money;
      case MenuRealtimeEventType.organization:
        return Icons.reorder;
      case MenuRealtimeEventType.customization:
        return Icons.tune;
      case MenuRealtimeEventType.analytics:
        return Icons.analytics;
    }
  }

  Color _getEventColor(MenuRealtimeAction action) {
    switch (action) {
      case MenuRealtimeAction.created:
        return Colors.green;
      case MenuRealtimeAction.updated:
        return Colors.orange;
      case MenuRealtimeAction.deleted:
        return Colors.red;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  String _calculateUptime() {
    // Mock calculation
    return '99.8%';
  }

  String _calculateEventsPerMinute() {
    // Mock calculation
    return (_totalEventsReceived / 5).toStringAsFixed(1);
  }

  String _calculateDataFreshness(MenuSynchronizationState syncState) {
    if (syncState.lastSyncTime == null) return 'Unknown';
    
    final diff = DateTime.now().difference(syncState.lastSyncTime!);
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }

  void _handleMenuEvent(MenuRealtimeEvent event) {
    setState(() {
      _recentEvents.insert(0, event);
      if (_recentEvents.length > 100) {
        _recentEvents.removeLast();
      }
      _totalEventsReceived++;
    });
  }

  void _showConnectionAlert(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showRealtimeInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Real-time Synchronization'),
        content: const Text(
          'This demo shows how menu data is synchronized in real-time across all connected clients. '
          'Changes made to menu items, categories, pricing, and organization are immediately reflected '
          'without requiring manual refresh.',
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

  void _simulateMenuUpdate() {
    // Simulate a menu update event
    final event = MenuRealtimeEvent(
      type: MenuRealtimeEventType.menuItem,
      action: MenuRealtimeAction.updated,
      data: {'id': 'demo-item-${DateTime.now().millisecondsSinceEpoch}', 'name': 'Simulated Item'},
      timestamp: DateTime.now(),
      vendorId: _demoVendorId,
    );
    
    _handleMenuEvent(event);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Simulated menu update event'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _reconnectRealtime() {
    final connectionNotifier = ref.read(menuRealtimeConnectionProvider.notifier);
    connectionNotifier.initializeForVendor(_demoVendorId);
  }

  void _forceSynchronization() {
    final syncNotifier = ref.read(menuSynchronizationNotifierProvider(_demoVendorId).notifier);
    syncNotifier.forceSynchronization();
  }

  void _clearEvents() {
    setState(() {
      _recentEvents.clear();
      _totalEventsReceived = 0;
    });
  }

  void _exportEventLog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Event log exported successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
