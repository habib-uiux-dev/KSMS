import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';
import '../../utils/colors.dart';
import '../../utils/custom_back_button.dart';
import 'edit_event_screen.dart';

class AdminHistoryScreen extends StatelessWidget {
  const AdminHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: 120.w,
          leading: const CustomBackButton(label: 'History'),
          bottom: TabBar(
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: AppColors.textLight,
            indicatorColor: AppColors.primaryGreen,
            indicatorWeight: 3.h,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
            tabs: const [
              Tab(text: 'Meal'),
              Tab(text: 'Gift'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _HistoryList(eventType: EventType.meal),
            _HistoryList(eventType: EventType.gift),
          ],
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final EventType eventType;

  const _HistoryList({required this.eventType});

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

    final events = appState.events
        .where((e) => e.type == eventType)
        .toList()
        .reversed
        .toList();

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64.sp, color: Colors.grey.shade300),
            SizedBox(height: 16.h),
            Text('Empty history', style: TextStyle(color: Colors.grey.shade500, fontSize: 16.sp)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        bool isMeal = event.type == EventType.meal;
        String title = isMeal ? (event as MealEvent).restaurantName : "Gift for ${(event as GiftEvent).recipient}";

        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: isMeal ? AppColors.lightGreen : AppColors.lightBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMeal ? Icons.restaurant : Icons.card_giftcard,
                  color: isMeal ? AppColors.primaryGreen : AppColors.primaryBlue,
                  size: 20.sp,
                ),
              ),
              title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 16.sp)),
              subtitle: Text(DateFormat('MMM dd, yyyy').format(event.date), style: TextStyle(fontSize: 12.sp)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('৳${event.totalAmount}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen, fontSize: 15.sp)),
                  SizedBox(width: 4.w),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 18.sp, color: AppColors.textLight),
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
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      SizedBox(height: 8.h),
                      if (isMeal) ...[
                        Text('Expenses Breakdown', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight, fontSize: 12.sp)),
                        SizedBox(height: 8.h),
                        ...(event as MealEvent).expenses.map((e) => Padding(
                          padding: EdgeInsets.only(bottom: 4.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.description, style: TextStyle(color: AppColors.textDark, fontSize: 14.sp)),
                              Text('৳${e.amount}', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.sp)),
                            ],
                          ),
                        )),
                        SizedBox(height: 16.h),
                      ],
                      if (!isMeal) ...[
                        Text('Item Detail', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight, fontSize: 12.sp)),
                        SizedBox(height: 4.h),
                        Text((event as GiftEvent).itemName, style: TextStyle(color: AppColors.textDark, fontSize: 14.sp)),
                        SizedBox(height: 16.h),
                      ],
                      Text('Contributors (${event.userStatuses.length})', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight, fontSize: 12.sp)),
                      SizedBox(height: 8.h),
                      ...event.userStatuses.map((s) {
                        final user = appState.allUsers.cast<User?>().firstWhere(
                          (u) => u?.id == s.userId,
                          orElse: () => null,
                        );
                        return Padding(
                          padding: EdgeInsets.only(bottom: 6.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(user?.name ?? 'Member', style: TextStyle(color: AppColors.textDark, fontSize: 14.sp)),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: s.isPaid ? AppColors.lightGreen : AppColors.pendingBg,
                                  borderRadius: BorderRadius.circular(4.r)
                                ),
                                child: Text(s.isPaid ? 'Paid' : 'Pending', style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  color: s.isPaid ? AppColors.primaryGreen : AppColors.pendingOrange
                                )),
                              )
                            ],
                          ),
                        );
                      })
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
