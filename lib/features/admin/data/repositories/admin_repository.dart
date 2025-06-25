import 'package:flutter/foundation.dart';

import '../models/admin_user.dart';
import '../models/admin_activity_log.dart';
import '../models/admin_notification.dart';
import '../models/support_ticket.dart';
import '../models/system_setting.dart';
import '../models/admin_dashboard_stats.dart';
import '../../../customers/data/repositories/base_repository.dart';

/// Repository for admin-specific operations
class AdminRepository extends BaseRepository {
  AdminRepository() : super();

  // ============================================================================
  // DASHBOARD STATISTICS
  // ============================================================================

  /// Get comprehensive dashboard statistics
  Future<AdminDashboardStats> getDashboardStats() async {
    return executeQuery(() async {
      debugPrint('🔍 AdminRepository: Getting dashboard stats');
      
      final response = await supabase.rpc('get_admin_dashboard_stats');
      
      debugPrint('🔍 AdminRepository: Dashboard stats response: $response');
      
      return AdminDashboardStats.fromJson(response as Map<String, dynamic>);
    });
  }

  /// Get daily analytics data
  Future<List<DailyAnalytics>> getDailyAnalytics({
    int days = 30,
  }) async {
    return executeQuery(() async {
      final response = await supabase
          .from('daily_analytics')
          .select('*')
          .order('date', ascending: false)
          .limit(days);

      return response.map((json) => DailyAnalytics.fromJson(json)).toList();
    });
  }

  /// Get user statistics by role
  Future<List<UserStatistics>> getUserStatistics() async {
    return executeQuery(() async {
      final response = await supabase
          .from('user_statistics')
          .select('*')
          .order('total_users', ascending: false);

      return response.map((json) => UserStatistics.fromJson(json)).toList();
    });
  }

  /// Get vendor performance data
  Future<List<VendorPerformance>> getVendorPerformance({
    int limit = 50,
    int offset = 0,
  }) async {
    return executeQuery(() async {
      final response = await supabase
          .from('vendor_performance')
          .select('*')
          .order('revenue_last_30_days', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((json) => VendorPerformance.fromJson(json)).toList();
    });
  }

  // ============================================================================
  // USER MANAGEMENT
  // ============================================================================

  /// Get all users with pagination and filters
  Future<List<AdminUser>> getUsers({
    String? searchQuery,
    String? role,
    bool? isVerified,
    bool? isActive,
    int limit = 50,
    int offset = 0,
  }) async {
    return executeQuery(() async {
      debugPrint('🔍 AdminRepository: Getting users with filters');
      
      var query = supabase
          .from('users')
          .select('''
            *,
            user_profiles!inner(*)
          ''');

      // Apply filters
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'email.ilike.%$searchQuery%,full_name.ilike.%$searchQuery%'
        );
      }

      if (role != null) {
        query = query.eq('role', role);
      }

      if (isVerified != null) {
        query = query.eq('is_verified', isVerified);
      }

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      debugPrint('🔍 AdminRepository: Found ${response.length} users');

      return response.map((json) => AdminUser.fromJson(json)).toList();
    });
  }

  /// Get user by ID
  Future<AdminUser?> getUserById(String userId) async {
    return executeQuery(() async {
      final response = await supabase
          .from('users')
          .select('''
            *,
            user_profiles!inner(*)
          ''')
          .eq('id', userId)
          .maybeSingle();

      return response != null ? AdminUser.fromJson(response) : null;
    });
  }

  /// Update user status (activate/deactivate)
  Future<void> updateUserStatus(String userId, bool isActive, {String? reason}) async {
    return executeQuery(() async {
      debugPrint('🔍 AdminRepository: Updating user status: $userId -> $isActive');
      
      // Use the database function for proper logging
      await supabase.rpc('admin_update_user_status', params: {
        'p_user_id': userId,
        'p_is_active': isActive,
        'p_reason': reason,
      });

      debugPrint('🔍 AdminRepository: User status updated successfully');
    });
  }

  /// Update user role
  Future<void> updateUserRole(String userId, String newRole, {String? reason}) async {
    return executeQuery(() async {
      debugPrint('🔍 AdminRepository: Updating user role: $userId -> $newRole');
      
      // Update user role
      await supabase
          .from('users')
          .update({
            'role': newRole,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // Log the activity
      await logAdminActivity(
        actionType: AdminActionType.roleChanged,
        targetType: AdminTargetType.user,
        targetId: userId,
        details: {
          'new_role': newRole,
          'reason': reason,
        },
      );

      debugPrint('🔍 AdminRepository: User role updated successfully');
    });
  }

  /// Create new user
  Future<void> createUser(Map<String, dynamic> userData) async {
    return executeQuery(() async {
      debugPrint('🔍 AdminRepository: Creating user: ${userData['email']}');

      // Create user via Supabase Auth Admin API
      final response = await supabase.rpc('create_admin_user', params: {
        'p_email': userData['email'],
        'p_password': userData['password'],
        'p_full_name': userData['full_name'],
        'p_phone_number': userData['phone_number'],
        'p_role': userData['role'],
        'p_is_active': userData['is_active'] ?? true,
        'p_is_verified': userData['is_verified'] ?? false,
      });

      // Log the activity
      await logAdminActivity(
        actionType: AdminActionType.userCreated,
        targetType: AdminTargetType.user,
        targetId: response.toString(),
        details: {
          'email': userData['email'],
          'role': userData['role'],
        },
      );

      debugPrint('🔍 AdminRepository: User created successfully');
    });
  }

  /// Update user
  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    return executeQuery(() async {
      debugPrint('🔍 AdminRepository: Updating user: $userId');

      // Add updated_at timestamp
      final updateData = Map<String, dynamic>.from(updates);
      updateData['updated_at'] = DateTime.now().toIso8601String();

      // Update user
      await supabase
          .from('users')
          .update(updateData)
          .eq('id', userId);

      // Log the activity
      await logAdminActivity(
        actionType: AdminActionType.userUpdated,
        targetType: AdminTargetType.user,
        targetId: userId,
        details: updates,
      );

      debugPrint('🔍 AdminRepository: User updated successfully');
    });
  }

  /// Delete user (soft delete by deactivating)
  Future<void> deleteUser(String userId, {String? reason}) async {
    return executeQuery(() async {
      debugPrint('🔍 AdminRepository: Soft deleting user: $userId');
      
      await updateUserStatus(userId, false, reason: reason ?? 'User deleted by admin');
      
      // Log the activity
      await logAdminActivity(
        actionType: AdminActionType.userDeleted,
        targetType: AdminTargetType.user,
        targetId: userId,
        details: {
          'reason': reason,
          'deletion_type': 'soft_delete',
        },
      );

      debugPrint('🔍 AdminRepository: User soft deleted successfully');
    });
  }

  // ============================================================================
  // ACTIVITY LOGGING
  // ============================================================================

  /// Log admin activity
  Future<String> logAdminActivity({
    required String actionType,
    required String targetType,
    String? targetId,
    Map<String, dynamic>? details,
  }) async {
    return executeQuery(() async {
      debugPrint('🔍 AdminRepository: Logging admin activity: $actionType');
      
      final response = await supabase.rpc('log_admin_activity', params: {
        'p_action_type': actionType,
        'p_target_type': targetType,
        'p_target_id': targetId,
        'p_details': details ?? {},
      });

      debugPrint('🔍 AdminRepository: Activity logged with ID: $response');
      
      return response as String;
    });
  }

  /// Get activity logs with filters
  Future<List<AdminActivityLog>> getActivityLogs({
    ActivityLogFilter? filter,
  }) async {
    return executeQuery(() async {
      var query = supabase
          .from('admin_activity_logs')
          .select('*');

      // Apply filters if provided
      if (filter != null) {
        if (filter.actionType != null) {
          query = query.eq('action_type', filter.actionType!);
        }
        if (filter.targetType != null) {
          query = query.eq('target_type', filter.targetType!);
        }
        if (filter.adminUserId != null) {
          query = query.eq('admin_user_id', filter.adminUserId!);
        }
        if (filter.startDate != null) {
          query = query.gte('created_at', filter.startDate!.toIso8601String());
        }
        if (filter.endDate != null) {
          query = query.lte('created_at', filter.endDate!.toIso8601String());
        }
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(filter?.offset ?? 0, (filter?.offset ?? 0) + (filter?.limit ?? 50) - 1);

      return response.map((json) => AdminActivityLog.fromJson(json)).toList();
    });
  }

  // ============================================================================
  // NOTIFICATIONS
  // ============================================================================

  /// Get admin notifications
  Future<List<AdminNotification>> getNotifications({
    NotificationFilter? filter,
  }) async {
    return executeQuery(() async {
      var query = supabase
          .from('admin_notifications')
          .select('*');

      // Apply filters if provided
      if (filter != null) {
        if (filter.type != null) {
          query = query.eq('type', filter.type!.value);
        }
        if (filter.isRead != null) {
          query = query.eq('is_read', filter.isRead!);
        }
        if (filter.minPriority != null) {
          query = query.gte('priority', filter.minPriority!);
        }
        if (filter.maxPriority != null) {
          query = query.lte('priority', filter.maxPriority!);
        }
        if (filter.category != null) {
          query = query.eq('category', filter.category!);
        }
        if (filter.startDate != null) {
          query = query.gte('created_at', filter.startDate!.toIso8601String());
        }
        if (filter.endDate != null) {
          query = query.lte('created_at', filter.endDate!.toIso8601String());
        }
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(filter?.offset ?? 0, (filter?.offset ?? 0) + (filter?.limit ?? 50) - 1);

      return response.map((json) => AdminNotification.fromJson(json)).toList();
    });
  }

  /// Create admin notification
  Future<String> createNotification(AdminNotification notification) async {
    return executeQuery(() async {
      debugPrint('🔍 AdminRepository: Creating notification: ${notification.title}');
      
      final response = await supabase.rpc('create_admin_notification', params: {
        'p_title': notification.title,
        'p_message': notification.message,
        'p_type': notification.type.value,
        'p_priority': notification.priority,
        'p_admin_user_id': notification.adminUserId,
        'p_metadata': notification.metadata,
        'p_expires_at': notification.expiresAt?.toIso8601String(),
      });

      debugPrint('🔍 AdminRepository: Notification created with ID: $response');
      
      return response as String;
    });
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    return executeQuery(() async {
      await supabase
          .from('admin_notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    });
  }

  /// Mark all notifications as read for current admin
  Future<void> markAllNotificationsAsRead() async {
    return executeQuery(() async {
      await supabase
          .from('admin_notifications')
          .update({'is_read': true})
          .eq('admin_user_id', currentUserId!)
          .eq('is_read', false);
    });
  }

  // ============================================================================
  // SUPPORT TICKETS
  // ============================================================================

  /// Get support tickets with filters
  Future<List<SupportTicket>> getSupportTickets({
    TicketFilter? filter,
  }) async {
    return executeQuery(() async {
      var query = supabase
          .from('support_tickets')
          .select('*');

      // Apply filters if provided
      if (filter != null) {
        if (filter.status != null) {
          query = query.eq('status', filter.status!.value);
        }
        if (filter.priority != null) {
          query = query.eq('priority', filter.priority!.value);
        }
        if (filter.category != null) {
          query = query.eq('category', filter.category!);
        }
        if (filter.assignedAdminId != null) {
          query = query.eq('assigned_admin_id', filter.assignedAdminId!);
        }
        if (filter.userId != null) {
          query = query.eq('user_id', filter.userId!);
        }
        if (filter.startDate != null) {
          query = query.gte('created_at', filter.startDate!.toIso8601String());
        }
        if (filter.endDate != null) {
          query = query.lte('created_at', filter.endDate!.toIso8601String());
        }
        if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
          query = query.or(
            'subject.ilike.%${filter.searchQuery}%,description.ilike.%${filter.searchQuery}%,ticket_number.ilike.%${filter.searchQuery}%'
          );
        }
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(filter?.offset ?? 0, (filter?.offset ?? 0) + (filter?.limit ?? 50) - 1);

      return response.map((json) => SupportTicket.fromJson(json)).toList();
    });
  }

  /// Get support ticket by ID
  Future<SupportTicket?> getSupportTicketById(String ticketId) async {
    return executeQuery(() async {
      final response = await supabase
          .from('support_tickets')
          .select('*')
          .eq('id', ticketId)
          .maybeSingle();

      return response != null ? SupportTicket.fromJson(response) : null;
    });
  }

  /// Create support ticket
  Future<String> createSupportTicket({
    required String subject,
    required String description,
    String category = 'general',
    String priority = 'medium',
  }) async {
    return executeQuery(() async {
      debugPrint('🔍 AdminRepository: Creating support ticket: $subject');

      final response = await supabase.rpc('create_support_ticket', params: {
        'p_subject': subject,
        'p_description': description,
        'p_category': category,
        'p_priority': priority,
      });

      debugPrint('🔍 AdminRepository: Support ticket created with ID: $response');

      return response as String;
    });
  }

  /// Assign ticket to admin
  Future<void> assignTicket(String ticketId, String adminId, {String? reason}) async {
    return executeQuery(() async {
      debugPrint('🔍 AdminRepository: Assigning ticket $ticketId to admin $adminId');

      await supabase
          .from('support_tickets')
          .update({
            'assigned_admin_id': adminId,
            'status': TicketStatus.inProgress.value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', ticketId);

      // Log the activity
      await logAdminActivity(
        actionType: AdminActionType.ticketAssigned,
        targetType: AdminTargetType.ticket,
        targetId: ticketId,
        details: {
          'assigned_admin_id': adminId,
          'reason': reason,
        },
      );

      debugPrint('🔍 AdminRepository: Ticket assigned successfully');
    });
  }

  /// Update ticket status
  Future<void> updateTicketStatus(String ticketId, TicketStatus newStatus, {String? notes}) async {
    return executeQuery(() async {
      debugPrint('🔍 AdminRepository: Updating ticket status: $ticketId -> ${newStatus.value}');

      final updateData = {
        'status': newStatus.value,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (newStatus == TicketStatus.resolved || newStatus == TicketStatus.closed) {
        updateData['resolved_at'] = DateTime.now().toIso8601String();
        if (notes != null) {
          updateData['resolution_notes'] = notes;
        }
      }

      await supabase
          .from('support_tickets')
          .update(updateData)
          .eq('id', ticketId);

      // Log the activity
      await logAdminActivity(
        actionType: newStatus == TicketStatus.resolved
            ? AdminActionType.ticketResolved
            : AdminActionType.ticketClosed,
        targetType: AdminTargetType.ticket,
        targetId: ticketId,
        details: {
          'new_status': newStatus.value,
          'notes': notes,
        },
      );

      debugPrint('🔍 AdminRepository: Ticket status updated successfully');
    });
  }

  /// Get ticket statistics
  Future<TicketStatistics> getTicketStatistics() async {
    return executeQuery(() async {
      final response = await supabase
          .from('support_tickets')
          .select('status, priority, assigned_admin_id');

      final tickets = response as List<dynamic>;

      int totalTickets = tickets.length;
      int openTickets = tickets.where((t) => t['status'] == 'open').length;
      int inProgressTickets = tickets.where((t) => t['status'] == 'in_progress').length;
      int resolvedTickets = tickets.where((t) => t['status'] == 'resolved').length;
      int closedTickets = tickets.where((t) => t['status'] == 'closed').length;
      int urgentTickets = tickets.where((t) => t['priority'] == 'urgent').length;
      int highPriorityTickets = tickets.where((t) => t['priority'] == 'high').length;

      return TicketStatistics(
        totalTickets: totalTickets,
        openTickets: openTickets,
        inProgressTickets: inProgressTickets,
        resolvedTickets: resolvedTickets,
        closedTickets: closedTickets,
        urgentTickets: urgentTickets,
        highPriorityTickets: highPriorityTickets,
        unassignedTickets: tickets.where((t) => t['assigned_admin_id'] == null).length,
      );
    });
  }

  // ============================================================================
  // SYSTEM SETTINGS
  // ============================================================================

  /// Get system settings with filters
  Future<List<SystemSetting>> getSystemSettings({
    SettingsFilter? filter,
  }) async {
    return executeQuery(() async {
      var query = supabase
          .from('system_settings')
          .select('*');

      // Apply filters if provided
      if (filter != null) {
        if (filter.category != null) {
          query = query.eq('category', filter.category!);
        }
        if (filter.isPublic != null) {
          query = query.eq('is_public', filter.isPublic!);
        }
        if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
          query = query.or(
            'setting_key.ilike.%${filter.searchQuery}%,description.ilike.%${filter.searchQuery}%'
          );
        }
      }

      final response = await query
          .order('category', ascending: true)
          .order('setting_key', ascending: true)
          .range(filter?.offset ?? 0, (filter?.offset ?? 0) + (filter?.limit ?? 100) - 1);

      return response.map((json) => SystemSetting.fromJson(json)).toList();
    });
  }

  /// Get system setting by key
  Future<SystemSetting?> getSystemSetting(String settingKey) async {
    return executeQuery(() async {
      final response = await supabase
          .from('system_settings')
          .select('*')
          .eq('setting_key', settingKey)
          .maybeSingle();

      return response != null ? SystemSetting.fromJson(response) : null;
    });
  }

  /// Update system setting
  Future<void> updateSystemSetting(String settingKey, dynamic settingValue, {String? reason}) async {
    return executeQuery(() async {
      debugPrint('🔍 AdminRepository: Updating system setting: $settingKey -> $settingValue');

      await supabase
          .from('system_settings')
          .update({
            'setting_value': settingValue,
            'updated_by': currentUserId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('setting_key', settingKey);

      // Log the activity
      await logAdminActivity(
        actionType: AdminActionType.systemSettingUpdated,
        targetType: AdminTargetType.setting,
        targetId: settingKey,
        details: {
          'setting_key': settingKey,
          'new_value': settingValue,
          'reason': reason,
        },
      );

      debugPrint('🔍 AdminRepository: System setting updated successfully');
    });
  }

  /// Create system setting
  Future<void> createSystemSetting({
    required String settingKey,
    required dynamic settingValue,
    String? description,
    String category = 'general',
    bool isPublic = false,
  }) async {
    return executeQuery(() async {
      debugPrint('🔍 AdminRepository: Creating system setting: $settingKey');

      await supabase
          .from('system_settings')
          .insert({
            'setting_key': settingKey,
            'setting_value': settingValue,
            'description': description,
            'category': category,
            'is_public': isPublic,
            'updated_by': currentUserId,
          });

      // Log the activity
      await logAdminActivity(
        actionType: AdminActionType.systemSettingUpdated,
        targetType: AdminTargetType.setting,
        targetId: settingKey,
        details: {
          'setting_key': settingKey,
          'setting_value': settingValue,
          'action': 'created',
        },
      );

      debugPrint('🔍 AdminRepository: System setting created successfully');
    });
  }

  /// Delete system setting
  Future<void> deleteSystemSetting(String settingKey, {String? reason}) async {
    return executeQuery(() async {
      debugPrint('🔍 AdminRepository: Deleting system setting: $settingKey');

      await supabase
          .from('system_settings')
          .delete()
          .eq('setting_key', settingKey);

      // Log the activity
      await logAdminActivity(
        actionType: AdminActionType.systemSettingUpdated,
        targetType: AdminTargetType.setting,
        targetId: settingKey,
        details: {
          'setting_key': settingKey,
          'action': 'deleted',
          'reason': reason,
        },
      );

      debugPrint('🔍 AdminRepository: System setting deleted successfully');
    });
  }

  // ============================================================================
  // REAL-TIME STREAMS
  // ============================================================================

  /// Stream admin notifications for current user
  Stream<List<AdminNotification>> streamNotifications() {
    return supabase
        .from('admin_notifications')
        .stream(primaryKey: ['id'])
        .eq('admin_user_id', currentUserId!)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => AdminNotification.fromJson(json)).toList());
  }

  /// Stream activity logs
  Stream<List<AdminActivityLog>> streamActivityLogs({int limit = 50}) {
    return supabase
        .from('admin_activity_logs')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(limit)
        .map((data) => data.map((json) => AdminActivityLog.fromJson(json)).toList());
  }

  /// Stream support tickets
  Stream<List<SupportTicket>> streamSupportTickets({
    TicketStatus? status,
    String? assignedAdminId,
  }) {
    return supabase
        .from('support_tickets')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          var tickets = data.map((json) => SupportTicket.fromJson(json)).toList();

          // Apply filters in memory for streams
          if (status != null) {
            tickets = tickets.where((ticket) => ticket.status == status).toList();
          }

          if (assignedAdminId != null) {
            tickets = tickets.where((ticket) => ticket.assignedAdminId == assignedAdminId).toList();
          }

          return tickets;
        });
  }

  // ============================================================================
  // VENDOR MANAGEMENT
  // ============================================================================

  /// Get all vendors with admin-specific data and filters
  Future<List<Map<String, dynamic>>> getVendorsForAdmin({
    String? searchQuery,
    String? verificationStatus,
    bool? isActive,
    String sortBy = 'created_at',
    bool ascending = false,
    int limit = 50,
    int offset = 0,
  }) async {
    return executeQuery(() async {
      debugPrint('🔍 AdminRepository: Getting vendors for admin');

      var query = supabase
          .from('admin_vendor_analytics')
          .select('*');

      // Apply filters
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('business_name', '%$searchQuery%');
      }

      if (verificationStatus != null) {
        query = query.eq('verification_status', verificationStatus);
      }

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      // Apply sorting and pagination
      final response = await query
          .order(sortBy, ascending: ascending)
          .range(offset, offset + limit - 1);

      debugPrint('🔍 AdminRepository: Vendors response: ${response.length} items');

      return List<Map<String, dynamic>>.from(response);
    });
  }

  /// Approve vendor
  Future<void> approveVendor(String vendorId, {String? adminNotes}) async {
    return executeQuery(() async {
      debugPrint('🔍 AdminRepository: Approving vendor: $vendorId');

      await supabase.rpc('approve_vendor', params: {
        'p_vendor_id': vendorId,
        'p_admin_notes': adminNotes,
      });

      debugPrint('🔍 AdminRepository: Vendor approved successfully');
    });
  }

  /// Reject vendor
  Future<void> rejectVendor(String vendorId, String rejectionReason, {String? adminNotes}) async {
    return executeQuery(() async {
      debugPrint('🔍 AdminRepository: Rejecting vendor: $vendorId');

      await supabase.rpc('reject_vendor', params: {
        'p_vendor_id': vendorId,
        'p_rejection_reason': rejectionReason,
        'p_admin_notes': adminNotes,
      });

      debugPrint('🔍 AdminRepository: Vendor rejected successfully');
    });
  }

  /// Toggle vendor active status
  Future<void> toggleVendorStatus(String vendorId, bool isActive) async {
    return executeQuery(() async {
      debugPrint('🔍 AdminRepository: Toggling vendor status: $vendorId to $isActive');

      await supabase
          .from('vendors')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', vendorId);

      // Log admin activity
      await logAdminActivity(
        actionType: 'toggle_vendor_status',
        targetType: 'vendor',
        targetId: vendorId,
        details: {'is_active': isActive},
      );

      debugPrint('🔍 AdminRepository: Vendor status toggled successfully');
    });
  }

  /// Get vendor details with admin information
  Future<Map<String, dynamic>> getVendorDetailsForAdmin(String vendorId) async {
    return executeQuery(() async {
      debugPrint('🔍 AdminRepository: Getting vendor details for admin: $vendorId');

      final response = await supabase
          .from('vendors')
          .select('''
            *,
            user:users!vendors_user_id_fkey(
              id,
              email,
              full_name,
              phone_number,
              created_at,
              last_sign_in_at
            ),
            approved_by_user:users!vendors_approved_by_fkey(
              full_name,
              email
            )
          ''')
          .eq('id', vendorId)
          .single();

      debugPrint('🔍 AdminRepository: Vendor details retrieved');
      return response;
    });
  }

  // ============================================================================
  // ORDER MANAGEMENT
  // ============================================================================

  /// Get all orders with admin-specific data and filters
  Future<List<Map<String, dynamic>>> getOrdersForAdmin({
    String? searchQuery,
    String? status,
    String? vendorId,
    String? customerId,
    DateTime? startDate,
    DateTime? endDate,
    String sortBy = 'created_at',
    bool ascending = false,
    int limit = 50,
    int offset = 0,
  }) async {
    return executeQuery(() async {
      debugPrint('🔍 AdminRepository: Getting orders for admin');

      var query = supabase
          .from('orders')
          .select('*');

      // Apply filters
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('order_number', '%$searchQuery%');
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      if (vendorId != null) {
        query = query.eq('vendor_id', vendorId);
      }

      if (customerId != null) {
        query = query.eq('customer_id', customerId);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      // Apply sorting and pagination
      final response = await query
          .order(sortBy, ascending: ascending)
          .range(offset, offset + limit - 1);

      debugPrint('🔍 AdminRepository: Orders response: ${response.length} items');

      return List<Map<String, dynamic>>.from(response);
    });
  }

  /// Update order status with admin tracking
  Future<void> updateOrderStatus(
    String orderId,
    String newStatus, {
    String? adminNotes,
    int? priorityLevel,
  }) async {
    return executeQuery(() async {
      debugPrint('🔍 AdminRepository: Updating order status: $orderId -> $newStatus');

      await supabase.rpc('admin_update_order_status', params: {
        'p_order_id': orderId,
        'p_new_status': newStatus,
        'p_admin_notes': adminNotes,
        'p_priority_level': priorityLevel,
      });

      debugPrint('🔍 AdminRepository: Order status updated successfully');
    });
  }

  /// Process order refund
  Future<void> processOrderRefund(
    String orderId,
    double refundAmount,
    String refundReason,
  ) async {
    return executeQuery(() async {
      debugPrint('🔍 AdminRepository: Processing refund for order: $orderId');

      await supabase.rpc('process_order_refund', params: {
        'p_order_id': orderId,
        'p_refund_amount': refundAmount,
        'p_refund_reason': refundReason,
      });

      debugPrint('🔍 AdminRepository: Order refund processed successfully');
    });
  }

  /// Get order details with admin information
  Future<Map<String, dynamic>> getOrderDetailsForAdmin(String orderId) async {
    return executeQuery(() async {
      debugPrint('🔍 AdminRepository: Getting order details for admin: $orderId');

      final response = await supabase
          .from('orders')
          .select('''
            *,
            vendor:vendors!orders_vendor_id_fkey(*),
            customer:customer_profiles!orders_customer_id_fkey(*),
            sales_agent:users!orders_sales_agent_id_fkey(
              id,
              full_name,
              email,
              phone_number
            ),
            driver:drivers!orders_assigned_driver_id_fkey(
              id,
              full_name,
              phone_number,
              status
            ),
            order_items:order_items(*),
            last_modified_by_user:users!orders_last_modified_by_fkey(
              full_name,
              email
            ),
            refunded_by_user:users!orders_refunded_by_fkey(
              full_name,
              email
            )
          ''')
          .eq('id', orderId)
          .single();

      debugPrint('🔍 AdminRepository: Order details retrieved');
      return response;
    });
  }

  /// Get order analytics data
  Future<List<Map<String, dynamic>>> getOrderAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 30,
  }) async {
    return executeQuery(() async {
      debugPrint('🔍 AdminRepository: Getting order analytics');

      var query = supabase
          .from('admin_order_analytics')
          .select('*');

      if (startDate != null) {
        query = query.gte('order_date', startDate.toIso8601String().split('T')[0]);
      }

      if (endDate != null) {
        query = query.lte('order_date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query
          .order('order_date', ascending: false)
          .limit(limit);

      debugPrint('🔍 AdminRepository: Order analytics retrieved: ${response.length} items');

      return List<Map<String, dynamic>>.from(response);
    });
  }
}
