import 'package:flutter/material.dart';

/// Widget that shows the current progress of the verification process
class VerificationProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String>? stepLabels;

  const VerificationProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.stepLabels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultLabels = [
      'Submit Details',
      'Processing',
      'Verified',
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
      stepColor = Colors.grey;
      stepIcon = Icons.radio_button_unchecked;
    }

    return Column(
      children: [
        Row(
          children: [
            // Step icon
            Icon(
              stepIcon,
              color: stepColor,
              size: 24,
            ),
            
            const SizedBox(width: 12),
            
            // Step label
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isUpcoming 
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            
            // Step status
            if (isCompleted) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Complete',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ] else if (isCurrent) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'In Progress',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        
        // Connector line (except for last step)
        if (!isLast) ...[
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(left: 12),
            child: Row(
              children: [
                Container(
                  width: 2,
                  height: 20,
                  color: isCompleted || isCurrent 
                      ? stepColor.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.3),
                ),
              ],
            ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Overall Progress',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(
            currentStep == totalSteps ? Colors.green : theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
