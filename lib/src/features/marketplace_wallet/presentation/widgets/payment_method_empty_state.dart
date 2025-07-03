import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Empty state widget for when user has no payment methods
class PaymentMethodEmptyState extends StatelessWidget {
  const PaymentMethodEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          
          // Illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.payment,
              size: 60,
              color: theme.colorScheme.primary,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Title
          Text(
            'No Payment Methods',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            'Add a payment method to make ordering faster and more convenient. Your payment information is securely stored and encrypted.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 40),
          
          // Benefits list
          _buildBenefitsList(theme),
          
          const SizedBox(height: 40),
          
          // Add payment method button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/customer/payment-methods/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add Payment Method'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Secondary action
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Maybe Later',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildBenefitsList(ThemeData theme) {
    final benefits = [
      {
        'icon': Icons.flash_on,
        'title': 'Faster Checkout',
        'description': 'Skip entering card details every time',
      },
      {
        'icon': Icons.security,
        'title': 'Secure & Safe',
        'description': 'Bank-level encryption protects your data',
      },
      {
        'icon': Icons.star,
        'title': 'Set Default',
        'description': 'Choose your preferred payment method',
      },
    ];

    return Column(
      children: benefits.map((benefit) => _buildBenefitItem(
        theme,
        benefit['icon'] as IconData,
        benefit['title'] as String,
        benefit['description'] as String,
      )).toList(),
    );
  }

  Widget _buildBenefitItem(
    ThemeData theme,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
