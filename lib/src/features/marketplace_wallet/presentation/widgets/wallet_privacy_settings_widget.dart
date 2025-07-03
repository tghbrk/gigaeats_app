import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/loading_widget.dart';

/// Privacy settings for wallet data and transaction history
enum PrivacyLevel {
  public,
  friends,
  private;

  String get displayName {
    switch (this) {
      case PrivacyLevel.public:
        return 'Public';
      case PrivacyLevel.friends:
        return 'Friends Only';
      case PrivacyLevel.private:
        return 'Private';
    }
  }

  String get description {
    switch (this) {
      case PrivacyLevel.public:
        return 'Visible to everyone';
      case PrivacyLevel.friends:
        return 'Visible to friends only';
      case PrivacyLevel.private:
        return 'Only visible to you';
    }
  }
}

/// Widget for managing wallet privacy settings
class WalletPrivacySettingsWidget extends ConsumerStatefulWidget {
  const WalletPrivacySettingsWidget({super.key});

  @override
  ConsumerState<WalletPrivacySettingsWidget> createState() => _WalletPrivacySettingsWidgetState();
}

class _WalletPrivacySettingsWidgetState extends ConsumerState<WalletPrivacySettingsWidget> {
  // Privacy settings state
  PrivacyLevel _transactionHistoryVisibility = PrivacyLevel.private;
  PrivacyLevel _balanceVisibility = PrivacyLevel.private;
  bool _shareSpendingInsights = false;
  bool _shareLocationData = false;
  bool _allowDataAnalytics = true;
  bool _allowMarketingCommunications = false;
  bool _allowThirdPartySharing = false;
  
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Load actual privacy settings from provider
      // For now, use default values
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: LoadingWidget()),
        ),
      );
    }

    if (_errorMessage != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                color: AppTheme.errorColor,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load privacy settings',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPrivacySettings,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy & Data Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Control who can see your wallet information and how your data is used',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),

        // Transaction History Visibility
        _buildVisibilityCard(
          context,
          'Transaction History Visibility',
          'Control who can see your transaction history',
          _transactionHistoryVisibility,
          (level) => _updateTransactionHistoryVisibility(level),
        ),
        const SizedBox(height: 16),

        // Balance Visibility
        _buildVisibilityCard(
          context,
          'Balance Visibility',
          'Control who can see your wallet balance',
          _balanceVisibility,
          (level) => _updateBalanceVisibility(level),
        ),
        const SizedBox(height: 16),

        // Data Sharing Settings
        _buildDataSharingCard(context),
        const SizedBox(height: 16),

        // Data Rights & Export
        _buildDataRightsCard(context),
      ],
    );
  }

  Widget _buildVisibilityCard(
    BuildContext context,
    String title,
    String description,
    PrivacyLevel currentLevel,
    Function(PrivacyLevel) onChanged,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),

            ...PrivacyLevel.values.map((level) => RadioListTile<PrivacyLevel>(
              title: Text(level.displayName),
              subtitle: Text(level.description),
              value: level,
              groupValue: currentLevel,
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                }
              },
              contentPadding: EdgeInsets.zero,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSharingCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Sharing Preferences',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Share Spending Insights'),
              subtitle: const Text('Allow anonymized spending patterns to improve recommendations'),
              value: _shareSpendingInsights,
              onChanged: (value) => _updateDataSharingSetting('shareSpendingInsights', value),
              contentPadding: EdgeInsets.zero,
            ),

            SwitchListTile(
              title: const Text('Share Location Data'),
              subtitle: const Text('Help improve location-based services and offers'),
              value: _shareLocationData,
              onChanged: (value) => _updateDataSharingSetting('shareLocationData', value),
              contentPadding: EdgeInsets.zero,
            ),

            SwitchListTile(
              title: const Text('Analytics & Performance'),
              subtitle: const Text('Help improve app performance and user experience'),
              value: _allowDataAnalytics,
              onChanged: (value) => _updateDataSharingSetting('allowDataAnalytics', value),
              contentPadding: EdgeInsets.zero,
            ),

            SwitchListTile(
              title: const Text('Marketing Communications'),
              subtitle: const Text('Receive personalized offers and promotions'),
              value: _allowMarketingCommunications,
              onChanged: (value) => _updateDataSharingSetting('allowMarketingCommunications', value),
              contentPadding: EdgeInsets.zero,
            ),

            const Divider(),

            SwitchListTile(
              title: const Text('Third-party Data Sharing'),
              subtitle: const Text('Share data with trusted partners for better services'),
              value: _allowThirdPartySharing,
              onChanged: (value) => _showThirdPartyDataSharingDialog(context, value),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRightsCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Rights & Export',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export My Data'),
              subtitle: const Text('Download a copy of your wallet data'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showDataExportDialog(context),
              contentPadding: EdgeInsets.zero,
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: const Text('Delete My Data'),
              subtitle: const Text('Permanently delete your wallet data'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showDataDeletionDialog(context),
              contentPadding: EdgeInsets.zero,
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.policy),
              title: const Text('Privacy Policy'),
              subtitle: const Text('View our privacy policy and data practices'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _openPrivacyPolicy(context),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  void _updateTransactionHistoryVisibility(PrivacyLevel level) {
    if (level != PrivacyLevel.private) {
      _showVisibilityConfirmationDialog(
        context,
        'Transaction History Visibility',
        'Are you sure you want to make your transaction history ${level.description.toLowerCase()}? This will allow others to see your spending patterns.',
        () {
          setState(() {
            _transactionHistoryVisibility = level;
          });
          _savePrivacySettings();
        },
      );
    } else {
      setState(() {
        _transactionHistoryVisibility = level;
      });
      _savePrivacySettings();
    }
  }

  void _updateBalanceVisibility(PrivacyLevel level) {
    if (level != PrivacyLevel.private) {
      _showVisibilityConfirmationDialog(
        context,
        'Balance Visibility',
        'Are you sure you want to make your wallet balance ${level.description.toLowerCase()}? This will allow others to see your current balance.',
        () {
          setState(() {
            _balanceVisibility = level;
          });
          _savePrivacySettings();
        },
      );
    } else {
      setState(() {
        _balanceVisibility = level;
      });
      _savePrivacySettings();
    }
  }

  void _updateDataSharingSetting(String setting, bool value) {
    setState(() {
      switch (setting) {
        case 'shareSpendingInsights':
          _shareSpendingInsights = value;
          break;
        case 'shareLocationData':
          _shareLocationData = value;
          break;
        case 'allowDataAnalytics':
          _allowDataAnalytics = value;
          break;
        case 'allowMarketingCommunications':
          _allowMarketingCommunications = value;
          break;
      }
    });
    _savePrivacySettings();
  }

  void _showVisibilityConfirmationDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningColor,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showThirdPartyDataSharingDialog(BuildContext context, bool value) {
    if (value) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Third-party Data Sharing'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('By enabling third-party data sharing, you allow us to share your anonymized data with:'),
              SizedBox(height: 12),
              Text('• Payment processors for fraud prevention'),
              Text('• Analytics partners for service improvement'),
              Text('• Marketing partners for relevant offers'),
              SizedBox(height: 12),
              Text('Your personal information will never be shared without your explicit consent.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _allowThirdPartySharing = value;
                });
                _savePrivacySettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningColor,
              ),
              child: const Text('Enable'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _allowThirdPartySharing = value;
      });
      _savePrivacySettings();
    }
  }

  void _showDataExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export My Data'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('We will prepare a comprehensive export of your wallet data including:'),
            SizedBox(height: 12),
            Text('• Transaction history'),
            Text('• Payment methods'),
            Text('• Wallet settings'),
            Text('• Privacy preferences'),
            SizedBox(height: 12),
            Text('The export will be sent to your registered email address within 24 hours.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _requestDataExport();
            },
            child: const Text('Request Export'),
          ),
        ],
      ),
    );
  }

  void _showDataDeletionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete My Data'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('⚠️ This action cannot be undone!'),
            SizedBox(height: 12),
            Text('Deleting your data will permanently remove:'),
            SizedBox(height: 8),
            Text('• All transaction history'),
            Text('• Saved payment methods'),
            Text('• Wallet settings and preferences'),
            Text('• Account information'),
            SizedBox(height: 12),
            Text('You will need to create a new account to use the wallet again.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showFinalDeletionConfirmation(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showFinalDeletionConfirmation(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Type "DELETE MY DATA" to confirm permanent deletion:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'DELETE MY DATA',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text == 'DELETE MY DATA') {
                Navigator.of(context).pop();
                _requestDataDeletion();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please type "DELETE MY DATA" exactly as shown'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }

  void _openPrivacyPolicy(BuildContext context) {
    // TODO: Open privacy policy URL
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening privacy policy...')),
    );
  }

  Future<void> _requestDataExport() async {
    try {
      // TODO: Request data export from backend
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data export requested. You will receive an email within 24 hours.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to request data export: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _requestDataDeletion() async {
    try {
      // TODO: Request data deletion from backend
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data deletion requested. Your account will be deleted within 30 days.'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to request data deletion: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _savePrivacySettings() async {
    try {
      // TODO: Save privacy settings to backend
      debugPrint('Saving privacy settings...');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save privacy settings: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
