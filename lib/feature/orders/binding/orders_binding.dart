import 'package:get/get.dart';

import '../controller/orders_controller.dart';

/// Built on navigation, disposed on pop - so the two history streams only run
/// while the screen is open.
class OrdersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrdersController>(OrdersController.new);
  }
}
