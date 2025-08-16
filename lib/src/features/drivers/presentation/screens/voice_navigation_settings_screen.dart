import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../data/models/user_role.dart';
import '../providers/enhanced_voice_navigation_provider.dart';

import '../../data/models/traffic_models.dart';


/// Voice navigation settings screen for Phase 4.1
/// Provides comprehensive voice guidance configuration with multi-language support,
/// battery optimization, and traffic alert preferences
class VoiceNavigationSettingsScreen extends ConsumerStatefulWidget {
  const VoiceNavigationSettingsScreen({super.key});

  @override
  ConsumerState<VoiceNavigationSettingsScreen> createState() => _VoiceNavigationSettingsScreenState();
}

class _VoiceNavigationSettingsScreenState extends ConsumerState<VoiceNavigationSettingsScreen> {
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _initializeVoiceNavigation();
  }

  Future<void> _initializeVoiceNavigation() async {
    if (_isInitializing) return;
    
    setState(() {
      _isInitializing = true;
    });

    try {
      final voiceNotifier = ref.read(enhancedVoiceNavigationProvider.notifier);
      await voiceNotifier.initialize();
    } catch (e) {
      debugPrint('❌ [VOICE-SETTINGS] Error initializing: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final voiceState = ref.watch(enhancedVoiceNavigationProvider);

    // Check authentication and role
    if (authState.user == null || 
        (authState.user!.role != UserRole.driver && authState.user!.role != UserRole.admin)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Voice Navigation Settings'),
        ),
        body: const Center(
          child: Text('Access denied. Driver role required.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Navigation Settings'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          // Test voice button
          if (voiceState.isInitialized)
            IconButton(
              icon: const Icon(Icons.volume_up),
              onPressed: _testVoice,
              tooltip: 'Test Voice',
            ),
        ],
      ),
      body: _isInitializing || voiceState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildSettingsContent(theme, voiceState),
    );
  }

  Widget _buildSettingsContent(ThemeData theme, EnhancedVoiceNavigationState voiceState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error display
          if (voiceState.error != null) ...[
            _buildErrorCard(theme, voiceState.error!),
            const SizedBox(height: 16),
          ],

          // Voice guidance toggle
          _buildVoiceGuidanceSection(theme, voiceState),
          const SizedBox(height: 24),

          // Language settings
          _buildLanguageSection(theme, voiceState),
          const SizedBox(height: 24),

          // Audio settings
          _buildAudioSection(theme, voiceState),
          const SizedBox(height: 24),

          // Battery optimization
          _buildBatteryOptimizationSection(theme, voiceState),
          const SizedBox(height: 24),

          // Traffic alerts
          _buildTrafficAlertsSection(theme, voiceState),
          const SizedBox(height: 24),

          // Recent traffic alerts
          if (voiceState.recentTrafficAlerts.isNotEmpty) ...[
            _buildRecentAlertsSection(theme, voiceState),
            const SizedBox(height: 24),
          ],

          // Advanced settings
          _buildAdvancedSection(theme, voiceState),
        ],
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme, String error) {
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceGuidanceSection(ThemeData theme, EnhancedVoiceNavigationState voiceState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voice Guidance',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Voice Navigation'),
              subtitle: const Text('Turn-by-turn voice instructions'),
              value: voiceState.isEnabled,
              onChanged: voiceState.isInitialized ? (value) => _toggleVoiceGuidance() : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSection(ThemeData theme, EnhancedVoiceNavigationState voiceState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Language Settings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: voiceState.currentLanguage,
              decoration: const InputDecoration(
                labelText: 'Voice Language',
                border: OutlineInputBorder(),
              ),
              items: _getLanguageOptions(),
              onChanged: voiceState.isInitialized ? (value) {
                if (value != null) _changeLanguage(value);
              } : null,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose your preferred language for voice instructions',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioSection(ThemeData theme, EnhancedVoiceNavigationState voiceState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audio Settings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Volume slider
            Text('Volume: ${(voiceState.volume * 100).round()}%'),
            Slider(
              value: voiceState.volume,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              onChanged: voiceState.isInitialized ? (value) => _setVolume(value) : null,
            ),
            
            const SizedBox(height: 16),
            
            // Speech rate slider
            Text('Speech Rate: ${(voiceState.speechRate * 100).round()}%'),
            Slider(
              value: voiceState.speechRate,
              min: 0.5,
              max: 1.5,
              divisions: 10,
              onChanged: voiceState.isInitialized ? (value) => _setSpeechRate(value) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatteryOptimizationSection(ThemeData theme, EnhancedVoiceNavigationState voiceState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Battery Optimization',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Automatically reduces voice activity when not needed to save battery',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.battery_saver,
                  color: voiceState.batteryOptimizationEnabled 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.outline,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    voiceState.batteryOptimizationEnabled 
                        ? 'Battery optimization enabled'
                        : 'Battery optimization disabled',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrafficAlertsSection(ThemeData theme, EnhancedVoiceNavigationState voiceState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Traffic Alerts',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Voice announcements for traffic conditions and route changes',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.traffic,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Traffic alerts enabled with voice guidance',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAlertsSection(ThemeData theme, EnhancedVoiceNavigationState voiceState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent Traffic Alerts',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _clearTrafficAlerts,
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...voiceState.recentTrafficAlerts.take(5).map((alert) => 
              _buildTrafficAlertItem(theme, alert)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrafficAlertItem(ThemeData theme, TrafficAlert alert) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            _getSeverityIcon(alert.severity),
            color: _getSeverityColor(alert.severity),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              alert.message,
              style: theme.textTheme.bodySmall,
            ),
          ),
          Text(
            _formatTime(alert.timestamp),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSection(ThemeData theme, EnhancedVoiceNavigationState voiceState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Settings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.volume_up),
              title: const Text('Test Voice'),
              subtitle: const Text('Play a sample voice announcement'),
              onTap: voiceState.isInitialized ? _testVoice : null,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Voice Status'),
              subtitle: Text(
                voiceState.isInitialized 
                    ? 'Voice navigation ready (${voiceState.currentLanguage})'
                    : 'Voice navigation not initialized',
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _getLanguageOptions() {
    return [
      const DropdownMenuItem(value: 'en-MY', child: Text('English (Malaysia)')),
      const DropdownMenuItem(value: 'ms-MY', child: Text('Bahasa Malaysia')),
      const DropdownMenuItem(value: 'zh-CN', child: Text('中文 (Chinese)')),
      const DropdownMenuItem(value: 'ta-MY', child: Text('தமிழ் (Tamil)')),
    ];
  }

  IconData _getSeverityIcon(TrafficSeverity severity) {
    switch (severity) {
      case TrafficSeverity.low:
        return Icons.info_outline;
      case TrafficSeverity.medium:
        return Icons.warning_amber_outlined;
      case TrafficSeverity.high:
        return Icons.warning;
      case TrafficSeverity.critical:
        return Icons.error;
    }
  }

  Color _getSeverityColor(TrafficSeverity severity) {
    switch (severity) {
      case TrafficSeverity.low:
        return Colors.blue;
      case TrafficSeverity.medium:
        return Colors.orange;
      case TrafficSeverity.high:
        return Colors.red;
      case TrafficSeverity.critical:
        return Colors.red.shade900;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }

  void _toggleVoiceGuidance() {
    final voiceNotifier = ref.read(enhancedVoiceNavigationProvider.notifier);
    voiceNotifier.toggleVoiceGuidance();
  }

  void _changeLanguage(String language) {
    final voiceNotifier = ref.read(enhancedVoiceNavigationProvider.notifier);
    voiceNotifier.setLanguage(language);
  }

  void _setVolume(double volume) {
    final voiceNotifier = ref.read(enhancedVoiceNavigationProvider.notifier);
    voiceNotifier.setVolume(volume);
  }

  void _setSpeechRate(double rate) {
    final voiceNotifier = ref.read(enhancedVoiceNavigationProvider.notifier);
    voiceNotifier.setSpeechRate(rate);
  }

  void _testVoice() {
    final voiceNotifier = ref.read(enhancedVoiceNavigationProvider.notifier);
    voiceNotifier.testVoice();
  }

  void _clearTrafficAlerts() {
    final voiceNotifier = ref.read(enhancedVoiceNavigationProvider.notifier);
    voiceNotifier.clearTrafficAlerts();
  }
}
