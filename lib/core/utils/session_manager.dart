import 'package:get_storage/get_storage.dart';

import '../routes/app_pages.dart';
import '../transition/screen_transition.dart';

const kIsLogin = 'is_login';
const kToken = 'user_token';
const kIsFirstTime = 'first_time';

class SessionManager {
  SessionManager._();

  static GetStorage _preferences = GetStorage();

  static Future<void> init() async {
    await GetStorage.init();
    _preferences = GetStorage();
  }

  static void setValue(String key, dynamic value) =>
      _preferences.write(key, value);

  static dynamic getValue(String key, {dynamic value}) =>
      _preferences.read(key) ?? value;

  static dynamic removeValue(String key) => _preferences.remove(key);

  /// Clears the credentials and sends the user back to the splash screen,
  /// which re-decides where they belong.
  static void logout() {
    removeValue(kIsLogin);
    removeValue(kToken);
    const ScreenTransition(routeName: Routes.splash, replace: true).navigate();
  }
}
