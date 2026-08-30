import 'package:get/get.dart';

import '../../feature/admin/controller/admin_controller.dart';
import '../../feature/home/controller/home_controller.dart';
import '../services/api/api_client.dart';
import '../theme/theme_controller.dart';
import '../utils/constants.dart';

/// Wired into GetMaterialApp as `initialBinding`, so these exist before the
/// first route builds.
///
/// `permanent: true` for things that must outlive every screen; `fenix: true`
/// for feature controllers, so they are disposed when their screen pops but
/// rebuilt automatically if the user comes back.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    final apiClient = ApiClient(
      appBaseUrl: '${Constants.baseUrl}${Constants.subUrl}',
    );

    Get.put<ApiClient>(apiClient, permanent: true);
    Get.put<ThemeController>(ThemeController(), permanent: true);

    // Permanent: the shop screen asks it whether to show the admin button, and
    // it re-checks the flag on every sign-in.
    Get.put<AdminController>(AdminController(), permanent: true);

    // Repositories are cheap and stateless, so the controller builds its own
    // by default; pass fakes here in a test.
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
  }
}
