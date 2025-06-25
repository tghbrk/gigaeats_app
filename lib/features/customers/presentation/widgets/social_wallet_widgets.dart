import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/social_wallet_provider.dart';
import '../../data/models/social_wallet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Enhanced error widget for Social Wallet operations
class SocialWalletErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  final String? context;
  final bool showDetails;

  const SocialWalletErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.context,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error ${this.context != null ? this.context! : 'occurred'}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getUserFriendlyMessage(error),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onRetry != null) ...[
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getUserFriendlyMessage(String error) {
    if (error.contains('Unauthorized') || error.contains('authentication')) {
      return 'Please sign in again to continue.';
    } else if (error.contains('Access denied') || error.contains('permission')) {
      return 'You don\'t have permission to perform this action.';
    } else if (error.contains('required') || error.contains('invalid')) {
      return 'Please check your input and try again.';
    } else if (error.contains('network') || error.contains('connection')) {
      return 'Please check your internet connection and try again.';
    } else if (error.contains('server') || error.contains('500')) {
      return 'Server error. Please try again later.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }
}

/// Groups overview card showing key metrics
class GroupsOverviewCard extends ConsumerWidget {
  const GroupsOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socialWalletState = ref.watch(socialWalletProvider);
    final groups = socialWalletState.groups;

    final totalGroups = groups.length;
    final activeGroups = groups.where((g) => g.isActive).length;
    final totalSpent = groups.fold(0.0, (sum, group) => sum + group.totalSpent);
    final totalTransactions = groups.fold(0, (sum, group) => sum + group.transactionCount);

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor.withValues(alpha: 0.1), AppTheme.primaryColor.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.groups,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Groups',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Collaborative spending overview',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Total Groups',
                    value: totalGroups.toString(),
                    subtitle: '$activeGroups active',
                    icon: Icons.group,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Total Spent',
                    value: 'RM ${totalSpent.toStringAsFixed(0)}',
                    subtitle: '$totalTransactions transactions',
                    icon: Icons.payments,
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

/// Active groups list widget
class ActiveGroupsList extends ConsumerWidget {
  const ActiveGroupsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socialWalletState = ref.watch(socialWalletProvider);
    final groups = socialWalletState.groups.where((g) => g.isActive).toList();

    if (groups.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.groups_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No Active Groups',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first payment group to start splitting expenses with friends and family.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Groups',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...groups.map((group) => _GroupCard(group: group)),
      ],
    );
  }
}

class _GroupCard extends ConsumerWidget {
  final PaymentGroup group;

  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToGroupDetails(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getGroupTypeColor(group.type).withValues(alpha: 0.1),
                    child: Icon(
                      _getGroupTypeIcon(group.type),
                      color: _getGroupTypeColor(group.type),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          group.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getGroupTypeColor(group.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      group.type.displayName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getGroupTypeColor(group.type),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${group.members.length} members',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.payments,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    group.formattedTotalSpent,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToGroupDetails(BuildContext context, WidgetRef ref) {
    ref.read(socialWalletProvider.notifier).selectGroup(group);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GroupDetailsScreen(group: group),
      ),
    );
  }

  Color _getGroupTypeColor(GroupType type) {
    switch (type) {
      case GroupType.family:
        return AppTheme.primaryColor;
      case GroupType.friends:
        return AppTheme.successColor;
      case GroupType.roommates:
        return AppTheme.infoColor;
      case GroupType.travel:
        return AppTheme.warningColor;
      case GroupType.project:
        return Colors.purple;
      case GroupType.other:
        return Colors.grey;
    }
  }

  IconData _getGroupTypeIcon(GroupType type) {
    switch (type) {
      case GroupType.family:
        return Icons.family_restroom;
      case GroupType.friends:
        return Icons.group;
      case GroupType.roommates:
        return Icons.home;
      case GroupType.travel:
        return Icons.flight;
      case GroupType.project:
        return Icons.work;
      case GroupType.other:
        return Icons.category;
    }
  }
}

/// Bills overview card
class BillsOverviewCard extends ConsumerWidget {
  const BillsOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socialWalletState = ref.watch(socialWalletProvider);
    final billSplits = socialWalletState.billSplits;

    final totalBills = billSplits.length;
    final pendingBills = billSplits.where((b) => b.status == BillSplitStatus.pending).length;
    final totalAmount = billSplits.fold(0.0, (sum, bill) => sum + bill.totalAmount);
    final settledAmount = billSplits.fold(0.0, (sum, bill) => sum + bill.totalSettled);

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [AppTheme.infoColor.withValues(alpha: 0.1), AppTheme.infoColor.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: AppTheme.infoColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bill Splits',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Shared expenses overview',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Total Bills',
                    value: totalBills.toString(),
                    subtitle: '$pendingBills pending',
                    icon: Icons.receipt,
                    color: AppTheme.infoColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Settlement Rate',
                    value: totalAmount > 0 ? '${((settledAmount / totalAmount) * 100).toStringAsFixed(0)}%' : '0%',
                    subtitle: 'RM ${settledAmount.toStringAsFixed(0)} settled',
                    icon: Icons.check_circle,
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Requests overview card
class RequestsOverviewCard extends ConsumerWidget {
  const RequestsOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socialWalletState = ref.watch(socialWalletProvider);
    final requests = socialWalletState.paymentRequests;

    final totalRequests = requests.length;
    final pendingRequests = requests.where((r) => r.status == PaymentRequestStatus.pending).length;
    final overdueRequests = requests.where((r) => r.isOverdue).length;
    final totalAmount = requests.fold(0.0, (sum, request) => sum + request.amount);

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [AppTheme.warningColor.withValues(alpha: 0.1), AppTheme.warningColor.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.request_page,
                  color: AppTheme.warningColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Requests',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Incoming and outgoing requests',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Total Requests',
                    value: totalRequests.toString(),
                    subtitle: '$pendingRequests pending',
                    icon: Icons.request_page,
                    color: AppTheme.warningColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Overdue',
                    value: overdueRequests.toString(),
                    subtitle: 'RM ${totalAmount.toStringAsFixed(0)} total',
                    icon: Icons.schedule,
                    color: AppTheme.errorColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder widgets for additional social wallet components
class RecentGroupActivity extends StatelessWidget {
  const RecentGroupActivity({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Recent Group Activity - Coming Soon'),
      ),
    );
  }
}

class RecentBillSplits extends StatelessWidget {
  const RecentBillSplits({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Recent Bill Splits - Coming Soon'),
      ),
    );
  }
}

class PendingSettlements extends StatelessWidget {
  const PendingSettlements({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Pending Settlements - Coming Soon'),
      ),
    );
  }
}

class IncomingPaymentRequests extends ConsumerWidget {
  const IncomingPaymentRequests({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.call_received,
                  color: AppTheme.successColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Incoming Requests',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _loadIncomingRequests(ref),
                  child: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRequestsList(context, ref, incoming: true),
          ],
        ),
      ),
    );
  }

  void _loadIncomingRequests(WidgetRef ref) {
    ref.read(socialWalletProvider.notifier).loadPaymentRequests(
      incoming: true,
      limit: 5,
    );
  }

  Widget _buildRequestsList(BuildContext context, WidgetRef ref, {required bool incoming}) {
    final socialWalletState = ref.watch(socialWalletProvider);

    if (socialWalletState.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (socialWalletState.errorMessage != null) {
      return SocialWalletErrorWidget(
        error: socialWalletState.errorMessage!,
        onRetry: () => _loadIncomingRequests(ref),
        context: 'loading incoming payment requests',
      );
    }

    final requests = socialWalletState.paymentRequests
        .where((request) => incoming
            ? request.toUserId == ref.read(authStateProvider).user?.id
            : request.fromUserId == ref.read(authStateProvider).user?.id)
        .take(5)
        .toList();

    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                incoming ? Icons.call_received : Icons.call_made,
                color: Colors.grey.shade400,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                incoming ? 'No incoming requests' : 'No outgoing requests',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                incoming
                    ? 'You have no pending payment requests'
                    : 'You haven\'t sent any payment requests',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: requests.map((request) => _buildRequestItem(context, request)).toList(),
    );
  }

  Widget _buildRequestItem(BuildContext context, PaymentRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: Icon(
              Icons.person,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (request.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    request.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'RM ${request.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusChip(context, request.status),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, PaymentRequestStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case PaymentRequestStatus.pending:
        backgroundColor = AppTheme.warningColor.withValues(alpha: 0.1);
        textColor = AppTheme.warningColor;
        text = 'Pending';
        break;
      case PaymentRequestStatus.accepted:
        backgroundColor = AppTheme.successColor.withValues(alpha: 0.1);
        textColor = AppTheme.successColor;
        text = 'Accepted';
        break;
      case PaymentRequestStatus.declined:
        backgroundColor = AppTheme.errorColor.withValues(alpha: 0.1);
        textColor = AppTheme.errorColor;
        text = 'Declined';
        break;
      case PaymentRequestStatus.cancelled:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade600;
        text = 'Cancelled';
        break;
      case PaymentRequestStatus.paid:
        backgroundColor = AppTheme.primaryColor.withValues(alpha: 0.1);
        textColor = AppTheme.primaryColor;
        text = 'Paid';
        break;
      case PaymentRequestStatus.expired:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade600;
        text = 'Expired';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class OutgoingPaymentRequests extends ConsumerWidget {
  const OutgoingPaymentRequests({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.call_made,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Outgoing Requests',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _loadOutgoingRequests(ref),
                  child: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRequestsList(context, ref, incoming: false),
          ],
        ),
      ),
    );
  }

  void _loadOutgoingRequests(WidgetRef ref) {
    ref.read(socialWalletProvider.notifier).loadPaymentRequests(
      incoming: false,
      limit: 5,
    );
  }

  Widget _buildRequestsList(BuildContext context, WidgetRef ref, {required bool incoming}) {
    final socialWalletState = ref.watch(socialWalletProvider);

    if (socialWalletState.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (socialWalletState.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                color: AppTheme.errorColor,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'Error loading requests',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                socialWalletState.errorMessage!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _loadOutgoingRequests(ref),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final requests = socialWalletState.paymentRequests
        .where((request) => incoming
            ? request.toUserId == ref.read(authStateProvider).user?.id
            : request.fromUserId == ref.read(authStateProvider).user?.id)
        .take(5)
        .toList();

    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                incoming ? Icons.call_received : Icons.call_made,
                color: Colors.grey.shade400,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                incoming ? 'No incoming requests' : 'No outgoing requests',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                incoming
                    ? 'You have no pending payment requests'
                    : 'You haven\'t sent any payment requests',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: requests.map((request) => _buildRequestItem(context, request)).toList(),
    );
  }

  Widget _buildRequestItem(BuildContext context, PaymentRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: Icon(
              Icons.person,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (request.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    request.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'RM ${request.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusChip(context, request.status),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, PaymentRequestStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case PaymentRequestStatus.pending:
        backgroundColor = AppTheme.warningColor.withValues(alpha: 0.1);
        textColor = AppTheme.warningColor;
        text = 'Pending';
        break;
      case PaymentRequestStatus.accepted:
        backgroundColor = AppTheme.successColor.withValues(alpha: 0.1);
        textColor = AppTheme.successColor;
        text = 'Accepted';
        break;
      case PaymentRequestStatus.declined:
        backgroundColor = AppTheme.errorColor.withValues(alpha: 0.1);
        textColor = AppTheme.errorColor;
        text = 'Declined';
        break;
      case PaymentRequestStatus.cancelled:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade600;
        text = 'Cancelled';
        break;
      case PaymentRequestStatus.paid:
        backgroundColor = AppTheme.primaryColor.withValues(alpha: 0.1);
        textColor = AppTheme.primaryColor;
        text = 'Paid';
        break;
      case PaymentRequestStatus.expired:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade600;
        text = 'Expired';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Placeholder screens for navigation
class GroupDetailsScreen extends StatelessWidget {
  final PaymentGroup group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Group Details - Coming Soon'),
      ),
    );
  }
}

class SplitBillScreen extends StatelessWidget {
  const SplitBillScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Bill'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Split Bill - Coming Soon'),
      ),
    );
  }
}

class SendPaymentRequestScreen extends StatelessWidget {
  const SendPaymentRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Payment Request'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Send Payment Request - Coming Soon'),
      ),
    );
  }
}

class SocialWalletSettingsScreen extends StatelessWidget {
  const SocialWalletSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Wallet Settings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Social Wallet Settings - Coming Soon'),
      ),
    );
  }
}
