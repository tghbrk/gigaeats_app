import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/menu_realtime_providers.dart';
import '../../data/services/menu_realtime_service.dart';
import '../../../../core/utils/logger.dart';

/// Widget that provides real-time synchronization for menu data
/// Can be used as a wrapper around menu screens to ensure data is always up-to-date
class MenuRealtimeSyncWidget extends ConsumerStatefulWidget {
  final String vendorId;
  final Widget child;
  final bool showConnectionStatus;
  final VoidCallback? onConnectionLost;
  final VoidCallback? onConnectionRestored;
  final Function(MenuRealtimeEvent)? onMenuEvent;

  const MenuRealtimeSyncWidget({
    super.key,
    required this.vendorId,
    required this.child,
    this.showConnectionStatus = false,
    this.onConnectionLost,
    this.onConnectionRestored,
    this.onMenuEvent,
  });

  @override
  ConsumerState<MenuRealtimeSyncWidget> createState() => _MenuRealtimeSyncWidgetState();
}

class _MenuRealtimeSyncWidgetState extends ConsumerState<MenuRealtimeSyncWidget> {
  final AppLogger _logger = AppLogger();
  bool _wasConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeConnection();
  }

  @override
  void didUpdateWidget(MenuRealtimeSyncWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vendorId != widget.vendorId) {
      _initializeConnection();
    }
  }

  void _initializeConnection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final connectionNotifier = ref.read(menuRealtimeConnectionProvider.notifier);
      connectionNotifier.initializeForVendor(widget.vendorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to connection state
    final connectionState = ref.watch(menuRealtimeConnectionProvider);
    
    // Listen to synchronization state
    final syncState = ref.watch(menuSynchronizationNotifierProvider(widget.vendorId));
    
    // Listen to real-time events
    ref.listen(menuEventsRealtimeProvider(widget.vendorId), (previous, next) {
      next.whenData((event) {
        widget.onMenuEvent?.call(event);
        _handleMenuEvent(event);
      });
    });

    // Handle connection state changes
    _handleConnectionStateChange(connectionState);

    return Stack(
      children: [
        widget.child,
        
        // Connection status overlay
        if (widget.showConnectionStatus)
          _buildConnectionStatusOverlay(connectionState, syncState),
        
        // Error overlay
        if (connectionState.error != null || syncState.lastError != null)
          _buildErrorOverlay(connectionState, syncState),
      ],
    );
  }

  void _handleConnectionStateChange(MenuRealtimeConnectionState state) {
    if (state.isConnected && !_wasConnected) {
      // Connection restored
      _wasConnected = true;
      widget.onConnectionRestored?.call();
      _logger.info('Menu real-time connection restored for vendor: ${widget.vendorId}');
    } else if (!state.isConnected && _wasConnected) {
      // Connection lost
      _wasConnected = false;
      widget.onConnectionLost?.call();
      _logger.warning('Menu real-time connection lost for vendor: ${widget.vendorId}');
    }
  }

  void _handleMenuEvent(MenuRealtimeEvent event) {
    _logger.debug('Menu event received: ${event.type} - ${event.action}');
    
    // Show subtle notification for important events
    if (event.type == MenuRealtimeEventType.menuItem && event.action == MenuRealtimeAction.created) {
      _showEventNotification('New menu item added', Icons.restaurant_menu, Colors.green);
    } else if (event.type == MenuRealtimeEventType.pricing && event.action == MenuRealtimeAction.updated) {
      _showEventNotification('Pricing updated', Icons.attach_money, Colors.orange);
    } else if (event.type == MenuRealtimeEventType.organization && event.action == MenuRealtimeAction.updated) {
      _showEventNotification('Menu organization updated', Icons.reorder, Colors.blue);
    }
  }

  void _showEventNotification(String message, IconData icon, Color color) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildConnectionStatusOverlay(
    MenuRealtimeConnectionState connectionState,
    MenuSynchronizationState syncState,
  ) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _getConnectionStatusColor(connectionState, syncState).withValues(alpha: 0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Icon(
                _getConnectionStatusIcon(connectionState, syncState),
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getConnectionStatusText(connectionState, syncState),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (syncState.eventCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${syncState.eventCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(
    MenuRealtimeConnectionState connectionState,
    MenuSynchronizationState syncState,
  ) {
    final error = connectionState.error ?? syncState.lastError;
    if (error == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[600],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Connection Error',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      error,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _retryConnection,
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getConnectionStatusColor(
    MenuRealtimeConnectionState connectionState,
    MenuSynchronizationState syncState,
  ) {
    if (connectionState.isConnecting || syncState.isInitializing) {
      return Colors.orange;
    } else if (connectionState.isConnected && syncState.isConnected) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  IconData _getConnectionStatusIcon(
    MenuRealtimeConnectionState connectionState,
    MenuSynchronizationState syncState,
  ) {
    if (connectionState.isConnecting || syncState.isInitializing) {
      return Icons.sync;
    } else if (connectionState.isConnected && syncState.isConnected) {
      return Icons.cloud_done;
    } else {
      return Icons.cloud_off;
    }
  }

  String _getConnectionStatusText(
    MenuRealtimeConnectionState connectionState,
    MenuSynchronizationState syncState,
  ) {
    if (connectionState.isConnecting || syncState.isInitializing) {
      return 'Connecting to real-time updates...';
    } else if (connectionState.isConnected && syncState.isConnected) {
      final lastSync = syncState.lastSyncTime;
      if (lastSync != null) {
        final timeDiff = DateTime.now().difference(lastSync);
        if (timeDiff.inMinutes < 1) {
          return 'Real-time sync active • Just now';
        } else if (timeDiff.inMinutes < 60) {
          return 'Real-time sync active • ${timeDiff.inMinutes}m ago';
        } else {
          return 'Real-time sync active • ${timeDiff.inHours}h ago';
        }
      }
      return 'Real-time sync active';
    } else {
      return 'Real-time sync disconnected';
    }
  }

  void _retryConnection() {
    final connectionNotifier = ref.read(menuRealtimeConnectionProvider.notifier);
    connectionNotifier.initializeForVendor(widget.vendorId);
  }
}

/// Simplified real-time sync indicator widget
class MenuRealtimeSyncIndicator extends ConsumerWidget {
  final String vendorId;
  final bool compact;

  const MenuRealtimeSyncIndicator({
    super.key,
    required this.vendorId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(menuRealtimeConnectionProvider);
    final syncState = ref.watch(menuSynchronizationNotifierProvider(vendorId));

    if (compact) {
      return _buildCompactIndicator(connectionState, syncState);
    } else {
      return _buildFullIndicator(context, connectionState, syncState);
    }
  }

  Widget _buildCompactIndicator(
    MenuRealtimeConnectionState connectionState,
    MenuSynchronizationState syncState,
  ) {
    final isConnected = connectionState.isConnected && syncState.isConnected;
    final isConnecting = connectionState.isConnecting || syncState.isInitializing;

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isConnecting
            ? Colors.orange
            : isConnected
                ? Colors.green
                : Colors.red,
      ),
    );
  }

  Widget _buildFullIndicator(
    BuildContext context,
    MenuRealtimeConnectionState connectionState,
    MenuSynchronizationState syncState,
  ) {
    final isConnected = connectionState.isConnected && syncState.isConnected;
    final isConnecting = connectionState.isConnecting || syncState.isInitializing;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isConnecting
            ? Colors.orange[100]
            : isConnected
                ? Colors.green[100]
                : Colors.red[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnecting
              ? Colors.orange
              : isConnected
                  ? Colors.green
                  : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnecting
                ? Icons.sync
                : isConnected
                    ? Icons.cloud_done
                    : Icons.cloud_off,
            size: 14,
            color: isConnecting
                ? Colors.orange[700]
                : isConnected
                    ? Colors.green[700]
                    : Colors.red[700],
          ),
          const SizedBox(width: 4),
          Text(
            isConnecting
                ? 'Syncing'
                : isConnected
                    ? 'Live'
                    : 'Offline',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isConnecting
                  ? Colors.orange[700]
                  : isConnected
                      ? Colors.green[700]
                      : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }
}
