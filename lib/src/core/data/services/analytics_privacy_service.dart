import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/failures.dart';
import '../../utils/logger.dart';
import '../../../features/marketplace_wallet/data/repositories/customer_wallet_analytics_repository.dart';

/// Service for analytics privacy controls and permission validation
class AnalyticsPrivacyService {
  final CustomerWalletAnalyticsRepository _repository;
  final SupabaseClient _supabase = Supabase.instance.client;
  final AppLogger _logger = AppLogger();

  AnalyticsPrivacyService({
    required CustomerWalletAnalyticsRepository repository,
  }) : _repository = repository;

  /// Validate if user has analytics access permission
  Future<Either<Failure, bool>> validateAnalyticsAccess() async {
    try {
      debugPrint('🔒 [ANALYTICS-PRIVACY] Validating analytics access');

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return Left(AuthFailure(message: 'User not authenticated'));
      }

      final permissionResult = await _repository.hasAnalyticsPermission();
      return permissionResult.fold(
        (failure) => Left(failure),
        (hasPermission) {
          debugPrint('🔒 [ANALYTICS-PRIVACY] Analytics access validation: $hasPermission');
          return Right(hasPermission);
        },
      );
    } catch (e) {
      _logger.logError('Failed to validate analytics access', e);
      return Left(ServerFailure(message: 'Failed to validate analytics access: ${e.toString()}'));
    }
  }

  /// Validate if user can export analytics data
  Future<Either<Failure, bool>> validateExportPermission() async {
    try {
      debugPrint('🔒 [ANALYTICS-PRIVACY] Validating export permission');

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return Left(AuthFailure(message: 'User not authenticated'));
      }

      final exportResult = await _repository.canExportAnalytics();
      return exportResult.fold(
        (failure) => Left(failure),
        (canExport) {
          debugPrint('🔒 [ANALYTICS-PRIVACY] Export permission validation: $canExport');
          return Right(canExport);
        },
      );
    } catch (e) {
      _logger.logError('Failed to validate export permission', e);
      return Left(ServerFailure(message: 'Failed to validate export permission: ${e.toString()}'));
    }
  }

  /// Get current privacy settings for analytics
  Future<Either<Failure, Map<String, bool>>> getPrivacySettings() async {
    try {
      debugPrint('🔒 [ANALYTICS-PRIVACY] Getting privacy settings');

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return Left(AuthFailure(message: 'User not authenticated'));
      }

      // Get wallet settings
      final response = await _supabase
          .from('wallet_settings')
          .select('allow_analytics, share_transaction_data, allow_insights, allow_export')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (response == null) {
        // Return default privacy settings
        return const Right({
          'allow_analytics': false,
          'share_transaction_data': false,
          'allow_insights': false,
          'allow_export': false,
        });
      }

      final settings = <String, bool>{
        'allow_analytics': response['allow_analytics'] ?? false,
        'share_transaction_data': response['share_transaction_data'] ?? false,
        'allow_insights': response['allow_insights'] ?? false,
        'allow_export': response['allow_export'] ?? false,
      };

      debugPrint('🔒 [ANALYTICS-PRIVACY] Privacy settings retrieved: $settings');
      return Right(settings);
    } catch (e) {
      _logger.logError('Failed to get privacy settings', e);
      return Left(ServerFailure(message: 'Failed to get privacy settings: ${e.toString()}'));
    }
  }

  /// Update privacy settings for analytics
  Future<Either<Failure, void>> updatePrivacySettings({
    bool? allowAnalytics,
    bool? shareTransactionData,
    bool? allowInsights,
    bool? allowExport,
  }) async {
    try {
      debugPrint('🔒 [ANALYTICS-PRIVACY] Updating privacy settings');

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return Left(AuthFailure(message: 'User not authenticated'));
      }

      final updateData = <String, dynamic>{};
      if (allowAnalytics != null) updateData['allow_analytics'] = allowAnalytics;
      if (shareTransactionData != null) updateData['share_transaction_data'] = shareTransactionData;
      if (allowInsights != null) updateData['allow_insights'] = allowInsights;
      if (allowExport != null) updateData['allow_export'] = allowExport;

      if (updateData.isEmpty) {
        return const Right(null);
      }

      updateData['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from('wallet_settings')
          .upsert({
            'user_id': currentUser.id,
            ...updateData,
          });

      debugPrint('🔒 [ANALYTICS-PRIVACY] Privacy settings updated successfully');
      return const Right(null);
    } catch (e) {
      _logger.logError('Failed to update privacy settings', e);
      return Left(ServerFailure(message: 'Failed to update privacy settings: ${e.toString()}'));
    }
  }

  /// Check if specific analytics feature is allowed
  Future<Either<Failure, bool>> isFeatureAllowed(String feature) async {
    try {
      debugPrint('🔒 [ANALYTICS-PRIVACY] Checking if feature is allowed: $feature');

      final settingsResult = await getPrivacySettings();
      return settingsResult.fold(
        (failure) => Left(failure),
        (settings) {
          bool isAllowed = false;

          switch (feature.toLowerCase()) {
            case 'analytics':
            case 'view_analytics':
              isAllowed = settings['allow_analytics'] ?? false;
              break;
            case 'export':
            case 'export_data':
              isAllowed = (settings['allow_analytics'] ?? false) && 
                         (settings['allow_export'] ?? false);
              break;
            case 'insights':
            case 'view_insights':
              isAllowed = (settings['allow_analytics'] ?? false) && 
                         (settings['allow_insights'] ?? false);
              break;
            case 'share':
            case 'share_data':
              isAllowed = (settings['allow_analytics'] ?? false) && 
                         (settings['share_transaction_data'] ?? false);
              break;
            default:
              isAllowed = false;
          }

          debugPrint('🔒 [ANALYTICS-PRIVACY] Feature $feature allowed: $isAllowed');
          return Right(isAllowed);
        },
      );
    } catch (e) {
      _logger.logError('Failed to check feature permission', e);
      return Left(ServerFailure(message: 'Failed to check feature permission: ${e.toString()}'));
    }
  }

  /// Get anonymized data based on privacy settings
  Future<Either<Failure, Map<String, dynamic>>> getAnonymizedData(
    Map<String, dynamic> originalData,
  ) async {
    try {
      debugPrint('🔒 [ANALYTICS-PRIVACY] Anonymizing data based on privacy settings');

      final settingsResult = await getPrivacySettings();
      return settingsResult.fold(
        (failure) => Left(failure),
        (settings) {
          final anonymizedData = Map<String, dynamic>.from(originalData);

          // Remove sensitive data based on privacy settings
          if (!(settings['share_transaction_data'] ?? false)) {
            // Remove specific transaction details
            anonymizedData.remove('transaction_ids');
            anonymizedData.remove('vendor_names');
            anonymizedData.remove('specific_amounts');
          }

          if (!(settings['allow_insights'] ?? false)) {
            // Remove insight-related data
            anonymizedData.remove('spending_patterns');
            anonymizedData.remove('recommendations');
            anonymizedData.remove('behavioral_data');
          }

          // Always remove personally identifiable information
          anonymizedData.remove('user_id');
          anonymizedData.remove('wallet_id');
          anonymizedData.remove('personal_details');

          debugPrint('🔒 [ANALYTICS-PRIVACY] Data anonymized successfully');
          return Right(anonymizedData);
        },
      );
    } catch (e) {
      _logger.logError('Failed to anonymize data', e);
      return Left(ServerFailure(message: 'Failed to anonymize data: ${e.toString()}'));
    }
  }

  /// Log privacy-related access for audit purposes
  Future<void> logPrivacyAccess({
    required String action,
    required String feature,
    required bool granted,
    String? reason,
  }) async {
    try {
      debugPrint('🔒 [ANALYTICS-PRIVACY] Logging privacy access: $action for $feature');

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      await _supabase.from('analytics_access_log').insert({
        'user_id': currentUser.id,
        'wallet_id': null, // Will be populated by trigger
        'operation': '$action:$feature',
        'access_granted': granted,
        'error_message': reason,
        'accessed_at': DateTime.now().toIso8601String(),
      });

      debugPrint('🔒 [ANALYTICS-PRIVACY] Privacy access logged successfully');
    } catch (e) {
      _logger.logError('Failed to log privacy access', e);
      // Don't throw error for logging failures
    }
  }

  /// Get privacy compliance status
  Future<Either<Failure, Map<String, dynamic>>> getComplianceStatus() async {
    try {
      debugPrint('🔒 [ANALYTICS-PRIVACY] Getting privacy compliance status');

      final settingsResult = await getPrivacySettings();
      return settingsResult.fold(
        (failure) => Left(failure),
        (settings) {
          final complianceStatus = {
            'gdpr_compliant': _checkGDPRCompliance(settings),
            'data_minimization': _checkDataMinimization(settings),
            'user_consent': _checkUserConsent(settings),
            'data_portability': settings['allow_export'] ?? false,
            'right_to_be_forgotten': true, // Always supported
            'privacy_by_design': true, // Built into the system
            'last_updated': DateTime.now().toIso8601String(),
          };

          debugPrint('🔒 [ANALYTICS-PRIVACY] Compliance status: $complianceStatus');
          return Right(complianceStatus);
        },
      );
    } catch (e) {
      _logger.logError('Failed to get compliance status', e);
      return Left(ServerFailure(message: 'Failed to get compliance status: ${e.toString()}'));
    }
  }

  /// Check GDPR compliance
  bool _checkGDPRCompliance(Map<String, bool> settings) {
    // GDPR requires explicit consent for data processing
    return settings['allow_analytics'] == true;
  }

  /// Check data minimization principle
  bool _checkDataMinimization(Map<String, bool> settings) {
    // Data minimization: only collect what's necessary
    // If analytics is disabled, we're minimizing data collection
    return !(settings['allow_analytics'] == true && 
             settings['share_transaction_data'] == true &&
             settings['allow_insights'] == true &&
             settings['allow_export'] == true);
  }

  /// Check user consent status
  bool _checkUserConsent(Map<String, bool> settings) {
    // User has explicitly consented to analytics
    return settings['allow_analytics'] == true;
  }

  /// Generate privacy report for user
  Future<Either<Failure, Map<String, dynamic>>> generatePrivacyReport() async {
    try {
      debugPrint('🔒 [ANALYTICS-PRIVACY] Generating privacy report');

      final settingsResult = await getPrivacySettings();
      final complianceResult = await getComplianceStatus();

      return settingsResult.fold(
        (failure) => Left(failure),
        (settings) => complianceResult.fold(
          (failure) => Left(failure),
          (compliance) {
            final report = {
              'user_id': _supabase.auth.currentUser?.id,
              'privacy_settings': settings,
              'compliance_status': compliance,
              'data_collection': {
                'analytics_enabled': settings['allow_analytics'],
                'data_sharing_enabled': settings['share_transaction_data'],
                'insights_enabled': settings['allow_insights'],
                'export_enabled': settings['allow_export'],
              },
              'user_rights': {
                'right_to_access': true,
                'right_to_rectification': true,
                'right_to_erasure': true,
                'right_to_portability': settings['allow_export'],
                'right_to_object': true,
              },
              'generated_at': DateTime.now().toIso8601String(),
            };

            debugPrint('🔒 [ANALYTICS-PRIVACY] Privacy report generated');
            return Right(report);
          },
        ),
      );
    } catch (e) {
      _logger.logError('Failed to generate privacy report', e);
      return Left(ServerFailure(message: 'Failed to generate privacy report: ${e.toString()}'));
    }
  }

  /// Clear all analytics data for the current user
  Future<Either<Failure, void>> clearAnalyticsData() async {
    try {
      debugPrint('🔒 [ANALYTICS-PRIVACY] Clearing analytics data');

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return Left(AuthFailure(message: 'User not authenticated'));
      }

      // Clear analytics data from multiple tables
      await Future.wait([
        _supabase
            .from('wallet_analytics_summary')
            .delete()
            .eq('user_id', currentUser.id),
        _supabase
            .from('wallet_spending_categories')
            .delete()
            .eq('user_id', currentUser.id),
        // Clear any cached analytics data
        _supabase
            .from('wallet_analytics_cache')
            .delete()
            .eq('user_id', currentUser.id),
      ]);

      debugPrint('🔒 [ANALYTICS-PRIVACY] Analytics data cleared successfully');
      return const Right(null);
    } catch (e) {
      _logger.logError('Failed to clear analytics data', e);
      return Left(ServerFailure(message: 'Failed to clear analytics data: ${e.toString()}'));
    }
  }

  /// Request data deletion (GDPR right to be forgotten)
  Future<Either<Failure, void>> requestDataDeletion() async {
    try {
      debugPrint('🔒 [ANALYTICS-PRIVACY] Requesting data deletion');

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return Left(AuthFailure(message: 'User not authenticated'));
      }

      // Create data deletion request
      await _supabase.from('data_deletion_requests').insert({
        'user_id': currentUser.id,
        'request_type': 'analytics_data',
        'status': 'pending',
        'requested_at': DateTime.now().toIso8601String(),
      });

      // Immediately clear analytics data
      final clearResult = await clearAnalyticsData();

      return clearResult.fold(
        (failure) => Left(failure),
        (_) {
          debugPrint('🔒 [ANALYTICS-PRIVACY] Data deletion request submitted');
          return const Right(null);
        },
      );
    } catch (e) {
      _logger.logError('Failed to request data deletion', e);
      return Left(ServerFailure(message: 'Failed to request data deletion: ${e.toString()}'));
    }
  }
}
