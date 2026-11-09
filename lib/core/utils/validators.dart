/// Utility class for form validation
class Validators {
  Validators._();

  /// Validate required field
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate medicine name
  static String? medicineName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Medicine name is required';
    }
    if (value.trim().length < 2) {
      return 'Medicine name must be at least 2 characters';
    }
    return null;
  }

  /// Validate dosage
  static String? dosage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Dosage is required';
    }
    return null;
  }

  /// Validate minimum length
  static String? minLength(String? value, int length,
      {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < length) {
      return '$fieldName must be at least $length characters';
    }
    return null;
  }

  /// Validate maximum length
  static String? maxLength(String? value, int length,
      {String fieldName = 'This field'}) {
    if (value != null && value.trim().length > length) {
      return '$fieldName must be at most $length characters';
    }
    return null;
  }
}

