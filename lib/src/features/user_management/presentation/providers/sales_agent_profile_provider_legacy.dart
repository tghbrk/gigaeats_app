import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/sales_agent_profile.dart';
// TODO: Restore when repository providers are implemented
// import '../../../presentation/providers/repository_providers.dart';

// TODO: Restore when salesAgentRepositoryProvider and SalesAgentProfileNotifier are implemented
// // Sales Agent Profile Provider
// final salesAgentProfileProvider = StateNotifierProvider<SalesAgentProfileNotifier, SalesAgentProfileState>((ref) {
//   final salesAgentRepository = ref.watch(salesAgentRepositoryProvider);
//   return SalesAgentProfileNotifier(salesAgentRepository);
// });

// Current Sales Agent Profile Provider
final currentSalesAgentProfileProvider = FutureProvider<SalesAgentProfile?>((ref) async {
  // TODO: Restore when salesAgentRepositoryProvider is implemented
  // final salesAgentRepository = ref.watch(salesAgentRepositoryProvider);
  try {
    // return await salesAgentRepository.getCurrentProfile();
    return null; // Placeholder until repository is implemented
  } catch (e) {
    return null;
  }
});

// Sales Agent Profile State
class SalesAgentProfileState {
  final SalesAgentProfile? profile;
  final bool isLoading;
  final String? errorMessage;

  const SalesAgentProfileState({
    this.profile,
    this.isLoading = false,
    this.errorMessage,
  });

  SalesAgentProfileState copyWith({
    SalesAgentProfile? profile,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SalesAgentProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Sales Agent Profile Notifier
class SalesAgentProfileNotifier extends StateNotifier<SalesAgentProfileState> {
  final dynamic salesAgentRepository;

  SalesAgentProfileNotifier(this.salesAgentRepository) : super(const SalesAgentProfileState());

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final profile = await salesAgentRepository.getCurrentProfile();
      state = state.copyWith(
        profile: profile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> updateProfile(SalesAgentProfile updatedProfile) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final profile = await salesAgentRepository.updateProfile(updatedProfile);
      state = state.copyWith(
        profile: profile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
