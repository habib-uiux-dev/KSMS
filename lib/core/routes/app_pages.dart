/// Route names only – no imports, so anything can reference a route without
/// pulling in a screen. The GetPage list lives in app_routes.dart.
abstract class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/home';
  static const adminShell = '/admin';
  static const adminProductForm = '/admin/product-form';
}
