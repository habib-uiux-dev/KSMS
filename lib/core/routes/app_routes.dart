import 'package:get/get.dart';

import '../../feature/admin/binding/admin_binding.dart';
import '../../feature/admin/view/admin_product_form_screen.dart';
import '../../feature/admin/view/admin_shell_screen.dart';
import '../../feature/auth/binding/auth_binding.dart';
import '../../feature/auth/view/designation_screen.dart';
import '../../feature/auth/view/login_screen.dart';
import '../../feature/home/view/home_screen.dart';
import '../../feature/orders/binding/orders_binding.dart';
import '../../feature/orders/view/orders_shell_screen.dart';
import '../../feature/splash/view/splash_screen.dart';
import '../../feature/chat/binding/chat_binding.dart';
import '../../feature/chat/view/chat_detail_screen.dart';
import '../../feature/chat/view/chat_list_screen.dart';
import '../../feature/accounts/binding/accounts_binding.dart';
import '../../feature/accounts/view/accounts_screen.dart';
import '../../feature/accounts/view/accounts_history_screen.dart';
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
      name: Routes.designation,
      page: () => const DesignationScreen(),
      transition: Transition.native,
      // Reached from splash too, where AuthController may not exist yet.
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
    GetPage(
      name: Routes.chatList,
      page: () => const ChatListScreen(),
      transition: Transition.native,
      binding: ChatListBinding(),
    ),
    GetPage(
      name: Routes.chatDetail,
      page: () => const ChatDetailScreen(),
      transition: Transition.native,
      binding: ChatDetailBinding(),
    ),
    GetPage(
      name: Routes.accounts,
      page: () => const AccountsScreen(),
      transition: Transition.native,
      binding: AccountsBinding(),
    ),
    GetPage(
      name: Routes.accountsHistory,
      page: () => const AccountsHistoryScreen(),
      transition: Transition.native,
      binding: AccountsBinding(),
    ),
  ];
}
