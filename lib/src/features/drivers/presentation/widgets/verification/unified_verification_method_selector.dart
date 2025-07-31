import 'package:flutter/material.dart';

/// Widget that shows the unified verification method option
class UnifiedVerificationMethodSelector extends StatelessWidget {
  final VoidCallback onStartVerification;
  final bool isLoading;

  const UnifiedVerificationMethodSelector({
    super.key,
    required this.onStartVerification,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verification Method',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Complete your wallet verification in one simple process.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        
        _buildUnifiedMethodCard(theme),
      ],
    );
  }

  Widget _buildUnifiedMethodCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: isLoading ? null : onStartVerification,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.05),
                theme.colorScheme.primary.withValues(alpha: 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Method icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.security,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Method details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Complete Verification',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Verify your bank account and identity in one secure process',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Arrow icon
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Features list
              _buildFeaturesList(theme),
              
              const SizedBox(height: 16),
              
              // Method badges
              _buildMethodBadges(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesList(ThemeData theme) {
    final features = [
      'Bank account verification',
      'Malaysian IC document upload',
      'Enhanced security with AI verification',
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  feature,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMethodBadges(ThemeData theme) {
    final badges = [
      {'text': '1-2 days', 'color': theme.colorScheme.primary},
      {'text': 'Most secure', 'color': Colors.green},
      {'text': 'All-in-one', 'color': Colors.orange},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: badges.map((badge) {
        final color = badge['color'] as Color;
        final text = badge['text'] as String;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}
