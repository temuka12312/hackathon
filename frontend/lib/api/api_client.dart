import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class ApiClient {
  const ApiClient._();

  static const int _defaultPort = 3030;
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) {
      return _baseUrlOverride;
    }

    if (kIsWeb) {
      return 'http://localhost:$_defaultPort';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:$_defaultPort';
    }

    return 'http://localhost:$_defaultPort';
  }
}
