import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/user_role.dart';
import '../../../../shared/widgets/auth_guard.dart';

import '../providers/driver_withdrawal_provider.dart';
import '../../data/models/driver_withdrawal_request.dart';

/// Screen for viewing detailed information about a withdrawal request
class DriverWithdrawalDetailScreen extends ConsumerStatefulWidget {
  final String withdrawalId;

  const DriverWithdrawalDetailScreen({
    super.key,
    required this.withdrawalId,
  });

  @override
  ConsumerState<DriverWithdrawalDetailScreen> createState() => _DriverWithdrawalDetailScreenState();
}

class _DriverWithdrawalDetailScreenState extends ConsumerState<DriverWithdrawalDetailScreen> {
  DriverWithdrawalRequest? _withdrawalRequest;

  @override
  void initState() {
    super.initState();
    _loadWithdrawalDetails();
  }

  void _loadWithdrawalDetails() {
    // Find the withdrawal request from the provider state
    final withdrawalState = ref.read(driverWithdrawalProvider);
    _withdrawalRequest = withdrawalState.withdrawalRequests
        ?.where((request) => request.id == widget.withdrawalId)
        .firstOrNull;

    if (_withdrawalRequest == null) {
      // If not found in current state, try to load it
      debugPrint('🔍 [WITHDRAWAL-DETAIL] Withdrawal request not found in state, loading...');
      // TODO: Implement individual withdrawal request loading
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthGuard(
      allowedRoles: const [UserRole.driver, UserRole.admin],
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: _buildAppBar(theme),
        body: _withdrawalRequest == null
            ? _buildWithdrawalNotFound(theme)
            : _buildWithdrawalDetails(theme, _withdrawalRequest!),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: const Text('Withdrawal Details'),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      actions: [
        if (_withdrawalRequest != null)
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value, _withdrawalRequest!),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Share Details'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'support',
                child: Row(
                  children: [
                    Icon(Icons.support_agent),
                    SizedBox(width: 8),
                    Text('Contact Support'),
                  ],
                ),
              ),
              if (_withdrawalRequest?.status == DriverWithdrawalStatus.pending)
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Cancel Request', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildWithdrawalNotFound(ThemeData theme) {
    return Center(
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
            'Withdrawal Not Found',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The withdrawal request could not be found.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalDetails(ThemeData theme, DriverWithdrawalRequest request) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status and amount header
          _buildHeaderCard(theme, request),
          
          const SizedBox(height: 16),
          
          // Request details
          _buildRequestDetailsCard(theme, request),
          
          const SizedBox(height: 16),
          
          // Destination details
          _buildDestinationDetailsCard(theme, request),
          
          const SizedBox(height: 16),
          
          // Processing timeline
          _buildProcessingTimelineCard(theme, request),
          
          if (request.failureReason != null) ...[
            const SizedBox(height: 16),
            _buildFailureReasonCard(theme, request),
          ],
          
          if (request.notes != null && request.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildNotesCard(theme, request),
          ],
          
          const SizedBox(height: 16),
          
          // Action buttons
          _buildActionButtons(theme, request),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme, DriverWithdrawalRequest request) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status badge
            _buildStatusBadge(theme, request.status),
            
            const SizedBox(height: 16),
            
            // Amount
            Text(
              'RM ${request.amount.toStringAsFixed(2)}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            
            if (request.processingFee > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Processing Fee: RM ${request.processingFee.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Net Amount: RM ${request.netAmount.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Request ID
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'ID: ${request.id}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, DriverWithdrawalStatus status) {
    final statusInfo = _getStatusInfo(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusInfo['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusInfo['color'].withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusInfo['icon'],
            size: 16,
            color: statusInfo['color'],
          ),
          const SizedBox(width: 6),
          Text(
            statusInfo['label'],
            style: theme.textTheme.labelMedium?.copyWith(
              color: statusInfo['color'],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestDetailsCard(ThemeData theme, DriverWithdrawalRequest request) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildDetailRow(theme, 'Method', _getMethodDisplayName(request.withdrawalMethod)),
            _buildDetailRow(theme, 'Requested', _formatDateTime(request.requestedAt)),
            
            if (request.transactionReference != null)
              _buildDetailRow(theme, 'Reference', request.transactionReference!),
            
            if (request.processedBy != null)
              _buildDetailRow(theme, 'Processed By', request.processedBy!),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationDetailsCard(ThemeData theme, DriverWithdrawalRequest request) {
    if (request.destinationDetails.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Destination Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            ...request.destinationDetails.entries.map((entry) {
              return _buildDetailRow(
                theme,
                _formatDestinationKey(entry.key),
                entry.value.toString(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingTimelineCard(ThemeData theme, DriverWithdrawalRequest request) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Processing Timeline',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildTimelineItem(
              theme,
              'Request Submitted',
              request.requestedAt,
              true,
              Icons.send,
            ),
            
            if (request.processedAt != null)
              _buildTimelineItem(
                theme,
                'Processing Started',
                request.processedAt!,
                true,
                Icons.sync,
              ),
            
            if (request.completedAt != null)
              _buildTimelineItem(
                theme,
                'Transfer Completed',
                request.completedAt!,
                true,
                Icons.check_circle,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    ThemeData theme,
    String title,
    DateTime date,
    bool completed,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: completed 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: completed 
                  ? Colors.white 
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: completed 
                        ? theme.colorScheme.onSurface 
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  _formatDateTime(date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureReasonCard(ThemeData theme, DriverWithdrawalRequest request) {
    return Card(
      elevation: 1,
      color: Colors.red.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Failure Reason',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              request.failureReason!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(ThemeData theme, DriverWithdrawalRequest request) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              request.notes!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, DriverWithdrawalRequest request) {
    return Column(
      children: [
        if (request.status == DriverWithdrawalStatus.pending) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _cancelWithdrawal(request),
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel Request'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _contactSupport(request),
            icon: const Icon(Icons.support_agent),
            label: const Text('Contact Support'),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(DriverWithdrawalStatus status) {
    switch (status) {
      case DriverWithdrawalStatus.pending:
        return {'label': 'Pending', 'icon': Icons.schedule, 'color': Colors.orange};
      case DriverWithdrawalStatus.processing:
        return {'label': 'Processing', 'icon': Icons.sync, 'color': Colors.blue};
      case DriverWithdrawalStatus.completed:
        return {'label': 'Completed', 'icon': Icons.check_circle, 'color': Colors.green};
      case DriverWithdrawalStatus.failed:
        return {'label': 'Failed', 'icon': Icons.error, 'color': Colors.red};
      case DriverWithdrawalStatus.cancelled:
        return {'label': 'Cancelled', 'icon': Icons.cancel, 'color': Colors.grey};
    }
  }

  String _getMethodDisplayName(String method) {
    switch (method.toLowerCase()) {
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'e_wallet':
        return 'E-Wallet';
      case 'cash_pickup':
        return 'Cash Pickup';
      default:
        return method.replaceAll('_', ' ').split(' ').map((word) => 
          word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word
        ).join(' ');
    }
  }

  String _formatDestinationKey(String key) {
    return key.replaceAll('_', ' ').split(' ').map((word) => 
      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word
    ).join(' ');
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy \'at\' HH:mm').format(date);
  }

  void _handleMenuAction(BuildContext context, String action, DriverWithdrawalRequest request) {
    switch (action) {
      case 'share':
        _shareWithdrawalDetails(request);
        break;
      case 'support':
        _contactSupport(request);
        break;
      case 'cancel':
        _cancelWithdrawal(request);
        break;
    }
  }

  void _shareWithdrawalDetails(DriverWithdrawalRequest request) {
    // TODO: Implement sharing functionality
    debugPrint('📤 [WITHDRAWAL-DETAIL] Share withdrawal details: ${request.id}');
  }

  void _contactSupport(DriverWithdrawalRequest request) {
    // TODO: Implement support contact functionality
    debugPrint('📞 [WITHDRAWAL-DETAIL] Contact support for withdrawal: ${request.id}');
  }

  void _cancelWithdrawal(DriverWithdrawalRequest request) {
    // TODO: Implement withdrawal cancellation
    debugPrint('❌ [WITHDRAWAL-DETAIL] Cancel withdrawal: ${request.id}');
  }
}
