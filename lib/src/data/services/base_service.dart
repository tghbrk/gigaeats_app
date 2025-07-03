import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/failures.dart';

/// Base service class for all data services
abstract class BaseService {
  final SupabaseClient client;

  BaseService({required this.client});

  /// Execute a service call with error handling
  Future<Either<Failure, T>> executeServiceCall<T>(
    Future<T> Function() serviceCall,
  ) async {
    try {
      final result = await serviceCall();
      return Right(result);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on FunctionException catch (e) {
      return Left(ServerFailure(message: e.details ?? e.reasonPhrase ?? 'Function error'));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  /// Execute a service call that returns a Map
  Future<Either<Failure, Map<String, dynamic>>> executeServiceCallMap(
    Future<Map<String, dynamic>> Function() serviceCall,
  ) async {
    return executeServiceCall(serviceCall);
  }

  /// Execute a service call that returns a List
  Future<Either<Failure, List<T>>> executeServiceCallList<T>(
    Future<List<T>> Function() serviceCall,
  ) async {
    return executeServiceCall(serviceCall);
  }

  /// Execute a service call that returns void
  Future<Either<Failure, void>> executeServiceCallVoid(
    Future<void> Function() serviceCall,
  ) async {
    return executeServiceCall(serviceCall);
  }

  /// Get current user ID
  String? get currentUserUid => client.auth.currentUser?.id;

  /// Check if user is authenticated
  bool get isAuthenticated => client.auth.currentUser != null;

  /// Get current session
  Session? get currentSession => client.auth.currentSession;
}
