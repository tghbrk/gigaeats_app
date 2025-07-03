
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enhanced_cart_models.dart';
import '../../../menu/data/models/menu_item.dart';
import '../../../core/utils/logger.dart';
import '../../../../core/constants/app_constants.dart';

/// Advanced cart quantity management with bulk pricing and validation
class CartQuantityManager {
  final AppLogger _logger = AppLogger();

  /// Calculate optimal quantity based on bulk pricing
  QuantityOptimizationResult calculateOptimalQuantity({
    required MenuItem menuItem,
    required int requestedQuantity,
    double? budgetLimit,
  }) {
    try {
      _logger.debug('📊 [QUANTITY-MGR] Calculating optimal quantity for ${menuItem.name}');

      // Validate basic quantity constraints
      final validationResult = _validateQuantityConstraints(menuItem, requestedQuantity);
      if (!validationResult.isValid) {
        return QuantityOptimizationResult.invalid(validationResult.errors);
      }

      // If no bulk pricing, return requested quantity
      if (menuItem.bulkPricingTiers.isEmpty) {
        return QuantityOptimizationResult.success(
          optimalQuantity: requestedQuantity,
          unitPrice: menuItem.basePrice,
          totalPrice: menuItem.basePrice * requestedQuantity,
          savings: 0.0,
          appliedTier: null,
        );
      }

      // Find the best pricing tier for requested quantity
      final currentTier = _findBestTier(menuItem.bulkPricingTiers, requestedQuantity);
      final currentPrice = currentTier?.pricePerUnit ?? menuItem.basePrice;
      final currentTotal = currentPrice * requestedQuantity;

      // Check if increasing quantity to next tier would be beneficial
      final nextTierAnalysis = _analyzeNextTierBenefit(
        menuItem,
        requestedQuantity,
        budgetLimit,
      );

      // Calculate savings compared to base price
      final basePriceTotal = menuItem.basePrice * requestedQuantity;
      final savings = basePriceTotal - currentTotal;

      return QuantityOptimizationResult.success(
        optimalQuantity: nextTierAnalysis.suggestedQuantity ?? requestedQuantity,
        unitPrice: nextTierAnalysis.unitPrice ?? currentPrice,
        totalPrice: nextTierAnalysis.totalPrice ?? currentTotal,
        savings: nextTierAnalysis.additionalSavings ?? savings,
        appliedTier: nextTierAnalysis.tier ?? currentTier,
        suggestion: nextTierAnalysis.suggestion,
      );

    } catch (e) {
      _logger.error('❌ [QUANTITY-MGR] Failed to calculate optimal quantity', e);
      return QuantityOptimizationResult.error('Failed to calculate optimal quantity: $e');
    }
  }

  /// Validate quantity increase/decrease operations
  QuantityValidationResult validateQuantityChange({
    required EnhancedCartItem cartItem,
    required int newQuantity,
    required MenuItem menuItem,
  }) {
    try {
      _logger.debug('✅ [QUANTITY-MGR] Validating quantity change: ${cartItem.name} to $newQuantity');

      final errors = <String>[];
      final warnings = <String>[];

      // Basic validation
      if (newQuantity < 0) {
        errors.add('Quantity cannot be negative');
      }

      if (newQuantity == 0) {
        return QuantityValidationResult.removal();
      }

      // Check minimum quantity
      if (newQuantity < menuItem.minimumOrderQuantity) {
        errors.add('Minimum quantity is ${menuItem.minimumOrderQuantity}');
      }

      // Check maximum quantity
      if (menuItem.maximumOrderQuantity != null && newQuantity > menuItem.maximumOrderQuantity!) {
        errors.add('Maximum quantity is ${menuItem.maximumOrderQuantity}');
      }

      // Check available quantity
      if (menuItem.availableQuantity != null && newQuantity > menuItem.availableQuantity!) {
        errors.add('Only ${menuItem.availableQuantity} items available');
      }

      // Check bulk pricing benefits
      if (menuItem.bulkPricingTiers.isNotEmpty) {
        final currentTier = _findBestTier(menuItem.bulkPricingTiers, cartItem.quantity);
        final newTier = _findBestTier(menuItem.bulkPricingTiers, newQuantity);

        if (newTier != null && currentTier != newTier) {
          if (newTier.pricePerUnit < (currentTier?.pricePerUnit ?? menuItem.basePrice)) {
            warnings.add('Better pricing available at quantity ${newTier.minimumQuantity}');
          }
        }
      }

      // Check if quantity change affects cart total significantly
      final currentTotal = cartItem.totalPrice;
      final newUnitPrice = menuItem.getEffectivePrice(newQuantity);
      final newTotal = newUnitPrice * newQuantity;
      final priceDifference = newTotal - currentTotal;

      if (priceDifference.abs() > AppConstants.significantPriceChangeThreshold) {
        warnings.add('Price will change by RM ${priceDifference.abs().toStringAsFixed(2)}');
      }

      return errors.isEmpty
          ? QuantityValidationResult.valid(warnings: warnings)
          : QuantityValidationResult.invalid(errors, warnings: warnings);

    } catch (e) {
      _logger.error('❌ [QUANTITY-MGR] Failed to validate quantity change', e);
      return QuantityValidationResult.invalid(['Validation error: $e']);
    }
  }

  /// Calculate quantity recommendations for cart optimization
  List<QuantityRecommendation> generateQuantityRecommendations({
    required List<EnhancedCartItem> cartItems,
    required Map<String, MenuItem> menuItems,
    double? budgetLimit,
  }) {
    try {
      _logger.debug('💡 [QUANTITY-MGR] Generating quantity recommendations');

      final recommendations = <QuantityRecommendation>[];

      for (final cartItem in cartItems) {
        final menuItem = menuItems[cartItem.productId];
        if (menuItem == null) continue;

        // Check for bulk pricing opportunities
        if (menuItem.bulkPricingTiers.isNotEmpty) {
          final nextTier = _findNextBetterTier(menuItem.bulkPricingTiers, cartItem.quantity);

          if (nextTier != null) {
            final currentTotal = cartItem.totalPrice;
            final nextTierTotal = nextTier.pricePerUnit * nextTier.minimumQuantity;
            final savings = (menuItem.basePrice * nextTier.minimumQuantity) - nextTierTotal;

            if (savings > AppConstants.minSavingsThreshold) {
              recommendations.add(QuantityRecommendation(
                cartItemId: cartItem.id,
                currentQuantity: cartItem.quantity,
                recommendedQuantity: nextTier.minimumQuantity,
                currentTotal: currentTotal,
                recommendedTotal: nextTierTotal,
                savings: savings,
                reason: 'Bulk pricing discount available',
                type: QuantityRecommendationType.bulkDiscount,
              ));
            }
          }
        }

        // Check for minimum order optimizations
        if (cartItem.quantity < menuItem.minimumOrderQuantity * 2) {
          final doubleMinQuantity = menuItem.minimumOrderQuantity * 2;
          if (menuItem.isValidQuantity(doubleMinQuantity)) {
            final currentUnitPrice = menuItem.getEffectivePrice(cartItem.quantity);
            final doubleUnitPrice = menuItem.getEffectivePrice(doubleMinQuantity);

            if (doubleUnitPrice < currentUnitPrice) {
              recommendations.add(QuantityRecommendation(
                cartItemId: cartItem.id,
                currentQuantity: cartItem.quantity,
                recommendedQuantity: doubleMinQuantity,
                currentTotal: cartItem.totalPrice,
                recommendedTotal: doubleUnitPrice * doubleMinQuantity,
                savings: (currentUnitPrice - doubleUnitPrice) * doubleMinQuantity,
                reason: 'Better unit price at higher quantity',
                type: QuantityRecommendationType.betterUnitPrice,
              ));
            }
          }
        }
      }

      // Sort recommendations by savings (highest first)
      recommendations.sort((a, b) => b.savings.compareTo(a.savings));

      _logger.debug('💡 [QUANTITY-MGR] Generated ${recommendations.length} recommendations');
      return recommendations;

    } catch (e) {
      _logger.error('❌ [QUANTITY-MGR] Failed to generate recommendations', e);
      return [];
    }
  }

  /// Calculate quantity for budget optimization
  QuantityBudgetResult optimizeQuantityForBudget({
    required MenuItem menuItem,
    required double budget,
    Map<String, dynamic>? customizations,
  }) {
    try {
      _logger.debug('💰 [QUANTITY-MGR] Optimizing quantity for budget: RM${budget.toStringAsFixed(2)}');

      // Calculate customization cost
      double customizationCost = 0.0;
      if (customizations != null) {
        for (final customization in menuItem.customizations) {
          final selectedValue = customizations[customization.id];
          if (selectedValue != null) {
            if (customization.additionalCost != null) {
              customizationCost += customization.additionalCost!;
            }
            for (final option in customization.options) {
              if (selectedValue is List && selectedValue.contains(option.id)) {
                customizationCost += option.additionalCost;
              } else if (selectedValue == option.id) {
                customizationCost += option.additionalCost;
              }
            }
          }
        }
      }

      // Find maximum quantity within budget
      int maxQuantity = 0;
      double bestUnitPrice = menuItem.basePrice + customizationCost;
      BulkPricingTier? bestTier;

      // Check each bulk pricing tier
      for (final tier in menuItem.bulkPricingTiers) {
        final tierUnitPrice = tier.pricePerUnit + customizationCost;
        final tierMaxQuantity = (budget / tierUnitPrice).floor();

        if (tierMaxQuantity >= tier.minimumQuantity && tierMaxQuantity > maxQuantity) {
          maxQuantity = tierMaxQuantity;
          bestUnitPrice = tierUnitPrice;
          bestTier = tier;
        }
      }

      // Check base price if no tier applies
      if (maxQuantity == 0) {
        maxQuantity = (budget / bestUnitPrice).floor();
      }

      // Ensure quantity meets minimum requirements
      if (maxQuantity < menuItem.minimumOrderQuantity) {
        return QuantityBudgetResult.insufficient(
          budget: budget,
          minimumRequired: menuItem.minimumOrderQuantity * bestUnitPrice,
          minimumQuantity: menuItem.minimumOrderQuantity,
        );
      }

      // Respect maximum quantity limits
      if (menuItem.maximumOrderQuantity != null && maxQuantity > menuItem.maximumOrderQuantity!) {
        maxQuantity = menuItem.maximumOrderQuantity!;
      }

      final totalCost = bestUnitPrice * maxQuantity;
      final remainingBudget = budget - totalCost;

      return QuantityBudgetResult.success(
        optimalQuantity: maxQuantity,
        unitPrice: bestUnitPrice,
        totalCost: totalCost,
        remainingBudget: remainingBudget,
        appliedTier: bestTier,
      );

    } catch (e) {
      _logger.error('❌ [QUANTITY-MGR] Failed to optimize quantity for budget', e);
      return QuantityBudgetResult.error('Budget optimization failed: $e');
    }
  }

  /// Validate quantity constraints
  CartValidationResult _validateQuantityConstraints(MenuItem menuItem, int quantity) {
    final errors = <String>[];

    if (quantity < menuItem.minimumOrderQuantity) {
      errors.add('Minimum quantity is ${menuItem.minimumOrderQuantity}');
    }

    if (menuItem.maximumOrderQuantity != null && quantity > menuItem.maximumOrderQuantity!) {
      errors.add('Maximum quantity is ${menuItem.maximumOrderQuantity}');
    }

    if (menuItem.availableQuantity != null && quantity > menuItem.availableQuantity!) {
      errors.add('Only ${menuItem.availableQuantity} items available');
    }

    return errors.isEmpty
        ? CartValidationResult.valid()
        : CartValidationResult.invalid(errors);
  }

  /// Find the best pricing tier for a given quantity
  BulkPricingTier? _findBestTier(List<BulkPricingTier> tiers, int quantity) {
    BulkPricingTier? bestTier;
    for (final tier in tiers) {
      if (quantity >= tier.minimumQuantity) {
        if (bestTier == null || tier.minimumQuantity > bestTier.minimumQuantity) {
          bestTier = tier;
        }
      }
    }
    return bestTier;
  }

  /// Find the next better pricing tier
  BulkPricingTier? _findNextBetterTier(List<BulkPricingTier> tiers, int currentQuantity) {
    BulkPricingTier? nextTier;
    for (final tier in tiers) {
      if (tier.minimumQuantity > currentQuantity) {
        if (nextTier == null || tier.minimumQuantity < nextTier.minimumQuantity) {
          nextTier = tier;
        }
      }
    }
    return nextTier;
  }

  /// Analyze next tier benefit
  NextTierAnalysis _analyzeNextTierBenefit(
    MenuItem menuItem,
    int currentQuantity,
    double? budgetLimit,
  ) {
    final nextTier = _findNextBetterTier(menuItem.bulkPricingTiers, currentQuantity);
    if (nextTier == null) {
      return NextTierAnalysis();
    }

    final nextTierPrice = nextTier.pricePerUnit;
    final nextTierTotal = nextTierPrice * nextTier.minimumQuantity;

    // Check if next tier is within budget
    if (budgetLimit != null && nextTierTotal > budgetLimit) {
      return NextTierAnalysis();
    }

    // Calculate savings
    final basePriceTotal = menuItem.basePrice * nextTier.minimumQuantity;
    final savings = basePriceTotal - nextTierTotal;

    if (savings > AppConstants.minSavingsThreshold) {
      return NextTierAnalysis(
        tier: nextTier,
        suggestedQuantity: nextTier.minimumQuantity,
        unitPrice: nextTierPrice,
        totalPrice: nextTierTotal,
        additionalSavings: savings,
        suggestion: 'Add ${nextTier.minimumQuantity - currentQuantity} more items to save RM${savings.toStringAsFixed(2)}',
      );
    }

    return NextTierAnalysis();
  }
}

/// Quantity optimization result
class QuantityOptimizationResult {
  final bool isSuccess;
  final String? error;
  final List<String> errors;
  final int? optimalQuantity;
  final double? unitPrice;
  final double? totalPrice;
  final double? savings;
  final BulkPricingTier? appliedTier;
  final String? suggestion;

  QuantityOptimizationResult._({
    required this.isSuccess,
    this.error,
    this.errors = const [],
    this.optimalQuantity,
    this.unitPrice,
    this.totalPrice,
    this.savings,
    this.appliedTier,
    this.suggestion,
  });

  factory QuantityOptimizationResult.success({
    required int optimalQuantity,
    required double unitPrice,
    required double totalPrice,
    required double savings,
    BulkPricingTier? appliedTier,
    String? suggestion,
  }) => QuantityOptimizationResult._(
    isSuccess: true,
    optimalQuantity: optimalQuantity,
    unitPrice: unitPrice,
    totalPrice: totalPrice,
    savings: savings,
    appliedTier: appliedTier,
    suggestion: suggestion,
  );

  factory QuantityOptimizationResult.invalid(List<String> errors) => 
      QuantityOptimizationResult._(isSuccess: false, errors: errors);

  factory QuantityOptimizationResult.error(String error) => 
      QuantityOptimizationResult._(isSuccess: false, error: error);
}

/// Quantity validation result
class QuantityValidationResult {
  final bool isValid;
  final bool isRemoval;
  final List<String> errors;
  final List<String> warnings;

  QuantityValidationResult._({
    required this.isValid,
    this.isRemoval = false,
    this.errors = const [],
    this.warnings = const [],
  });

  factory QuantityValidationResult.valid({List<String>? warnings}) => 
      QuantityValidationResult._(isValid: true, warnings: warnings ?? []);

  factory QuantityValidationResult.invalid(List<String> errors, {List<String>? warnings}) => 
      QuantityValidationResult._(
        isValid: false, 
        errors: errors, 
        warnings: warnings ?? [],
      );

  factory QuantityValidationResult.removal() => 
      QuantityValidationResult._(isValid: true, isRemoval: true);
}

/// Quantity recommendation
class QuantityRecommendation {
  final String cartItemId;
  final int currentQuantity;
  final int recommendedQuantity;
  final double currentTotal;
  final double recommendedTotal;
  final double savings;
  final String reason;
  final QuantityRecommendationType type;

  QuantityRecommendation({
    required this.cartItemId,
    required this.currentQuantity,
    required this.recommendedQuantity,
    required this.currentTotal,
    required this.recommendedTotal,
    required this.savings,
    required this.reason,
    required this.type,
  });
}

/// Quantity recommendation types
enum QuantityRecommendationType {
  bulkDiscount,
  betterUnitPrice,
  minimumOrder,
  budgetOptimization,
}

/// Quantity budget result
class QuantityBudgetResult {
  final bool isSuccess;
  final String? error;
  final double budget;
  final int? optimalQuantity;
  final double? unitPrice;
  final double? totalCost;
  final double? remainingBudget;
  final BulkPricingTier? appliedTier;
  final double? minimumRequired;
  final int? minimumQuantity;

  QuantityBudgetResult._({
    required this.isSuccess,
    this.error,
    required this.budget,
    this.optimalQuantity,
    this.unitPrice,
    this.totalCost,
    this.remainingBudget,
    this.appliedTier,
    this.minimumRequired,
    this.minimumQuantity,
  });

  factory QuantityBudgetResult.success({
    required int optimalQuantity,
    required double unitPrice,
    required double totalCost,
    required double remainingBudget,
    BulkPricingTier? appliedTier,
  }) => QuantityBudgetResult._(
    isSuccess: true,
    budget: totalCost + remainingBudget,
    optimalQuantity: optimalQuantity,
    unitPrice: unitPrice,
    totalCost: totalCost,
    remainingBudget: remainingBudget,
    appliedTier: appliedTier,
  );

  factory QuantityBudgetResult.insufficient({
    required double budget,
    required double minimumRequired,
    required int minimumQuantity,
  }) => QuantityBudgetResult._(
    isSuccess: false,
    budget: budget,
    minimumRequired: minimumRequired,
    minimumQuantity: minimumQuantity,
  );

  factory QuantityBudgetResult.error(String error) => 
      QuantityBudgetResult._(isSuccess: false, error: error, budget: 0.0);
}

/// Next tier analysis
class NextTierAnalysis {
  final BulkPricingTier? tier;
  final int? suggestedQuantity;
  final double? unitPrice;
  final double? totalPrice;
  final double? additionalSavings;
  final String? suggestion;

  NextTierAnalysis({
    this.tier,
    this.suggestedQuantity,
    this.unitPrice,
    this.totalPrice,
    this.additionalSavings,
    this.suggestion,
  });
}

/// Cart quantity manager provider
final cartQuantityManagerProvider = Provider<CartQuantityManager>((ref) {
  return CartQuantityManager();
});
