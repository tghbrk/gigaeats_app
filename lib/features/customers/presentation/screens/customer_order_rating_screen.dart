import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../orders/data/models/order.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../data/services/customer_rating_service.dart';

class CustomerOrderRatingScreen extends ConsumerStatefulWidget {
  final Order order;

  const CustomerOrderRatingScreen({
    super.key,
    required this.order,
  });

  @override
  ConsumerState<CustomerOrderRatingScreen> createState() => _CustomerOrderRatingScreenState();
}

class _CustomerOrderRatingScreenState extends ConsumerState<CustomerOrderRatingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reviewController = TextEditingController();
  
  int _overallRating = 0;
  int _foodQualityRating = 0;
  int _deliveryRating = 0;
  int _serviceRating = 0;
  bool _isSubmitting = false;
  bool _wouldRecommend = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Your Order'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: _isSubmitting
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Information Header
                    _buildOrderHeader(theme),
                    
                    const SizedBox(height: 32),

                    // Overall Rating
                    _buildRatingSection(
                      title: 'Overall Experience',
                      subtitle: 'How was your overall experience?',
                      rating: _overallRating,
                      onRatingChanged: (rating) => setState(() => _overallRating = rating),
                      theme: theme,
                    ),

                    const SizedBox(height: 24),

                    // Food Quality Rating
                    _buildRatingSection(
                      title: 'Food Quality',
                      subtitle: 'How was the quality of your food?',
                      rating: _foodQualityRating,
                      onRatingChanged: (rating) => setState(() => _foodQualityRating = rating),
                      theme: theme,
                    ),

                    const SizedBox(height: 24),

                    // Delivery Rating
                    _buildRatingSection(
                      title: 'Delivery Experience',
                      subtitle: 'How was the delivery service?',
                      rating: _deliveryRating,
                      onRatingChanged: (rating) => setState(() => _deliveryRating = rating),
                      theme: theme,
                    ),

                    const SizedBox(height: 24),

                    // Service Rating
                    _buildRatingSection(
                      title: 'Customer Service',
                      subtitle: 'How was the customer service?',
                      rating: _serviceRating,
                      onRatingChanged: (rating) => setState(() => _serviceRating = rating),
                      theme: theme,
                    ),

                    const SizedBox(height: 32),

                    // Would Recommend
                    _buildRecommendationSection(theme),

                    const SizedBox(height: 24),

                    // Written Review
                    _buildReviewSection(theme),

                    const SizedBox(height: 32),

                    // Submit Button
                    _buildSubmitButton(theme),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOrderHeader(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.restaurant,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.order.vendorName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order #${widget.order.orderNumber}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      Text(
                        '${widget.order.items.length} items • RM ${widget.order.totalAmount.toStringAsFixed(2)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection({
    required String title,
    required String subtitle,
    required int rating,
    required Function(int) onRatingChanged,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            return GestureDetector(
              onTap: () => onRatingChanged(starIndex),
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  starIndex <= rating ? Icons.star : Icons.star_border,
                  color: starIndex <= rating 
                      ? Colors.amber 
                      : theme.colorScheme.outline,
                  size: 32,
                ),
              ),
            );
          }),
        ),
        if (rating > 0) ...[
          const SizedBox(height: 8),
          Text(
            _getRatingText(rating),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecommendationSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Would you recommend this restaurant?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildRecommendationOption(
                    title: 'Yes, I would',
                    subtitle: 'Recommend to others',
                    icon: Icons.thumb_up,
                    isSelected: _wouldRecommend,
                    onTap: () => setState(() => _wouldRecommend = true),
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRecommendationOption(
                    title: 'No, I wouldn\'t',
                    subtitle: 'Not recommended',
                    icon: Icons.thumb_down,
                    isSelected: !_wouldRecommend,
                    onTap: () => setState(() => _wouldRecommend = false),
                    theme: theme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary 
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.outline,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Write a Review (Optional)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Share your experience to help other customers',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _reviewController,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Tell us about your experience...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    final canSubmit = _overallRating > 0;
    
    return CustomButton(
      text: 'Submit Rating',
      onPressed: canSubmit ? _submitRating : null,
      type: ButtonType.primary,
      isExpanded: true,
      icon: Icons.send,
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  void _submitRating() async {
    if (!_formKey.currentState!.validate() || _overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide at least an overall rating'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final ratingService = ref.read(customerRatingServiceProvider);
      
      await ratingService.submitOrderRating(
        orderId: widget.order.id,
        vendorId: widget.order.vendorId,
        overallRating: _overallRating,
        foodQualityRating: _foodQualityRating,
        deliveryRating: _deliveryRating,
        serviceRating: _serviceRating,
        wouldRecommend: _wouldRecommend,
        reviewText: _reviewController.text.trim().isNotEmpty 
            ? _reviewController.text.trim() 
            : null,
      );

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Thank You!'),
              ],
            ),
            content: const Text(
              'Your rating has been submitted successfully. Thank you for your feedback!',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  context.pop(); // Go back to order details
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
