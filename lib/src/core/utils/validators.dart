import 'dart:core';

/// Input validation utilities for the application
class InputValidator {
  // Private constructor to prevent instantiation
  InputValidator._();

  /// Email validation regex
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Phone number validation regex (Malaysian format)
  static final RegExp _phoneRegex = RegExp(
    r'^(\+?6?01)[0-46-9]-*[0-9]{7,8}$',
  );

  /// Password strength regex patterns
  static final RegExp _uppercaseRegex = RegExp(r'[A-Z]');
  static final RegExp _lowercaseRegex = RegExp(r'[a-z]');
  static final RegExp _digitRegex = RegExp(r'[0-9]');
  static final RegExp _specialCharRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  /// SQL injection patterns to detect
  static final List<RegExp> _sqlInjectionPatterns = [
    RegExp(r"('|(\\')|(;)|(\\;))", caseSensitive: false),
    RegExp(r'((\s*(union|select|insert|delete|update|drop|create|alter|exec|execute)\s+))', caseSensitive: false),
    RegExp(r'((\s*(or|and)\s+[\w\s]*\s*=\s*[\w\s]*\s*))', caseSensitive: false),
    RegExp(r'(--|\#|\/\*|\*\/)', caseSensitive: false),
  ];

  /// XSS patterns to detect
  static final List<RegExp> _xssPatterns = [
    RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
    RegExp(r'javascript:', caseSensitive: false),
    RegExp(r'on\w+\s*=', caseSensitive: false),
    RegExp(r'<iframe[^>]*>.*?</iframe>', caseSensitive: false),
  ];

  /// Validates email format
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    return _emailRegex.hasMatch(email.trim());
  }

  /// Validates phone number (Malaysian format)
  static bool isValidPhoneNumber(String phone) {
    if (phone.isEmpty) return false;
    final cleanPhone = phone.replaceAll(RegExp(r'[\s-]'), '');
    return _phoneRegex.hasMatch(cleanPhone);
  }

  /// Validates password strength
  static bool isStrongPassword(String password) {
    if (password.length < 8) return false;
    
    return _uppercaseRegex.hasMatch(password) &&
           _lowercaseRegex.hasMatch(password) &&
           _digitRegex.hasMatch(password) &&
           _specialCharRegex.hasMatch(password);
  }

  /// Gets password strength score (0-4)
  static int getPasswordStrength(String password) {
    int score = 0;
    
    if (password.length >= 8) score++;
    if (_uppercaseRegex.hasMatch(password)) score++;
    if (_lowercaseRegex.hasMatch(password)) score++;
    if (_digitRegex.hasMatch(password)) score++;
    if (_specialCharRegex.hasMatch(password)) score++;
    
    return score;
  }

  /// Gets password strength description
  static String getPasswordStrengthDescription(String password) {
    final strength = getPasswordStrength(password);
    switch (strength) {
      case 0:
      case 1:
        return 'Very Weak';
      case 2:
        return 'Weak';
      case 3:
        return 'Medium';
      case 4:
        return 'Strong';
      case 5:
        return 'Very Strong';
      default:
        return 'Unknown';
    }
  }

  /// Validates name (only letters, spaces, and common punctuation)
  static bool isValidName(String name) {
    if (name.isEmpty || name.length > 100) return false;
    final nameRegex = RegExp(r"^[a-zA-Z\s\-'\.]+$");
    return nameRegex.hasMatch(name.trim());
  }

  /// Validates URL format
  static bool isValidUrl(String url) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Validates numeric input
  static bool isValidNumber(String input, {double? min, double? max}) {
    if (input.isEmpty) return false;
    
    final number = double.tryParse(input);
    if (number == null) return false;
    
    if (min != null && number < min) return false;
    if (max != null && number > max) return false;
    
    return true;
  }

  /// Validates integer input
  static bool isValidInteger(String input, {int? min, int? max}) {
    if (input.isEmpty) return false;
    
    final number = int.tryParse(input);
    if (number == null) return false;
    
    if (min != null && number < min) return false;
    if (max != null && number > max) return false;
    
    return true;
  }

  /// Sanitizes input to prevent SQL injection
  static String sanitizeForSql(String input) {
    String sanitized = input;
    
    // Remove or escape dangerous characters
    sanitized = sanitized.replaceAll("'", "''"); // Escape single quotes
    sanitized = sanitized.replaceAll('"', '""'); // Escape double quotes
    sanitized = sanitized.replaceAll(';', ''); // Remove semicolons
    sanitized = sanitized.replaceAll('--', ''); // Remove SQL comments
    sanitized = sanitized.replaceAll('/*', ''); // Remove block comments
    sanitized = sanitized.replaceAll('*/', ''); // Remove block comments
    
    return sanitized.trim();
  }

  /// Sanitizes input to prevent XSS attacks
  static String sanitizeForXss(String input) {
    String sanitized = input;
    
    // Escape HTML characters
    sanitized = sanitized.replaceAll('&', '&amp;');
    sanitized = sanitized.replaceAll('<', '&lt;');
    sanitized = sanitized.replaceAll('>', '&gt;');
    sanitized = sanitized.replaceAll('"', '&quot;');
    sanitized = sanitized.replaceAll("'", '&#x27;');
    sanitized = sanitized.replaceAll('/', '&#x2F;');
    
    return sanitized;
  }

  /// Checks for potential SQL injection attempts
  static bool containsSqlInjection(String input) {
    final lowerInput = input.toLowerCase();
    return _sqlInjectionPatterns.any((pattern) => pattern.hasMatch(lowerInput));
  }

  /// Checks for potential XSS attempts
  static bool containsXss(String input) {
    final lowerInput = input.toLowerCase();
    return _xssPatterns.any((pattern) => pattern.hasMatch(lowerInput));
  }

  /// Validates and sanitizes general text input
  static String? validateAndSanitizeText(
    String input, {
    int? minLength,
    int? maxLength,
    bool allowEmpty = false,
    bool checkSqlInjection = true,
    bool checkXss = true,
  }) {
    if (!allowEmpty && input.trim().isEmpty) {
      return 'This field cannot be empty';
    }
    
    if (minLength != null && input.length < minLength) {
      return 'Must be at least $minLength characters long';
    }
    
    if (maxLength != null && input.length > maxLength) {
      return 'Must be no more than $maxLength characters long';
    }
    
    if (checkSqlInjection && containsSqlInjection(input)) {
      return 'Invalid characters detected';
    }
    
    if (checkXss && containsXss(input)) {
      return 'Invalid characters detected';
    }
    
    return null; // Valid input
  }

  /// Validates Malaysian IC number format
  static bool isValidMalaysianIC(String ic) {
    if (ic.isEmpty) return false;
    
    // Remove any dashes or spaces
    final cleanIC = ic.replaceAll(RegExp(r'[\s-]'), '');
    
    // Check if it's 12 digits
    if (cleanIC.length != 12) return false;
    
    // Check if all characters are digits
    if (!RegExp(r'^\d{12}$').hasMatch(cleanIC)) return false;
    
    // Basic format validation (YYMMDD-PB-###G)
    final year = int.tryParse(cleanIC.substring(0, 2));
    final month = int.tryParse(cleanIC.substring(2, 4));
    final day = int.tryParse(cleanIC.substring(4, 6));
    
    if (year == null || month == null || day == null) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    
    return true;
  }
}

/// Alias for backward compatibility
class Validators {
  // Private constructor to prevent instantiation
  Validators._();

  /// Validates email format
  static bool isValidEmail(String email) => InputValidator.isValidEmail(email);

  /// Validates phone number (Malaysian format)
  static bool isValidPhoneNumber(String phone) => InputValidator.isValidPhoneNumber(phone);

  /// Validates password strength
  static bool isStrongPassword(String password) => InputValidator.isStrongPassword(password);

  /// Gets password strength score (0-4)
  static int getPasswordStrength(String password) => InputValidator.getPasswordStrength(password);

  /// Gets password strength description
  static String getPasswordStrengthDescription(String password) => InputValidator.getPasswordStrengthDescription(password);

  /// Validates name (only letters, spaces, and common punctuation)
  static bool isValidName(String name) => InputValidator.isValidName(name);

  /// Validates URL format
  static bool isValidUrl(String url) => InputValidator.isValidUrl(url);

  /// Validates numeric input
  static bool isValidNumber(String input, {double? min, double? max}) => InputValidator.isValidNumber(input, min: min, max: max);

  /// Validates integer input
  static bool isValidInteger(String input, {int? min, int? max}) => InputValidator.isValidInteger(input, min: min, max: max);

  /// Sanitizes input to prevent SQL injection
  static String sanitizeForSql(String input) => InputValidator.sanitizeForSql(input);

  /// Sanitizes input to prevent XSS attacks
  static String sanitizeForXss(String input) => InputValidator.sanitizeForXss(input);

  /// Checks for potential SQL injection attempts
  static bool containsSqlInjection(String input) => InputValidator.containsSqlInjection(input);

  /// Checks for potential XSS attempts
  static bool containsXss(String input) => InputValidator.containsXss(input);

  /// Validates and sanitizes general text input
  static String? validateAndSanitizeText(
    String input, {
    int? minLength,
    int? maxLength,
    bool allowEmpty = false,
    bool checkSqlInjection = true,
    bool checkXss = true,
  }) => InputValidator.validateAndSanitizeText(
    input,
    minLength: minLength,
    maxLength: maxLength,
    allowEmpty: allowEmpty,
    checkSqlInjection: checkSqlInjection,
    checkXss: checkXss,
  );

  /// Validates Malaysian IC number format
  static bool isValidMalaysianIC(String ic) => InputValidator.isValidMalaysianIC(ic);
}
