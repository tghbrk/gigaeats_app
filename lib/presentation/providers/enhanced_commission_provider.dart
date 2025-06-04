import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/debug_logger.dart';
import 'enhanced_order_provider.dart';
import 'auth_provider.dart';

// Enhanced Commission Management with Real-time Tracking

// Commission Tier Model
class CommissionTier {
  final String id;
  final String salesAgentId;
  final String tierName;
  final int minOrders;
  final int? maxOrders;
  final double commissionRate;
  final DateTime validFrom;
  final DateTime? validUntil;
  final DateTime createdAt;

  CommissionTier({
    required this.id,
    required this.salesAgentId,
    required this.tierName,
    required this.minOrders,
    this.maxOrders,
    required this.commissionRate,
    required this.validFrom,
    this.validUntil,
    required this.createdAt,
  });

  factory CommissionTier.fromJson(Map<String, dynamic> json) {
    return CommissionTier(
      id: json['id'],
      salesAgentId: json['sales_agent_id'],
      tierName: json['tier_name'],
      minOrders: json['min_orders'],
      maxOrders: json['max_orders'],
      commissionRate: (json['commission_rate'] as num).toDouble(),
      validFrom: DateTime.parse(json['valid_from']),
      validUntil: json['valid_until'] != null ? DateTime.parse(json['valid_until']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sales_agent_id': salesAgentId,
    'tier_name': tierName,
    'min_orders': minOrders,
    'max_orders': maxOrders,
    'commission_rate': commissionRate,
    'valid_from': validFrom.toIso8601String(),
    'valid_until': validUntil?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };
}

// Commission Transaction Model
class CommissionTransaction {
  final String id;
  final String orderId;
  final String salesAgentId;
  final String? commissionTierId;
  final double orderAmount;
  final double commissionRate;
  final double commissionAmount;
  final double platformFee;
  final double netCommission;
  final String status;
  final String? payoutId;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommissionTransaction({
    required this.id,
    required this.orderId,
    required this.salesAgentId,
    this.commissionTierId,
    required this.orderAmount,
    required this.commissionRate,
    required this.commissionAmount,
    required this.platformFee,
    required this.netCommission,
    required this.status,
    this.payoutId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommissionTransaction.fromJson(Map<String, dynamic> json) {
    return CommissionTransaction(
      id: json['id'],
      orderId: json['order_id'],
      salesAgentId: json['sales_agent_id'],
      commissionTierId: json['commission_tier_id'],
      orderAmount: (json['order_amount'] as num).toDouble(),
      commissionRate: (json['commission_rate'] as num).toDouble(),
      commissionAmount: (json['commission_amount'] as num).toDouble(),
      platformFee: (json['platform_fee'] as num).toDouble(),
      netCommission: (json['net_commission'] as num).toDouble(),
      status: json['status'],
      payoutId: json['payout_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

// Commission Payout Model
class CommissionPayout {
  final String id;
  final String salesAgentId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double totalAmount;
  final int transactionCount;
  final String status;
  final String? payoutReference;
  final DateTime? payoutDate;
  final Map<String, dynamic>? bankDetails;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommissionPayout({
    required this.id,
    required this.salesAgentId,
    required this.periodStart,
    required this.periodEnd,
    required this.totalAmount,
    required this.transactionCount,
    required this.status,
    this.payoutReference,
    this.payoutDate,
    this.bankDetails,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommissionPayout.fromJson(Map<String, dynamic> json) {
    return CommissionPayout(
      id: json['id'],
      salesAgentId: json['sales_agent_id'],
      periodStart: DateTime.parse(json['period_start']),
      periodEnd: DateTime.parse(json['period_end']),
      totalAmount: (json['total_amount'] as num).toDouble(),
      transactionCount: json['transaction_count'],
      status: json['status'],
      payoutReference: json['payout_reference'],
      payoutDate: json['payout_date'] != null ? DateTime.parse(json['payout_date']) : null,
      bankDetails: json['bank_details'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

// Commission State
class CommissionState {
  final List<CommissionTransaction> transactions;
  final List<CommissionTier> tiers;
  final List<CommissionPayout> payouts;
  final bool isLoading;
  final String? errorMessage;
  final double totalEarnings;
  final double pendingCommissions;
  final double paidCommissions;

  CommissionState({
    this.transactions = const [],
    this.tiers = const [],
    this.payouts = const [],
    this.isLoading = false,
    this.errorMessage,
    this.totalEarnings = 0.0,
    this.pendingCommissions = 0.0,
    this.paidCommissions = 0.0,
  });

  CommissionState copyWith({
    List<CommissionTransaction>? transactions,
    List<CommissionTier>? tiers,
    List<CommissionPayout>? payouts,
    bool? isLoading,
    String? errorMessage,
    double? totalEarnings,
    double? pendingCommissions,
    double? paidCommissions,
  }) {
    return CommissionState(
      transactions: transactions ?? this.transactions,
      tiers: tiers ?? this.tiers,
      payouts: payouts ?? this.payouts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      pendingCommissions: pendingCommissions ?? this.pendingCommissions,
      paidCommissions: paidCommissions ?? this.paidCommissions,
    );
  }
}

// Enhanced Commission Notifier
class EnhancedCommissionNotifier extends StateNotifier<CommissionState> {
  final SupabaseClient _supabase;
  final Ref _ref;

  EnhancedCommissionNotifier(this._supabase, this._ref) : super(CommissionState());

  // Load commission data for sales agent (using real database)
  Future<void> loadCommissionData(String salesAgentId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      DebugLogger.info('Loading commission data for agent: $salesAgentId (from database)', tag: 'EnhancedCommissionNotifier');

      // Load commission transactions from database
      final transactionsResponse = await _supabase
          .from('commission_transactions')
          .select('*')
          .eq('sales_agent_id', salesAgentId)
          .order('created_at', ascending: false);

      final transactions = (transactionsResponse as List)
          .map((json) => CommissionTransaction.fromJson(json))
          .toList();

      // Load commission tiers from database
      final tiersResponse = await _supabase
          .from('commission_tiers')
          .select('*')
          .eq('sales_agent_id', salesAgentId)
          .order('created_at', ascending: false);

      final tiers = (tiersResponse as List)
          .map((json) => CommissionTier.fromJson(json))
          .toList();

      // Load commission payouts from database
      final payoutsResponse = await _supabase
          .from('commission_payouts')
          .select('*')
          .eq('sales_agent_id', salesAgentId)
          .order('created_at', ascending: false);

      final payouts = (payoutsResponse as List)
          .map((json) => CommissionPayout.fromJson(json))
          .toList();

      // Calculate totals
      final totalEarnings = transactions
          .where((t) => t.status == 'earned' || t.status == 'paid')
          .fold(0.0, (sum, t) => sum + t.netCommission);

      final pendingCommissions = transactions
          .where((t) => t.status == 'earned')
          .fold(0.0, (sum, t) => sum + t.netCommission);

      final paidCommissions = transactions
          .where((t) => t.status == 'paid')
          .fold(0.0, (sum, t) => sum + t.netCommission);

      state = state.copyWith(
        transactions: transactions,
        tiers: tiers,
        payouts: payouts,
        isLoading: false,
        totalEarnings: totalEarnings,
        pendingCommissions: pendingCommissions,
        paidCommissions: paidCommissions,
      );

      DebugLogger.success('Commission data loaded successfully: ${transactions.length} transactions, ${tiers.length} tiers, ${payouts.length} payouts', tag: 'EnhancedCommissionNotifier');

    } catch (e) {
      DebugLogger.error('Error loading commission data: $e', tag: 'EnhancedCommissionNotifier');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  // Create commission tier (using real database)
  Future<CommissionTier?> createCommissionTier({
    required String salesAgentId,
    required String tierName,
    required int minOrders,
    int? maxOrders,
    required double commissionRate,
    DateTime? validFrom,
    DateTime? validUntil,
  }) async {
    try {
      DebugLogger.info('Creating commission tier: $tierName (in database)', tag: 'EnhancedCommissionNotifier');

      // Prepare tier data for database
      final tierData = {
        'sales_agent_id': salesAgentId,
        'tier_name': tierName,
        'min_orders': minOrders,
        'max_orders': maxOrders,
        'commission_rate': commissionRate,
        'valid_from': (validFrom ?? DateTime.now()).toIso8601String(),
        'valid_until': validUntil?.toIso8601String(),
      };

      // Insert into database
      final response = await _supabase
          .from('commission_tiers')
          .insert(tierData)
          .select()
          .single();

      final tier = CommissionTier.fromJson(response);

      // Update local state
      final updatedTiers = [tier, ...state.tiers];
      state = state.copyWith(tiers: updatedTiers);

      DebugLogger.success('Commission tier created successfully: ${tier.id}', tag: 'EnhancedCommissionNotifier');
      return tier;

    } catch (e) {
      DebugLogger.error('Error creating commission tier: $e', tag: 'EnhancedCommissionNotifier');
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  // Request payout
  Future<CommissionPayout?> requestPayout({
    required String salesAgentId,
    required DateTime periodStart,
    required DateTime periodEnd,
    required Map<String, dynamic> bankDetails,
  }) async {
    try {
      DebugLogger.info('Requesting payout for period: $periodStart to $periodEnd', tag: 'EnhancedCommissionNotifier');

      // Calculate total amount from pending transactions
      final pendingTransactions = state.transactions
          .where((t) => t.status == 'earned' && 
                       t.createdAt.isAfter(periodStart) && 
                       t.createdAt.isBefore(periodEnd))
          .toList();

      final totalAmount = pendingTransactions
          .fold(0.0, (sum, t) => sum + t.netCommission);

      if (totalAmount <= 0) {
        throw Exception('No pending commissions for the selected period');
      }

      final payoutData = {
        'sales_agent_id': salesAgentId,
        'period_start': periodStart.toIso8601String(),
        'period_end': periodEnd.toIso8601String(),
        'total_amount': totalAmount,
        'transaction_count': pendingTransactions.length,
        'status': 'pending',
        'bank_details': bankDetails,
      };

      final response = await _supabase
          .from('commission_payouts')
          .insert(payoutData)
          .select()
          .single();

      final payout = CommissionPayout.fromJson(response);

      // Update local state
      final updatedPayouts = [payout, ...state.payouts];
      state = state.copyWith(payouts: updatedPayouts);

      DebugLogger.success('Payout requested: ${payout.id}', tag: 'EnhancedCommissionNotifier');
      return payout;

    } catch (e) {
      DebugLogger.error('Error requesting payout: $e', tag: 'EnhancedCommissionNotifier');
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  // Get current commission tier for sales agent
  CommissionTier? getCurrentTier(String salesAgentId) {
    final now = DateTime.now();
    return state.tiers
        .where((tier) => 
            tier.salesAgentId == salesAgentId &&
            tier.validFrom.isBefore(now) &&
            (tier.validUntil == null || tier.validUntil!.isAfter(now)))
        .fold<CommissionTier?>(null, (current, tier) {
          if (current == null) return tier;
          return tier.commissionRate > current.commissionRate ? tier : current;
        });
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }


}

// Enhanced Commission Provider
final enhancedCommissionProvider = StateNotifierProvider<EnhancedCommissionNotifier, CommissionState>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return EnhancedCommissionNotifier(supabase, ref);
});

// Commission Transactions Provider for specific sales agent
final commissionTransactionsProvider = FutureProvider.family<List<CommissionTransaction>, String>((ref, salesAgentId) async {
  final supabase = ref.watch(supabaseProvider);
  
  final response = await supabase
      .from('commission_transactions')
      .select('*')
      .eq('sales_agent_id', salesAgentId)
      .order('created_at', ascending: false);

  return (response as List)
      .map((json) => CommissionTransaction.fromJson(json))
      .toList();
});

// Commission Tiers Provider for specific sales agent
final commissionTiersProvider = FutureProvider.family<List<CommissionTier>, String>((ref, salesAgentId) async {
  final supabase = ref.watch(supabaseProvider);
  
  final response = await supabase
      .from('commission_tiers')
      .select('*')
      .eq('sales_agent_id', salesAgentId)
      .order('valid_from', ascending: false);

  return (response as List)
      .map((json) => CommissionTier.fromJson(json))
      .toList();
});

// Commission Payouts Provider for specific sales agent
final commissionPayoutsProvider = FutureProvider.family<List<CommissionPayout>, String>((ref, salesAgentId) async {
  final supabase = ref.watch(supabaseProvider);

  final response = await supabase
      .from('commission_payouts')
      .select('*')
      .eq('sales_agent_id', salesAgentId)
      .order('created_at', ascending: false);

  return (response as List)
      .map((json) => CommissionPayout.fromJson(json))
      .toList();
});

// Current Sales Agent Commission Rate Provider
final currentCommissionRateProvider = FutureProvider<double>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id;

  if (userId == null) {
    return 0.07; // Default 7% if not authenticated
  }

  try {
    // Get commission tiers for the current user
    final tiers = await ref.watch(commissionTiersProvider(userId).future);

    if (tiers.isEmpty) {
      return 0.07; // Default 7% if no tiers found
    }

    // Find the current active tier
    final now = DateTime.now();
    final activeTier = tiers
        .where((tier) =>
            tier.validFrom.isBefore(now) &&
            (tier.validUntil == null || tier.validUntil!.isAfter(now)))
        .fold<CommissionTier?>(null, (current, tier) {
          if (current == null) return tier;
          return tier.commissionRate > current.commissionRate ? tier : current;
        });

    return activeTier?.commissionRate ?? 0.07; // Default 7% if no active tier
  } catch (e) {
    DebugLogger.error('Error fetching commission rate: $e', tag: 'CurrentCommissionRateProvider');
    return 0.07; // Default 7% on error
  }
});
