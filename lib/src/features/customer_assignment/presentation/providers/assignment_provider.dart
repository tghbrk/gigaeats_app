import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/assignment_request.dart';
import '../../data/models/customer_assignment.dart';
import '../../data/models/assignment_history.dart';
import '../../data/repositories/assignment_repository.dart';

/// Provider for assignment repository
final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  return AssignmentRepository();
});

/// State class for assignment management
class AssignmentState {
  final List<AssignmentRequest> requests;
  final List<CustomerAssignment> assignments;
  final List<AssignmentHistory> history;
  final Map<String, dynamic>? stats;
  final bool isLoading;
  final String? errorMessage;

  const AssignmentState({
    this.requests = const [],
    this.assignments = const [],
    this.history = const [],
    this.stats,
    this.isLoading = false,
    this.errorMessage,
  });

  AssignmentState copyWith({
    List<AssignmentRequest>? requests,
    List<CustomerAssignment>? assignments,
    List<AssignmentHistory>? history,
    Map<String, dynamic>? stats,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AssignmentState(
      requests: requests ?? this.requests,
      assignments: assignments ?? this.assignments,
      history: history ?? this.history,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Assignment notifier for managing customer assignments
class AssignmentNotifier extends StateNotifier<AssignmentState> {
  final AssignmentRepository _repository;

  AssignmentNotifier(this._repository) : super(const AssignmentState());

  /// Create a new assignment request
  Future<bool> createAssignmentRequest({
    required String customerId,
    required String salesAgentId,
    String? message,
    AssignmentRequestPriority priority = AssignmentRequestPriority.normal,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _repository.createAssignmentRequest(
        customerId: customerId,
        salesAgentId: salesAgentId,
        message: message,
        priority: priority,
      );

      if (result['success'] == true) {
        // Refresh requests list
        await loadSalesAgentRequests();
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['error'] ?? 'Failed to create assignment request',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Assignment Provider: Error creating request: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Respond to an assignment request
  Future<bool> respondToAssignmentRequest({
    required String requestId,
    required String response, // 'approve' or 'reject'
    String? message,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _repository.respondToAssignmentRequest(
        requestId: requestId,
        response: response,
        message: message,
      );

      if (result['success'] == true || response == 'reject') {
        // Refresh requests and assignments
        await loadCustomerRequests();
        if (response == 'approve') {
          await loadSalesAgentAssignments();
        }
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['error'] ?? 'Failed to respond to assignment request',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Assignment Provider: Error responding to request: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Cancel an assignment request
  Future<bool> cancelAssignmentRequest({
    required String requestId,
    String? reason,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _repository.cancelAssignmentRequest(
        requestId: requestId,
        reason: reason,
      );

      if (result['success'] == true) {
        // Refresh requests list
        await loadSalesAgentRequests();
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['error'] ?? 'Failed to cancel assignment request',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Assignment Provider: Error cancelling request: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Deactivate an assignment
  Future<bool> deactivateAssignment({
    required String assignmentId,
    required String reason,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _repository.deactivateAssignment(
        assignmentId: assignmentId,
        reason: reason,
      );

      if (result['success'] == true) {
        // Refresh assignments list
        await loadSalesAgentAssignments();
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['error'] ?? 'Failed to deactivate assignment',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Assignment Provider: Error deactivating assignment: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Load sales agent assignment requests
  Future<void> loadSalesAgentRequests({String? status}) async {
    try {
      final requests = await _repository.getSalesAgentAssignmentRequests(
        status: status,
      );
      state = state.copyWith(requests: requests);
    } catch (e) {
      debugPrint('Assignment Provider: Error loading sales agent requests: $e');
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Load customer assignment requests
  Future<void> loadCustomerRequests({String? status}) async {
    try {
      final requests = await _repository.getCustomerAssignmentRequests(
        status: status,
      );
      state = state.copyWith(requests: requests);
    } catch (e) {
      debugPrint('Assignment Provider: Error loading customer requests: $e');
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Load sales agent assignments
  Future<void> loadSalesAgentAssignments({bool activeOnly = true}) async {
    try {
      final assignments = await _repository.getSalesAgentAssignments(
        activeOnly: activeOnly,
      );
      state = state.copyWith(assignments: assignments);
    } catch (e) {
      debugPrint('Assignment Provider: Error loading assignments: $e');
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Load assignment history
  Future<void> loadAssignmentHistory({
    String? customerId,
    String? salesAgentId,
  }) async {
    try {
      final history = await _repository.getAssignmentHistory(
        customerId: customerId,
        salesAgentId: salesAgentId,
      );
      state = state.copyWith(history: history);
    } catch (e) {
      debugPrint('Assignment Provider: Error loading history: $e');
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Load assignment statistics for sales agent
  Future<void> loadAssignmentStats() async {
    try {
      final stats = await _repository.getSalesAgentAssignmentStats();
      state = state.copyWith(stats: stats);
    } catch (e) {
      debugPrint('Assignment Provider: Error loading stats: $e');
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Search available customers
  Future<List<Map<String, dynamic>>> searchAvailableCustomers({
    String? searchQuery,
    int limit = 20,
  }) async {
    try {
      return await _repository.searchAvailableCustomers(
        searchQuery: searchQuery,
        limit: limit,
      );
    } catch (e) {
      debugPrint('Assignment Provider: Error searching customers: $e');
      state = state.copyWith(errorMessage: e.toString());
      return [];
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Refresh all data
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      await Future.wait([
        loadSalesAgentRequests(),
        loadSalesAgentAssignments(),
        loadAssignmentStats(),
      ]);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('Assignment Provider: Error refreshing data: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

/// Provider for assignment notifier
final assignmentProvider = StateNotifierProvider<AssignmentNotifier, AssignmentState>((ref) {
  final repository = ref.read(assignmentRepositoryProvider);
  return AssignmentNotifier(repository);
});

/// Provider for pending assignment requests count
final pendingAssignmentRequestsCountProvider = FutureProvider<int>((ref) async {
  try {
    final repository = ref.read(assignmentRepositoryProvider);
    final requests = await repository.getSalesAgentAssignmentRequests(
      status: 'pending',
      limit: 100, // Get enough to count
    );
    return requests.length;
  } catch (e) {
    debugPrint('Error getting pending requests count: $e');
    return 0;
  }
});

/// Provider for customer assignment status
final customerAssignmentStatusProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, customerId) async {
  try {
    final repository = ref.read(assignmentRepositoryProvider);
    final result = await repository.getCustomerAssignmentStatus(customerId);
    return result['data'];
  } catch (e) {
    debugPrint('Error getting customer assignment status: $e');
    return null;
  }
});
