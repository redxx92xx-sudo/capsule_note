import 'package:flutter/foundation.dart';

/// Limited diagnostics so a hung test can report the last await.
void rkTrace(String location) {
  debugPrint('[RK_TRACE ${DateTime.now().toIso8601String()}] $location');
}
