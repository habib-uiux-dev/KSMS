import 'package:get/route_manager.dart';

/// One call site for every kind of navigation, so screens never reach for
/// `Get.offAllNamed` / `Get.offAndToNamed` directly and the intent is spelled
/// out by the flag name.
class ScreenTransition {
  final String routeName;
  final dynamic arguments;
  final Map<String, String>? params;

  /// Wipes the stack – use after login / logout.
  final bool? replace;

  /// Replaces only the current screen.
  final bool? removeCurrentScreen;

  /// Pops the current screen, then pushes – avoids stacking duplicates.
  final bool? reOpen;

  /// Pops back to an existing route instead of pushing anything.
  final String? backToRoute;

  /// Pushes, then pops back to [backTo] once the pushed screen returns.
  final String? backTo;

  const ScreenTransition({
    required this.routeName,
    this.arguments,
    this.params,
    this.replace,
    this.reOpen,
    this.removeCurrentScreen,
    this.backToRoute,
    this.backTo,
  });

  void navigate() {
    if (replace ?? false) {
      Get.offAllNamed(routeName, arguments: arguments, parameters: params);
    } else if (removeCurrentScreen ?? false) {
      Get.offAndToNamed(routeName, arguments: arguments, parameters: params);
    } else if (reOpen ?? false) {
      Get.offNamed(routeName, arguments: arguments, parameters: params);
    } else if (backToRoute != null) {
      Get.until((route) => Get.currentRoute == backToRoute);
    } else {
      Get.toNamed(routeName, arguments: arguments, parameters: params)?.then((
        _,
      ) {
        if (backTo != null) {
          Get.until((route) => Get.currentRoute == backTo);
        }
      });
    }
  }
}
