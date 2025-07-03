
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/errors/error_handler.dart';
import '../../core/utils/logger.dart';



/// Base repository class that provides common functionality for all repositories
abstract class BaseRepository {
  final SupabaseClient _client;
  final AppLogger _logger = AppLogger();

  // Track recently created sessions to avoid aggressive expiry checks
  static final Map<String, DateTime> _recentSessions = <String, DateTime>{};

  BaseRepository({
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  /// Get the Supabase client
  SupabaseClient get client => _client;

  /// Mark a session as recently created to avoid aggressive expiry checks
  static void markSessionAsRecent(String sessionId) {
    _recentSessions[sessionId] = DateTime.now();

    // Clean up old entries (older than 10 minutes)
    final cutoff = DateTime.now().subtract(const Duration(minutes: 10));
    _recentSessions.removeWhere((key, value) => value.isBefore(cutoff));
  }

  /// Check if a session was recently created (within last 5 minutes)
  static bool isSessionRecent(String sessionId) {
    final sessionTime = _recentSessions[sessionId];
    if (sessionTime == null) return false;

    final age = DateTime.now().difference(sessionTime);
    return age.inMinutes < 5;
  }

  /// Get authenticated Supabase client with comprehensive session validation
  Future<SupabaseClient> getAuthenticatedClient() async {
    // Check if user is authenticated
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      debugPrint('BaseRepository: No authenticated user found');
      throw Exception('User not authenticated. Please log in and try again.');
    }

    // Validate session for all platforms (not just web)
    final session = _client.auth.currentSession;
    if (session == null) {
      debugPrint('BaseRepository: No active session found');
      throw Exception('No active session. Please log in again.');
    }

    if (session.isExpired) {
      debugPrint('BaseRepository: Session expired at ${session.expiresAt}');
      debugPrint('BaseRepository: Attempting to refresh expired session');

      try {
        // Attempt to refresh the expired session immediately
        final refreshResponse = await _client.auth.refreshSession();
        if (refreshResponse.session == null) {
          debugPrint('BaseRepository: Session refresh failed - no session returned');
          throw Exception('Session expired and refresh failed. Please log in again.');
        }
        debugPrint('BaseRepository: Session refreshed successfully');
      } catch (e) {
        debugPrint('BaseRepository: Session refresh failed: $e');
        throw Exception('Session expired and refresh failed. Please log in again.');
      }
    }

    // Additional validation for session integrity
    if (session.accessToken.isEmpty) {
      debugPrint('BaseRepository: Invalid access token');
      throw Exception('Invalid session. Please log in again.');
    }

    debugPrint('BaseRepository: Using authenticated client');
    debugPrint('BaseRepository: User ID: ${currentUser.id}');
    debugPrint('BaseRepository: User email: ${currentUser.email}');
    debugPrint('BaseRepository: Session expires at: ${session.expiresAt}');

    // Return the client which should have the authentication context
    return _client;
  }

  /// Get current Supabase user ID
  String? get currentUserUid {
    return _client.auth.currentUser?.id;
  }

  /// Check if user is authenticated
  bool get isAuthenticated {
    return _client.auth.currentUser != null;
  }

  /// Handle Supabase errors and convert them to user-friendly messages
  String handleSupabaseError(Object error) {
    if (error is PostgrestException) {
      switch (error.code) {
        case '23505': // Unique violation
          return 'This record already exists';
        case '23503': // Foreign key violation
          return 'Referenced record does not exist';
        case '42501': // Insufficient privilege
          return 'You do not have permission to perform this action';
        default:
          return error.message;
      }
    } else if (error is StorageException) {
      switch (error.statusCode) {
        case '413':
          return 'File is too large';
        case '415':
          return 'File type not supported';
        default:
          return error.message;
      }
    }
    return error.toString();
  }

  /// Execute a query with automatic authentication
  Future<T> executeQuery<T>(Future<T> Function() query) async {
    try {
      return await query();
    } catch (e) {
      debugPrint('BaseRepository: Query error: $e');
      rethrow;
    }
  }

  /// Execute a query that returns a stream with automatic authentication and error handling
  Stream<T> executeStreamQuery<T>(Stream<T> Function() query) async* {
    try {
      // Ensure we have a valid session before setting up the stream
      await refreshSessionIfNeeded();
      await getAuthenticatedClient();

      debugPrint('BaseRepository: Setting up authenticated stream');
      yield* query();
    } catch (e) {
      debugPrint('BaseRepository: Stream query error: $e');

      // Check if it's an authentication error
      if (e.toString().contains('expired') || e.toString().contains('unauthorized')) {
        try {
          debugPrint('BaseRepository: Authentication error in stream, attempting session refresh');
          await _client.auth.refreshSession();

          // Retry the stream setup once after session refresh
          yield* query();
        } catch (retryError) {
          debugPrint('BaseRepository: Stream setup failed even after session refresh: $retryError');
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  /// Refresh session if needed with comprehensive validation
  Future<void> refreshSessionIfNeeded() async {
    try {
      final session = _client.auth.currentSession;
      final now = DateTime.now();
      final currentTimestamp = now.millisecondsSinceEpoch ~/ 1000;

      debugPrint('BaseRepository: === SESSION ANALYSIS ===');
      debugPrint('BaseRepository: Current session exists: ${session != null}');

      if (session != null) {
        final expiresAt = session.expiresAt ?? 0;
        debugPrint('BaseRepository: Session expires at timestamp: $expiresAt');
        debugPrint('BaseRepository: Current timestamp: $currentTimestamp');
        debugPrint('BaseRepository: Time difference: ${expiresAt - currentTimestamp} seconds');
        debugPrint('BaseRepository: Session.isExpired: ${session.isExpired}');
        debugPrint('BaseRepository: Manual expiry check: ${expiresAt <= currentTimestamp}');
        debugPrint('BaseRepository: Session access token length: ${session.accessToken.length}');
        debugPrint('BaseRepository: Session refresh token exists: ${session.refreshToken != null}');
      }

      if (session == null) {
        debugPrint('BaseRepository: No session found, user needs to log in');
        throw Exception('No active session. Please log in again.');
      }

      // Use manual expiry check instead of session.isExpired
      final isManuallyExpired = (session.expiresAt ?? 0) <= currentTimestamp;
      final timeDifference = (session.expiresAt ?? 0) - currentTimestamp;
      debugPrint('BaseRepository: Using manual expiry check: $isManuallyExpired vs session.isExpired: ${session.isExpired}');

      // Check if session is severely expired (more than 1 hour old)
      // BUT avoid this logic for recently created sessions
      final sessionId = session.accessToken.substring(0, 20); // Use first 20 chars as session ID
      final isTrackedRecentSession = isSessionRecent(sessionId);
      final sessionAge = currentTimestamp - (session.expiresAt ?? 0) + 3600; // Approximate session creation time
      final isRecentByAge = sessionAge < 300; // Less than 5 minutes old
      final isRecentSession = isTrackedRecentSession || isRecentByAge;

      if (isManuallyExpired && timeDifference < -3600 && !isRecentSession) {
        debugPrint('BaseRepository: Session is severely expired (${-timeDifference} seconds old) and not recent, forcing sign out and re-authentication');
        try {
          await _client.auth.signOut();
          throw Exception('Session severely expired. Please log in again.');
        } catch (e) {
          debugPrint('BaseRepository: Error during forced sign out: $e');
          throw Exception('Session severely expired. Please log in again.');
        }
      } else if (isManuallyExpired && timeDifference < -3600 && isRecentSession) {
        debugPrint('BaseRepository: Session appears expired but is recent (tracked: $isTrackedRecentSession, age: ${sessionAge}s), allowing refresh attempt');
      }

      if (isManuallyExpired) {
        debugPrint('BaseRepository: Session manually determined as expired, refreshing...');

        try {
          debugPrint('BaseRepository: Starting session refresh with 15-second timeout...');
          final refreshResponse = await _client.auth.refreshSession().timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint('BaseRepository: Session refresh timed out after 15 seconds');
              throw Exception('Session refresh timeout after 15 seconds. Please check your connection.');
            },
          );

          debugPrint('BaseRepository: Session refresh response received');
          debugPrint('BaseRepository: Refresh response session exists: ${refreshResponse.session != null}');
          debugPrint('BaseRepository: Refresh response user exists: ${refreshResponse.user != null}');

          if (refreshResponse.session == null) {
            debugPrint('BaseRepository: Session refresh failed - no session returned');
            throw Exception('Session refresh failed. Please log in again.');
          }

          final newSession = refreshResponse.session!;
          final newCurrentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

          debugPrint('BaseRepository: === SESSION REFRESH SUCCESS ===');
          debugPrint('BaseRepository: New session expires at: ${newSession.expiresAt}');
          debugPrint('BaseRepository: New session access token length: ${newSession.accessToken.length}');
          debugPrint('BaseRepository: New session refresh token exists: ${newSession.refreshToken != null}');
          debugPrint('BaseRepository: Current timestamp after refresh: $newCurrentTimestamp');
          debugPrint('BaseRepository: New session time difference: ${(newSession.expiresAt ?? 0) - newCurrentTimestamp} seconds');
          debugPrint('BaseRepository: New session is expired: ${newSession.isExpired}');

          // Verify the session was actually updated
          final verifySession = _client.auth.currentSession;
          if (verifySession != null) {
            debugPrint('BaseRepository: Verification - current session expires at: ${verifySession.expiresAt}');
            debugPrint('BaseRepository: Verification - session matches refresh: ${verifySession.expiresAt == newSession.expiresAt}');
          } else {
            debugPrint('BaseRepository: Verification - NO CURRENT SESSION FOUND!');
          }

          // Wait longer for the session to be fully established
          await Future.delayed(const Duration(milliseconds: 1000));
          debugPrint('BaseRepository: Session establishment wait completed');

        } catch (e) {
          debugPrint('BaseRepository: Session refresh failed with error: $e');

          // Check if this is a timeout error - but be less aggressive for recent sessions
          if (e.toString().contains('timeout') || e.toString().contains('Timeout')) {
            debugPrint('BaseRepository: Session refresh timeout detected');

            // Check if this might be a recent session that's having connectivity issues
            final currentSession = _client.auth.currentSession;
            if (currentSession != null) {
              final currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
              final sessionAge = currentTimestamp - (currentSession.expiresAt ?? 0) + 3600;

              if (sessionAge < 300) { // Less than 5 minutes old
                debugPrint('BaseRepository: Session is recent (${sessionAge}s old), not forcing sign out for timeout');
                throw Exception('Session refresh timeout. Please check your connection and try again.');
              }
            }

            debugPrint('BaseRepository: Session refresh timeout for old session, forcing sign out');
            try {
              await _client.auth.signOut();
              throw Exception('Session refresh timeout. Please log in again.');
            } catch (signOutError) {
              debugPrint('BaseRepository: Error during forced sign out: $signOutError');
              throw Exception('Session refresh timeout. Please log in again.');
            }
          }

          // If session refresh fails, try to get a fresh session by checking current auth state
          debugPrint('BaseRepository: Attempting to recover session by checking auth state...');
          try {
            final currentUser = _client.auth.currentUser;
            if (currentUser != null) {
              debugPrint('BaseRepository: User still exists, attempting to continue with current session...');
              // Wait a bit and check if session was updated in the background
              await Future.delayed(const Duration(milliseconds: 2000));

              final recoveredSession = _client.auth.currentSession;
              if (recoveredSession != null) {
                final recoveredTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
                debugPrint('BaseRepository: Recovered session expires at: ${recoveredSession.expiresAt}');
                debugPrint('BaseRepository: Recovery timestamp: $recoveredTimestamp');
                debugPrint('BaseRepository: Recovery time difference: ${(recoveredSession.expiresAt ?? 0) - recoveredTimestamp} seconds');

                // If the session is still expired, we'll proceed anyway and let the query fail gracefully
                if ((recoveredSession.expiresAt ?? 0) <= recoveredTimestamp) {
                  debugPrint('BaseRepository: Session still expired after recovery attempt, but proceeding...');
                } else {
                  debugPrint('BaseRepository: Session recovered successfully!');
                }
              }
            } else {
              debugPrint('BaseRepository: No user found during recovery, session refresh truly failed');
              throw Exception('Session refresh failed: $e. Please log in again.');
            }
          } catch (recoveryError) {
            debugPrint('BaseRepository: Session recovery also failed: $recoveryError');
            throw Exception('Session refresh failed: $e. Please log in again.');
          }
        }
      } else {
        debugPrint('BaseRepository: Session is valid, no refresh needed');
      }

      debugPrint('BaseRepository: === SESSION ANALYSIS COMPLETE ===');
    } catch (e) {
      debugPrint('BaseRepository: Failed to refresh session: $e');
      throw Exception('Failed to refresh session. Please log in again.');
    }
  }

  /// Execute a query with intelligent retry logic and exponential backoff
  Future<Either<Failure, T>> executeQuerySafe<T>(Future<T> Function() query) async {
    return await _executeWithRetry(query, 'executeQuerySafe');
  }

  /// Internal method to execute queries with retry logic
  Future<Either<Failure, T>> _executeWithRetry<T>(
    Future<T> Function() query,
    String operationName, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    debugPrint('BaseRepository: Starting $operationName with retry logic');

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          final delay = Duration(seconds: (initialDelay.inSeconds * (1 << (attempt - 1))).clamp(1, 30));
          debugPrint('BaseRepository: Retry attempt $attempt after ${delay.inSeconds}s delay');
          await Future.delayed(delay);
        }

        // Ensure we have a valid session before executing the query
        debugPrint('BaseRepository: Checking and refreshing session if needed (attempt ${attempt + 1})');
        await refreshSessionIfNeeded();

        // Validate authentication context
        debugPrint('BaseRepository: Validating authentication context (attempt ${attempt + 1})');
        await getAuthenticatedClient();

        // Verify session is still valid before query
        final preQuerySession = _client.auth.currentSession;
        if (preQuerySession != null) {
          debugPrint('BaseRepository: Pre-query session check - expires at: ${preQuerySession.expiresAt}');
          debugPrint('BaseRepository: Pre-query session check - access token length: ${preQuerySession.accessToken.length}');
          debugPrint('BaseRepository: Pre-query session check - is expired: ${preQuerySession.isExpired}');
        } else {
          debugPrint('BaseRepository: Pre-query session check - NO SESSION FOUND!');
        }

        // Execute the query with reasonable timeout
        final result = await query().timeout(
          const Duration(seconds: 30), // Reduced timeout for better responsiveness
          onTimeout: () {
            debugPrint('BaseRepository: Query timed out after 30 seconds (attempt ${attempt + 1})');
            debugPrint('BaseRepository: Session at timeout - exists: ${_client.auth.currentSession != null}');
            if (_client.auth.currentSession != null) {
              debugPrint('BaseRepository: Session at timeout - expires: ${_client.auth.currentSession!.expiresAt}');
              debugPrint('BaseRepository: Session at timeout - expired: ${_client.auth.currentSession!.isExpired}');
            }
            throw Exception('Query timeout after 30 seconds. Please check your connection.');
          },
        );

        debugPrint('BaseRepository: === QUERY EXECUTION SUCCESS (attempt ${attempt + 1}) ===');
        debugPrint('BaseRepository: Query executed successfully');
        debugPrint('BaseRepository: Result type: ${result.runtimeType}');
        _logger.debug('Query executed successfully');
        return Right(result);

      } catch (e, stackTrace) {
        debugPrint('BaseRepository: Query execution failed on attempt ${attempt + 1}: $e');
        _logger.error('Query execution failed', e, stackTrace);

        // Determine if this error is retryable
        final isRetryable = _isRetryableError(e);
        final isLastAttempt = attempt == maxRetries;

        if (!isRetryable || isLastAttempt) {
          debugPrint('BaseRepository: Error is not retryable or max attempts reached');
          final failure = ErrorHandler.handleException(e, stackTrace);
          return Left(failure);
        }

        debugPrint('BaseRepository: Error is retryable, will retry after delay');
        // Continue to next iteration for retry
      }
    }

    // If we get here, all retries failed
    debugPrint('BaseRepository: All retry attempts failed');
    final failure = ErrorHandler.handleException(
      Exception('All retry attempts failed'),
      StackTrace.current,
    );
    return Left(failure);
  }

  /// Determine if an error is retryable
  bool _isRetryableError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Retryable errors
    if (errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('expired') ||
        errorString.contains('unauthorized') ||
        errorString.contains('jwt') ||
        errorString.contains('session')) {
      return true;
    }

    // Non-retryable errors
    if (errorString.contains('not found') ||
        errorString.contains('permission') ||
        errorString.contains('forbidden') ||
        errorString.contains('invalid') ||
        errorString.contains('malformed')) {
      return false;
    }

    // Default to retryable for unknown errors
    return true;
  }

  /// Execute a stream query with Either pattern for error handling
  Stream<Either<Failure, T>> executeStreamQuerySafe<T>(Stream<T> Function() query) async* {
    try {
      yield* query().map((data) => Right<Failure, T>(data));
    } catch (e, stackTrace) {
      _logger.error('Stream query execution failed', e, stackTrace);
      final failure = ErrorHandler.handleException(e, stackTrace);
      yield Left(failure);
    }
  }
}
