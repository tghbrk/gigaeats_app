import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

part 'vendor.g.dart';

// Helper functions for null-safe String parsing
String _safeStringFromJson(dynamic value) => value?.toString() ?? '';
String _businessNameFromJson(dynamic value) => value?.toString() ?? 'Unknown Business';
String _businessAddressFromJson(dynamic value) => value?.toString() ?? 'Unknown Address';
String _businessTypeFromJson(dynamic value) => value?.toString() ?? 'Restaurant';
String _businessRegistrationFromJson(dynamic value) => value?.toString() ?? '';
List<String> _safeCuisineTypesFromJson(dynamic value) {
  if (value == null) return ['General'];
  if (value is List) {
    return value.map((e) => e?.toString() ?? 'General').toList();
  }
  return ['General'];
}

@JsonSerializable()
class Vendor extends Equatable {
  @JsonKey(fromJson: _safeStringFromJson)
  final String id;
  @JsonKey(name: 'business_name', fromJson: _businessNameFromJson)
  final String businessName;
  @JsonKey(name: 'user_id')
  final String? userId;
  @JsonKey(name: 'business_registration_number', fromJson: _businessRegistrationFromJson)
  final String businessRegistrationNumber;
  @JsonKey(name: 'business_address', fromJson: _businessAddressFromJson)
  final String businessAddress;
  @JsonKey(name: 'business_type', fromJson: _businessTypeFromJson)
  final String businessType;
  @JsonKey(name: 'cuisine_types', fromJson: _safeCuisineTypesFromJson)
  final List<String> cuisineTypes;
  @JsonKey(name: 'is_halal_certified')
  final bool isHalalCertified;
  @JsonKey(name: 'halal_certification_number')
  final String? halalCertificationNumber;
  final String? description;
  final double rating;
  @JsonKey(name: 'total_reviews')
  final int totalReviews;
  @JsonKey(name: 'total_orders')
  final int totalOrders;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  @JsonKey(name: 'cover_image_url')
  final String? coverImageUrl;
  @JsonKey(name: 'gallery_images')
  final List<String> galleryImages;
  @JsonKey(name: 'business_hours')
  final Map<String, dynamic>? businessHours;
  @JsonKey(name: 'service_areas')
  final List<String>? serviceAreas;
  @JsonKey(name: 'minimum_order_amount')
  final double? minimumOrderAmount;
  @JsonKey(name: 'delivery_fee')
  final double? deliveryFee;
  @JsonKey(name: 'free_delivery_threshold')
  final double? freeDeliveryThreshold;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const Vendor({
    required this.id,
    required this.businessName,
    this.userId,
    required this.businessRegistrationNumber,
    required this.businessAddress,
    required this.businessType,
    required this.cuisineTypes,
    this.isHalalCertified = false,
    this.halalCertificationNumber,
    this.description,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.totalOrders = 0,
    this.isActive = true,
    this.isVerified = false,
    this.coverImageUrl,
    this.galleryImages = const [],
    this.businessHours,
    this.serviceAreas,
    this.minimumOrderAmount,
    this.deliveryFee,
    this.freeDeliveryThreshold,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) => _$VendorFromJson(json);
  Map<String, dynamic> toJson() => _$VendorToJson(this);

  Vendor copyWith({
    String? id,
    String? businessName,
    String? userId,
    String? businessRegistrationNumber,
    String? businessAddress,
    String? businessType,
    List<String>? cuisineTypes,
    bool? isHalalCertified,
    String? halalCertificationNumber,
    String? description,
    double? rating,
    int? totalReviews,
    int? totalOrders,
    bool? isActive,
    bool? isVerified,
    String? coverImageUrl,
    List<String>? galleryImages,
    Map<String, dynamic>? businessHours,
    List<String>? serviceAreas,
    double? minimumOrderAmount,
    double? deliveryFee,
    double? freeDeliveryThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vendor(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      userId: userId ?? this.userId,
      businessRegistrationNumber: businessRegistrationNumber ?? this.businessRegistrationNumber,
      businessAddress: businessAddress ?? this.businessAddress,
      businessType: businessType ?? this.businessType,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      isHalalCertified: isHalalCertified ?? this.isHalalCertified,
      halalCertificationNumber: halalCertificationNumber ?? this.halalCertificationNumber,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalOrders: totalOrders ?? this.totalOrders,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      businessHours: businessHours ?? this.businessHours,
      serviceAreas: serviceAreas ?? this.serviceAreas,
      minimumOrderAmount: minimumOrderAmount ?? this.minimumOrderAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      freeDeliveryThreshold: freeDeliveryThreshold ?? this.freeDeliveryThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        businessName,
        userId,
        businessRegistrationNumber,
        businessAddress,
        businessType,
        cuisineTypes,
        isHalalCertified,
        halalCertificationNumber,
        description,
        rating,
        totalReviews,
        totalOrders,
        isActive,
        isVerified,
        coverImageUrl,
        galleryImages,
        businessHours,
        serviceAreas,
        minimumOrderAmount,
        deliveryFee,
        freeDeliveryThreshold,
        createdAt,
        updatedAt,
      ];

  // Helper getters for backward compatibility with UI components
  String get fullAddress => businessAddress;

  // Create a simple address object for compatibility
  VendorAddress get address => VendorAddress(
    street: businessAddress,
    city: serviceAreas?.isNotEmpty == true ? serviceAreas!.first : 'Unknown',
    state: 'Selangor', // Default for Malaysia
    postcode: '50000', // Default
  );

  // Create a simple business info object for compatibility
  VendorBusinessInfo get businessInfo => VendorBusinessInfo(
    ssmNumber: businessRegistrationNumber,
    halalCertNumber: halalCertificationNumber,
    minimumOrderAmount: minimumOrderAmount ?? 0.0,
    deliveryRadius: 10.0, // Default
    paymentMethods: ['Cash', 'Online Banking'], // Default
    operatingHours: VendorOperatingHours(
      schedule: _parseBusinessHours(),
    ),
  );

  // Parse business hours from database JSON
  Map<String, DaySchedule> _parseBusinessHours() {
    debugPrint('🕒 [BUSINESS-HOURS-PARSE] Starting business hours parsing');
    debugPrint('🕒 [BUSINESS-HOURS-PARSE] Raw businessHours: $businessHours');

    if (businessHours == null || businessHours!.isEmpty) {
      debugPrint('🕒 [BUSINESS-HOURS-PARSE] No business hours data, using defaults');
      // Return default hours if no data
      return {
        'monday': const DaySchedule(isOpen: true, openTime: '09:00', closeTime: '18:00'),
        'tuesday': const DaySchedule(isOpen: true, openTime: '09:00', closeTime: '18:00'),
        'wednesday': const DaySchedule(isOpen: true, openTime: '09:00', closeTime: '18:00'),
        'thursday': const DaySchedule(isOpen: true, openTime: '09:00', closeTime: '18:00'),
        'friday': const DaySchedule(isOpen: true, openTime: '09:00', closeTime: '18:00'),
        'saturday': const DaySchedule(isOpen: true, openTime: '09:00', closeTime: '18:00'),
        'sunday': const DaySchedule(isOpen: false),
      };
    }

    // Parse actual business hours from database
    final Map<String, DaySchedule> schedule = {};
    debugPrint('🕒 [BUSINESS-HOURS-PARSE] Parsing ${businessHours!.length} day entries');

    for (final entry in businessHours!.entries) {
      try {
        debugPrint('🕒 [BUSINESS-HOURS-PARSE] Processing day: ${entry.key}');
        debugPrint('🕒 [BUSINESS-HOURS-PARSE] Day data: ${entry.value}');

        if (entry.value is Map<String, dynamic>) {
          final daySchedule = DaySchedule.fromJson(entry.value as Map<String, dynamic>);
          schedule[entry.key] = daySchedule;
          debugPrint('🕒 [BUSINESS-HOURS-PARSE] Successfully parsed ${entry.key}: isOpen=${daySchedule.isOpen}, open=${daySchedule.openTime}, close=${daySchedule.closeTime}');
        } else {
          debugPrint('⚠️ [BUSINESS-HOURS-PARSE] Invalid data type for ${entry.key}: ${entry.value.runtimeType}');
        }
      } catch (e) {
        debugPrint('❌ [BUSINESS-HOURS-PARSE] Failed to parse ${entry.key}: $e');
        // If parsing fails, use default for this day
        schedule[entry.key] = const DaySchedule(isOpen: true, openTime: '09:00', closeTime: '18:00');
      }
    }

    // Ensure all days are present
    final allDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    for (final day in allDays) {
      if (!schedule.containsKey(day)) {
        debugPrint('🕒 [BUSINESS-HOURS-PARSE] Adding missing day: $day with defaults');
        schedule[day] = const DaySchedule(isOpen: true, openTime: '09:00', closeTime: '18:00');
      }
    }

    debugPrint('🕒 [BUSINESS-HOURS-PARSE] Final parsed schedule: ${schedule.map((k, v) => MapEntry(k, v.safeIsOpen ? "${v.openTime}-${v.closeTime}" : "Closed"))}');
    return schedule;
  }

  // Create default settings for compatibility
  VendorSettings get settings => VendorSettings();

  // Placeholder fields for backward compatibility
  String get ownerName => 'Owner'; // Placeholder
  String get email => '${userId ?? 'unknown'}@example.com'; // Placeholder
  String get phoneNumber => '+60123456789'; // Placeholder
  String? get profileImageUrl => null; // Not available in current schema
}

@JsonSerializable()
class VendorAddress extends Equatable {
  final String street;
  final String city;
  final String state;
  final String postcode;
  final String country;
  final double? latitude;
  final double? longitude;

  const VendorAddress({
    required this.street,
    required this.city,
    required this.state,
    required this.postcode,
    this.country = 'Malaysia',
    this.latitude,
    this.longitude,
  });

  factory VendorAddress.fromJson(Map<String, dynamic> json) => _$VendorAddressFromJson(json);
  Map<String, dynamic> toJson() => _$VendorAddressToJson(this);

  String get fullAddress => '$street, $postcode $city, $state, $country';

  @override
  List<Object?> get props => [street, city, state, postcode, country, latitude, longitude];
}

@JsonSerializable()
class VendorBusinessInfo extends Equatable {
  final String ssmNumber;
  final String? halalCertNumber;
  final String? businessLicense;
  final double minimumOrderAmount;
  final double deliveryRadius;
  final List<String> paymentMethods;
  final VendorOperatingHours operatingHours;

  const VendorBusinessInfo({
    required this.ssmNumber,
    this.halalCertNumber,
    this.businessLicense,
    required this.minimumOrderAmount,
    required this.deliveryRadius,
    required this.paymentMethods,
    required this.operatingHours,
  });

  factory VendorBusinessInfo.fromJson(Map<String, dynamic> json) => _$VendorBusinessInfoFromJson(json);
  Map<String, dynamic> toJson() => _$VendorBusinessInfoToJson(this);

  @override
  List<Object?> get props => [
        ssmNumber,
        halalCertNumber,
        businessLicense,
        minimumOrderAmount,
        deliveryRadius,
        paymentMethods,
        operatingHours,
      ];
}

@JsonSerializable()
class VendorOperatingHours extends Equatable {
  final Map<String, DaySchedule> schedule;
  final bool isOpen24Hours;
  final List<String> holidays;

  const VendorOperatingHours({
    required this.schedule,
    this.isOpen24Hours = false,
    this.holidays = const [],
  });

  factory VendorOperatingHours.fromJson(Map<String, dynamic> json) => _$VendorOperatingHoursFromJson(json);
  Map<String, dynamic> toJson() => _$VendorOperatingHoursToJson(this);

  @override
  List<Object?> get props => [schedule, isOpen24Hours, holidays];
}

@JsonSerializable()
class DaySchedule extends Equatable {
  @JsonKey(defaultValue: false)
  final bool? isOpen;
  final String? openTime;
  final String? closeTime;
  final String? breakStart;
  final String? breakEnd;

  const DaySchedule({
    this.isOpen,
    this.openTime,
    this.closeTime,
    this.breakStart,
    this.breakEnd,
  });

  // Helper getter for safe access
  bool get safeIsOpen => isOpen ?? false;

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    // Support both field naming conventions for backward compatibility
    final isOpen = json['isOpen'] as bool? ?? json['is_open'] as bool?;
    final openTime = json['openTime'] as String? ?? json['open'] as String?;
    final closeTime = json['closeTime'] as String? ?? json['close'] as String?;

    return DaySchedule(
      isOpen: isOpen,
      openTime: openTime,
      closeTime: closeTime,
      breakStart: json['breakStart'] as String?,
      breakEnd: json['breakEnd'] as String?,
    );
  }
  Map<String, dynamic> toJson() => _$DayScheduleToJson(this);

  @override
  List<Object?> get props => [isOpen, openTime, closeTime, breakStart, breakEnd];
}

@JsonSerializable()
class VendorSettings extends Equatable {
  final bool acceptsPreOrders;
  final int maxPreOrderDays;
  final bool autoAcceptOrders;
  final int preparationTimeMinutes;
  final double commissionRate;
  final bool isAvailableForDelivery;
  final bool isAvailableForPickup;

  const VendorSettings({
    this.acceptsPreOrders = true,
    this.maxPreOrderDays = 7,
    this.autoAcceptOrders = false,
    this.preparationTimeMinutes = 60,
    this.commissionRate = 0.07,
    this.isAvailableForDelivery = true,
    this.isAvailableForPickup = false,
  });

  factory VendorSettings.fromJson(Map<String, dynamic> json) => _$VendorSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$VendorSettingsToJson(this);

  @override
  List<Object?> get props => [
        acceptsPreOrders,
        maxPreOrderDays,
        autoAcceptOrders,
        preparationTimeMinutes,
        commissionRate,
        isAvailableForDelivery,
        isAvailableForPickup,
      ];
}
