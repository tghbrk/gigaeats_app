import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/loading_widget.dart';
import '../../providers/wallet_analytics_provider.dart';
import '../../widgets/customer_wallet_error_widget.dart';
import '../../../data/models/customer_wallet_error.dart';

class WalletAnalyticsSettingsScreen extends ConsumerStatefulWidget {
  const WalletAnalyticsSettingsScreen({super.key});

  @override
  ConsumerState<WalletAnalyticsSettingsScreen> createState() => _WalletAnalyticsSettingsScreenState();
}

class _WalletAnalyticsSettingsScreenState extends ConsumerState<WalletAnalyticsSettingsScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletAnalyticsProvider.notifier).loadPrivacySettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analyticsState = ref.watch(walletAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Settings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : analyticsState.errorMessage != null
              ? CustomerWalletErrorWidget(
                  error: CustomerWalletError.fromMessage(analyticsState.errorMessage!),
                  onRetry: () => ref.read(walletAnalyticsProvider.notifier).loadPrivacySettings(),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        'Privacy & Analytics',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Control how your wallet data is used for analytics and insights.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Privacy Notice
                      _buildPrivacyNotice(),
                      const SizedBox(height: 24),

                      // Analytics Settings
                      _buildSettingsSection(
                        title: 'Analytics Features',
                        subtitle: 'Control how your spending data is analyzed and used',
                        children: [
                          _buildEnhancedSettingsTile(
                            title: 'Enable Analytics',
                            subtitle: 'Allow generation of spending insights and trends',
                            description: 'When enabled, we analyze your transaction patterns to provide personalized insights about your spending habits.',
                            value: analyticsState.privacySettings['allow_analytics'] ?? false,
                            onChanged: (value) => _updateSetting('allow_analytics', value),
                            icon: Icons.analytics,
                            isRequired: false,
                          ),
                          _buildEnhancedSettingsTile(
                            title: 'Share Transaction Data',
                            subtitle: 'Allow anonymized data sharing for improved insights',
                            description: 'Your transaction data will be anonymized and used to improve our analytics algorithms. No personal information is shared.',
                            value: analyticsState.privacySettings['share_transaction_data'] ?? false,
                            onChanged: (value) => _updateSetting('share_transaction_data', value),
                            enabled: analyticsState.privacySettings['allow_analytics'] ?? false,
                            icon: Icons.share,
                            isRequired: false,
                          ),
                          _buildEnhancedSettingsTile(
                            title: 'AI Insights',
                            subtitle: 'Enable AI-powered spending recommendations',
                            description: 'Get personalized recommendations and insights powered by artificial intelligence to help you manage your spending better.',
                            value: analyticsState.privacySettings['allow_insights'] ?? false,
                            onChanged: (value) => _updateSetting('allow_insights', value),
                            enabled: analyticsState.privacySettings['allow_analytics'] ?? false,
                            icon: Icons.psychology,
                            isRequired: false,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Export Settings
                      _buildSettingsSection(
                        title: 'Data Export',
                        children: [
                          _buildSettingsTile(
                            title: 'Allow Data Export',
                            subtitle: 'Enable exporting analytics data to PDF/CSV',
                            value: analyticsState.privacySettings['allow_export'] ?? false,
                            onChanged: (value) => _updateSetting('allow_export', value),
                            enabled: analyticsState.privacySettings['allow_analytics'] ?? false,
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Information Card
                      Card(
                        color: AppTheme.infoColor.withValues(alpha: 0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppTheme.infoColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Privacy Information',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.infoColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your privacy is important to us. Analytics data is processed securely and never shared with third parties. You can disable analytics at any time.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _clearAnalyticsData,
                              child: const Text('Clear Analytics Data'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => context.pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Done'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.privacy_tip, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Privacy & Data Control',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You have full control over your analytics data. All settings can be changed at any time, and you can request data deletion. We follow GDPR guidelines and never share personal information.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _showPrivacyPolicy(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'View Privacy Policy',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSettingsTile({
    required String title,
    required String subtitle,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
    required IconData icon,
    required bool isRequired,
  }) {
    return ExpansionTile(
      leading: Icon(
        icon,
        color: enabled ? AppTheme.primaryColor : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: enabled ? null : Colors.grey,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: enabled ? Colors.grey.shade600 : Colors.grey,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: AppTheme.primaryColor,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              if (isRequired) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Required for core functionality',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeColor: AppTheme.primaryColor,
    );
  }

  Future<void> _updateSetting(String key, bool value) async {
    setState(() => _isLoading = true);

    try {
      // Update settings using AnalyticsPrivacyService
      final privacyService = ref.read(analyticsPrivacyServiceProvider);

      final updateResult = await privacyService.updatePrivacySettings(
        allowAnalytics: key == 'allow_analytics' ? value : null,
        shareTransactionData: key == 'share_transaction_data' ? value : null,
        allowInsights: key == 'allow_insights' ? value : null,
        allowExport: key == 'allow_export' ? value : null,
      );

      await updateResult.fold(
        (failure) async {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update settings: ${failure.message}'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        (_) async {
          // Reload privacy settings to get updated state
          await ref.read(walletAnalyticsProvider.notifier).loadPrivacySettings();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Settings updated successfully'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settings updated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update settings: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _clearAnalyticsData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Analytics Data'),
        content: const Text(
          'This will permanently delete all your analytics data. This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        // Clear analytics data using AnalyticsPrivacyService
        final privacyService = ref.read(analyticsPrivacyServiceProvider);

        final clearResult = await privacyService.clearAnalyticsData();

        await clearResult.fold(
          (failure) async {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to clear data: ${failure.message}'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          },
          (_) async {
            // Reload analytics data to reflect changes
            await ref.read(walletAnalyticsProvider.notifier).loadAnalytics();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Analytics data cleared successfully'),
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
              content: Text('Failed to clear data: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'GigaEats Privacy Policy\n\n'
            'We are committed to protecting your privacy and ensuring you have control over your data.\n\n'
            '• Analytics data is processed locally and anonymized\n'
            '• You can disable analytics at any time\n'
            '• Data export is optional and requires your consent\n'
            '• We never share personal information with third parties\n'
            '• You have the right to request data deletion\n\n'
            'For the complete privacy policy, visit our website.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Open full privacy policy
            },
            child: const Text('View Full Policy'),
          ),
        ],
      ),
    );
  }
}
