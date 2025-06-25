import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'customer_profile.g.dart';

/// Customer profile model for direct customer app usage
/// This is different from the Customer model used by sales agents
@JsonSerializable()
class CustomerProfile extends Equatable {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId; // Links to auth.users
  @JsonKey(name: 'full_name')
  final String fullName;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  @JsonKey(name: 'profile_image_url')
  final String? profileImageUrl;
  @JsonKey(name: 'total_orders')
  final int totalOrders;
  @JsonKey(name: 'total_spent')
  final double totalSpent;
  @JsonKey(name: 'loyalty_points')
  final int loyaltyPoints;
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // These will be loaded separately from related tables
  @JsonKey(name: 'saved_addresses')
  final List<CustomerAddress> addresses;
  final CustomerPreferences? preferences;

  // Additional computed fields for statistics
  final String? favoriteVendorId;
  final String? favoriteVendorName;

  const CustomerProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    this.phoneNumber,
    this.profileImageUrl,
    this.totalOrders = 0,
    this.totalSpent = 0.0,
    this.loyaltyPoints = 0,
    this.isVerified = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.addresses = const [],
    this.preferences,
    this.favoriteVendorId,
    this.favoriteVendorName,
  });

  factory CustomerProfile.fromJson(Map<String, dynamic> json) => _$CustomerProfileFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerProfileToJson(this);

  CustomerProfile copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
    int? totalOrders,
    double? totalSpent,
    int? loyaltyPoints,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<CustomerAddress>? addresses,
    CustomerPreferences? preferences,
    String? favoriteVendorId,
    String? favoriteVendorName,
  }) {
    return CustomerProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      totalOrders: totalOrders ?? this.totalOrders,
      totalSpent: totalSpent ?? this.totalSpent,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      addresses: addresses ?? this.addresses,
      preferences: preferences ?? this.preferences,
      favoriteVendorId: favoriteVendorId ?? this.favoriteVendorId,
      favoriteVendorName: favoriteVendorName ?? this.favoriteVendorName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        fullName,
        phoneNumber,
        profileImageUrl,
        totalOrders,
        totalSpent,
        loyaltyPoints,
        isVerified,
        isActive,
        createdAt,
        updatedAt,
        addresses,
        preferences,
        favoriteVendorId,
        favoriteVendorName,
      ];
}

/// Customer address model for delivery locations
@JsonSerializable()
class CustomerAddress extends Equatable {
  final String? id;
  final String label; // e.g., 'Home', 'Office', 'Mom's House'
  @JsonKey(name: 'address_line_1')
  final String addressLine1;
  @JsonKey(name: 'address_line_2')
  final String? addressLine2;
  final String city;
  final String state;
  @JsonKey(name: 'postal_code')
  final String postalCode;
  final String country;
  final double? latitude;
  final double? longitude;
  @JsonKey(name: 'delivery_instructions')
  final String? deliveryInstructions;
  @JsonKey(name: 'is_default')
  final bool isDefault;

  const CustomerAddress({
    this.id,
    required this.label,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    this.country = 'Malaysia',
    this.latitude,
    this.longitude,
    this.deliveryInstructions,
    this.isDefault = false,
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    // Handle both int and string IDs from database
    String? id;
    if (json['id'] != null) {
      if (json['id'] is int) {
        id = json['id'].toString();
      } else if (json['id'] is String) {
        id = json['id'] as String;
      }
    }

    // Create a copy of the JSON with the converted ID
    final processedJson = Map<String, dynamic>.from(json);
    processedJson['id'] = id;

    return _$CustomerAddressFromJson(processedJson);
  }
  Map<String, dynamic> toJson() => _$CustomerAddressToJson(this);

  String get fullAddress {
    final parts = [
      addressLine1,
      if (addressLine2?.isNotEmpty == true) addressLine2,
      city,
      '$postalCode $state',
      country,
    ];
    return parts.join(', ');
  }

  CustomerAddress copyWith({
    String? id,
    String? label,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    double? latitude,
    double? longitude,
    String? deliveryInstructions,
    bool? isDefault,
  }) {
    return CustomerAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  List<Object?> get props => [
        id,
        label,
        addressLine1,
        addressLine2,
        city,
        state,
        postalCode,
        country,
        latitude,
        longitude,
        deliveryInstructions,
        isDefault,
      ];
}

/// Customer preferences for personalized experience
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
  final int spiceToleranceLevel; // 1-5 scale
  @JsonKey(name: 'budget_range_min')
  final double budgetRangeMin;
  @JsonKey(name: 'budget_range_max')
  final double budgetRangeMax;
  @JsonKey(name: 'preferred_delivery_times')
  final List<String> preferredDeliveryTimes;
  @JsonKey(name: 'notification_preferences')
  final NotificationPreferences notificationPreferences;
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
    this.notificationPreferences = const NotificationPreferences(),
    this.allowSubstitutions = true,
    this.specialInstructions,
  });

  factory CustomerPreferences.fromJson(Map<String, dynamic> json) => _$CustomerPreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerPreferencesToJson(this);

  CustomerPreferences copyWith({
    List<String>? preferredCuisines,
    List<String>? dietaryRestrictions,
    bool? halalOnly,
    bool? vegetarianOptions,
    bool? veganOptions,
    int? spiceToleranceLevel,
    double? budgetRangeMin,
    double? budgetRangeMax,
    List<String>? preferredDeliveryTimes,
    NotificationPreferences? notificationPreferences,
    bool? allowSubstitutions,
    String? specialInstructions,
  }) {
    return CustomerPreferences(
      preferredCuisines: preferredCuisines ?? this.preferredCuisines,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      halalOnly: halalOnly ?? this.halalOnly,
      vegetarianOptions: vegetarianOptions ?? this.vegetarianOptions,
      veganOptions: veganOptions ?? this.veganOptions,
      spiceToleranceLevel: spiceToleranceLevel ?? this.spiceToleranceLevel,
      budgetRangeMin: budgetRangeMin ?? this.budgetRangeMin,
      budgetRangeMax: budgetRangeMax ?? this.budgetRangeMax,
      preferredDeliveryTimes: preferredDeliveryTimes ?? this.preferredDeliveryTimes,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
      allowSubstitutions: allowSubstitutions ?? this.allowSubstitutions,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }

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
        notificationPreferences,
        allowSubstitutions,
        specialInstructions,
      ];
}

/// Notification preferences for customers
@JsonSerializable()
class NotificationPreferences extends Equatable {
  @JsonKey(name: 'order_updates')
  final bool orderUpdates;
  @JsonKey(name: 'promotional_offers')
  final bool promotionalOffers;
  @JsonKey(name: 'new_restaurants')
  final bool newRestaurants;
  @JsonKey(name: 'delivery_updates')
  final bool deliveryUpdates;
  @JsonKey(name: 'email_notifications')
  final bool emailNotifications;
  @JsonKey(name: 'sms_notifications')
  final bool smsNotifications;
  @JsonKey(name: 'push_notifications')
  final bool pushNotifications;

  const NotificationPreferences({
    this.orderUpdates = true,
    this.promotionalOffers = false,
    this.newRestaurants = false,
    this.deliveryUpdates = true,
    this.emailNotifications = true,
    this.smsNotifications = false,
    this.pushNotifications = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) => _$NotificationPreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationPreferencesToJson(this);

  NotificationPreferences copyWith({
    bool? orderUpdates,
    bool? promotionalOffers,
    bool? newRestaurants,
    bool? deliveryUpdates,
    bool? emailNotifications,
    bool? smsNotifications,
    bool? pushNotifications,
  }) {
    return NotificationPreferences(
      orderUpdates: orderUpdates ?? this.orderUpdates,
      promotionalOffers: promotionalOffers ?? this.promotionalOffers,
      newRestaurants: newRestaurants ?? this.newRestaurants,
      deliveryUpdates: deliveryUpdates ?? this.deliveryUpdates,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
    );
  }

  @override
  List<Object?> get props => [
        orderUpdates,
        promotionalOffers,
        newRestaurants,
        deliveryUpdates,
        emailNotifications,
        smsNotifications,
        pushNotifications,
      ];
}
