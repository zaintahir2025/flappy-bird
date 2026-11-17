// CONDITIONAL COMPILATION STORAGE FACADE
//
// Dart resolves conditional export directives at compile-time:
// 1. By default, it uses 'score_storage_stub.dart' (the base API contract).
// 2. If compiling for Native platforms (Android, iOS, Windows, macOS, Linux),
//    'dart.library.io' is available, so it exports 'score_storage_io.dart' (local JSON file).
// 3. If compiling for Web browsers (Chrome, Safari, Edge, Firefox),
//    'dart.library.js_interop' is available, so it exports 'score_storage_web.dart' (localStorage).
//
// This guarantees that no platform-specific code (like dart:io) ever leaks into the web build,
// preventing runtime and compile-time crashes across all devices.

export 'score_storage_stub.dart'
    if (dart.library.io) 'score_storage_io.dart'
    if (dart.library.js_interop) 'score_storage_web.dart';
