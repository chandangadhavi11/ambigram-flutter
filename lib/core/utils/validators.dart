class Validators {
  static bool isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+\$').hasMatch(email);
  }

  static bool isValidPassword(String password) {
    // For demonstration, let's say password must be at least 6 chars
    return password.length >= 6;
  }
}
