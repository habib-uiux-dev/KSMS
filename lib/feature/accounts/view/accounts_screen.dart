import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/routes/app_pages.dart';
import '../../../core/widgets/show_custom_toast.dart';
import '../../meal_gift/utils/colors.dart';
import '../../meal_gift/utils/custom_back_button.dart';
import '../controller/accounts_controller.dart';
import '../model/account_entry.dart';

class AccountsScreen extends GetView<AccountsController> {
  const AccountsScreen({super.key});

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

  void _showAddJorimanaDialog(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();

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
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6EE),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.gavel,
                      size: 28.sp,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Add Jorimana (Fine)',
                    style: GoogleFonts.openSans(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Enter fine details to add to accounts balance',
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
                      label: 'User Name (e.g. Kaoser)',
                      icon: Icons.person_outline,
                      activeColor: AppColors.primaryGreen,
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
                      activeColor: AppColors.primaryGreen,
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
                        activeColor: AppColors.primaryGreen,
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
                              showCustomToast(
                                  'Please enter valid name and amount');
                              return;
                            }

                            Navigator.pop(context);
                            try {
                              await controller.addJorimana(
                                name: name,
                                amount: amt,
                                date: selectedDate,
                              );
                              showCustomToast('Jorimana added successfully!');
                            } catch (e) {
                              showCustomToast('Failed to save Jorimana: $e');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          child: Text(
                            'Save',
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

  void _showAddExpenseDialog(BuildContext context) {
    final spentByController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();

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
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFEBEE),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      size: 28.sp,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Add Expense',
                    style: GoogleFonts.openSans(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Enter expense details to deduct from accounts balance',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.openSans(
                      fontSize: 12.sp,
                      color: AppColors.textLight,
                    ),
                  ),
                  SizedBox(height: 18.h),
                  TextField(
                    controller: spentByController,
                    style: GoogleFonts.openSans(fontSize: 14.sp),
                    decoration: _dialogInputDecoration(
                      label: 'Spent By / Reason (e.g. Tea & Snacks)',
                      icon: Icons.edit_note_outlined,
                      activeColor: Colors.red,
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
                      activeColor: Colors.red,
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
                        activeColor: Colors.red,
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
                            final spentBy = spentByController.text.trim();
                            final amt =
                                double.tryParse(amountController.text.trim()) ??
                                    0;

                            if (spentBy.isEmpty || amt <= 0) {
                              showCustomToast(
                                  'Please enter valid reason and amount');
                              return;
                            }

                            Navigator.pop(context);
                            try {
                              await controller.addExpense(
                                spentBy: spentBy,
                                amount: amt,
                                date: selectedDate,
                              );
                              showCustomToast('Expense added successfully!');
                            } catch (e) {
                              showCustomToast('Failed to save Expense: $e');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          child: Text(
                            'Save',
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
                              showCustomToast(
                                  'Please enter valid name and amount');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        centerTitle: true,
        leadingWidth: 100.w,
        leading: const CustomBackButton(label: 'Back'),
        title: Text(
          'Accounts',
          style: GoogleFonts.openSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.history_outlined,
              size: 24.sp,
              color: AppColors.primaryGreen,
            ),
            tooltip: 'Accounts History',
            onPressed: () => Get.toNamed(Routes.accountsHistory),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final netBalance = controller.netBalance;
        final totalJorimana = controller.totalJorimana;
        final totalExpense = controller.totalExpense;
        final recentEntries = controller.entries.take(5).toList();

        final bool isPositive = netBalance > 0;
        final bool isNegative = netBalance < 0;

        final Color balanceColor = isPositive
            ? AppColors.primaryGreen
            : isNegative
                ? Colors.red
                : AppColors.textDark;

        final String balanceStatusText = isPositive
            ? '৳${netBalance.toStringAsFixed(2)} Joma Ache'
            : isNegative
                ? '-৳${netBalance.abs().toStringAsFixed(2)} Minus'
                : '৳0.00 Balance';

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ================= BIG BALANCE DISPLAY CARD =================
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isNegative
                        ? [const Color(0xFFFFEBEE), const Color(0xFFFFCDD2)]
                        : [const Color(0xFFEFF6EE), const Color(0xFFE2F0E0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: isNegative
                        ? Colors.red.withValues(alpha: 0.25)
                        : AppColors.primaryGreen.withValues(alpha: 0.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'TOTAL ACCOUNTS BALANCE',
                      style: GoogleFonts.openSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: balanceColor,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      isNegative
                          ? '-৳${netBalance.abs().toStringAsFixed(2)}'
                          : '৳${netBalance.toStringAsFixed(2)}',
                      style: GoogleFonts.openSans(
                        fontSize: 38.sp,
                        fontWeight: FontWeight.w800,
                        color: balanceColor,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: balanceColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        balanceStatusText,
                        style: GoogleFonts.openSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: balanceColor,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // BREAKDOWN ROW
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: const Color(0xFFE8ECE9),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Total Jorimana',
                                  style: GoogleFonts.openSans(
                                    fontSize: 11.sp,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  '৳${totalJorimana.toStringAsFixed(2)}',
                                  style: GoogleFonts.openSans(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: const Color(0xFFE8ECE9),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Total Expense',
                                  style: GoogleFonts.openSans(
                                    fontSize: 11.sp,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  '৳${totalExpense.toStringAsFixed(2)}',
                                  style: GoogleFonts.openSans(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // ================= RECENT TRANSACTIONS HEADER =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: GoogleFonts.openSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.toNamed(Routes.accountsHistory),
                    child: Text(
                      'View History',
                      style: GoogleFonts.openSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              if (recentEntries.isEmpty)
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFFE8ECE9)),
                  ),
                  child: Center(
                    child: Text(
                      'No transactions yet. Add Jorimana or Expense below.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.openSans(
                        color: Colors.grey,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                )
              else
                ...recentEntries
                    .map((e) => _buildTransactionTile(context, e)),

              SizedBox(height: 20.h),
            ],
          ),
        );
      }),

      // ================= BOTTOM BAR (2 ACTION BUTTONS) =================
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52.h,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddJorimanaDialog(context),
                    icon: Icon(Icons.add, size: 20.sp, color: Colors.white),
                    label: Text(
                      'Add Jorimana',
                      style: GoogleFonts.openSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: SizedBox(
                  height: 52.h,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddExpenseDialog(context),
                    icon: Icon(Icons.remove, size: 20.sp, color: Colors.white),
                    label: Text(
                      'Add Expense',
                      style: GoogleFonts.openSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, AccountEntry entry) {
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
            backgroundColor: isJorimana
                ? AppColors.lightGreen
                : const Color(0xFFFFEBEE),
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
                  DateFormat('MM/dd/yyyy').format(entry.date),
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
            onPressed: () => _showEditDialog(context, entry),
          ),
        ],
      ),
    );
  }
}
