import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/customer_delivery_method.dart';
import '../../../user_management/domain/customer_profile.dart';
import 'enhanced_payment_provider.dart';

// Enhanced checkout flow provider with proper imports structure

/// Enhanced checkout flow state
class EnhancedCheckoutFlowState {
  final CustomerDeliveryMethod? selectedDeliveryMethod;
  final CustomerAddress? selectedAddress;
  final PaymentMethodType? selectedPaymentMethod;
  final DateTime? scheduledDeliveryTime;
  final bool isProcessing;
  final String? errorMessage;
  final double? deliveryFee;
  final double? totalAmount;

  const EnhancedCheckoutFlowState({
    this.selectedDeliveryMethod,
    this.selectedAddress,
    this.selectedPaymentMethod,
    this.scheduledDeliveryTime,
    this.isProcessing = false,
    this.errorMessage,
    this.deliveryFee,
    this.totalAmount,
  });

  EnhancedCheckoutFlowState copyWith({
    CustomerDeliveryMethod? selectedDeliveryMethod,
    CustomerAddress? selectedAddress,
    PaymentMethodType? selectedPaymentMethod,
    DateTime? scheduledDeliveryTime,
    bool? isProcessing,
    String? errorMessage,
    double? deliveryFee,
    double? totalAmount,
  }) {
    return EnhancedCheckoutFlowState(
      selectedDeliveryMethod: selectedDeliveryMethod ?? this.selectedDeliveryMethod,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
      scheduledDeliveryTime: scheduledDeliveryTime ?? this.scheduledDeliveryTime,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage ?? this.errorMessage,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }
}

/// Enhanced checkout flow notifier
class EnhancedCheckoutFlowNotifier extends StateNotifier<EnhancedCheckoutFlowState> {
  EnhancedCheckoutFlowNotifier() : super(const EnhancedCheckoutFlowState());

  /// Set delivery method
  void setDeliveryMethod(CustomerDeliveryMethod method) {
    state = state.copyWith(selectedDeliveryMethod: method);
  }

  /// Set delivery address
  void setDeliveryAddress(CustomerAddress address) {
    state = state.copyWith(selectedAddress: address);
  }

  /// Set payment method
  void setPaymentMethod(PaymentMethodType method) {
    state = state.copyWith(selectedPaymentMethod: method);
  }

  /// Set scheduled delivery time
  void setScheduledDeliveryTime(DateTime? time) {
    state = state.copyWith(scheduledDeliveryTime: time);
  }

  /// Calculate delivery fee
  Future<void> calculateDeliveryFee() async {
    if (state.selectedDeliveryMethod == null || state.selectedAddress == null) {
      return;
    }

    state = state.copyWith(isProcessing: true);

    try {
      // TODO: Implement actual delivery fee calculation
      double fee = 0.0;
      
      switch (state.selectedDeliveryMethod!) {
        case CustomerDeliveryMethod.customerPickup:
          fee = 0.0;
          break;
        case CustomerDeliveryMethod.salesAgentPickup:
          fee = 5.0;
          break;
        case CustomerDeliveryMethod.ownFleet:
          fee = 10.0;
          break;
        case CustomerDeliveryMethod.lalamove:
          fee = 15.0;
          break;
        case CustomerDeliveryMethod.thirdParty:
          fee = 12.0;
          break;
        case CustomerDeliveryMethod.pickup:
          fee = 0.0;
          break;
        case CustomerDeliveryMethod.delivery:
          fee = 8.0;
          break;
        case CustomerDeliveryMethod.scheduled:
          fee = 10.0;
          break;
      }

      state = state.copyWith(
        deliveryFee: fee,
        isProcessing: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Failed to calculate delivery fee: $e',
      );
    }
  }

  /// Calculate total amount
  void calculateTotal(double subtotal) {
    final deliveryFee = state.deliveryFee ?? 0.0;
    final total = subtotal + deliveryFee;
    state = state.copyWith(totalAmount: total);
  }

  /// Reset checkout flow
  void reset() {
    state = const EnhancedCheckoutFlowState();
  }

  /// Validate checkout data
  bool isValid() {
    return state.selectedDeliveryMethod != null &&
           state.selectedAddress != null &&
           state.selectedPaymentMethod != null;
  }
}

/// Enhanced checkout flow notifier provider
final enhancedCheckoutFlowProvider = StateNotifierProvider<EnhancedCheckoutFlowNotifier, EnhancedCheckoutFlowState>((ref) {
  return EnhancedCheckoutFlowNotifier();
});
