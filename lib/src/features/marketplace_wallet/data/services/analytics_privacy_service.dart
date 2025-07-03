import 'package:supabase_flutter/supabase_flutter.dart';

/// Analytics privacy service for managing user data privacy
class AnalyticsPrivacyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get user privacy settings
  Future<Map<String, dynamic>> getPrivacySettings(String customerId) async {
    try {
      final response = await _supabase
          .from('customer_privacy_settings')
          .select()
          .eq('customer_id', customerId)
          .single();

      return response;
    } catch (e) {
      // Return default privacy settings if none exist
      return _getDefaultPrivacySettings();
    }
  }

  /// Update privacy settings
  Future<bool> updatePrivacySettings(String customerId, Map<String, dynamic> settings) async {
    try {
      await _supabase
          .from('customer_privacy_settings')
          .upsert({
            'customer_id': customerId,
            ...settings,
            'updated_at': DateTime.now().toIso8601String(),
          });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if analytics data collection is allowed
  Future<bool> isAnalyticsAllowed(String customerId) async {
    final settings = await getPrivacySettings(customerId);
    return settings['allow_analytics'] as bool? ?? true;
  }

  /// Check if data sharing is allowed
  Future<bool> isDataSharingAllowed(String customerId) async {
    final settings = await getPrivacySettings(customerId);
    return settings['allow_data_sharing'] as bool? ?? false;
  }

  /// Check if personalized recommendations are allowed
  Future<bool> isPersonalizationAllowed(String customerId) async {
    final settings = await getPrivacySettings(customerId);
    return settings['allow_personalization'] as bool? ?? true;
  }

  /// Anonymize transaction data for analytics
  Map<String, dynamic> anonymizeTransactionData(Map<String, dynamic> transaction) {
    final anonymized = Map<String, dynamic>.from(transaction);
    
    // Remove personally identifiable information
    anonymized.remove('customer_id');
    anonymized.remove('customer_name');
    anonymized.remove('customer_email');
    anonymized.remove('customer_phone');
    
    // Replace with anonymized identifiers
    anonymized['anonymous_id'] = _generateAnonymousId(transaction['customer_id'] as String?);
    
    // Keep only necessary fields for analytics
    return {
      'anonymous_id': anonymized['anonymous_id'],
      'amount': anonymized['amount'],
      'transaction_type': anonymized['transaction_type'],
      'category': anonymized['category'],
      'merchant_category': anonymized['merchant_category'],
      'created_at': anonymized['created_at'],
      'payment_method': anonymized['payment_method'],
    };
  }

  /// Generate anonymous ID from customer ID
  String _generateAnonymousId(String? customerId) {
    if (customerId == null) return 'anonymous';
    
    // Simple hash-based anonymization (in production, use proper hashing)
    return 'anon_${customerId.hashCode.abs()}';
  }

  /// Get filtered analytics data based on privacy settings
  Future<List<Map<String, dynamic>>> getFilteredAnalyticsData(
    String customerId,
    List<Map<String, dynamic>> rawData,
  ) async {
    final settings = await getPrivacySettings(customerId);
    final allowAnalytics = settings['allow_analytics'] as bool? ?? true;
    final allowDataSharing = settings['allow_data_sharing'] as bool? ?? false;
    
    if (!allowAnalytics) {
      return []; // Return empty data if analytics not allowed
    }
    
    if (!allowDataSharing) {
      // Return anonymized data
      return rawData.map((data) => anonymizeTransactionData(data)).toList();
    }
    
    return rawData; // Return full data if sharing is allowed
  }

  /// Export user data (GDPR compliance)
  Future<Map<String, dynamic>> exportUserData(String customerId) async {
    try {
      // Get all user data from various tables
      final walletData = await _supabase
          .from('customer_wallets')
          .select()
          .eq('customer_id', customerId);

      final transactionData = await _supabase
          .from('wallet_transactions')
          .select()
          .eq('customer_id', customerId);

      final privacySettings = await getPrivacySettings(customerId);

      return {
        'customer_id': customerId,
        'export_date': DateTime.now().toIso8601String(),
        'wallet_data': walletData,
        'transaction_data': transactionData,
        'privacy_settings': privacySettings,
      };
    } catch (e) {
      throw Exception('Failed to export user data: $e');
    }
  }

  /// Delete user data (GDPR right to be forgotten)
  Future<bool> deleteUserData(String customerId) async {
    try {
      // Delete from all related tables
      await _supabase
          .from('wallet_transactions')
          .delete()
          .eq('customer_id', customerId);

      await _supabase
          .from('customer_wallets')
          .delete()
          .eq('customer_id', customerId);

      await _supabase
          .from('customer_privacy_settings')
          .delete()
          .eq('customer_id', customerId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get data retention period
  Future<int> getDataRetentionPeriod(String customerId) async {
    final settings = await getPrivacySettings(customerId);
    return settings['data_retention_days'] as int? ?? 365; // Default 1 year
  }

  /// Clean up old data based on retention policy
  Future<void> cleanupOldData(String customerId) async {
    final retentionDays = await getDataRetentionPeriod(customerId);
    final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));

    try {
      await _supabase
          .from('wallet_transactions')
          .delete()
          .eq('customer_id', customerId)
          .lt('created_at', cutoffDate.toIso8601String());
    } catch (e) {
      // Log error but don't throw
    }
  }

  /// Get default privacy settings
  Map<String, dynamic> _getDefaultPrivacySettings() {
    return {
      'allow_analytics': true,
      'allow_data_sharing': false,
      'allow_personalization': true,
      'allow_marketing': false,
      'data_retention_days': 365,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Check if user has consented to data processing
  Future<bool> hasDataProcessingConsent(String customerId) async {
    final settings = await getPrivacySettings(customerId);
    return settings['data_processing_consent'] as bool? ?? false;
  }

  /// Record data processing consent
  Future<bool> recordDataProcessingConsent(String customerId, bool consent) async {
    try {
      await updatePrivacySettings(customerId, {
        'data_processing_consent': consent,
        'consent_date': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
