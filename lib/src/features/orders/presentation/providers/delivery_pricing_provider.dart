import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/customer_delivery_method.dart';
import '../../data/models/delivery_fee_calculation.dart';
import '../../data/services/delivery_fee_service.dart';
import 'delivery_method_provider.dart';
import '../../../user_management/domain/customer_profile.dart';
import '../../../core/utils/logger.dart';
import '../../data/models/delivery_method.dart';

/// State for delivery pricing information
class DeliveryPricingState extends Equatable {
  final CustomerDeliveryMethod selectedMethod;
  final DeliveryFeeCalculation? calculation;
  final bool isCalculating;
  final String? error;
  final DateTime lastUpdated;

  const DeliveryPricingState({
    required this.selectedMethod,
    this.calculation,
    this.isCalculating = false,
    this.error,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
        selectedMethod,
        calculation,
        isCalculating,
        error,
        lastUpdated,
      ];

  DeliveryPricingState copyWith({
    CustomerDeliveryMethod? selectedMethod,
    DeliveryFeeCalculation? calculation,
    bool? isCalculating,
    String? error,
    DateTime? lastUpdated,
  }) {
    return DeliveryPricingState(
      selectedMethod: selectedMethod ?? this.selectedMethod,
      calculation: calculation ?? this.calculation,
      isCalculating: isCalculating ?? this.isCalculating,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Get formatted price display
  String get formattedPrice {
    if (calculation == null) return 'Calculating...';
    if (calculation!.finalFee <= 0) return 'FREE';
    return 'RM ${calculation!.finalFee.toStringAsFixed(2)}';
  }

  /// Check if method is pickup (no delivery fee)
  bool get isPickupMethod {
    return selectedMethod == CustomerDeliveryMethod.pickup;
  }

  /// Get price color indicator
  String get priceColorType {
    if (calculation == null) return 'neutral';
    if (calculation!.finalFee <= 0) return 'success';
    return 'primary';
  }
}

/// Notifier for delivery pricing state management
class DeliveryPricingNotifier extends StateNotifier<DeliveryPricingState> {
  final DeliveryFeeService _deliveryFeeService;
  final AppLogger _logger = AppLogger();
  static const String _tag = 'DELIVERY-PRICING';

  DeliveryPricingNotifier(this._deliveryFeeService)
      : super(DeliveryPricingState(
          selectedMethod: CustomerDeliveryMethod.pickup,
          lastUpdated: DateTime.now(),
        ));

  /// Calculate delivery fee for current parameters
  Future<void> calculateDeliveryFee({
    required CustomerDeliveryMethod deliveryMethod,
    required String vendorId,
    required double subtotal,
    CustomerAddress? deliveryAddress,
    DateTime? scheduledTime,
  }) async {
    if (state.isCalculating) {
      _logger.debug('🔄 [$_tag] Calculation already in progress, skipping');
      return;
    }

    _logger.info('💰 [$_tag] Calculating delivery fee for method: ${deliveryMethod.value}');

    state = state.copyWith(
      selectedMethod: deliveryMethod,
      isCalculating: true,
      error: null,
      lastUpdated: DateTime.now(),
    );

    try {
      // Map CustomerDeliveryMethod to DeliveryMethod for service call
      final mappedMethod = _mapToDeliveryMethod(deliveryMethod);
      if (mappedMethod == null) {
        throw Exception('Unsupported delivery method: ${deliveryMethod.value}');
      }

      final calculation = await _deliveryFeeService.calculateDeliveryFee(
        deliveryMethod: mappedMethod,
        vendorId: vendorId,
        subtotal: subtotal,
        deliveryLatitude: deliveryAddress?.latitude,
        deliveryLongitude: deliveryAddress?.longitude,
        deliveryTime: scheduledTime,
      );

      _logger.info('✅ [$_tag] Fee calculation completed: ${calculation.formattedFee}');
      _logger.debug('📊 [$_tag] Calculation details: ${calculation.breakdown}');

      state = state.copyWith(
        calculation: calculation,
        isCalculating: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e, stack) {
      _logger.error('❌ [$_tag] Failed to calculate delivery fee', e, stack);
      
      // Create fallback calculation for pickup methods
      final fallbackCalculation = deliveryMethod.isPickupMethod
          ? DeliveryFeeCalculation.pickup(deliveryMethod.value)
          : DeliveryFeeCalculation.error('Calculation failed: $e');

      state = state.copyWith(
        calculation: fallbackCalculation,
        isCalculating: false,
        error: e.toString(),
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Update delivery method and recalculate if needed
  void updateDeliveryMethod(CustomerDeliveryMethod method) {
    _logger.info('🚚 [$_tag] Delivery method updated to: ${method.value}');
    
    state = state.copyWith(
      selectedMethod: method,
      lastUpdated: DateTime.now(),
    );
  }

  /// Clear current calculation
  void clearCalculation() {
    _logger.debug('🧹 [$_tag] Clearing delivery fee calculation');
    
    state = state.copyWith(
      calculation: null,
      error: null,
      lastUpdated: DateTime.now(),
    );
  }

  /// Map CustomerDeliveryMethod to DeliveryMethod
  DeliveryMethod? _mapToDeliveryMethod(CustomerDeliveryMethod method) {
    switch (method) {
      case CustomerDeliveryMethod.pickup:
        return DeliveryMethod.customerPickup;
      case CustomerDeliveryMethod.delivery:
      case CustomerDeliveryMethod.scheduled:
        return DeliveryMethod.ownFleet; // Both delivery and scheduled use own fleet pricing
    }
  }
}

/// Extension for CustomerDeliveryMethod to check if it's a pickup method
extension CustomerDeliveryMethodPickupExtension on CustomerDeliveryMethod {
  bool get isPickupMethod {
    return this == CustomerDeliveryMethod.pickup;
  }
}

/// Provider for delivery pricing state management
final deliveryPricingProvider = StateNotifierProvider<DeliveryPricingNotifier, DeliveryPricingState>((ref) {
  final deliveryFeeService = ref.watch(deliveryFeeServiceProvider);
  return DeliveryPricingNotifier(deliveryFeeService);
});

/// Convenience providers for specific pricing data
final currentDeliveryFeeProvider = Provider<double>((ref) {
  final state = ref.watch(deliveryPricingProvider);
  return state.calculation?.finalFee ?? 0.0;
});

final formattedDeliveryPriceProvider = Provider<String>((ref) {
  final state = ref.watch(deliveryPricingProvider);
  return state.formattedPrice;
});

final deliveryFeeCalculationProvider = Provider<DeliveryFeeCalculation?>((ref) {
  final state = ref.watch(deliveryPricingProvider);
  return state.calculation;
});

final isCalculatingDeliveryFeeProvider = Provider<bool>((ref) {
  final state = ref.watch(deliveryPricingProvider);
  return state.isCalculating;
});
