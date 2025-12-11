import 'package:flutter/foundation.dart';

class ApiHelper {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:5032';
    } else {
      return 'http://10.0.2.2:5032';
    }
  }
}
