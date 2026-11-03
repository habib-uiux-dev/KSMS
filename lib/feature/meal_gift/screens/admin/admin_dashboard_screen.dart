import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';
import '../../utils/colors.dart';
import '../../utils/custom_logout_button.dart';
import '../login_screen.dart';
import 'create_event_screen.dart';
import 'admin_history_screen.dart';
import 'edit_event_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  void _showDeleteConfirmDialog(BuildContext context, String eventId, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Event', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this event?', style: TextStyle(fontSize: 14.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textDark, fontSize: 14.sp)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h)
            ),
            onPressed: () {
              appState.deleteEvent(eventId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Event deleted successfully', style: TextStyle(fontSize: 14.sp))),
              );
            },
            child: Text('Delete', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final events = appState.events.reversed.toList();

    // Calculate total pending amounts across all events
    double totalPendingOverall = 0;
    for (var event in events) {
      int pendingCount = event.userStatuses.where((s) => !s.isPaid).length;
      totalPendingOverall += pendingCount * event.perPersonShare;
    }

    // Get all users who are part of at least one event
    List<User> activeUsers = appState.allUsers.where((u) {
      return events.any((e) => e.userStatuses.any((s) => s.userId == u.id));
    }).toList();

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
        actions: [
          IconButton(
            icon: Icon(Icons.history, size: 24.sp),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminHistoryScreen()));
            },
          ),
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: IconButton(
              icon: Icon(Icons.add_circle, color: AppColors.primaryGreen, size: 28.sp),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEventScreen()));
              },
            ),
          )
        ],
      ),
      body: events.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note, size: 64.sp, color: Colors.grey.shade300),
                  SizedBox(height: 16.h),
                  Text("No events created yet.", style: TextStyle(color: Colors.grey.shade500, fontSize: 16.sp)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (totalPendingOverall > 0)
                    Container(
                      margin: EdgeInsets.only(bottom: 16.h),
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.pendingBg,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColors.pendingOrange.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.pendingOrange.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: AppColors.pendingOrange.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.account_balance_wallet, color: AppColors.pendingOrange, size: 24.sp),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Outstanding Amount', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 13.sp)),
                                SizedBox(height: 2.h),
                                Text('৳${totalPendingOverall.toStringAsFixed(2)}', style: TextStyle(color: AppColors.pendingOrange, fontSize: 22.sp, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Render Event Cards
                  ...events.map((e) => _buildEventCard(context, e, appState)),

                  // Consolidated Collection Status
                  if (activeUsers.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    Text('Collection Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: AppColors.textDark)),
                    SizedBox(height: 16.h),
                    ...activeUsers.map((u) => _buildConsolidatedUserCard(appState, u, events)),
                  ]
                ],
              ),
            ),
    );
  }

  Widget _buildEventCard(BuildContext context, BaseEvent event, AppState appState) {
    String title = event.type == EventType.meal
        ? (event as MealEvent).restaurantName
        : "Gift for ${(event as GiftEvent).recipient}";
    String subtitle = DateFormat('MMM dd, yyyy').format(event.date);

    int paidCount = event.userStatuses.where((s) => s.isPaid).length;
    int totalCount = event.userStatuses.length;

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: event.type == EventType.meal ? AppColors.lightGreen : AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    event.type == EventType.meal ? Icons.restaurant : Icons.card_giftcard,
                    color: event.type == EventType.meal ? AppColors.primaryGreen : AppColors.primaryBlue,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      SizedBox(height: 4.h),
                      Text(subtitle, style: TextStyle(color: AppColors.textLight, fontSize: 13.sp)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppColors.textLight, size: 22.sp),
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => EditEventScreen(event: event)));
                    } else if (value == 'delete') {
                      _showDeleteConfirmDialog(context, event.id, appState);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18.sp, color: AppColors.primaryGreen),
                          SizedBox(width: 8.w),
                          Text('Edit', style: TextStyle(fontSize: 14.sp)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18.sp, color: Colors.red),
                          SizedBox(width: 8.w),
                          Text('Delete', style: TextStyle(fontSize: 14.sp, color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12.h),
            // Show who paid the bill
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, size: 16.sp, color: AppColors.textLight),
                  SizedBox(width: 8.w),
                  Text('Paid by: ', style: TextStyle(color: AppColors.textLight, fontSize: 13.sp)),
                  Text(event.paidBy, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 13.sp)),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                _infoBox('Total Bill', '৳${event.totalAmount.toStringAsFixed(2)}', icon: Icons.receipt_long),
                SizedBox(width: 12.w),
                _infoBox('Per Person', '৳${event.perPersonShare.toStringAsFixed(2)}', icon: Icons.person),
              ],
            ),
            SizedBox(height: 12.h),

            _buildStatusProgressBox(paidCount, totalCount, event.totalAmount, event.perPersonShare),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusProgressBox(int paidCount, int totalCount, double totalAmount, double perPersonShare) {
    bool isAllPaid = paidCount == totalCount;
    double collectedAmount = paidCount * perPersonShare;
    double pendingAmount = (totalCount - paidCount) * perPersonShare;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isAllPaid ? AppColors.lightGreen : AppColors.pendingBg.withValues(alpha: 0.5),
        border: Border.all(color: isAllPaid ? AppColors.primaryGreen.withValues(alpha: 0.3) : AppColors.pendingOrange.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAllPaid ? 'Fully Collected' : 'Collection Progress',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: isAllPaid ? AppColors.primaryGreen : AppColors.pendingOrange
                )
              ),
              Text(
                '$paidCount/$totalCount Paid',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.textDark)
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: totalCount == 0 ? 0 : paidCount / totalCount,
              backgroundColor: Colors.white,
              color: isAllPaid ? AppColors.primaryGreen : AppColors.pendingOrange,
              minHeight: 8.h,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Collected', style: TextStyle(fontSize: 11.sp, color: AppColors.textLight)),
                  SizedBox(height: 2.h),
                  Text('৳${collectedAmount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen, fontSize: 14.sp)),
                ],
              ),
              if (!isAllPaid)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Pending', style: TextStyle(fontSize: 11.sp, color: AppColors.textLight)),
                    SizedBox(height: 2.h),
                    Text('৳${pendingAmount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.pendingOrange, fontSize: 14.sp)),
                  ],
                ),
            ],
          )
        ],
      ),
    );
  }

  Widget _infoBox(String title, String value, {Color color = AppColors.textDark, Color? bgColor, IconData? icon}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: bgColor ?? Colors.white,
          border: bgColor == null ? Border.all(color: Colors.grey.shade200) : null,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14.sp, color: AppColors.textLight),
                  SizedBox(width: 4.w),
                ],
                Text(title, style: TextStyle(fontSize: 12.sp, color: bgColor == null ? AppColors.textLight : color.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
              ],
            ),
            SizedBox(height: 6.h),
            Text(value, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildConsolidatedUserCard(AppState appState, User user, List<BaseEvent> allEvents) {
    double totalPending = 0;
    double totalAmount = 0;

    for (var event in allEvents) {
      var statusIdx = event.userStatuses.indexWhere((s) => s.userId == user.id);
      if (statusIdx != -1) {
        totalAmount += event.perPersonShare;
        if (!event.userStatuses[statusIdx].isPaid) {
          totalPending += event.perPersonShare;
        }
      }
    }

    if (totalAmount == 0) return const SizedBox.shrink();

    bool isAllPaid = totalPending <= 0;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
                radius: 20.r,
                child: Text(user.name.substring(0, 1).toUpperCase(), style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16.sp)),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp, color: AppColors.textDark)),
                    Text(user.role, style: TextStyle(fontSize: 12.sp, color: AppColors.textLight)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isAllPaid ? AppColors.lightGreen : AppColors.pendingBg,
                      borderRadius: BorderRadius.circular(20.r)
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isAllPaid ? Icons.check_circle : Icons.timer, size: 12.sp, color: isAllPaid ? AppColors.primaryGreen : AppColors.pendingOrange),
                        SizedBox(width: 4.w),
                        Text(isAllPaid ? 'Complete' : 'Pending', style: TextStyle(color: isAllPaid ? AppColors.primaryGreen : AppColors.pendingOrange, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '৳${(isAllPaid ? totalAmount : totalPending).toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 16.sp),
                  ),
                ],
              )
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                appState.toggleAllPaidStatusForUser(user.id, !isAllPaid);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isAllPaid ? Colors.grey.shade200 : AppColors.primaryGreen,
                foregroundColor: isAllPaid ? Colors.grey.shade700 : Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              child: Text(
                isAllPaid ? 'Mark as Unpaid' : 'Mark as Paid',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
              ),
            ),
          )
        ],
      ),
    );
  }
}
