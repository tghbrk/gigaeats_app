import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

part 'customer.g.dart';

@JsonSerializable()
class Customer extends Equatable {
  final String id;
  @JsonKey(name: 'sales_agent_id')
  final String salesAgentId;
  @JsonKey(name: 'customer_type')
  final CustomerType type;
  @JsonKey(name: 'organization_name')
  final String organizationName;
  @JsonKey(name: 'contact_person_name')
  final String contactPersonName;
  final String email;
  @JsonKey(name: 'phone_number')
  final String phoneNumber;
  @JsonKey(name: 'alternate_phone_number')
  final String? alternatePhoneNumber;
  final CustomerAddress address;
  @JsonKey(name: 'business_info')
  final CustomerBusinessInfo? businessInfo;
  final CustomerPreferences preferences;
  @JsonKey(name: 'total_spent')
  final double totalSpent;
  @JsonKey(name: 'total_orders')
  final int totalOrders;
  @JsonKey(name: 'average_order_value')
  final double averageOrderValue;
  @JsonKey(name: 'last_order_date')
  final DateTime? lastOrderDate;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  final String? notes;
  final List<String> tags;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
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
    this.lastOrderDate,
    this.isActive = true,
    this.isVerified = false,
    this.notes,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Safe string conversion helper to handle type casting issues
  static String _safeStringConversion(dynamic value, String fieldName) {
    try {
      if (value == null) {
        debugPrint('Customer._safeStringConversion: Field $fieldName is null, using empty string');
        return '';
      }
      if (value is String) {
        return value;
      }
      final stringValue = value.toString();
      debugPrint('Customer._safeStringConversion: Converted $fieldName from ${value.runtimeType} to String: "$stringValue"');
      return stringValue;
    } catch (e) {
      debugPrint('Customer._safeStringConversion: Error converting $fieldName (${value.runtimeType}): $e');
      debugPrint('Customer._safeStringConversion: Value was: $value');
      return '';
    }
  }

  /// Safe numeric conversion helper for double values
  static double? _safeDoubleConversion(dynamic value, String fieldName) {
    try {
      if (value == null) {
        debugPrint('Customer._safeDoubleConversion: Field $fieldName is null, returning null');
        return null;
      }

      if (value is double) {
        return value;
      }

      if (value is int) {
        return value.toDouble();
      }

      if (value is String) {
        if (value.isEmpty) {
          debugPrint('Customer._safeDoubleConversion: Field $fieldName is empty string, returning 0.0');
          return 0.0;
        }
        final parsed = double.parse(value);
        debugPrint('Customer._safeDoubleConversion: Converted $fieldName from String "$value" to double $parsed');
        return parsed;
      }

      debugPrint('Customer._safeDoubleConversion: Unexpected type for $fieldName: ${value.runtimeType}, value: $value');
      return 0.0; // Default fallback
    } catch (e) {
      debugPrint('Customer._safeDoubleConversion: Error converting $fieldName (${value.runtimeType}): $e');
      debugPrint('Customer._safeDoubleConversion: Value was: $value');
      return 0.0; // Default to 0.0 for invalid values
    }
  }

  /// Safe integer conversion helper
  static int? _safeIntConversion(dynamic value, String fieldName) {
    try {
      if (value == null) {
        debugPrint('Customer._safeIntConversion: Field $fieldName is null, returning null');
        return null;
      }

      if (value is int) {
        return value;
      }

      if (value is double) {
        return value.toInt();
      }

      if (value is String) {
        if (value.isEmpty) {
          debugPrint('Customer._safeIntConversion: Field $fieldName is empty string, returning 0');
          return 0;
        }
        final parsed = int.parse(value);
        debugPrint('Customer._safeIntConversion: Converted $fieldName from String "$value" to int $parsed');
        return parsed;
      }

      debugPrint('Customer._safeIntConversion: Unexpected type for $fieldName: ${value.runtimeType}, value: $value');
      return 0; // Default fallback
    } catch (e) {
      debugPrint('Customer._safeIntConversion: Error converting $fieldName (${value.runtimeType}): $e');
      debugPrint('Customer._safeIntConversion: Value was: $value');
      return 0; // Default to 0 for invalid values
    }
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    try {
      // Handle potential null values and provide defaults
      final processedJson = Map<String, dynamic>.from(json);

      // Ensure required string fields are not null with enhanced type safety
      processedJson['id'] = _safeStringConversion(json['id'], 'id');
      processedJson['sales_agent_id'] = _safeStringConversion(json['sales_agent_id'], 'sales_agent_id');
      processedJson['organization_name'] = _safeStringConversion(json['organization_name'], 'organization_name');
      processedJson['contact_person_name'] = _safeStringConversion(json['contact_person_name'], 'contact_person_name');
      processedJson['email'] = _safeStringConversion(json['email'], 'email');
      processedJson['phone_number'] = _safeStringConversion(json['phone_number'], 'phone_number');

      // Handle customer_type enum
      if (json['customer_type'] == null) {
        processedJson['customer_type'] = 'other';
      }

      // Handle nested objects with defaults
      final addressData = json['address'];
      if (addressData == null || (addressData is Map && addressData.isEmpty)) {
        processedJson['address'] = {
          'street': '',
          'city': '',
          'state': '',
          'postcode': '',
          'country': 'Malaysia',
        };
      } else if (addressData is Map) {
        // Ensure all required address fields exist
        final addressMap = Map<String, dynamic>.from(addressData);
        addressMap['street'] = _safeStringConversion(addressMap['street'], 'address.street');
        addressMap['city'] = _safeStringConversion(addressMap['city'], 'address.city');
        addressMap['state'] = _safeStringConversion(addressMap['state'], 'address.state');

        // Handle both 'postcode' and 'postal_code' field names
        final postcodeValue = addressMap['postcode'] ?? addressMap['postal_code'];
        addressMap['postcode'] = _safeStringConversion(postcodeValue, 'address.postcode');

        final countryValue = addressMap['country'] ?? 'Malaysia';
        addressMap['country'] = _safeStringConversion(countryValue, 'address.country');

        // Handle optional fields
        addressMap['building_name'] = _safeStringConversion(addressMap['building_name'], 'address.building_name');
        addressMap['floor'] = _safeStringConversion(addressMap['floor'], 'address.floor');
        addressMap['unit'] = _safeStringConversion(addressMap['unit'], 'address.unit');
        addressMap['delivery_instructions'] = _safeStringConversion(addressMap['delivery_instructions'], 'address.delivery_instructions');

        // Handle numeric fields
        addressMap['latitude'] = (addressMap['latitude'] as num?)?.toDouble();
        addressMap['longitude'] = (addressMap['longitude'] as num?)?.toDouble();

        processedJson['address'] = addressMap;
      }

      // Handle preferences - check if it's null or empty object
      final preferencesData = json['preferences'];
      if (preferencesData == null || (preferencesData is Map && preferencesData.isEmpty)) {
        processedJson['preferences'] = {
          'preferred_cuisines': <String>[],
          'dietary_restrictions': <String>[],
          'halal_only': false,
          'vegetarian_options': false,
          'vegan_options': false,
          'spice_tolerance_level': 2,
          'budget_range_min': 0.0,
          'budget_range_max': 1000.0,
          'preferred_delivery_times': <String>[],
          'advance_order_days': 1,
          'allow_substitutions': true,
        };
      } else if (preferencesData is Map) {
        // Ensure all required preference fields exist with defaults
        final preferencesMap = Map<String, dynamic>.from(preferencesData);
        preferencesMap['preferred_cuisines'] = preferencesMap['preferred_cuisines'] ?? <String>[];
        preferencesMap['dietary_restrictions'] = preferencesMap['dietary_restrictions'] ?? <String>[];
        preferencesMap['halal_only'] = preferencesMap['halal_only'] ?? false;
        preferencesMap['vegetarian_options'] = preferencesMap['vegetarian_options'] ?? false;
        preferencesMap['vegan_options'] = preferencesMap['vegan_options'] ?? false;
        preferencesMap['spice_tolerance_level'] = preferencesMap['spice_tolerance_level'] ?? 2;
        preferencesMap['budget_range_min'] = (preferencesMap['budget_range_min'] as num?)?.toDouble() ?? 0.0;
        preferencesMap['budget_range_max'] = (preferencesMap['budget_range_max'] as num?)?.toDouble() ?? 1000.0;
        preferencesMap['preferred_delivery_times'] = preferencesMap['preferred_delivery_times'] ?? <String>[];
        preferencesMap['advance_order_days'] = preferencesMap['advance_order_days'] ?? 1;
        preferencesMap['allow_substitutions'] = preferencesMap['allow_substitutions'] ?? true;
        processedJson['preferences'] = preferencesMap;
      }

      // Handle business_info - check if it's null or empty object
      final businessInfoData = json['business_info'];
      if (businessInfoData == null || (businessInfoData is Map && businessInfoData.isEmpty)) {
        // If it's null or empty object, set it to null so the model treats it as optional
        processedJson['business_info'] = null;
      } else if (businessInfoData is Map) {
        // Ensure required business info fields exist
        final businessMap = Map<String, dynamic>.from(businessInfoData);
        businessMap['industry'] = businessMap['industry']?.toString() ?? 'Other';
        businessMap['employee_count'] = (businessMap['employee_count'] as num?)?.toInt() ?? 1;
        businessMap['business_hours'] = businessMap['business_hours'] ?? <String>[];
        businessMap['requires_invoice'] = businessMap['requires_invoice'] ?? false;
        processedJson['business_info'] = businessMap;
      }

      // Handle numeric fields with safe conversion
      processedJson['total_spent'] = _safeDoubleConversion(json['total_spent'], 'total_spent') ?? 0.0;
      processedJson['total_orders'] = _safeIntConversion(json['total_orders'], 'total_orders') ?? 0;
      processedJson['average_order_value'] = _safeDoubleConversion(json['average_order_value'], 'average_order_value') ?? 0.0;

      // Handle boolean fields
      processedJson['is_active'] = json['is_active'] ?? true;
      processedJson['is_verified'] = json['is_verified'] ?? false;

      // Handle arrays
      processedJson['tags'] = (json['tags'] as List?)?.cast<String>() ?? <String>[];

      // Handle dates - last_order_date can be null
      // Don't set a default for last_order_date, let it remain null
      if (json['created_at'] == null) {
        processedJson['created_at'] = DateTime.now().toIso8601String();
      }
      if (json['updated_at'] == null) {
        processedJson['updated_at'] = DateTime.now().toIso8601String();
      }

      return _$CustomerFromJson(processedJson);
    } catch (e) {
      debugPrint('Customer.fromJson error: $e');
      debugPrint('JSON data: $json');
      rethrow;
    }
  }
  Map<String, dynamic> toJson() {
    final json = _$CustomerToJson(this);
    // Ensure nested objects are properly serialized
    json['address'] = address.toJson();
    json['preferences'] = preferences.toJson();
    if (businessInfo != null) {
      json['business_info'] = businessInfo!.toJson();
    }
    return json;
  }

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
  @JsonKey(name: 'building_name')
  final String? buildingName;
  final String? floor;
  final String? unit;
  @JsonKey(name: 'delivery_instructions')
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
  @JsonKey(name: 'company_registration_number')
  final String? companyRegistrationNumber;
  @JsonKey(name: 'tax_id')
  final String? taxId;
  final String industry;
  @JsonKey(name: 'employee_count')
  final int employeeCount;
  final String? website;
  @JsonKey(name: 'business_hours')
  final List<String> businessHours;
  @JsonKey(name: 'requires_invoice')
  final bool requiresInvoice;
  @JsonKey(name: 'billing_email')
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
  @JsonKey(name: 'preferred_cuisines')
  final List<String> preferredCuisines;
  @JsonKey(name: 'dietary_restrictions')
  final List<String> dietaryRestrictions;
  @JsonKey(name: 'halal_only')
  final bool halalOnly;
  @JsonKey(name: 'vegetarian_options')
  final bool vegetarianOptions;
  @JsonKey(name: 'vegan_options')
  final bool veganOptions;
  @JsonKey(name: 'spice_tolerance_level')
  final int spiceToleranceLevel; // 0-5
  @JsonKey(name: 'budget_range_min')
  final double budgetRangeMin;
  @JsonKey(name: 'budget_range_max')
  final double budgetRangeMax;
  @JsonKey(name: 'preferred_delivery_times')
  final List<String> preferredDeliveryTimes;
  @JsonKey(name: 'advance_order_days')
  final int advanceOrderDays;
  @JsonKey(name: 'allow_substitutions')
  final bool allowSubstitutions;
  @JsonKey(name: 'special_instructions')
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
