import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/social_wallet.dart';

/// Service for managing social wallet features
class SocialWalletService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get user's payment groups
  Future<List<PaymentGroup>> getUserGroups(String userId) async {
    try {
      debugPrint('🔍 [SOCIAL-WALLET-SERVICE] getUserGroups called for user: $userId');

      debugPrint('🔍 [SOCIAL-WALLET-SERVICE] Invoking social-wallet-groups Edge Function');
      final response = await _supabase.functions.invoke(
        'social-wallet-groups',
        body: {
          'action': 'get_user_groups',
          'user_id': userId,
        },
      );

      debugPrint('🔍 [SOCIAL-WALLET-SERVICE] Edge Function response status: ${response.status}');
      debugPrint('🔍 [SOCIAL-WALLET-SERVICE] Edge Function response data: ${response.data}');

      if (response.data == null) {
        debugPrint('❌ [SOCIAL-WALLET-SERVICE] Response data is null');
        throw Exception('Failed to load payment groups: Response data is null');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        debugPrint('❌ [SOCIAL-WALLET-SERVICE] Edge Function returned error: ${data['error']}');
        throw Exception('Failed to load payment groups: ${data['error']}');
      }

      if (data['groups'] == null) {
        debugPrint('⚠️ [SOCIAL-WALLET-SERVICE] No groups found in response');
        return [];
      }

      final groupsData = data['groups'] as List<dynamic>;
      debugPrint('✅ [SOCIAL-WALLET-SERVICE] Successfully parsed ${groupsData.length} groups');
      return groupsData.map((item) => PaymentGroup.fromJson(item as Map<String, dynamic>)).toList();
    } on FunctionException catch (e) {
      debugPrint('❌ [SOCIAL-WALLET-SERVICE] FunctionException: ${e.status} - ${e.details}');
      debugPrint('❌ [SOCIAL-WALLET-SERVICE] FunctionException reasonPhrase: ${e.reasonPhrase}');
      throw Exception('Failed to load payment groups: ${e.details}');
    } catch (e) {
      debugPrint('❌ [SOCIAL-WALLET-SERVICE] General exception: $e');
      debugPrint('❌ [SOCIAL-WALLET-SERVICE] Exception type: ${e.runtimeType}');
      throw Exception('Failed to load payment groups: ${e.toString()}');
    }
  }

  /// Create a new payment group
  Future<PaymentGroup> createGroup({
    required String userId,
    required String name,
    required String description,
    required GroupType type,
    required List<String> memberEmails,
    GroupSettings? settings,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'social-wallet-groups',
        body: {
          'action': 'create_group',
          'user_id': userId,
          'name': name,
          'description': description,
          'type': type.value,
          'member_emails': memberEmails,
          'settings': settings?.toJson() ?? const GroupSettings().toJson(),
        },
      );

      if (response.data == null) {
        throw Exception('Failed to create payment group');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to create payment group: ${data['error']}');
      }

      return PaymentGroup.fromJson(data['group'] as Map<String, dynamic>);
    } on FunctionException catch (e) {
      throw Exception('Failed to create payment group: ${e.details}');
    } catch (e) {
      throw Exception('Failed to create payment group: ${e.toString()}');
    }
  }

  /// Update payment group
  Future<PaymentGroup> updateGroup({
    required String groupId,
    required String userId,
    String? name,
    String? description,
    GroupSettings? settings,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'social-wallet-groups',
        body: {
          'action': 'update_group',
          'group_id': groupId,
          'user_id': userId,
          'name': name,
          'description': description,
          'settings': settings?.toJson(),
        },
      );

      if (response.data == null) {
        throw Exception('Failed to update payment group');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to update payment group: ${data['error']}');
      }

      return PaymentGroup.fromJson(data['group'] as Map<String, dynamic>);
    } on FunctionException catch (e) {
      throw Exception('Failed to update payment group: ${e.details}');
    } catch (e) {
      throw Exception('Failed to update payment group: ${e.toString()}');
    }
  }

  /// Add members to group
  Future<void> addMembersToGroup({
    required String groupId,
    required String userId,
    required List<String> memberEmails,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'social-wallet-groups',
        body: {
          'action': 'add_members',
          'group_id': groupId,
          'user_id': userId,
          'member_emails': memberEmails,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to add members to group');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to add members to group: ${data['error']}');
      }
    } on FunctionException catch (e) {
      throw Exception('Failed to add members to group: ${e.details}');
    } catch (e) {
      throw Exception('Failed to add members to group: ${e.toString()}');
    }
  }

  /// Remove member from group
  Future<void> removeMemberFromGroup({
    required String groupId,
    required String userId,
    required String memberUserId,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'social-wallet-groups',
        body: {
          'action': 'remove_member',
          'group_id': groupId,
          'user_id': userId,
          'member_user_id': memberUserId,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to remove member from group');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to remove member from group: ${data['error']}');
      }
    } on FunctionException catch (e) {
      throw Exception('Failed to remove member from group: ${e.details}');
    } catch (e) {
      throw Exception('Failed to remove member from group: ${e.toString()}');
    }
  }

  /// Create bill split
  Future<BillSplit> createBillSplit({
    required String groupId,
    required String userId,
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
      final response = await _supabase.functions.invoke(
        'social-wallet-bills',
        body: {
          'action': 'create_bill_split',
          'group_id': groupId,
          'user_id': userId,
          'title': title,
          'description': description,
          'total_amount': totalAmount,
          'split_method': splitMethod.value,
          'participants': participants,
          'receipt_image_url': receiptImageUrl,
          'category': category,
          'transaction_date': (transactionDate ?? DateTime.now()).toIso8601String(),
        },
      );

      if (response.data == null) {
        throw Exception('Failed to create bill split');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to create bill split: ${data['error']}');
      }

      return BillSplit.fromJson(data['bill_split'] as Map<String, dynamic>);
    } on FunctionException catch (e) {
      throw Exception('Failed to create bill split: ${e.details}');
    } catch (e) {
      throw Exception('Failed to create bill split: ${e.toString()}');
    }
  }

  /// Get group bill splits
  Future<List<BillSplit>> getGroupBillSplits({
    required String groupId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'social-wallet-bills',
        body: {
          'action': 'get_group_bills',
          'group_id': groupId,
          'limit': limit,
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
        },
      );

      if (response.data == null) {
        throw Exception('Failed to load bill splits');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to load bill splits: ${data['error']}');
      }

      return (data['bill_splits'] as List<dynamic>)
          .map((item) => BillSplit.fromJson(item as Map<String, dynamic>))
          .toList();
    } on FunctionException catch (e) {
      throw Exception('Failed to load bill splits: ${e.details}');
    } catch (e) {
      throw Exception('Failed to load bill splits: ${e.toString()}');
    }
  }

  /// Mark bill split participant as paid
  Future<void> markBillSplitAsPaid({
    required String billSplitId,
    required String userId,
    required String participantUserId,
    required String paymentTransactionId,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'social-wallet-bills',
        body: {
          'action': 'mark_as_paid',
          'bill_split_id': billSplitId,
          'user_id': userId,
          'participant_user_id': participantUserId,
          'payment_transaction_id': paymentTransactionId,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to mark bill split as paid');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to mark bill split as paid: ${data['error']}');
      }
    } on FunctionException catch (e) {
      throw Exception('Failed to mark bill split as paid: ${e.details}');
    } catch (e) {
      throw Exception('Failed to mark bill split as paid: ${e.toString()}');
    }
  }

  /// Create payment request
  Future<PaymentRequest> createPaymentRequest({
    required String fromUserId,
    required String toUserId,
    required double amount,
    required String title,
    String? description,
    String? groupId,
    String? billSplitId,
    DateTime? dueDate,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'social-wallet-requests',
        body: {
          'action': 'create_request',
          'from_user_id': fromUserId,
          'to_user_id': toUserId,
          'amount': amount,
          'title': title,
          'description': description,
          'group_id': groupId,
          'bill_split_id': billSplitId,
          'due_date': (dueDate ?? DateTime.now().add(const Duration(days: 7))).toIso8601String(),
        },
      );

      if (response.data == null) {
        throw Exception('Failed to create payment request');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to create payment request: ${data['error']}');
      }

      return PaymentRequest.fromJson(data['payment_request'] as Map<String, dynamic>);
    } on FunctionException catch (e) {
      throw Exception('Failed to create payment request: ${e.details}');
    } catch (e) {
      throw Exception('Failed to create payment request: ${e.toString()}');
    }
  }

  /// Get user payment requests
  Future<List<PaymentRequest>> getUserPaymentRequests({
    required String userId,
    bool? incoming,
    PaymentRequestStatus? status,
    int? limit,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'social-wallet-requests',
        body: {
          'action': 'get_user_requests',
          'user_id': userId,
          'incoming': incoming,
          'status': status?.value,
          'limit': limit,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to load payment requests');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to load payment requests: ${data['error']}');
      }

      return (data['payment_requests'] as List<dynamic>)
          .map((item) => PaymentRequest.fromJson(item as Map<String, dynamic>))
          .toList();
    } on FunctionException catch (e) {
      throw Exception('Failed to load payment requests: ${e.details}');
    } catch (e) {
      throw Exception('Failed to load payment requests: ${e.toString()}');
    }
  }

  /// Respond to payment request
  Future<void> respondToPaymentRequest({
    required String requestId,
    required String userId,
    required PaymentRequestStatus status,
    String? responseMessage,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'social-wallet-requests',
        body: {
          'action': 'respond_to_request',
          'request_id': requestId,
          'user_id': userId,
          'status': status.value,
          'response_message': responseMessage,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to respond to payment request');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to respond to payment request: ${data['error']}');
      }
    } on FunctionException catch (e) {
      throw Exception('Failed to respond to payment request: ${e.details}');
    } catch (e) {
      throw Exception('Failed to respond to payment request: ${e.toString()}');
    }
  }

  /// Send payment reminder
  Future<void> sendPaymentReminder({
    required String requestId,
    required String userId,
    String? customMessage,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'social-wallet-requests',
        body: {
          'action': 'send_reminder',
          'request_id': requestId,
          'user_id': userId,
          'custom_message': customMessage,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to send payment reminder');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to send payment reminder: ${data['error']}');
      }
    } on FunctionException catch (e) {
      throw Exception('Failed to send payment reminder: ${e.details}');
    } catch (e) {
      throw Exception('Failed to send payment reminder: ${e.toString()}');
    }
  }
}
