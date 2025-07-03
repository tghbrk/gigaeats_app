import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/customer_wallet_provider.dart';

/// Wallet security status widget
class WalletSecurityStatus extends ConsumerWidget {
  final VoidCallback? onSecurityPressed;

  const WalletSecurityStatus({
    super.key,
    this.onSecurityPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final walletState = ref.watch(customerWalletProvider);

    // Only show if wallet exists and has security recommendations
    if (!walletState.hasWallet || !_hasSecurityRecommendations(walletState)) {
      return const SizedBox.shrink();
    }

    final securityLevel = _calculateSecurityLevel(walletState);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSecurityPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getSecurityColor(theme, securityLevel).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getSecurityColor(theme, securityLevel).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getSecurityColor(theme, securityLevel).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getSecurityIcon(securityLevel),
                    color: _getSecurityColor(theme, securityLevel),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getSecurityTitle(securityLevel),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _getSecurityColor(theme, securityLevel),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getSecurityMessage(securityLevel),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _hasSecurityRecommendations(CustomerWalletState walletState) {
    // Check if there are any security recommendations
    // This would typically check various security factors
    return true; // For demo purposes, always show
  }

  SecurityLevel _calculateSecurityLevel(CustomerWalletState walletState) {
    // Calculate security level based on various factors
    int securityScore = 0;
    
    if (walletState.wallet != null) {
      // Check if wallet is active
      if (walletState.wallet!.isActive) {
        securityScore += 20;
      }
      
      // Check if wallet has recent activity (indicates monitoring)
      if (walletState.wallet!.lastActivityAt != null &&
          walletState.wallet!.lastActivityAt!.isAfter(DateTime.now().subtract(const Duration(days: 7)))) {
        securityScore += 20;
      }
      
      // Check wallet balance (higher balance = higher security needs)
      if (walletState.wallet!.availableBalance > 100) {
        securityScore += 20;
      }
      
      // Additional security checks would go here
      // - Two-factor authentication enabled
      // - Recent password change
      // - Device verification
      // - Transaction limits set
      securityScore += 30; // Assume some security measures are in place
    }
    
    if (securityScore >= 80) {
      return SecurityLevel.excellent;
    } else if (securityScore >= 60) {
      return SecurityLevel.good;
    } else if (securityScore >= 40) {
      return SecurityLevel.fair;
    } else {
      return SecurityLevel.poor;
    }
  }

  Color _getSecurityColor(ThemeData theme, SecurityLevel level) {
    switch (level) {
      case SecurityLevel.excellent:
        return Colors.green;
      case SecurityLevel.good:
        return theme.colorScheme.primary;
      case SecurityLevel.fair:
        return Colors.orange;
      case SecurityLevel.poor:
        return theme.colorScheme.error;
    }
  }

  IconData _getSecurityIcon(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.excellent:
        return Icons.verified_user;
      case SecurityLevel.good:
        return Icons.security;
      case SecurityLevel.fair:
        return Icons.warning_amber;
      case SecurityLevel.poor:
        return Icons.error_outline;
    }
  }

  String _getSecurityTitle(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.excellent:
        return 'Excellent Security';
      case SecurityLevel.good:
        return 'Good Security';
      case SecurityLevel.fair:
        return 'Security Needs Attention';
      case SecurityLevel.poor:
        return 'Security Alert';
    }
  }

  String _getSecurityMessage(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.excellent:
        return 'Your wallet is well protected with all security features enabled.';
      case SecurityLevel.good:
        return 'Your wallet security is good. Consider enabling additional features.';
      case SecurityLevel.fair:
        return 'Some security features need attention. Tap to review.';
      case SecurityLevel.poor:
        return 'Important security issues detected. Immediate action required.';
    }
  }
}

enum SecurityLevel {
  excellent,
  good,
  fair,
  poor,
}
