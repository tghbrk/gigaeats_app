/// Temporary stub for sales agent notification preferences
class SalesAgentNotificationPreferences {
  final String id;
  final String salesAgentId;
  final bool orderNotifications;
  final bool commissionNotifications;
  final bool marketingNotifications;
  final bool systemNotifications;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SalesAgentNotificationPreferences({
    required this.id,
    required this.salesAgentId,
    this.orderNotifications = true,
    this.commissionNotifications = true,
    this.marketingNotifications = false,
    this.systemNotifications = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory SalesAgentNotificationPreferences.fromJson(Map<String, dynamic> json) {
    return SalesAgentNotificationPreferences(
      id: json['id'] ?? '',
      salesAgentId: json['sales_agent_id'] ?? '',
      orderNotifications: json['order_notifications'] ?? true,
      commissionNotifications: json['commission_notifications'] ?? true,
      marketingNotifications: json['marketing_notifications'] ?? false,
      systemNotifications: json['system_notifications'] ?? true,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sales_agent_id': salesAgentId,
      'order_notifications': orderNotifications,
      'commission_notifications': commissionNotifications,
      'marketing_notifications': marketingNotifications,
      'system_notifications': systemNotifications,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  SalesAgentNotificationPreferences copyWith({
    String? id,
    String? salesAgentId,
    bool? orderNotifications,
    bool? commissionNotifications,
    bool? marketingNotifications,
    bool? systemNotifications,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SalesAgentNotificationPreferences(
      id: id ?? this.id,
      salesAgentId: salesAgentId ?? this.salesAgentId,
      orderNotifications: orderNotifications ?? this.orderNotifications,
      commissionNotifications: commissionNotifications ?? this.commissionNotifications,
      marketingNotifications: marketingNotifications ?? this.marketingNotifications,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
