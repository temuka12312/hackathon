import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class ApiClient {
  const ApiClient._();

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3030';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3030';
    }

    return 'http://localhost:3030';
  }
}
