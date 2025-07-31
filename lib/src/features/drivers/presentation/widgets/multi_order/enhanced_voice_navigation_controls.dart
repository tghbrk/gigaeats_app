import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/navigation_models.dart';
import '../../providers/enhanced_navigation_provider.dart';
import '../../providers/enhanced_voice_navigation_provider.dart';

/// Enhanced voice navigation controls widget with Phase 2 improvements
/// Provides comprehensive voice guidance controls with volume, language, and speech rate settings
class EnhancedVoiceNavigationControls extends ConsumerStatefulWidget {
  final bool showAdvancedControls;
  final VoidCallback? onToggleVoice;
  final Function(NavigationPreferences)? onPreferencesChanged;

  const EnhancedVoiceNavigationControls({
    super.key,
    this.showAdvancedControls = false,
    this.onToggleVoice,
    this.onPreferencesChanged,
  });

  @override
  ConsumerState<EnhancedVoiceNavigationControls> createState() => _EnhancedVoiceNavigationControlsState();
}

class _EnhancedVoiceNavigationControlsState extends ConsumerState<EnhancedVoiceNavigationControls>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    
    debugPrint('🔊 [VOICE-CONTROLS] Initializing enhanced voice navigation controls (Phase 2)');
    
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navState = ref.watch(enhancedNavigationProvider);
    final voiceState = ref.watch(enhancedVoiceNavigationProvider);

    if (!navState.isNavigating) {
      return const SizedBox.shrink();
    }

    debugPrint('🔊 [VOICE-CONTROLS] Building enhanced voice controls - Voice enabled: ${navState.isVoiceEnabled}');

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main voice toggle
            _buildMainVoiceToggle(theme, navState, voiceState),
            
            // Advanced controls (expandable)
            if (widget.showAdvancedControls) ...[
              const SizedBox(height: 12),
              _buildExpandToggle(theme),
              
              AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) {
                  return ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: _expandAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: _buildAdvancedControls(theme, navState, voiceState),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build main voice toggle control
  Widget _buildMainVoiceToggle(
    ThemeData theme,
    EnhancedNavigationState navState,
    EnhancedVoiceNavigationState voiceState,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: navState.isVoiceEnabled 
                ? theme.colorScheme.primary.withValues(alpha: 0.15)
                : theme.colorScheme.outline.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            navState.isVoiceEnabled ? Icons.volume_up : Icons.volume_off,
            color: navState.isVoiceEnabled 
                ? theme.colorScheme.primary 
                : theme.colorScheme.outline,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voice Navigation',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                navState.isVoiceEnabled 
                    ? 'Turn-by-turn voice guidance enabled'
                    : 'Voice guidance disabled',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: navState.isVoiceEnabled,
          onChanged: (value) {
            debugPrint('🔊 [VOICE-CONTROLS] Toggling voice guidance: $value');
            widget.onToggleVoice?.call();
          },
        ),
      ],
    );
  }

  /// Build expand/collapse toggle
  Widget _buildExpandToggle(ThemeData theme) {
    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
        
        if (_isExpanded) {
          _expandController.forward();
        } else {
          _expandController.reverse();
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(
              'Advanced Settings',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const Spacer(),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.expand_more,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build advanced voice controls
  Widget _buildAdvancedControls(
    ThemeData theme,
    EnhancedNavigationState navState,
    EnhancedVoiceNavigationState voiceState,
  ) {
    final preferences = navState.currentSession?.preferences ?? const NavigationPreferences();
    
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Volume control
          _buildVolumeControl(theme, preferences),
          
          const SizedBox(height: 16),
          
          // Language selection
          _buildLanguageSelection(theme, preferences),
          
          const SizedBox(height: 16),
          
          // Speech rate control
          _buildSpeechRateControl(theme, preferences),
          
          const SizedBox(height: 16),
          
          // Voice alerts toggle
          _buildVoiceAlertsToggle(theme, preferences),
        ],
      ),
    );
  }

  /// Build volume control slider
  Widget _buildVolumeControl(ThemeData theme, NavigationPreferences preferences) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.volume_up,
              size: 16,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 8),
            Text(
              'Volume',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${(preferences.voiceVolume * 100).round()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: preferences.voiceVolume,
          onChanged: (value) {
            _updatePreferences(preferences.copyWith(voiceVolume: value));
          },
          min: 0.0,
          max: 1.0,
          divisions: 10,
        ),
      ],
    );
  }

  /// Build language selection
  Widget _buildLanguageSelection(ThemeData theme, NavigationPreferences preferences) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.language,
              size: 16,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 8),
            Text(
              'Language',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: preferences.language,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [
            DropdownMenuItem(value: 'en-MY', child: Text('English (Malaysia)')),
            DropdownMenuItem(value: 'ms-MY', child: Text('Bahasa Malaysia')),
            DropdownMenuItem(value: 'zh-CN', child: Text('中文 (简体)')),
            DropdownMenuItem(value: 'ta-MY', child: Text('தமிழ்')),
          ],
          onChanged: (value) {
            if (value != null) {
              _updatePreferences(preferences.copyWith(language: value));
            }
          },
        ),
      ],
    );
  }

  /// Build speech rate control
  Widget _buildSpeechRateControl(ThemeData theme, NavigationPreferences preferences) {
    // Note: NavigationPreferences doesn't have speechRate, this is a placeholder
    const speechRate = 0.8; // Default value
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.speed,
              size: 16,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 8),
            Text(
              'Speech Rate',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${(speechRate * 100).round()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: speechRate,
          onChanged: (value) {
            // TODO: Implement speech rate update
            debugPrint('🔊 [VOICE-CONTROLS] Speech rate changed: $value');
          },
          min: 0.5,
          max: 2.0,
          divisions: 15,
        ),
      ],
    );
  }

  /// Build voice alerts toggle
  Widget _buildVoiceAlertsToggle(ThemeData theme, NavigationPreferences preferences) {
    return SwitchListTile(
      title: Text(
        'Traffic Alerts',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        'Announce traffic conditions and delays',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
      value: preferences.trafficAlertsEnabled,
      onChanged: (value) {
        _updatePreferences(preferences.copyWith(trafficAlertsEnabled: value));
      },
      secondary: Icon(
        Icons.traffic,
        color: theme.colorScheme.outline,
      ),
    );
  }

  /// Update navigation preferences
  void _updatePreferences(NavigationPreferences preferences) {
    debugPrint('🔊 [VOICE-CONTROLS] Updating navigation preferences');
    widget.onPreferencesChanged?.call(preferences);
  }
}
