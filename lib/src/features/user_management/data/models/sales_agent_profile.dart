import 'package:freezed_annotation/freezed_annotation.dart';

part 'sales_agent_profile.freezed.dart';
part 'sales_agent_profile.g.dart';

/// Sales agent profile model
@freezed
class SalesAgentProfile with _$SalesAgentProfile {
  const factory SalesAgentProfile({
    required String id,
    required String userId,
    required String fullName,
    required String email,
    required String phoneNumber,
    String? alternatePhoneNumber,
    String? profileImageUrl,
    required bool isActive,
    required bool isAvailable,
    String? territory,
    double? commissionRate,
    DateTime? lastActiveAt,
    required DateTime createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) = _SalesAgentProfile;

  factory SalesAgentProfile.fromJson(Map<String, dynamic> json) => _$SalesAgentProfileFromJson(json);
}

/// Sales agent statistics model
@freezed
class SalesAgentStats with _$SalesAgentStats {
  const factory SalesAgentStats({
    required String salesAgentId,
    required int totalCustomers,
    required int totalOrders,
    required double totalRevenue,
    required double totalCommission,
    required int thisMonthOrders,
    required double thisMonthRevenue,
    required double thisMonthCommission,
    required int activeOrders,
    required DateTime lastUpdated,
  }) = _SalesAgentStats;

  factory SalesAgentStats.fromJson(Map<String, dynamic> json) => _$SalesAgentStatsFromJson(json);
}

/// Sales agent territory model
@freezed
class SalesAgentTerritory with _$SalesAgentTerritory {
  const factory SalesAgentTerritory({
    required String id,
    required String name,
    required String description,
    List<String>? postcodes,
    List<String>? areas,
    bool? isActive,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _SalesAgentTerritory;

  factory SalesAgentTerritory.fromJson(Map<String, dynamic> json) => _$SalesAgentTerritoryFromJson(json);
}
