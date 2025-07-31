import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/driver_document_verification.dart';

/// Material Design 3 progress widget for driver document verification
class DriverVerificationProgressWidget extends ConsumerWidget {
  final DriverDocumentVerification verification;
  final bool showDetailedSteps;
  final VoidCallback? onTapDetails;

  const DriverVerificationProgressWidget({
    super.key,
    required this.verification,
    this.showDetailedSteps = true,
    this.onTapDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 20),
            _buildProgressIndicator(theme),
            const SizedBox(height: 16),
            _buildStatusInfo(theme),
            if (showDetailedSteps) ...[
              const SizedBox(height: 20),
              _buildStepsList(theme),
            ],
            if (verification.hasFailed || verification.requiresManualReview) ...[
              const SizedBox(height: 16),
              _buildActionSection(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getStatusColor(theme).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getStatusIcon(),
            color: _getStatusColor(theme),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Document Verification',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                verification.statusDisplayText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _getStatusColor(theme),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (onTapDetails != null)
          IconButton(
            onPressed: onTapDetails,
            icon: const Icon(Icons.info_outline),
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              verification.progressPercentage,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: _getStatusColor(theme),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: verification.completionPercentage / 100,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(theme)),
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        Text(
          'Step ${verification.currentStep} of ${verification.totalSteps}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor(theme).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(theme).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(),
            color: _getStatusColor(theme),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusTitle(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(theme),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusDescription(),
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

  Widget _buildStepsList(ThemeData theme) {
    final steps = _getVerificationSteps();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verification Steps',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        ...steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final stepNumber = index + 1;
          final isCompleted = stepNumber < verification.currentStep;
          final isCurrent = stepNumber == verification.currentStep;
          final isUpcoming = stepNumber > verification.currentStep;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? theme.colorScheme.primary
                        : isCurrent
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(
                            Icons.check,
                            color: theme.colorScheme.onPrimary,
                            size: 16,
                          )
                        : Text(
                            stepNumber.toString(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isCurrent
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title']!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                          color: isUpcoming
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (step['description'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          step['description']!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionSection(ThemeData theme) {
    if (verification.hasFailed) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Verification Failed',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (verification.failureReasons.isNotEmpty) ...[
              ...verification.failureReasons.map((reason) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $reason',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              )),
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              onPressed: () {
                // Handle retry action
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Verification'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
            ),
          ],
        ),
      );
    }

    if (verification.requiresManualReview) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: theme.colorScheme.onTertiaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Manual Review Required',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your documents are being reviewed by our team. This usually takes 1-2 business days.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Color _getStatusColor(ThemeData theme) {
    switch (verification.overallStatus) {
      case VerificationStatus.pending:
        return theme.colorScheme.onSurfaceVariant;
      case VerificationStatus.processing:
        return theme.colorScheme.primary;
      case VerificationStatus.verified:
        return theme.colorScheme.primary;
      case VerificationStatus.failed:
        return theme.colorScheme.error;
      case VerificationStatus.expired:
        return theme.colorScheme.error;
      case VerificationStatus.manualReview:
        return theme.colorScheme.tertiary;
      case VerificationStatus.rejected:
        return theme.colorScheme.error;
    }
  }

  IconData _getStatusIcon() {
    switch (verification.overallStatus) {
      case VerificationStatus.pending:
        return Icons.upload_file;
      case VerificationStatus.processing:
        return Icons.hourglass_empty;
      case VerificationStatus.verified:
        return Icons.verified;
      case VerificationStatus.failed:
        return Icons.error;
      case VerificationStatus.expired:
        return Icons.schedule;
      case VerificationStatus.manualReview:
        return Icons.person_search;
      case VerificationStatus.rejected:
        return Icons.cancel;
    }
  }

  String _getStatusTitle() {
    switch (verification.overallStatus) {
      case VerificationStatus.pending:
        return 'Upload Required';
      case VerificationStatus.processing:
        return 'Processing Documents';
      case VerificationStatus.verified:
        return 'Verification Complete';
      case VerificationStatus.failed:
        return 'Verification Failed';
      case VerificationStatus.expired:
        return 'Documents Expired';
      case VerificationStatus.manualReview:
        return 'Under Review';
      case VerificationStatus.rejected:
        return 'Application Rejected';
    }
  }

  String _getStatusDescription() {
    switch (verification.overallStatus) {
      case VerificationStatus.pending:
        return 'Please upload the required documents to continue';
      case VerificationStatus.processing:
        return 'We\'re verifying your documents using AI technology';
      case VerificationStatus.verified:
        return 'Your documents have been successfully verified';
      case VerificationStatus.failed:
        return 'Some documents could not be verified. Please check and resubmit';
      case VerificationStatus.expired:
        return 'Your documents have expired. Please upload new ones';
      case VerificationStatus.manualReview:
        return 'Our team is reviewing your documents manually';
      case VerificationStatus.rejected:
        return 'Your application has been rejected. Contact support for details';
    }
  }

  List<Map<String, String>> _getVerificationSteps() {
    return [
      {
        'title': 'Upload Documents',
        'description': 'Upload required identity and address documents',
      },
      {
        'title': 'AI Verification',
        'description': 'Automated verification using OCR and AI technology',
      },
      {
        'title': 'Final Review',
        'description': 'Final verification and account activation',
      },
    ];
  }
}
