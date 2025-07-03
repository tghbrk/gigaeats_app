import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';

import '../../data/models/assignment_request.dart';
import '../../data/models/customer_assignment.dart';
import '../providers/assignment_provider.dart';

/// Screen for sales agents to manage their customer assignments
class SalesAgentAssignmentScreen extends ConsumerStatefulWidget {
  const SalesAgentAssignmentScreen({super.key});

  @override
  ConsumerState<SalesAgentAssignmentScreen> createState() => _SalesAgentAssignmentScreenState();
}

class _SalesAgentAssignmentScreenState extends ConsumerState<SalesAgentAssignmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load assignment data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assignmentProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cancelRequest(String requestId, String reason) async {
    final success = await ref.read(assignmentProvider.notifier).cancelAssignmentRequest(
      requestId: requestId,
      reason: reason,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment request cancelled successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        final errorMessage = ref.read(assignmentProvider).errorMessage ?? 'Failed to cancel request';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deactivateAssignment(String assignmentId, String reason) async {
    final success = await ref.read(assignmentProvider.notifier).deactivateAssignment(
      assignmentId: assignmentId,
      reason: reason,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment deactivated successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        final errorMessage = ref.read(assignmentProvider).errorMessage ?? 'Failed to deactivate assignment';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCancelDialog(AssignmentRequest request) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Assignment Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to cancel the assignment request to ${request.customerName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason (Optional)',
                hintText: 'Why are you cancelling this request?',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Request'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelRequest(request.id, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
  }

  void _showDeactivateDialog(CustomerAssignment assignment) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Assignment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to deactivate your assignment with ${assignment.customerName}?'),
            const SizedBox(height: 8),
            const Text(
              'This will remove you as their sales agent and stop commission tracking.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason (Required)',
                hintText: 'Why are you deactivating this assignment?',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Assignment'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason for deactivation'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.of(context).pop();
              _deactivateAssignment(assignment.id, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignmentState = ref.watch(assignmentProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Assignments'),
        backgroundColor: theme.colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/sales-agent/assignments/request'),
            tooltip: 'Request New Assignment',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
          indicatorColor: theme.colorScheme.onPrimary,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Pending'),
            Tab(text: 'History'),
            Tab(text: 'Stats'),
          ],
        ),
      ),
      body: assignmentState.isLoading
          ? const LoadingWidget(message: 'Loading assignments...')
          : assignmentState.errorMessage != null
              ? CustomErrorWidget(
                  message: assignmentState.errorMessage!,
                  onRetry: () => ref.read(assignmentProvider.notifier).refresh(),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(assignmentProvider.notifier).refresh(),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildActiveAssignments(),
                      _buildPendingRequests(),
                      _buildRequestHistory(),
                      _buildStatsView(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildActiveAssignments() {
    final activeAssignments = ref.watch(assignmentProvider).assignments;

    if (activeAssignments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No active assignments',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Send assignment requests to customers to start earning commissions',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeAssignments.length,
      itemBuilder: (context, index) {
        final assignment = activeAssignments[index];
        return _buildAssignmentCard(assignment);
      },
    );
  }

  Widget _buildPendingRequests() {
    final pendingRequests = ref.watch(assignmentProvider)
        .requests
        .where((request) => request.status.isPending)
        .toList();

    if (pendingRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No pending requests',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Your assignment requests will appear here',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingRequests.length,
      itemBuilder: (context, index) {
        final request = pendingRequests[index];
        return _buildRequestCard(request, showActions: true);
      },
    );
  }

  Widget _buildRequestHistory() {
    final historyRequests = ref.watch(assignmentProvider)
        .requests
        .where((request) => request.status.isCompleted)
        .toList();

    if (historyRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No request history',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: historyRequests.length,
      itemBuilder: (context, index) {
        final request = historyRequests[index];
        return _buildRequestCard(request, showActions: false);
      },
    );
  }

  Widget _buildStatsView() {
    final stats = ref.watch(assignmentProvider).stats;

    if (stats == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Loading statistics...',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCard('Assignment Overview', [
            _buildStatItem('Active Assignments', '${stats['total_active_assignments'] ?? 0}', Icons.people),
            _buildStatItem('Total Orders', '${stats['total_orders'] ?? 0}', Icons.shopping_cart),
            _buildStatItem('Total Commission', 'RM ${(stats['total_commission_earned'] ?? 0.0).toStringAsFixed(2)}', Icons.monetization_on),
          ]),
          const SizedBox(height: 16),
          _buildStatsCard('Request Statistics', [
            _buildStatItem('Pending Requests', '${stats['pending_requests'] ?? 0}', Icons.schedule),
            _buildStatItem('Approved Requests', '${stats['approved_requests'] ?? 0}', Icons.check_circle),
            _buildStatItem('Approval Rate', '${stats['approval_rate'] ?? 0}%', Icons.trending_up),
          ]),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(CustomerAssignment assignment) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  child: Text(
                    assignment.customerName?.substring(0, 1).toUpperCase() ?? 'C',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.customerName ?? 'Customer',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (assignment.customerOrganization != null)
                        Text(
                          assignment.customerOrganization!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'deactivate') {
                      _showDeactivateDialog(assignment);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'deactivate',
                      child: Row(
                        children: [
                          Icon(Icons.remove_circle_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Deactivate Assignment'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Performance metrics
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    icon: Icons.shopping_cart,
                    label: 'Orders',
                    value: '${assignment.totalOrders}',
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    icon: Icons.monetization_on,
                    label: 'Commission',
                    value: assignment.formattedTotalCommissionEarned,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    icon: Icons.schedule,
                    label: 'Duration',
                    value: assignment.formattedAssignmentDuration,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Additional info
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.percent,
                    label: 'Commission Rate',
                    value: assignment.formattedCommissionRate,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.access_time,
                    label: 'Last Order',
                    value: assignment.formattedLastOrderDate,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(AssignmentRequest request, {required bool showActions}) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  child: Text(
                    request.customerName?.substring(0, 1).toUpperCase() ?? 'C',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.customerName ?? 'Customer',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (request.customerOrganization != null)
                        Text(
                          request.customerOrganization!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                _buildStatusChip(request.status),
              ],
            ),

            const SizedBox(height: 12),

            // Request details
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.schedule,
                    label: 'Requested',
                    value: _formatDate(request.createdAt),
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.timer,
                    label: 'Expires',
                    value: request.formattedExpiryTime,
                  ),
                ),
              ],
            ),

            // Message
            if (request.message != null && request.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  request.message!,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],

            // Actions for pending requests
            if (showActions && request.status.isPending) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelDialog(request),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Request'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(String title, List<Widget> children) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(AssignmentRequestStatus status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case AssignmentRequestStatus.pending:
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        icon = Icons.schedule;
        break;
      case AssignmentRequestStatus.approved:
        backgroundColor = Colors.green;
        textColor = Colors.white;
        icon = Icons.check_circle;
        break;
      case AssignmentRequestStatus.rejected:
        backgroundColor = Colors.red;
        textColor = Colors.white;
        icon = Icons.cancel;
        break;
      case AssignmentRequestStatus.cancelled:
        backgroundColor = Colors.grey;
        textColor = Colors.white;
        icon = Icons.cancel_outlined;
        break;
      case AssignmentRequestStatus.expired:
        backgroundColor = Colors.grey[600]!;
        textColor = Colors.white;
        icon = Icons.timer_off;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
