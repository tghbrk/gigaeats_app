import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Temporary stub for sales agent notification settings
class SalesAgentNotificationCategory {
  final String id;
  final String name;
  final String description;

  const SalesAgentNotificationCategory({
    required this.id,
    required this.name,
    required this.description,
  });
}

class SalesAgentNotificationSettingsState {
  final bool isLoading;
  final String? error;
  final Map<String, bool> settings;

  const SalesAgentNotificationSettingsState({
    this.isLoading = false,
    this.error,
    this.settings = const {},
  });

  SalesAgentNotificationSettingsState copyWith({
    bool? isLoading,
    String? error,
    Map<String, bool>? settings,
  }) {
    return SalesAgentNotificationSettingsState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      settings: settings ?? this.settings,
    );
  }
}

class SalesAgentNotificationSettingsNotifier extends StateNotifier<SalesAgentNotificationSettingsState> {
  SalesAgentNotificationSettingsNotifier() : super(const SalesAgentNotificationSettingsState());

  void refresh() {
    // Stub implementation
  }

  void clearMessages() {
    // Stub implementation
  }

  Future<void> updateSetting(String key, bool value) async {
    // Stub implementation
  }
}

/// Provider for sales agent notification settings
final salesAgentNotificationSettingsProvider = StateNotifierProvider.family<
    SalesAgentNotificationSettingsNotifier,
    SalesAgentNotificationSettingsState,
    String>((ref, agentId) {
  return SalesAgentNotificationSettingsNotifier();
});
