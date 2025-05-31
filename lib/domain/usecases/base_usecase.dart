import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../core/errors/failures.dart';

/// Base use case interface
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use case for operations that don't require parameters
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object> get props => [];
}

/// Base use case for stream operations
abstract class StreamUseCase<Type, Params> {
  Stream<Either<Failure, Type>> call(Params params);
}

/// Base use case for synchronous operations
abstract class SyncUseCase<Type, Params> {
  Either<Failure, Type> call(Params params);
}

/// Use case result wrapper
class UseCaseResult<T> {
  final T? data;
  final Failure? failure;
  final bool isSuccess;

  const UseCaseResult._({
    this.data,
    this.failure,
    required this.isSuccess,
  });

  /// Create successful result
  factory UseCaseResult.success(T data) {
    return UseCaseResult._(
      data: data,
      isSuccess: true,
    );
  }

  /// Create failed result
  factory UseCaseResult.failure(Failure failure) {
    return UseCaseResult._(
      failure: failure,
      isSuccess: false,
    );
  }

  /// Create result from Either
  factory UseCaseResult.fromEither(Either<Failure, T> either) {
    return either.fold(
      (failure) => UseCaseResult.failure(failure),
      (data) => UseCaseResult.success(data),
    );
  }

  /// Convert to Either
  Either<Failure, T> toEither() {
    if (isSuccess && data != null) {
      return Right(data!);
    } else if (failure != null) {
      return Left(failure!);
    } else {
      return const Left(UnexpectedFailure(message: 'Unknown error occurred'));
    }
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'UseCaseResult.success(data: $data)';
    } else {
      return 'UseCaseResult.failure(failure: $failure)';
    }
  }
}

/// Pagination parameters
class PaginationParams extends Equatable {
  final int page;
  final int limit;
  int get offset => (page - 1) * limit;

  const PaginationParams({
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object> get props => [page, limit];

  @override
  String toString() => 'PaginationParams(page: $page, limit: $limit)';
}

/// Search parameters
class SearchParams extends Equatable {
  final String query;
  final PaginationParams? pagination;
  final Map<String, dynamic>? filters;
  final String? sortBy;
  final bool sortAscending;

  const SearchParams({
    required this.query,
    this.pagination,
    this.filters,
    this.sortBy,
    this.sortAscending = true,
  });

  @override
  List<Object?> get props => [query, pagination, filters, sortBy, sortAscending];

  @override
  String toString() => 'SearchParams(query: $query, pagination: $pagination)';
}

/// Filter parameters
class FilterParams extends Equatable {
  final Map<String, dynamic> filters;
  final PaginationParams? pagination;
  final String? sortBy;
  final bool sortAscending;

  const FilterParams({
    required this.filters,
    this.pagination,
    this.sortBy,
    this.sortAscending = true,
  });

  @override
  List<Object?> get props => [filters, pagination, sortBy, sortAscending];

  @override
  String toString() => 'FilterParams(filters: $filters, pagination: $pagination)';
}

/// ID parameters for operations that require an ID
class IdParams extends Equatable {
  final String id;

  const IdParams({required this.id});

  @override
  List<Object> get props => [id];

  @override
  String toString() => 'IdParams(id: $id)';
}

/// Parameters for operations that require multiple IDs
class IdsParams extends Equatable {
  final List<String> ids;

  const IdsParams({required this.ids});

  @override
  List<Object> get props => [ids];

  @override
  String toString() => 'IdsParams(ids: $ids)';
}

/// Date range parameters
class DateRangeParams extends Equatable {
  final DateTime startDate;
  final DateTime endDate;

  const DateRangeParams({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [startDate, endDate];

  @override
  String toString() => 'DateRangeParams(startDate: $startDate, endDate: $endDate)';
}

/// Use case executor for handling common use case operations
class UseCaseExecutor {
  /// Execute use case and handle common error scenarios
  static Future<UseCaseResult<T>> execute<T>(
    Future<Either<Failure, T>> Function() useCase,
  ) async {
    try {
      final result = await useCase();
      return UseCaseResult.fromEither(result);
    } catch (e) {
      return UseCaseResult.failure(
        UnexpectedFailure(
          message: 'Unexpected error occurred: ${e.toString()}',
          details: e,
        ),
      );
    }
  }

  /// Execute multiple use cases in parallel
  static Future<List<UseCaseResult<T>>> executeParallel<T>(
    List<Future<Either<Failure, T>> Function()> useCases,
  ) async {
    final futures = useCases.map((useCase) => execute(useCase));
    return await Future.wait(futures);
  }

  /// Execute use cases in sequence
  static Future<List<UseCaseResult<T>>> executeSequential<T>(
    List<Future<Either<Failure, T>> Function()> useCases,
  ) async {
    final results = <UseCaseResult<T>>[];
    
    for (final useCase in useCases) {
      final result = await execute(useCase);
      results.add(result);
      
      // Stop execution if any use case fails
      if (!result.isSuccess) {
        break;
      }
    }
    
    return results;
  }
}
