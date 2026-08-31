import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/controller/auth_controller.dart';
import '../controller/home_controller.dart';

const Color _green = Color(0xFF116A2A);
const Color _ink = Color(0xFF23332B);
const Color _muted = Color(0xFF6E7A74);
const Color _line = Color(0xFFE8ECE9);
const Color _border = Color(0xFFBFD6C6);

/// Lets someone fix their own name and team after onboarding.
///
/// Without this the designation picker was a one-way door: it appears once per
/// account and never again, so a wrong tap during sign-up stuck forever - and
/// reinstalling did not reset it, because the answer lives with the account.
Future<void> showEditProfileSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (context) => const _EditProfileSheet(),
  );
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final HomeController _controller = Get.find<HomeController>();
  late final TextEditingController _name = TextEditingController(
    text: _controller.greetingName,
  );

  late String? _designation = _selectableDesignation();

  /// A role saved before the fixed list existed - or removed from it since -
  /// is not a valid dropdown value, and passing it would assert. Falling back
  /// to null just shows the hint until they pick.
  String? _selectableDesignation() {
    final current = _controller.greetingDesignation;
    return AuthController.designations.contains(current) ? current : null;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Dismissing the keyboard first, then popping.
  ///
  /// A text field torn down mid keyboard-animation is what threw the
  /// `'attached': is not true` assertion on the old login screen: its caret
  /// callback runs a frame later, against a render object that is already gone.
  void _close() {
    FocusScope.of(context).unfocus();
    Navigator.pop(context);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      Get.rawSnackbar(message: 'Your name cannot be empty');
      return;
    }
    if (_designation == null) {
      Get.rawSnackbar(message: 'Choose your designation');
      return;
    }

    final saved = await _controller.updateProfile(
      name: name,
      designation: _designation!,
    );
    if (saved && mounted) _close();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lifts the sheet above the keyboard instead of letting it cover the
      // field being typed into.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: _line,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Edit Profile',
                      style: GoogleFonts.openSans(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: _green,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _close,
                    icon: Icon(Icons.close, size: 20.sp, color: _muted),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Close',
                  ),
                ],
              ),
              Divider(height: 1, color: _line),
              SizedBox(height: 16.h),

              _Label('Name'),
              SizedBox(height: 8.h),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                decoration: _decoration(hint: 'Your name'),
                style: GoogleFonts.openSans(fontSize: 16.sp, color: _ink),
              ),

              SizedBox(height: 16.h),
              _Label('Designation'),
              SizedBox(height: 8.h),
              DropdownButtonFormField<String>(
                initialValue: _designation,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFF3A4F42),
                ),
                hint: Text(
                  'Select your role',
                  style: GoogleFonts.openSans(
                    color: const Color(0xFF9AA49A),
                    fontSize: 16.sp,
                  ),
                ),
                items: AuthController.designations
                    .map(
                      (role) => DropdownMenuItem<String>(
                        value: role,
                        child: Text(
                          role,
                          style: GoogleFonts.openSans(
                            fontSize: 16.sp,
                            color: _ink,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _designation = value),
                decoration: _decoration(),
              ),

              SizedBox(height: 22.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: _controller.isSavingProfile.value ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      disabledBackgroundColor: const Color(0xFF86C8A2),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      _controller.isSavingProfile.value
                          ? 'Saving...'
                          : 'Save Changes',
                      style: GoogleFonts.openSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration({String? hint}) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.openSans(
      color: const Color(0xFF9AA49A),
      fontSize: 16.sp,
    ),
    filled: true,
    fillColor: const Color(0xFFF7F8FA),
    contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide(color: _border.withValues(alpha: 0.7)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide(color: _border.withValues(alpha: 0.7)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: const BorderSide(color: _green),
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.openSans(
      fontSize: 13.sp,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF374B41),
    ),
  );
}
