import 'package:flutter/material.dart';

// TODO: Restore missing URI target - commented out for analyzer cleanup
// import '../../vendors/data/models/vendor.dart';

class VendorCard extends StatelessWidget {
  // TODO: Restore undefined class - commented out for analyzer cleanup
  // final Vendor vendor;
  final Map<String, dynamic> vendor;
  final VoidCallback? onTap;
  final bool showDetails;

  const VendorCard({
    super.key,
    required this.vendor,
    this.onTap,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Vendor Image/Avatar
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade200,
                    ),
                    // TODO: Restore undefined getters - commented out for analyzer cleanup
                    // child: vendor.coverImageUrl != null
                    child: vendor['coverImageUrl'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              // vendor.coverImageUrl!,
                              vendor['coverImageUrl']!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.restaurant,
                                  size: 30,
                                  color: Colors.grey.shade600,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.restaurant,
                            size: 30,
                            color: Colors.grey.shade600,
                          ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Vendor Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          // TODO: Restore undefined getter - commented out for analyzer cleanup
                          // vendor.businessName,
                          vendor['businessName'] ?? 'Unknown Business',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // TODO: Restore undefined getters - commented out for analyzer cleanup
                        // if (vendor.cuisineTypes.isNotEmpty)
                        if ((vendor['cuisineTypes'] as List<dynamic>?)?.isNotEmpty ?? false)
                          Text(
                            // vendor.cuisineTypes.join(', '),
                            (vendor['cuisineTypes'] as List<dynamic>).join(', '),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              // TODO: Restore undefined getter - commented out for analyzer cleanup
                              // vendor.rating.toStringAsFixed(1),
                              (vendor['rating'] as double? ?? 0.0).toStringAsFixed(1),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              // TODO: Restore undefined getter - commented out for analyzer cleanup
                              // '(${vendor.totalReviews} reviews)',
                              '(${vendor['totalReviews'] ?? 0} reviews)',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Status Indicators
                  Column(
                    children: [
                      // TODO: Restore vendor.isVerified when provider is implemented - commented out for analyzer cleanup
                  if (vendor['isVerified'] ?? false) // vendor.isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Verified',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      // TODO: Restore vendor.isHalalCertified when provider is implemented - commented out for analyzer cleanup
                      if (vendor['isHalalCertified'] ?? false) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Halal',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              
              if (showDetails) ...[
                const SizedBox(height: 12),
                
                // Business Address
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        // TODO: Restore vendor.businessAddress when provider is implemented - commented out for analyzer cleanup
                      vendor['businessAddress'] ?? 'Address', // vendor.businessAddress,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Additional Info
                Row(
                  children: [
                    // TODO: Restore vendor.minimumOrderAmount when provider is implemented - commented out for analyzer cleanup
                    if ((vendor['minimumOrderAmount'] ?? 0) > 0) ...[
                      Icon(
                        Icons.shopping_cart,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        // TODO: Restore vendor.minimumOrderAmount when provider is implemented - commented out for analyzer cleanup
                        'Min: RM${((vendor['minimumOrderAmount'] ?? 0) as double).toStringAsFixed(2)}', // vendor.minimumOrderAmount!.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    // TODO: Restore vendor.deliveryFee when provider is implemented - commented out for analyzer cleanup
                    if ((vendor['deliveryFee'] ?? 0) > 0) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.delivery_dining,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        // TODO: Restore vendor.deliveryFee when provider is implemented - commented out for analyzer cleanup
                        'Delivery: RM${((vendor['deliveryFee'] ?? 0) as double).toStringAsFixed(2)}', // vendor.deliveryFee!.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
