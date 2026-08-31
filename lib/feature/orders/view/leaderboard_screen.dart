import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controller/orders_controller.dart';

const Color _green = Color(0xFF16A34A);
const Color _ink = Color(0xFF23332B);
const Color _muted = Color(0xFF6E7A74);
const Color _line = Color(0xFFE8ECE9);

/// Medal colours for the top three. Everyone below gets a plain number.
const List<Color> _podium = [
  Color(0xFFE0A800),
  Color(0xFF9AA49A),
  Color(0xFFB45309),
];

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrdersController>();

    return Column(
      children: [
        SizedBox(height: 8.h),
        _RangeTabs(controller: controller),
        SizedBox(height: 12.h),
        _TotalBanner(controller: controller),
        SizedBox(height: 12.h),
        Expanded(child: _Board(controller: controller)),
      ],
    );
  }
}

class _RangeTabs extends StatelessWidget {
  const _RangeTabs({required this.controller});

  final OrdersController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.range.value;

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: LeaderboardRange.values.map((range) {
            final isSelected = range == selected;
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8.r),
                onTap: () => controller.selectRange(range),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 9.h),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? _green : Colors.transparent,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    range.label,
                    style: GoogleFonts.openSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : _muted,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }
}

class _TotalBanner extends StatelessWidget {
  const _TotalBanner({required this.controller});

  final OrdersController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: _green,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Items ${controller.range.value.label}',
                    style: GoogleFonts.openSans(
                      fontSize: 13.sp,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${controller.totalItems}',
                    style: GoogleFonts.openSans(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 44.w,
              height: 44.w,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant,
                color: Colors.white,
                size: 22.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.controller});

  final OrdersController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingBoard.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final error = controller.boardError.value;
      if (error != null) {
        return _Message(icon: Icons.cloud_off_outlined, text: error);
      }

      final entries = controller.entries;
      if (entries.isEmpty) {
        return _Message(
          icon: Icons.leaderboard_outlined,
          text: 'Nothing ordered ${controller.range.value.label.toLowerCase()}',
        );
      }

      return Container(
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: ListView.separated(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          itemCount: entries.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            indent: 16.w,
            endIndent: 16.w,
            color: _line,
          ),
          itemBuilder: (context, index) =>
              _Row(rank: index + 1, entry: entries[index]),
        ),
      );
    });
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.rank, required this.entry});

  final int rank;
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final medal = rank <= _podium.length ? _podium[rank - 1] : null;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          SizedBox(
            width: 22.w,
            child: Text(
              '$rank',
              style: GoogleFonts.openSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: medal ?? _muted,
              ),
            ),
          ),
          SizedBox(width: 8.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.openSans(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                if (entry.designation.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    entry.designation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.openSans(
                      fontSize: 12.sp,
                      color: _muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.items} Items',
                style: GoogleFonts.openSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: _green,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                '৳${entry.spent}',
                style: GoogleFonts.openSans(
                  fontSize: 12.sp,
                  color: const Color(0xFFB45309),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44.sp, color: _muted),
          SizedBox(height: 10.h),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(fontSize: 14.sp, color: _muted),
          ),
        ],
      ),
    );
  }
}
