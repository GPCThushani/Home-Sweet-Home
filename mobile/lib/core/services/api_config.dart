import 'package:flutter/foundation.dart';

class ApiConfig {
  static final String baseUrl = resolve(
    override: const String.fromEnvironment('API_BASE_URL'),
    platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
  );
  static String get origin => Uri.parse(baseUrl).origin;

  static String resolve({String override = '', required String platform}) {
    final value =
        (override.isNotEmpty
                ? override
                : 'http://${platform == 'android' ? '10.0.2.2' : 'localhost'}:8080/api')
            .replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !uri.path.endsWith('/api')) {
      throw ArgumentError(
        'API_BASE_URL must be an HTTP(S) URL ending in /api.',
      );
    }
    return value;
  }
}
