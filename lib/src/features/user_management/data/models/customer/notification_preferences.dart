import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'notification_preferences.g.dart';

/// Wallet notification types
enum WalletNotificationType {
  @JsonValue('transaction_received')
  transactionReceived,
  @JsonValue('transaction_sent')
  transactionSent,
  @JsonValue('low_balance')
  lowBalance,
  @JsonValue('spending_limit_reached')
  spendingLimitReached,
  @JsonValue('auto_reload_triggered')
  autoReloadTriggered,
  @JsonValue('security_alert')
  securityAlert,
  @JsonValue('weekly_summary')
  weeklySummary,
  @JsonValue('monthly_summary')
  monthlySummary;

  String get value => switch (this) {
    WalletNotificationType.transactionReceived => 'transaction_received',
    WalletNotificationType.transactionSent => 'transaction_sent',
    WalletNotificationType.lowBalance => 'low_balance',
    WalletNotificationType.spendingLimitReached => 'spending_limit_reached',
    WalletNotificationType.autoReloadTriggered => 'auto_reload_triggered',
    WalletNotificationType.securityAlert => 'security_alert',
    WalletNotificationType.weeklySummary => 'weekly_summary',
    WalletNotificationType.monthlySummary => 'monthly_summary',
  };

  String get displayName => switch (this) {
    WalletNotificationType.transactionReceived => 'Money Received',
    WalletNotificationType.transactionSent => 'Money Sent',
    WalletNotificationType.lowBalance => 'Low Balance',
    WalletNotificationType.spendingLimitReached => 'Spending Limit',
    WalletNotificationType.autoReloadTriggered => 'Auto Reload',
    WalletNotificationType.securityAlert => 'Security Alert',
    WalletNotificationType.weeklySummary => 'Weekly Summary',
    WalletNotificationType.monthlySummary => 'Monthly Summary',
  };

  String get description => switch (this) {
    WalletNotificationType.transactionReceived => 'When you receive money',
    WalletNotificationType.transactionSent => 'When you send money',
    WalletNotificationType.lowBalance => 'When your balance is low',
    WalletNotificationType.spendingLimitReached => 'When you reach spending limits',
    WalletNotificationType.autoReloadTriggered => 'When auto-reload is triggered',
    WalletNotificationType.securityAlert => 'Security-related alerts',
    WalletNotificationType.weeklySummary => 'Weekly spending summary',
    WalletNotificationType.monthlySummary => 'Monthly spending summary',
  };
}

/// Notification channels
enum NotificationChannel {
  @JsonValue('push')
  push,
  @JsonValue('email')
  email,
  @JsonValue('sms')
  sms,
  @JsonValue('in_app')
  inApp;

  String get value => switch (this) {
    NotificationChannel.push => 'push',
    NotificationChannel.email => 'email',
    NotificationChannel.sms => 'sms',
    NotificationChannel.inApp => 'in_app',
  };

  String get displayName => switch (this) {
    NotificationChannel.push => 'Push Notification',
    NotificationChannel.email => 'Email',
    NotificationChannel.sms => 'SMS',
    NotificationChannel.inApp => 'In-App',
  };
}

/// Model representing notification preferences for wallet
@JsonSerializable()
class NotificationPreference extends Equatable {
  final String id;
  final String userId;
  final String walletId;
  final WalletNotificationType notificationType;
  final NotificationChannel channel;
  final bool isEnabled;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final String timezone;
  final int? maxDailyNotifications;
  final bool batchNotifications;
  final int? batchIntervalMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationPreference({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.notificationType,
    required this.channel,
    required this.isEnabled,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.timezone = 'Asia/Kuala_Lumpur',
    this.maxDailyNotifications,
    this.batchNotifications = false,
    this.batchIntervalMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationPreference.fromJson(Map<String, dynamic> json) => 
      _$NotificationPreferenceFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationPreferenceToJson(this);

  NotificationPreference copyWith({
    String? id,
    String? userId,
    String? walletId,
    WalletNotificationType? notificationType,
    NotificationChannel? channel,
    bool? isEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? timezone,
    int? maxDailyNotifications,
    bool? batchNotifications,
    int? batchIntervalMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationPreference(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      notificationType: notificationType ?? this.notificationType,
      channel: channel ?? this.channel,
      isEnabled: isEnabled ?? this.isEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      timezone: timezone ?? this.timezone,
      maxDailyNotifications: maxDailyNotifications ?? this.maxDailyNotifications,
      batchNotifications: batchNotifications ?? this.batchNotifications,
      batchIntervalMinutes: batchIntervalMinutes ?? this.batchIntervalMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        walletId,
        notificationType,
        channel,
        isEnabled,
        quietHoursStart,
        quietHoursEnd,
        timezone,
        maxDailyNotifications,
        batchNotifications,
        batchIntervalMinutes,
        createdAt,
        updatedAt,
      ];

  /// Get display title for this preference
  String get displayTitle => '${notificationType.displayName} - ${channel.displayName}';

  /// Check if quiet hours are configured
  bool get hasQuietHours => quietHoursStart != null && quietHoursEnd != null;

  /// Get quiet hours display text
  String get quietHoursDisplay {
    if (!hasQuietHours) return 'No quiet hours';
    return '$quietHoursStart - $quietHoursEnd';
  }

  /// Get batch settings display text
  String get batchSettingsDisplay {
    if (!batchNotifications) return 'Immediate';
    return 'Batch every ${batchIntervalMinutes ?? 60} minutes';
  }

  /// Create test notification preference for development
  factory NotificationPreference.test({
    String? id,
    String? userId,
    String? walletId,
    WalletNotificationType? notificationType,
    NotificationChannel? channel,
    bool? isEnabled,
  }) {
    final now = DateTime.now();
    return NotificationPreference(
      id: id ?? 'test-notification-preference-id',
      userId: userId ?? 'test-user-id',
      walletId: walletId ?? 'test-wallet-id',
      notificationType: notificationType ?? WalletNotificationType.transactionReceived,
      channel: channel ?? NotificationChannel.push,
      isEnabled: isEnabled ?? true,
      timezone: 'Asia/Kuala_Lumpur',
      maxDailyNotifications: 10,
      batchNotifications: false,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
    );
  }

  /// Create default notification preferences for a wallet
  static List<NotificationPreference> createDefaults({
    required String userId,
    required String walletId,
  }) {
    final now = DateTime.now();
    
    return [
      // Push notifications (enabled by default for important events)
      NotificationPreference(
        id: 'default-push-transaction-received',
        userId: userId,
        walletId: walletId,
        notificationType: WalletNotificationType.transactionReceived,
        channel: NotificationChannel.push,
        isEnabled: true,
        createdAt: now,
        updatedAt: now,
      ),
      NotificationPreference(
        id: 'default-push-transaction-sent',
        userId: userId,
        walletId: walletId,
        notificationType: WalletNotificationType.transactionSent,
        channel: NotificationChannel.push,
        isEnabled: true,
        createdAt: now,
        updatedAt: now,
      ),
      NotificationPreference(
        id: 'default-push-low-balance',
        userId: userId,
        walletId: walletId,
        notificationType: WalletNotificationType.lowBalance,
        channel: NotificationChannel.push,
        isEnabled: true,
        createdAt: now,
        updatedAt: now,
      ),
      NotificationPreference(
        id: 'default-push-spending-limit',
        userId: userId,
        walletId: walletId,
        notificationType: WalletNotificationType.spendingLimitReached,
        channel: NotificationChannel.push,
        isEnabled: true,
        createdAt: now,
        updatedAt: now,
      ),
      NotificationPreference(
        id: 'default-push-security-alert',
        userId: userId,
        walletId: walletId,
        notificationType: WalletNotificationType.securityAlert,
        channel: NotificationChannel.push,
        isEnabled: true,
        createdAt: now,
        updatedAt: now,
      ),
      
      // Email notifications (disabled by default except monthly summary)
      NotificationPreference(
        id: 'default-email-monthly-summary',
        userId: userId,
        walletId: walletId,
        notificationType: WalletNotificationType.monthlySummary,
        channel: NotificationChannel.email,
        isEnabled: true,
        createdAt: now,
        updatedAt: now,
      ),
      NotificationPreference(
        id: 'default-email-weekly-summary',
        userId: userId,
        walletId: walletId,
        notificationType: WalletNotificationType.weeklySummary,
        channel: NotificationChannel.email,
        isEnabled: false,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
