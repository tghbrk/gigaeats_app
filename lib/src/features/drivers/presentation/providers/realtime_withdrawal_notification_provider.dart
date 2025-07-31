import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/notification_service.dart';
import '../../../notifications/data/services/notification_service.dart' as app_notifications;
import '../../../auth/presentation/providers/auth_provider.dart' as auth;
import '../../../../data/models/user_role.dart';
import '../../data/services/enhanced_withdrawal_notification_service.dart';
import '../../data/services/withdrawal_balance_tracker.dart';
import 'driver_withdrawal_provider.dart';
import 'driver_wallet_provider.dart';

/// Provider for enhanced withdrawal notification service
final enhancedWithdrawalNotificationServiceProvider = Provider<EnhancedWithdrawalNotificationService>((ref) {
  final supabase = Supabase.instance.client;
  final notificationService = ref.watch(notificationServiceProvider);
  final appNotificationService = ref.watch(appNotificationServiceProvider);

  return EnhancedWithdrawalNotificationService(
    supabase: supabase,
    notificationService: notificationService,
    appNotificationService: appNotificationService,
  );
});

/// Provider for withdrawal balance tracker
final withdrawalBalanceTrackerProvider = Provider<WithdrawalBalanceTracker>((ref) {
  final supabase = Supabase.instance.client;
  final notificationService = ref.watch(enhancedWithdrawalNotificationServiceProvider);

  return WithdrawalBalanceTracker(
    supabase: supabase,
    notificationService: notificationService,
  );
});

/// Provider for core notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Provider for app notification service
final appNotificationServiceProvider = Provider<app_notifications.NotificationService>((ref) {
  return app_notifications.NotificationService();
});

/// State for real-time withdrawal notifications
@immutable
class RealtimeWithdrawalNotificationState {
  final bool isActive;
  final bool isInitialized;
  final String? currentDriverId;
  final DateTime? lastNotificationSent;
  final int totalNotificationsSent;
  final Map<String, DateTime> withdrawalNotificationHistory;
  final bool balanceTrackingEnabled;
  final bool statusNotificationsEnabled;
  final String? errorMessage;

  const RealtimeWithdrawalNotificationState({
    this.isActive = false,
    this.isInitialized = false,
    this.currentDriverId,
    this.lastNotificationSent,
    this.totalNotificationsSent = 0,
    this.withdrawalNotificationHistory = const {},
    this.balanceTrackingEnabled = true,
    this.statusNotificationsEnabled = true,
    this.errorMessage,
  });

  RealtimeWithdrawalNotificationState copyWith({
    bool? isActive,
    bool? isInitialized,
    String? currentDriverId,
    DateTime? lastNotificationSent,
    int? totalNotificationsSent,
    Map<String, DateTime>? withdrawalNotificationHistory,
    bool? balanceTrackingEnabled,
    bool? statusNotificationsEnabled,
    String? errorMessage,
  }) {
    return RealtimeWithdrawalNotificationState(
      isActive: isActive ?? this.isActive,
      isInitialized: isInitialized ?? this.isInitialized,
      currentDriverId: currentDriverId ?? this.currentDriverId,
      lastNotificationSent: lastNotificationSent ?? this.lastNotificationSent,
      totalNotificationsSent: totalNotificationsSent ?? this.totalNotificationsSent,
      withdrawalNotificationHistory: withdrawalNotificationHistory ?? this.withdrawalNotificationHistory,
      balanceTrackingEnabled: balanceTrackingEnabled ?? this.balanceTrackingEnabled,
      statusNotificationsEnabled: statusNotificationsEnabled ?? this.statusNotificationsEnabled,
      errorMessage: errorMessage,
    );
  }
}

/// Provider for real-time withdrawal notification state
final realtimeWithdrawalNotificationProvider = StateNotifierProvider<RealtimeWithdrawalNotificationNotifier, RealtimeWithdrawalNotificationState>((ref) {
  return RealtimeWithdrawalNotificationNotifier(ref);
});

/// Notifier for real-time withdrawal notifications
class RealtimeWithdrawalNotificationNotifier extends StateNotifier<RealtimeWithdrawalNotificationState> {
  final Ref _ref;
  WithdrawalBalanceTracker? _balanceTracker;

  RealtimeWithdrawalNotificationNotifier(this._ref) : super(const RealtimeWithdrawalNotificationState()) {
    _initializeNotificationSystem();
  }

  /// Initialize the real-time notification system
  void _initializeNotificationSystem() {
    try {
      debugPrint('🔔 [REALTIME-WITHDRAWAL-NOTIFICATIONS] Initializing notification system');
      
      // Listen to auth state changes
      _ref.listen(auth.authStateProvider, (previous, next) {
        _handleAuthStateChange(previous, next);
      });
      
      // Listen to withdrawal provider changes for immediate notifications
      _ref.listen(driverWithdrawalProvider, (previous, next) {
        _handleWithdrawalStateChange(previous, next);
      });
      
      // Listen to wallet provider changes for balance notifications
      _ref.listen(driverWalletProvider, (previous, next) {
        _handleWalletStateChange(previous, next);
      });
      
      state = state.copyWith(isInitialized: true);
      debugPrint('✅ [REALTIME-WITHDRAWAL-NOTIFICATIONS] Notification system initialized');
    } catch (e) {
      debugPrint('❌ [REALTIME-WITHDRAWAL-NOTIFICATIONS] Error initializing notification system: $e');
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Handle authentication state changes
  void _handleAuthStateChange(auth.AuthState? previous, auth.AuthState next) {
    try {
      final previousDriverId = previous?.user?.role == UserRole.driver ? previous?.user?.id : null;
      final currentDriverId = next.user?.role == UserRole.driver ? next.user?.id : null;
      
      if (previousDriverId != currentDriverId) {
        debugPrint('🔄 [REALTIME-WITHDRAWAL-NOTIFICATIONS] Driver changed: $previousDriverId → $currentDriverId');
        
        // Stop tracking for previous driver
        if (previousDriverId != null) {
          _stopTrackingForDriver();
        }
        
        // Start tracking for new driver
        if (currentDriverId != null) {
          _startTrackingForDriver(currentDriverId);
        }
      }
    } catch (e) {
      debugPrint('❌ [REALTIME-WITHDRAWAL-NOTIFICATIONS] Error handling auth state change: $e');
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Handle withdrawal provider state changes
  void _handleWithdrawalStateChange(DriverWithdrawalState? previous, DriverWithdrawalState next) {
    if (!state.statusNotificationsEnabled) return;
    
    try {
      // Check for new withdrawal requests
      if (previous?.withdrawalRequests != null && next.withdrawalRequests != null) {
        final previousRequests = previous!.withdrawalRequests!;
        final currentRequests = next.withdrawalRequests!;
        
        // Find newly added requests
        for (final request in currentRequests) {
          final wasPresent = previousRequests.any((r) => r.id == request.id);
          if (!wasPresent) {
            debugPrint('🆕 [REALTIME-WITHDRAWAL-NOTIFICATIONS] New withdrawal request detected: ${request.id}');
            _recordNotificationSent(request.id);
          }
        }
        
        // Find status changes
        for (final currentRequest in currentRequests) {
          final previousRequest = previousRequests.where((r) => r.id == currentRequest.id).firstOrNull;
          if (previousRequest != null && previousRequest.status != currentRequest.status) {
            debugPrint('🔄 [REALTIME-WITHDRAWAL-NOTIFICATIONS] Status change detected: ${currentRequest.id} (${previousRequest.status.name} → ${currentRequest.status.name})');
            _recordNotificationSent(currentRequest.id);
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [REALTIME-WITHDRAWAL-NOTIFICATIONS] Error handling withdrawal state change: $e');
    }
  }

  /// Handle wallet provider state changes
  void _handleWalletStateChange(DriverWalletState? previous, DriverWalletState next) {
    if (!state.balanceTrackingEnabled) return;
    
    try {
      // Check for balance changes
      if (previous?.wallet != null && next.wallet != null) {
        final previousBalance = previous!.wallet!.availableBalance;
        final currentBalance = next.wallet!.availableBalance;
        
        if ((previousBalance - currentBalance).abs() > 0.01) {
          debugPrint('💰 [REALTIME-WITHDRAWAL-NOTIFICATIONS] Balance change detected: RM ${previousBalance.toStringAsFixed(2)} → RM ${currentBalance.toStringAsFixed(2)}');
          // Balance tracking is handled by WithdrawalBalanceTracker
        }
      }
    } catch (e) {
      debugPrint('❌ [REALTIME-WITHDRAWAL-NOTIFICATIONS] Error handling wallet state change: $e');
    }
  }

  /// Start tracking for a specific driver
  Future<void> _startTrackingForDriver(String driverId) async {
    try {
      debugPrint('🔄 [REALTIME-WITHDRAWAL-NOTIFICATIONS] Starting tracking for driver: $driverId');
      
      // Initialize balance tracker
      _balanceTracker = _ref.read(withdrawalBalanceTrackerProvider);
      await _balanceTracker!.startTracking(driverId);
      
      state = state.copyWith(
        isActive: true,
        currentDriverId: driverId,
        errorMessage: null,
      );
      
      debugPrint('✅ [REALTIME-WITHDRAWAL-NOTIFICATIONS] Tracking started for driver: $driverId');
    } catch (e) {
      debugPrint('❌ [REALTIME-WITHDRAWAL-NOTIFICATIONS] Error starting tracking: $e');
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Stop tracking for current driver
  Future<void> _stopTrackingForDriver() async {
    try {
      debugPrint('🔄 [REALTIME-WITHDRAWAL-NOTIFICATIONS] Stopping tracking');
      
      if (_balanceTracker != null) {
        await _balanceTracker!.stopTracking();
        _balanceTracker = null;
      }
      
      state = state.copyWith(
        isActive: false,
        currentDriverId: null,
      );
      
      debugPrint('✅ [REALTIME-WITHDRAWAL-NOTIFICATIONS] Tracking stopped');
    } catch (e) {
      debugPrint('❌ [REALTIME-WITHDRAWAL-NOTIFICATIONS] Error stopping tracking: $e');
    }
  }

  /// Record that a notification was sent for a withdrawal
  void _recordNotificationSent(String withdrawalId) {
    final now = DateTime.now();
    final updatedHistory = Map<String, DateTime>.from(state.withdrawalNotificationHistory);
    updatedHistory[withdrawalId] = now;
    
    state = state.copyWith(
      lastNotificationSent: now,
      totalNotificationsSent: state.totalNotificationsSent + 1,
      withdrawalNotificationHistory: updatedHistory,
    );
  }

  /// Update notification preferences
  void updateNotificationPreferences({
    bool? balanceTrackingEnabled,
    bool? statusNotificationsEnabled,
  }) {
    debugPrint('⚙️ [REALTIME-WITHDRAWAL-NOTIFICATIONS] Updating notification preferences');
    
    state = state.copyWith(
      balanceTrackingEnabled: balanceTrackingEnabled ?? state.balanceTrackingEnabled,
      statusNotificationsEnabled: statusNotificationsEnabled ?? state.statusNotificationsEnabled,
    );
    
    debugPrint('✅ [REALTIME-WITHDRAWAL-NOTIFICATIONS] Notification preferences updated');
  }

  /// Get tracking status
  Map<String, dynamic> getTrackingStatus() {
    final balanceTrackerStatus = _balanceTracker?.getTrackingStatus() ?? {};
    
    return {
      'notification_system_active': state.isActive,
      'notification_system_initialized': state.isInitialized,
      'current_driver_id': state.currentDriverId,
      'balance_tracking_enabled': state.balanceTrackingEnabled,
      'status_notifications_enabled': state.statusNotificationsEnabled,
      'total_notifications_sent': state.totalNotificationsSent,
      'last_notification_sent': state.lastNotificationSent?.toIso8601String(),
      'error_message': state.errorMessage,
      'balance_tracker_status': balanceTrackerStatus,
    };
  }

  /// Force refresh tracking system
  Future<void> refreshTrackingSystem() async {
    try {
      debugPrint('🔄 [REALTIME-WITHDRAWAL-NOTIFICATIONS] Refreshing tracking system');
      
      if (state.currentDriverId != null) {
        await _stopTrackingForDriver();
        await _startTrackingForDriver(state.currentDriverId!);
      }
      
      debugPrint('✅ [REALTIME-WITHDRAWAL-NOTIFICATIONS] Tracking system refreshed');
    } catch (e) {
      debugPrint('❌ [REALTIME-WITHDRAWAL-NOTIFICATIONS] Error refreshing tracking system: $e');
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  @override
  void dispose() {
    _stopTrackingForDriver();
    super.dispose();
  }
}
