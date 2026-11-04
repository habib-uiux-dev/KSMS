import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/show_custom_toast.dart';
import '../../meal_gift/utils/colors.dart';
import '../../meal_gift/utils/custom_back_button.dart';
import '../controller/accounts_controller.dart';
import '../model/account_entry.dart';

class AccountsHistoryScreen extends GetView<AccountsController> {
  const AccountsHistoryScreen({super.key});

  InputDecoration _dialogInputDecoration({
    required String label,
    required IconData icon,
    required Color activeColor,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.openSans(
        color: AppColors.textLight,
        fontSize: 13.sp,
      ),
      prefixIcon: Icon(icon, size: 20.sp, color: activeColor),
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFFE8ECE9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: activeColor, width: 1.5),
      ),
    );
  }

  void _showEditDialog(BuildContext context, AccountEntry entry) {
    final bool isJorimana = entry.type == AccountEntryType.jorimana;
    final nameController = TextEditingController(text: entry.name);
    final amountController =
        TextEditingController(text: entry.amount.toString());
    DateTime selectedDate = entry.date;
    final activeColor = isJorimana ? AppColors.primaryGreen : Colors.red;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: isJorimana
                          ? const Color(0xFFEFF6EE)
                          : const Color(0xFFFFEBEE),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isJorimana ? Icons.gavel : Icons.receipt_long,
                      size: 28.sp,
                      color: activeColor,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    isJorimana ? 'Edit Jorimana' : 'Edit Expense',
                    style: GoogleFonts.openSans(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Update transaction details below',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.openSans(
                      fontSize: 12.sp,
                      color: AppColors.textLight,
                    ),
                  ),
                  SizedBox(height: 18.h),
                  TextField(
                    controller: nameController,
                    style: GoogleFonts.openSans(fontSize: 14.sp),
                    decoration: _dialogInputDecoration(
                      label: isJorimana ? 'User Name' : 'Spent By / Reason',
                      icon: isJorimana
                          ? Icons.person_outline
                          : Icons.edit_note_outlined,
                      activeColor: activeColor,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.openSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: _dialogInputDecoration(
                      label: 'Amount (৳)',
                      icon: Icons.payments_outlined,
                      activeColor: activeColor,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(12.r),
                    child: InputDecorator(
                      decoration: _dialogInputDecoration(
                        label: 'Date',
                        icon: Icons.calendar_month_outlined,
                        activeColor: activeColor,
                      ),
                      child: Text(
                        DateFormat('MM/dd/yyyy').format(selectedDate),
                        style: GoogleFonts.openSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            side: const BorderSide(color: Color(0xFFE8ECE9)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.openSans(
                              color: AppColors.textLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final name = nameController.text.trim();
                            final amt =
                                double.tryParse(amountController.text.trim()) ??
                                    0;

                            if (name.isEmpty || amt <= 0) {
                              showCustomToast('Please enter valid name and amount');
                              return;
                            }

                            Navigator.pop(context);
                            await controller.updateEntry(
                              id: entry.id,
                              type: entry.type,
                              name: name,
                              amount: amt,
                              date: selectedDate,
                            );
                            showCustomToast('Transaction updated successfully!');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: activeColor,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          child: Text(
                            'Update',
                            style: GoogleFonts.openSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AccountEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Transaction', style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this entry for "${entry.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.openSans(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await controller.deleteEntry(entry.id);
              showCustomToast('Entry deleted successfully');
            },
            child: Text('Delete', style: GoogleFonts.openSans(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          leadingWidth: 120.w,
          leading: const CustomBackButton(label: 'History'),
          bottom: TabBar(
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: AppColors.textLight,
            indicatorColor: AppColors.primaryGreen,
            indicatorWeight: 3.h,
            labelStyle: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 14.sp),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Jorimana'),
              Tab(text: 'Expense'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _EntryList(
              filter: (e) => true,
              onEdit: (e) => _showEditDialog(context, e),
              onDelete: (e) => _confirmDelete(context, e),
            ),
            _EntryList(
              filter: (e) => e.type == AccountEntryType.jorimana,
              onEdit: (e) => _showEditDialog(context, e),
              onDelete: (e) => _confirmDelete(context, e),
            ),
            _EntryList(
              filter: (e) => e.type == AccountEntryType.expense,
              onEdit: (e) => _showEditDialog(context, e),
              onDelete: (e) => _confirmDelete(context, e),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryList extends StatelessWidget {
  const _EntryList({
    required this.filter,
    required this.onEdit,
    required this.onDelete,
  });

  final bool Function(AccountEntry) filter;
  final Function(AccountEntry) onEdit;
  final Function(AccountEntry) onDelete;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AccountsController>();

    return Obx(() {
      final list = controller.entries.where(filter).toList();

      if (list.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_outlined, size: 48.sp, color: Colors.grey.shade400),
                SizedBox(height: 12.h),
                Text(
                  'No transactions found in history',
                  style: GoogleFonts.openSans(color: Colors.grey, fontSize: 14.sp),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final entry = list[index];
          final bool isJorimana = entry.type == AccountEntryType.jorimana;

          return Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFE8ECE9)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isJorimana ? AppColors.lightGreen : const Color(0xFFFFEBEE),
                  child: Icon(
                    isJorimana ? Icons.gavel : Icons.receipt_long,
                    color: isJorimana ? AppColors.primaryGreen : Colors.red,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: GoogleFonts.openSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${isJorimana ? "Jorimana" : "Expense"} · ${DateFormat('dd/MM/yyyy').format(entry.date)}',
                        style: GoogleFonts.openSans(
                          color: Colors.grey,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  isJorimana
                      ? '+৳${entry.amount.toStringAsFixed(2)}'
                      : '-৳${entry.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.openSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                    color: isJorimana ? AppColors.primaryGreen : Colors.red,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 20.sp, color: Colors.grey),
                  tooltip: 'Edit Entry',
                  onPressed: () => onEdit(entry),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 20.sp, color: Colors.grey),
                  tooltip: 'Delete Entry',
                  onPressed: () => onDelete(entry),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}
