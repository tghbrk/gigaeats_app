import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/customer.dart';
import '../../providers/customer_provider.dart';

import '../../../core/utils/responsive_utils.dart';

class CustomerDetailsScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailsScreen({
    super.key,
    required this.customerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerByIdProvider(customerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              // Navigate to edit screen and wait for result
              await context.push('/sales-agent/customers/$customerId/edit');

              // Refresh customer data when returning from edit screen
              debugPrint('🔧 CustomerDetailsScreen: Returned from edit, refreshing data');
              ref.invalidate(customerByIdProvider(customerId));
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  _showDeleteDialog(context, ref);
                  break;
                case 'add_note':
                  _showAddNoteDialog(context, ref);
                  break;
                case 'add_tag':
                  _showAddTagDialog(context, ref);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_note',
                child: ListTile(
                  leading: Icon(Icons.note_add),
                  title: Text('Add Note'),
                ),
              ),
              const PopupMenuItem(
                value: 'add_tag',
                child: ListTile(
                  leading: Icon(Icons.label),
                  title: Text('Add Tag'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete Customer', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),
      body: customerAsync.when(
        data: (customer) => customer != null
            ? _buildCustomerDetails(context, customer, ref)
            : _buildNotFound(context),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(context, error.toString(), ref),
      ),
    );
  }

  Widget _buildCustomerDetails(BuildContext context, Customer customer, WidgetRef ref) {
    return ResponsiveContainer(
      child: SingleChildScrollView(
        padding: context.responsivePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Header
            _buildCustomerHeader(context, customer),
            const SizedBox(height: 24),

            // Customer Information Cards
            if (context.isDesktop)
              _buildDesktopLayout(context, customer, ref)
            else
              _buildMobileLayout(context, customer, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerHeader(BuildContext context, Customer customer) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                customer.organizationName.isNotEmpty
                    ? customer.organizationName[0].toUpperCase()
                    : 'C',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.organizationName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    customer.contactPersonName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _getTypeIcon(customer.type),
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        customer.type.displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: customer.isActive
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          customer.isActive ? 'Active' : 'Inactive',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: customer.isActive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, Customer customer, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildContactInfoCard(context, customer),
              const SizedBox(height: 16),
              _buildAddressCard(context, customer),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildStatsCard(context, customer),
              const SizedBox(height: 16),
              _buildTagsCard(context, customer, ref),
              if (customer.notes != null) ...[
                const SizedBox(height: 16),
                _buildNotesCard(context, customer),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, Customer customer, WidgetRef ref) {
    return Column(
      children: [
        _buildContactInfoCard(context, customer),
        const SizedBox(height: 16),
        _buildAddressCard(context, customer),
        const SizedBox(height: 16),
        _buildStatsCard(context, customer),
        const SizedBox(height: 16),
        _buildTagsCard(context, customer, ref),
        if (customer.notes != null) ...[
          const SizedBox(height: 16),
          _buildNotesCard(context, customer),
        ],
      ],
    );
  }

  Widget _buildContactInfoCard(BuildContext context, Customer customer) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email, 'Email', customer.email),
            _buildInfoRow(Icons.phone, 'Phone', customer.phoneNumber),
            if (customer.alternatePhoneNumber != null)
              _buildInfoRow(Icons.phone_android, 'Alternate Phone', customer.alternatePhoneNumber!),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, Customer customer) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Address',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.location_on, 'Address', customer.address.fullAddress),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, Customer customer) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Total Orders', customer.totalOrders.toString()),
            _buildStatRow('Total Spent', 'RM ${customer.totalSpent.toStringAsFixed(2)}'),
            _buildStatRow('Average Order', 'RM ${customer.averageOrderValue.toStringAsFixed(2)}'),
            _buildStatRow('Last Order', customer.lastOrderDate != null ? _formatDate(customer.lastOrderDate!) : 'No orders yet'),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsCard(BuildContext context, Customer customer, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tags',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (customer.tags.isEmpty)
              Text(
                'No tags added',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: customer.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeTag(context, ref, tag),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(BuildContext context, Customer customer) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              customer.notes ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Customer not found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading customer',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Trigger a refresh by invalidating the provider
                ref.invalidate(customerByIdProvider(customerId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(CustomerType type) {
    switch (type) {
      case CustomerType.corporate:
        return Icons.business;
      case CustomerType.school:
        return Icons.school;
      case CustomerType.hospital:
        return Icons.local_hospital;
      case CustomerType.government:
        return Icons.account_balance;
      case CustomerType.event:
        return Icons.event;
      case CustomerType.catering:
        return Icons.restaurant;
      case CustomerType.other:
        return Icons.business_center;
    }
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
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text('Are you sure you want to delete this customer? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();

              final success = await ref.read(customerProvider.notifier).deleteCustomer(customerId);
              if (success && context.mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Customer deleted successfully')),
                );
                context.pop(); // Go back to customers list
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter note...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final note = controller.text.trim();

              if (note.isNotEmpty) {
                navigator.pop();
                final success = await ref.read(customerProvider.notifier).addNote(customerId, note);
                if (success && context.mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Note added successfully')),
                  );
                  ref.invalidate(customerByIdProvider(customerId));
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddTagDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter tag...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final tag = controller.text.trim();

              if (tag.isNotEmpty) {
                navigator.pop();
                final success = await ref.read(customerProvider.notifier).addTag(customerId, tag);
                if (success && context.mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Tag added successfully')),
                  );
                  ref.invalidate(customerByIdProvider(customerId));
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeTag(BuildContext context, WidgetRef ref, String tag) async {
    final success = await ref.read(customerProvider.notifier).removeTag(customerId, tag);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tag removed successfully')),
      );
      ref.invalidate(customerByIdProvider(customerId));
    }
  }
}
