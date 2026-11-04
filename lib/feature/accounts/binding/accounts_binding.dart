import 'package:get/get.dart';
import '../controller/accounts_controller.dart';

class AccountsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AccountsController>(() => AccountsController());
  }
}
