import 'package:supabase_flutter/supabase_flutter.dart';

/// Real-time analytics service for wallet operations
class RealTimeAnalyticsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get real-time spending analytics
  Stream<Map<String, dynamic>> getSpendingAnalyticsStream(String customerId) {
    return _supabase
        .from('wallet_transactions')
        .stream(primaryKey: ['id'])
        .map((data) {
          // Filter data in the stream
          final filteredData = data.where((transaction) {
            final transactionCustomerId = transaction['customer_id'] as String?;
            return transactionCustomerId == customerId;
          }).toList();
          return _processSpendingData(filteredData);
        });
  }

  /// Get real-time transaction count
  Stream<int> getTransactionCountStream(String customerId) {
    return _supabase
        .from('wallet_transactions')
        .stream(primaryKey: ['id'])
        .map((data) {
          // Filter data in the stream
          final filteredData = data.where((transaction) {
            final transactionCustomerId = transaction['customer_id'] as String?;
            return transactionCustomerId == customerId;
          }).toList();
          return filteredData.length;
        });
  }

  /// Get real-time balance updates
  Stream<double> getBalanceStream(String customerId) {
    return _supabase
        .from('customer_wallets')
        .stream(primaryKey: ['id'])
        .map((data) {
          // Filter data in the stream
          final filteredData = data.where((wallet) {
            final walletCustomerId = wallet['customer_id'] as String?;
            return walletCustomerId == customerId;
          }).toList();

          if (filteredData.isEmpty) return 0.0;
          return (filteredData.first['available_balance'] as num?)?.toDouble() ?? 0.0;
        });
  }

  /// Get real-time monthly spending
  Stream<double> getMonthlySpendingStream(String customerId) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    return _supabase
        .from('wallet_transactions')
        .stream(primaryKey: ['id'])
        .map((data) {
          // Filter data in the stream
          final filteredData = data.where((transaction) {
            final transactionCustomerId = transaction['customer_id'] as String?;
            final createdAt = transaction['created_at'] as String?;
            final transactionType = transaction['transaction_type'] as String?;

            if (transactionCustomerId != customerId) return false;
            if (transactionType != 'debit') return false;
            if (createdAt == null) return false;

            final transactionDate = DateTime.tryParse(createdAt);
            return transactionDate != null && transactionDate.isAfter(startOfMonth);
          }).toList();

          return filteredData.fold<double>(0.0, (sum, transaction) {
            return sum + ((transaction['amount'] as num?)?.toDouble() ?? 0.0);
          });
        });
  }

  /// Get real-time category spending
  Stream<Map<String, double>> getCategorySpendingStream(String customerId) {
    return _supabase
        .from('wallet_transactions')
        .stream(primaryKey: ['id'])
        .map((data) {
          // Filter data in the stream
          final filteredData = data.where((transaction) {
            final transactionCustomerId = transaction['customer_id'] as String?;
            final transactionType = transaction['transaction_type'] as String?;
            return transactionCustomerId == customerId && transactionType == 'debit';
          }).toList();
          return _processCategoryData(filteredData);
        });
  }

  /// Process spending data for analytics
  Map<String, dynamic> _processSpendingData(List<Map<String, dynamic>> transactions) {
    double totalSpent = 0.0;
    double totalReceived = 0.0;
    int transactionCount = transactions.length;
    
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    double monthlySpent = 0.0;
    
    for (final transaction in transactions) {
      final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
      final type = transaction['transaction_type'] as String?;
      final createdAt = DateTime.tryParse(transaction['created_at'] as String? ?? '');
      
      if (type == 'debit') {
        totalSpent += amount;
        if (createdAt != null && createdAt.isAfter(startOfMonth)) {
          monthlySpent += amount;
        }
      } else if (type == 'credit') {
        totalReceived += amount;
      }
    }
    
    return {
      'total_spent': totalSpent,
      'total_received': totalReceived,
      'monthly_spent': monthlySpent,
      'transaction_count': transactionCount,
      'average_transaction': transactionCount > 0 ? totalSpent / transactionCount : 0.0,
    };
  }

  /// Process category data for analytics
  Map<String, double> _processCategoryData(List<Map<String, dynamic>> transactions) {
    final categoryTotals = <String, double>{};
    
    for (final transaction in transactions) {
      final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
      final category = transaction['category'] as String? ?? 'Other';
      
      categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
    }
    
    return categoryTotals;
  }

  /// Get real-time top merchants
  Stream<List<Map<String, dynamic>>> getTopMerchantsStream(String customerId) {
    return _supabase
        .from('wallet_transactions')
        .stream(primaryKey: ['id'])
        .map((data) {
          // Filter data in the stream
          final filteredData = data.where((transaction) {
            final transactionCustomerId = transaction['customer_id'] as String?;
            final transactionType = transaction['transaction_type'] as String?;
            return transactionCustomerId == customerId && transactionType == 'debit';
          }).toList();
          return _processTopMerchants(filteredData);
        });
  }

  /// Process top merchants data
  List<Map<String, dynamic>> _processTopMerchants(List<Map<String, dynamic>> transactions) {
    final merchantTotals = <String, double>{};
    
    for (final transaction in transactions) {
      final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
      final merchant = transaction['merchant_name'] as String? ?? 'Unknown';
      
      merchantTotals[merchant] = (merchantTotals[merchant] ?? 0.0) + amount;
    }
    
    // Convert to list and sort by amount
    final merchantList = merchantTotals.entries
        .map((entry) => {
              'name': entry.key,
              'total_spent': entry.value,
            })
        .toList();
    
    merchantList.sort((a, b) => (b['total_spent'] as double).compareTo(a['total_spent'] as double));
    
    return merchantList.take(10).toList(); // Top 10 merchants
  }

  /// Get real-time spending trends (last 30 days)
  Stream<List<Map<String, dynamic>>> getSpendingTrendsStream(String customerId) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    return _supabase
        .from('wallet_transactions')
        .stream(primaryKey: ['id'])
        .map((data) {
          // Filter data in the stream
          final filteredData = data.where((transaction) {
            final transactionCustomerId = transaction['customer_id'] as String?;
            final transactionType = transaction['transaction_type'] as String?;
            final createdAt = transaction['created_at'] as String?;

            if (transactionCustomerId != customerId) return false;
            if (transactionType != 'debit') return false;
            if (createdAt == null) return false;

            final transactionDate = DateTime.tryParse(createdAt);
            return transactionDate != null && transactionDate.isAfter(thirtyDaysAgo);
          }).toList();
          return _processSpendingTrends(filteredData);
        });
  }

  /// Process spending trends data
  List<Map<String, dynamic>> _processSpendingTrends(List<Map<String, dynamic>> transactions) {
    final dailyTotals = <String, double>{};
    
    for (final transaction in transactions) {
      final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
      final createdAt = DateTime.tryParse(transaction['created_at'] as String? ?? '');
      
      if (createdAt != null) {
        final dateKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
        dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0.0) + amount;
      }
    }
    
    // Convert to list and sort by date
    final trendsList = dailyTotals.entries
        .map((entry) => {
              'date': entry.key,
              'amount': entry.value,
            })
        .toList();
    
    trendsList.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    
    return trendsList;
  }

  /// Dispose resources
  void dispose() {
    // Clean up any resources if needed
  }
}
