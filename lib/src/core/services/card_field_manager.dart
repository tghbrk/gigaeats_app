import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

/// Global CardField manager to prevent platform view conflicts
/// 
/// This singleton ensures only one Stripe CardField instance exists at a time,
/// preventing the Android platform view conflict that occurs when multiple
/// CardField instances are created simultaneously during navigation.
class CardFieldManager {
  static final CardFieldManager _instance = CardFieldManager._internal();
  factory CardFieldManager() => _instance;
  CardFieldManager._internal();

  final AppLogger _logger = AppLogger();
  
  // Track the currently active CardField
  String? _activeCardFieldId;
  bool _isCardFieldActive = false;
  
  // Callbacks for cleanup
  final Map<String, VoidCallback> _cleanupCallbacks = {};

  /// Request permission to create a CardField
  /// Returns true if permission is granted, false if another CardField is active
  bool requestCardFieldPermission(String screenId) {
    _logger.debug('🔐 [CARD-FIELD-MANAGER] Permission requested by: $screenId');
    
    if (_isCardFieldActive && _activeCardFieldId != screenId) {
      _logger.warning('❌ [CARD-FIELD-MANAGER] Permission denied - CardField already active: $_activeCardFieldId');
      return false;
    }
    
    _activeCardFieldId = screenId;
    _isCardFieldActive = true;
    _logger.info('✅ [CARD-FIELD-MANAGER] Permission granted to: $screenId');
    return true;
  }

  /// Release CardField permission
  void releaseCardFieldPermission(String screenId) {
    _logger.debug('🔓 [CARD-FIELD-MANAGER] Permission release requested by: $screenId');
    
    if (_activeCardFieldId == screenId) {
      // Execute cleanup callback if exists
      final cleanup = _cleanupCallbacks[screenId];
      if (cleanup != null) {
        _logger.debug('🧹 [CARD-FIELD-MANAGER] Executing cleanup for: $screenId');
        cleanup();
        _cleanupCallbacks.remove(screenId);
      }
      
      _activeCardFieldId = null;
      _isCardFieldActive = false;
      _logger.info('✅ [CARD-FIELD-MANAGER] Permission released by: $screenId');
    } else {
      _logger.warning('⚠️ [CARD-FIELD-MANAGER] Release ignored - not the active CardField: $screenId (active: $_activeCardFieldId)');
    }
  }

  /// Force release all CardField permissions (emergency cleanup)
  void forceReleaseAll() {
    _logger.warning('🚨 [CARD-FIELD-MANAGER] Force releasing all CardField permissions');

    // Execute all cleanup callbacks
    for (final entry in _cleanupCallbacks.entries) {
      _logger.debug('🧹 [CARD-FIELD-MANAGER] Force cleanup for: ${entry.key}');
      entry.value();
    }

    _cleanupCallbacks.clear();
    _activeCardFieldId = null;
    _isCardFieldActive = false;
    _logger.info('✅ [CARD-FIELD-MANAGER] All permissions force released');
  }

  /// Transfer CardField permission from one screen to another
  /// This is useful for navigation scenarios where a new screen needs CardField access
  bool transferCardFieldPermission(String fromScreenId, String toScreenId) {
    _logger.debug('🔄 [CARD-FIELD-MANAGER] Permission transfer requested: $fromScreenId → $toScreenId');

    if (_activeCardFieldId != fromScreenId) {
      _logger.warning('⚠️ [CARD-FIELD-MANAGER] Transfer denied - $fromScreenId is not the active CardField (active: $_activeCardFieldId)');
      return false;
    }

    // Execute cleanup for the source screen
    final cleanup = _cleanupCallbacks[fromScreenId];
    if (cleanup != null) {
      _logger.debug('🧹 [CARD-FIELD-MANAGER] Executing cleanup for source screen: $fromScreenId');
      cleanup();
      _cleanupCallbacks.remove(fromScreenId);
    }

    // Transfer permission to new screen
    _activeCardFieldId = toScreenId;
    _logger.info('✅ [CARD-FIELD-MANAGER] Permission transferred: $fromScreenId → $toScreenId');
    return true;
  }

  /// Request CardField permission with automatic cleanup of conflicting screens
  /// This is more aggressive than regular requestCardFieldPermission
  bool requestCardFieldPermissionWithCleanup(String screenId) {
    _logger.debug('🔐 [CARD-FIELD-MANAGER] Permission with cleanup requested by: $screenId');

    if (_isCardFieldActive && _activeCardFieldId != screenId) {
      _logger.info('🧹 [CARD-FIELD-MANAGER] Auto-cleaning up conflicting CardField: $_activeCardFieldId');

      // Force cleanup of the current active CardField
      final cleanup = _cleanupCallbacks[_activeCardFieldId!];
      if (cleanup != null) {
        _logger.debug('🧹 [CARD-FIELD-MANAGER] Executing cleanup for: $_activeCardFieldId');
        cleanup();
        _cleanupCallbacks.remove(_activeCardFieldId!);
      }
    }

    // Grant permission to new screen
    _activeCardFieldId = screenId;
    _isCardFieldActive = true;
    _logger.info('✅ [CARD-FIELD-MANAGER] Permission with cleanup granted to: $screenId');
    return true;
  }

  /// Register a cleanup callback for a CardField
  void registerCleanupCallback(String screenId, VoidCallback cleanup) {
    _cleanupCallbacks[screenId] = cleanup;
    _logger.debug('📝 [CARD-FIELD-MANAGER] Cleanup callback registered for: $screenId');
  }

  /// Check if a specific screen has CardField permission
  bool hasPermission(String screenId) {
    return _activeCardFieldId == screenId && _isCardFieldActive;
  }

  /// Get the currently active CardField screen ID
  String? get activeCardFieldId => _activeCardFieldId;

  /// Check if any CardField is currently active
  bool get isCardFieldActive => _isCardFieldActive;

  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'activeCardFieldId': _activeCardFieldId,
      'isCardFieldActive': _isCardFieldActive,
      'registeredCallbacks': _cleanupCallbacks.keys.toList(),
    };
  }
}
