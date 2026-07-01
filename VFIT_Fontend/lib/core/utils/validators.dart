class Validators {
  const Validators._();

  static String? required(String? value, {String label = 'Trường này'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label không được để trống';
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
      return 'Vui lòng nhập địa chỉ email hợp lệ';
    }
    return null;
  }

  static String? password(String? value) {
    final requiredMessage = required(value, label: 'Mật khẩu');
    if (requiredMessage != null) {
      return requiredMessage;
    }
    final password = value!;
    if (password.length < 8) {
      return 'Mật khẩu phải dài ít nhất 8 ký tự';
    }
    if (!RegExp('[A-Z]').hasMatch(password)) {
      return 'Mật khẩu phải chứa ít nhất một chữ hoa';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Mật khẩu phải chứa ít nhất một chữ số';
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
      return '$label phải là một số';
    }
    if (parsed < min || parsed > max) {
      return '$label phải nằm trong khoảng từ $min đến $max';
    }
    return null;
  }
}
