import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

import 'package:kms/core/routes/app_pages.dart';
import 'package:kms/core/routes/app_routes.dart';
import 'package:kms/core/utils/session_manager.dart';

/// Note: these deliberately do not pump [MyApp]. Every screen renders
/// google_fonts text, which fetches the face over HTTP on first use - there is
/// no network in a widget test, so it throws no matter what is asserted.
/// Bundle Inter under `assets/fonts/` and switch app_fonts.dart to
/// `TextStyle(fontFamily: ...)` if you want a full-app boot test.
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // GetStorage asks path_provider where to put its file, and there is no
    // plugin implementation in the test host - answer the channel ourselves.
    final storageDir = Directory('.dart_tool/test_storage')
      ..createSync(recursive: true);

    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => storageDir.path,
    );

    await SessionManager.init();
  });

  test('every route name has exactly one page', () {
    final names = AppPages.pages.map((p) => p.name).toList();

    expect(names, contains(Routes.splash));
    expect(names, contains(Routes.home));
    expect(names.toSet().length, names.length, reason: 'duplicate route name');
  });

  test('SessionManager round-trips and clears values', () {
    SessionManager.setValue(kToken, 'abc123');
    expect(SessionManager.getValue(kToken), 'abc123');

    SessionManager.removeValue(kToken);
    expect(SessionManager.getValue(kToken, value: ''), '');
  });

  tearDownAll(() async {
    await GetStorage().erase();
  });
}
