import 'dart:async';
import 'package:flutter/widgets.dart';
import 'enhanced_supabase_connection_manager.dart';

/// App lifecycle events
enum AppLifecycleEvent {
  resumed,
  paused,
  detached,
  inactive,
  hidden,
}

/// App lifecycle service that coordinates with connection manager
class AppLifecycleService with WidgetsBindingObserver {
  static final AppLifecycleService _instance = AppLifecycleService._internal();
  
  factory AppLifecycleService() => _instance;
  
  AppLifecycleService._internal();

  final EnhancedSupabaseConnectionManager _connectionManager = 
      EnhancedSupabaseConnectionManager();
  
  bool _isInitialized = false;
  AppLifecycleState? _lastState;
  DateTime? _lastPausedTime;
  DateTime? _lastResumedTime;
  
  // Event streams
  final StreamController<AppLifecycleEvent> _lifecycleEventController = 
      StreamController<AppLifecycleEvent>.broadcast();
  
  /// Stream of app lifecycle events
  Stream<AppLifecycleEvent> get lifecycleEventStream => 
      _lifecycleEventController.stream;
  
  /// Initialize the lifecycle service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    debugPrint('🔄 [LIFECYCLE-SERVICE] Initializing app lifecycle service');
    
    try {
      // Register as observer
      WidgetsBinding.instance.addObserver(this);
      
      // Initialize connection manager
      await _connectionManager.initialize();
      
      // Get initial app state
      _lastState = WidgetsBinding.instance.lifecycleState;
      debugPrint('🔄 [LIFECYCLE-SERVICE] Initial app state: $_lastState');
      
      _isInitialized = true;
      debugPrint('✅ [LIFECYCLE-SERVICE] App lifecycle service initialized');
    } catch (e) {
      debugPrint('❌ [LIFECYCLE-SERVICE] Failed to initialize: $e');
      rethrow;
    }
  }
  
  /// App lifecycle state changed
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    final previousState = _lastState;
    _lastState = state;
    
    debugPrint('🔄 [LIFECYCLE-SERVICE] App lifecycle changed: $previousState → $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed(previousState);
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.inactive:
        _handleAppInactive();
        break;
      case AppLifecycleState.hidden:
        _handleAppHidden();
        break;
    }
  }
  
  /// Handle memory pressure warnings
  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    debugPrint('⚠️ [LIFECYCLE-SERVICE] Memory pressure detected');
    
    // Could implement memory optimization here
    // For now, just log the event
  }
  
  /// Handle platform messages
  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) {
    debugPrint('🔗 [LIFECYCLE-SERVICE] Route information pushed: ${routeInformation.uri}');
    return super.didPushRouteInformation(routeInformation);
  }
  
  /// Get connection manager instance
  EnhancedSupabaseConnectionManager get connectionManager => _connectionManager;
  
  /// Check if app was recently backgrounded
  bool get wasRecentlyBackgrounded {
    if (_lastPausedTime == null || _lastResumedTime == null) return false;
    
    final backgroundDuration = _lastResumedTime!.difference(_lastPausedTime!);
    return backgroundDuration > const Duration(seconds: 5);
  }
  
  /// Get time since last resume
  Duration? get timeSinceLastResume {
    if (_lastResumedTime == null) return null;
    return DateTime.now().difference(_lastResumedTime!);
  }
  
  /// Dispose the lifecycle service
  Future<void> dispose() async {
    debugPrint('🗑️ [LIFECYCLE-SERVICE] Disposing app lifecycle service');
    
    // Remove observer
    WidgetsBinding.instance.removeObserver(this);
    
    // Dispose connection manager
    await _connectionManager.dispose();
    
    // Close streams
    await _lifecycleEventController.close();
    
    _isInitialized = false;
  }
  
  // Private methods
  
  /// Handle app resumed
  void _handleAppResumed(AppLifecycleState? previousState) {
    _lastResumedTime = DateTime.now();
    
    debugPrint('📱 [LIFECYCLE-SERVICE] App resumed from $previousState');
    
    // Emit event
    _lifecycleEventController.add(AppLifecycleEvent.resumed);
    
    // Handle different resume scenarios
    if (previousState == AppLifecycleState.paused) {
      _handleResumeFromBackground();
    } else if (previousState == AppLifecycleState.inactive) {
      _handleResumeFromInactive();
    }
  }
  
  /// Handle app paused
  void _handleAppPaused() {
    _lastPausedTime = DateTime.now();
    
    debugPrint('📱 [LIFECYCLE-SERVICE] App paused to background');
    
    // Emit event
    _lifecycleEventController.add(AppLifecycleEvent.paused);
    
    // Handle background optimizations
    _handleBackgroundOptimizations();
  }
  
  /// Handle app detached
  void _handleAppDetached() {
    debugPrint('📱 [LIFECYCLE-SERVICE] App detached');
    
    // Emit event
    _lifecycleEventController.add(AppLifecycleEvent.detached);
    
    // Cleanup resources
    _handleAppCleanup();
  }
  
  /// Handle app inactive
  void _handleAppInactive() {
    debugPrint('📱 [LIFECYCLE-SERVICE] App inactive');
    
    // Emit event
    _lifecycleEventController.add(AppLifecycleEvent.inactive);
  }
  
  /// Handle app hidden
  void _handleAppHidden() {
    debugPrint('📱 [LIFECYCLE-SERVICE] App hidden');
    
    // Emit event
    _lifecycleEventController.add(AppLifecycleEvent.hidden);
  }
  
  /// Handle resume from background
  void _handleResumeFromBackground() {
    debugPrint('🔄 [LIFECYCLE-SERVICE] Handling resume from background');
    
    // Check if we were backgrounded for a significant time
    if (wasRecentlyBackgrounded) {
      debugPrint('⏰ [LIFECYCLE-SERVICE] App was backgrounded for significant time, checking connections');
      
      // Delay connection check to allow app to fully resume
      Future.delayed(const Duration(milliseconds: 1500), () async {
        final isHealthy = await _connectionManager.checkConnectionHealth();
        if (!isHealthy) {
          debugPrint('🔄 [LIFECYCLE-SERVICE] Connection unhealthy, triggering reconnect');
          await _connectionManager.reconnectAll();
        }
      });
    }
  }
  
  /// Handle resume from inactive state
  void _handleResumeFromInactive() {
    debugPrint('🔄 [LIFECYCLE-SERVICE] Handling resume from inactive');
    
    // Quick connection health check
    Future.delayed(const Duration(milliseconds: 500), () {
      _connectionManager.checkConnectionHealth();
    });
  }
  
  /// Handle background optimizations
  void _handleBackgroundOptimizations() {
    debugPrint('🔋 [LIFECYCLE-SERVICE] Applying background optimizations');
    
    // The connection manager will handle subscription suspension
    // Additional optimizations can be added here
  }
  
  /// Handle app cleanup
  void _handleAppCleanup() {
    debugPrint('🧹 [LIFECYCLE-SERVICE] Performing app cleanup');
    
    // Cleanup resources before app termination
    // The connection manager will handle subscription cleanup
  }
}
