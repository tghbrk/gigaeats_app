import 'package:freezed_annotation/freezed_annotation.dart';

part 'unified_customer_models.freezed.dart';
part 'unified_customer_models.g.dart';

@freezed
class UnifiedCustomer with _$UnifiedCustomer {
  const factory UnifiedCustomer({
    required String id,
    String? userId,
    String? salesAgentId,
    required String customerType,
    required String fullName,
    String? email,
    String? phoneNumber,
    String? alternatePhoneNumber,
    String? organizationName,
    String? contactPersonName,
    String? businessRegistrationNumber,
    @Default({}) Map<String, dynamic> businessInfo,
    Map<String, dynamic>? address,
    @Default({}) Map<String, dynamic> preferences,
    @Default('en') String languagePreference,
    @Default('MYR') String currencyPreference,
    @Default(0.0) double totalSpent,
    @Default(0) int totalOrders,
    @Default(0.0) double averageOrderValue,
    double? creditLimit,
    @Default(30) int paymentTerms,
    @Default(true) bool isActive,
    @Default(false) bool isVerified,
    @Default('basic') String verificationLevel,
    DateTime? customerSince,
    DateTime? lastOrderDate,
    DateTime? lastLoginDate,
    String? notes,
    @Default([]) List<String> tags,
    @Default('normal') String priorityLevel,
    @Default(0) int loyaltyPoints,
    @Default('bronze') String loyaltyTier,
    @Default(false) bool marketingConsent,
    @Default(true) bool emailNotifications,
    @Default(false) bool smsNotifications,
    @Default(true) bool pushNotifications,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? createdBy,
  }) = _UnifiedCustomer;

  factory UnifiedCustomer.fromJson(Map<String, dynamic> json) =>
      _$UnifiedCustomerFromJson(json);
}

@freezed
class UnifiedCustomerAddress with _$UnifiedCustomerAddress {
  const factory UnifiedCustomerAddress({
    required String id,
    required String customerId,
    required String label,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String postalCode,
    @Default('Malaysia') String country,
    @Default('residential') String addressType,
    @Default(false) bool isDefault,
    @Default(true) bool isActive,
    String? deliveryInstructions,
    String? landmark,
    double? latitude,
    double? longitude,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UnifiedCustomerAddress;

  factory UnifiedCustomerAddress.fromJson(Map<String, dynamic> json) =>
      _$UnifiedCustomerAddressFromJson(json);
}

@freezed
class UnifiedCustomerResult with _$UnifiedCustomerResult {
  const factory UnifiedCustomerResult({
    required bool success,
    UnifiedCustomer? customer,
    required String message,
    Map<String, dynamic>? errorDetails,
  }) = _UnifiedCustomerResult;

  factory UnifiedCustomerResult.fromJson(Map<String, dynamic> json) =>
      _$UnifiedCustomerResultFromJson(json);
}

@freezed
class UnifiedCustomerAddressResult with _$UnifiedCustomerAddressResult {
  const factory UnifiedCustomerAddressResult({
    required bool success,
    UnifiedCustomerAddress? address,
    required String message,
    Map<String, dynamic>? errorDetails,
  }) = _UnifiedCustomerAddressResult;

  factory UnifiedCustomerAddressResult.fromJson(Map<String, dynamic> json) =>
      _$UnifiedCustomerAddressResultFromJson(json);
}

@freezed
class CustomerMigrationResult with _$CustomerMigrationResult {
  const factory CustomerMigrationResult({
    required int migratedCustomers,
    required int migratedProfiles,
    required int migratedAddresses,
    required int errorCount,
    required Map<String, dynamic> details,
  }) = _CustomerMigrationResult;

  factory CustomerMigrationResult.fromJson(Map<String, dynamic> json) =>
      _$CustomerMigrationResultFromJson(json);
}

@freezed
class CustomerSystemValidation with _$CustomerSystemValidation {
  const factory CustomerSystemValidation({
    required int totalUnifiedCustomers,
    required int customersWithAuth,
    required int customersWithSalesAgents,
    required int totalAddresses,
    required List<String> validationIssues,
    required List<String> recommendations,
  }) = _CustomerSystemValidation;

  factory CustomerSystemValidation.fromJson(Map<String, dynamic> json) =>
      _$CustomerSystemValidationFromJson(json);
}

// Extension methods for UnifiedCustomer
extension UnifiedCustomerExtensions on UnifiedCustomer {
  String get displayName {
    if (customerType == 'corporate' && organizationName != null) {
      return organizationName!;
    }
    return fullName;
  }

  String get primaryContact {
    if (customerType == 'corporate' && contactPersonName != null) {
      return contactPersonName!;
    }
    return fullName;
  }

  String get fullAddress {
    if (address == null) return '';
    
    final parts = <String>[];
    if (address!['street'] != null) parts.add(address!['street']);
    if (address!['city'] != null) parts.add(address!['city']);
    if (address!['state'] != null) parts.add(address!['state']);
    if (address!['postal_code'] != null) parts.add(address!['postal_code']);
    if (address!['country'] != null) parts.add(address!['country']);
    
    return parts.join(', ');
  }

  bool get hasAppAccount => userId != null;
  
  bool get isCorporate => customerType == 'corporate';
  
  bool get isIndividual => customerType == 'individual';
  
  bool get isVip => priorityLevel == 'vip';
  
  bool get isPremium => verificationLevel == 'premium';
  
  String get loyaltyStatus {
    switch (loyaltyTier) {
      case 'platinum':
        return 'Platinum Member';
      case 'gold':
        return 'Gold Member';
      case 'silver':
        return 'Silver Member';
      default:
        return 'Bronze Member';
    }
  }
}

// Extension methods for UnifiedCustomerAddress
extension UnifiedCustomerAddressExtensions on UnifiedCustomerAddress {
  String get fullAddress {
    final parts = <String>[addressLine1];
    if (addressLine2 != null && addressLine2!.isNotEmpty) {
      parts.add(addressLine2!);
    }
    parts.addAll([city, state, postalCode, country]);
    return parts.join(', ');
  }

  String get shortAddress {
    return '$addressLine1, $city, $state';
  }

  bool get hasCoordinates => latitude != null && longitude != null;
}
