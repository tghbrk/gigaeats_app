import 'package:equatable/equatable.dart';

/// Address model for delivery and pickup locations
class Address extends Equatable {
  final String id;
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String? unitNumber;
  final String? buildingName;
  final String? landmark;
  final String? specialInstructions;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Address({
    required this.id,
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.unitNumber,
    this.buildingName,
    this.landmark,
    this.specialInstructions,
    this.latitude,
    this.longitude,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Address from JSON
  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      street: json['street'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      postalCode: json['postal_code'] as String,
      country: json['country'] as String,
      unitNumber: json['unit_number'] as String?,
      buildingName: json['building_name'] as String?,
      landmark: json['landmark'] as String?,
      specialInstructions: json['special_instructions'] as String?,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert Address to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'street': street,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'unit_number': unitNumber,
      'building_name': buildingName,
      'landmark': landmark,
      'special_instructions': specialInstructions,
      'latitude': latitude,
      'longitude': longitude,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of Address with updated fields
  Address copyWith({
    String? id,
    String? street,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? unitNumber,
    String? buildingName,
    String? landmark,
    String? specialInstructions,
    double? latitude,
    double? longitude,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Address(
      id: id ?? this.id,
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      unitNumber: unitNumber ?? this.unitNumber,
      buildingName: buildingName ?? this.buildingName,
      landmark: landmark ?? this.landmark,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get formatted address string
  String get formattedAddress {
    final parts = <String>[];
    
    if (unitNumber != null && unitNumber!.isNotEmpty) {
      parts.add('Unit $unitNumber');
    }
    
    if (buildingName != null && buildingName!.isNotEmpty) {
      parts.add(buildingName!);
    }
    
    parts.add(street);
    parts.add('$postalCode $city');
    parts.add(state);
    parts.add(country);
    
    return parts.join(', ');
  }

  /// Get short address string (street and city only)
  String get shortAddress {
    return '$street, $city';
  }

  /// Check if address has coordinates
  bool get hasCoordinates {
    return latitude != null && longitude != null;
  }

  /// Get display name for address (building name or street)
  String get displayName {
    if (buildingName != null && buildingName!.isNotEmpty) {
      return buildingName!;
    }
    return street;
  }

  /// Create a test address for development
  factory Address.test({
    String? id,
    String? street,
    String? city,
    String? state,
    String? postalCode,
    String? country,
  }) {
    final now = DateTime.now();
    return Address(
      id: id ?? 'test-address-1',
      street: street ?? 'Jalan Test 123',
      city: city ?? 'Kuala Lumpur',
      state: state ?? 'Selangor',
      postalCode: postalCode ?? '50000',
      country: country ?? 'Malaysia',
      unitNumber: 'A-12-3',
      buildingName: 'Test Building',
      landmark: 'Near Test Mall',
      specialInstructions: 'Ring the bell twice',
      latitude: 3.1390,
      longitude: 101.6869,
      isDefault: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create an empty address for forms
  factory Address.empty() {
    final now = DateTime.now();
    return Address(
      id: '',
      street: '',
      city: '',
      state: '',
      postalCode: '',
      country: 'Malaysia',
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  List<Object?> get props => [
        id,
        street,
        city,
        state,
        postalCode,
        country,
        unitNumber,
        buildingName,
        landmark,
        specialInstructions,
        latitude,
        longitude,
        isDefault,
        createdAt,
        updatedAt,
      ];
}
