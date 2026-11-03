import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'colors.dart';

class CustomBackButton extends StatelessWidget {
  const CustomBackButton({
    super.key,
    this.label = 'Back',
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back_ios_new, size: 18.sp, color: AppColors.primaryGreen),
          SizedBox(width: 4.w),
          Text(label, style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600, fontSize: 16.sp)),
        ],
      ),
      onPressed: () => Navigator.of(context).pop(),
      padding: EdgeInsets.only(left: 16.w),
      alignment: Alignment.centerLeft,
    );
  }
}
