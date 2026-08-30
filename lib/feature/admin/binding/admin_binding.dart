import 'package:get/get.dart';

import '../controller/admin_dashboard_controller.dart';
import '../controller/admin_products_controller.dart';

/// Bound to the admin shell route.
///
/// [AdminController] is NOT here - it lives in InitialBinding, because the shop
/// screen needs the admin flag to decide whether to show the unlock button.
class AdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminDashboardController>(() => AdminDashboardController());
    Get.lazyPut<AdminProductsController>(() => AdminProductsController());
  }
}
