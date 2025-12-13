import 'dart:ui';

/// Validation Utilities for Account Management
/// Philippine-specific validation rules
class ValidationUtils {
  /// Validate full name
  /// - Required
  /// - 2-100 characters
  /// - Letters, spaces, hyphens, and periods only
  /// - Must have at least first and last name
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }

    final trimmed = value.trim();

    // Length validation
    if (trimmed.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (trimmed.length > 100) {
      return 'Name must not exceed 100 characters';
    }

    // Must have at least first and last name
    final nameParts = trimmed
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();
    if (nameParts.length < 2) {
      return 'Please enter first and last name';
    }

    // Valid characters only (letters, spaces, hyphens, periods)
    final nameRegex = RegExp(r'^[a-zA-ZÀ-ÿ\s\-\.]+$');
    if (!nameRegex.hasMatch(trimmed)) {
      return 'Name can only contain letters, spaces, hyphens, and periods';
    }

    // Each name part must start with a letter
    for (final part in nameParts) {
      if (!RegExp(r'^[a-zA-ZÀ-ÿ]').hasMatch(part)) {
        return 'Each name must start with a letter';
      }
    }

    return null;
  }

  /// Validate username
  /// - Required
  /// - 3-30 characters
  /// - Lowercase letters, numbers, underscores, and hyphens only
  /// - Must start with a letter
  /// - No consecutive special characters
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }

    final trimmed = value.trim();

    // Length validation
    if (trimmed.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (trimmed.length > 30) {
      return 'Username must not exceed 30 characters';
    }

    // Must start with a letter
    if (!RegExp(r'^[a-z]').hasMatch(trimmed)) {
      return 'Username must start with a lowercase letter';
    }

    // Valid characters only
    final usernameRegex = RegExp(r'^[a-z][a-z0-9_-]*$');
    if (!usernameRegex.hasMatch(trimmed)) {
      return 'Username can only contain lowercase letters, numbers, underscores, and hyphens';
    }

    // No consecutive special characters
    if (RegExp(r'[_-]{2,}').hasMatch(trimmed)) {
      return 'Username cannot have consecutive underscores or hyphens';
    }

    // Cannot end with special character
    if (RegExp(r'[_-]$').hasMatch(trimmed)) {
      return 'Username cannot end with underscore or hyphen';
    }

    return null;
  }

  /// Validate Philippine phone number
  /// Formats accepted:
  /// - 09XX XXX XXXX (with or without spaces)
  /// - +639XX XXX XXXX
  /// - 639XX XXX XXXX
  /// - 9XX XXX XXXX
  static String? validatePhilippinePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    // Remove all spaces, hyphens, and parentheses
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if it's a valid Philippine mobile number
    final patterns = [
      RegExp(r'^09\d{9}$'), // 09XXXXXXXXX
      RegExp(r'^\+639\d{9}$'), // +639XXXXXXXXX
      RegExp(r'^639\d{9}$'), // 639XXXXXXXXX
      RegExp(r'^9\d{9}$'), // 9XXXXXXXXX
    ];

    bool isValid = patterns.any((pattern) => pattern.hasMatch(cleaned));

    if (!isValid) {
      return 'Please enter a valid Philippine mobile number (09XX XXX XXXX)';
    }

    // Check if it starts with valid prefix
    String number = cleaned;
    if (number.startsWith('+63')) {
      number = number.substring(3);
    } else if (number.startsWith('63')) {
      number = number.substring(2);
    } else if (number.startsWith('0')) {
      number = number.substring(1);
    }

    // Valid Philippine mobile prefixes
    final validPrefixes = [
      '905', '906', '907', '908', '909', // Smart
      '910', '911', '912', '913', '914', // Smart
      '918', '919', '920', '921', '928', // Smart
      '929', '930', '938', '939', '946', // Smart
      '947', '948', '949', '950', // Smart
      '900', '915', '916', '917', '926', // Globe
      '927', '935', '936', '937', '945', // Globe
      '953', '954', '955', '956', '965', // Globe
      '966', '967', '975', '976', '977', // Globe
      '978', '979', '995', '996', '997', // Globe
      '902', '903', '904', '932', '933', // Sun
      '934', '940', '941', '942', '943', // Sun
      '944', '973', '974', // Sun
      '992', '993', '994', // Other networks
    ];

    final prefix = number.substring(0, 3);
    if (!validPrefixes.contains(prefix)) {
      return 'Invalid Philippine mobile number prefix';
    }

    return null;
  }

  /// Format Philippine phone number to display format
  /// Output: 09XX XXX XXXX
  static String formatPhilippinePhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    final cleaned = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // Convert to standard format
    String number = cleaned;
    if (number.startsWith('63')) {
      number = '0${number.substring(2)}';
    } else if (number.startsWith('+63')) {
      number = '0${number.substring(3)}';
    } else if (!number.startsWith('0')) {
      number = '0$number';
    }

    // Format as 09XX XXX XXXX
    if (number.length == 11) {
      return '${number.substring(0, 4)} ${number.substring(4, 7)} ${number.substring(7)}';
    }

    return number;
  }

  /// Validate password
  /// - Minimum 8 characters
  /// - At least one uppercase letter
  /// - At least one lowercase letter
  /// - At least one number
  /// - At least one special character
  /// - Maximum 128 characters
  static String? validatePassword(String? value, {bool isRequired = true}) {
    if (value == null || value.isEmpty) {
      return isRequired ? 'Password is required' : null;
    }

    // Length validation
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (value.length > 128) {
      return 'Password must not exceed 128 characters';
    }

    // Must contain uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }

    // Must contain lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }

    // Must contain number
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    // Must contain special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }

    // Check for common weak passwords
    final weakPasswords = [
      'password',
      'password123',
      '12345678',
      'qwerty123',
      'admin123',
      'welcome123',
      'letmein123',
      'password1',
    ];
    if (weakPasswords.contains(value.toLowerCase())) {
      return 'This password is too common. Please choose a stronger password';
    }

    return null;
  }

  /// Validate password confirmation
  static String? validatePasswordConfirmation(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Calculate password strength
  /// Returns: 0 (very weak) to 4 (very strong)
  static int calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;

    int strength = 0;

    // Length check
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;

    // Character variety
    if (RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password))
      strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    return strength > 4 ? 4 : strength;
  }

  /// Get password strength text
  static String getPasswordStrengthText(int strength) {
    switch (strength) {
      case 0:
        return 'Very Weak';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return 'Unknown';
    }
  }

  /// Get password strength color
  static Color getPasswordStrengthColor(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return const Color(0xFFEF4444); // Red
      case 2:
        return const Color(0xFFF59E0B); // Orange
      case 3:
        return const Color(0xFF3B82F6); // Blue
      case 4:
        return const Color(0xFF10B981); // Green
      default:
        return const Color(0xFF9CA3AF); // Gray
    }
  }

  /// Sanitize input (remove extra spaces, trim)
  static String sanitizeInput(String input) {
    // Remove extra spaces
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Validate role selection
  static String? validateRole(String? value) {
    if (value == null || value.isEmpty) {
      return 'Role is required';
    }

    final validRoles = ['driver', 'conductor'];
    if (!validRoles.contains(value.toLowerCase())) {
      return 'Invalid role selected';
    }

    return null;
  }

  /// Validate availability status
  static String? validateAvailabilityStatus(String? value) {
    if (value == null || value.isEmpty) {
      return 'Availability status is required';
    }

    final validStatuses = [
      'available',
      'in_transit',
      'on_leave',
      'unavailable',
    ];
    if (!validStatuses.contains(value.toLowerCase())) {
      return 'Invalid availability status';
    }

    return null;
  }

  /// Check if string contains only valid characters
  static bool containsOnlyValidCharacters(String value, String allowedPattern) {
    return RegExp(allowedPattern).hasMatch(value);
  }

  /// Validate general text field
  static String? validateTextField(
    String? value, {
    required String fieldName,
    int minLength = 1,
    int maxLength = 255,
    bool required = true,
    String? pattern,
    String? patternError,
  }) {
    if (value == null || value.trim().isEmpty) {
      return required ? '$fieldName is required' : null;
    }

    final trimmed = value.trim();

    if (trimmed.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    if (trimmed.length > maxLength) {
      return '$fieldName must not exceed $maxLength characters';
    }

    if (pattern != null && !RegExp(pattern).hasMatch(trimmed)) {
      return patternError ?? 'Invalid $fieldName format';
    }

    return null;
  }
}
