import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/firebase/app_firestore.dart';
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

  static const NotifyPreset mealBillPreset = (
    id: 'meal_bill',
    title: 'খাবারের বিল দিন',
    body: 'আজকের খাবারের বিল পরিশোধ করার জন্য বিনীত অনুরোধ করা হচ্ছে।',
  );

  static const NotifyPreset giftBillPreset = (
    id: 'gift_bill',
    title: 'গিফটের বিল দিন',
    body: 'আজকের গিফটের বিল পরিশোধ করার জন্য বিনীত অনুরোধ করা হচ্ছে।',
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
    mealBillPreset,
    giftBillPreset,
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

  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return null;
  }

  Future<Set<String>?> _fetchLatestEventUserIds({required bool isMeal}) async {
    try {
      final targetType = isMeal ? 'meal' : 'gift';
      final List<Map<String, dynamic>> allEvents = [];

      try {
        final snapshot = await appFirestore.collection('events').get();
        for (final doc in snapshot.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          if (!data.containsKey('id') || data['id'] == null) {
            data['id'] = doc.id;
          }
          allEvents.add(data);
        }
      } catch (e) {
        log('Could not fetch events from Firestore: $e');
      }

      if (allEvents.isEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final eventsJson = prefs.getStringList('app_events');
          if (eventsJson != null && eventsJson.isNotEmpty) {
            for (final str in eventsJson) {
              final map = jsonDecode(str) as Map<String, dynamic>;
              allEvents.add(map);
            }
          }
        } catch (e) {
          log('Could not load events from prefs fallback: $e');
        }
      }

      if (allEvents.isEmpty) return null;

      final matchingDocs = allEvents.where((data) {
        final type = data['type']?.toString().toLowerCase().trim();
        return type == targetType;
      }).toList();

      if (matchingDocs.isEmpty) return null;

      matchingDocs.sort((a, b) {
        final dateA = _parseDate(a['date'] ?? a['createdAt'] ?? a['created_at']);
        final dateB = _parseDate(b['date'] ?? b['createdAt'] ?? b['created_at']);
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA);
      });

      final latestDoc = matchingDocs.first;
      final userStatuses = latestDoc['userStatuses'] as List? ?? [];
      final selectedUserIdsList = latestDoc['selectedUserIds'] as List? ?? [];

      final rawSelectedIds = <String>{};
      for (final s in userStatuses) {
        if (s is Map) {
          final uId = s['userId']?.toString().trim();
          if (uId != null && uId.isNotEmpty) {
            rawSelectedIds.add(uId);
          }
        } else if (s is String && s.trim().isNotEmpty) {
          rawSelectedIds.add(s.trim());
        }
      }
      for (final id in selectedUserIdsList) {
        if (id != null && id.toString().trim().isNotEmpty) {
          rawSelectedIds.add(id.toString().trim());
        }
      }

      if (rawSelectedIds.isEmpty) return null;

      final resolvedUids = <String>{...rawSelectedIds};
      try {
        final allUserDocs = await appFirestore.collection('users').get();
        for (final uDoc in allUserDocs.docs) {
          final uData = uDoc.data();
          if (UserRepository.matchesUser(
            allowedIdentifiers: rawSelectedIds,
            docId: uDoc.id,
            data: uData,
          )) {
            resolvedUids.add(uDoc.id);
            final customId = uData['id']?.toString().trim();
            final authUid = uData['uid']?.toString().trim();
            final email = uData['email']?.toString().trim();
            final name = uData['name']?.toString().trim();
            if (customId != null && customId.isNotEmpty) resolvedUids.add(customId);
            if (authUid != null && authUid.isNotEmpty) resolvedUids.add(authUid);
            if (email != null && email.isNotEmpty) resolvedUids.add(email);
            if (name != null && name.isNotEmpty) resolvedUids.add(name);
          }
        }
      } catch (e) {
        log('Could not resolve user aliases: $e');
      }

      return resolvedUids;
    } catch (e) {
      log('Could not fetch event user ids: $e');
      return null;
    }
  }

  Future<void> send() async {
    if (!canSend) return;

    final sentTitle = title.value.trim();
    final sentBody = body.value.trim();
    final link = imageUrl.value.trim();

    isSending.value = true;
    delivered.value = 0;
    failures.clear();

    try {
      final isMealBill = activePresetId.value == 'meal_bill' ||
          sentTitle == mealBillPreset.title ||
          sentTitle.contains('খাবারের বিল') ||
          sentTitle.toLowerCase().contains('meal bill');

      final isGiftBill = activePresetId.value == 'gift_bill' ||
          sentTitle == giftBillPreset.title ||
          sentTitle.contains('গিফটের বিল') ||
          sentTitle.toLowerCase().contains('gift bill');

      final isTargetedBill = isMealBill || isGiftBill;

      Set<String>? allowedUids;
      if (isMealBill) {
        allowedUids = await _fetchLatestEventUserIds(isMeal: true);
        if (allowedUids == null || allowedUids.isEmpty) {
          showCustomToast('কোনো মিল ইভেন্ট বা নির্বাচিত ইউজার পাওয়া যায়নি', duration: 4);
          return;
        }
      } else if (isGiftBill) {
        allowedUids = await _fetchLatestEventUserIds(isMeal: false);
        if (allowedUids == null || allowedUids.isEmpty) {
          showCustomToast('কোনো গিফট ইভেন্ট বা নির্বাচিত ইউজার পাওয়া যায়নি', duration: 4);
          return;
        }
      }

      final targets = await _users.fetchPushTargets(allowedUids: allowedUids);

      // Nobody has registered a device yet - everyone is still on a build
      // from before tokens shipped.
      if (targets.isEmpty) {
        if (isTargetedBill) {
          showCustomToast('নির্বাচিত ইউজারদের কোনো ডিভাইস টোকেন পাওয়া যায়নি', duration: 5);
          return;
        }

        // Only general announcements fall back to the all_users topic
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
