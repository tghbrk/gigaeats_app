import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'vendor.g.dart';

@JsonSerializable()
class Vendor extends Equatable {
  final String id;
  @JsonKey(name: 'business_name')
  final String businessName;
  @JsonKey(name: 'user_id')
  final String? userId;
  @JsonKey(name: 'business_registration_number')
  final String businessRegistrationNumber;
  @JsonKey(name: 'business_address')
  final String businessAddress;
  @JsonKey(name: 'business_type')
  final String businessType;
  @JsonKey(name: 'cuisine_types')
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
    if (businessHours == null || businessHours!.isEmpty) {
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
    for (final entry in businessHours!.entries) {
      try {
        if (entry.value is Map<String, dynamic>) {
          schedule[entry.key] = DaySchedule.fromJson(entry.value as Map<String, dynamic>);
        }
      } catch (e) {
        // If parsing fails, use default for this day
        schedule[entry.key] = const DaySchedule(isOpen: true, openTime: '09:00', closeTime: '18:00');
      }
    }

    // Ensure all days are present
    final allDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    for (final day in allDays) {
      if (!schedule.containsKey(day)) {
        schedule[day] = const DaySchedule(isOpen: true, openTime: '09:00', closeTime: '18:00');
      }
    }

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
    return DaySchedule(
      isOpen: json['isOpen'] as bool?,
      openTime: json['openTime'] as String?,
      closeTime: json['closeTime'] as String?,
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
