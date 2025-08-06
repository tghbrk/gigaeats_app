import 'package:flutter/material.dart';

/// Widget that shows the current progress of the customer wallet verification process
class CustomerVerificationProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String>? stepLabels;
  final bool showUnifiedProgress;
  final Map<String, String>? verificationStatuses; // For unified verification progress

  const CustomerVerificationProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.stepLabels,
    this.showUnifiedProgress = false,
    this.verificationStatuses,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultLabels = [
      'Submit Details',
      'Processing Verification',
      'Verification Complete',
    ];
    
    final labels = stepLabels ?? defaultLabels;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Verification Progress',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Step $currentStep of $totalSteps',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Progress steps
            Column(
              children: List.generate(totalSteps, (index) {
                final stepNumber = index + 1;
                final isCompleted = stepNumber < currentStep;
                final isCurrent = stepNumber == currentStep;
                final isUpcoming = stepNumber > currentStep;
                
                return _buildProgressStep(
                  theme,
                  stepNumber,
                  labels.length > index ? labels[index] : 'Step $stepNumber',
                  isCompleted: isCompleted,
                  isCurrent: isCurrent,
                  isUpcoming: isUpcoming,
                  isLast: index == totalSteps - 1,
                );
              }),
            ),
            
            const SizedBox(height: 16),
            
            // Progress bar
            _buildProgressBar(theme),

            // Unified verification details (if enabled)
            if (showUnifiedProgress && verificationStatuses != null) ...[
              const SizedBox(height: 20),
              _buildUnifiedVerificationDetails(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStep(
    ThemeData theme,
    int stepNumber,
    String label, {
    required bool isCompleted,
    required bool isCurrent,
    required bool isUpcoming,
    required bool isLast,
  }) {
    Color stepColor;
    IconData stepIcon;
    
    if (isCompleted) {
      stepColor = Colors.green;
      stepIcon = Icons.check_circle;
    } else if (isCurrent) {
      stepColor = theme.colorScheme.primary;
      stepIcon = Icons.radio_button_checked;
    } else {
      stepColor = theme.colorScheme.outline;
      stepIcon = Icons.radio_button_unchecked;
    }

    return Column(
      children: [
        Row(
          children: [
            // Step icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: stepColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: stepColor, width: 2),
              ),
              child: Icon(
                stepIcon,
                size: 18,
                color: stepColor,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Step label
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                  color: isUpcoming 
                      ? theme.colorScheme.onSurfaceVariant 
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        
        // Connector line (except for last step)
        if (!isLast) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 16), // Center align with icon
              Container(
                width: 2,
                height: 24,
                color: isCompleted 
                    ? Colors.green.withValues(alpha: 0.5)
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 16),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    final progress = currentStep / totalSteps;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        Text(
          '${(progress * 100).round()}% Complete',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildUnifiedVerificationDetails(ThemeData theme) {
    final statuses = verificationStatuses!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verification Components',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          
          // Bank account verification
          _buildVerificationComponent(
            theme,
            'Bank Account',
            statuses['bank_verification_status'] ?? 'pending',
            Icons.account_balance,
          ),
          
          const SizedBox(height: 8),
          
          // Document verification
          _buildVerificationComponent(
            theme,
            'Identity Documents',
            statuses['document_verification_status'] ?? 'pending',
            Icons.credit_card,
          ),
          
          // Instant verification (if included)
          if (statuses['instant_verification_status'] != null) ...[
            const SizedBox(height: 8),
            _buildVerificationComponent(
              theme,
              'Instant Verification',
              statuses['instant_verification_status']!,
              Icons.flash_on,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerificationComponent(
    ThemeData theme,
    String title,
    String status,
    IconData icon,
  ) {
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'verified':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'processing':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case 'pending':
      default:
        statusColor = theme.colorScheme.outline;
        statusIcon = Icons.schedule;
        break;
    }

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        Icon(
          statusIcon,
          size: 16,
          color: statusColor,
        ),
        const SizedBox(width: 4),
        Text(
          _getStatusDisplayText(status),
          style: theme.textTheme.bodySmall?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'verified':
        return 'Verified';
      case 'processing':
        return 'Processing';
      case 'failed':
        return 'Failed';
      case 'pending':
      default:
        return 'Pending';
    }
  }
}
