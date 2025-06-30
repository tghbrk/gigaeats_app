

/// Specialized validators for profile forms
class ProfileValidators {
  ProfileValidators._();

  /// Validate full name
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    
    final trimmedValue = value.trim();
    
    if (trimmedValue.length < 2) {
      return 'Full name must be at least 2 characters';
    }
    
    if (trimmedValue.length > 100) {
      return 'Full name must be less than 100 characters';
    }
    
    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-'\.]+$").hasMatch(trimmedValue)) {
      return 'Full name can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    // Check for reasonable name format (at least one letter)
    if (!RegExp(r'[a-zA-Z]').hasMatch(trimmedValue)) {
      return 'Full name must contain at least one letter';
    }
    
    return null;
  }

  /// Validate Malaysian phone number
  static String? validateMalaysianPhoneNumber(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Phone number is required' : null;
    }
    
    final cleanValue = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Malaysian phone number patterns:
    // +60123456789 (12-13 digits with +60)
    // 0123456789 (10-11 digits starting with 0)
    // 123456789 (9-10 digits without prefix)
    bool isValid = RegExp(r'^\+60\d{9,10}$').hasMatch(cleanValue) ||
                  RegExp(r'^0\d{9,10}$').hasMatch(cleanValue) ||
                  RegExp(r'^\d{8,11}$').hasMatch(cleanValue);
    
    if (!isValid) {
      return 'Please enter a valid Malaysian phone number';
    }
    
    return null;
  }

  /// Validate email address
  static String? validateEmail(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Email address is required' : null;
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Validate password
  static String? validatePassword(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'Password is required' : null;
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    if (value.length > 128) {
      return 'Password must be less than 128 characters';
    }
    
    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Check for at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    // Check for at least one digit
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    
    // Check for at least one special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    
    return null;
  }

  /// Validate confirm password
  static String? validateConfirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  /// Validate address
  static String? validateAddress(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Address is required' : null;
    }
    
    final trimmedValue = value.trim();
    
    if (trimmedValue.length < 10) {
      return 'Address must be at least 10 characters';
    }
    
    if (trimmedValue.length > 200) {
      return 'Address must be less than 200 characters';
    }
    
    return null;
  }

  /// Validate Malaysian postcode
  static String? validateMalaysianPostcode(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Postcode is required' : null;
    }
    
    final cleanValue = value.replaceAll(RegExp(r'\s'), '');
    
    if (!RegExp(r'^\d{5}$').hasMatch(cleanValue)) {
      return 'Please enter a valid 5-digit postcode';
    }
    
    return null;
  }

  /// Validate city name
  static String? validateCity(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'City is required' : null;
    }
    
    final trimmedValue = value.trim();
    
    if (trimmedValue.length < 2) {
      return 'City name must be at least 2 characters';
    }
    
    if (trimmedValue.length > 50) {
      return 'City name must be less than 50 characters';
    }
    
    // Check for valid characters (letters, spaces, hyphens)
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(trimmedValue)) {
      return 'City name can only contain letters, spaces, and hyphens';
    }
    
    return null;
  }

  /// Validate state name
  static String? validateState(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'State is required' : null;
    }
    
    final trimmedValue = value.trim();
    
    // List of Malaysian states
    const malaysianStates = [
      'Johor', 'Kedah', 'Kelantan', 'Malacca', 'Negeri Sembilan',
      'Pahang', 'Penang', 'Perak', 'Perlis', 'Sabah', 'Sarawak',
      'Selangor', 'Terengganu', 'Kuala Lumpur', 'Labuan', 'Putrajaya'
    ];
    
    if (!malaysianStates.any((state) => 
        state.toLowerCase() == trimmedValue.toLowerCase())) {
      return 'Please select a valid Malaysian state';
    }
    
    return null;
  }

  /// Validate business registration number (for vendors)
  static String? validateBusinessRegistration(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Business registration number is required' : null;
    }
    
    final cleanValue = value.replaceAll(RegExp(r'[\s\-]'), '');
    
    // Malaysian business registration patterns
    // SSM format: 123456-A or 123456789-A
    if (!RegExp(r'^\d{6,9}[A-Z]?$').hasMatch(cleanValue)) {
      return 'Please enter a valid business registration number';
    }
    
    return null;
  }

  /// Validate emergency contact name
  static String? validateEmergencyContactName(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Emergency contact name is required' : null;
    }
    
    return validateFullName(value);
  }

  /// Validate emergency contact phone
  static String? validateEmergencyContactPhone(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Emergency contact phone is required' : null;
    }
    
    return validateMalaysianPhoneNumber(value, required: required);
  }

  /// Validate IC number (Malaysian Identity Card)
  static String? validateICNumber(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'IC number is required' : null;
    }
    
    final cleanValue = value.replaceAll(RegExp(r'[\s\-]'), '');
    
    // Malaysian IC format: 123456-12-1234
    if (!RegExp(r'^\d{12}$').hasMatch(cleanValue)) {
      return 'Please enter a valid 12-digit IC number';
    }
    
    return null;
  }

  /// Validate bank account number
  static String? validateBankAccountNumber(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Bank account number is required' : null;
    }
    
    final cleanValue = value.replaceAll(RegExp(r'[\s\-]'), '');
    
    // Malaysian bank account numbers are typically 10-16 digits
    if (!RegExp(r'^\d{10,16}$').hasMatch(cleanValue)) {
      return 'Please enter a valid bank account number (10-16 digits)';
    }
    
    return null;
  }
}
