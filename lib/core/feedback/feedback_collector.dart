import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackCollector {
  static final FeedbackCollector _instance = FeedbackCollector._internal();
  factory FeedbackCollector() => _instance;
  FeedbackCollector._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Collect customization-specific feedback
  Future<void> collectCustomizationFeedback({
    required String userId,
    required String userRole,
    required String menuItemId,
    required String feedbackType,
    required int rating,
    String? comments,
    Map<String, dynamic>? customizationData,
    Map<String, dynamic>? usabilityMetrics,
  }) async {
    try {
      final feedback = UserFeedback(
        userId: userId,
        userRole: userRole,
        category: 'customization',
        subcategory: feedbackType,
        rating: rating,
        comments: comments,
        metadata: {
          'menu_item_id': menuItemId,
          if (customizationData != null) 'customization_data': customizationData,
          if (usabilityMetrics != null) 'usability_metrics': usabilityMetrics,
        },
        timestamp: DateTime.now(),
      );

      await _supabase.from('user_feedback').insert(feedback.toJson());

      if (kDebugMode) {
        print('📝 FeedbackCollector: Customization feedback collected for $menuItemId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('📝 FeedbackCollector: Error collecting feedback: $e');
      }
    }
  }

  // Collect general feature feedback
  Future<void> collectFeatureFeedback({
    required String userId,
    required String userRole,
    required String feature,
    required int rating,
    String? comments,
    Map<String, dynamic>? featureUsage,
  }) async {
    try {
      final feedback = UserFeedback(
        userId: userId,
        userRole: userRole,
        category: 'feature',
        subcategory: feature,
        rating: rating,
        comments: comments,
        metadata: {
          if (featureUsage != null) 'feature_usage': featureUsage,
        },
        timestamp: DateTime.now(),
      );

      await _supabase.from('user_feedback').insert(feedback.toJson());

      if (kDebugMode) {
        print('📝 FeedbackCollector: Feature feedback collected for $feature');
      }
    } catch (e) {
      if (kDebugMode) {
        print('📝 FeedbackCollector: Error collecting feedback: $e');
      }
    }
  }

  // Collect usability feedback
  Future<void> collectUsabilityFeedback({
    required String userId,
    required String userRole,
    required String screen,
    required String action,
    required int difficultyRating,
    required int satisfactionRating,
    String? suggestions,
    Map<String, dynamic>? interactionData,
  }) async {
    try {
      final feedback = UserFeedback(
        userId: userId,
        userRole: userRole,
        category: 'usability',
        subcategory: '${screen}_$action',
        rating: satisfactionRating,
        comments: suggestions,
        metadata: {
          'screen': screen,
          'action': action,
          'difficulty_rating': difficultyRating,
          'satisfaction_rating': satisfactionRating,
          if (interactionData != null) 'interaction_data': interactionData,
        },
        timestamp: DateTime.now(),
      );

      await _supabase.from('user_feedback').insert(feedback.toJson());

      if (kDebugMode) {
        print('📝 FeedbackCollector: Usability feedback collected for $screen/$action');
      }
    } catch (e) {
      if (kDebugMode) {
        print('📝 FeedbackCollector: Error collecting feedback: $e');
      }
    }
  }

  // Collect bug reports
  Future<void> collectBugReport({
    required String userId,
    required String userRole,
    required String bugDescription,
    required String severity,
    String? stepsToReproduce,
    String? expectedBehavior,
    String? actualBehavior,
    Map<String, dynamic>? deviceInfo,
    Map<String, dynamic>? errorData,
  }) async {
    try {
      final feedback = UserFeedback(
        userId: userId,
        userRole: userRole,
        category: 'bug_report',
        subcategory: severity,
        rating: 1, // Bug reports are always low satisfaction
        comments: bugDescription,
        metadata: {
          'steps_to_reproduce': stepsToReproduce,
          'expected_behavior': expectedBehavior,
          'actual_behavior': actualBehavior,
          if (deviceInfo != null) 'device_info': deviceInfo,
          if (errorData != null) 'error_data': errorData,
        },
        timestamp: DateTime.now(),
      );

      await _supabase.from('user_feedback').insert(feedback.toJson());

      if (kDebugMode) {
        print('📝 FeedbackCollector: Bug report collected: $severity');
      }
    } catch (e) {
      if (kDebugMode) {
        print('📝 FeedbackCollector: Error collecting bug report: $e');
      }
    }
  }

  // Collect feature requests
  Future<void> collectFeatureRequest({
    required String userId,
    required String userRole,
    required String featureTitle,
    required String featureDescription,
    required int priority,
    String? businessJustification,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final feedback = UserFeedback(
        userId: userId,
        userRole: userRole,
        category: 'feature_request',
        subcategory: 'priority_$priority',
        rating: priority,
        comments: featureDescription,
        metadata: {
          'feature_title': featureTitle,
          'business_justification': businessJustification,
          if (additionalData != null) ...additionalData,
        },
        timestamp: DateTime.now(),
      );

      await _supabase.from('user_feedback').insert(feedback.toJson());

      if (kDebugMode) {
        print('📝 FeedbackCollector: Feature request collected: $featureTitle');
      }
    } catch (e) {
      if (kDebugMode) {
        print('📝 FeedbackCollector: Error collecting feature request: $e');
      }
    }
  }

  // Get feedback analytics
  Future<FeedbackAnalytics> getFeedbackAnalytics({
    String? category,
    String? userRole,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase.from('user_feedback').select();

      if (category != null) {
        query = query.eq('category', category);
      }
      if (userRole != null) {
        query = query.eq('user_role', userRole);
      }
      if (startDate != null) {
        query = query.gte('timestamp', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('timestamp', endDate.toIso8601String());
      }

      final response = await query;
      final feedbackList = response.map((data) => UserFeedback.fromJson(data)).toList();

      return FeedbackAnalytics.fromFeedbackList(feedbackList);
    } catch (e) {
      if (kDebugMode) {
        print('📝 FeedbackCollector: Error getting analytics: $e');
      }
      return FeedbackAnalytics.empty();
    }
  }
}

class UserFeedback {
  final String userId;
  final String userRole;
  final String category;
  final String subcategory;
  final int rating;
  final String? comments;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  UserFeedback({
    required this.userId,
    required this.userRole,
    required this.category,
    required this.subcategory,
    required this.rating,
    this.comments,
    required this.metadata,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_role': userRole,
      'category': category,
      'subcategory': subcategory,
      'rating': rating,
      'comments': comments,
      'metadata': jsonEncode(metadata),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory UserFeedback.fromJson(Map<String, dynamic> json) {
    return UserFeedback(
      userId: json['user_id'],
      userRole: json['user_role'],
      category: json['category'],
      subcategory: json['subcategory'],
      rating: json['rating'],
      comments: json['comments'],
      metadata: json['metadata'] != null ? jsonDecode(json['metadata']) : {},
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class FeedbackAnalytics {
  final int totalFeedback;
  final double averageRating;
  final Map<String, int> categoryBreakdown;
  final Map<String, int> userRoleBreakdown;
  final Map<String, double> categoryRatings;
  final List<String> topIssues;
  final List<String> topRequests;

  FeedbackAnalytics({
    required this.totalFeedback,
    required this.averageRating,
    required this.categoryBreakdown,
    required this.userRoleBreakdown,
    required this.categoryRatings,
    required this.topIssues,
    required this.topRequests,
  });

  factory FeedbackAnalytics.fromFeedbackList(List<UserFeedback> feedbackList) {
    if (feedbackList.isEmpty) {
      return FeedbackAnalytics.empty();
    }

    final categoryBreakdown = <String, int>{};
    final userRoleBreakdown = <String, int>{};
    final categoryRatings = <String, List<int>>{};
    final issues = <String>[];
    final requests = <String>[];

    for (final feedback in feedbackList) {
      categoryBreakdown[feedback.category] = (categoryBreakdown[feedback.category] ?? 0) + 1;
      userRoleBreakdown[feedback.userRole] = (userRoleBreakdown[feedback.userRole] ?? 0) + 1;
      
      categoryRatings.putIfAbsent(feedback.category, () => []).add(feedback.rating);

      if (feedback.category == 'bug_report' && feedback.comments != null) {
        issues.add(feedback.comments!);
      }
      if (feedback.category == 'feature_request' && feedback.comments != null) {
        requests.add(feedback.comments!);
      }
    }

    final avgCategoryRatings = categoryRatings.map(
      (category, ratings) => MapEntry(
        category,
        ratings.reduce((a, b) => a + b) / ratings.length,
      ),
    );

    final totalRating = feedbackList.map((f) => f.rating).reduce((a, b) => a + b);
    final averageRating = totalRating / feedbackList.length;

    return FeedbackAnalytics(
      totalFeedback: feedbackList.length,
      averageRating: averageRating,
      categoryBreakdown: categoryBreakdown,
      userRoleBreakdown: userRoleBreakdown,
      categoryRatings: avgCategoryRatings,
      topIssues: issues.take(10).toList(),
      topRequests: requests.take(10).toList(),
    );
  }

  factory FeedbackAnalytics.empty() {
    return FeedbackAnalytics(
      totalFeedback: 0,
      averageRating: 0,
      categoryBreakdown: {},
      userRoleBreakdown: {},
      categoryRatings: {},
      topIssues: [],
      topRequests: [],
    );
  }
}
