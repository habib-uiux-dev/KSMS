import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'colors.dart';

class CustomLogoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CustomLogoutButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back_ios_new, size: 18.sp, color: AppColors.primaryGreen),
          SizedBox(width: 4.w),
          Text('Back', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600, fontSize: 16.sp)),
        ],
      ),
      onPressed: onPressed,
      padding: EdgeInsets.only(left: 16.w),
      alignment: Alignment.centerLeft,
    );
  }
}
