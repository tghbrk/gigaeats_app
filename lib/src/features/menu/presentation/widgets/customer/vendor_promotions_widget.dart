import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/customer/vendor_details_provider.dart';
import '../../../data/models/customer/vendor_promotion.dart';
import '../../../../../shared/widgets/loading_widget.dart';

class VendorPromotionsWidget extends ConsumerWidget {
  final String vendorId;
  final bool showAll;

  const VendorPromotionsWidget({
    super.key,
    required this.vendorId,
    this.showAll = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promotionsAsync = ref.watch(vendorPromotionsProvider(vendorId));

    return promotionsAsync.when(
      data: (promotions) => _buildPromotionsList(context, promotions),
      loading: () => const LoadingWidget(message: 'Loading promotions...'),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Failed to load promotions'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(vendorPromotionsProvider(vendorId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionsList(BuildContext context, List<VendorPromotion> promotions) {
    if (promotions.isEmpty) {
      return _buildEmptyPromotions(context);
    }

    final displayPromotions = showAll ? promotions : promotions.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Offers',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        ...displayPromotions.map((promotion) => _buildPromotionCard(context, promotion)),
        
        if (!showAll && promotions.length > 2) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => _showAllPromotions(context),
              child: Text('View all ${promotions.length} offers'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPromotionCard(BuildContext context, VendorPromotion promotion) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              theme.primaryColor.withValues(alpha: 0.1),
              theme.primaryColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Promotion header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getPromotionTypeText(promotion.type),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (promotion.promoCode != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.primaryColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        promotion.promoCode!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Promotion title
              Text(
                promotion.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Promotion description
              Text(
                promotion.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Promotion details
              Row(
                children: [
                  if (promotion.discountPercentage != null) ...[
                    Icon(Icons.percent, size: 16, color: Colors.green[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${promotion.discountPercentage!.toStringAsFixed(0)}% OFF',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.green[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else if (promotion.discountAmount != null) ...[
                    Icon(Icons.money_off, size: 16, color: Colors.green[600]),
                    const SizedBox(width: 4),
                    Text(
                      'RM${promotion.discountAmount!.toStringAsFixed(2)} OFF',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.green[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  
                  const Spacer(),
                  
                  // Expiry date
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Until ${_formatDate(promotion.endDate)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Minimum order requirement
              if (promotion.minimumOrderAmount != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Text(
                    'Min. order: RM${promotion.minimumOrderAmount!.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
              
              // Usage limit
              if (promotion.usageLimit != null) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (promotion.usedCount ?? 0) / promotion.usageLimit!,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                ),
                const SizedBox(height: 4),
                Text(
                  '${promotion.usedCount ?? 0}/${promotion.usageLimit} used',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPromotions(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No active promotions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for special offers',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAllPromotions(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AllPromotionsScreen(vendorId: vendorId),
      ),
    );
  }

  String _getPromotionTypeText(PromotionType type) {
    switch (type) {
      case PromotionType.percentageDiscount:
        return 'DISCOUNT';
      case PromotionType.fixedDiscount:
        return 'DISCOUNT';
      case PromotionType.freeDelivery:
        return 'FREE DELIVERY';
      case PromotionType.buyOneGetOne:
        return 'BOGO';
      case PromotionType.minimumOrderDiscount:
        return 'MIN ORDER';
      case PromotionType.categoryDiscount:
        return 'CATEGORY';
      case PromotionType.itemDiscount:
        return 'ITEM DEAL';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'tomorrow';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class AllPromotionsScreen extends StatelessWidget {
  final String vendorId;

  const AllPromotionsScreen({
    super.key,
    required this.vendorId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Promotions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: VendorPromotionsWidget(
          vendorId: vendorId,
          showAll: true,
        ),
      ),
    );
  }
}
