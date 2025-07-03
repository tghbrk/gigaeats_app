import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/cart_quantity_manager.dart';
import '../../../menu/data/models/menu_item.dart';
import '../../../core/utils/logger.dart';

/// Advanced quantity selector with bulk pricing and recommendations
class QuantitySelectorWidget extends ConsumerStatefulWidget {
  final MenuItem menuItem;
  final int initialQuantity;
  final Map<String, dynamic>? customizations;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<QuantityOptimizationResult>? onOptimizationResult;
  final bool showBulkPricing;
  final bool showRecommendations;
  final double? budgetLimit;

  const QuantitySelectorWidget({
    super.key,
    required this.menuItem,
    required this.initialQuantity,
    this.customizations,
    required this.onQuantityChanged,
    this.onOptimizationResult,
    this.showBulkPricing = true,
    this.showRecommendations = true,
    this.budgetLimit,
  });

  @override
  ConsumerState<QuantitySelectorWidget> createState() => _QuantitySelectorWidgetState();
}

class _QuantitySelectorWidgetState extends ConsumerState<QuantitySelectorWidget>
    with TickerProviderStateMixin {
  late TextEditingController _quantityController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  int _currentQuantity = 1;
  QuantityOptimizationResult? _optimizationResult;
  final AppLogger _logger = AppLogger();

  @override
  void initState() {
    super.initState();
    _currentQuantity = widget.initialQuantity;
    _quantityController = TextEditingController(text: _currentQuantity.toString());
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _calculateOptimalQuantity();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 16),
            _buildQuantityControls(theme),
            if (widget.showBulkPricing && widget.menuItem.bulkPricingTiers.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildBulkPricingInfo(theme),
            ],
            if (_optimizationResult != null && widget.showRecommendations) ...[
              const SizedBox(height: 16),
              _buildOptimizationSuggestion(theme),
            ],
            const SizedBox(height: 16),
            _buildPricingBreakdown(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.shopping_cart,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'Select Quantity',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityControls(ThemeData theme) {
    final canDecrease = _currentQuantity > widget.menuItem.minimumOrderQuantity;
    final canIncrease = widget.menuItem.maximumOrderQuantity == null || 
                       _currentQuantity < widget.menuItem.maximumOrderQuantity!;

    return Row(
      children: [
        // Decrease button
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  color: canDecrease 
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: canDecrease ? () => _updateQuantity(_currentQuantity - 1) : null,
                  icon: Icon(
                    Icons.remove,
                    color: canDecrease 
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(width: 16),
        
        // Quantity input
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _quantityController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                hintText: 'Qty',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              onChanged: (value) {
                final quantity = int.tryParse(value);
                if (quantity != null && quantity > 0) {
                  _updateQuantity(quantity);
                }
              },
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Increase button
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  color: canIncrease 
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: canIncrease ? () => _updateQuantity(_currentQuantity + 1) : null,
                  icon: Icon(
                    Icons.add,
                    color: canIncrease 
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBulkPricingInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_offer,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Bulk Pricing Available',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.menuItem.bulkPricingTiers.map((tier) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text(
                  '${tier.minimumQuantity}+ items:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  'RM ${tier.pricePerUnit.toStringAsFixed(2)} each',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: _currentQuantity >= tier.minimumQuantity
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (tier.discountPercentage != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${tier.discountPercentage!.toStringAsFixed(0)}% off',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildOptimizationSuggestion(ThemeData theme) {
    final result = _optimizationResult!;
    
    if (!result.isSuccess || result.suggestion == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Savings Opportunity',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  result.suggestion!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (result.optimalQuantity != null && result.optimalQuantity != _currentQuantity)
            TextButton(
              onPressed: () => _updateQuantity(result.optimalQuantity!),
              child: Text(
                'Apply',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPricingBreakdown(ThemeData theme) {
    final unitPrice = widget.menuItem.getEffectivePrice(_currentQuantity);
    final totalPrice = unitPrice * _currentQuantity;
    final baseTotalPrice = widget.menuItem.basePrice * _currentQuantity;
    final savings = baseTotalPrice - totalPrice;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Unit Price:',
                style: theme.textTheme.bodyMedium,
              ),
              const Spacer(),
              Text(
                'RM ${unitPrice.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Total ($_currentQuantity items):',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'RM ${totalPrice.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          if (savings > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'You save:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  'RM ${savings.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _updateQuantity(int newQuantity) {
    // Validate quantity
    if (newQuantity < widget.menuItem.minimumOrderQuantity) {
      newQuantity = widget.menuItem.minimumOrderQuantity;
    }
    
    if (widget.menuItem.maximumOrderQuantity != null && 
        newQuantity > widget.menuItem.maximumOrderQuantity!) {
      newQuantity = widget.menuItem.maximumOrderQuantity!;
    }

    if (widget.menuItem.availableQuantity != null && 
        newQuantity > widget.menuItem.availableQuantity!) {
      newQuantity = widget.menuItem.availableQuantity!;
    }

    setState(() {
      _currentQuantity = newQuantity;
      _quantityController.text = newQuantity.toString();
    });

    // Trigger pulse animation
    _pulseController.forward().then((_) => _pulseController.reverse());

    // Calculate optimization
    _calculateOptimalQuantity();

    // Notify parent
    widget.onQuantityChanged(newQuantity);

    _logger.debug('📊 [QUANTITY-SELECTOR] Quantity updated to $newQuantity for ${widget.menuItem.name}');
  }

  void _calculateOptimalQuantity() {
    final quantityManager = ref.read(cartQuantityManagerProvider);
    
    final result = quantityManager.calculateOptimalQuantity(
      menuItem: widget.menuItem,
      requestedQuantity: _currentQuantity,
      budgetLimit: widget.budgetLimit,
    );

    setState(() {
      _optimizationResult = result;
    });

    widget.onOptimizationResult?.call(result);
  }
}
