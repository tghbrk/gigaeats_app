import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/errors/error_handler.dart';
import '../../core/utils/logger.dart';
import '../../core/config/supabase_config.dart';

/// Base repository class that provides common functionality for all repositories
abstract class BaseRepository {
  final SupabaseClient _client;
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final AppLogger _logger = AppLogger();

  BaseRepository({
    SupabaseClient? client,
    firebase_auth.FirebaseAuth? firebaseAuth,
  }) : _client = client ?? Supabase.instance.client,
       _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  /// Get the Supabase client
  SupabaseClient get client => _client;

  /// Get the Firebase Auth instance
  firebase_auth.FirebaseAuth get firebaseAuth => _firebaseAuth;

  /// Create authenticated Supabase client with Firebase token
  Future<SupabaseClient> getAuthenticatedClient() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final idToken = await user.getIdToken();
        if (idToken != null) {
          // Create a new client with Firebase token for RLS
          return SupabaseClient(
            SupabaseConfig.url,
            SupabaseConfig.anonKey,
            headers: {
              'Authorization': 'Bearer $idToken',
            },
          );
        }
      }

      // Fallback to default client
      debugPrint('BaseRepository: Using default client (no Firebase auth)');
      return _client;
    } catch (e) {
      debugPrint('BaseRepository: Error creating authenticated client: $e');
      return _client;
    }
  }

  /// Get current Firebase user UID
  String? get currentUserUid => _firebaseAuth.currentUser?.uid;

  /// Check if user is authenticated
  bool get isAuthenticated => _firebaseAuth.currentUser != null;

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
