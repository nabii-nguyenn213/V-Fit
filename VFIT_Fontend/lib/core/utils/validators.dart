class Validators {
  const Validators._();

  static String? required(String? value, {String label = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static String? email(String? value) {
    final requiredMessage = required(value, label: 'Email');
    if (requiredMessage != null) {
      return requiredMessage;
    }
    final normalized = value!.trim();
    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalized);
    if (!isValid) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? password(String? value) {
    final requiredMessage = required(value, label: 'Password');
    if (requiredMessage != null) {
      return requiredMessage;
    }
    final password = value!;
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp('[A-Z]').hasMatch(password)) {
      return 'Password must contain one uppercase letter';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Password must contain one number';
    }
    return null;
  }

  static String? optionalNumber(
    String? value, {
    required double min,
    required double max,
    required String label,
  }) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return '$label must be a number';
    }
    if (parsed < min || parsed > max) {
      return '$label must be between $min and $max';
    }
    return null;
  }
}
