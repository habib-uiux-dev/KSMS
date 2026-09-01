import 'package:get/get.dart';

import '../../../core/services/notifications/push_sender.dart';
import '../../../core/utils/session_manager.dart';
import '../../../core/widgets/show_custom_toast.dart';

/// One ready-made announcement.
///
/// The `id` is what the remembered image link is filed under, so it must stay
/// stable - renaming the title is safe, renaming the id orphans the saved link.
typedef NotifyPreset = ({String id, String title, String body});

/// Backs the admin's "send a notification to everyone" screen.
class AdminNotifyController extends GetxController {
  final title = ''.obs;
  final body = ''.obs;

  /// Optional picture shown inside the notification.
  final imageUrl = ''.obs;

  final isSending = false.obs;

  /// False until the service-account key has been dropped into assets. The
  /// screen shows the setup note instead of a dead Send button.
  final isConfigured = true.obs;
  final isChecking = true.obs;

  /// Kept only for this session. Enough to see that the last one went, not
  /// enough to pretend this is a message history.
  final lastSent = RxnString();

  /// Which preset the current draft came from, so the image link is saved back
  /// under the right one. Anything typed by hand shares the `custom` slot.
  final activePresetId = _customId.obs;

  static const String _customId = 'custom';

  /// The two calls that go out every day.
  ///
  /// Kept apart from [presets] and given their own buttons rather than another
  /// pair of identical chips: these are the reason this screen gets opened,
  /// and burying them in a row of five would cost a hunt every single time.
  static const NotifyPreset teaPreset = (
    id: 'tea',
    title: 'চা এসেছে',
    body: 'চা ব্রেকের সময়, চলে আসুন।',
  );

  static const NotifyPreset smokePreset = (
    id: 'smoke',
    title: 'স্মোক ব্রেক',
    body: 'স্মোক ব্রেকের সময়, চলে আসুন।',
  );

  /// The occasional ones, as chips.
  static const List<NotifyPreset> presets = [
    (
      id: 'orders_open',
      title: 'অর্ডার নেওয়া শুরু',
      body: 'আজকের অর্ডার দেওয়া যাচ্ছে এখন।',
    ),
    (
      id: 'orders_closed',
      title: 'অর্ডার বন্ধ',
      body: 'আজকের মতো অর্ডার নেওয়া বন্ধ।',
    ),
    (
      id: 'new_item',
      title: 'নতুন আইটেম',
      body: 'দোকানে নতুন কিছু এসেছে, দেখে নিন।',
    ),
  ];

  // ------------------------------------------------------- remembered images

  static String _imageKey(String presetId) => 'notify_image_$presetId';

  /// The link last sent with this preset, or empty if there wasn't one.
  static String savedImageFor(String presetId) =>
      SessionManager.getValue(_imageKey(presetId), value: '') as String? ?? '';

  /// Written only after a send actually succeeds.
  ///
  /// Saving on every keystroke would mean a half-pasted link becomes the
  /// remembered one the moment the screen closes, and a link that FCM rejected
  /// would come back tomorrow to fail again.
  void _rememberImage() {
    final key = _imageKey(activePresetId.value);
    final link = imageUrl.value.trim();
    if (link.isEmpty) {
      // Clearing the field and sending is how you forget a link. Leaving the
      // old one behind would make that impossible from inside the app.
      SessionManager.removeValue(key);
    } else {
      SessionManager.setValue(key, link);
    }
  }

  // --------------------------------------------------------------- validity

  /// True when the box is empty or holds something FCM will actually fetch.
  ///
  /// FCM downloads this URL on its own servers, so a link that only works on
  /// the office wifi, or one behind a login, silently arrives as a
  /// notification with no picture. There is no error for that - which is why
  /// the screen previews it before sending.
  bool get isImageLinkValid {
    final link = imageUrl.value.trim();
    if (link.isEmpty) return true;
    final uri = Uri.tryParse(link);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  bool get canSend =>
      !isSending.value &&
      isConfigured.value &&
      isImageLinkValid &&
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

  /// Loads a preset along with whatever picture went out with it last time.
  void usePreset(NotifyPreset preset) {
    title.value = preset.title;
    body.value = preset.body;
    activePresetId.value = preset.id;
    imageUrl.value = savedImageFor(preset.id);
  }

  /// Called when the text is edited by hand, so the draft stops belonging to
  /// whichever preset filled it and its image is saved separately.
  void markAsCustom() => activePresetId.value = _customId;

  Future<void> send() async {
    if (!canSend) return;

    final sentTitle = title.value.trim();
    final link = imageUrl.value.trim();

    isSending.value = true;
    try {
      final error = await PushSender.sendToEveryone(
        title: sentTitle,
        body: body.value.trim(),
        imageUrl: link.isEmpty ? null : link,
      );

      if (error != null) {
        // Shown for longer than the usual toast: these say what to fix, and
        // they are not the kind of sentence anyone reads in two seconds.
        showCustomToast(error, duration: 6);
        return;
      }

      _rememberImage();
      lastSent.value = sentTitle;
      title.value = '';
      body.value = '';
      imageUrl.value = '';
      activePresetId.value = _customId;
      showCustomToast('Sent to everyone');
    } finally {
      isSending.value = false;
    }
  }
}
