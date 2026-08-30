import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controller/admin_dashboard_controller.dart';
import 'widgets/admin_widgets.dart';

/// What the shop actually has to buy or make today, aggregated across every
/// order so nobody has to add it up by hand.
class AdminSummaryScreen extends StatelessWidget {
  const AdminSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminDashboardController>();

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final summary = controller.summaryByCategory;

      return RefreshIndicator(
        onRefresh: () async => controller.refreshOrders(),
        color: AdminColors.green,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          children: [
            Text(
              "Today's Summary",
              style: GoogleFonts.openSans(
                fontSize: 26.sp,
                fontWeight: FontWeight.w800,
                color: AdminColors.ink,
              ),
            ),

            SizedBox(height: 4.h),

            Text(
              "Aggregated products needed for today's orders.",
              style: GoogleFonts.openSans(color: AdminColors.muted),
            ),

            SizedBox(height: 14.h),

            // ================= TOTALS BANNER =================
            Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: AdminColors.green,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _BannerStat(
                      label: 'Total Items',
                      value: '${controller.totalPieces}',
                    ),
                  ),
                  Expanded(
                    child: _BannerStat(
                      label: 'Total Amount',
                      value: '৳${controller.totalAmount}',
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            if (summary.isEmpty)
              const AdminEmpty(
                message: 'Nothing ordered yet today',
                icon: Icons.summarize_outlined,
              )
            else
              for (final entry in summary.entries)
                _SummaryGroup(title: entry.key, lines: entry.value),
          ],
        ),
      );
    });
  }
}

class _BannerStat extends StatelessWidget {
  const _BannerStat({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GoogleFonts.openSans(color: Colors.white70)),
        SizedBox(height: 4.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: GoogleFonts.openSans(
              fontSize: 28.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryGroup extends StatelessWidget {
  const _SummaryGroup({required this.title, required this.lines});

  final String title;
  final Map<String, int> lines;

  @override
  Widget build(BuildContext context) {
    // Biggest quantity first - that is the number the shop acts on.
    final sorted = lines.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AdminColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.openSans(
              fontSize: 19.sp,
              fontWeight: FontWeight.w800,
              color: AdminColors.ink,
            ),
          ),

          Divider(height: 20.h, color: AdminColors.line),

          for (final line in sorted)
            Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      line.key,
                      style: GoogleFonts.openSans(
                        fontSize: 15.sp,
                        color: AdminColors.ink,
                      ),
                    ),
                  ),
                  Text(
                    '${line.value} pcs',
                    style: GoogleFonts.openSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: AdminColors.green,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
