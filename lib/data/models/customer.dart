import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'customer.g.dart';

@JsonSerializable()
class Customer extends Equatable {
  final String id;
  final String salesAgentId;
  final CustomerType type;
  final String organizationName;
  final String contactPersonName;
  final String email;
  final String phoneNumber;
  final String? alternatePhoneNumber;
  final CustomerAddress address;
  final CustomerBusinessInfo? businessInfo;
  final CustomerPreferences preferences;
  final double totalSpent;
  final int totalOrders;
  final double averageOrderValue;
  final DateTime lastOrderDate;
  final bool isActive;
  final bool isVerified;
  final String? notes;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    required this.id,
    required this.salesAgentId,
    required this.type,
    required this.organizationName,
    required this.contactPersonName,
    required this.email,
    required this.phoneNumber,
    this.alternatePhoneNumber,
    required this.address,
    this.businessInfo,
    required this.preferences,
    this.totalSpent = 0.0,
    this.totalOrders = 0,
    this.averageOrderValue = 0.0,
    required this.lastOrderDate,
    this.isActive = true,
    this.isVerified = false,
    this.notes,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => _$CustomerFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerToJson(this);

  Customer copyWith({
    String? id,
    String? salesAgentId,
    CustomerType? type,
    String? organizationName,
    String? contactPersonName,
    String? email,
    String? phoneNumber,
    String? alternatePhoneNumber,
    CustomerAddress? address,
    CustomerBusinessInfo? businessInfo,
    CustomerPreferences? preferences,
    double? totalSpent,
    int? totalOrders,
    double? averageOrderValue,
    DateTime? lastOrderDate,
    bool? isActive,
    bool? isVerified,
    String? notes,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      salesAgentId: salesAgentId ?? this.salesAgentId,
      type: type ?? this.type,
      organizationName: organizationName ?? this.organizationName,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      alternatePhoneNumber: alternatePhoneNumber ?? this.alternatePhoneNumber,
      address: address ?? this.address,
      businessInfo: businessInfo ?? this.businessInfo,
      preferences: preferences ?? this.preferences,
      totalSpent: totalSpent ?? this.totalSpent,
      totalOrders: totalOrders ?? this.totalOrders,
      averageOrderValue: averageOrderValue ?? this.averageOrderValue,
      lastOrderDate: lastOrderDate ?? this.lastOrderDate,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convenience getters for backward compatibility
  String get businessName => organizationName;
  String get contactPerson => contactPersonName;

  @override
  List<Object?> get props => [
        id,
        salesAgentId,
        type,
        organizationName,
        contactPersonName,
        email,
        phoneNumber,
        alternatePhoneNumber,
        address,
        businessInfo,
        preferences,
        totalSpent,
        totalOrders,
        averageOrderValue,
        lastOrderDate,
        isActive,
        isVerified,
        notes,
        tags,
        createdAt,
        updatedAt,
      ];
}

@JsonEnum()
enum CustomerType {
  @JsonValue('corporate')
  corporate,
  @JsonValue('school')
  school,
  @JsonValue('hospital')
  hospital,
  @JsonValue('government')
  government,
  @JsonValue('event')
  event,
  @JsonValue('catering')
  catering,
  @JsonValue('other')
  other;

  String get displayName {
    switch (this) {
      case CustomerType.corporate:
        return 'Corporate';
      case CustomerType.school:
        return 'School/University';
      case CustomerType.hospital:
        return 'Hospital/Healthcare';
      case CustomerType.government:
        return 'Government';
      case CustomerType.event:
        return 'Event/Wedding';
      case CustomerType.catering:
        return 'Catering Service';
      case CustomerType.other:
        return 'Other';
    }
  }
}

@JsonSerializable()
class CustomerAddress extends Equatable {
  final String street;
  final String city;
  final String state;
  final String postcode;
  final String country;
  final String? buildingName;
  final String? floor;
  final String? unit;
  final String? deliveryInstructions;
  final double? latitude;
  final double? longitude;

  const CustomerAddress({
    required this.street,
    required this.city,
    required this.state,
    required this.postcode,
    this.country = 'Malaysia',
    this.buildingName,
    this.floor,
    this.unit,
    this.deliveryInstructions,
    this.latitude,
    this.longitude,
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) => _$CustomerAddressFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerAddressToJson(this);

  String get fullAddress {
    final parts = <String>[];
    if (buildingName != null) parts.add(buildingName!);
    if (floor != null && unit != null) {
      parts.add('$floor-$unit');
    } else if (floor != null) {
      parts.add('Floor $floor');
    } else if (unit != null) {
      parts.add('Unit $unit');
    }
    parts.add(street);
    parts.add('$postcode $city');
    parts.add(state);
    parts.add(country);
    return parts.join(', ');
  }

  @override
  List<Object?> get props => [
        street,
        city,
        state,
        postcode,
        country,
        buildingName,
        floor,
        unit,
        deliveryInstructions,
        latitude,
        longitude,
      ];
}

@JsonSerializable()
class CustomerBusinessInfo extends Equatable {
  final String? companyRegistrationNumber;
  final String? taxId;
  final String industry;
  final int employeeCount;
  final String? website;
  final List<String> businessHours;
  final bool requiresInvoice;
  final String? billingEmail;

  const CustomerBusinessInfo({
    this.companyRegistrationNumber,
    this.taxId,
    required this.industry,
    required this.employeeCount,
    this.website,
    this.businessHours = const [],
    this.requiresInvoice = false,
    this.billingEmail,
  });

  factory CustomerBusinessInfo.fromJson(Map<String, dynamic> json) => _$CustomerBusinessInfoFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerBusinessInfoToJson(this);

  @override
  List<Object?> get props => [
        companyRegistrationNumber,
        taxId,
        industry,
        employeeCount,
        website,
        businessHours,
        requiresInvoice,
        billingEmail,
      ];
}

@JsonSerializable()
class CustomerPreferences extends Equatable {
  final List<String> preferredCuisines;
  final List<String> dietaryRestrictions;
  final bool halalOnly;
  final bool vegetarianOptions;
  final bool veganOptions;
  final int spiceToleranceLevel; // 0-5
  final double budgetRangeMin;
  final double budgetRangeMax;
  final List<String> preferredDeliveryTimes;
  final int advanceOrderDays;
  final bool allowSubstitutions;
  final String? specialInstructions;

  const CustomerPreferences({
    this.preferredCuisines = const [],
    this.dietaryRestrictions = const [],
    this.halalOnly = false,
    this.vegetarianOptions = false,
    this.veganOptions = false,
    this.spiceToleranceLevel = 2,
    this.budgetRangeMin = 0.0,
    this.budgetRangeMax = 1000.0,
    this.preferredDeliveryTimes = const [],
    this.advanceOrderDays = 1,
    this.allowSubstitutions = true,
    this.specialInstructions,
  });

  factory CustomerPreferences.fromJson(Map<String, dynamic> json) => _$CustomerPreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerPreferencesToJson(this);

  @override
  List<Object?> get props => [
        preferredCuisines,
        dietaryRestrictions,
        halalOnly,
        vegetarianOptions,
        veganOptions,
        spiceToleranceLevel,
        budgetRangeMin,
        budgetRangeMax,
        preferredDeliveryTimes,
        advanceOrderDays,
        allowSubstitutions,
        specialInstructions,
      ];
}
