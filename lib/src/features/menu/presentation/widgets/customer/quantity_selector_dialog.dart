import 'package:flutter/material.dart';
import '../../../data/models/product.dart';

/// Reusable quantity selector dialog for adding items to cart
/// Displays product information and allows quantity selection with validation
class QuantitySelectorDialog extends StatefulWidget {
  final Product product;
  final Function(int quantity) onAddToCart;
  final int initialQuantity;

  const QuantitySelectorDialog({
    super.key,
    required this.product,
    required this.onAddToCart,
    this.initialQuantity = 1,
  });

  @override
  State<QuantitySelectorDialog> createState() => _QuantitySelectorDialogState();

  /// Static method to show the dialog
  static Future<void> show({
    required BuildContext context,
    required Product product,
    required Function(int quantity) onAddToCart,
    int initialQuantity = 1,
  }) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return QuantitySelectorDialog(
          product: product,
          onAddToCart: onAddToCart,
          initialQuantity: initialQuantity,
        );
      },
    );
  }
}

class _QuantitySelectorDialogState extends State<QuantitySelectorDialog> {
  late int selectedQuantity;
  late int minQuantity;

  @override
  void initState() {
    super.initState();
    selectedQuantity = widget.initialQuantity;
    minQuantity = widget.product.minOrderQuantity ?? 1;
    
    // Ensure initial quantity meets minimum requirement
    if (selectedQuantity < minQuantity) {
      selectedQuantity = minQuantity;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Add to Cart',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product info
          _buildProductInfo(theme),
          
          const SizedBox(height: 20),
          
          // Quantity selector
          _buildQuantitySelector(theme),
          
          if (minQuantity > 1) ...[
            const SizedBox(height: 8),
            Text(
              'Minimum order: $minQuantity',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Total price
          _buildTotalPrice(theme),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onAddToCart(selectedQuantity);
          },
          child: const Text('Add to Cart'),
        ),
      ],
    );
  }

  Widget _buildProductInfo(ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: widget.product.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.product.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.fastfood,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : Icon(
                  Icons.fastfood,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'RM ${widget.product.basePrice.toStringAsFixed(2)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantity',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: selectedQuantity > minQuantity
                  ? () => setState(() => selectedQuantity--)
                  : null,
              icon: const Icon(Icons.remove),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              selectedQuantity.toString(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: () => setState(() => selectedQuantity++),
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalPrice(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          Text(
            'RM ${(widget.product.basePrice * selectedQuantity).toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
