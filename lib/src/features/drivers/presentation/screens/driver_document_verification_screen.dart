import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/logger.dart';
import '../../domain/models/driver_document_verification.dart';
import '../widgets/document_verification/driver_document_upload_widget.dart';
import '../widgets/document_verification/driver_verification_progress_widget.dart';

/// Main screen for driver document verification with Material Design 3
class DriverDocumentVerificationScreen extends ConsumerStatefulWidget {
  final String driverId;
  final String userId;

  const DriverDocumentVerificationScreen({
    super.key,
    required this.driverId,
    required this.userId,
  });

  @override
  ConsumerState<DriverDocumentVerificationScreen> createState() =>
      _DriverDocumentVerificationScreenState();
}

class _DriverDocumentVerificationScreenState
    extends ConsumerState<DriverDocumentVerificationScreen>
    with TickerProviderStateMixin {
  final AppLogger _logger = AppLogger();
  late TabController _tabController;
  
  // Mock verification data (will be replaced with actual provider)
  late DriverDocumentVerification _mockVerification;
  final String _mockVerificationId = 'mock-verification-id';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeMockData();
    
    _logger.info('🚀 Driver document verification screen initialized');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeMockData() {
    _mockVerification = DriverDocumentVerification(
      id: _mockVerificationId,
      driverId: widget.driverId,
      userId: widget.userId,
      verificationType: 'wallet_kyc',
      overallStatus: VerificationStatus.pending,
      currentStep: 1,
      totalSteps: 3,
      completionPercentage: 0.0,
      verificationMethod: VerificationMethod.ocrAi,
      extractedData: {},
      verificationResults: {},
      failureReasons: [],
      kycComplianceStatus: 'pending',
      complianceChecks: {},
      auditTrail: {},
      retentionExpiresAt: DateTime.now().add(const Duration(days: 365 * 7)),
      metadata: {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(theme),
      body: Column(
        children: [
          _buildTabBar(theme),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVerificationTab(),
                _buildProgressTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back),
        style: IconButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurface,
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Document Verification',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            'Verify your identity for wallet access',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _showHelpDialog,
          icon: const Icon(Icons.help_outline),
          style: IconButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: theme.colorScheme.onPrimary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.upload_file),
            text: 'Upload Documents',
          ),
          Tab(
            icon: Icon(Icons.timeline),
            text: 'Progress',
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 20),
          _buildRequiredDocumentsSection(),
          const SizedBox(height: 20),
          _buildDocumentUploadSections(),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DriverVerificationProgressWidget(
            verification: _mockVerification,
            showDetailedSteps: true,
            onTapDetails: _showVerificationDetails,
          ),
          const SizedBox(height: 20),
          _buildVerificationHistory(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.verified_user,
                    color: theme.colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verify Your Identity',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complete KYC verification to access wallet features',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    color: theme.colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your documents are encrypted and stored securely according to Malaysian KYC compliance standards.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequiredDocumentsSection() {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.checklist,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Required Documents',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDocumentRequirement(
              theme,
              Icons.credit_card,
              'Malaysian IC',
              'Front and back of your Malaysian Identity Card',
              true,
            ),
            const SizedBox(height: 12),
            _buildDocumentRequirement(
              theme,
              Icons.face,
              'Selfie Photo',
              'Clear selfie for identity verification',
              true,
            ),
            const SizedBox(height: 12),
            _buildDocumentRequirement(
              theme,
              Icons.receipt_long,
              'Address Proof',
              'Utility bill or bank statement (optional)',
              false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentRequirement(
    ThemeData theme,
    IconData icon,
    String title,
    String description,
    bool isRequired,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (isRequired) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Required',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onError,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentUploadSections() {
    return Column(
      children: [
        // Malaysian IC Front
        DriverDocumentUploadWidget(
          documentType: DocumentType.icCard,
          documentSide: 'front',
          verificationId: _mockVerificationId,
          driverId: widget.driverId,
          userId: widget.userId,
          onUploadComplete: _onDocumentUploadComplete,
          onUploadError: _onDocumentUploadError,
        ),
        const SizedBox(height: 16),

        // Malaysian IC Back
        DriverDocumentUploadWidget(
          documentType: DocumentType.icCard,
          documentSide: 'back',
          verificationId: _mockVerificationId,
          driverId: widget.driverId,
          userId: widget.userId,
          onUploadComplete: _onDocumentUploadComplete,
          onUploadError: _onDocumentUploadError,
        ),
        const SizedBox(height: 16),

        // Selfie
        DriverDocumentUploadWidget(
          documentType: DocumentType.selfie,
          verificationId: _mockVerificationId,
          driverId: widget.driverId,
          userId: widget.userId,
          onUploadComplete: _onDocumentUploadComplete,
          onUploadError: _onDocumentUploadError,
        ),
      ],
    );
  }

  Widget _buildVerificationHistory() {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Verification History',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildHistoryItem(
              theme,
              'Verification Started',
              'Document verification process initiated',
              DateTime.now().subtract(const Duration(minutes: 5)),
              Icons.play_circle_outline,
              theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            _buildHistoryItem(
              theme,
              'Documents Required',
              'Please upload required identity documents',
              DateTime.now().subtract(const Duration(minutes: 5)),
              Icons.upload_file,
              theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
    ThemeData theme,
    String title,
    String description,
    DateTime timestamp,
    IconData icon,
    Color iconColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 16,
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
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatTimestamp(timestamp),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Event handlers
  void _onDocumentUploadComplete() {
    _logger.info('✅ Document upload completed');

    // Update verification progress (mock)
    setState(() {
      _mockVerification = DriverDocumentVerification(
        id: _mockVerification.id,
        driverId: _mockVerification.driverId,
        userId: _mockVerification.userId,
        verificationType: _mockVerification.verificationType,
        overallStatus: VerificationStatus.processing,
        currentStep: 2,
        totalSteps: _mockVerification.totalSteps,
        completionPercentage: 66.0,
        verificationMethod: _mockVerification.verificationMethod,
        processingStartedAt: DateTime.now(),
        extractedData: _mockVerification.extractedData,
        verificationResults: _mockVerification.verificationResults,
        failureReasons: _mockVerification.failureReasons,
        kycComplianceStatus: _mockVerification.kycComplianceStatus,
        complianceChecks: _mockVerification.complianceChecks,
        auditTrail: _mockVerification.auditTrail,
        retentionExpiresAt: _mockVerification.retentionExpiresAt,
        metadata: _mockVerification.metadata,
        createdAt: _mockVerification.createdAt,
        updatedAt: DateTime.now(),
      );
    });

    // Switch to progress tab
    _tabController.animateTo(1);
  }

  void _onDocumentUploadError() {
    _logger.warning('⚠️ Document upload error occurred');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Upload failed. Please try again.'),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () {
            // Handle retry logic
          },
        ),
      ),
    );
  }

  void _showVerificationDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => _buildVerificationDetailsSheet(
          scrollController,
        ),
      ),
    );
  }

  Widget _buildVerificationDetailsSheet(ScrollController scrollController) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Verification Details',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                _buildDetailItem('Verification ID', _mockVerification.id),
                _buildDetailItem('Status', _mockVerification.statusDisplayText),
                _buildDetailItem('Progress', _mockVerification.progressPercentage),
                _buildDetailItem('Method', 'OCR + AI Verification'),
                _buildDetailItem('Created', _formatTimestamp(_mockVerification.createdAt)),
                _buildDetailItem('Updated', _formatTimestamp(_mockVerification.updatedAt)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
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

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Document Verification Help'),
        content: const Text(
          'This process verifies your identity for wallet access. Upload clear photos of your Malaysian IC and a selfie. Processing usually takes a few minutes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
