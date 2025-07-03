import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/loading_widget.dart';
import '../../../../../shared/widgets/custom_error_widget.dart';
// TODO: Restore when customer payment providers and widgets are implemented
// import '../../../../customers/presentation/providers/customer_payment_methods_provider.dart';
// import '../../../../customers/presentation/widgets/customer_payment_method_card.dart';
// import '../../../../customers/presentation/widgets/add_payment_method_dialog.dart';
// import '../../../../customers/data/models/customer_payment_method.dart';

/// Screen for managing customer payment methods
class CustomerPaymentMethodsScreen extends ConsumerStatefulWidget {
  const CustomerPaymentMethodsScreen({super.key});

  @override
  ConsumerState<CustomerPaymentMethodsScreen> createState() =>
      _CustomerPaymentMethodsScreenState();
}

class _CustomerPaymentMethodsScreenState
    extends ConsumerState<CustomerPaymentMethodsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // TODO: Restore when customerPaymentMethodsProvider is implemented
    // final paymentMethodsAsync = ref.watch(customerPaymentMethodsProvider);
    final paymentMethodsAsync = null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshPaymentMethods(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPaymentMethods,
        child: paymentMethodsAsync.when(
          data: (paymentMethods) => _buildPaymentMethodsList(paymentMethods),
          loading: () => const LoadingWidget(),
          error: (error, stack) => CustomErrorWidget(
            message: 'Failed to load payment methods',
            onRetry: _refreshPaymentMethods,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _showAddPaymentMethodDialog,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Payment Method'),
      ),
    );
  }

  Widget _buildPaymentMethodsList(List paymentMethods) {
    if (paymentMethods.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: paymentMethods.length,
      itemBuilder: (context, index) {
        final paymentMethod = paymentMethods[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          // TODO: Restore when CustomerPaymentMethodCard is implemented
          // child: CustomerPaymentMethodCard(
          child: Card( // Placeholder card
            child: ListTile(
              title: Text('Payment Method ${index + 1}'),
              subtitle: Text('Payment method details coming soon'),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('Edit'),
                    onTap: () => _editPaymentMethod(paymentMethod),
                  ),
                  PopupMenuItem(
                    child: const Text('Delete'),
                    onTap: () => _deletePaymentMethod(paymentMethod),
                  ),
                  PopupMenuItem(
                    child: const Text('Set Default'),
                    onTap: () => _setDefaultPaymentMethod(paymentMethod),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Payment Methods',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add a payment method to make purchases easier and faster.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAddPaymentMethodDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Payment Method'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshPaymentMethods() async {
    // TODO: Restore when customerPaymentMethodsProvider is implemented
    // await ref.read(customerPaymentMethodsProvider.notifier).refresh();
  }

  void _showAddPaymentMethodDialog() {
    showDialog(
      context: context,
      // TODO: Restore when AddPaymentMethodDialog is implemented
      // builder: (context) => AddPaymentMethodDialog(
      builder: (context) => AlertDialog( // Placeholder dialog
        title: const Text('Add Payment Method'),
        content: const Text('Add payment method feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // TODO: Restore when CustomerPaymentMethod is implemented
  void _editPaymentMethod(dynamic paymentMethod) {
    showDialog(
      context: context,
      builder: (context) => _EditPaymentMethodDialog(
        paymentMethod: paymentMethod,
        onUpdate: (nickname) async {
          setState(() => _isLoading = true);
          try {
            // TODO: Restore when customerPaymentMethodsProvider is implemented
            // await ref.read(customerPaymentMethodsProvider.notifier).updatePaymentMethod(
            //       paymentMethodId: paymentMethod.id,
            //       nickname: nickname,
            //     );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment method updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update payment method: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } finally {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          }
        },
      ),
    );
  }

  // TODO: Restore when CustomerPaymentMethod is implemented
  void _deletePaymentMethod(dynamic paymentMethod) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: Text(
          'Are you sure you want to delete ${paymentMethod.displayName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() => _isLoading = true);
              try {
                // TODO: Restore when customerPaymentMethodsProvider is implemented
                // await ref.read(customerPaymentMethodsProvider.notifier).deletePaymentMethod(
                //       paymentMethod.id,
                //     );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment method deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete payment method: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // TODO: Restore when CustomerPaymentMethod is implemented
  Future<void> _setDefaultPaymentMethod(dynamic paymentMethod) async {
    if (paymentMethod.isDefault) return;

    setState(() => _isLoading = true);
    try {
      // TODO: Restore when customerPaymentMethodsProvider is implemented
      // await ref.read(customerPaymentMethodsProvider.notifier).setDefaultPaymentMethod(
      //       paymentMethod.id,
      //     );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default payment method updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set default payment method: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// Dialog for editing payment method nickname
class _EditPaymentMethodDialog extends StatefulWidget {
  final dynamic paymentMethod;
  final Function(String?) onUpdate;

  const _EditPaymentMethodDialog({
    required this.paymentMethod,
    required this.onUpdate,
  });

  @override
  State<_EditPaymentMethodDialog> createState() => _EditPaymentMethodDialogState();
}

class _EditPaymentMethodDialogState extends State<_EditPaymentMethodDialog> {
  late final TextEditingController _nicknameController;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.paymentMethod.nickname);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Payment Method'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.paymentMethod.displayName,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nicknameController,
            decoration: const InputDecoration(
              labelText: 'Nickname (optional)',
              hintText: 'e.g., Primary Card, Work Card',
              border: OutlineInputBorder(),
            ),
            maxLength: 50,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onUpdate(_nicknameController.text.trim().isEmpty 
                ? null 
                : _nicknameController.text.trim());
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}
