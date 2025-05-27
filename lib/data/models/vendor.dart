import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'vendor.g.dart';

@JsonSerializable()
class Vendor extends Equatable {
  final String id;
  final String businessName;
  final String ownerName;
  final String email;
  final String phoneNumber;
  final String description;
  final VendorAddress address;
  final List<String> cuisineTypes;
  final VendorBusinessInfo businessInfo;
  final VendorSettings settings;
  final double rating;
  final int totalReviews;
  final bool isActive;
  final bool isVerified;
  final bool isHalalCertified;
  final String? profileImageUrl;
  final String? coverImageUrl;
  final List<String> galleryImages;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Vendor({
    required this.id,
    required this.businessName,
    required this.ownerName,
    required this.email,
    required this.phoneNumber,
    required this.description,
    required this.address,
    required this.cuisineTypes,
    required this.businessInfo,
    required this.settings,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.isActive = true,
    this.isVerified = false,
    this.isHalalCertified = false,
    this.profileImageUrl,
    this.coverImageUrl,
    this.galleryImages = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) => _$VendorFromJson(json);
  Map<String, dynamic> toJson() => _$VendorToJson(this);

  Vendor copyWith({
    String? id,
    String? businessName,
    String? ownerName,
    String? email,
    String? phoneNumber,
    String? description,
    VendorAddress? address,
    List<String>? cuisineTypes,
    VendorBusinessInfo? businessInfo,
    VendorSettings? settings,
    double? rating,
    int? totalReviews,
    bool? isActive,
    bool? isVerified,
    bool? isHalalCertified,
    String? profileImageUrl,
    String? coverImageUrl,
    List<String>? galleryImages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vendor(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      description: description ?? this.description,
      address: address ?? this.address,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      businessInfo: businessInfo ?? this.businessInfo,
      settings: settings ?? this.settings,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      isHalalCertified: isHalalCertified ?? this.isHalalCertified,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        businessName,
        ownerName,
        email,
        phoneNumber,
        description,
        address,
        cuisineTypes,
        businessInfo,
        settings,
        rating,
        totalReviews,
        isActive,
        isVerified,
        isHalalCertified,
        profileImageUrl,
        coverImageUrl,
        galleryImages,
        createdAt,
        updatedAt,
      ];
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
  final bool isOpen;
  final String? openTime;
  final String? closeTime;
  final String? breakStart;
  final String? breakEnd;

  const DaySchedule({
    required this.isOpen,
    this.openTime,
    this.closeTime,
    this.breakStart,
    this.breakEnd,
  });

  factory DaySchedule.fromJson(Map<String, dynamic> json) => _$DayScheduleFromJson(json);
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
