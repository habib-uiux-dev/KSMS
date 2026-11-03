import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controller/admin_notify_controller.dart';
import 'widgets/admin_widgets.dart';

/// Lets the admin write a notification and push it to everyone, instead of
/// opening the Firebase console on a laptop to do the same thing.
class AdminNotifyScreen extends StatefulWidget {
  const AdminNotifyScreen({super.key});

  @override
  State<AdminNotifyScreen> createState() => _AdminNotifyScreenState();
}

class _AdminNotifyScreenState extends State<AdminNotifyScreen> {
  final _controller = Get.put(AdminNotifyController());

  final _title = TextEditingController();
  final _body = TextEditingController();
  final _image = TextEditingController();

  /// True while a preset is being written into the fields, so the listeners
  /// below do not read that as the admin typing and drop the draft back to
  /// `custom` - which would file the image link under the wrong preset.
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    // The controller holds the text so `canSend` can react to it; these
    // listeners only mirror the fields into it.
    _title.addListener(() {
      _controller.title.value = _title.text;
      if (!_applying) _controller.markAsCustom();
    });
    _body.addListener(() {
      _controller.body.value = _body.text;
      if (!_applying) _controller.markAsCustom();
    });
    _image.addListener(() => _controller.imageUrl.value = _image.text);
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _image.dispose();
    super.dispose();
  }

  void _applyPreset(NotifyPreset preset) {
    _applying = true;
    _controller.usePreset(preset);
    _title.text = preset.title;
    _body.text = preset.body;
    // Whatever picture went out with this preset last time comes back with it.
    _image.text = _controller.imageUrl.value;
    _applying = false;
  }

  Future<void> _confirmThenSend() async {
    // Always confirm. This reaches every phone in the office at once and
    // there is no unsend - a mis-tap is not something to find out about from
    // the people it woke up.
    FocusScope.of(context).unfocus();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Send to everyone?',
          style: GoogleFonts.openSans(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _controller.title.value,
              style: GoogleFonts.openSans(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4.h),
            Text(_controller.body.value, style: GoogleFonts.openSans()),
            if (_controller.imageUrl.value.trim().isNotEmpty) ...[
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 14.sp,
                    color: AdminColors.muted,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'with a picture',
                    style: GoogleFonts.openSans(
                      fontSize: 12.sp,
                      color: AdminColors.muted,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 12.h),
            Text(
              'Everyone with the app installed gets this. It cannot be taken '
              'back.',
              style: GoogleFonts.openSans(
                fontSize: 12.sp,
                color: AdminColors.muted,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.openSans()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Send',
              style: GoogleFonts.openSans(
                fontWeight: FontWeight.w700,
                color: AdminColors.green,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _controller.send();
    if (_controller.title.value.isEmpty) {
      _applying = true;
      _title.clear();
      _body.clear();
      _image.clear();
      _applying = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final listView = ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      children: [
        Text(
          'Send a Notification',
          style: GoogleFonts.openSans(
            fontSize: 22.sp,
            fontWeight: FontWeight.w800,
            color: AdminColors.ink,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Goes to everyone with the app installed.',
          style: GoogleFonts.openSans(
            fontSize: 13.sp,
            color: AdminColors.muted,
          ),
        ),
        SizedBox(height: 14.h),

        const _CoverageCard(),
        SizedBox(height: 18.h),

        Obx(() {
          if (_controller.isChecking.value || _controller.isConfigured.value) {
            return const SizedBox.shrink();
          }
          return _SetupNote();
        }),

        Text(
          'Daily calls',
          style: GoogleFonts.openSans(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: AdminColors.ink,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            // Labels come from the presets rather than being typed again here,
            // so editing the message can never leave the button saying
            // something else.
            Expanded(
              child: _CallButton(
                label: AdminNotifyController.teaPreset.title,
                icon: Icons.local_cafe,
                color: AdminColors.green,
                onTap: () => _applyPreset(AdminNotifyController.teaPreset),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _CallButton(
                label: AdminNotifyController.smokePreset.title,
                icon: Icons.smoking_rooms,
                color: AdminColors.red,
                onTap: () => _applyPreset(AdminNotifyController.smokePreset),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Text(
          // Says what a tap does, because a big coloured button labelled
          // "চা এসেছে" reads like it sends on the spot - and one stray tap
          // reaching every phone in the office is not a thing to leave to
          // guesswork.
          'Fills the message below. Send still needs a tap.',
          style: GoogleFonts.openSans(
            fontSize: 11.sp,
            color: AdminColors.muted,
          ),
        ),

        SizedBox(height: 18.h),
        Text(
          'Other messages',
          style: GoogleFonts.openSans(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: AdminColors.ink,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final preset in AdminNotifyController.presets)
              InkWell(
                onTap: () => _applyPreset(preset),
                borderRadius: BorderRadius.circular(20.r),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 7.h,
                  ),
                  decoration: BoxDecoration(
                    color: AdminColors.tile,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: AdminColors.line),
                  ),
                  child: Text(
                    preset.title,
                    style: GoogleFonts.openSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.ink,
                    ),
                  ),
                ),
              ),
          ],
        ),

        SizedBox(height: 20.h),
        _Label('Title'),
        SizedBox(height: 8.h),
        TextField(
          controller: _title,
          textInputAction: TextInputAction.next,
          maxLength: 60,
          decoration: _decoration('যেমন: অর্ডার নেওয়া শুরু'),
          style: GoogleFonts.openSans(fontSize: 16.sp, color: AdminColors.ink),
        ),

        SizedBox(height: 6.h),
        _Label('Message'),
        SizedBox(height: 8.h),
        TextField(
          controller: _body,
          maxLines: 3,
          maxLength: 180,
          decoration: _decoration('যা জানাতে চান'),
          style: GoogleFonts.openSans(fontSize: 16.sp, color: AdminColors.ink),
        ),

        SizedBox(height: 6.h),
        Row(
          children: [
            _Label('Picture link'),
            SizedBox(width: 6.w),
            Text(
              'optional',
              style: GoogleFonts.openSans(
                fontSize: 12.sp,
                color: AdminColors.muted,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: _image,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: _decoration('https://...'),
          style: GoogleFonts.openSans(fontSize: 14.sp, color: AdminColors.ink),
        ),
        SizedBox(height: 6.h),
        Obx(() {
          final link = _controller.imageUrl.value.trim();

          if (link.isNotEmpty && !_controller.isImageLinkValid) {
            return _Hint(
              'That is not a link. It has to start with https://',
              color: AdminColors.red,
              icon: Icons.error_outline,
            );
          }

          if (link.isEmpty) {
            return _Hint(
              'Remembered per message - the tea link comes back next tea time.',
              color: AdminColors.muted,
              icon: Icons.info_outline,
            );
          }

          return _ImagePreview(url: link);
        }),

        SizedBox(height: 14.h),
        SizedBox(
          width: double.infinity,
          height: 52.h,
          child: Obx(
            () => ElevatedButton.icon(
              onPressed: _controller.canSend ? _confirmThenSend : null,
              icon: _controller.isSending.value
                  ? SizedBox(
                      width: 16.w,
                      height: 16.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.send, size: 18.sp, color: Colors.white),
              label: Text(
                _controller.isSending.value ? 'Sending...' : 'Send to everyone',
                style: GoogleFonts.openSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.green,
                disabledBackgroundColor: const Color(0xFF86C8A2),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ),

        Obx(() {
          final last = _controller.lastSent.value;
          if (last == null) return const SizedBox.shrink();
          return Padding(
            padding: EdgeInsets.only(top: 14.h),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 16.sp,
                  color: AdminColors.green,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    'Last sent: $last',
                    style: GoogleFonts.openSans(
                      fontSize: 12.sp,
                      color: AdminColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        const _FailureList(),
      ],
    );

    if (Navigator.canPop(context)) {
      return Scaffold(
        backgroundColor: AdminColors.bg,
        appBar: AppBar(
          backgroundColor: AdminColors.bg,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: AdminColors.ink),
            tooltip: 'Back',
          ),
          title: Text(
            'Notifications',
            style: GoogleFonts.openSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AdminColors.ink,
            ),
          ),
        ),
        body: listView,
      );
    }

    return listView;
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.openSans(
      color: const Color(0xFF9AA49A),
      fontSize: 15.sp,
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 14.w),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: const BorderSide(color: AdminColors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: const BorderSide(color: AdminColors.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: const BorderSide(color: AdminColors.green),
    ),
  );
}

/// How many phones can actually be reached, against how many people exist.
///
/// Sent to a topic, this number was unknowable - which is exactly why "it
/// reaches some devices and not others" went uninvestigated for so long. A
/// gap here has one cause: somebody has not opened the current build yet, so
/// their device has never registered.
class _CoverageCard extends StatelessWidget {
  const _CoverageCard();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminNotifyController>();

    return Obx(() {
      final reachable = controller.reachableCount.value;
      final total = controller.userCount.value;
      final missing = total - reachable;
      final busy = controller.isCountingDevices.value;

      final allCovered = missing <= 0 && reachable > 0;

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: allCovered ? const Color(0xFFDCFCE7) : AdminColors.tile,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: allCovered
                ? AdminColors.green.withValues(alpha: 0.3)
                : AdminColors.line,
          ),
        ),
        child: Row(
          children: [
            Icon(
              allCovered ? Icons.devices : Icons.phonelink_erase_outlined,
              size: 20.sp,
              color: allCovered ? AdminColors.green : AdminColors.muted,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    busy
                        ? 'Checking devices...'
                        : '$reachable of $total can be reached',
                    style: GoogleFonts.openSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: allCovered ? AdminColors.green : AdminColors.ink,
                    ),
                  ),
                  if (!busy && missing > 0) ...[
                    SizedBox(height: 2.h),
                    Text(
                      '$missing ${missing == 1 ? 'person has' : 'people have'} '
                      'not opened the latest app yet',
                      style: GoogleFonts.openSans(
                        fontSize: 12.sp,
                        color: AdminColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: busy ? null : controller.refreshDeviceCount,
              icon: Icon(Icons.refresh, size: 18.sp, color: AdminColors.muted),
              visualDensity: VisualDensity.compact,
              tooltip: 'Check again',
            ),
          ],
        ),
      );
    });
  }
}

/// Names the phones the last send did not reach.
class _FailureList extends StatelessWidget {
  const _FailureList();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminNotifyController>();

    return Obx(() {
      final failures = controller.failures;
      if (failures.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: EdgeInsets.only(top: 16.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AdminColors.amberBg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AdminColors.amber.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Did not reach ${failures.length}',
              style: GoogleFonts.openSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AdminColors.amber,
              ),
            ),
            SizedBox(height: 8.h),
            for (final failure in failures)
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Text(
                  '${failure.name} — ${failure.reason}',
                  style: GoogleFonts.openSans(
                    fontSize: 12.sp,
                    color: const Color(0xFF7A4A0A),
                  ),
                ),
              ),
            SizedBox(height: 4.h),
            Text(
              // Says what to do about it, because "App removed or reinstalled"
              // on its own reads like something the admin has to fix.
              'These fix themselves the next time that person opens the app.',
              style: GoogleFonts.openSans(
                fontSize: 11.sp,
                color: AdminColors.muted,
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// Draws the picture before it goes out.
///
/// Worth the space: FCM fetches the URL on its own servers and silently drops
/// the picture if it cannot, so a bad link produces a perfectly successful
/// send with no image and no error. Seeing it load here is the only warning
/// available.
class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: Image.network(
        url,
        height: 120.h,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : Container(
                height: 120.h,
                color: AdminColors.tile,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
        errorBuilder: (context, error, stack) => Container(
          height: 60.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          color: AdminColors.amberBg,
          child: Row(
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: 18.sp,
                color: AdminColors.amber,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'This link did not load. The notification would arrive '
                  'without a picture.',
                  style: GoogleFonts.openSans(
                    fontSize: 12.sp,
                    color: const Color(0xFF7A4A0A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text, {required this.color, required this.icon});

  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13.sp, color: color),
        SizedBox(width: 5.w),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.openSans(fontSize: 11.sp, color: color),
          ),
        ),
      ],
    );
  }
}

/// One of the two daily calls. Same shape as the tea/smoke shortcuts the shop
/// screen already uses, so the pair reads as the same idea.
class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.openSans(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 14.r,
              child: Icon(icon, size: 17.sp, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown until the service-account key is added, because otherwise the first
/// send fails with an error nobody can act on from the phone.
class _SetupNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 18.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AdminColors.amberBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AdminColors.amber.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.key_outlined, size: 18.sp, color: AdminColors.amber),
              SizedBox(width: 8.w),
              Text(
                'Sender key not added yet',
                style: GoogleFonts.openSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.amber,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'Put the service-account JSON at\n'
            'assets/secrets/fcm_service_account.json and rebuild. The '
            '.example file next to it says where to download one.',
            style: GoogleFonts.openSans(
              fontSize: 12.sp,
              height: 1.5,
              color: const Color(0xFF7A4A0A),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.openSans(
      fontSize: 13.sp,
      fontWeight: FontWeight.w700,
      color: AdminColors.ink,
    ),
  );
}
