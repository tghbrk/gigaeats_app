/// Examples demonstrating how to use the new audit compliance features
/// This file shows practical usage of the implemented audit system
library;

import 'package:dartz/dartz.dart';
import '../core/errors/failures.dart';
import '../core/errors/exceptions.dart';
import '../core/errors/error_handler.dart';
import '../core/utils/logger.dart';
import '../core/utils/validators.dart';
import '../core/services/security_service.dart';
import '../domain/entities/user_entity.dart';
import '../domain/usecases/base_usecase.dart';

/// Example class demonstrating audit compliance patterns
class AuditUsageExamples {
  final AppLogger _logger = AppLogger();
  final SecurityService _securityService = SecurityService();

  /// Example 1: Error Handling with Either Pattern
  Future<Either<Failure, String>> exampleErrorHandling() async {
    try {
      // Simulate some operation that might fail
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Simulate an error
      throw const ServerException(message: 'Database connection failed');
      
    } catch (e, stackTrace) {
      // Use centralized error handler
      final failure = ErrorHandler.handleException(e, stackTrace);
      return Left(failure);
    }
  }

  /// Example 2: Input Validation and Security
  Either<Failure, Map<String, String>> exampleInputValidation({
    required String email,
    required String password,
    required String userInput,
  }) {
    // Email validation
    if (!InputValidator.isValidEmail(email)) {
      return const Left(ValidationFailure(
        message: 'Please enter a valid email address',
        code: 'invalid_email',
      ));
    }

    // Password strength validation
    if (!InputValidator.isStrongPassword(password)) {
      return const Left(ValidationFailure(
        message: 'Password must be at least 8 characters with uppercase, lowercase, number, and special character',
        code: 'weak_password',
      ));
    }

    // Security validation - check for SQL injection
    if (InputValidator.containsSqlInjection(userInput)) {
      return const Left(ValidationFailure(
        message: 'Invalid characters detected in input',
        code: 'security_violation',
      ));
    }

    // Security validation - check for XSS
    if (InputValidator.containsXss(userInput)) {
      return const Left(ValidationFailure(
        message: 'Invalid characters detected in input',
        code: 'security_violation',
      ));
    }

    // Sanitize input
    final sanitizedInput = InputValidator.sanitizeForSql(
      InputValidator.sanitizeForXss(userInput),
    );

    return Right({
      'email': email,
      'sanitized_input': sanitizedInput,
      'password_strength': InputValidator.getPasswordStrengthDescription(password),
    });
  }

  /// Example 3: Structured Logging
  void exampleLogging() {
    // Different log levels
    _logger.debug('Debug information for development');
    _logger.info('User action performed successfully');
    _logger.warning('Potential issue detected');
    _logger.error('Error occurred', Exception('Sample error'));

    // API request logging
    _logger.logApiRequest('POST', '/api/users', {'name': 'John Doe'});
    
    // User action logging
    _logger.logUserAction('login_attempt', {'email': 'user@example.com'});
    
    // Performance logging
    _logger.logPerformance('database_query', const Duration(milliseconds: 150));
  }

  /// Example 4: Secure Token Management
  Future<Either<Failure, String>> exampleSecureTokenManagement() async {
    try {
      // Store tokens securely
      await _securityService.storeTokens(
        accessToken: 'sample_access_token',
        refreshToken: 'sample_refresh_token',
        userId: 'user123',
      );

      // Retrieve and validate token
      final token = await _securityService.getAccessToken();
      if (token == null) {
        return const Left(AuthFailure(message: 'No access token found'));
      }

      // Validate token
      if (!_securityService.isTokenValid(token)) {
        return const Left(AuthFailure(message: 'Token has expired'));
      }

      // Extract user ID from token
      final userId = _securityService.getUserIdFromToken(token);
      if (userId == null) {
        return const Left(AuthFailure(message: 'Invalid token format'));
      }

      return Right(userId);
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handleException(e, stackTrace);
      return Left(failure);
    }
  }

  /// Example 5: Use Case Pattern Implementation
  Future<Either<Failure, UserEntity>> exampleUseCasePattern({
    required String email,
    required String password,
  }) async {
    // Note: In real implementation, you would create use case parameters
    // final params = LoginParams(email: email, password: password);
    // and inject the repository
    // final loginUseCase = LoginUseCase(authRepository);

    // Execute use case
    // final result = await loginUseCase(params);

    // For demonstration, return a mock result
    return Right(UserEntity(
      id: 'user123',
      email: email,
      fullName: 'John Doe',
      phoneNumber: '+60123456789',
      role: UserRoleEntity.customer,
      isVerified: true,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  /// Example 6: Domain Entity Usage
  void exampleDomainEntities() {
    // Create user entity
    final user = UserEntity(
      id: 'user123',
      email: 'john.doe@example.com',
      fullName: 'John Doe',
      phoneNumber: '+60123456789',
      role: UserRoleEntity.customer,
      isVerified: true,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Check user permissions
    final canPlaceOrder = user.role.hasPermission('place_order');
    final canManageUsers = user.role.hasPermission('manage_users');

    _logger.info('User permissions: place_order=$canPlaceOrder, manage_users=$canManageUsers');

    // Create updated user
    final updatedUser = user.copyWith(
      fullName: 'John Smith',
      updatedAt: DateTime.now(),
    );

    _logger.info('User updated: ${updatedUser.fullName}');
  }

  /// Example 7: Comprehensive Error Handling Flow
  Future<Either<Failure, String>> exampleComprehensiveFlow({
    required String email,
    required String password,
  }) async {
    try {
      // Step 1: Input validation
      final validationResult = exampleInputValidation(
        email: email,
        password: password,
        userInput: 'safe user input',
      );

      if (validationResult.isLeft()) {
        return validationResult.fold(
          (failure) => Left(failure),
          (data) => const Right(''), // This won't be reached
        );
      }

      // Step 2: Security checks
      final securityResult = await exampleSecureTokenManagement();
      if (securityResult.isLeft()) {
        return securityResult.fold(
          (failure) => Left(failure),
          (data) => const Right(''), // This won't be reached
        );
      }

      // Step 3: Business logic
      final useCaseResult = await exampleUseCasePattern(
        email: email,
        password: password,
      );

      return useCaseResult.fold(
        (failure) => Left(failure),
        (user) => Right('User ${user.fullName} processed successfully'),
      );

    } catch (e, stackTrace) {
      // Centralized error handling
      final failure = ErrorHandler.handleException(e, stackTrace);
      return Left(failure);
    }
  }

  /// Example 8: Using Extension Methods for Easy Logging
  void exampleExtensionLogging() {
    // Using extension methods for easy logging
    logInfo('This is an info message from $runtimeType');
    logDebug('Debug information');
    logWarning('Warning message');
    logError('Error occurred', Exception('Sample error'));
  }

  /// Example 9: Pagination and Search Parameters
  void exampleUseCaseParameters() {
    // Pagination parameters
    const pagination = PaginationParams(page: 2, limit: 20);
    _logger.info('Pagination: page=${pagination.page}, offset=${pagination.offset}');

    // Search parameters
    const searchParams = SearchParams(
      query: 'john doe',
      pagination: pagination,
      sortBy: 'created_at',
      sortAscending: false,
    );
    _logger.info('Search: ${searchParams.query}');

    // Filter parameters
    final filterParams = FilterParams(
      filters: {
        'role': 'customer',
        'is_active': true,
        'created_after': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      },
      pagination: pagination,
    );
    _logger.info('Filters: ${filterParams.filters}');
  }

  /// Example 10: Use Case Result Handling
  void exampleUseCaseResults() {
    // Success result
    final successResult = UseCaseResult.success('Operation completed');
    if (successResult.isSuccess) {
      _logger.info('Success: ${successResult.data}');
    }

    // Failure result
    const failure = ServerFailure(message: 'Server error occurred');
    final failureResult = UseCaseResult.failure(failure);
    if (!failureResult.isSuccess) {
      _logger.error('Failure: ${failureResult.failure?.message}');
    }

    // Convert to Either
    final either = successResult.toEither();
    either.fold(
      (failure) => _logger.error('Error: ${failure.message}'),
      (data) => _logger.info('Data: $data'),
    );
  }
}

/// Example usage in a widget or service
class ExampleUsage {
  final AuditUsageExamples _examples = AuditUsageExamples();
  final AppLogger _logger = AppLogger();

  Future<void> demonstrateAuditFeatures() async {
    // Example 1: Error handling
    final errorResult = await _examples.exampleErrorHandling();
    errorResult.fold(
      (failure) => _logger.error('Error handled: ${failure.message}'),
      (data) => _logger.info('Success: $data'),
    );

    // Example 2: Input validation
    final validationResult = _examples.exampleInputValidation(
      email: 'test@example.com',
      password: 'WeakPass',
      userInput: 'normal input',
    );
    validationResult.fold(
      (failure) => _logger.error('Validation failed: ${failure.message}'),
      (data) => _logger.info('Validation passed: $data'),
    );

    // Example 3: Logging
    _examples.exampleLogging();

    // Example 4: Comprehensive flow
    final flowResult = await _examples.exampleComprehensiveFlow(
      email: 'user@example.com',
      password: 'StrongPass123!',
    );
    flowResult.fold(
      (failure) => _logger.error('Flow failed: ${failure.message}'),
      (data) => _logger.info('Flow completed: $data'),
    );
  }
}
