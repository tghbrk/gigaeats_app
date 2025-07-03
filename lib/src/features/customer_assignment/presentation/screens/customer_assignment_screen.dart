import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../data/models/assignment_request.dart';
import '../providers/assignment_provider.dart';

/// Screen for customers to view and respond to assignment requests
class CustomerAssignmentScreen extends ConsumerStatefulWidget {
  const CustomerAssignmentScreen({super.key});

  @override
  ConsumerState<CustomerAssignmentScreen> createState() => _CustomerAssignmentScreenState();
}

class _CustomerAssignmentScreenState extends ConsumerState<CustomerAssignmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _responseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load customer assignment requests
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assignmentProvider.notifier).loadCustomerRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _respondToRequest(AssignmentRequest request, String response) async {
    final success = await ref.read(assignmentProvider.notifier).respondToAssignmentRequest(
      requestId: request.id,
      response: response,
      message: _responseController.text.trim().isEmpty ? null : _responseController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response == 'approve' 
                  ? 'Assignment request approved successfully!'
                  : 'Assignment request rejected',
            ),
            backgroundColor: response == 'approve' ? Colors.green : Colors.orange,
          ),
        );
        _responseController.clear();
        Navigator.of(context).pop(); // Close dialog
      } else {
        final errorMessage = ref.read(assignmentProvider).errorMessage ?? 'Failed to respond to request';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showResponseDialog(AssignmentRequest request, String response) {
    _responseController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(response == 'approve' ? 'Approve Assignment' : 'Reject Assignment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              response == 'approve'
                  ? 'Are you sure you want to approve this assignment request from ${request.salesAgentName}?'
                  : 'Are you sure you want to reject this assignment request from ${request.salesAgentName}?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _responseController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: response == 'approve' ? 'Message (Optional)' : 'Reason (Optional)',
                hintText: response == 'approve'
                    ? 'Add a message for your new sales agent...'
                    : 'Let them know why you\'re rejecting...',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _respondToRequest(request, response),
            style: ElevatedButton.styleFrom(
              backgroundColor: response == 'approve' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(response == 'approve' ? 'Approve' : 'Reject'),
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
        title: const Text('Assignment Requests'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
          indicatorColor: theme.colorScheme.onPrimary,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'History'),
            Tab(text: 'Current'),
          ],
        ),
      ),
      body: assignmentState.isLoading
          ? const LoadingWidget(message: 'Loading assignment requests...')
          : assignmentState.errorMessage != null
              ? CustomErrorWidget(
                  message: assignmentState.errorMessage!,
                  onRetry: () => ref.read(assignmentProvider.notifier).loadCustomerRequests(),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(assignmentProvider.notifier).loadCustomerRequests(),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPendingRequests(),
                      _buildRequestHistory(),
                      _buildCurrentAssignment(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPendingRequests() {
    final pendingRequests = ref.watch(assignmentProvider)
        .requests
        .where((request) => request.status.isPending && !request.isExpiredNow)
        .toList();

    if (pendingRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No pending assignment requests',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Sales agents can send you assignment requests',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
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
              'No assignment history',
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

  Widget _buildCurrentAssignment() {
    // TODO: Implement current assignment view
    // This would show the currently assigned sales agent details
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Current Assignment',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Your current sales agent assignment will appear here',
            style: TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
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
            // Header with sales agent info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  child: Text(
                    request.salesAgentName?.substring(0, 1).toUpperCase() ?? 'S',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.salesAgentName ?? 'Sales Agent',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (request.salesAgentEmail != null)
                        Text(
                          request.salesAgentEmail!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                _buildStatusChip(request.status, request.priority),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Request message
            if (request.message != null && request.message!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.message!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Request details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.schedule,
                    label: 'Requested',
                    value: _formatDate(request.createdAt),
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.timer,
                    label: 'Expires',
                    value: request.formattedExpiryTime,
                    isWarning: request.expiresSoon,
                  ),
                ),
              ],
            ),
            
            // Customer response (if any)
            if (request.customerResponse != null && request.customerResponse!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: request.status.isApproved 
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: request.status.isApproved ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Response:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: request.status.isApproved ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.customerResponse!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
            
            // Action buttons for pending requests
            if (showActions && request.status.isPending && !request.isExpiredNow) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showResponseDialog(request, 'reject'),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showResponseDialog(request, 'approve'),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(AssignmentRequestStatus status, AssignmentRequestPriority priority) {
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
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (priority != AssignmentRequestPriority.normal) ...[
            const SizedBox(width: 4),
            Icon(
              priority == AssignmentRequestPriority.urgent
                  ? Icons.priority_high
                  : priority == AssignmentRequestPriority.high
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
              size: 12,
              color: textColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    bool isWarning = false,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isWarning ? Colors.orange : Colors.grey[600],
        ),
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
                  color: isWarning ? Colors.orange : null,
                ),
              ),
            ],
          ),
        ),
      ],
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
