import 'dart:async';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Enhanced connection state for real-time subscriptions
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  suspended,
  failed,
}

/// Connection health metrics
class ConnectionHealth {
  final ConnectionState state;
  final DateTime lastConnected;
  final DateTime? lastDisconnected;
  final int reconnectAttempts;
  final Duration? lastLatency;
  final String? lastError;
  final bool isNetworkAvailable;

  const ConnectionHealth({
    required this.state,
    required this.lastConnected,
    this.lastDisconnected,
    this.reconnectAttempts = 0,
    this.lastLatency,
    this.lastError,
    this.isNetworkAvailable = true,
  });

  ConnectionHealth copyWith({
    ConnectionState? state,
    DateTime? lastConnected,
    DateTime? lastDisconnected,
    int? reconnectAttempts,
    Duration? lastLatency,
    String? lastError,
    bool? isNetworkAvailable,
  }) {
    return ConnectionHealth(
      state: state ?? this.state,
      lastConnected: lastConnected ?? this.lastConnected,
      lastDisconnected: lastDisconnected ?? this.lastDisconnected,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      lastLatency: lastLatency ?? this.lastLatency,
      lastError: lastError ?? this.lastError,
      isNetworkAvailable: isNetworkAvailable ?? this.isNetworkAvailable,
    );
  }
}

/// Subscription configuration for enhanced management
class SubscriptionConfig {
  final String id;
  final String table;
  final String? filter;
  final void Function(List<Map<String, dynamic>>) onData;
  final void Function(dynamic)? onError;
  final bool autoReconnect;
  final Duration reconnectDelay;
  final int maxReconnectAttempts;

  const SubscriptionConfig({
    required this.id,
    required this.table,
    this.filter,
    required this.onData,
    this.onError,
    this.autoReconnect = true,
    this.reconnectDelay = const Duration(seconds: 5),
    this.maxReconnectAttempts = 10,
  });
}

/// Enhanced Supabase Connection Manager with app lifecycle and network awareness
class EnhancedSupabaseConnectionManager with WidgetsBindingObserver {
  static final EnhancedSupabaseConnectionManager _instance = 
      EnhancedSupabaseConnectionManager._internal();
  
  factory EnhancedSupabaseConnectionManager() => _instance;
  
  EnhancedSupabaseConnectionManager._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final Connectivity _connectivity = Connectivity();
  
  // Connection state management
  ConnectionHealth _connectionHealth = ConnectionHealth(
    state: ConnectionState.disconnected,
    lastConnected: DateTime.now(),
  );
  
  // Subscription management
  final Map<String, StreamSubscription<List<Map<String, dynamic>>>> _subscriptions = {};
  final Map<String, SubscriptionConfig> _subscriptionConfigs = {};
  final Map<String, Timer> _reconnectTimers = {};
  
  // Network and lifecycle monitoring
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isInitialized = false;

  // Reconnection strategy
  static const Duration _baseReconnectDelay = Duration(seconds: 2);
  static const Duration _maxReconnectDelay = Duration(minutes: 5);
  
  // Event streams
  final StreamController<ConnectionHealth> _connectionHealthController = 
      StreamController<ConnectionHealth>.broadcast();
  
  /// Stream of connection health updates
  Stream<ConnectionHealth> get connectionHealthStream => 
      _connectionHealthController.stream;
  
  /// Current connection health
  ConnectionHealth get connectionHealth => _connectionHealth;
  
  /// Initialize the connection manager
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    debugPrint('🔗 [CONNECTION-MANAGER] Initializing enhanced connection manager');
    
    try {
      // Register app lifecycle observer
      WidgetsBinding.instance.addObserver(this);
      
      // Start network monitoring
      await _startNetworkMonitoring();
      
      // Check initial connection
      await _checkConnectionHealth();
      
      _isInitialized = true;
      debugPrint('✅ [CONNECTION-MANAGER] Enhanced connection manager initialized');
    } catch (e) {
      debugPrint('❌ [CONNECTION-MANAGER] Failed to initialize: $e');
      rethrow;
    }
  }
  
  /// Subscribe to real-time updates with enhanced management
  Future<String> subscribe(SubscriptionConfig config) async {
    debugPrint('📡 [CONNECTION-MANAGER] Creating subscription: ${config.id}');
    
    // Store configuration
    _subscriptionConfigs[config.id] = config;
    
    // Create subscription
    await _createSubscription(config);
    
    return config.id;
  }
  
  /// Unsubscribe from real-time updates
  Future<void> unsubscribe(String subscriptionId) async {
    debugPrint('🔇 [CONNECTION-MANAGER] Unsubscribing: $subscriptionId');
    
    // Cancel subscription
    await _subscriptions[subscriptionId]?.cancel();
    _subscriptions.remove(subscriptionId);
    
    // Cancel reconnect timer
    _reconnectTimers[subscriptionId]?.cancel();
    _reconnectTimers.remove(subscriptionId);
    
    // Remove configuration
    _subscriptionConfigs.remove(subscriptionId);
  }
  
  /// Force reconnect all subscriptions
  Future<void> reconnectAll() async {
    debugPrint('🔄 [CONNECTION-MANAGER] Force reconnecting all subscriptions');
    
    _updateConnectionHealth(
      _connectionHealth.copyWith(
        state: ConnectionState.reconnecting,
        reconnectAttempts: _connectionHealth.reconnectAttempts + 1,
      ),
    );
    
    // Reconnect all active subscriptions
    final configs = Map<String, SubscriptionConfig>.from(_subscriptionConfigs);
    for (final config in configs.values) {
      await _reconnectSubscription(config.id);
    }
  }
  
  /// Check connection health
  Future<bool> checkConnectionHealth() async {
    return await _checkConnectionHealth();
  }
  
  /// App lifecycle callback - app resumed
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    debugPrint('📱 [CONNECTION-MANAGER] App lifecycle changed: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      default:
        break;
    }
  }
  
  /// Dispose the connection manager
  Future<void> dispose() async {
    debugPrint('🗑️ [CONNECTION-MANAGER] Disposing connection manager');

    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Cancel all subscriptions
    for (final subscriptionId in _subscriptions.keys.toList()) {
      await unsubscribe(subscriptionId);
    }

    // Cancel network monitoring
    await _connectivitySubscription?.cancel();

    // Close streams
    await _connectionHealthController.close();

    _isInitialized = false;
  }

  // Private implementation methods

  /// Create a new subscription
  Future<void> _createSubscription(SubscriptionConfig config) async {
    try {
      debugPrint('📡 [CONNECTION-MANAGER] Creating subscription for table: ${config.table}');

      // Cancel existing subscription if any
      await _subscriptions[config.id]?.cancel();

      // Create new subscription and store it immediately to satisfy analyzer
      _subscriptions[config.id] = _supabase
          .from(config.table)
          .stream(primaryKey: ['id'])
          .listen(
            (data) {
              debugPrint('📨 [CONNECTION-MANAGER] Data received for ${config.id}: ${data.length} records');
              config.onData(data);

              // Update connection health on successful data
              _updateConnectionHealth(
                _connectionHealth.copyWith(
                  state: ConnectionState.connected,
                  lastConnected: DateTime.now(),
                  reconnectAttempts: 0,
                  lastError: null,
                ),
              );
            },
            onError: (error) {
              debugPrint('❌ [CONNECTION-MANAGER] Subscription error for ${config.id}: $error');

              // Handle error
              _handleSubscriptionError(config.id, error);

              // Call user error handler
              config.onError?.call(error);
            },
          );

      debugPrint('✅ [CONNECTION-MANAGER] Subscription created: ${config.id}');
    } catch (e) {
      debugPrint('❌ [CONNECTION-MANAGER] Failed to create subscription ${config.id}: $e');
      _handleSubscriptionError(config.id, e);
    }
  }

  /// Handle subscription errors with intelligent reconnection
  void _handleSubscriptionError(String subscriptionId, dynamic error) {
    final config = _subscriptionConfigs[subscriptionId];
    if (config == null) return;

    debugPrint('🔧 [CONNECTION-MANAGER] Handling error for $subscriptionId: $error');

    // Update connection health
    _updateConnectionHealth(
      _connectionHealth.copyWith(
        state: ConnectionState.failed,
        lastError: error.toString(),
        lastDisconnected: DateTime.now(),
      ),
    );

    // Schedule reconnection if enabled
    if (config.autoReconnect &&
        _connectionHealth.reconnectAttempts < config.maxReconnectAttempts) {
      _scheduleReconnection(subscriptionId);
    } else {
      debugPrint('⚠️ [CONNECTION-MANAGER] Max reconnect attempts reached for $subscriptionId');
    }
  }

  /// Schedule reconnection with exponential backoff
  void _scheduleReconnection(String subscriptionId) {
    final config = _subscriptionConfigs[subscriptionId];
    if (config == null) return;

    // Cancel existing timer
    _reconnectTimers[subscriptionId]?.cancel();

    // Calculate delay with exponential backoff
    final attempt = _connectionHealth.reconnectAttempts;
    final delay = Duration(
      milliseconds: min(
        _baseReconnectDelay.inMilliseconds * pow(2, attempt).toInt(),
        _maxReconnectDelay.inMilliseconds,
      ),
    );

    debugPrint('⏰ [CONNECTION-MANAGER] Scheduling reconnection for $subscriptionId in ${delay.inSeconds}s (attempt ${attempt + 1})');

    _reconnectTimers[subscriptionId] = Timer(delay, () {
      _reconnectSubscription(subscriptionId);
    });
  }

  /// Reconnect a specific subscription
  Future<void> _reconnectSubscription(String subscriptionId) async {
    final config = _subscriptionConfigs[subscriptionId];
    if (config == null) return;

    debugPrint('🔄 [CONNECTION-MANAGER] Reconnecting subscription: $subscriptionId');

    // Check network availability first
    if (!_connectionHealth.isNetworkAvailable) {
      debugPrint('📵 [CONNECTION-MANAGER] Network unavailable, postponing reconnection');
      return;
    }

    // Update connection health
    _updateConnectionHealth(
      _connectionHealth.copyWith(
        state: ConnectionState.reconnecting,
        reconnectAttempts: _connectionHealth.reconnectAttempts + 1,
      ),
    );

    try {
      await _createSubscription(config);
    } catch (e) {
      debugPrint('❌ [CONNECTION-MANAGER] Reconnection failed for $subscriptionId: $e');
      _handleSubscriptionError(subscriptionId, e);
    }
  }

  /// Update connection health and notify listeners
  void _updateConnectionHealth(ConnectionHealth newHealth) {
    _connectionHealth = newHealth;
    _connectionHealthController.add(newHealth);

    debugPrint('📊 [CONNECTION-MANAGER] Connection health updated: ${newHealth.state.name}');
  }

  /// Start network connectivity monitoring
  Future<void> _startNetworkMonitoring() async {
    debugPrint('🌐 [CONNECTION-MANAGER] Starting network monitoring');

    // Check initial connectivity
    final connectivityResult = await _connectivity.checkConnectivity();
    final isConnected = !connectivityResult.contains(ConnectivityResult.none);

    _updateConnectionHealth(
      _connectionHealth.copyWith(isNetworkAvailable: isConnected),
    );

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final wasConnected = _connectionHealth.isNetworkAvailable;
        final isConnected = !results.contains(ConnectivityResult.none);

        debugPrint('🌐 [CONNECTION-MANAGER] Network connectivity changed: $isConnected');

        _updateConnectionHealth(
          _connectionHealth.copyWith(isNetworkAvailable: isConnected),
        );

        // Handle network restoration
        if (!wasConnected && isConnected) {
          _handleNetworkRestored();
        } else if (wasConnected && !isConnected) {
          _handleNetworkLost();
        }
      },
    );
  }

  /// Check connection health with Supabase
  Future<bool> _checkConnectionHealth() async {
    try {
      debugPrint('🔍 [CONNECTION-MANAGER] Checking connection health');

      final startTime = DateTime.now();

      // Simple health check query
      await _supabase.from('driver_earnings').select('id').limit(1);

      final latency = DateTime.now().difference(startTime);

      _updateConnectionHealth(
        _connectionHealth.copyWith(
          state: ConnectionState.connected,
          lastConnected: DateTime.now(),
          lastLatency: latency,
          lastError: null,
        ),
      );

      debugPrint('✅ [CONNECTION-MANAGER] Connection healthy (latency: ${latency.inMilliseconds}ms)');
      return true;
    } catch (e) {
      debugPrint('❌ [CONNECTION-MANAGER] Connection health check failed: $e');

      _updateConnectionHealth(
        _connectionHealth.copyWith(
          state: ConnectionState.failed,
          lastError: e.toString(),
          lastDisconnected: DateTime.now(),
        ),
      );

      return false;
    }
  }

  /// Handle app resumed from background
  void _handleAppResumed() {
    debugPrint('📱 [CONNECTION-MANAGER] App resumed from background');

    // Check connection health and reconnect if needed
    Future.delayed(const Duration(seconds: 1), () async {
      final isHealthy = await _checkConnectionHealth();
      if (!isHealthy) {
        await reconnectAll();
      }
    });
  }

  /// Handle app paused to background
  void _handleAppPaused() {
    debugPrint('📱 [CONNECTION-MANAGER] App paused to background');

    // Suspend connections to save battery
    _updateConnectionHealth(
      _connectionHealth.copyWith(state: ConnectionState.suspended),
    );
  }

  /// Handle app detached
  void _handleAppDetached() {
    debugPrint('📱 [CONNECTION-MANAGER] App detached');
    // Cleanup resources if needed
  }

  /// Handle network connectivity restored
  void _handleNetworkRestored() {
    debugPrint('🌐 [CONNECTION-MANAGER] Network connectivity restored');

    // Reconnect all subscriptions after a brief delay
    Future.delayed(const Duration(seconds: 2), () async {
      if (_connectionHealth.isNetworkAvailable) {
        await reconnectAll();
      }
    });
  }

  /// Handle network connectivity lost
  void _handleNetworkLost() {
    debugPrint('📵 [CONNECTION-MANAGER] Network connectivity lost');

    _updateConnectionHealth(
      _connectionHealth.copyWith(
        state: ConnectionState.disconnected,
        lastDisconnected: DateTime.now(),
      ),
    );
  }
}
