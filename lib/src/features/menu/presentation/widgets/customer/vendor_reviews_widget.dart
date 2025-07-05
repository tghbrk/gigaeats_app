import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/customer/vendor_details_provider.dart';
import '../../../data/models/customer/vendor_review.dart';
import '../../../../../shared/widgets/loading_widget.dart';

class VendorReviewsWidget extends ConsumerWidget {
  final String vendorId;
  final bool showAll;

  const VendorReviewsWidget({
    super.key,
    required this.vendorId,
    this.showAll = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(vendorReviewsProvider(vendorId));
    final statsAsync = ref.watch(vendorReviewStatsProvider(vendorId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reviews header with stats
        statsAsync.when(
          data: (stats) => _buildReviewsHeader(context, stats),
          loading: () => const SizedBox(height: 60, child: LoadingWidget()),
          error: (error, stack) => const SizedBox(),
        ),
        
        const SizedBox(height: 16),
        
        // Reviews list
        reviewsAsync.when(
          data: (reviews) => _buildReviewsList(context, reviews),
          loading: () => const LoadingWidget(message: 'Loading reviews...'),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Failed to load reviews'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(vendorReviewsProvider(vendorId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsHeader(BuildContext context, VendorReviewStats stats) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber[600], size: 24),
              const SizedBox(width: 8),
              Text(
                stats.averageRating.toStringAsFixed(1),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${stats.totalReviews} reviews)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Rating distribution
          ...List.generate(5, (index) {
            final rating = 5 - index;
            final count = stats.ratingDistribution[rating] ?? 0;
            final percentage = stats.totalReviews > 0 ? count / stats.totalReviews : 0.0;
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text(
                    '$rating',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.star, size: 12, color: Colors.amber[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[600]!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '$count',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReviewsList(BuildContext context, List<VendorReview> reviews) {
    if (reviews.isEmpty) {
      return _buildEmptyReviews(context);
    }

    final displayReviews = showAll ? reviews : reviews.take(3).toList();

    return Column(
      children: [
        ...displayReviews.map((review) => _buildReviewCard(context, review)),
        
        if (!showAll && reviews.length > 3) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => _showAllReviews(context),
              child: Text('View all ${reviews.length} reviews'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewCard(BuildContext context, VendorReview review) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reviewer info and rating
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    review.customer?.name.substring(0, 1).toUpperCase() ?? 'A',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.customer?.name ?? 'Anonymous',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatDate(review.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Rating stars
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating ? Icons.star : Icons.star_border,
                      size: 16,
                      color: Colors.amber[600],
                    );
                  }),
                ),
              ],
            ),
            
            // Review text
            if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                review.reviewText!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            
            // Review images
            if (review.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(review.imageUrls[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            
            // Vendor response
            if (review.vendorResponse != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.store, size: 16, color: theme.primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          'Restaurant Response',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.primaryColor,
                          ),
                        ),
                        const Spacer(),
                        if (review.vendorResponseDate != null)
                          Text(
                            _formatDate(review.vendorResponseDate!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      review.vendorResponse!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyReviews(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No reviews yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to review this restaurant',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAllReviews(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AllReviewsScreen(vendorId: vendorId),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class AllReviewsScreen extends StatelessWidget {
  final String vendorId;

  const AllReviewsScreen({
    super.key,
    required this.vendorId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Reviews'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: VendorReviewsWidget(
          vendorId: vendorId,
          showAll: true,
        ),
      ),
    );
  }
}
