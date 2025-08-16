import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../../features/marketplace_wallet/presentation/providers/wallet_analytics_provider.dart';

/// Comprehensive analytics consent dialog for GDPR compliance
class AnalyticsConsentDialog extends ConsumerStatefulWidget {
  final bool isFirstTime;
  final VoidCallback? onConsentGiven;
  final VoidCallback? onConsentDenied;

  const AnalyticsConsentDialog({
    super.key,
    this.isFirstTime = false,
    this.onConsentGiven,
    this.onConsentDenied,
  });

  @override
  ConsumerState<AnalyticsConsentDialog> createState() => _AnalyticsConsentDialogState();
}

class _AnalyticsConsentDialogState extends ConsumerState<AnalyticsConsentDialog> {
  bool _allowAnalytics = false;
  bool _allowDataSharing = false;
  bool _allowInsights = false;
  bool _allowExport = false;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.privacy_tip, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Privacy & Analytics Consent'),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Introduction
              _buildIntroduction(),
              const SizedBox(height: 20),
              
              // Consent Options
              _buildConsentOptions(),
              const SizedBox(height: 20),
              
              // Data Usage Information
              _buildDataUsageInfo(),
              const SizedBox(height: 20),
              
              // User Rights
              _buildUserRights(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => _handleConsentResponse(false),
          child: const Text('Decline All'),
        ),
        TextButton(
          onPressed: _isProcessing ? null : _showCustomizeOptions,
          child: const Text('Customize'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : () => _handleConsentResponse(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Accept All'),
        ),
      ],
    );
  }

  Widget _buildIntroduction() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isFirstTime 
              ? 'Welcome to GigaEats Analytics!'
              : 'Update Your Privacy Preferences',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We respect your privacy and want to be transparent about how we use your data. '
          'You have full control over your analytics preferences and can change them at any time.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildConsentOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics Preferences',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildConsentTile(
          title: 'Enable Analytics',
          description: 'Allow us to analyze your spending patterns to provide insights',
          value: _allowAnalytics,
          onChanged: (value) => setState(() => _allowAnalytics = value),
          icon: Icons.analytics,
        ),
        _buildConsentTile(
          title: 'Data Sharing',
          description: 'Share anonymized data to improve our services',
          value: _allowDataSharing,
          onChanged: (value) => setState(() => _allowDataSharing = value),
          icon: Icons.share,
          enabled: _allowAnalytics,
        ),
        _buildConsentTile(
          title: 'AI Insights',
          description: 'Get personalized recommendations powered by AI',
          value: _allowInsights,
          onChanged: (value) => setState(() => _allowInsights = value),
          icon: Icons.psychology,
          enabled: _allowAnalytics,
        ),
        _buildConsentTile(
          title: 'Data Export',
          description: 'Allow exporting your analytics data',
          value: _allowExport,
          onChanged: (value) => setState(() => _allowExport = value),
          icon: Icons.download,
          enabled: _allowAnalytics,
        ),
      ],
    );
  }

  Widget _buildConsentTile({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: enabled ? AppTheme.primaryColor : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: enabled ? null : Colors.grey,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: enabled ? Colors.grey.shade600 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDataUsageInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue.shade700, size: 16),
              const SizedBox(width: 6),
              Text(
                'How We Use Your Data',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '• Analytics data helps you understand your spending patterns\n'
            '• All data is encrypted and stored securely\n'
            '• We never share personal information with third parties\n'
            '• You can delete your data at any time',
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRights() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: Colors.green.shade700, size: 16),
              const SizedBox(width: 6),
              Text(
                'Your Rights',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '• Right to access your data\n'
            '• Right to correct inaccurate data\n'
            '• Right to delete your data\n'
            '• Right to data portability\n'
            '• Right to withdraw consent',
            style: TextStyle(
              fontSize: 11,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomizeOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Customize Privacy Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You can customize your privacy settings in the wallet settings screen.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                // Navigate to settings
              },
              child: const Text('Go to Settings'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConsentResponse(bool acceptAll) async {
    setState(() => _isProcessing = true);

    try {
      final privacyService = ref.read(analyticsPrivacyServiceProvider);
      
      // Set consent based on user choice
      final allowAnalytics = acceptAll || _allowAnalytics;
      final allowDataSharing = acceptAll || _allowDataSharing;
      final allowInsights = acceptAll || _allowInsights;
      final allowExport = acceptAll || _allowExport;

      final result = await privacyService.updatePrivacySettings(
        allowAnalytics: allowAnalytics,
        shareTransactionData: allowDataSharing,
        allowInsights: allowInsights,
        allowExport: allowExport,
      );

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to save preferences: ${failure.message}'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        (_) {
          // Success case - handle UI updates
          if (mounted) {
            Navigator.of(context).pop();

            // Call appropriate callback
            if (acceptAll || allowAnalytics) {
              widget.onConsentGiven?.call();
            } else {
              widget.onConsentDenied?.call();
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Privacy preferences saved successfully'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
