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

  @override
  void initState() {
    super.initState();
    // The controller holds the text so `canSend` can react to it; these two
    // only mirror it into the fields when a preset is tapped.
    _title.addListener(() => _controller.title.value = _title.text);
    _body.addListener(() => _controller.body.value = _body.text);
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _applyPreset(({String title, String body}) preset) {
    _controller.usePreset(preset);
    _title.text = preset.title;
    _body.text = preset.body;
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
      _title.clear();
      _body.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
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
        SizedBox(height: 18.h),

        Obx(() {
          if (_controller.isChecking.value || _controller.isConfigured.value) {
            return const SizedBox.shrink();
          }
          return _SetupNote();
        }),

        Text(
          'Quick messages',
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

        SizedBox(height: 12.h),
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
      ],
    );
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
