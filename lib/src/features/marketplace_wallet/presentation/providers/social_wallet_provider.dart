import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/social_wallet.dart';
import '../../data/services/social_wallet_service.dart';

/// Provider for social wallet service
final socialWalletServiceProvider = Provider<SocialWalletService>((ref) {
  return SocialWalletService();
});

/// Enhanced error types for better error handling
enum SocialWalletErrorType {
  network,
  authentication,
  authorization,
  validation,
  serverError,
  unknown,
}

/// Enhanced error class for Social Wallet operations
class SocialWalletError {
  final SocialWalletErrorType type;
  final String message;
  final String? details;
  final bool isRetryable;
  final DateTime timestamp;

  const SocialWalletError({
    required this.type,
    required this.message,
    this.details,
    this.isRetryable = true,
    required this.timestamp,
  });

  factory SocialWalletError.fromException(dynamic exception) {
    final now = DateTime.now();
    final errorMessage = exception.toString();

    if (errorMessage.contains('Unauthorized') || errorMessage.contains('authentication')) {
      return SocialWalletError(
        type: SocialWalletErrorType.authentication,
        message: 'Authentication required. Please sign in again.',
        details: errorMessage,
        isRetryable: false,
        timestamp: now,
      );
    } else if (errorMessage.contains('Access denied') || errorMessage.contains('permission')) {
      return SocialWalletError(
        type: SocialWalletErrorType.authorization,
        message: 'You don\'t have permission to perform this action.',
        details: errorMessage,
        isRetryable: false,
        timestamp: now,
      );
    } else if (errorMessage.contains('required') || errorMessage.contains('invalid')) {
      return SocialWalletError(
        type: SocialWalletErrorType.validation,
        message: 'Please check your input and try again.',
        details: errorMessage,
        isRetryable: false,
        timestamp: now,
      );
    } else if (errorMessage.contains('network') || errorMessage.contains('connection')) {
      return SocialWalletError(
        type: SocialWalletErrorType.network,
        message: 'Network connection error. Please check your internet connection.',
        details: errorMessage,
        isRetryable: true,
        timestamp: now,
      );
    } else if (errorMessage.contains('server') || errorMessage.contains('500')) {
      return SocialWalletError(
        type: SocialWalletErrorType.serverError,
        message: 'Server error. Please try again later.',
        details: errorMessage,
        isRetryable: true,
        timestamp: now,
      );
    } else {
      return SocialWalletError(
        type: SocialWalletErrorType.unknown,
        message: 'An unexpected error occurred. Please try again.',
        details: errorMessage,
        isRetryable: true,
        timestamp: now,
      );
    }
  }

  String get userFriendlyMessage => message;
}

/// Enhanced state class for social wallet with better error handling
class SocialWalletState {
  final bool isLoading;
  final bool isGroupsLoading;
  final bool isBillsLoading;
  final bool isRequestsLoading;
  final SocialWalletError? error;
  final List<PaymentGroup> groups;
  final List<BillSplit> billSplits;
  final List<PaymentRequest> paymentRequests;
  final PaymentGroup? selectedGroup;
  final BillSplit? selectedBillSplit;
  final int retryCount;
  final DateTime? lastRefreshTime;

  const SocialWalletState({
    this.isLoading = false,
    this.isGroupsLoading = false,
    this.isBillsLoading = false,
    this.isRequestsLoading = false,
    this.error,
    this.groups = const [],
    this.billSplits = const [],
    this.paymentRequests = const [],
    this.selectedGroup,
    this.selectedBillSplit,
    this.retryCount = 0,
    this.lastRefreshTime,
  });

  // Backward compatibility
  String? get errorMessage => error?.userFriendlyMessage;

  SocialWalletState copyWith({
    bool? isLoading,
    bool? isGroupsLoading,
    bool? isBillsLoading,
    bool? isRequestsLoading,
    SocialWalletError? error,
    bool clearError = false,
    List<PaymentGroup>? groups,
    List<BillSplit>? billSplits,
    List<PaymentRequest>? paymentRequests,
    PaymentGroup? selectedGroup,
    BillSplit? selectedBillSplit,
    int? retryCount,
    DateTime? lastRefreshTime,
  }) {
    return SocialWalletState(
      isLoading: isLoading ?? this.isLoading,
      isGroupsLoading: isGroupsLoading ?? this.isGroupsLoading,
      isBillsLoading: isBillsLoading ?? this.isBillsLoading,
      isRequestsLoading: isRequestsLoading ?? this.isRequestsLoading,
      error: clearError ? null : (error ?? this.error),
      groups: groups ?? this.groups,
      billSplits: billSplits ?? this.billSplits,
      paymentRequests: paymentRequests ?? this.paymentRequests,
      selectedGroup: selectedGroup ?? this.selectedGroup,
      selectedBillSplit: selectedBillSplit ?? this.selectedBillSplit,
      retryCount: retryCount ?? this.retryCount,
      lastRefreshTime: lastRefreshTime ?? this.lastRefreshTime,
    );
  }
}

/// Notifier for social wallet
class SocialWalletNotifier extends StateNotifier<SocialWalletState> {
  final SocialWalletService _socialWalletService;
  final Ref _ref;

  // Debounce mechanism to prevent rapid successive calls
  DateTime? _lastRefreshTime;
  static const Duration _debounceDelay = Duration(milliseconds: 500);

  SocialWalletNotifier(this._socialWalletService, this._ref)
      : super(const SocialWalletState());

  /// Load user's payment groups with enhanced error handling
  Future<void> loadUserGroups() async {
    debugPrint('🔍 [SOCIAL-WALLET-PROVIDER] loadUserGroups() called');

    // Prevent multiple simultaneous calls
    if (state.isGroupsLoading) {
      debugPrint('🔍 [SOCIAL-WALLET-PROVIDER] Already loading groups, skipping duplicate call');
      return;
    }

    state = state.copyWith(isGroupsLoading: true, clearError: true);

    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      debugPrint('🔍 [SOCIAL-WALLET-PROVIDER] Auth state: ${authState.status}');
      debugPrint('🔍 [SOCIAL-WALLET-PROVIDER] User: ${user?.email ?? 'null'}');

      if (user == null) {
        debugPrint('❌ [SOCIAL-WALLET-PROVIDER] User not authenticated');
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [SOCIAL-WALLET-PROVIDER] Calling getUserGroups for user: ${user.id}');
      final groups = await _socialWalletService.getUserGroups(user.id);

      debugPrint('✅ [SOCIAL-WALLET-PROVIDER] Successfully loaded ${groups.length} groups');
      state = state.copyWith(
        isGroupsLoading: false,
        groups: groups,
        retryCount: 0,
        lastRefreshTime: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ [SOCIAL-WALLET-PROVIDER] Error loading groups: $e');
      debugPrint('❌ [SOCIAL-WALLET-PROVIDER] Error type: ${e.runtimeType}');
      state = state.copyWith(
        isGroupsLoading: false,
        error: SocialWalletError.fromException(e),
        retryCount: state.retryCount + 1,
      );
    }
  }

  /// Create a new payment group with enhanced error handling
  Future<void> createGroup({
    required String name,
    required String description,
    required GroupType type,
    required List<String> memberEmails,
    GroupSettings? settings,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final newGroup = await _socialWalletService.createGroup(
        userId: user.id,
        name: name,
        description: description,
        type: type,
        memberEmails: memberEmails,
        settings: settings,
      );

      // Add the new group to the list
      final updatedGroups = [newGroup, ...state.groups];

      state = state.copyWith(
        isLoading: false,
        groups: updatedGroups,
        selectedGroup: newGroup,
        retryCount: 0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: SocialWalletError.fromException(e),
        retryCount: state.retryCount + 1,
      );
      rethrow;
    }
  }

  /// Update payment group with enhanced error handling
  Future<void> updateGroup({
    required String groupId,
    String? name,
    String? description,
    GroupSettings? settings,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final updatedGroup = await _socialWalletService.updateGroup(
        groupId: groupId,
        userId: user.id,
        name: name,
        description: description,
        settings: settings,
      );

      // Update the group in the list
      final updatedGroups = state.groups.map((group) {
        return group.id == groupId ? updatedGroup : group;
      }).toList();

      state = state.copyWith(
        isLoading: false,
        groups: updatedGroups,
        selectedGroup: state.selectedGroup?.id == groupId ? updatedGroup : state.selectedGroup,
        retryCount: 0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: SocialWalletError.fromException(e),
        retryCount: state.retryCount + 1,
      );
      rethrow;
    }
  }

  /// Add members to group with enhanced error handling
  Future<void> addMembersToGroup({
    required String groupId,
    required List<String> memberEmails,
  }) async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _socialWalletService.addMembersToGroup(
        groupId: groupId,
        userId: user.id,
        memberEmails: memberEmails,
      );

      // Reload groups to get updated member list
      await loadUserGroups();
    } catch (e) {
      state = state.copyWith(error: SocialWalletError.fromException(e));
      rethrow;
    }
  }

  /// Remove member from group with enhanced error handling
  Future<void> removeMemberFromGroup({
    required String groupId,
    required String memberUserId,
  }) async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _socialWalletService.removeMemberFromGroup(
        groupId: groupId,
        userId: user.id,
        memberUserId: memberUserId,
      );

      // Reload groups to get updated member list
      await loadUserGroups();
    } catch (e) {
      state = state.copyWith(error: SocialWalletError.fromException(e));
      rethrow;
    }
  }

  /// Create bill split with enhanced error handling
  Future<void> createBillSplit({
    required String groupId,
    required String title,
    required String description,
    required double totalAmount,
    required SplitMethod splitMethod,
    required List<Map<String, dynamic>> participants,
    String? receiptImageUrl,
    String? category,
    DateTime? transactionDate,
  }) async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final newBillSplit = await _socialWalletService.createBillSplit(
        groupId: groupId,
        userId: user.id,
        title: title,
        description: description,
        totalAmount: totalAmount,
        splitMethod: splitMethod,
        participants: participants,
        receiptImageUrl: receiptImageUrl,
        category: category,
        transactionDate: transactionDate,
      );

      // Add the new bill split to the list
      final updatedBillSplits = [newBillSplit, ...state.billSplits];

      state = state.copyWith(
        billSplits: updatedBillSplits,
        selectedBillSplit: newBillSplit,
      );
    } catch (e) {
      state = state.copyWith(error: SocialWalletError.fromException(e));
      rethrow;
    }
  }

  /// Load group bill splits with enhanced error handling
  Future<void> loadGroupBillSplits({
    required String groupId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(isBillsLoading: true, clearError: true);

    try {
      final billSplits = await _socialWalletService.getGroupBillSplits(
        groupId: groupId,
        limit: limit,
        startDate: startDate,
        endDate: endDate,
      );

      state = state.copyWith(
        isBillsLoading: false,
        billSplits: billSplits,
        retryCount: 0,
      );
    } catch (e) {
      state = state.copyWith(
        isBillsLoading: false,
        error: SocialWalletError.fromException(e),
        retryCount: state.retryCount + 1,
      );
    }
  }

  /// Mark bill split participant as paid with enhanced error handling
  Future<void> markBillSplitAsPaid({
    required String billSplitId,
    required String participantUserId,
    required String paymentTransactionId,
  }) async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _socialWalletService.markBillSplitAsPaid(
        billSplitId: billSplitId,
        userId: user.id,
        participantUserId: participantUserId,
        paymentTransactionId: paymentTransactionId,
      );

      // Reload bill splits to get updated status
      if (state.selectedGroup != null) {
        await loadGroupBillSplits(groupId: state.selectedGroup!.id);
      }
    } catch (e) {
      state = state.copyWith(error: SocialWalletError.fromException(e));
      rethrow;
    }
  }

  /// Create payment request with enhanced error handling
  Future<void> createPaymentRequest({
    required String toUserId,
    required double amount,
    required String title,
    String? description,
    String? groupId,
    String? billSplitId,
    DateTime? dueDate,
  }) async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final newRequest = await _socialWalletService.createPaymentRequest(
        fromUserId: user.id,
        toUserId: toUserId,
        amount: amount,
        title: title,
        description: description,
        groupId: groupId,
        billSplitId: billSplitId,
        dueDate: dueDate,
      );

      // Add the new request to the list
      final updatedRequests = [newRequest, ...state.paymentRequests];

      state = state.copyWith(paymentRequests: updatedRequests);
    } catch (e) {
      state = state.copyWith(error: SocialWalletError.fromException(e));
      rethrow;
    }
  }

  /// Load user payment requests
  Future<void> loadPaymentRequests({
    bool? incoming,
    PaymentRequestStatus? status,
    int? limit,
  }) async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        debugPrint('❌ [SOCIAL-WALLET-PROVIDER] User not authenticated for payment requests');
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [SOCIAL-WALLET-PROVIDER] Loading payment requests for user: ${user.id}');
      final requests = await _socialWalletService.getUserPaymentRequests(
        userId: user.id,
        incoming: incoming,
        status: status,
        limit: limit,
      );

      debugPrint('✅ [SOCIAL-WALLET-PROVIDER] Successfully loaded ${requests.length} payment requests');
      state = state.copyWith(paymentRequests: requests);
    } catch (e) {
      debugPrint('❌ [SOCIAL-WALLET-PROVIDER] Error loading payment requests: $e');
      state = state.copyWith(error: SocialWalletError.fromException(e));
    }
  }

  /// Respond to payment request
  Future<void> respondToPaymentRequest({
    required String requestId,
    required PaymentRequestStatus status,
    String? responseMessage,
  }) async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _socialWalletService.respondToPaymentRequest(
        requestId: requestId,
        userId: user.id,
        status: status,
        responseMessage: responseMessage,
      );

      // Reload payment requests to get updated status
      await loadPaymentRequests();
    } catch (e) {
      state = state.copyWith(error: SocialWalletError.fromException(e));
      rethrow;
    }
  }

  /// Send payment reminder
  Future<void> sendPaymentReminder({
    required String requestId,
    String? customMessage,
  }) async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _socialWalletService.sendPaymentReminder(
        requestId: requestId,
        userId: user.id,
        customMessage: customMessage,
      );
    } catch (e) {
      state = state.copyWith(error: SocialWalletError.fromException(e));
      rethrow;
    }
  }

  /// Select a group
  void selectGroup(PaymentGroup group) {
    state = state.copyWith(selectedGroup: group);
    // Load bill splits for the selected group
    loadGroupBillSplits(groupId: group.id);
  }

  /// Clear selected group
  void clearSelectedGroup() {
    state = state.copyWith(selectedGroup: null, billSplits: []);
  }

  /// Select a bill split
  void selectBillSplit(BillSplit billSplit) {
    state = state.copyWith(selectedBillSplit: billSplit);
  }

  /// Clear selected bill split
  void clearSelectedBillSplit() {
    state = state.copyWith(selectedBillSplit: null);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Retry failed operation with exponential backoff
  Future<void> retryOperation() async {
    if (state.error == null || !state.error!.isRetryable) {
      return;
    }

    // Exponential backoff: wait longer for each retry
    final delaySeconds = math.min(math.pow(2, state.retryCount).toInt(), 30);
    await Future.delayed(Duration(seconds: delaySeconds));

    // Retry the last failed operation
    await refreshAll();
  }

  /// Refresh all social wallet data
  Future<void> refreshAll() async {
    final now = DateTime.now();
    debugPrint('🔍 [SOCIAL-WALLET-PROVIDER] refreshAll() called at $now');

    // Debounce: prevent calls within 500ms of each other
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!) < _debounceDelay) {
      debugPrint('🔍 [SOCIAL-WALLET-PROVIDER] Debouncing call - too soon after last refresh');
      return;
    }

    // Prevent multiple simultaneous refresh calls
    if (state.isLoading) {
      debugPrint('🔍 [SOCIAL-WALLET-PROVIDER] Already refreshing, skipping duplicate call');
      return;
    }

    _lastRefreshTime = now;

    try {
      await loadUserGroups();
      await loadPaymentRequests();
      debugPrint('✅ [SOCIAL-WALLET-PROVIDER] refreshAll() completed successfully');
    } catch (e) {
      debugPrint('❌ [SOCIAL-WALLET-PROVIDER] refreshAll() failed: $e');
      // Error is already handled in individual methods
    }
  }
}

/// Provider for social wallet state management
final socialWalletProvider = StateNotifierProvider<SocialWalletNotifier, SocialWalletState>((ref) {
  final socialWalletService = ref.watch(socialWalletServiceProvider);
  return SocialWalletNotifier(socialWalletService, ref);
});

/// Provider for user groups as AsyncValue
final userGroupsProvider = FutureProvider<List<PaymentGroup>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;
  
  if (user == null) {
    return [];
  }

  final socialWalletService = ref.watch(socialWalletServiceProvider);
  return socialWalletService.getUserGroups(user.id);
});

/// Provider for payment requests as AsyncValue
final paymentRequestsProvider = FutureProvider.family<List<PaymentRequest>, Map<String, dynamic>>((ref, params) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;
  
  if (user == null) {
    return [];
  }

  final socialWalletService = ref.watch(socialWalletServiceProvider);
  return socialWalletService.getUserPaymentRequests(
    userId: user.id,
    incoming: params['incoming'] as bool?,
    status: params['status'] as PaymentRequestStatus?,
    limit: params['limit'] as int?,
  );
});

/// Provider for group bill splits as AsyncValue
final groupBillSplitsProvider = FutureProvider.family<List<BillSplit>, String>((ref, groupId) async {
  final socialWalletService = ref.watch(socialWalletServiceProvider);
  return socialWalletService.getGroupBillSplits(groupId: groupId);
});
