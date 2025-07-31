import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/logger.dart';
import '../../../../core/config/route_optimization_feature_flags.dart';

/// Beta Testing Program Service
/// Manages driver enrollment, feedback collection, performance monitoring,
/// and issue tracking for the route optimization beta testing program
class BetaTestingProgramService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AppLogger _logger = AppLogger();
  final RouteOptimizationFeatureFlags _featureFlags = RouteOptimizationFeatureFlags();

  static const String _programName = 'route_optimization';
  static const int _maxBetaDrivers = 50; // Start with 50 beta drivers
  static const Duration _feedbackReminderInterval = Duration(days: 3);

  /// Enroll a driver in the beta testing program
  Future<BetaEnrollmentResult> enrollDriver(String driverId, {
    String? enrolledBy,
    String? notes,
  }) async {
    try {
      // Check if beta testing is active
      if (!await _featureFlags.isBetaTestingActive()) {
        return BetaEnrollmentResult(
          success: false,
          message: 'Beta testing program is not currently active',
        );
      }

      // Check if driver is already enrolled
      final existingEnrollment = await _supabase
          .from('beta_testing_drivers')
          .select('*')
          .eq('driver_id', driverId)
          .eq('program_name', _programName)
          .maybeSingle();

      if (existingEnrollment != null) {
        if (existingEnrollment['status'] == 'active') {
          return BetaEnrollmentResult(
            success: false,
            message: 'Driver is already enrolled in the beta program',
          );
        } else {
          // Reactivate existing enrollment
          await _supabase
              .from('beta_testing_drivers')
              .update({
                'status': 'active',
                'enrolled_at': DateTime.now().toIso8601String(),
                'notes': notes,
              })
              .eq('id', existingEnrollment['id']);

          await _updateBetaDriverList();
          
          return BetaEnrollmentResult(
            success: true,
            message: 'Driver successfully re-enrolled in beta program',
          );
        }
      }

      // Check beta program capacity
      final currentBetaCount = await _getBetaDriverCount();
      if (currentBetaCount >= _maxBetaDrivers) {
        return BetaEnrollmentResult(
          success: false,
          message: 'Beta program is at capacity. Please try again later.',
        );
      }

      // Verify driver exists and is eligible
      final driver = await _supabase
          .from('drivers')
          .select('id, user_id, status, created_at')
          .eq('id', driverId)
          .single();

      if (driver['status'] != 'active') {
        return BetaEnrollmentResult(
          success: false,
          message: 'Driver must be active to join beta program',
        );
      }

      // Check driver experience (must be active for at least 30 days)
      final driverCreated = DateTime.parse(driver['created_at']);
      final daysSinceCreated = DateTime.now().difference(driverCreated).inDays;
      if (daysSinceCreated < 30) {
        return BetaEnrollmentResult(
          success: false,
          message: 'Driver must be active for at least 30 days to join beta program',
        );
      }

      // Enroll driver
      await _supabase
          .from('beta_testing_drivers')
          .insert({
            'driver_id': driverId,
            'program_name': _programName,
            'status': 'active',
            'enrolled_at': DateTime.now().toIso8601String(),
            'enrolled_by': enrolledBy,
            'notes': notes,
          });

      // Update feature flag beta driver list
      await _updateBetaDriverList();

      _logger.info('Driver $driverId enrolled in beta testing program');

      return BetaEnrollmentResult(
        success: true,
        message: 'Driver successfully enrolled in beta program',
      );

    } catch (e) {
      _logger.error('Failed to enroll driver in beta program: $e');
      return BetaEnrollmentResult(
        success: false,
        message: 'Failed to enroll driver: ${e.toString()}',
      );
    }
  }

  /// Remove a driver from the beta testing program
  Future<bool> unenrollDriver(String driverId, {String? reason}) async {
    try {
      await _supabase
          .from('beta_testing_drivers')
          .update({
            'status': 'inactive',
            'notes': reason != null ? 'Unenrolled: $reason' : 'Unenrolled',
          })
          .eq('driver_id', driverId)
          .eq('program_name', _programName);

      await _updateBetaDriverList();

      _logger.info('Driver $driverId unenrolled from beta testing program');
      return true;
    } catch (e) {
      _logger.error('Failed to unenroll driver from beta program: $e');
      return false;
    }
  }

  /// Get list of all beta testing drivers
  Future<List<BetaDriver>> getBetaDrivers({String status = 'active'}) async {
    try {
      final response = await _supabase
          .from('beta_testing_drivers')
          .select('''
            *,
            drivers:driver_id (
              id,
              user_id,
              status,
              created_at,
              user_profiles:user_id (
                full_name,
                phone_number
              )
            )
          ''')
          .eq('program_name', _programName)
          .eq('status', status)
          .order('enrolled_at', ascending: false);

      return response.map((data) => BetaDriver.fromJson(data)).toList();
    } catch (e) {
      _logger.error('Failed to get beta drivers: $e');
      return [];
    }
  }

  /// Get beta testing status for a specific driver
  Future<BetaDriverStatus?> getDriverBetaStatus(String driverId) async {
    try {
      final response = await _supabase
          .from('beta_testing_drivers')
          .select('*')
          .eq('driver_id', driverId)
          .eq('program_name', _programName)
          .maybeSingle();

      if (response == null) return null;

      return BetaDriverStatus.fromJson(response);
    } catch (e) {
      _logger.error('Failed to get driver beta status: $e');
      return null;
    }
  }

  /// Submit beta feedback
  Future<bool> submitFeedback(String driverId, BetaFeedback feedback) async {
    try {
      // Insert feedback
      await _supabase
          .from('beta_feedback')
          .insert({
            'driver_id': driverId,
            'program_name': _programName,
            'feedback_type': feedback.type.name,
            'rating': feedback.rating,
            'title': feedback.title,
            'description': feedback.description,
            'feature_area': feedback.featureArea,
            'severity': feedback.severity?.name,
            'steps_to_reproduce': feedback.stepsToReproduce,
            'expected_behavior': feedback.expectedBehavior,
            'actual_behavior': feedback.actualBehavior,
            'device_info': feedback.deviceInfo,
            'app_version': feedback.appVersion,
            'submitted_at': DateTime.now().toIso8601String(),
          });

      // Update feedback count for driver
      await _supabase.rpc('increment_beta_feedback_count', params: {
        'driver_id': driverId,
        'program_name': _programName,
      });

      _logger.info('Beta feedback submitted by driver $driverId');
      return true;
    } catch (e) {
      _logger.error('Failed to submit beta feedback: $e');
      return false;
    }
  }

  /// Get beta feedback for analysis
  Future<List<BetaFeedback>> getBetaFeedback({
    String? driverId,
    FeedbackType? type,
    DateTime? since,
    int limit = 100,
  }) async {
    try {
      var query = _supabase
          .from('beta_feedback')
          .select('*')
          .eq('program_name', _programName);

      if (driverId != null) {
        query = query.eq('driver_id', driverId);
      }

      if (type != null) {
        query = query.eq('feedback_type', type.name);
      }

      if (since != null) {
        query = query.gte('submitted_at', since.toIso8601String());
      }

      final response = await query
          .order('submitted_at', ascending: false)
          .limit(limit);
      return response.map((data) => BetaFeedback.fromJson(data)).toList();
    } catch (e) {
      _logger.error('Failed to get beta feedback: $e');
      return [];
    }
  }

  /// Get beta program statistics
  Future<BetaProgramStats> getBetaProgramStats() async {
    try {
      final stats = await _supabase.rpc('get_beta_program_stats', params: {
        'program_name': _programName,
      });

      return BetaProgramStats.fromJson(stats);
    } catch (e) {
      _logger.error('Failed to get beta program stats: $e');
      return BetaProgramStats.empty();
    }
  }

  /// Update performance score for a beta driver
  Future<void> updateDriverPerformanceScore(String driverId, double score) async {
    try {
      await _supabase
          .from('beta_testing_drivers')
          .update({'performance_score': score})
          .eq('driver_id', driverId)
          .eq('program_name', _programName);

      _logger.info('Updated performance score for beta driver $driverId: $score');
    } catch (e) {
      _logger.error('Failed to update driver performance score: $e');
    }
  }

  /// Send feedback reminder to beta drivers
  Future<void> sendFeedbackReminders() async {
    try {
      final betaDrivers = await getBetaDrivers();
      final cutoffDate = DateTime.now().subtract(_feedbackReminderInterval);

      for (final driver in betaDrivers) {
        // Check if driver has submitted feedback recently
        final recentFeedback = await _supabase
            .from('beta_feedback')
            .select('id')
            .eq('driver_id', driver.driverId)
            .eq('program_name', _programName)
            .gte('submitted_at', cutoffDate.toIso8601String())
            .limit(1);

        if (recentFeedback.isEmpty) {
          // Send reminder (would integrate with notification system)
          await _sendFeedbackReminderNotification(driver.driverId);
        }
      }
    } catch (e) {
      _logger.error('Failed to send feedback reminders: $e');
    }
  }

  /// Get current beta driver count
  Future<int> _getBetaDriverCount() async {
    final response = await _supabase
        .from('beta_testing_drivers')
        .select('id')
        .eq('program_name', _programName)
        .eq('status', 'active');
    
    return response.length;
  }

  /// Update the beta driver list in feature flags
  Future<void> _updateBetaDriverList() async {
    try {
      final betaDrivers = await _supabase
          .from('beta_testing_drivers')
          .select('driver_id')
          .eq('program_name', _programName)
          .eq('status', 'active');

      final driverIds = betaDrivers.map((d) => d['driver_id'] as String).toList();

      await _supabase
          .from('feature_flags')
          .update({
            'flag_value': driverIds.toString(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('feature_group', 'route_optimization')
          .eq('flag_key', 'beta_driver_list');

      // Refresh feature flags cache
      await _featureFlags.refreshCache();

    } catch (e) {
      _logger.error('Failed to update beta driver list: $e');
    }
  }

  /// Send feedback reminder notification (placeholder)
  Future<void> _sendFeedbackReminderNotification(String driverId) async {
    // This would integrate with the notification system
    debugPrint('📧 Sending feedback reminder to driver: $driverId');
  }
}

/// Beta enrollment result
class BetaEnrollmentResult {
  final bool success;
  final String message;

  const BetaEnrollmentResult({
    required this.success,
    required this.message,
  });
}

/// Beta driver model
class BetaDriver {
  final String id;
  final String driverId;
  final String programName;
  final DateTime enrolledAt;
  final String status;
  final int feedbackCount;
  final double? performanceScore;
  final String? notes;
  final String? driverName;
  final String? phoneNumber;

  const BetaDriver({
    required this.id,
    required this.driverId,
    required this.programName,
    required this.enrolledAt,
    required this.status,
    required this.feedbackCount,
    this.performanceScore,
    this.notes,
    this.driverName,
    this.phoneNumber,
  });

  factory BetaDriver.fromJson(Map<String, dynamic> json) {
    final driver = json['drivers'] as Map<String, dynamic>?;
    final profile = driver?['user_profiles'] as Map<String, dynamic>?;

    return BetaDriver(
      id: json['id'],
      driverId: json['driver_id'],
      programName: json['program_name'],
      enrolledAt: DateTime.parse(json['enrolled_at']),
      status: json['status'],
      feedbackCount: json['feedback_count'] ?? 0,
      performanceScore: json['performance_score']?.toDouble(),
      notes: json['notes'],
      driverName: profile?['full_name'],
      phoneNumber: profile?['phone_number'],
    );
  }
}

/// Beta driver status
class BetaDriverStatus {
  final String status;
  final DateTime enrolledAt;
  final int feedbackCount;
  final double? performanceScore;

  const BetaDriverStatus({
    required this.status,
    required this.enrolledAt,
    required this.feedbackCount,
    this.performanceScore,
  });

  factory BetaDriverStatus.fromJson(Map<String, dynamic> json) {
    return BetaDriverStatus(
      status: json['status'],
      enrolledAt: DateTime.parse(json['enrolled_at']),
      feedbackCount: json['feedback_count'] ?? 0,
      performanceScore: json['performance_score']?.toDouble(),
    );
  }

  bool get isActive => status == 'active';
}

/// Feedback types
enum FeedbackType {
  bug,
  featureRequest,
  improvement,
  performance,
  usability,
  general;
}

/// Feedback severity
enum FeedbackSeverity {
  low,
  medium,
  high,
  critical;
}

/// Beta feedback model
class BetaFeedback {
  final String id;
  final String driverId;
  final FeedbackType type;
  final int? rating;
  final String title;
  final String description;
  final String? featureArea;
  final FeedbackSeverity? severity;
  final String? stepsToReproduce;
  final String? expectedBehavior;
  final String? actualBehavior;
  final String? deviceInfo;
  final String? appVersion;
  final DateTime submittedAt;

  const BetaFeedback({
    required this.id,
    required this.driverId,
    required this.type,
    this.rating,
    required this.title,
    required this.description,
    this.featureArea,
    this.severity,
    this.stepsToReproduce,
    this.expectedBehavior,
    this.actualBehavior,
    this.deviceInfo,
    this.appVersion,
    required this.submittedAt,
  });

  factory BetaFeedback.fromJson(Map<String, dynamic> json) {
    return BetaFeedback(
      id: json['id'],
      driverId: json['driver_id'],
      type: FeedbackType.values.firstWhere(
        (t) => t.name == json['feedback_type'],
        orElse: () => FeedbackType.general,
      ),
      rating: json['rating'],
      title: json['title'],
      description: json['description'],
      featureArea: json['feature_area'],
      severity: json['severity'] != null
          ? FeedbackSeverity.values.firstWhere(
              (s) => s.name == json['severity'],
              orElse: () => FeedbackSeverity.medium,
            )
          : null,
      stepsToReproduce: json['steps_to_reproduce'],
      expectedBehavior: json['expected_behavior'],
      actualBehavior: json['actual_behavior'],
      deviceInfo: json['device_info'],
      appVersion: json['app_version'],
      submittedAt: DateTime.parse(json['submitted_at']),
    );
  }
}

/// Beta program statistics
class BetaProgramStats {
  final int totalDrivers;
  final int activeDrivers;
  final int totalFeedback;
  final double averageRating;
  final int bugReports;
  final int featureRequests;
  final double averagePerformanceScore;

  const BetaProgramStats({
    required this.totalDrivers,
    required this.activeDrivers,
    required this.totalFeedback,
    required this.averageRating,
    required this.bugReports,
    required this.featureRequests,
    required this.averagePerformanceScore,
  });

  factory BetaProgramStats.fromJson(Map<String, dynamic> json) {
    return BetaProgramStats(
      totalDrivers: json['total_drivers'] ?? 0,
      activeDrivers: json['active_drivers'] ?? 0,
      totalFeedback: json['total_feedback'] ?? 0,
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      bugReports: json['bug_reports'] ?? 0,
      featureRequests: json['feature_requests'] ?? 0,
      averagePerformanceScore: (json['average_performance_score'] ?? 0.0).toDouble(),
    );
  }

  factory BetaProgramStats.empty() {
    return const BetaProgramStats(
      totalDrivers: 0,
      activeDrivers: 0,
      totalFeedback: 0,
      averageRating: 0.0,
      bugReports: 0,
      featureRequests: 0,
      averagePerformanceScore: 0.0,
    );
  }
}
