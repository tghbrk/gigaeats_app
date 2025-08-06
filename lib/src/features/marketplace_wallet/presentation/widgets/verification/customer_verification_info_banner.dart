import 'package:flutter/material.dart';

/// Widget that displays informational banners for customer wallet verification
class CustomerVerificationInfoBanner extends StatelessWidget {
  final CustomerVerificationInfoType type;
  final String? customMessage;
  final VoidCallback? onAction;
  final String? actionText;

  const CustomerVerificationInfoBanner({
    super.key,
    required this.type,
    this.customMessage,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bannerConfig = _getBannerConfig();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerConfig.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerConfig.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                bannerConfig.icon,
                color: bannerConfig.iconColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bannerConfig.title != null) ...[
                      Text(
                        bannerConfig.title!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: bannerConfig.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      customMessage ?? bannerConfig.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: bannerConfig.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Action button if provided
          if (onAction != null && actionText != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: bannerConfig.iconColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(
                  actionText!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _BannerConfig _getBannerConfig() {
    switch (type) {
      case CustomerVerificationInfoType.unverifiedInfo:
        return _BannerConfig(
          icon: Icons.info_outline,
          iconColor: Colors.green.shade700,
          backgroundColor: Colors.green.shade50,
          borderColor: Colors.green.shade200,
          textColor: Colors.green.shade700,
          message: 'Verification is required to withdraw funds from your wallet.',
        );

      case CustomerVerificationInfoType.instantVerificationInfo:
        return _BannerConfig(
          icon: Icons.flash_on,
          iconColor: Colors.blue.shade700,
          backgroundColor: Colors.blue.shade50,
          borderColor: Colors.blue.shade200,
          textColor: Colors.blue.shade700,
          message: 'Enable instant verification for faster processing (optional).',
        );

      case CustomerVerificationInfoType.processingInfo:
        return _BannerConfig(
          icon: Icons.hourglass_empty,
          iconColor: Colors.orange.shade700,
          backgroundColor: Colors.orange.shade50,
          borderColor: Colors.orange.shade200,
          textColor: Colors.orange.shade700,
          title: 'Verification in Progress',
          message: 'Your verification is being processed. This may take 1-3 business days.',
        );

      case CustomerVerificationInfoType.securityInfo:
        return _BannerConfig(
          icon: Icons.security,
          iconColor: Colors.purple.shade700,
          backgroundColor: Colors.purple.shade50,
          borderColor: Colors.purple.shade200,
          textColor: Colors.purple.shade700,
          title: 'Enhanced Security',
          message: 'This unified process combines bank account verification, identity document verification, and optional instant verification for maximum security.',
        );

      case CustomerVerificationInfoType.requirementsInfo:
        return _BannerConfig(
          icon: Icons.checklist,
          iconColor: Colors.indigo.shade700,
          backgroundColor: Colors.indigo.shade50,
          borderColor: Colors.indigo.shade200,
          textColor: Colors.indigo.shade700,
          title: 'Verification Requirements',
          message: 'You will need: Malaysian IC (front & back), bank account details, and optionally your IC number for instant verification.',
        );

      case CustomerVerificationInfoType.errorInfo:
        return _BannerConfig(
          icon: Icons.error_outline,
          iconColor: Colors.red.shade700,
          backgroundColor: Colors.red.shade50,
          borderColor: Colors.red.shade200,
          textColor: Colors.red.shade700,
          title: 'Verification Failed',
          message: 'There was an issue with your verification. Please try again or contact support.',
        );

      case CustomerVerificationInfoType.successInfo:
        return _BannerConfig(
          icon: Icons.check_circle_outline,
          iconColor: Colors.green.shade700,
          backgroundColor: Colors.green.shade50,
          borderColor: Colors.green.shade200,
          textColor: Colors.green.shade700,
          title: 'Verification Complete',
          message: 'Your wallet has been successfully verified. You can now withdraw funds.',
        );

      case CustomerVerificationInfoType.warningInfo:
        return _BannerConfig(
          icon: Icons.warning_amber_outlined,
          iconColor: Colors.amber.shade700,
          backgroundColor: Colors.amber.shade50,
          borderColor: Colors.amber.shade200,
          textColor: Colors.amber.shade700,
          message: 'Please ensure all information is accurate to avoid verification delays.',
        );
    }
  }
}

/// Configuration class for banner styling
class _BannerConfig {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final String? title;
  final String message;

  const _BannerConfig({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    this.title,
    required this.message,
  });
}

/// Types of information banners for customer verification
enum CustomerVerificationInfoType {
  unverifiedInfo,
  instantVerificationInfo,
  processingInfo,
  securityInfo,
  requirementsInfo,
  errorInfo,
  successInfo,
  warningInfo,
}

/// Factory methods for common banner configurations
extension CustomerVerificationInfoBannerFactory on CustomerVerificationInfoBanner {
  /// Creates an unverified wallet info banner
  static CustomerVerificationInfoBanner unverified({
    VoidCallback? onStartVerification,
  }) {
    return CustomerVerificationInfoBanner(
      type: CustomerVerificationInfoType.unverifiedInfo,
      onAction: onStartVerification,
      actionText: 'Start Verification',
    );
  }

  /// Creates an instant verification info banner
  static CustomerVerificationInfoBanner instantVerification() {
    return const CustomerVerificationInfoBanner(
      type: CustomerVerificationInfoType.instantVerificationInfo,
    );
  }

  /// Creates a processing info banner
  static CustomerVerificationInfoBanner processing({
    String? customMessage,
  }) {
    return CustomerVerificationInfoBanner(
      type: CustomerVerificationInfoType.processingInfo,
      customMessage: customMessage,
    );
  }

  /// Creates a security info banner
  static CustomerVerificationInfoBanner security() {
    return const CustomerVerificationInfoBanner(
      type: CustomerVerificationInfoType.securityInfo,
    );
  }

  /// Creates a requirements info banner
  static CustomerVerificationInfoBanner requirements({
    VoidCallback? onLearnMore,
  }) {
    return CustomerVerificationInfoBanner(
      type: CustomerVerificationInfoType.requirementsInfo,
      onAction: onLearnMore,
      actionText: 'Learn More',
    );
  }

  /// Creates an error info banner
  static CustomerVerificationInfoBanner error({
    String? customMessage,
    VoidCallback? onRetry,
  }) {
    return CustomerVerificationInfoBanner(
      type: CustomerVerificationInfoType.errorInfo,
      customMessage: customMessage,
      onAction: onRetry,
      actionText: 'Retry',
    );
  }

  /// Creates a success info banner
  static CustomerVerificationInfoBanner success({
    VoidCallback? onContinue,
  }) {
    return CustomerVerificationInfoBanner(
      type: CustomerVerificationInfoType.successInfo,
      onAction: onContinue,
      actionText: 'Continue',
    );
  }

  /// Creates a warning info banner
  static CustomerVerificationInfoBanner warning({
    String? customMessage,
  }) {
    return CustomerVerificationInfoBanner(
      type: CustomerVerificationInfoType.warningInfo,
      customMessage: customMessage,
    );
  }
}
