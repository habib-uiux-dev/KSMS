import 'dart:developer';

import 'package:get/get.dart';

import '../../../core/services/firebase/user_repository.dart';
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

  /// The devices that can be reached right now, and how many people exist at
  /// all. Shown side by side so a gap - somebody who has not opened the app
  /// since tokens shipped - is visible before sending, not guessed at after.
  final reachableCount = 0.obs;
  final userCount = 0.obs;
  final isCountingDevices = true.obs;

  /// The result of the last send, per device. This is the reason the whole
  /// token mechanism exists: a topic send could only ever report "accepted".
  final delivered = 0.obs;
  final failures = <PushFailure>[].obs;

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

  final UserRepository _users = UserRepository();

  @override
  void onInit() {
    super.onInit();
    _check();
    refreshDeviceCount();
  }

  Future<void> _check() async {
    isConfigured.value = await PushSender.isConfigured();
    isChecking.value = false;
  }

  /// Public so the screen can offer a retry - this is the number an admin
  /// checks after handing out a new APK.
  Future<void> refreshDeviceCount() async {
    isCountingDevices.value = true;
    try {
      final targets = await _users.fetchPushTargets();
      reachableCount.value = targets.length;
      userCount.value = await _users.countUsers();
    } catch (e) {
      log('Could not count devices: $e');
    } finally {
      isCountingDevices.value = false;
    }
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
    final sentBody = body.value.trim();
    final link = imageUrl.value.trim();

    isSending.value = true;
    delivered.value = 0;
    failures.clear();

    try {
      final targets = await _users.fetchPushTargets();

      // Nobody has registered a device yet - everyone is still on a build
      // from before tokens shipped. The topic is the only thing those phones
      // have in common, so fall back to it rather than sending to no one.
      if (targets.isEmpty) {
        final error = await PushSender.sendToEveryone(
          title: sentTitle,
          body: sentBody,
          imageUrl: link.isEmpty ? null : link,
        );
        if (error != null) {
          // Shown for longer than the usual toast: these say what to fix, and
          // they are not the kind of sentence anyone reads in two seconds.
          showCustomToast(error, duration: 6);
          return;
        }
        _finish(sentTitle);
        showCustomToast('Sent to the all_users topic');
        return;
      }

      final report = await PushSender.sendToDevices(
        targets: targets,
        title: sentTitle,
        body: sentBody,
        imageUrl: link.isEmpty ? null : link,
      );

      delivered.value = report.delivered;
      failures.value = report.failures;
      reachableCount.value = targets.length;

      if (report.delivered == 0) {
        showCustomToast('Nobody received it - see the list below', duration: 6);
        return;
      }

      _finish(sentTitle);
      showCustomToast(
        report.isCompleteSuccess
            ? 'Sent to all ${report.delivered}'
            : 'Sent to ${report.delivered} of ${report.attempted}',
      );
    } finally {
      isSending.value = false;
    }
  }

  /// Clears the draft after a send that actually reached somebody.
  void _finish(String sentTitle) {
    _rememberImage();
    lastSent.value = sentTitle;
    title.value = '';
    body.value = '';
    imageUrl.value = '';
    activePresetId.value = _customId;
  }
}
