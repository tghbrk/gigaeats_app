import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/voice_navigation_preferences.dart';
import '../../providers/enhanced_voice_navigation_provider.dart';

/// Enhanced voice settings panel for Phase 4.1
/// Provides comprehensive voice navigation configuration with advanced features
class EnhancedVoiceSettingsPanel extends ConsumerStatefulWidget {
  final VoiceNavigationPreferences preferences;
  final Function(VoiceNavigationPreferences) onPreferencesChanged;
  final bool showAdvancedSettings;

  const EnhancedVoiceSettingsPanel({
    super.key,
    required this.preferences,
    required this.onPreferencesChanged,
    this.showAdvancedSettings = false,
  });

  @override
  ConsumerState<EnhancedVoiceSettingsPanel> createState() => _EnhancedVoiceSettingsPanelState();
}

class _EnhancedVoiceSettingsPanelState extends ConsumerState<EnhancedVoiceSettingsPanel> {
  late VoiceNavigationPreferences _currentPreferences;

  @override
  void initState() {
    super.initState();
    _currentPreferences = widget.preferences;
  }

  @override
  void didUpdateWidget(EnhancedVoiceSettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preferences != widget.preferences) {
      _currentPreferences = widget.preferences;
    }
  }

  void _updatePreferences(VoiceNavigationPreferences newPreferences) {
    setState(() {
      _currentPreferences = newPreferences;
    });
    widget.onPreferencesChanged(newPreferences);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final voiceState = ref.watch(enhancedVoiceNavigationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Voice Settings
        _buildMainVoiceSettings(theme, voiceState),
        
        const SizedBox(height: 16),
        
        // Language Selection
        _buildLanguageSelection(theme, voiceState),
        
        const SizedBox(height: 16),
        
        // Audio Controls
        _buildAudioControls(theme, voiceState),
        
        if (widget.showAdvancedSettings) ...[
          const SizedBox(height: 16),
          _buildAdvancedSettings(theme, voiceState),
        ],
        
        const SizedBox(height: 16),
        
        // Test Voice Button
        _buildTestVoiceButton(theme, voiceState),
      ],
    );
  }

  Widget _buildMainVoiceSettings(ThemeData theme, EnhancedVoiceNavigationState voiceState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.record_voice_over,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Voice Guidance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Enable/Disable Voice Guidance
            SwitchListTile(
              title: const Text('Enable Voice Guidance'),
              subtitle: const Text('Turn-by-turn voice instructions during navigation'),
              value: _currentPreferences.isEnabled,
              onChanged: voiceState.isInitialized ? (value) {
                _updatePreferences(_currentPreferences.copyWith(isEnabled: value));
              } : null,
            ),
            
            // Traffic Alerts
            SwitchListTile(
              title: const Text('Traffic Alerts'),
              subtitle: const Text('Voice notifications for traffic conditions'),
              value: _currentPreferences.trafficAlertsEnabled,
              onChanged: _currentPreferences.isEnabled ? (value) {
                _updatePreferences(_currentPreferences.copyWith(trafficAlertsEnabled: value));
              } : null,
            ),
            
            // Emergency Alerts
            SwitchListTile(
              title: const Text('Emergency Alerts'),
              subtitle: const Text('High-priority voice notifications'),
              value: _currentPreferences.emergencyAlertsEnabled,
              onChanged: _currentPreferences.isEnabled ? (value) {
                _updatePreferences(_currentPreferences.copyWith(emergencyAlertsEnabled: value));
              } : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelection(ThemeData theme, EnhancedVoiceNavigationState voiceState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.language,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Language Settings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Language Dropdown
            DropdownButtonFormField<String>(
              value: _currentPreferences.language,
              decoration: const InputDecoration(
                labelText: 'Voice Language',
                border: OutlineInputBorder(),
              ),
              items: _getLanguageOptions().map((option) {
                return DropdownMenuItem<String>(
                  value: option['code'],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(option['displayName'] ?? ''),
                      if (option['nativeDisplayName'] != option['displayName'])
                        Text(
                          option['nativeDisplayName'] ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _currentPreferences.isEnabled ? (value) {
                if (value != null) {
                  _updatePreferences(_currentPreferences.copyWith(language: value));
                }
              } : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioControls(ThemeData theme, EnhancedVoiceNavigationState voiceState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.volume_up,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Audio Controls',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Volume Slider
            Text('Volume: ${(_currentPreferences.volume * 100).round()}%'),
            Slider(
              value: _currentPreferences.volume,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              onChanged: _currentPreferences.isEnabled ? (value) {
                _updatePreferences(_currentPreferences.copyWith(volume: value));
              } : null,
            ),
            
            const SizedBox(height: 16),
            
            // Speech Rate Slider
            Text('Speech Rate: ${(_currentPreferences.speechRate * 100).round()}%'),
            Slider(
              value: _currentPreferences.speechRate,
              min: 0.1,
              max: 2.0,
              divisions: 19,
              onChanged: _currentPreferences.isEnabled ? (value) {
                _updatePreferences(_currentPreferences.copyWith(speechRate: value));
              } : null,
            ),
            
            const SizedBox(height: 16),
            
            // Pitch Slider
            Text('Pitch: ${(_currentPreferences.pitch * 100).round()}%'),
            Slider(
              value: _currentPreferences.pitch,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              onChanged: _currentPreferences.isEnabled ? (value) {
                _updatePreferences(_currentPreferences.copyWith(pitch: value));
              } : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettings(ThemeData theme, EnhancedVoiceNavigationState voiceState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_applications,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Advanced Settings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Battery Optimization
            SwitchListTile(
              title: const Text('Battery Optimization'),
              subtitle: const Text('Reduce battery usage during long navigation'),
              value: _currentPreferences.batteryOptimizationEnabled,
              onChanged: (value) {
                _updatePreferences(_currentPreferences.copyWith(batteryOptimizationEnabled: value));
              },
            ),
            
            // Haptic Feedback
            SwitchListTile(
              title: const Text('Haptic Feedback'),
              subtitle: const Text('Vibration feedback for voice commands'),
              value: _currentPreferences.hapticFeedbackEnabled,
              onChanged: (value) {
                _updatePreferences(_currentPreferences.copyWith(hapticFeedbackEnabled: value));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestVoiceButton(ThemeData theme, EnhancedVoiceNavigationState voiceState) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: voiceState.isInitialized && _currentPreferences.isEnabled
            ? () => _testVoice()
            : null,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Test Voice'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  List<Map<String, String>> _getLanguageOptions() {
    return [
      {
        'code': 'en-MY',
        'displayName': 'English (Malaysia)',
        'nativeDisplayName': 'English (Malaysia)',
      },
      {
        'code': 'ms-MY',
        'displayName': 'Malay (Malaysia)',
        'nativeDisplayName': 'Bahasa Melayu (Malaysia)',
      },
      {
        'code': 'zh-CN',
        'displayName': 'Chinese (Simplified)',
        'nativeDisplayName': '中文 (简体)',
      },
      {
        'code': 'ta-MY',
        'displayName': 'Tamil (Malaysia)',
        'nativeDisplayName': 'தமிழ் (மலேசியா)',
      },
    ];
  }

  void _testVoice() {
    ref.read(enhancedVoiceNavigationProvider.notifier).testVoice();
  }
}
