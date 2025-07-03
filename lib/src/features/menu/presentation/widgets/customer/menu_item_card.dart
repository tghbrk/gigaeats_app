import 'package:flutter/material.dart';
import '../../../data/models/product.dart';
import 'feature_chip.dart';

/// Enhanced menu item card widget with Material Design 3 styling
/// Displays product information, availability status, features, and add to cart functionality
class MenuItemCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final bool showAddButton;

  const MenuItemCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.showAddButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAvailable = product.isAvailable ?? true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isAvailable ? null : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image with availability overlay
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                      child: product.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                product.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.fastfood,
                                  size: 32,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.fastfood,
                              size: 32,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                    ),
                    if (!isAvailable)
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                        child: Center(
                          child: Text(
                            'Unavailable',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(width: 16),
                
                // Product details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product name with availability styling
                      Text(
                        product.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isAvailable 
                              ? theme.colorScheme.onSurface 
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      
                      if (product.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 6),
                        Text(
                          product.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isAvailable 
                                ? theme.colorScheme.onSurfaceVariant 
                                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      
                      const SizedBox(height: 12),
                      
                      // Enhanced tags and features
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (product.isHalal == true)
                            FeatureChip(
                              label: 'Halal',
                              color: Colors.green,
                              icon: Icons.verified,
                            ),
                          if (product.isVegetarian == true)
                            FeatureChip(
                              label: 'Vegetarian',
                              color: Colors.orange,
                              icon: Icons.eco,
                            ),
                          if (product.isSpicy == true)
                            FeatureChip(
                              label: 'Spicy',
                              color: Colors.red,
                              icon: Icons.local_fire_department,
                            ),
                          if (!isAvailable)
                            FeatureChip(
                              label: 'Unavailable',
                              color: Colors.grey,
                              icon: Icons.block,
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Price and add button with enhanced styling
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RM ${product.basePrice.toStringAsFixed(2)}',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isAvailable 
                                      ? theme.colorScheme.primary 
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (product.minOrderQuantity != null && product.minOrderQuantity! > 1)
                                Text(
                                  'Min: ${product.minOrderQuantity} pcs',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                          if (showAddButton && isAvailable)
                            FilledButton.icon(
                              onPressed: onAddToCart,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add'),
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            )
                          else if (showAddButton && !isAvailable)
                            OutlinedButton(
                              onPressed: null,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Unavailable'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
