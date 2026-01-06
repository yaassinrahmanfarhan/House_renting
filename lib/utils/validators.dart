class AppValidators {
  // 1. Email Regex: Ensures standard format (user@domain.com)
  static final RegExp _emailRegExp = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  );

  // 2. Password Regex: At least 8 chars, 1 uppercase, 1 lowercase, 1 number, 1 special char
  static final RegExp _passwordRegExp = RegExp(
    r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$',
  );

  // 3. Username Regex: 3-20 chars, alphanumeric and underscores only
  static final RegExp _usernameRegExp = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!_emailRegExp.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (!_passwordRegExp.hasMatch(value)) {
      return 'Must have 8+ chars, uppercase, number & special char';
    }
    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) return 'Username is required';
    if (!_usernameRegExp.hasMatch(value)) {
      return '3-20 chars, letters, numbers, and underscores only';
    }
    return null;
  }
}