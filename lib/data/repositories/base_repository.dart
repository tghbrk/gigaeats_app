
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

  BaseRepository({
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  /// Get the Supabase client
  SupabaseClient get client => _client;

  /// Get authenticated Supabase client
  Future<SupabaseClient> getAuthenticatedClient() async {
    // Check if user is authenticated
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      debugPrint('BaseRepository: No authenticated user found');
      throw Exception('User not authenticated. Please log in and try again.');
    }

    // For web platform, ensure we have a valid session
    if (kIsWeb) {
      final session = _client.auth.currentSession;
      if (session == null || session.isExpired) {
        debugPrint('BaseRepository: Session expired or invalid for web platform');
        throw Exception('Session expired. Please log in again.');
      }

      debugPrint('BaseRepository: Using authenticated client for web platform');
      debugPrint('BaseRepository: User ID: ${currentUser.id}');
      debugPrint('BaseRepository: User email: ${currentUser.email}');
    }

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

  /// Execute a query that returns a stream with automatic authentication
  Stream<T> executeStreamQuery<T>(Stream<T> Function() query) async* {
    try {
      yield* query();
    } catch (e) {
      debugPrint('BaseRepository: Stream query error: $e');
      rethrow;
    }
  }

  /// Execute a query with Either pattern for error handling
  Future<Either<Failure, T>> executeQuerySafe<T>(Future<T> Function() query) async {
    try {
      final result = await query();
      _logger.debug('Query executed successfully');
      return Right(result);
    } catch (e, stackTrace) {
      _logger.error('Query execution failed', e, stackTrace);
      final failure = ErrorHandler.handleException(e, stackTrace);
      return Left(failure);
    }
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
