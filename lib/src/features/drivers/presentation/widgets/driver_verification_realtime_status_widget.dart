import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/driver_document_verification_realtime_providers.dart';
import '../providers/driver_verification_notification_provider.dart';
import '../providers/driver_verification_status_monitor_provider.dart';
import '../../domain/models/driver_document_verification.dart';
import '../../../../core/utils/logger.dart';

/// Logger for real-time status widget
final _logger = AppLogger();

/// Real-time verification status widget with live updates
class DriverVerificationRealtimeStatusWidget extends ConsumerStatefulWidget {
  final String driverId;
  final String userId;
  final VoidCallback? onVerificationComplete;
  final VoidCallback? onVerificationFailed;

  const DriverVerificationRealtimeStatusWidget({
    super.key,
    required this.driverId,
    required this.userId,
    this.onVerificationComplete,
    this.onVerificationFailed,
  });

  @override
  ConsumerState<DriverVerificationRealtimeStatusWidget> createState() =>
      _DriverVerificationRealtimeStatusWidgetState();
}

class _DriverVerificationRealtimeStatusWidgetState
    extends ConsumerState<DriverVerificationRealtimeStatusWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    // Start status monitoring
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentDriverStatusMonitorProvider.notifier).startMonitoring();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 20),
            _buildVerificationStatus(),
            const SizedBox(height: 16),
            _buildDocumentsStatus(),
            const SizedBox(height: 16),
            _buildProgressIndicator(),
            const SizedBox(height: 16),
            _buildActionButtons(),
            const SizedBox(height: 12),
            _buildConnectionStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.verified_user,
          color: theme.colorScheme.primary,
          size: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Document Verification',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Real-time AI processing with Malaysian KYC compliance',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        _buildNotificationBadge(),
      ],
    );
  }

  Widget _buildNotificationBadge() {
    final unreadCount = ref.watch(unreadVerificationNotificationCountProvider);
    
    if (unreadCount == 0) return const SizedBox.shrink();
    
    return Badge(
      label: Text('$unreadCount'),
      child: IconButton(
        icon: const Icon(Icons.notifications),
        onPressed: () => _showNotifications(),
      ),
    );
  }

  Widget _buildVerificationStatus() {
    final verificationAsync = ref.watch(currentDriverVerificationStreamProvider);
    
    return verificationAsync.when(
      data: (verification) => _buildVerificationStatusContent(verification),
      loading: () => _buildLoadingStatus(),
      error: (error, stackTrace) => _buildErrorStatus(error),
    );
  }

  Widget _buildVerificationStatusContent(DriverDocumentVerification? verification) {
    final theme = Theme.of(context);
    
    if (verification == null) {
      return _buildNoVerificationStatus();
    }

    // Update progress animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _progressController.animateTo(verification.completionPercentage / 100);
    });

    // Handle status changes
    _handleStatusChange(verification);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor(verification.overallStatus).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(verification.overallStatus).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusIcon(verification.overallStatus),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verification.statusDisplayText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(verification.overallStatus),
                      ),
                    ),
                    Text(
                      _getStatusDescription(verification.overallStatus),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '${verification.completionPercentage.toInt()}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(verification.overallStatus),
                ),
              ),
            ],
          ),
          if (verification.overallStatus == VerificationStatus.processing) ...[
            const SizedBox(height: 12),
            _buildProcessingIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Loading verification status...'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorStatus(Object error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connection Error',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(
                  'Failed to load verification: $error',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(currentDriverVerificationStreamProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildNoVerificationStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.assignment, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          const Text(
            'No Verification Started',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start your document verification to access wallet features.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _startVerification(),
            child: const Text('Start Verification'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsStatus() {
    final verificationState = ref.watch(currentDriverDocumentVerificationProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documents (${verificationState.verifiedDocuments}/${verificationState.totalDocuments})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (verificationState.documents.isEmpty)
          const Text(
            'No documents uploaded yet',
            style: TextStyle(color: Colors.grey),
          )
        else
          ...verificationState.documents.map((doc) => _buildDocumentItem(doc)),
      ],
    );
  }

  Widget _buildDocumentItem(DriverVerificationDocument document) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          _buildDocumentStatusIcon(document.processingStatus),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.documentTypeDisplayName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (document.confidenceScore != null && document.confidenceScore! > 0)
                  Text(
                    'Confidence: ${document.confidenceScore}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
          if (document.isProcessing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Progress',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _progressAnimation.value,
              backgroundColor: Colors.grey.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons() {
    final verificationState = ref.watch(currentDriverDocumentVerificationProvider);
    
    return Row(
      children: [
        if (verificationState.verification == null)
          Expanded(
            child: ElevatedButton(
              onPressed: verificationState.isLoading ? null : () => _startVerification(),
              child: verificationState.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Start Verification'),
            ),
          )
        else ...[
          Expanded(
            child: OutlinedButton(
              onPressed: () => _refreshStatus(),
              child: const Text('Refresh'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: verificationState.isProcessing ? null : () => _processDocuments(),
              child: verificationState.isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Process'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConnectionStatus() {
    final monitorState = ref.watch(currentDriverStatusMonitorProvider);
    final isHealthy = ref.watch(monitoringHealthProvider);
    
    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isHealthy ? _pulseAnimation.value : 1.0,
              child: Icon(
                isHealthy ? Icons.wifi : Icons.wifi_off,
                size: 16,
                color: isHealthy ? Colors.green : Colors.red,
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        Text(
          isHealthy ? 'Connected' : 'Disconnected',
          style: TextStyle(
            fontSize: 12,
            color: isHealthy ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        if (monitorState.lastUpdate != null)
          Text(
            'Updated: ${_formatTime(monitorState.lastUpdate!)}',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
      ],
    );
  }

  // Helper methods and event handlers

  Widget _buildStatusIcon(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return const Icon(Icons.hourglass_empty, color: Colors.orange);
      case VerificationStatus.processing:
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: const Icon(Icons.autorenew, color: Colors.blue),
            );
          },
        );
      case VerificationStatus.verified:
        return const Icon(Icons.verified, color: Colors.green);
      case VerificationStatus.failed:
        return const Icon(Icons.error, color: Colors.red);
      case VerificationStatus.rejected:
        return const Icon(Icons.cancel, color: Colors.red);
      case VerificationStatus.manualReview:
        return const Icon(Icons.person_search, color: Colors.orange);
      case VerificationStatus.expired:
        return const Icon(Icons.schedule, color: Colors.red);
    }
  }

  Widget _buildDocumentStatusIcon(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return const Icon(Icons.upload_file, color: Colors.grey, size: 20);
      case VerificationStatus.processing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case VerificationStatus.verified:
        return const Icon(Icons.check_circle, color: Colors.green, size: 20);
      case VerificationStatus.failed:
        return const Icon(Icons.error, color: Colors.red, size: 20);
      case VerificationStatus.manualReview:
        return const Icon(Icons.person_search, color: Colors.orange, size: 20);
      case VerificationStatus.expired:
        return const Icon(Icons.schedule, color: Colors.red, size: 20);
      case VerificationStatus.rejected:
        return const Icon(Icons.block, color: Colors.red, size: 20);
    }
  }

  Widget _buildProcessingIndicator() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1 * _pulseAnimation.value),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue.withOpacity(_pulseAnimation.value),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'AI Processing...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.withOpacity(_pulseAnimation.value),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return Colors.orange;
      case VerificationStatus.processing:
        return Colors.blue;
      case VerificationStatus.verified:
        return Colors.green;
      case VerificationStatus.failed:
        return Colors.red;
      case VerificationStatus.manualReview:
        return Colors.orange;
      case VerificationStatus.expired:
        return Colors.red;
      case VerificationStatus.rejected:
        return Colors.red;
    }
  }

  String _getStatusDescription(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return 'Waiting for documents to be uploaded';
      case VerificationStatus.processing:
        return 'AI is analyzing your documents using Gemini 2.5 Flash Lite';
      case VerificationStatus.verified:
        return 'All documents verified successfully';
      case VerificationStatus.failed:
        return 'Some documents could not be verified';
      case VerificationStatus.manualReview:
        return 'Documents are being reviewed by our team';
      case VerificationStatus.expired:
        return 'Documents have expired and need to be renewed';
      case VerificationStatus.rejected:
        return 'Documents were rejected and need to be resubmitted';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _handleStatusChange(DriverDocumentVerification verification) {
    // Handle completion callbacks
    if (verification.isComplete && widget.onVerificationComplete != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onVerificationComplete!();
      });
    } else if (verification.hasFailed && widget.onVerificationFailed != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onVerificationFailed!();
      });
    }
  }

  Future<void> _startVerification() async {
    try {
      _logger.info('🚀 Starting verification from UI');

      await ref.read(currentDriverDocumentVerificationProvider.notifier)
          .createVerification();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification process started successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logger.error('❌ Failed to start verification', e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start verification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _refreshStatus() {
    _logger.info('🔄 Refreshing verification status');

    // Refresh the real-time stream
    ref.invalidate(currentDriverVerificationStreamProvider);

    // Refresh the verification state
    ref.read(currentDriverDocumentVerificationProvider.notifier).refresh();
  }

  Future<void> _processDocuments() async {
    try {
      _logger.info('⚙️ Processing documents from UI');

      await ref.read(currentDriverDocumentVerificationProvider.notifier)
          .verifyIdentity();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document processing started'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      _logger.error('❌ Failed to process documents', e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process documents: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Verification Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildNotificationsList(scrollController),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationsList(ScrollController scrollController) {
    final notifications = ref.watch(verificationNotificationProvider).notifications;

    if (notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              notification.icon ?? notification.defaultIcon,
              color: notification.color ?? notification.defaultColor,
            ),
            title: Text(
              notification.title,
              style: TextStyle(
                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.message),
                const SizedBox(height: 4),
                Text(
                  _formatTime(notification.timestamp),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            onTap: () {
              ref.read(verificationNotificationProvider.notifier)
                  .markAsRead(notification.id);
            },
          ),
        );
      },
    );
  }
}
