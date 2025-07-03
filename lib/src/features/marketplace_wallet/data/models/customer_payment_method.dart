import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'customer_payment_method.g.dart';

/// Enum for payment method types
enum CustomerPaymentMethodType {
  @JsonValue('card')
  card,
  @JsonValue('bank_account')
  bankAccount,
  @JsonValue('digital_wallet')
  digitalWallet,
}

/// Enum for card brands
enum CardBrand {
  @JsonValue('visa')
  visa,
  @JsonValue('mastercard')
  mastercard,
  @JsonValue('amex')
  amex,
  @JsonValue('discover')
  discover,
  @JsonValue('jcb')
  jcb,
  @JsonValue('diners')
  diners,
  @JsonValue('unionpay')
  unionpay,
  @JsonValue('unknown')
  unknown,
}

/// Customer payment method model for saved payment methods
@JsonSerializable()
class CustomerPaymentMethod extends Equatable {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'stripe_payment_method_id')
  final String stripePaymentMethodId;
  @JsonKey(name: 'stripe_customer_id')
  final String stripeCustomerId;
  final CustomerPaymentMethodType type;
  @JsonKey(name: 'is_default')
  final bool isDefault;
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  // Card-specific details
  @JsonKey(name: 'card_brand')
  final CardBrand? cardBrand;
  @JsonKey(name: 'card_last4')
  final String? cardLast4;
  @JsonKey(name: 'card_exp_month')
  final int? cardExpMonth;
  @JsonKey(name: 'card_exp_year')
  final int? cardExpYear;
  @JsonKey(name: 'card_funding')
  final String? cardFunding;
  @JsonKey(name: 'card_country')
  final String? cardCountry;
  
  // Bank account details
  @JsonKey(name: 'bank_name')
  final String? bankName;
  @JsonKey(name: 'bank_account_last4')
  final String? bankAccountLast4;
  @JsonKey(name: 'bank_account_type')
  final String? bankAccountType;

  // Digital wallet details
  @JsonKey(name: 'wallet_type')
  final String? walletType;

  // Metadata
  final String? nickname;
  @JsonKey(name: 'billing_address')
  final Map<String, dynamic>? billingAddress;
  final Map<String, dynamic>? metadata;

  // Audit fields
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'last_used_at')
  final DateTime? lastUsedAt;

  const CustomerPaymentMethod({
    required this.id,
    required this.userId,
    required this.stripePaymentMethodId,
    required this.stripeCustomerId,
    required this.type,
    required this.isDefault,
    required this.isActive,
    this.cardBrand,
    this.cardLast4,
    this.cardExpMonth,
    this.cardExpYear,
    this.cardFunding,
    this.cardCountry,
    this.bankName,
    this.bankAccountLast4,
    this.bankAccountType,
    this.walletType,
    this.nickname,
    this.billingAddress,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.lastUsedAt,
  });

  factory CustomerPaymentMethod.fromJson(Map<String, dynamic> json) =>
      _$CustomerPaymentMethodFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerPaymentMethodToJson(this);

  CustomerPaymentMethod copyWith({
    String? id,
    String? userId,
    String? stripePaymentMethodId,
    String? stripeCustomerId,
    CustomerPaymentMethodType? type,
    bool? isDefault,
    bool? isActive,
    CardBrand? cardBrand,
    String? cardLast4,
    int? cardExpMonth,
    int? cardExpYear,
    String? cardFunding,
    String? cardCountry,
    String? bankName,
    String? bankAccountLast4,
    String? bankAccountType,
    String? walletType,
    String? nickname,
    Map<String, dynamic>? billingAddress,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUsedAt,
  }) {
    return CustomerPaymentMethod(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      stripePaymentMethodId: stripePaymentMethodId ?? this.stripePaymentMethodId,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      cardBrand: cardBrand ?? this.cardBrand,
      cardLast4: cardLast4 ?? this.cardLast4,
      cardExpMonth: cardExpMonth ?? this.cardExpMonth,
      cardExpYear: cardExpYear ?? this.cardExpYear,
      cardFunding: cardFunding ?? this.cardFunding,
      cardCountry: cardCountry ?? this.cardCountry,
      bankName: bankName ?? this.bankName,
      bankAccountLast4: bankAccountLast4 ?? this.bankAccountLast4,
      bankAccountType: bankAccountType ?? this.bankAccountType,
      walletType: walletType ?? this.walletType,
      nickname: nickname ?? this.nickname,
      billingAddress: billingAddress ?? this.billingAddress,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        stripePaymentMethodId,
        stripeCustomerId,
        type,
        isDefault,
        isActive,
        cardBrand,
        cardLast4,
        cardExpMonth,
        cardExpYear,
        cardFunding,
        cardCountry,
        bankName,
        bankAccountLast4,
        bankAccountType,
        walletType,
        nickname,
        billingAddress,
        metadata,
        createdAt,
        updatedAt,
        lastUsedAt,
      ];

  /// Get display name for the payment method
  String get displayName {
    if (nickname != null && nickname!.isNotEmpty) {
      return nickname!;
    }

    switch (type) {
      case CustomerPaymentMethodType.card:
        final brand = cardBrand?.name.toUpperCase() ?? 'CARD';
        final last4 = cardLast4 ?? '****';
        return '$brand •••• $last4';
      case CustomerPaymentMethodType.bankAccount:
        final bank = bankName ?? 'Bank';
        final last4 = bankAccountLast4 ?? '****';
        return '$bank •••• $last4';
      case CustomerPaymentMethodType.digitalWallet:
        return walletType?.replaceAll('_', ' ').toUpperCase() ?? 'Digital Wallet';
    }
  }

  /// Get formatted expiry date for cards
  String? get formattedExpiry {
    if (type == CustomerPaymentMethodType.card && 
        cardExpMonth != null && 
        cardExpYear != null) {
      return '${cardExpMonth.toString().padLeft(2, '0')}/${cardExpYear.toString().substring(2)}';
    }
    return null;
  }

  /// Check if card is expired
  bool get isExpired {
    if (type != CustomerPaymentMethodType.card || 
        cardExpMonth == null || 
        cardExpYear == null) {
      return false;
    }

    final now = DateTime.now();
    final expiry = DateTime(cardExpYear!, cardExpMonth!);
    return expiry.isBefore(DateTime(now.year, now.month));
  }

  /// Get icon name for the payment method
  String get iconName {
    switch (type) {
      case CustomerPaymentMethodType.card:
        switch (cardBrand) {
          case CardBrand.visa:
            return 'visa';
          case CardBrand.mastercard:
            return 'mastercard';
          case CardBrand.amex:
            return 'amex';
          case CardBrand.discover:
            return 'discover';
          default:
            return 'credit_card';
        }
      case CustomerPaymentMethodType.bankAccount:
        return 'account_balance';
      case CustomerPaymentMethodType.digitalWallet:
        switch (walletType) {
          case 'apple_pay':
            return 'apple';
          case 'google_pay':
            return 'google';
          case 'samsung_pay':
            return 'samsung';
          default:
            return 'account_balance_wallet';
        }
    }
  }

  /// Create a test payment method for development
  factory CustomerPaymentMethod.test({
    String? id,
    String? userId,
    CustomerPaymentMethodType? type,
    bool? isDefault,
    String? nickname,
  }) {
    final now = DateTime.now();
    return CustomerPaymentMethod(
      id: id ?? 'test-payment-method-id',
      userId: userId ?? 'test-user-id',
      stripePaymentMethodId: 'pm_test_123456789',
      stripeCustomerId: 'cus_test_123456789',
      type: type ?? CustomerPaymentMethodType.card,
      isDefault: isDefault ?? true,
      isActive: true,
      cardBrand: CardBrand.visa,
      cardLast4: '4242',
      cardExpMonth: 12,
      cardExpYear: 2025,
      cardFunding: 'credit',
      cardCountry: 'MY',
      nickname: nickname,
      createdAt: now.subtract(const Duration(days: 7)),
      updatedAt: now,
      lastUsedAt: now.subtract(const Duration(hours: 2)),
    );
  }

  /// Create multiple test payment methods
  static List<CustomerPaymentMethod> testList({
    String? userId,
    int count = 3,
  }) {
    return List.generate(count, (index) {
      return CustomerPaymentMethod.test(
        id: 'test-payment-method-$index',
        userId: userId,
        isDefault: index == 0,
        nickname: index == 0 ? 'Primary Card' : null,
      );
    });
  }
}
