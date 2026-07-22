import 'package:flutter/foundation.dart';
import 'package:sqflite_common/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> initDatabase() async {
  try {
    // Set the WebAssembly SQLite database factory for web platform
    databaseFactory = databaseFactoryFfiWebNoWebWorker;

    // Quick test: verify the factory wasm loads within 8 seconds.
    // If it hangs, the timeout fires, we set factory to null,
    // causing sqflite to throw StateError quickly instead of hanging.
    await databaseFactory
        .getDatabasesPath()
        .timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint('Web SQLite WASM init failed, falling back: $e');
    // Reset factory — sqflite will throw StateError quickly on next call,
    // which is caught by caller's try-catch and shows empty state.
    databaseFactory = null;
  }
}
