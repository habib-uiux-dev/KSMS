import 'package:get/get.dart';

import '../../../core/services/notifications/push_sender.dart';
import '../../../core/widgets/show_custom_toast.dart';

/// Backs the admin's "send a notification to everyone" screen.
class AdminNotifyController extends GetxController {
  final title = ''.obs;
  final body = ''.obs;

  final isSending = false.obs;

  /// False until the service-account key has been dropped into assets. The
  /// screen shows the setup note instead of a dead Send button.
  final isConfigured = true.obs;
  final isChecking = true.obs;

  /// Kept only for this session. Enough to see that the last one went, not
  /// enough to pretend this is a message history.
  final lastSent = RxnString();

  /// Ready-made lines for the three things the shop actually announces.
  static const List<({String title, String body})> presets = [
    (title: 'অর্ডার নেওয়া শুরু', body: 'আজকের অর্ডার দেওয়া যাচ্ছে এখন।'),
    (title: 'অর্ডার বন্ধ', body: 'আজকের মতো অর্ডার নেওয়া বন্ধ।'),
    (title: 'নতুন আইটেম', body: 'দোকানে নতুন কিছু এসেছে, দেখে নিন।'),
  ];

  bool get canSend =>
      !isSending.value &&
      isConfigured.value &&
      title.value.trim().isNotEmpty &&
      body.value.trim().isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _check();
  }

  Future<void> _check() async {
    isConfigured.value = await PushSender.isConfigured();
    isChecking.value = false;
  }

  void usePreset(({String title, String body}) preset) {
    title.value = preset.title;
    body.value = preset.body;
  }

  Future<void> send() async {
    if (!canSend) return;

    final sentTitle = title.value.trim();
    isSending.value = true;
    try {
      final error = await PushSender.sendToEveryone(
        title: sentTitle,
        body: body.value.trim(),
      );

      if (error != null) {
        // Shown for longer than the usual toast: these say what to fix, and
        // they are not the kind of sentence anyone reads in two seconds.
        showCustomToast(error, duration: 6);
        return;
      }

      lastSent.value = sentTitle;
      title.value = '';
      body.value = '';
      showCustomToast('Sent to everyone');
    } finally {
      isSending.value = false;
    }
  }
}
