import 'package:flutter/material.dart';

import '../../../data/models/driver_wallet_verification.dart';

/// Widget that allows users to select their preferred verification method
class VerificationMethodSelector extends StatelessWidget {
  final Function(String) onMethodSelected;
  final bool isLoading;

  const VerificationMethodSelector({
    super.key,
    required this.onMethodSelected,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: VerificationMethod.values.map((method) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMethodCard(theme, method),
        );
      }).toList(),
    );
  }

  Widget _buildMethodCard(ThemeData theme, VerificationMethod method) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: isLoading ? null : () => onMethodSelected(method.value),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Method icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getMethodColor(method).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getMethodIcon(method),
                  color: _getMethodColor(method),
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Method details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      method.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMethodBadges(theme, method),
                  ],
                ),
              ),
              
              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodBadges(ThemeData theme, VerificationMethod method) {
    final badges = _getMethodBadges(method);
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: badges.map((badge) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badge['color'].withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            badge['text'],
            style: theme.textTheme.bodySmall?.copyWith(
              color: badge['color'],
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getMethodIcon(VerificationMethod method) {
    switch (method) {
      case VerificationMethod.bankAccount:
        return Icons.account_balance;
      case VerificationMethod.document:
        return Icons.upload_file;
      case VerificationMethod.instant:
        return Icons.flash_on;
      case VerificationMethod.unified:
        return Icons.security;
    }
  }

  Color _getMethodColor(VerificationMethod method) {
    switch (method) {
      case VerificationMethod.bankAccount:
        return Colors.blue;
      case VerificationMethod.document:
        return Colors.green;
      case VerificationMethod.instant:
        return Colors.orange;
      case VerificationMethod.unified:
        return Colors.purple;
    }
  }

  List<Map<String, dynamic>> _getMethodBadges(VerificationMethod method) {
    switch (method) {
      case VerificationMethod.bankAccount:
        return [
          {'text': '1-2 days', 'color': Colors.blue},
          {'text': 'Most secure', 'color': Colors.green},
        ];
      case VerificationMethod.document:
        return [
          {'text': '2-3 days', 'color': Colors.orange},
          {'text': 'Upload required', 'color': Colors.grey},
        ];
      case VerificationMethod.instant:
        return [
          {'text': 'Instant', 'color': Colors.green},
          {'text': 'IC required', 'color': Colors.blue},
        ];
      case VerificationMethod.unified:
        return [
          {'text': '1-2 days', 'color': Colors.purple},
          {'text': 'All-in-one', 'color': Colors.green},
        ];
    }
  }
}
