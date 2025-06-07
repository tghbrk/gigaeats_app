import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/sales_agent_profile.dart';
import '../data/repositories/sales_agent_repository.dart';

/// State for sales agent profile
class SalesAgentProfileState {
  final SalesAgentProfile? profile;
  final bool isLoading;
  final String? error;

  const SalesAgentProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
  });

  SalesAgentProfileState copyWith({
    SalesAgentProfile? profile,
    bool? isLoading,
    String? error,
  }) {
    return SalesAgentProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Notifier for sales agent profile state
class SalesAgentProfileStateNotifier extends StateNotifier<SalesAgentProfileState> {
  final SalesAgentRepository _repository;

  SalesAgentProfileStateNotifier(this._repository) : super(const SalesAgentProfileState());

  Future<void> loadCurrentProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final profile = await _repository.getCurrentProfile();
      state = state.copyWith(
        profile: profile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void refresh() {
    loadCurrentProfile();
  }

  Future<void> updateProfile(SalesAgentProfile profile) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final updatedProfile = await _repository.updateSalesAgentProfile(profile);
      state = state.copyWith(
        profile: updatedProfile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

/// Provider for sales agent profile state
final salesAgentProfileStateProvider = StateNotifierProvider<SalesAgentProfileStateNotifier, SalesAgentProfileState>((ref) {
  final repository = SalesAgentRepository();
  return SalesAgentProfileStateNotifier(repository);
});
