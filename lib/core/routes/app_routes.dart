import 'package:get/get.dart';

import '../../feature/admin/binding/admin_binding.dart';
import '../../feature/admin/view/admin_product_form_screen.dart';
import '../../feature/admin/view/admin_shell_screen.dart';
import '../../feature/auth/binding/auth_binding.dart';
import '../../feature/auth/view/login_screen.dart';
import '../../feature/home/view/home_screen.dart';
import '../../feature/orders/binding/orders_binding.dart';
import '../../feature/orders/view/orders_shell_screen.dart';
import '../../feature/splash/view/splash_screen.dart';
import 'app_pages.dart';

/// The route table handed to GetMaterialApp. Bind a controller to a page with
/// `binding:` so it is created on navigation and disposed on pop.
class AppPages {
  AppPages._();

  static final pages = [
    GetPage(
      name: Routes.splash,
      page: () => const SplashScreen(),
      transition: Transition.native,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginScreen(),
      transition: Transition.native,
      transitionDuration: const Duration(milliseconds: 300),
      // AuthController is built here, so LoginScreen can Get.find it.
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomeScreen(),
      transition: Transition.native,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.myOrders,
      page: () => const OrdersShellScreen(),
      transition: Transition.native,
      binding: OrdersBinding(),
    ),
    GetPage(
      name: Routes.adminShell,
      page: () => const AdminShellScreen(),
      transition: Transition.native,
      binding: AdminBinding(),
    ),
    GetPage(
      name: Routes.adminProductForm,
      page: () => const AdminProductFormScreen(),
      transition: Transition.native,
    ),
  ];
}
