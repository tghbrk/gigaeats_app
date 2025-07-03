import 'package:flutter/material.dart';
import '../../../../user_management/domain/vendor.dart';
import '../../../../user_management/application/vendor_utils.dart';

/// Reusable restaurant information card widget
/// Displays restaurant details including name, rating, status, cuisine types, and delivery info
class RestaurantInfoCard extends StatelessWidget {
  final Vendor vendor;
  final VoidCallback? onFavoritePressed;
  final VoidCallback? onSharePressed;
  final bool showActions;

  const RestaurantInfoCard({
    super.key,
    required this.vendor,
    this.onFavoritePressed,
    this.onSharePressed,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOpen = VendorUtils.isVendorOpen(vendor);
    final statusText = VendorUtils.getVendorStatusText(vendor);
    final estimatedDeliveryTime = VendorUtils.getEstimatedDeliveryTime(vendor);

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant name and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    vendor.businessName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (showActions) ...[
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: onFavoritePressed,
                    tooltip: 'Add to favorites',
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: onSharePressed,
                    tooltip: 'Share restaurant',
                  ),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOpen 
                        ? theme.colorScheme.primaryContainer 
                        : theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOpen ? Icons.access_time : Icons.schedule,
                        size: 16,
                        color: isOpen 
                            ? theme.colorScheme.onPrimaryContainer 
                            : theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isOpen 
                              ? theme.colorScheme.onPrimaryContainer 
                              : theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Rating and reviews
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  vendor.rating.toStringAsFixed(1),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${vendor.totalReviews} reviews)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Description
            if (vendor.description?.isNotEmpty == true) ...[
              Text(
                vendor.description!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Cuisine types and features
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...vendor.cuisineTypes.map((cuisine) => Chip(
                  label: Text(cuisine),
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                  side: BorderSide.none,
                )),
                if (vendor.isHalalCertified)
                  Chip(
                    label: const Text('Halal Certified'),
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                    avatar: const Icon(Icons.verified, size: 18, color: Colors.green),
                    side: BorderSide.none,
                  ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Delivery and order info cards
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    theme,
                    Icons.delivery_dining,
                    'Delivery Fee',
                    'RM ${vendor.deliveryFee?.toStringAsFixed(2) ?? '5.00'}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    theme,
                    Icons.access_time,
                    'Delivery Time',
                    estimatedDeliveryTime,
                  ),
                ),
              ],
            ),
            
            if (vendor.minimumOrderAmount != null) ...[
              const SizedBox(height: 12),
              _buildInfoCard(
                theme,
                Icons.shopping_cart,
                'Minimum Order',
                'RM ${vendor.minimumOrderAmount!.toStringAsFixed(2)}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
