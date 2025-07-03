import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'driver.g.dart';

/// Driver status enumeration
enum DriverStatus {
  @JsonValue('offline')
  offline,
  @JsonValue('online')
  online,
  @JsonValue('on_delivery')
  onDelivery;

  /// Display name for UI
  String get displayName {
    switch (this) {
      case DriverStatus.offline:
        return 'Offline';
      case DriverStatus.online:
        return 'Online';
      case DriverStatus.onDelivery:
        return 'On Delivery';
    }
  }

  /// Color for status indicator
  String get colorHex {
    switch (this) {
      case DriverStatus.offline:
        return '#9E9E9E'; // Grey
      case DriverStatus.online:
        return '#4CAF50'; // Green
      case DriverStatus.onDelivery:
        return '#2196F3'; // Blue
    }
  }

  /// Icon name for status
  String get iconName {
    switch (this) {
      case DriverStatus.offline:
        return 'cancel';
      case DriverStatus.online:
        return 'check_circle';
      case DriverStatus.onDelivery:
        return 'local_shipping';
    }
  }

  /// Whether driver is available for new assignments
  bool get isAvailable => this == DriverStatus.online;

  /// Create from string value
  static DriverStatus fromString(String value) {
    switch (value) {
      case 'offline':
        return DriverStatus.offline;
      case 'online':
        return DriverStatus.online;
      case 'on_delivery':
        return DriverStatus.onDelivery;
      default:
        return DriverStatus.offline;
    }
  }
}

/// Vehicle details model for structured vehicle information
@JsonSerializable()
class VehicleDetails extends Equatable {
  final String type; // motorcycle, car, bicycle, etc.
  final String plateNumber;
  final String? color;
  final String? brand;
  final String? model;
  final String? year;
  final Map<String, dynamic>? additionalInfo;

  const VehicleDetails({
    required this.type,
    required this.plateNumber,
    this.color,
    this.brand,
    this.model,
    this.year,
    this.additionalInfo,
  });

  factory VehicleDetails.fromJson(Map<String, dynamic> json) => _$VehicleDetailsFromJson(json);
  Map<String, dynamic> toJson() => _$VehicleDetailsToJson(this);

  /// Create from raw JSONB data
  factory VehicleDetails.fromJsonB(Map<String, dynamic> jsonb) {
    return VehicleDetails(
      type: jsonb['type'] ?? 'motorcycle',
      plateNumber: jsonb['plate_number'] ?? '',
      color: jsonb['color'],
      brand: jsonb['brand'],
      model: jsonb['model'],
      year: jsonb['year'],
      additionalInfo: Map<String, dynamic>.from(jsonb)
        ..removeWhere((key, value) => ['type', 'plate_number', 'color', 'brand', 'model', 'year'].contains(key)),
    );
  }

  /// Convert to JSONB format for database storage
  Map<String, dynamic> toJsonB() {
    final result = <String, dynamic>{
      'type': type,
      'plate_number': plateNumber,
    };
    
    if (color != null) result['color'] = color;
    if (brand != null) result['brand'] = brand;
    if (model != null) result['model'] = model;
    if (year != null) result['year'] = year;
    if (additionalInfo != null) result.addAll(additionalInfo!);
    
    return result;
  }

  /// Display string for vehicle
  String get displayString {
    final parts = <String>[];
    if (brand != null && model != null) {
      parts.add('$brand $model');
    } else if (brand != null) {
      parts.add(brand!);
    }
    parts.add(plateNumber);
    if (color != null) {
      parts.add('($color)');
    }
    return parts.join(' ');
  }

  /// Vehicle type display name
  String get typeDisplayName {
    switch (type.toLowerCase()) {
      case 'motorcycle':
        return 'Motorcycle';
      case 'car':
        return 'Car';
      case 'bicycle':
        return 'Bicycle';
      case 'van':
        return 'Van';
      case 'truck':
        return 'Truck';
      default:
        return type.toUpperCase();
    }
  }

  @override
  List<Object?> get props => [type, plateNumber, color, brand, model, year, additionalInfo];

  VehicleDetails copyWith({
    String? type,
    String? plateNumber,
    String? color,
    String? brand,
    String? model,
    String? year,
    Map<String, dynamic>? additionalInfo,
  }) {
    return VehicleDetails(
      type: type ?? this.type,
      plateNumber: plateNumber ?? this.plateNumber,
      color: color ?? this.color,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}

/// Driver location model for GPS coordinates
@JsonSerializable()
class DriverLocation extends Equatable {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracy; // GPS accuracy in meters
  final double? speed; // Speed in km/h
  final double? heading; // Direction in degrees (0-360)

  const DriverLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
    this.speed,
    this.heading,
  });

  factory DriverLocation.fromJson(Map<String, dynamic> json) => _$DriverLocationFromJson(json);
  Map<String, dynamic> toJson() => _$DriverLocationToJson(this);

  /// Create from PostGIS geometry data
  factory DriverLocation.fromPostGIS(Map<String, dynamic> data) {
    // Parse PostGIS POINT geometry
    final coordinates = data['coordinates'] as List<dynamic>;
    return DriverLocation(
      longitude: coordinates[0].toDouble(),
      latitude: coordinates[1].toDouble(),
      timestamp: DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String()),
      accuracy: data['accuracy']?.toDouble(),
      speed: data['speed']?.toDouble(),
      heading: data['heading']?.toDouble(),
    );
  }

  /// Convert to PostGIS format
  Map<String, dynamic> toPostGIS() {
    return {
      'type': 'Point',
      'coordinates': [longitude, latitude],
      'timestamp': timestamp.toIso8601String(),
      if (accuracy != null) 'accuracy': accuracy,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
    };
  }

  @override
  List<Object?> get props => [latitude, longitude, timestamp, accuracy, speed, heading];
}

/// Main Driver model
@JsonSerializable()
class Driver extends Equatable {
  final String id;
  @JsonKey(name: 'vendor_id')
  final String vendorId;
  @JsonKey(name: 'user_id')
  final String? userId; // Optional: if driver has app access
  final String name;
  @JsonKey(name: 'phone_number')
  final String phoneNumber;
  @JsonKey(name: 'profile_photo_url')
  final String? profilePhotoUrl;
  @JsonKey(name: 'vehicle_details', fromJson: _vehicleDetailsFromJson, toJson: _vehicleDetailsToJson)
  final VehicleDetails vehicleDetails;
  @JsonKey(fromJson: _driverStatusFromJson, toJson: _driverStatusToJson)
  final DriverStatus status;
  @JsonKey(name: 'last_location', fromJson: _locationFromJson, toJson: _locationToJson)
  final DriverLocation? lastLocation;
  @JsonKey(name: 'last_seen')
  final DateTime? lastSeen;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const Driver({
    required this.id,
    required this.vendorId,
    this.userId,
    required this.name,
    required this.phoneNumber,
    this.profilePhotoUrl,
    required this.vehicleDetails,
    required this.status,
    this.lastLocation,
    this.lastSeen,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Driver.fromJson(Map<String, dynamic> json) => _$DriverFromJson(json);
  Map<String, dynamic> toJson() => _$DriverToJson(this);

  /// Whether driver is currently available for assignment
  bool get isAvailable => isActive && status.isAvailable;

  /// Time since last seen
  Duration? get timeSinceLastSeen {
    if (lastSeen == null) return null;
    return DateTime.now().difference(lastSeen!);
  }

  /// Activity status based on last seen time
  String get activityStatus {
    final timeSince = timeSinceLastSeen;
    if (timeSince == null) return 'Unknown';
    
    if (timeSince.inMinutes <= 5) return 'Active';
    if (timeSince.inHours <= 1) return 'Recent';
    return 'Inactive';
  }

  @override
  List<Object?> get props => [
        id,
        vendorId,
        userId,
        name,
        phoneNumber,
        profilePhotoUrl,
        vehicleDetails,
        status,
        lastLocation,
        lastSeen,
        isActive,
        createdAt,
        updatedAt,
      ];

  Driver copyWith({
    String? id,
    String? vendorId,
    String? userId,
    String? name,
    String? phoneNumber,
    String? profilePhotoUrl,
    VehicleDetails? vehicleDetails,
    DriverStatus? status,
    DriverLocation? lastLocation,
    DateTime? lastSeen,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Driver(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      vehicleDetails: vehicleDetails ?? this.vehicleDetails,
      status: status ?? this.status,
      lastLocation: lastLocation ?? this.lastLocation,
      lastSeen: lastSeen ?? this.lastSeen,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// JSON conversion helper functions
VehicleDetails _vehicleDetailsFromJson(Map<String, dynamic>? json) {
  if (json == null) {
    return const VehicleDetails(type: 'motorcycle', plateNumber: '');
  }
  return VehicleDetails.fromJsonB(json);
}

Map<String, dynamic> _vehicleDetailsToJson(VehicleDetails details) => details.toJsonB();

DriverStatus _driverStatusFromJson(String status) => DriverStatus.fromString(status);

String _driverStatusToJson(DriverStatus status) => status.name;

DriverLocation? _locationFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  return DriverLocation.fromPostGIS(json);
}

Map<String, dynamic>? _locationToJson(DriverLocation? location) => location?.toPostGIS();
