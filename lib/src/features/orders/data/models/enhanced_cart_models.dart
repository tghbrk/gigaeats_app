import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';



import '../../../user_management/domain/customer_profile.dart';

import 'customer_delivery_method.dart';

part 'enhanced_cart_models.g.dart';

/// Enhanced cart item model with comprehensive customization support
@JsonSerializable()
class EnhancedCartItem extends Equatable {
  final String id;
  final String productId;
  final String name;
  final String description;
  final double basePrice;
  final double unitPrice; // Base price + customization costs
  final int quantity;
  final String? imageUrl;
  final Map<String, dynamic>? customizations;
  final double customizationCost;
  final String? notes;
  final String vendorId;
  final String vendorName;
  final DateTime addedAt;
  final bool isAvailable;
  final int? maxQuantity;
  final int minQuantity;

  const EnhancedCartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl,
    this.customizations,
    this.customizationCost = 0.0,
    this.notes,
    required this.vendorId,
    required this.vendorName,
    required this.addedAt,
    this.isAvailable = true,
    this.maxQuantity,
    this.minQuantity = 1,
  });

  factory EnhancedCartItem.fromJson(Map<String, dynamic> json) =>
      _$EnhancedCartItemFromJson(json);

  Map<String, dynamic> toJson() => _$EnhancedCartItemToJson(this);

  /// Calculate total price for this cart item
  double get totalPrice => unitPrice * quantity;

  /// Alias for productId to maintain compatibility
  String get menuItemId => productId;

  /// Calculate total customization cost for this cart item
  double get totalCustomizationCost => customizationCost * quantity;

  /// Check if quantity can be increased
  bool get canIncreaseQuantity => maxQuantity == null || quantity < maxQuantity!;

  /// Check if quantity can be decreased
  bool get canDecreaseQuantity => quantity > minQuantity;

  /// Get formatted customizations for display
  String get formattedCustomizations {
    if (customizations == null || customizations!.isEmpty) return '';
    
    final List<String> customizationStrings = [];
    customizations!.forEach((key, value) {
      if (value is List) {
        customizationStrings.add('$key: ${value.join(', ')}');
      } else {
        customizationStrings.add('$key: $value');
      }
    });
    
    return customizationStrings.join('; ');
  }

  EnhancedCartItem copyWith({
    String? id,
    String? productId,
    String? name,
    String? description,
    double? basePrice,
    double? unitPrice,
    int? quantity,
    String? imageUrl,
    Map<String, dynamic>? customizations,
    double? customizationCost,
    String? notes,
    String? vendorId,
    String? vendorName,
    DateTime? addedAt,
    bool? isAvailable,
    int? maxQuantity,
    int? minQuantity,
  }) {
    return EnhancedCartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      description: description ?? this.description,
      basePrice: basePrice ?? this.basePrice,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      customizations: customizations ?? this.customizations,
      customizationCost: customizationCost ?? this.customizationCost,
      notes: notes ?? this.notes,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      addedAt: addedAt ?? this.addedAt,
      isAvailable: isAvailable ?? this.isAvailable,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      minQuantity: minQuantity ?? this.minQuantity,
    );
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        name,
        description,
        basePrice,
        unitPrice,
        quantity,
        imageUrl,
        customizations,
        customizationCost,
        notes,
        vendorId,
        vendorName,
        addedAt,
        isAvailable,
        maxQuantity,
        minQuantity,
      ];
}

/// Cart validation result
@JsonSerializable()
class CartValidationResult extends Equatable {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final Map<String, dynamic>? metadata;

  const CartValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.metadata,
  });

  factory CartValidationResult.fromJson(Map<String, dynamic> json) =>
      _$CartValidationResultFromJson(json);

  Map<String, dynamic> toJson() => _$CartValidationResultToJson(this);

  factory CartValidationResult.valid() => const CartValidationResult(isValid: true);

  factory CartValidationResult.invalid(List<String> errors, {List<String>? warnings}) =>
      CartValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings ?? [],
      );

  @override
  List<Object?> get props => [isValid, errors, warnings, metadata];
}

/// Cart summary with pricing breakdown
@JsonSerializable()
class CartSummary extends Equatable {
  final double subtotal;
  final double customizationTotal;
  final double deliveryFee;
  final double sstAmount;
  final double discountAmount;
  final double totalAmount;
  final int totalItems;
  final int totalQuantity;
  final Map<String, double> vendorSubtotals;
  final DateTime calculatedAt;

  const CartSummary({
    required this.subtotal,
    required this.customizationTotal,
    required this.deliveryFee,
    required this.sstAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.totalItems,
    required this.totalQuantity,
    required this.vendorSubtotals,
    required this.calculatedAt,
  });

  factory CartSummary.fromJson(Map<String, dynamic> json) =>
      _$CartSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$CartSummaryToJson(this);

  @override
  List<Object?> get props => [
        subtotal,
        customizationTotal,
        deliveryFee,
        sstAmount,
        discountAmount,
        totalAmount,
        totalItems,
        totalQuantity,
        vendorSubtotals,
        calculatedAt,
      ];
}

/// Enhanced cart state with comprehensive checkout support
@JsonSerializable()
class EnhancedCartState extends Equatable {
  final List<EnhancedCartItem> items;
  final String? customerId;
  final CustomerAddress? selectedAddress;
  final CustomerDeliveryMethod deliveryMethod;
  final DateTime? scheduledDeliveryTime;
  final String? specialInstructions;
  final String? selectedPaymentMethod;
  final CartSummary? summary;
  final CartValidationResult? validationResult;
  final bool isLoading;
  final String? error;
  final DateTime lastUpdated;
  final Map<String, dynamic>? metadata;

  const EnhancedCartState({
    this.items = const [],
    this.customerId,
    this.selectedAddress,
    this.deliveryMethod = CustomerDeliveryMethod.delivery,
    this.scheduledDeliveryTime,
    this.specialInstructions,
    this.selectedPaymentMethod,
    this.summary,
    this.validationResult,
    this.isLoading = false,
    this.error,
    required this.lastUpdated,
    this.metadata,
  });

  factory EnhancedCartState.fromJson(Map<String, dynamic> json) =>
      _$EnhancedCartStateFromJson(json);

  Map<String, dynamic> toJson() => _$EnhancedCartStateToJson(this);

  /// Create initial empty cart state
  factory EnhancedCartState.empty() => EnhancedCartState(
        lastUpdated: DateTime.now(),
      );

  /// Check if cart is empty
  bool get isEmpty => items.isEmpty;

  /// Check if cart has items
  bool get isNotEmpty => items.isNotEmpty;

  /// Get total number of items
  int get totalItems => items.length;

  /// Get total quantity of all items
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  /// Get subtotal (sum of all item prices)
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Get total customization cost
  double get customizationTotal => items.fold(0.0, (sum, item) => sum + item.totalCustomizationCost);

  /// Get delivery fee from summary or calculate default
  double get deliveryFee => summary?.deliveryFee ?? _calculateDefaultDeliveryFee();

  /// Get SST amount (6% of subtotal + delivery fee)
  double get sstAmount => (subtotal + deliveryFee) * 0.06;

  /// Get total amount
  double get totalAmount => subtotal + deliveryFee + sstAmount - (summary?.discountAmount ?? 0.0);

  /// Group items by vendor
  Map<String, List<EnhancedCartItem>> get itemsByVendor {
    final Map<String, List<EnhancedCartItem>> grouped = {};
    for (final item in items) {
      grouped.putIfAbsent(item.vendorId, () => []).add(item);
    }
    return grouped;
  }

  /// Check if cart has items from multiple vendors
  bool get hasMultipleVendors => itemsByVendor.keys.length > 1;

  /// Get primary vendor ID (vendor with most items)
  String? get primaryVendorId {
    if (isEmpty) return null;

    final vendorCounts = <String, int>{};
    for (final item in items) {
      vendorCounts[item.vendorId] = (vendorCounts[item.vendorId] ?? 0) + item.quantity;
    }

    return vendorCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Check if cart is ready for checkout
  bool get isReadyForCheckout {
    return isNotEmpty &&
           validationResult?.isValid == true &&
           selectedAddress != null &&
           selectedPaymentMethod != null;
  }

  /// Calculate default delivery fee based on delivery method
  double _calculateDefaultDeliveryFee() {
    switch (deliveryMethod) {
      case CustomerDeliveryMethod.pickup:
      case CustomerDeliveryMethod.customerPickup:
        return 0.0;
      case CustomerDeliveryMethod.delivery:
      case CustomerDeliveryMethod.ownFleet:
      case CustomerDeliveryMethod.lalamove:
      case CustomerDeliveryMethod.thirdParty:
        return 5.0; // Default delivery fee
      case CustomerDeliveryMethod.scheduled:
        return 7.0; // Slightly higher for scheduled delivery
      case CustomerDeliveryMethod.salesAgentPickup:
        return 3.0; // Reduced fee for sales agent pickup
    }
  }

  EnhancedCartState copyWith({
    List<EnhancedCartItem>? items,
    CustomerAddress? selectedAddress,
    CustomerDeliveryMethod? deliveryMethod,
    DateTime? scheduledDeliveryTime,
    String? specialInstructions,
    String? selectedPaymentMethod,
    CartSummary? summary,
    CartValidationResult? validationResult,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
    Map<String, dynamic>? metadata,
  }) {
    return EnhancedCartState(
      items: items ?? this.items,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      scheduledDeliveryTime: scheduledDeliveryTime ?? this.scheduledDeliveryTime,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
      summary: summary ?? this.summary,
      validationResult: validationResult ?? this.validationResult,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? DateTime.now(),
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        items,
        selectedAddress,
        deliveryMethod,
        scheduledDeliveryTime,
        specialInstructions,
        selectedPaymentMethod,
        summary,
        validationResult,
        isLoading,
        error,
        lastUpdated,
        metadata,
      ];
}
