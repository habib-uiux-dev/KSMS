import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/colors.dart';
import '../../utils/custom_back_button.dart';
import 'create_meal_view.dart';
import 'create_gift_view.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  bool isMeal = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        centerTitle: true,
        leadingWidth: 110.w,
        leading: const CustomBackButton(label: 'Back'),
        title: Text(
          'Create Entry',
          style: GoogleFonts.openSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE8ECE9)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => isMeal = true),
                      borderRadius: BorderRadius.circular(12.r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: isMeal ? AppColors.primaryGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 18.sp,
                              color: isMeal ? Colors.white : AppColors.textLight,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'Create Meal',
                              style: GoogleFonts.openSans(
                                color: isMeal ? Colors.white : AppColors.textLight,
                                fontWeight: isMeal ? FontWeight.w700 : FontWeight.w600,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => isMeal = false),
                      borderRadius: BorderRadius.circular(12.r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: !isMeal ? AppColors.primaryGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.card_giftcard,
                              size: 18.sp,
                              color: !isMeal ? Colors.white : AppColors.textLight,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'Create Gift',
                              style: GoogleFonts.openSans(
                                color: !isMeal ? Colors.white : AppColors.textLight,
                                fontWeight: !isMeal ? FontWeight.w700 : FontWeight.w600,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isMeal ? const CreateMealView() : const CreateGiftView(),
            ),
          ),
        ],
      ),
    );
  }
}
