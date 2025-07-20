import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../drivers/data/models/driver_order.dart';
import '../../../orders/data/models/driver_order_state_machine.dart';
import '../../../../core/utils/driver_workflow_logger.dart';

/// Enhanced button state management provider for driver workflow
/// Provides centralized button state management with validation, caching, and logging
final enhancedButtonStateProvider = StateNotifierProvider.autoDispose.family<
  EnhancedButtonStateNotifier, 
  EnhancedButtonState,
  String
>((ref, orderId) {
  return EnhancedButtonStateNotifier(orderId);
});

/// Enhanced button state notifier with comprehensive state management
class EnhancedButtonStateNotifier extends StateNotifier<EnhancedButtonState> {
  final String _orderId;
  Timer? _validationTimer;

  EnhancedButtonStateNotifier(this._orderId)
      : super(EnhancedButtonState.initial(_orderId)) {
    _initializeButtonState();
  }

  /// Initialize button state based on current order
  void _initializeButtonState() {
    DriverWorkflowLogger.logProviderState(
      providerName: 'EnhancedButtonStateNotifier',
      state: 'Initializing button state',
      context: 'BUTTON_STATE',
      details: {'order_id': _orderId},
    );
    
    _updateButtonStateFromOrder();
  }

  /// Update button state when order status changes
  void updateFromOrder(DriverOrder order) {
    DriverWorkflowLogger.logProviderState(
      providerName: 'EnhancedButtonStateNotifier',
      state: 'Updating from order',
      context: 'BUTTON_STATE',
      details: {
        'order_id': order.id,
        'status': order.status.name,
      },
    );

    final availableActions = DriverOrderStateMachine.getAvailableActions(order.status);
    final buttonStates = _calculateButtonStates(availableActions, order);
    
    state = state.copyWith(
      currentStatus: order.status,
      availableActions: availableActions,
      buttonStates: buttonStates,
      lastUpdated: DateTime.now(),
      error: null,
    );
  }

  /// Set loading state for specific action
  void setActionLoading(String actionId, bool isLoading) {
    DriverWorkflowLogger.logProviderState(
      providerName: 'EnhancedButtonStateNotifier',
      state: 'Setting action loading state',
      context: 'BUTTON_STATE',
      details: {
        'action_id': actionId,
        'is_loading': isLoading,
      },
    );

    final updatedStates = Map<String, ButtonActionState>.from(state.buttonStates);
    if (updatedStates.containsKey(actionId)) {
      updatedStates[actionId] = updatedStates[actionId]!.copyWith(isLoading: isLoading);
    }

    state = state.copyWith(
      buttonStates: updatedStates,
      isAnyActionLoading: updatedStates.values.any((s) => s.isLoading),
    );
  }

  /// Set error state for specific action
  void setActionError(String actionId, String error) {
    DriverWorkflowLogger.logError(
      operation: 'Button Action Error',
      error: error,
      orderId: _orderId,
      context: 'BUTTON_STATE',
    );

    final updatedStates = Map<String, ButtonActionState>.from(state.buttonStates);
    if (updatedStates.containsKey(actionId)) {
      updatedStates[actionId] = updatedStates[actionId]!.copyWith(
        isLoading: false,
        error: error,
        lastErrorTime: DateTime.now(),
      );
    }

    state = state.copyWith(
      buttonStates: updatedStates,
      error: error,
      isAnyActionLoading: false,
    );
  }

  /// Clear error state for specific action
  void clearActionError(String actionId) {
    final updatedStates = Map<String, ButtonActionState>.from(state.buttonStates);
    if (updatedStates.containsKey(actionId)) {
      updatedStates[actionId] = updatedStates[actionId]!.copyWith(error: null);
    }

    state = state.copyWith(
      buttonStates: updatedStates,
      error: null,
    );
  }

  /// Validate action before execution
  bool validateAction(String actionId, DriverOrder order) {
    final buttonState = state.buttonStates[actionId];
    if (buttonState == null) return false;

    // Check if action is currently loading
    if (buttonState.isLoading) {
      DriverWorkflowLogger.logValidation(
        validationType: 'Button Action Validation',
        isValid: false,
        orderId: _orderId,
        context: 'BUTTON_STATE',
        reason: 'Action is currently loading',
      );
      return false;
    }

    // Check if any action is loading (prevent concurrent actions)
    if (state.isAnyActionLoading) {
      DriverWorkflowLogger.logValidation(
        validationType: 'Button Action Validation',
        isValid: false,
        orderId: _orderId,
        context: 'BUTTON_STATE',
        reason: 'Another action is currently loading',
      );
      return false;
    }

    // Validate state machine transition
    final action = state.availableActions.firstWhere(
      (a) => a.toString() == actionId,
      orElse: () => throw StateError('Action not found: $actionId'),
    );

    final validation = DriverOrderStateMachine.validateTransition(
      order.status,
      action.targetStatus,
    );

    DriverWorkflowLogger.logValidation(
      validationType: 'Button Action Validation',
      isValid: validation.isValid,
      orderId: _orderId,
      context: 'BUTTON_STATE',
      reason: validation.isValid ? 'Valid transition' : validation.errorMessage,
    );

    return validation.isValid;
  }

  /// Calculate button states for available actions
  Map<String, ButtonActionState> _calculateButtonStates(
    List<DriverOrderAction> actions,
    DriverOrder order,
  ) {
    final buttonStates = <String, ButtonActionState>{};

    for (final action in actions) {
      final actionId = action.toString();
      final isEnabled = _isActionEnabled(action, order);
      final requiresConfirmation = _requiresConfirmation(action);

      buttonStates[actionId] = ButtonActionState(
        actionId: actionId,
        action: action,
        isEnabled: isEnabled,
        isLoading: false,
        requiresConfirmation: requiresConfirmation,
        lastInteraction: null,
        error: null,
      );
    }

    return buttonStates;
  }

  /// Check if action is enabled based on current state
  bool _isActionEnabled(DriverOrderAction action, DriverOrder order) {
    // Basic state machine validation
    final validation = DriverOrderStateMachine.validateTransition(
      order.status,
      action.targetStatus,
    );

    if (!validation.isValid) return false;

    // Additional business logic validation
    switch (action) {
      case DriverOrderAction.confirmPickup:
        // Could add location-based validation here
        return true;
      case DriverOrderAction.confirmDeliveryWithPhoto:
        // Could add photo requirement validation here
        return true;
      default:
        return true;
    }
  }

  /// Check if action requires confirmation dialog
  bool _requiresConfirmation(DriverOrderAction action) {
    switch (action) {
      case DriverOrderAction.confirmPickup:
      case DriverOrderAction.confirmDeliveryWithPhoto:
        return true;
      default:
        return false;
    }
  }

  /// Update button state from current order (internal method)
  void _updateButtonStateFromOrder() {
    // This would typically get the current order from a provider
    // For now, we'll update when explicitly called
  }

  @override
  void dispose() {
    _validationTimer?.cancel();
    super.dispose();
  }
}

/// Enhanced button state data class
class EnhancedButtonState {
  final String orderId;
  final DriverOrderStatus? currentStatus;
  final List<DriverOrderAction> availableActions;
  final Map<String, ButtonActionState> buttonStates;
  final bool isAnyActionLoading;
  final String? error;
  final DateTime lastUpdated;

  const EnhancedButtonState({
    required this.orderId,
    this.currentStatus,
    required this.availableActions,
    required this.buttonStates,
    required this.isAnyActionLoading,
    this.error,
    required this.lastUpdated,
  });

  factory EnhancedButtonState.initial(String orderId) {
    return EnhancedButtonState(
      orderId: orderId,
      currentStatus: null,
      availableActions: [],
      buttonStates: {},
      isAnyActionLoading: false,
      error: null,
      lastUpdated: DateTime.now(),
    );
  }

  EnhancedButtonState copyWith({
    String? orderId,
    DriverOrderStatus? currentStatus,
    List<DriverOrderAction>? availableActions,
    Map<String, ButtonActionState>? buttonStates,
    bool? isAnyActionLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return EnhancedButtonState(
      orderId: orderId ?? this.orderId,
      currentStatus: currentStatus ?? this.currentStatus,
      availableActions: availableActions ?? this.availableActions,
      buttonStates: buttonStates ?? this.buttonStates,
      isAnyActionLoading: isAnyActionLoading ?? this.isAnyActionLoading,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Get button state for specific action
  ButtonActionState? getButtonState(String actionId) {
    return buttonStates[actionId];
  }

  /// Check if any button has an error
  bool get hasAnyError => buttonStates.values.any((s) => s.error != null);

  /// Get all enabled actions
  List<DriverOrderAction> get enabledActions {
    return buttonStates.values
        .where((s) => s.isEnabled && !s.isLoading)
        .map((s) => s.action)
        .toList();
  }
}

/// Individual button action state
class ButtonActionState {
  final String actionId;
  final DriverOrderAction action;
  final bool isEnabled;
  final bool isLoading;
  final bool requiresConfirmation;
  final DateTime? lastInteraction;
  final String? error;
  final DateTime? lastErrorTime;

  const ButtonActionState({
    required this.actionId,
    required this.action,
    required this.isEnabled,
    required this.isLoading,
    required this.requiresConfirmation,
    this.lastInteraction,
    this.error,
    this.lastErrorTime,
  });

  ButtonActionState copyWith({
    String? actionId,
    DriverOrderAction? action,
    bool? isEnabled,
    bool? isLoading,
    bool? requiresConfirmation,
    DateTime? lastInteraction,
    String? error,
    DateTime? lastErrorTime,
  }) {
    return ButtonActionState(
      actionId: actionId ?? this.actionId,
      action: action ?? this.action,
      isEnabled: isEnabled ?? this.isEnabled,
      isLoading: isLoading ?? this.isLoading,
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      error: error ?? this.error,
      lastErrorTime: lastErrorTime ?? this.lastErrorTime,
    );
  }

  /// Check if this action can be executed
  bool get canExecute => isEnabled && !isLoading && error == null;

  /// Check if error is recent (within last 5 seconds)
  bool get hasRecentError {
    if (error == null || lastErrorTime == null) return false;
    return DateTime.now().difference(lastErrorTime!).inSeconds < 5;
  }
}

/// Button interaction service for logging and execution
class ButtonInteractionService {
  /// Execute action with comprehensive logging and state management
  static Future<T> executeWithLogging<T>({
    required String actionId,
    required String orderId,
    required DriverOrderStatus currentStatus,
    required Future<T> Function() action,
    required AutoDisposeStateNotifierProviderFamily<EnhancedButtonStateNotifier, EnhancedButtonState, String> provider,
    required WidgetRef ref,
    String? context,
  }) async {
    final notifier = ref.read(provider(orderId).notifier);
    final startTime = DateTime.now();

    // Set loading state
    notifier.setActionLoading(actionId, true);

    DriverWorkflowLogger.logButtonInteraction(
      buttonName: actionId,
      orderId: orderId,
      currentStatus: currentStatus.name,
      context: context,
      metadata: {'start_time': startTime.toIso8601String()},
    );

    try {
      final result = await action();
      
      final duration = DateTime.now().difference(startTime);
      DriverWorkflowLogger.logPerformance(
        operation: 'Button Action: $actionId',
        duration: duration,
        orderId: orderId,
        context: context,
      );

      // Clear loading state
      notifier.setActionLoading(actionId, false);
      
      return result;

    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      
      DriverWorkflowLogger.logError(
        operation: 'Button Action: $actionId',
        error: e.toString(),
        orderId: orderId,
        context: context,
      );
      
      DriverWorkflowLogger.logPerformance(
        operation: 'Button Action: $actionId (Failed)',
        duration: duration,
        orderId: orderId,
        context: context,
      );

      // Set error state
      notifier.setActionError(actionId, e.toString());
      
      rethrow;
    }
  }
}
