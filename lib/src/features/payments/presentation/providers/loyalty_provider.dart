import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loyalty points state
class LoyaltyState {
  final int points;
  final List<LoyaltyTransaction> transactions;
  final bool isLoading;
  final String? errorMessage;

  const LoyaltyState({
    this.points = 0,
    this.transactions = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  LoyaltyState copyWith({
    int? points,
    List<LoyaltyTransaction>? transactions,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LoyaltyState(
      points: points ?? this.points,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Loyalty transaction model
class LoyaltyTransaction {
  final String id;
  final int points;
  final String type; // 'earned' or 'redeemed'
  final String description;
  final DateTime timestamp;

  const LoyaltyTransaction({
    required this.id,
    required this.points,
    required this.type,
    required this.description,
    required this.timestamp,
  });
}

/// Loyalty provider
final loyaltyProvider = StateNotifierProvider<LoyaltyNotifier, LoyaltyState>((ref) {
  return LoyaltyNotifier();
});

/// Loyalty notifier
class LoyaltyNotifier extends StateNotifier<LoyaltyState> {
  LoyaltyNotifier() : super(const LoyaltyState());

  /// Load loyalty points and transactions
  Future<void> loadLoyaltyData(String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      // In a real app, this would fetch from repository
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock data
      const points = 1250;
      final transactions = [
        LoyaltyTransaction(
          id: '1',
          points: 50,
          type: 'earned',
          description: 'Order #1001 - RM50.00',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
        LoyaltyTransaction(
          id: '2',
          points: -100,
          type: 'redeemed',
          description: 'Discount applied',
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];
      
      state = state.copyWith(
        points: points,
        transactions: transactions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Redeem points
  Future<bool> redeemPoints(int pointsToRedeem) async {
    if (pointsToRedeem > state.points) {
      state = state.copyWith(errorMessage: 'Insufficient points');
      return false;
    }

    try {
      // In a real app, this would call the backend
      await Future.delayed(const Duration(seconds: 1));
      
      final newTransaction = LoyaltyTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        points: -pointsToRedeem,
        type: 'redeemed',
        description: 'Points redeemed',
        timestamp: DateTime.now(),
      );
      
      state = state.copyWith(
        points: state.points - pointsToRedeem,
        transactions: [newTransaction, ...state.transactions],
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Add points (called when order is completed)
  void addPoints(int points, String description) {
    final newTransaction = LoyaltyTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      points: points,
      type: 'earned',
      description: description,
      timestamp: DateTime.now(),
    );
    
    state = state.copyWith(
      points: state.points + points,
      transactions: [newTransaction, ...state.transactions],
    );
  }
}
