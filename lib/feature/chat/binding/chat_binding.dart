import 'package:get/get.dart';

import '../controller/chat_detail_controller.dart';
import '../controller/chat_list_controller.dart';
import '../services/chat_service.dart';

class ChatListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatService>(() => ChatService(), fenix: true);
    Get.lazyPut<ChatListController>(() => ChatListController(), fenix: true);
  }
}

class ChatDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatService>(() => ChatService(), fenix: true);
    Get.lazyPut<ChatDetailController>(() => ChatDetailController());
  }
}
