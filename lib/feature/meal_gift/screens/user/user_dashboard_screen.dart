import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';
import '../../utils/colors.dart';
import '../../utils/custom_logout_button.dart';
import '../login_screen.dart';
import 'user_event_details_screen.dart';

class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    var user = appState.currentUser;

    if (user == null) {
      final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        final name = (fbUser.displayName?.isNotEmpty == true)
            ? fbUser.displayName!
            : (fbUser.email?.isNotEmpty == true)
                ? fbUser.email!.split('@').first
                : 'User';
        user = User(
          id: fbUser.uid,
          name: name,
          role: 'Staff',
          email: fbUser.email,
          photoUrl: fbUser.photoURL,
        );
      }
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Meal & Gift Bill'),
        ),
        body: Center(
          child: Text(
            'Please log in to view your bills',
            style: TextStyle(fontSize: 14.sp, color: AppColors.textLight),
          ),
        ),
      );
    }

    final currentUser = user;

    final userEvents = appState.events.where((e) => e.userStatuses.any((s) => s.userId == currentUser.id)).toList().reversed.toList();
    final mealEvents = userEvents.whereType<MealEvent>().toList();
    final giftEvents = userEvents.whereType<GiftEvent>().toList();

    // Calculate total pending amount for this user
    double totalPendingAmount = 0;
    for (var event in userEvents) {
      var status = event.userStatuses.firstWhere((s) => s.userId == currentUser.id);
      if (!status.isPaid) {
        totalPendingAmount += event.perPersonShare;
      }
    }

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 100.w,
        leading: CustomLogoutButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              appState.logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryGreen, AppColors.darkGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30.r,
                    backgroundColor: Colors.white24,
                    backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                    child: user.photoUrl == null ? Icon(Icons.person, size: 36.sp, color: Colors.white) : null,
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back,', style: TextStyle(color: Colors.white70, fontSize: 13.sp)),
                        Text(user.name, style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold)),
                        Text(user.email ?? user.role, style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
                      ],
                    ),
                  )
                ],
              ),
            ),

            // Total Payable Amount Banner
            if (totalPendingAmount > 0)
              Container(
                margin: EdgeInsets.only(bottom: 24.h),
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.pendingBg,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.pendingOrange.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.pendingOrange.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.account_balance_wallet, color: AppColors.pendingOrange, size: 28.sp),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Payable Amount', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 14.sp)),
                          SizedBox(height: 4.h),
                          Text('৳${totalPendingAmount.toStringAsFixed(2)}', style: TextStyle(color: AppColors.pendingOrange, fontSize: 24.sp, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 8.h),
            Text('Upcoming Meals', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            SizedBox(height: 12.h),
            if (mealEvents.isEmpty)
              _buildEmptyState('No upcoming meals.')
            else
              ...mealEvents.map((e) => _buildEventCard(context, e, currentUser)),

            SizedBox(height: 24.h),
            Text('Latest Gifts', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            SizedBox(height: 12.h),
            if (giftEvents.isEmpty)
              _buildEmptyState('No recent gifts.')
            else
              ...giftEvents.map((e) => _buildEventCard(context, e, currentUser)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox, size: 48.sp, color: Colors.grey.shade300),
          SizedBox(height: 12.h),
          Text(message, style: TextStyle(color: Colors.grey.shade500, fontSize: 14.sp)),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, BaseEvent event, User user) {
    bool isMeal = event.type == EventType.meal;
    String title = isMeal ? (event as MealEvent).restaurantName : "Gift for ${(event as GiftEvent).recipient}";
    String subtitle = DateFormat('MMM dd, yyyy').format(event.date);

    var userStatus = event.userStatuses.firstWhere((s) => s.userId == user.id);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: isMeal ? AppColors.lightGreen : AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    isMeal ? Icons.restaurant : Icons.card_giftcard,
                    color: isMeal ? AppColors.primaryGreen : AppColors.primaryBlue,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: AppColors.textDark)),
                      SizedBox(height: 2.h),
                      Text(subtitle, style: TextStyle(color: AppColors.textLight, fontSize: 12.sp)),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: userStatus.isPaid ? AppColors.lightGreen : AppColors.pendingBg,
                    borderRadius: BorderRadius.circular(12.r)
                  ),
                  child: Text(
                    userStatus.isPaid ? 'Approved' : 'Pending',
                    style: TextStyle(
                      color: userStatus.isPaid ? AppColors.primaryGreen : AppColors.pendingOrange,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                )
              ],
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Estimated', style: TextStyle(color: AppColors.textLight, fontSize: 12.sp)),
                    SizedBox(height: 2.h),
                    Text('৳${event.totalAmount}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14.sp)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Attendees', style: TextStyle(color: AppColors.textLight, fontSize: 12.sp)),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(Icons.group, size: 14.sp, color: AppColors.textLight),
                        SizedBox(width: 4.w),
                        Text('${event.userStatuses.length}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14.sp)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: userStatus.isPaid ? AppColors.lightGreen.withValues(alpha: 0.5) : AppColors.pendingBg.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: userStatus.isPaid ? AppColors.lightGreen : AppColors.pendingBg),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Share', style: TextStyle(color: userStatus.isPaid ? AppColors.primaryGreen : AppColors.pendingOrange, fontWeight: FontWeight.bold, fontSize: 14.sp)),
                  Text('৳${event.perPersonShare.toStringAsFixed(2)}', style: TextStyle(color: userStatus.isPaid ? AppColors.primaryGreen : AppColors.pendingOrange, fontWeight: FontWeight.bold, fontSize: 16.sp)),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => UserEventDetailsScreen(event: event, status: userStatus)));
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryGreen),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                child: Text('View Details', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14.sp)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
