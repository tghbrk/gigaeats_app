import 'package:json_annotation/json_annotation.dart';

/// Marketplace payment methods supported by the platform
enum MarketplacePaymentMethod {
  @JsonValue('credit_card')
  creditCard,
  @JsonValue('fpx')
  fpx,
  @JsonValue('grabpay')
  grabpay,
  @JsonValue('tng')
  tng,
  @JsonValue('boost')
  boost,
  @JsonValue('shopeepay')
  shopeepay,
  @JsonValue('wallet')
  wallet,
  @JsonValue('cash')
  cash,
}

extension MarketplacePaymentMethodExtension on MarketplacePaymentMethod {
  String get displayName {
    switch (this) {
      case MarketplacePaymentMethod.creditCard:
        return 'Credit Card';
      case MarketplacePaymentMethod.fpx:
        return 'FPX Online Banking';
      case MarketplacePaymentMethod.grabpay:
        return 'GrabPay';
      case MarketplacePaymentMethod.tng:
        return 'Touch \'n Go eWallet';
      case MarketplacePaymentMethod.boost:
        return 'Boost';
      case MarketplacePaymentMethod.shopeepay:
        return 'ShopeePay';
      case MarketplacePaymentMethod.wallet:
        return 'GigaEats Wallet';
      case MarketplacePaymentMethod.cash:
        return 'Cash on Delivery';
    }
  }

  String get value {
    switch (this) {
      case MarketplacePaymentMethod.creditCard:
        return 'credit_card';
      case MarketplacePaymentMethod.fpx:
        return 'fpx';
      case MarketplacePaymentMethod.grabpay:
        return 'grabpay';
      case MarketplacePaymentMethod.tng:
        return 'tng';
      case MarketplacePaymentMethod.boost:
        return 'boost';
      case MarketplacePaymentMethod.shopeepay:
        return 'shopeepay';
      case MarketplacePaymentMethod.wallet:
        return 'wallet';
      case MarketplacePaymentMethod.cash:
        return 'cash';
    }
  }

  /// Check if this payment method requires online processing
  bool get requiresOnlineProcessing {
    switch (this) {
      case MarketplacePaymentMethod.creditCard:
      case MarketplacePaymentMethod.fpx:
      case MarketplacePaymentMethod.grabpay:
      case MarketplacePaymentMethod.tng:
      case MarketplacePaymentMethod.boost:
      case MarketplacePaymentMethod.shopeepay:
        return true;
      case MarketplacePaymentMethod.wallet:
      case MarketplacePaymentMethod.cash:
        return false;
    }
  }

  /// Check if this payment method supports escrow
  bool get supportsEscrow {
    switch (this) {
      case MarketplacePaymentMethod.creditCard:
      case MarketplacePaymentMethod.fpx:
      case MarketplacePaymentMethod.grabpay:
      case MarketplacePaymentMethod.tng:
      case MarketplacePaymentMethod.boost:
      case MarketplacePaymentMethod.shopeepay:
      case MarketplacePaymentMethod.wallet:
        return true;
      case MarketplacePaymentMethod.cash:
        return false;
    }
  }

  /// Get the icon name for this payment method
  String get iconName {
    switch (this) {
      case MarketplacePaymentMethod.creditCard:
        return 'credit_card';
      case MarketplacePaymentMethod.fpx:
        return 'bank';
      case MarketplacePaymentMethod.grabpay:
        return 'grabpay';
      case MarketplacePaymentMethod.tng:
        return 'tng';
      case MarketplacePaymentMethod.boost:
        return 'boost';
      case MarketplacePaymentMethod.shopeepay:
        return 'shopeepay';
      case MarketplacePaymentMethod.wallet:
        return 'wallet';
      case MarketplacePaymentMethod.cash:
        return 'cash';
    }
  }

  static MarketplacePaymentMethod fromString(String value) {
    switch (value.toLowerCase()) {
      case 'credit_card':
      case 'card':
        return MarketplacePaymentMethod.creditCard;
      case 'fpx':
        return MarketplacePaymentMethod.fpx;
      case 'grabpay':
        return MarketplacePaymentMethod.grabpay;
      case 'tng':
        return MarketplacePaymentMethod.tng;
      case 'boost':
        return MarketplacePaymentMethod.boost;
      case 'shopeepay':
        return MarketplacePaymentMethod.shopeepay;
      case 'wallet':
        return MarketplacePaymentMethod.wallet;
      case 'cash':
        return MarketplacePaymentMethod.cash;
      default:
        throw ArgumentError('Invalid marketplace payment method: $value');
    }
  }
}
