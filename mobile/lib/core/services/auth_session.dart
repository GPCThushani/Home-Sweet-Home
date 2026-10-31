import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationException implements Exception {
  final String message;
  const AuthenticationException([
    this.message = 'Your session has expired. Please log in again.',
  ]);

  @override
  String toString() => message;
}

class AuthorizationException implements Exception {
  const AuthorizationException();

  @override
  String toString() =>
      'You do not have permission to access this family or record.';
}

class AuthSession {
  static void Function(String message)? onAuthenticationRequired;
  static bool _notified = false;

  // This detects missing/malformed/expired sessions. Signature verification is
  // always performed by the backend, never trusted to the client.
  static bool isUsableToken(Object? value) {
    if (value is! String || value.trim() != value) return false;
    try {
      final parts = value.split('.');
      if (parts.length != 3 || parts.any((part) => part.isEmpty)) return false;
      final claims = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return claims is Map &&
          claims['sub'] is String &&
          (claims['sub'] as String).isNotEmpty &&
          claims['exp'] is num &&
          (claims['exp'] as num) * 1000 > DateTime.now().millisecondsSinceEpoch;
    } catch (_) {
      return false;
    }
  }

  static Future<void> save(Map<String, dynamic> response) async {
    final token = response['token'];
    final userId = response['userId'];
    final email = response['email'];
    if (!isUsableToken(token) ||
        userId is! String ||
        userId.isEmpty ||
        email is! String ||
        email.isEmpty) {
      throw const AuthenticationException(
        'The server did not return a valid login session. Please try logging in.',
      );
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token as String);
    await prefs.setString('user_id', userId);
    await prefs.setString('user_email', email);
    _notified = false;
  }

  static Future<String> requireToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (!isUsableToken(token)) {
      await invalidate(token);
      throw const AuthenticationException();
    }
    return token!;
  }

  static Future<void> invalidate(String? rejectedToken) async {
    final prefs = await SharedPreferences.getInstance();
    // A response from an older request must not clear a newer login.
    if (prefs.getString('jwt_token') != rejectedToken) return;
    await prefs.remove('jwt_token');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    if (!_notified) {
      _notified = true;
      onAuthenticationRequired?.call(const AuthenticationException().message);
    }
  }
}
