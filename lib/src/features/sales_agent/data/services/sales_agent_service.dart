import 'package:supabase_flutter/supabase_flutter.dart';
// TODO: Restore when SalesAgentRepository is implemented
// import '../repositories/sales_agent_repository.dart';
import '../models/sales_agent_profile.dart';

/// Service for sales agent operations
class SalesAgentService {
  // TODO: Restore when SalesAgentRepository is used
  // final SalesAgentRepository _repository;
  final SupabaseClient _supabase = Supabase.instance.client;

  // TODO: Restore when SalesAgentRepository is used
  // SalesAgentService(this._repository);
  SalesAgentService(); // Placeholder constructor

  /// Get current sales agent profile
  Future<SalesAgentProfile?> getCurrentProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // TODO: Restore when getSalesAgentByUserId method is implemented
      // return await _repository.getSalesAgentByUserId(user.id);
      throw UnimplementedError('getSalesAgentByUserId method not implemented');
    } catch (e) {
      throw Exception('Failed to get current profile: $e');
    }
  }

  /// Update sales agent profile
  Future<SalesAgentProfile> updateProfile(SalesAgentProfile profile) async {
    try {
      // TODO: Restore when updateSalesAgent method is implemented
      // return await _repository.updateSalesAgent(profile);
      throw UnimplementedError('updateSalesAgent method not implemented');
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Get sales agent statistics
  Future<Map<String, dynamic>> getStatistics(String salesAgentId) async {
    try {
      // Get customer count
      final customersResponse = await _supabase
          .from('customers')
          .select('id')
          .eq('sales_agent_id', salesAgentId);

      // Get orders through customers
      final ordersResponse = await _supabase
          .from('orders')
          .select('id, total_amount, status, created_at')
          // TODO: Restore when in_ method is available or use alternative
          // .in_('customer_id', customersResponse.map((c) => c['id']).toList());
          .contains('customer_id', customersResponse.map((c) => c['id']).toList());

      // Calculate statistics
      final totalCustomers = customersResponse.length;
      final totalOrders = ordersResponse.length;
      
      final completedOrders = ordersResponse.where((o) => o['status'] == 'delivered').toList();
      final totalRevenue = completedOrders.fold<double>(
        0, 
        (sum, order) => sum + (order['total_amount'] as num).toDouble()
      );

      // Calculate commission (assuming 5% commission rate)
      const commissionRate = 0.05;
      final totalCommission = totalRevenue * commissionRate;

      // Get this month's statistics
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      
      final thisMonthOrders = ordersResponse.where((o) {
        final orderDate = DateTime.parse(o['created_at']);
        return orderDate.isAfter(startOfMonth);
      }).toList();

      final thisMonthRevenue = thisMonthOrders
          .where((o) => o['status'] == 'delivered')
          .fold<double>(0, (sum, order) => sum + (order['total_amount'] as num).toDouble());

      return {
        'total_customers': totalCustomers,
        'total_orders': totalOrders,
        'total_revenue': totalRevenue,
        'total_commission': totalCommission,
        'this_month_orders': thisMonthOrders.length,
        'this_month_revenue': thisMonthRevenue,
        'this_month_commission': thisMonthRevenue * commissionRate,
        'active_orders': ordersResponse.where((o) => 
          ['pending', 'confirmed', 'preparing', 'ready', 'out_for_delivery'].contains(o['status'])
        ).length,
      };
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }

  /// Get recent activities
  Future<List<Map<String, dynamic>>> getRecentActivities({
    required String salesAgentId,
    int limit = 10,
  }) async {
    try {
      // Get recent orders through customers
      final customersResponse = await _supabase
          .from('customers')
          .select('id, full_name')
          .eq('sales_agent_id', salesAgentId);

      final customerIds = customersResponse.map((c) => c['id']).toList();
      
      if (customerIds.isEmpty) return [];

      final ordersResponse = await _supabase
          .from('orders')
          .select('id, status, total_amount, created_at, customer_id')
          // TODO: Restore when in_ method is available or use alternative
          // .in_('customer_id', customerIds)
          .contains('customer_id', customerIds)
          .order('created_at', ascending: false)
          .limit(limit);

      // Combine order data with customer names
      final activities = ordersResponse.map((order) {
        final customer = customersResponse.firstWhere(
          (c) => c['id'] == order['customer_id'],
          orElse: () => {'full_name': 'Unknown Customer'},
        );

        return {
          'id': order['id'],
          'type': 'order',
          'title': 'Order ${order['status']}',
          'description': 'Order for ${customer['full_name']} - RM${order['total_amount']}',
          'timestamp': order['created_at'],
          'status': order['status'],
        };
      }).toList();

      return activities;
    } catch (e) {
      throw Exception('Failed to get recent activities: $e');
    }
  }

  /// Create customer for sales agent
  Future<Map<String, dynamic>> createCustomer({
    required String salesAgentId,
    required Map<String, dynamic> customerData,
  }) async {
    try {
      customerData['sales_agent_id'] = salesAgentId;
      customerData['created_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('customers')
          .insert(customerData)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to create customer: $e');
    }
  }

  /// Get commission history
  Future<List<Map<String, dynamic>>> getCommissionHistory({
    required String salesAgentId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      // Get customers for this sales agent
      final customersResponse = await _supabase
          .from('customers')
          .select('id')
          .eq('sales_agent_id', salesAgentId);

      final customerIds = customersResponse.map((c) => c['id']).toList();
      
      if (customerIds.isEmpty) return [];

      var query = _supabase
          .from('orders')
          .select('id, total_amount, created_at, customer_id')
          // TODO: Restore when in_ method is available or use alternative
          // .in_('customer_id', customerIds)
          .contains('customer_id', customerIds)
          .eq('status', 'delivered');

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final ordersResponse = await query
          .order('created_at', ascending: false)
          .limit(limit);

      // Calculate commission for each order (5% commission rate)
      const commissionRate = 0.05;
      
      return ordersResponse.map((order) {
        final orderAmount = (order['total_amount'] as num).toDouble();
        final commission = orderAmount * commissionRate;

        return {
          'order_id': order['id'],
          'order_amount': orderAmount,
          'commission_amount': commission,
          'commission_rate': commissionRate,
          'date': order['created_at'],
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get commission history: $e');
    }
  }

  /// Update sales agent availability
  Future<void> updateAvailability({
    required String salesAgentId,
    required bool isAvailable,
  }) async {
    try {
      await _supabase
          .from('sales_agents')
          .update({
            'is_available': isAvailable,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', salesAgentId);
    } catch (e) {
      throw Exception('Failed to update availability: $e');
    }
  }
}
