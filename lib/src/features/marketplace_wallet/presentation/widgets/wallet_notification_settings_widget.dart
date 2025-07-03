import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../user_management/data/models/customer/notification_preferences.dart' as customer_prefs;

/// Widget for managing wallet notification preferences
class WalletNotificationSettingsWidget extends ConsumerStatefulWidget {
  const WalletNotificationSettingsWidget({super.key});

  @override
  ConsumerState<WalletNotificationSettingsWidget> createState() => _WalletNotificationSettingsWidgetState();
}

class _WalletNotificationSettingsWidgetState extends ConsumerState<WalletNotificationSettingsWidget> {
  final Map<customer_prefs.WalletNotificationType, Map<customer_prefs.NotificationChannel, bool>> _preferences = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Initialize with default preferences
      for (final type in customer_prefs.WalletNotificationType.values) {
        _preferences[type] = {};
        for (final channel in customer_prefs.NotificationChannel.values) {
          _preferences[type]![channel] = _getDefaultPreference(type, channel);
        }
      }

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

  bool _getDefaultPreference(customer_prefs.WalletNotificationType type, customer_prefs.NotificationChannel channel) {
    // Default preferences based on notification type and channel
    switch (type) {
      case customer_prefs.WalletNotificationType.transactionReceived:
      case customer_prefs.WalletNotificationType.transactionSent:
      case customer_prefs.WalletNotificationType.lowBalance:
      case customer_prefs.WalletNotificationType.spendingLimitReached:
      case customer_prefs.WalletNotificationType.securityAlert:
        return channel == customer_prefs.NotificationChannel.push;
      case customer_prefs.WalletNotificationType.autoReloadTriggered:
        return channel == customer_prefs.NotificationChannel.push;
      case customer_prefs.WalletNotificationType.weeklySummary:
        return false;
      case customer_prefs.WalletNotificationType.monthlySummary:
        return channel == customer_prefs.NotificationChannel.email;
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
                'Failed to load notification preferences',
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
                onPressed: _loadNotificationPreferences,
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
          'Notification Preferences',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose how you want to be notified about wallet activities',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),

        // Transaction Notifications
        _buildNotificationSection(
          context,
          'Transaction Notifications',
          'Get notified when money is sent or received',
          [
            customer_prefs.WalletNotificationType.transactionReceived,
            customer_prefs.WalletNotificationType.transactionSent,
          ],
        ),
        const SizedBox(height: 16),

        // Balance & Spending Notifications
        _buildNotificationSection(
          context,
          'Balance & Spending Alerts',
          'Stay informed about your balance and spending limits',
          [
            customer_prefs.WalletNotificationType.lowBalance,
            customer_prefs.WalletNotificationType.spendingLimitReached,
            customer_prefs.WalletNotificationType.autoReloadTriggered,
          ],
        ),
        const SizedBox(height: 16),

        // Security Notifications
        _buildNotificationSection(
          context,
          'Security Alerts',
          'Important security-related notifications',
          [
            customer_prefs.WalletNotificationType.securityAlert,
          ],
        ),
        const SizedBox(height: 16),

        // Summary Notifications
        _buildNotificationSection(
          context,
          'Summary Reports',
          'Periodic summaries of your wallet activity',
          [
            customer_prefs.WalletNotificationType.weeklySummary,
            customer_prefs.WalletNotificationType.monthlySummary,
          ],
        ),
        const SizedBox(height: 24),

        // Notification Settings
        _buildNotificationSettingsCard(context),
      ],
    );
  }

  Widget _buildNotificationSection(
    BuildContext context,
    String title,
    String description,
    List<customer_prefs.WalletNotificationType> types,
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

            ...types.map((type) => _buildNotificationTypeRow(context, type)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypeRow(BuildContext context, customer_prefs.WalletNotificationType type) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            type.displayName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            type.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),

          // Channel toggles
          Row(
            children: customer_prefs.NotificationChannel.values.map((channel) {
              final isEnabled = _preferences[type]?[channel] ?? false;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildChannelToggle(context, type, channel, isEnabled),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelToggle(
    BuildContext context,
    customer_prefs.WalletNotificationType type,
    customer_prefs.NotificationChannel channel,
    bool isEnabled,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _toggleNotificationPreference(type, channel),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isEnabled 
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled 
                ? AppTheme.primaryColor
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getChannelIcon(channel),
              size: 16,
              color: isEnabled 
                  ? AppTheme.primaryColor
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                channel.displayName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isEnabled 
                      ? AppTheme.primaryColor
                      : Colors.grey.shade600,
                  fontWeight: isEnabled ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettingsCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Settings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Quiet Hours'),
              subtitle: const Text('Set times when notifications are silenced'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showQuietHoursDialog(context),
              contentPadding: EdgeInsets.zero,
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.group_work),
              title: const Text('Batch Notifications'),
              subtitle: const Text('Group similar notifications together'),
              trailing: Switch(
                value: false, // TODO: Implement batch notifications setting
                onChanged: (value) {
                  // TODO: Update batch notifications preference
                },
              ),
              contentPadding: EdgeInsets.zero,
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.volume_up),
              title: const Text('Notification Sound'),
              subtitle: const Text('Choose notification sound'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showNotificationSoundDialog(context),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getChannelIcon(customer_prefs.NotificationChannel channel) {
    switch (channel) {
      case customer_prefs.NotificationChannel.push:
        return Icons.notifications;
      case customer_prefs.NotificationChannel.email:
        return Icons.email;
      case customer_prefs.NotificationChannel.sms:
        return Icons.sms;
      case customer_prefs.NotificationChannel.inApp:
        return Icons.app_registration;
    }
  }

  void _toggleNotificationPreference(customer_prefs.WalletNotificationType type, customer_prefs.NotificationChannel channel) {
    setState(() {
      _preferences[type]![channel] = !(_preferences[type]![channel] ?? false);
    });

    // TODO: Save preference to backend
    _saveNotificationPreference(type, channel, _preferences[type]![channel]!);
  }

  Future<void> _saveNotificationPreference(
    customer_prefs.WalletNotificationType type,
    customer_prefs.NotificationChannel channel,
    bool isEnabled,
  ) async {
    try {
      // TODO: Implement saving to backend via repository
      debugPrint('Saving notification preference: $type, $channel, $isEnabled');
    } catch (e) {
      // Revert the change if save fails
      setState(() {
        _preferences[type]![channel] = !isEnabled;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save notification preference: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showQuietHoursDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const QuietHoursDialog(),
    );
  }

  void _showNotificationSoundDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const NotificationSoundDialog(),
    );
  }
}

/// Dialog for setting quiet hours
class QuietHoursDialog extends StatefulWidget {
  const QuietHoursDialog({super.key});

  @override
  State<QuietHoursDialog> createState() => _QuietHoursDialogState();
}

class _QuietHoursDialogState extends State<QuietHoursDialog> {
  bool _enableQuietHours = false;
  TimeOfDay _startTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 7, minute: 0);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quiet Hours'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set times when notifications will be silenced'),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Enable Quiet Hours'),
              value: _enableQuietHours,
              onChanged: (value) {
                setState(() {
                  _enableQuietHours = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),

            if (_enableQuietHours) ...[
              const SizedBox(height: 16),

              ListTile(
                title: const Text('Start Time'),
                subtitle: Text(_startTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context, true),
                contentPadding: EdgeInsets.zero,
              ),

              ListTile(
                title: const Text('End Time'),
                subtitle: Text(_endTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context, false),
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.infoColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.infoColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Notifications will be silenced from ${_startTime.format(context)} to ${_endTime.format(context)}',
                        style: TextStyle(
                          color: AppTheme.infoColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Save quiet hours settings
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Quiet hours settings saved'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }
}

/// Dialog for notification sound settings
class NotificationSoundDialog extends StatefulWidget {
  const NotificationSoundDialog({super.key});

  @override
  State<NotificationSoundDialog> createState() => _NotificationSoundDialogState();
}

class _NotificationSoundDialogState extends State<NotificationSoundDialog> {
  String _selectedSound = 'default';
  final List<Map<String, String>> _sounds = [
    {'id': 'default', 'name': 'Default'},
    {'id': 'chime', 'name': 'Chime'},
    {'id': 'bell', 'name': 'Bell'},
    {'id': 'ding', 'name': 'Ding'},
    {'id': 'none', 'name': 'Silent'},
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notification Sound'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose a sound for wallet notifications'),
            const SizedBox(height: 16),

            ..._sounds.map((sound) => RadioListTile<String>(
              title: Text(sound['name']!),
              value: sound['id']!,
              groupValue: _selectedSound,
              onChanged: (value) {
                setState(() {
                  _selectedSound = value!;
                });
              },
              contentPadding: EdgeInsets.zero,
            )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Save notification sound setting
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notification sound saved'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
