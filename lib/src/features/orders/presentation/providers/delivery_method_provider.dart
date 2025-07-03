import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/customer_delivery_method.dart';
import '../../data/models/delivery_fee_calculation.dart';
import '../../data/services/delivery_method_service.dart';
import '../../data/services/delivery_fee_service.dart';
import '../../../user_management/domain/customer_profile.dart';
import '../../../core/utils/logger.dart';

/// State for delivery method selection
class DeliveryMethodState {
  final CustomerDeliveryMethod selectedMethod;
  final List<CustomerDeliveryMethod> availableMethods;
  final Map<CustomerDeliveryMethod, DeliveryFeeCalculation?> feeCalculations;
  final DeliveryMethodRecommendation? recommendation;
  final bool isLoading;
  final String? error;
  final DateTime lastUpdated;

  const DeliveryMethodState({
    this.selectedMethod = CustomerDeliveryMethod.customerPickup,
    this.availableMethods = const [],
    this.feeCalculations = const {},
    this.recommendation,
    this.isLoading = false,
    this.error,
    required this.lastUpdated,
  });

  DeliveryMethodState copyWith({
    CustomerDeliveryMethod? selectedMethod,
    List<CustomerDeliveryMethod>? availableMethods,
    Map<CustomerDeliveryMethod, DeliveryFeeCalculation?>? feeCalculations,
    DeliveryMethodRecommendation? recommendation,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return DeliveryMethodState(
      selectedMethod: selectedMethod ?? this.selectedMethod,
      availableMethods: availableMethods ?? this.availableMethods,
      feeCalculations: feeCalculations ?? this.feeCalculations,
      recommendation: recommendation ?? this.recommendation,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  /// Get delivery fee for selected method
  double get selectedMethodFee {
    final calculation = feeCalculations[selectedMethod];
    return calculation?.finalFee ?? 0.0;
  }

  /// Check if selected method is available
  bool get isSelectedMethodAvailable {
    return availableMethods.contains(selectedMethod);
  }

  /// Get cheapest available method
  CustomerDeliveryMethod? get cheapestMethod {
    if (availableMethods.isEmpty) return null;

    CustomerDeliveryMethod? cheapest;
    double lowestFee = double.infinity;

    for (final method in availableMethods) {
      final calculation = feeCalculations[method];
      final fee = calculation?.finalFee ?? 0.0;
      
      if (fee < lowestFee) {
        lowestFee = fee;
        cheapest = method;
      }
    }

    return cheapest;
  }

  /// Get fastest available method
  CustomerDeliveryMethod? get fastestMethod {
    if (availableMethods.isEmpty) return null;

    // Customer pickup is typically fastest
    if (availableMethods.contains(CustomerDeliveryMethod.customerPickup)) {
      return CustomerDeliveryMethod.customerPickup;
    }

    // Otherwise return first available method
    return availableMethods.first;
  }
}

/// Delivery method state notifier
class DeliveryMethodNotifier extends StateNotifier<DeliveryMethodState> {
  final DeliveryMethodService _deliveryMethodService;
  final DeliveryFeeService _deliveryFeeService;
  final AppLogger _logger = AppLogger();

  DeliveryMethodNotifier(this._deliveryMethodService, this._deliveryFeeService)
      : super(DeliveryMethodState(lastUpdated: DateTime.now()));

  /// Load available delivery methods for vendor
  Future<void> loadAvailableMethods({
    required String vendorId,
    required double orderAmount,
    CustomerAddress? deliveryAddress,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      _logger.info('🚚 [DELIVERY-PROVIDER] Loading available methods for vendor: $vendorId');

      // Get available methods
      final availableMethods = await _deliveryMethodService.getAvailableMethodsForVendor(
        vendorId: vendorId,
        orderAmount: orderAmount,
        deliveryAddress: deliveryAddress,
      );

      // Calculate fees for all available methods
      final feeCalculations = <CustomerDeliveryMethod, DeliveryFeeCalculation?>{};
      
      for (final method in availableMethods) {
        try {
          final mappedMethod = _mapToDeliveryMethod(method);
          if (mappedMethod != null) {
            final calculation = await _deliveryFeeService.calculateDeliveryFee(
              deliveryMethod: mappedMethod,
              vendorId: vendorId,
              subtotal: orderAmount,
              deliveryLatitude: deliveryAddress?.latitude,
              deliveryLongitude: deliveryAddress?.longitude,
            );
            feeCalculations[method] = calculation;
          }
        } catch (e) {
          _logger.warning('Failed to calculate fee for ${method.value}: $e');
          feeCalculations[method] = DeliveryFeeCalculation.pickup(method.value);
        }
      }

      // Get recommendations
      final recommendation = await _deliveryMethodService.getMethodRecommendations(
        vendorId: vendorId,
        orderAmount: orderAmount,
        deliveryAddress: deliveryAddress,
      );

      // Update selected method if current selection is not available
      CustomerDeliveryMethod selectedMethod = state.selectedMethod;
      if (!availableMethods.contains(selectedMethod)) {
        selectedMethod = recommendation.hasRecommendation 
            ? recommendation.recommended!
            : (availableMethods.isNotEmpty ? availableMethods.first : CustomerDeliveryMethod.customerPickup);
      }

      state = state.copyWith(
        selectedMethod: selectedMethod,
        availableMethods: availableMethods,
        feeCalculations: feeCalculations,
        recommendation: recommendation,
        isLoading: false,
      );

      _logger.info('✅ [DELIVERY-PROVIDER] Loaded ${availableMethods.length} available methods');

    } catch (e) {
      _logger.error('❌ [DELIVERY-PROVIDER] Failed to load available methods', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Select delivery method
  void selectMethod(CustomerDeliveryMethod method) {
    _logger.info('🚚 [DELIVERY-PROVIDER] Selected method: ${method.value}');
    
    if (!state.availableMethods.contains(method)) {
      _logger.warning('Selected method is not available: ${method.value}');
      return;
    }

    state = state.copyWith(selectedMethod: method);
  }

  /// Refresh delivery fees
  Future<void> refreshFees({
    required String vendorId,
    required double orderAmount,
    CustomerAddress? deliveryAddress,
  }) async {
    try {
      _logger.info('💰 [DELIVERY-PROVIDER] Refreshing delivery fees');

      final feeCalculations = <CustomerDeliveryMethod, DeliveryFeeCalculation?>{};
      
      for (final method in state.availableMethods) {
        try {
          final mappedMethod = _mapToDeliveryMethod(method);
          if (mappedMethod != null) {
            final calculation = await _deliveryFeeService.calculateDeliveryFee(
              deliveryMethod: mappedMethod,
              vendorId: vendorId,
              subtotal: orderAmount,
              deliveryLatitude: deliveryAddress?.latitude,
              deliveryLongitude: deliveryAddress?.longitude,
            );
            feeCalculations[method] = calculation;
          }
        } catch (e) {
          _logger.warning('Failed to refresh fee for ${method.value}: $e');
          // Keep existing calculation if refresh fails
          feeCalculations[method] = state.feeCalculations[method];
        }
      }

      state = state.copyWith(feeCalculations: feeCalculations);

      _logger.info('✅ [DELIVERY-PROVIDER] Fees refreshed');

    } catch (e) {
      _logger.error('❌ [DELIVERY-PROVIDER] Failed to refresh fees', e);
    }
  }

  /// Get delivery fee for specific method
  double getMethodFee(CustomerDeliveryMethod method) {
    final calculation = state.feeCalculations[method];
    return calculation?.finalFee ?? 0.0;
  }

  /// Check if method is available
  bool isMethodAvailable(CustomerDeliveryMethod method) {
    return state.availableMethods.contains(method);
  }

  /// Clear state
  void clear() {
    state = DeliveryMethodState(lastUpdated: DateTime.now());
  }

  /// Map CustomerDeliveryMethod to service delivery method
  dynamic _mapToDeliveryMethod(CustomerDeliveryMethod method) {
    switch (method) {
      case CustomerDeliveryMethod.customerPickup:
      case CustomerDeliveryMethod.pickup:
        return 'customer_pickup';
      case CustomerDeliveryMethod.salesAgentPickup:
        return 'sales_agent_pickup';
      case CustomerDeliveryMethod.ownFleet:
      case CustomerDeliveryMethod.delivery:
        return 'own_fleet';
      case CustomerDeliveryMethod.thirdParty:
      case CustomerDeliveryMethod.lalamove:
        return 'third_party';
      default:
        return null;
    }
  }
}

/// Delivery method provider
final deliveryMethodProvider = StateNotifierProvider<DeliveryMethodNotifier, DeliveryMethodState>((ref) {
  final deliveryMethodService = ref.watch(deliveryMethodServiceProvider);
  final deliveryFeeService = ref.watch(deliveryFeeServiceProvider);
  return DeliveryMethodNotifier(deliveryMethodService, deliveryFeeService);
});

/// Delivery method service provider
final deliveryMethodServiceProvider = Provider<DeliveryMethodService>((ref) {
  return DeliveryMethodService();
});

/// Delivery fee service provider
final deliveryFeeServiceProvider = Provider<DeliveryFeeService>((ref) {
  return DeliveryFeeService();
});

/// Convenience providers
final selectedDeliveryMethodProvider = Provider<CustomerDeliveryMethod>((ref) {
  return ref.watch(deliveryMethodProvider).selectedMethod;
});

final availableDeliveryMethodsProvider = Provider<List<CustomerDeliveryMethod>>((ref) {
  return ref.watch(deliveryMethodProvider).availableMethods;
});

final deliveryFeeCalculationsProvider = Provider<Map<CustomerDeliveryMethod, DeliveryFeeCalculation?>>((ref) {
  return ref.watch(deliveryMethodProvider).feeCalculations;
});

final selectedMethodFeeProvider = Provider<double>((ref) {
  return ref.watch(deliveryMethodProvider).selectedMethodFee;
});

final deliveryMethodRecommendationProvider = Provider<DeliveryMethodRecommendation?>((ref) {
  return ref.watch(deliveryMethodProvider).recommendation;
});

final isDeliveryMethodLoadingProvider = Provider<bool>((ref) {
  return ref.watch(deliveryMethodProvider).isLoading;
});

final deliveryMethodErrorProvider = Provider<String?>((ref) {
  return ref.watch(deliveryMethodProvider).error;
});
