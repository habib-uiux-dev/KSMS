import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../utils/colors.dart';

class CreateMealView extends StatefulWidget {
  const CreateMealView({super.key});

  @override
  State<CreateMealView> createState() => _CreateMealViewState();
}

class _CreateMealViewState extends State<CreateMealView> {
  final _restaurantController = TextEditingController();
  final _paidByController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  final _expenseNameController = TextEditingController();
  final _expenseAmountController = TextEditingController();

  final Set<String> _selectedUserIds = {};

  @override
  void dispose() {
    _restaurantController.dispose();
    _paidByController.dispose();
    _expenseNameController.dispose();
    _expenseAmountController.dispose();
    super.dispose();
  }

  void _saveMeal() {
    if (_restaurantController.text.isEmpty ||
        _expenseNameController.text.isEmpty ||
        _expenseAmountController.text.isEmpty ||
        _paidByController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill all fields',
            style: GoogleFonts.openSans(fontSize: 14.sp),
          ),
        ),
      );
      return;
    }
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select at least one user',
            style: GoogleFonts.openSans(fontSize: 14.sp),
          ),
        ),
      );
      return;
    }

    double amount = double.tryParse(_expenseAmountController.text) ?? 0.0;
    final appState = Provider.of<AppState>(context, listen: false);

    appState.addMealEvent(
      _restaurantController.text,
      _selectedDate,
      _paidByController.text,
      [ExpenseItem(description: _expenseNameController.text, amount: amount)],
      _selectedUserIds.toList(),
    );
    Navigator.pop(context);
  }

  void _confirmDeleteUser(BuildContext context, AppState appState, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Permanently Remove User',
          style: GoogleFonts.openSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to permanently remove "${user.name}" from the user list?',
          style: GoogleFonts.openSans(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.openSans(
                color: AppColors.textDark,
                fontSize: 14.sp,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              appState.deleteUser(user.id);
              setState(() {
                _selectedUserIds.remove(user.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${user.name} permanently removed',
                    style: GoogleFonts.openSans(fontSize: 14.sp),
                  ),
                ),
              );
            },
            child: Text(
              'Remove',
              style: GoogleFonts.openSans(
                color: Colors.white,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.openSans(
        color: AppColors.textLight,
        fontSize: 13.sp,
      ),
      prefixIcon: Icon(icon, size: 20.sp, color: AppColors.primaryGreen),
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
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final allUsers = appState.allUsers;
    final allUserIds = allUsers.map((e) => e.id).toSet();
    final bool isAllSelected =
        allUserIds.isNotEmpty && _selectedUserIds.containsAll(allUserIds);

    double amount = double.tryParse(_expenseAmountController.text) ?? 0.0;
    double perPerson =
        _selectedUserIds.isEmpty ? 0 : amount / _selectedUserIds.length;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ================= CARD 1: MEAL DETAILS =================
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: const Color(0xFFE8ECE9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.restaurant,
                      size: 20.sp,
                      color: AppColors.primaryGreen,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Meal Info',
                      style: GoogleFonts.openSans(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                TextField(
                  controller: _restaurantController,
                  style: GoogleFonts.openSans(
                    fontSize: 14.sp,
                    color: AppColors.textDark,
                  ),
                  decoration: _inputDecoration(
                    label: 'Where (Restaurant name)',
                    icon: Icons.storefront_outlined,
                  ),
                ),
                SizedBox(height: 12.h),
                InkWell(
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12.r),
                  child: InputDecorator(
                    decoration: _inputDecoration(
                      label: 'Date',
                      icon: Icons.calendar_month_outlined,
                    ),
                    child: Text(
                      DateFormat('MM/dd/yyyy').format(_selectedDate),
                      style: GoogleFonts.openSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _expenseNameController,
                        style: GoogleFonts.openSans(
                          fontSize: 14.sp,
                          color: AppColors.textDark,
                        ),
                        decoration: _inputDecoration(
                          label: 'Expense Name (e.g. Auto vara)',
                          icon: Icons.receipt_outlined,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _expenseAmountController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.openSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        onChanged: (val) => setState(() {}),
                        decoration: _inputDecoration(
                          label: 'Amount (৳)',
                          icon: Icons.payments_outlined,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: _paidByController,
                  style: GoogleFonts.openSans(
                    fontSize: 14.sp,
                    color: AppColors.textDark,
                  ),
                  decoration: _inputDecoration(
                    label: 'Paid By (e.g. Kaoser)',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // ================= CARD 2: SELECT USERS =================
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: const Color(0xFFE8ECE9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 20.sp,
                          color: AppColors.primaryGreen,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Select Users',
                          style: GoogleFonts.openSans(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    if (allUsers.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            if (isAllSelected) {
                              _selectedUserIds.clear();
                            } else {
                              _selectedUserIds.addAll(allUserIds);
                            }
                          });
                        },
                        icon: Icon(
                          isAllSelected
                              ? Icons.deselect_outlined
                              : Icons.select_all_outlined,
                          size: 16.sp,
                          color: AppColors.primaryGreen,
                        ),
                        label: Text(
                          isAllSelected ? 'Deselect All' : 'Select All',
                          style: GoogleFonts.openSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 10.h),
                if (allUsers.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Text(
                      'No users registered yet. Add a user below:',
                      style: GoogleFonts.openSans(
                        color: AppColors.textLight,
                        fontSize: 13.sp,
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: allUsers.map((user) {
                      bool isSelected = _selectedUserIds.contains(user.id);
                      return GestureDetector(
                        onLongPress: () =>
                            _confirmDeleteUser(context, appState, user),
                        child: FilterChip(
                          label: Text(
                            user.name,
                            style: GoogleFonts.openSans(
                              fontSize: 13.sp,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primaryGreen
                                  : AppColors.textDark,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedUserIds.add(user.id);
                              } else {
                                _selectedUserIds.remove(user.id);
                              }
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primaryGreen
                                : const Color(0xFFE8ECE9),
                          ),
                          selectedColor: AppColors.lightGreen,
                          checkmarkColor: AppColors.primaryGreen,
                          backgroundColor: const Color(0xFFF7F8FA),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // ================= CARD 3: PER PERSON CALCULATION =================
          Container(
            padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEFF6EE), Color(0xFFE2F0E0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'PER PERSON CALCULATION',
                  style: GoogleFonts.openSans(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.sp,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  '৳${perPerson.toStringAsFixed(2)}',
                  style: GoogleFonts.openSans(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryGreen,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _selectedUserIds.isEmpty
                      ? 'No users selected'
                      : 'Split across ${_selectedUserIds.length} person(s)',
                  style: GoogleFonts.openSans(
                    fontSize: 12.sp,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // ================= SAVE BUTTON =================
          SizedBox(
            height: 52.h,
            child: ElevatedButton.icon(
              onPressed: _saveMeal,
              icon: Icon(
                Icons.check_circle_outline,
                size: 20.sp,
                color: Colors.white,
              ),
              label: Text(
                'Save Meal',
                style: GoogleFonts.openSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
