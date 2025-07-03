import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/models/enhanced_cart_models.dart';
import '../controllers/cart_operations_controller.dart';
import '../../../core/utils/logger.dart';


/// Enhanced cart item widget with comprehensive functionality
class EnhancedCartItemWidget extends ConsumerStatefulWidget {
  final EnhancedCartItem item;
  final bool showQuantityControls;
  final bool showCustomizations;
  final bool showRemoveButton;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const EnhancedCartItemWidget({
    super.key,
    required this.item,
    this.showQuantityControls = true,
    this.showCustomizations = true,
    this.showRemoveButton = true,
    this.onTap,
    this.onEdit,
  });

  @override
  ConsumerState<EnhancedCartItemWidget> createState() => _EnhancedCartItemWidgetState();
}

class _EnhancedCartItemWidgetState extends ConsumerState<EnhancedCartItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final AppLogger _logger = AppLogger();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final operationsState = ref.watch(cartOperationsControllerProvider);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onTapDown: (_) => _animationController.forward(),
                onTapUp: (_) => _animationController.reverse(),
                onTapCancel: () => _animationController.reverse(),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildItemHeader(theme),
                      const SizedBox(height: 12),
                      _buildItemDetails(theme),
                      if (widget.showCustomizations && widget.item.customizations != null)
                        ...[
                          const SizedBox(height: 8),
                          _buildCustomizations(theme),
                        ],
                      if (widget.item.notes != null && widget.item.notes!.isNotEmpty)
                        ...[
                          const SizedBox(height: 8),
                          _buildNotes(theme),
                        ],
                      const SizedBox(height: 12),
                      _buildItemFooter(theme, operationsState),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemHeader(ThemeData theme) {
    return Row(
      children: [
        // Item image
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: widget.item.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: widget.item.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.fastfood,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.fastfood,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                )
              : Icon(
                  Icons.fastfood,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
        ),
        const SizedBox(width: 12),
        
        // Item info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.item.vendorName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Availability indicator
        if (!widget.item.isAvailable)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Unavailable',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildItemDetails(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Base price
              if (widget.item.customizationCost > 0) ...[
                Text(
                  'Base: RM ${widget.item.basePrice.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Customizations: +RM ${widget.item.customizationCost.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              
              // Unit price
              Text(
                'RM ${widget.item.unitPrice.toStringAsFixed(2)} each',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        
        // Total price
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Total',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'RM ${widget.item.totalPrice.toStringAsFixed(2)}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomizations(ThemeData theme) {
    final customizationsText = widget.item.formattedCustomizations;
    if (customizationsText.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.tune,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              customizationsText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotes(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.note,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.item.notes!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemFooter(ThemeData theme, CartOperationsState operationsState) {
    return Row(
      children: [
        // Quantity controls
        if (widget.showQuantityControls)
          _buildQuantityControls(theme, operationsState),
        
        const Spacer(),
        
        // Edit button
        if (widget.onEdit != null)
          IconButton(
            onPressed: widget.onEdit,
            icon: Icon(
              Icons.edit,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            tooltip: 'Edit item',
          ),
        
        // Remove button
        if (widget.showRemoveButton)
          IconButton(
            onPressed: operationsState.isLoading 
                ? null 
                : () => _removeItem(),
            icon: Icon(
              Icons.delete_outline,
              size: 20,
              color: theme.colorScheme.error,
            ),
            tooltip: 'Remove item',
          ),
      ],
    );
  }

  Widget _buildQuantityControls(ThemeData theme, CartOperationsState operationsState) {
    final isLoading = operationsState.isLoading;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease button
          IconButton(
            onPressed: (isLoading || !widget.item.canDecreaseQuantity) 
                ? null 
                : () => _updateQuantity(widget.item.quantity - 1),
            icon: Icon(
              Icons.remove,
              size: 18,
              color: (isLoading || !widget.item.canDecreaseQuantity)
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                  : theme.colorScheme.primary,
            ),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          
          // Quantity display
          Container(
            constraints: const BoxConstraints(minWidth: 40),
            child: Text(
              widget.item.quantity.toString(),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Increase button
          IconButton(
            onPressed: (isLoading || !widget.item.canIncreaseQuantity) 
                ? null 
                : () => _updateQuantity(widget.item.quantity + 1),
            icon: Icon(
              Icons.add,
              size: 18,
              color: (isLoading || !widget.item.canIncreaseQuantity)
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                  : theme.colorScheme.primary,
            ),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  void _updateQuantity(int newQuantity) {
    _logger.info('📝 [CART-ITEM] Updating quantity to $newQuantity for ${widget.item.name}');
    
    ref.read(cartOperationsControllerProvider.notifier)
        .updateItemQuantity(widget.item.id, newQuantity);
  }

  void _removeItem() {
    _logger.info('🗑️ [CART-ITEM] Removing item ${widget.item.name}');
    
    ref.read(cartOperationsControllerProvider.notifier)
        .removeItem(widget.item.id);
  }
}
