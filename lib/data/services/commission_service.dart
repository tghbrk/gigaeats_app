import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/commission.dart';
import '../models/order.dart';

class CommissionService {
  static final List<Commission> _commissions = [];
  static final List<Payout> _payouts = [];
  static final _uuid = const Uuid();

  // Default commission rates by tier
  static const Map<String, double> _defaultCommissionRates = {
    'bronze': 0.05,   // 5%
    'silver': 0.07,   // 7%
    'gold': 0.10,     // 10%
    'platinum': 0.12, // 12%
  };

  // Platform fee percentage
  static const double _platformFeeRate = 0.02; // 2%

  // Create commission from order
  Future<Commission> createCommissionFromOrder(Order order) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate API delay

    // Get sales agent commission rate (in real app, this would come from user profile)
    final commissionRate = _getCommissionRate(order.salesAgentId ?? 'default');
    final commissionAmount = order.totalAmount * commissionRate;
    final platformFee = commissionAmount * _platformFeeRate;
    final netCommission = commissionAmount - platformFee;

    final commission = Commission(
      id: _uuid.v4(),
      orderId: order.id,
      orderNumber: order.orderNumber,
      salesAgentId: order.salesAgentId ?? 'default',
      salesAgentName: order.salesAgentName ?? 'Unknown Agent',
      vendorId: order.vendorId,
      vendorName: order.vendorName,
      customerId: order.customerId,
      customerName: order.customerName,
      orderAmount: order.totalAmount,
      commissionRate: commissionRate,
      commissionAmount: commissionAmount,
      platformFee: platformFee,
      netCommission: netCommission,
      status: CommissionStatus.pending,
      orderDate: order.createdAt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _commissions.add(commission);
    return commission;
  }

  // Get commissions for a sales agent
  Future<List<Commission>> getSalesAgentCommissions(
    String salesAgentId, {
    CommissionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400)); // Simulate API delay

    var commissions = _commissions
        .where((c) => c.salesAgentId == salesAgentId)
        .toList();

    if (status != null) {
      commissions = commissions.where((c) => c.status == status).toList();
    }

    if (startDate != null) {
      commissions = commissions.where((c) => c.orderDate.isAfter(startDate)).toList();
    }

    if (endDate != null) {
      commissions = commissions.where((c) => c.orderDate.isBefore(endDate)).toList();
    }

    // Sort by order date (newest first)
    commissions.sort((a, b) => b.orderDate.compareTo(a.orderDate));

    if (offset != null) {
      commissions = commissions.skip(offset).toList();
    }

    if (limit != null) {
      commissions = commissions.take(limit).toList();
    }

    return commissions;
  }

  // Get commission summary for a sales agent
  Future<CommissionSummary> getCommissionSummary(
    String salesAgentId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API delay

    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month - 11, 1); // Last 12 months
    final end = endDate ?? now;

    final commissions = await getSalesAgentCommissions(
      salesAgentId,
      startDate: start,
      endDate: end,
    );

    final totalEarnings = commissions
        .where((c) => c.status == CommissionStatus.paid)
        .fold(0.0, (sum, c) => sum + c.netCommission);

    final pendingCommissions = commissions
        .where((c) => c.status == CommissionStatus.pending)
        .fold(0.0, (sum, c) => sum + c.netCommission);

    final approvedCommissions = commissions
        .where((c) => c.status == CommissionStatus.approved)
        .fold(0.0, (sum, c) => sum + c.netCommission);

    final paidCommissions = commissions
        .where((c) => c.status == CommissionStatus.paid)
        .fold(0.0, (sum, c) => sum + c.netCommission);

    final totalOrders = commissions.length;
    final pendingOrders = commissions
        .where((c) => c.status == CommissionStatus.pending)
        .length;

    final averageCommissionRate = commissions.isNotEmpty
        ? commissions.fold(0.0, (sum, c) => sum + c.commissionRate) / commissions.length
        : 0.0;

    // Calculate monthly breakdown
    final monthlyBreakdown = <String, double>{};
    for (final commission in commissions) {
      if (commission.status == CommissionStatus.paid) {
        final monthKey = '${commission.orderDate.year}-${commission.orderDate.month.toString().padLeft(2, '0')}';
        monthlyBreakdown[monthKey] = (monthlyBreakdown[monthKey] ?? 0.0) + commission.netCommission;
      }
    }

    return CommissionSummary(
      salesAgentId: salesAgentId,
      totalEarnings: totalEarnings,
      pendingCommissions: pendingCommissions,
      approvedCommissions: approvedCommissions,
      paidCommissions: paidCommissions,
      totalOrders: totalOrders,
      pendingOrders: pendingOrders,
      averageCommissionRate: averageCommissionRate,
      periodStart: start,
      periodEnd: end,
      monthlyBreakdown: monthlyBreakdown,
    );
  }

  // Approve commission
  Future<Commission> approveCommission(String commissionId, {String? notes}) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate API delay

    final index = _commissions.indexWhere((c) => c.id == commissionId);
    if (index == -1) {
      throw Exception('Commission not found');
    }

    final commission = _commissions[index];
    if (commission.status != CommissionStatus.pending) {
      throw Exception('Commission is not in pending status');
    }

    final updatedCommission = commission.copyWith(
      status: CommissionStatus.approved,
      approvedAt: DateTime.now(),
      notes: notes,
      updatedAt: DateTime.now(),
    );

    _commissions[index] = updatedCommission;
    return updatedCommission;
  }

  // Create payout for approved commissions
  Future<Payout> createPayout({
    required String salesAgentId,
    required String salesAgentName,
    required List<String> commissionIds,
    required PayoutMethod method,
    String? bankAccountNumber,
    String? bankName,
    String? bankCode,
    String? recipientName,
    DateTime? scheduledDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400)); // Simulate API delay

    // Validate commissions
    final commissions = _commissions
        .where((c) => commissionIds.contains(c.id) && c.status == CommissionStatus.approved)
        .toList();

    if (commissions.length != commissionIds.length) {
      throw Exception('Some commissions are not found or not approved');
    }

    final totalAmount = commissions.fold(0.0, (sum, c) => sum + c.netCommission);
    final platformFee = totalAmount * 0.01; // 1% payout processing fee
    final netAmount = totalAmount - platformFee;

    final payout = Payout(
      id: _uuid.v4(),
      salesAgentId: salesAgentId,
      salesAgentName: salesAgentName,
      commissionIds: commissionIds,
      totalAmount: totalAmount,
      platformFee: platformFee,
      netAmount: netAmount,
      method: method,
      bankAccountNumber: bankAccountNumber,
      bankName: bankName,
      bankCode: bankCode,
      recipientName: recipientName,
      scheduledDate: scheduledDate ?? DateTime.now().add(const Duration(days: 1)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _payouts.add(payout);

    // Mark commissions as paid
    for (final commissionId in commissionIds) {
      await _markCommissionAsPaid(commissionId);
    }

    return payout;
  }

  // Get payouts for a sales agent
  Future<List<Payout>> getSalesAgentPayouts(
    String salesAgentId, {
    PayoutStatus? status,
    int? limit,
    int? offset,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate API delay

    var payouts = _payouts
        .where((p) => p.salesAgentId == salesAgentId)
        .toList();

    if (status != null) {
      payouts = payouts.where((p) => p.status == status).toList();
    }

    // Sort by created date (newest first)
    payouts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (offset != null) {
      payouts = payouts.skip(offset).toList();
    }

    if (limit != null) {
      payouts = payouts.take(limit).toList();
    }

    return payouts;
  }

  // Process pending payouts (admin function)
  Future<void> processPayouts() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API delay

    final pendingPayouts = _payouts
        .where((p) => p.status == PayoutStatus.pending && 
                     p.scheduledDate.isBefore(DateTime.now()))
        .toList();

    for (final payout in pendingPayouts) {
      try {
        // Simulate payment processing
        await _processPayment(payout);
        
        final index = _payouts.indexWhere((p) => p.id == payout.id);
        if (index != -1) {
          _payouts[index] = payout.copyWith(
            status: PayoutStatus.completed,
            processedAt: DateTime.now(),
            completedAt: DateTime.now(),
            transactionReference: 'TXN${DateTime.now().millisecondsSinceEpoch}',
            updatedAt: DateTime.now(),
          );
        }
      } catch (e) {
        final index = _payouts.indexWhere((p) => p.id == payout.id);
        if (index != -1) {
          _payouts[index] = payout.copyWith(
            status: PayoutStatus.failed,
            failureReason: e.toString(),
            updatedAt: DateTime.now(),
          );
        }
      }
    }
  }

  // Get commission rate for sales agent
  double _getCommissionRate(String salesAgentId) {
    // In a real app, this would fetch from user profile/tier
    // For now, return a random tier rate
    final tiers = _defaultCommissionRates.keys.toList();
    final randomTier = tiers[Random().nextInt(tiers.length)];
    return _defaultCommissionRates[randomTier]!;
  }

  // Mark commission as paid
  Future<void> _markCommissionAsPaid(String commissionId) async {
    final index = _commissions.indexWhere((c) => c.id == commissionId);
    if (index != -1) {
      _commissions[index] = _commissions[index].copyWith(
        status: CommissionStatus.paid,
        paidAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  // Simulate payment processing
  Future<void> _processPayment(Payout payout) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate processing time
    
    // Simulate random success/failure
    if (Random().nextDouble() < 0.95) { // 95% success rate
      debugPrint('Payment processed successfully for ${payout.id}');
    } else {
      throw Exception('Payment processing failed');
    }
  }

  // Generate sample commissions for testing
  Future<void> generateSampleCommissions(String salesAgentId) async {
    if (_commissions.any((c) => c.salesAgentId == salesAgentId)) {
      return; // Already has commissions
    }

    final random = Random();
    final now = DateTime.now();

    for (int i = 0; i < 20; i++) {
      final orderDate = now.subtract(Duration(days: random.nextInt(90)));
      final orderAmount = 50.0 + random.nextDouble() * 500.0;
      final commissionRate = _defaultCommissionRates.values.elementAt(random.nextInt(4));
      final commissionAmount = orderAmount * commissionRate;
      final platformFee = commissionAmount * _platformFeeRate;
      final netCommission = commissionAmount - platformFee;

      final statuses = CommissionStatus.values;
      final status = statuses[random.nextInt(statuses.length)];

      final commission = Commission(
        id: _uuid.v4(),
        orderId: 'order_${i + 1}',
        orderNumber: 'ORD${(1000 + i).toString()}',
        salesAgentId: salesAgentId,
        salesAgentName: 'Test Agent',
        vendorId: 'vendor_${random.nextInt(5) + 1}',
        vendorName: 'Test Vendor ${random.nextInt(5) + 1}',
        customerId: 'customer_${random.nextInt(10) + 1}',
        customerName: 'Test Customer ${random.nextInt(10) + 1}',
        orderAmount: orderAmount,
        commissionRate: commissionRate,
        commissionAmount: commissionAmount,
        platformFee: platformFee,
        netCommission: netCommission,
        status: status,
        orderDate: orderDate,
        approvedAt: status != CommissionStatus.pending ? orderDate.add(const Duration(days: 1)) : null,
        paidAt: status == CommissionStatus.paid ? orderDate.add(const Duration(days: 7)) : null,
        createdAt: orderDate,
        updatedAt: DateTime.now(),
      );

      _commissions.add(commission);
    }
  }
}
