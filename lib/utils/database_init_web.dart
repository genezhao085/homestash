import 'package:flutter/foundation.dart';

/// Web platform database init — return immediately with no-op.
/// The app will show empty state instead of shimmer infinite loading.
Future<void> initDatabase() async {
  // Web: sqflite_common_ffi_web requires sqlite3.wasm which cannot be
  // downloaded from GitHub due to network restrictions in China.
  // The app gracefully handles this by showing empty content.
}
