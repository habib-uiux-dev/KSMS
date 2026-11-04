import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/app_color.dart';
import '../../widgets/show_custom_toast.dart';
import 'app_version_model.dart';

class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  static const String settingsCollection = 'settings';
  static const String appVersionDoc = 'app_version';

  DocumentReference<Map<String, dynamic>> get _versionRef =>
      FirebaseFirestore.instance
          .collection(settingsCollection)
          .doc(appVersionDoc);

  bool _isDialogOpen = false;

  /// Real-time stream of the version configuration from Firestore.
  Stream<AppVersionModel> watchAppVersion() {
    return _versionRef.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return const AppVersionModel(
          minBuildNumber: 0,
          minVersion: '1.0.0',
          latestVersion: '1.0.0',
          updateUrl: '',
          forceUpdate: false,
          title: 'নতুন আপডেট এসেছে!',
          message:
              'KSMS অ্যাপ ব্যবহার চালিয়ে যেতে অনুগ্রহ করে এখনই নতুন ভার্সনে আপডেট করুন।',
        );
      }
      return AppVersionModel.fromMap(snapshot.data());
    });
  }

  /// Fetches the version configuration once.
  Future<AppVersionModel?> fetchAppVersion() async {
    try {
      final doc = await _versionRef.get();
      if (!doc.exists || doc.data() == null) return null;
      return AppVersionModel.fromMap(doc.data());
    } catch (e) {
      log('Failed to fetch app version config: $e');
      return null;
    }
  }

  /// Checks if the running app requires a mandatory force update.
  Future<bool> isUpdateRequired(AppVersionModel config) async {
    if (!config.forceUpdate) return false;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
      log('App build number: $currentBuildNumber | Required min build: ${config.minBuildNumber}');
      return currentBuildNumber < config.minBuildNumber;
    } catch (e) {
      log('Failed to read package info: $e');
      return false;
    }
  }

  /// Displays a non-dismissible, blocking force-update dialog.
  void showForceUpdateDialog(AppVersionModel config) {
    if (_isDialogOpen) return;
    _isDialogOpen = true;

    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Header
                Container(
                  width: 76.r,
                  height: 76.r,
                  decoration: BoxDecoration(
                    color: AppColor.primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.system_update_rounded,
                      color: AppColor.primaryColor,
                      size: 42.sp,
                    ),
                  ),
                ),
                SizedBox(height: 18.h),

                // Title
                Text(
                  config.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.openSans(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF14161A),
                  ),
                ),
                SizedBox(height: 6.h),

                // Version Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    'Version ${config.latestVersion}',
                    style: GoogleFonts.openSans(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                SizedBox(height: 14.h),

                // Message
                Text(
                  config.message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.openSans(
                    fontSize: 13.5.sp,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),

                // Optional release notes
                if (config.releaseNotes.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'নতুন কি আছে:',
                          style: GoogleFonts.openSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF14161A),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        ...config.releaseNotes.map(
                          (note) => Padding(
                            padding: EdgeInsets.only(bottom: 2.h),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• ',
                                    style: TextStyle(
                                        color: AppColor.primaryColor,
                                        fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(
                                    note,
                                    style: GoogleFonts.openSans(
                                      fontSize: 11.5.sp,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 22.h),

                // Update Now Button
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: () async {
                      if (config.updateUrl.trim().isEmpty) {
                        showCustomToast(
                            'আপডেট লিংক পাওয়া যায়নি। অনুগ্রহ করে অ্যাডমিনের সাথে যোগাযোগ করুন।');
                        return;
                      }

                      final uri = Uri.tryParse(config.updateUrl.trim());
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      } else {
                        showCustomToast('লিংকটি ওপেন করা সম্ভব হয়নি।');
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download_rounded, size: 20.sp),
                        SizedBox(width: 8.w),
                        Text(
                          'এখনই আপডেট করুন (Update)',
                          style: GoogleFonts.openSans(
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    ).then((_) {
      _isDialogOpen = false;
    });
  }

  /// Admin convenience: saves or updates the app version settings document in Firestore.
  Future<void> updateVersionConfig(AppVersionModel model) async {
    await _versionRef.set(model.toMap(), SetOptions(merge: true));
  }
}
