import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/customer_payment_methods_provider.dart';
import '../../data/models/customer_payment_method.dart';
import '../widgets/payment_method_card.dart';
import '../widgets/payment_method_empty_state.dart';

/// Screen for managing customer payment methods
class CustomerPaymentMethodsScreen extends ConsumerWidget {
  const CustomerPaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final paymentMethodsAsync = ref.watch(customerPaymentMethodsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/customer/payment-methods/add'),
            tooltip: 'Add Payment Method',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(customerPaymentMethodsProvider.notifier).refresh();
        },
        child: paymentMethodsAsync.when(
          data: (paymentMethods) => _buildPaymentMethodsList(
            context,
            ref,
            paymentMethods,
            theme,
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => _buildErrorState(
            context,
            ref,
            error.toString(),
            theme,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsList(
    BuildContext context,
    WidgetRef ref,
    List<CustomerPaymentMethod> paymentMethods,
    ThemeData theme,
  ) {
    if (paymentMethods.isEmpty) {
      return const PaymentMethodEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: paymentMethods.length,
      itemBuilder: (context, index) {
        final paymentMethod = paymentMethods[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PaymentMethodCard(
            paymentMethod: paymentMethod,
            onTap: () => _showPaymentMethodDetails(context, paymentMethod),
            onSetDefault: () => _setDefaultPaymentMethod(ref, paymentMethod),
            onDelete: () => _deletePaymentMethod(context, ref, paymentMethod),
            onEdit: () => _editPaymentMethod(context, paymentMethod),
          ),
        );
      },
    );
  }

  void _showPaymentMethodDetails(
    BuildContext context,
    CustomerPaymentMethod paymentMethod,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildPaymentMethodDetailsSheet(context, paymentMethod),
    );
  }

  Widget _buildPaymentMethodDetailsSheet(
    BuildContext context,
    CustomerPaymentMethod paymentMethod,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Title
          Text(
            'Payment Method Details',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Payment method info
          _buildDetailRow(
            'Type',
            _getPaymentMethodTypeDisplay(paymentMethod.type),
            theme,
          ),
          if (paymentMethod.cardBrand != null)
            _buildDetailRow(
              'Card Brand',
              _getCardBrandDisplay(paymentMethod.cardBrand!),
              theme,
            ),
          if (paymentMethod.cardLast4 != null)
            _buildDetailRow(
              'Card Number',
              '**** **** **** ${paymentMethod.cardLast4}',
              theme,
            ),
          if (paymentMethod.cardExpMonth != null && paymentMethod.cardExpYear != null)
            _buildDetailRow(
              'Expires',
              '${paymentMethod.cardExpMonth!.toString().padLeft(2, '0')}/${paymentMethod.cardExpYear}',
              theme,
            ),
          if (paymentMethod.nickname != null)
            _buildDetailRow(
              'Nickname',
              paymentMethod.nickname!,
              theme,
            ),
          _buildDetailRow(
            'Status',
            paymentMethod.isDefault ? 'Default Payment Method' : 'Available',
            theme,
            valueColor: paymentMethod.isDefault 
                ? theme.colorScheme.primary 
                : theme.colorScheme.onSurface,
          ),
          _buildDetailRow(
            'Added',
            _formatDate(paymentMethod.createdAt),
            theme,
          ),
          if (paymentMethod.lastUsedAt != null)
            _buildDetailRow(
              'Last Used',
              _formatDate(paymentMethod.lastUsedAt!),
              theme,
            ),

          const SizedBox(height: 32),
          
          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Close'),
            ),
          ),
          
          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    ThemeData theme, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: valueColor ?? theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setDefaultPaymentMethod(
    WidgetRef ref,
    CustomerPaymentMethod paymentMethod,
  ) async {
    if (paymentMethod.isDefault) return;

    try {
      await ref
          .read(customerPaymentMethodsProvider.notifier)
          .setDefaultPaymentMethod(paymentMethod.id);
    } catch (e) {
      // Error handling is done in the provider
    }
  }

  Future<void> _deletePaymentMethod(
    BuildContext context,
    WidgetRef ref,
    CustomerPaymentMethod paymentMethod,
  ) async {
    final confirmed = await _showDeleteConfirmationDialog(context, paymentMethod);
    if (!confirmed) return;

    try {
      await ref
          .read(customerPaymentMethodsProvider.notifier)
          .deletePaymentMethod(paymentMethod.id);
    } catch (e) {
      // Error handling is done in the provider
    }
  }

  Future<bool> _showDeleteConfirmationDialog(
    BuildContext context,
    CustomerPaymentMethod paymentMethod,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: Text(
          'Are you sure you want to delete this payment method?\n\n'
          '${_getPaymentMethodDisplayName(paymentMethod)}\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _editPaymentMethod(
    BuildContext context,
    CustomerPaymentMethod paymentMethod,
  ) {
    context.push('/customer/payment-methods/edit/${paymentMethod.id}');
  }

  String _getPaymentMethodTypeDisplay(CustomerPaymentMethodType type) {
    switch (type) {
      case CustomerPaymentMethodType.card:
        return 'Credit/Debit Card';
      case CustomerPaymentMethodType.bankAccount:
        return 'Bank Account';
      case CustomerPaymentMethodType.digitalWallet:
        return 'Digital Wallet';
    }
  }

  String _getCardBrandDisplay(CardBrand brand) {
    switch (brand) {
      case CardBrand.visa:
        return 'Visa';
      case CardBrand.mastercard:
        return 'Mastercard';
      case CardBrand.amex:
        return 'American Express';
      case CardBrand.discover:
        return 'Discover';
      case CardBrand.jcb:
        return 'JCB';
      case CardBrand.diners:
        return 'Diners Club';
      case CardBrand.unionpay:
        return 'UnionPay';
      case CardBrand.unknown:
        return 'Unknown';
    }
  }

  String _getPaymentMethodDisplayName(CustomerPaymentMethod paymentMethod) {
    if (paymentMethod.nickname != null && paymentMethod.nickname!.isNotEmpty) {
      return paymentMethod.nickname!;
    }

    if (paymentMethod.type == CustomerPaymentMethodType.card) {
      final brand = paymentMethod.cardBrand != null 
          ? _getCardBrandDisplay(paymentMethod.cardBrand!)
          : 'Card';
      final last4 = paymentMethod.cardLast4 ?? '****';
      return '$brand ending in $last4';
    }

    return _getPaymentMethodTypeDisplay(paymentMethod.type);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    String errorMessage,
    ThemeData theme,
  ) {
    // Check if it's a function not found error (404)
    final isFunctionNotFound = errorMessage.contains('404') ||
                               errorMessage.contains('NOT_FOUND') ||
                               errorMessage.contains('function was not found');

    if (isFunctionNotFound) {
      // Show empty state instead of error for function not found
      // This provides a better user experience while the function is being deployed
      return const PaymentMethodEmptyState();
    }

    // For other errors, show a proper error message
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We\'re having trouble loading your payment methods. Please try again.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.refresh(customerPaymentMethodsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
