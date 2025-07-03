import 'package:freezed_annotation/freezed_annotation.dart';

part 'driver.freezed.dart';
part 'driver.g.dart';

/// Driver status enumeration
enum DriverStatus {
  @JsonValue('offline')
  offline,
  @JsonValue('online')
  online,
  @JsonValue('busy')
  busy,
  @JsonValue('unavailable')
  unavailable;

  String get displayName {
    switch (this) {
      case DriverStatus.offline:
        return 'Offline';
      case DriverStatus.online:
        return 'Online';
      case DriverStatus.busy:
        return 'Busy';
      case DriverStatus.unavailable:
        return 'Unavailable';
    }
  }

  /// Create from string value
  static DriverStatus fromString(String value) {
    switch (value) {
      case 'offline':
        return DriverStatus.offline;
      case 'online':
        return DriverStatus.online;
      case 'busy':
        return DriverStatus.busy;
      case 'unavailable':
        return DriverStatus.unavailable;
      case 'on_delivery': // Map on_delivery to busy for compatibility
        return DriverStatus.busy;
      default:
        return DriverStatus.offline;
    }
  }
}

/// Vehicle type enumeration
enum VehicleType {
  @JsonValue('motorcycle')
  motorcycle,
  @JsonValue('car')
  car,
  @JsonValue('bicycle')
  bicycle,
  @JsonValue('scooter')
  scooter;

  String get displayName {
    switch (this) {
      case VehicleType.motorcycle:
        return 'Motorcycle';
      case VehicleType.car:
        return 'Car';
      case VehicleType.bicycle:
        return 'Bicycle';
      case VehicleType.scooter:
        return 'Scooter';
    }
  }
}

/// Driver model
@freezed
class Driver with _$Driver {
  const Driver._();

  const factory Driver({
    required String id,
    required String userId,
    required String fullName,
    required String email,
    required String phoneNumber,
    String? alternatePhoneNumber,
    String? profileImageUrl,
    required DriverStatus status,
    required bool isActive,
    required bool isVerified,
    String? licenseNumber,
    String? vehiclePlateNumber,
    required VehicleType vehicleType,
    String? vehicleModel,
    String? vehicleColor,
    double? currentLatitude,
    double? currentLongitude,
    DateTime? lastLocationUpdate,
    double? rating,
    int? totalDeliveries,
    double? totalEarnings,
    DateTime? lastActiveAt,
    required DateTime createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) = _Driver;

  factory Driver.fromJson(Map<String, dynamic> json) => _$DriverFromJson(json);

  /// Convenience getter for name (returns fullName)
  String get name => fullName;
}

/// Driver statistics model
@freezed
class DriverStats with _$DriverStats {
  const factory DriverStats({
    required String driverId,
    required int totalDeliveries,
    required int completedDeliveries,
    required double totalEarnings,
    required double averageRating,
    required double averageDeliveryTime,
    required int todayDeliveries,
    required double todayEarnings,
    required int thisWeekDeliveries,
    required double thisWeekEarnings,
    required int thisMonthDeliveries,
    required double thisMonthEarnings,
    required DateTime lastUpdated,
  }) = _DriverStats;

  factory DriverStats.fromJson(Map<String, dynamic> json) => _$DriverStatsFromJson(json);
}

/// Driver location model
@freezed
class DriverLocation with _$DriverLocation {
  const factory DriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    double? heading,
    required DateTime timestamp,
  }) = _DriverLocation;

  factory DriverLocation.fromJson(Map<String, dynamic> json) => _$DriverLocationFromJson(json);
}
