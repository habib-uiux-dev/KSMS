import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';
import '../../utils/colors.dart';
import '../../utils/custom_back_button.dart';

class EditEventScreen extends StatefulWidget {
  final BaseEvent event;

  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  late DateTime _selectedDate;
  late TextEditingController _paidByController;

  // Meal specific controllers
  late TextEditingController _restaurantController;
  late TextEditingController _expenseNameController;
  late TextEditingController _expenseAmountController;

  // Gift specific controllers
  late TextEditingController _recipientController;
  late TextEditingController _itemNameController;
  late TextEditingController _priceController;

  late Set<String> _selectedUserIds;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.event.date;
    _paidByController = TextEditingController(text: widget.event.paidBy);
    _selectedUserIds = widget.event.userStatuses.map((s) => s.userId).toSet();

    if (widget.event is MealEvent) {
      final meal = widget.event as MealEvent;
      _restaurantController = TextEditingController(text: meal.restaurantName);
      final firstExpense = meal.expenses.isNotEmpty ? meal.expenses.first : ExpenseItem(description: '', amount: 0);
      _expenseNameController = TextEditingController(text: firstExpense.description);
      _expenseAmountController = TextEditingController(text: firstExpense.amount.toString());
      _recipientController = TextEditingController();
      _itemNameController = TextEditingController();
      _priceController = TextEditingController();
    } else {
      final gift = widget.event as GiftEvent;
      _recipientController = TextEditingController(text: gift.recipient);
      _itemNameController = TextEditingController(text: gift.itemName);
      _priceController = TextEditingController(text: gift.price.toString());
      _restaurantController = TextEditingController();
      _expenseNameController = TextEditingController();
      _expenseAmountController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _paidByController.dispose();
    _restaurantController.dispose();
    _expenseNameController.dispose();
    _expenseAmountController.dispose();
    _recipientController.dispose();
    _itemNameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _updateEvent() {
    final appState = Provider.of<AppState>(context, listen: false);

    if (_paidByController.text.trim().isEmpty || _selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields and select users', style: TextStyle(fontSize: 14.sp))),
      );
      return;
    }

    if (widget.event is MealEvent) {
      if (_restaurantController.text.isEmpty || _expenseNameController.text.isEmpty || _expenseAmountController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill all meal details', style: TextStyle(fontSize: 14.sp))),
        );
        return;
      }
      double amount = double.tryParse(_expenseAmountController.text) ?? 0.0;
      appState.updateMealEvent(
        eventId: widget.event.id,
        restaurantName: _restaurantController.text,
        date: _selectedDate,
        paidBy: _paidByController.text,
        expenses: [ExpenseItem(description: _expenseNameController.text, amount: amount)],
        selectedUserIds: _selectedUserIds.toList(),
      );
    } else {
      if (_recipientController.text.isEmpty || _itemNameController.text.isEmpty || _priceController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill all gift details', style: TextStyle(fontSize: 14.sp))),
        );
        return;
      }
      double price = double.tryParse(_priceController.text) ?? 0.0;
      appState.updateGiftEvent(
        eventId: widget.event.id,
        recipient: _recipientController.text,
        itemName: _itemNameController.text,
        price: price,
        date: _selectedDate,
        paidBy: _paidByController.text,
        selectedUserIds: _selectedUserIds.toList(),
      );
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Event updated successfully', style: TextStyle(fontSize: 14.sp))),
    );
  }

  void _confirmDeleteUser(BuildContext context, AppState appState, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permanently Remove User', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to permanently remove "${user.name}" from the user list?', style: TextStyle(fontSize: 14.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textDark, fontSize: 14.sp)),
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
                SnackBar(content: Text('${user.name} permanently removed', style: TextStyle(fontSize: 14.sp))),
              );
            },
            child: Text('Remove', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    bool isMeal = widget.event is MealEvent;

    double amount = 0;
    if (isMeal) {
      amount = double.tryParse(_expenseAmountController.text) ?? 0;
    } else {
      amount = double.tryParse(_priceController.text) ?? 0;
    }
    double perPerson = _selectedUserIds.isEmpty ? 0 : amount / _selectedUserIds.length;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 100.w,
        leading: const CustomBackButton(),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit ${isMeal ? "Meal" : "Gift"} Event', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            SizedBox(height: 16.h),

            if (isMeal) ...[
              TextField(
                controller: _restaurantController,
                decoration: const InputDecoration(
                  labelText: 'Where (Restaurant name)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _expenseNameController,
                      decoration: const InputDecoration(
                        labelText: 'Expense Name (e.g. Auto vara)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _expenseAmountController,
                      keyboardType: TextInputType.number,
                      onChanged: (val) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Amount (৳)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              TextField(
                controller: _recipientController,
                decoration: const InputDecoration(
                  labelText: 'Gift For (e.g., Jane Doe)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: _itemNameController,
                decoration: const InputDecoration(
                  labelText: 'Gift Item (e.g., Premium Watch)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                onChanged: (val) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Gift Price (৳)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            SizedBox(height: 16.h),
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
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                ),
                child: Text(DateFormat('MM/dd/yyyy').format(_selectedDate), style: TextStyle(fontSize: 14.sp)),
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _paidByController,
              decoration: InputDecoration(
                labelText: 'Paid By',
                prefixIcon: Icon(Icons.person, size: 20.sp),
                border: const OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.h),

            () {
              final allUsers = appState.allUsers;
              final allUserIds = allUsers.map((e) => e.id).toSet();
              final bool isAllSelected = allUserIds.isNotEmpty && _selectedUserIds.containsAll(allUserIds);
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select Users', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                  if (allUsers.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (isAllSelected) {
                            _selectedUserIds.clear();
                          } else {
                            _selectedUserIds.addAll(allUserIds);
                          }
                        });
                      },
                      child: Text(isAllSelected ? 'Deselect All' : 'Select All', style: TextStyle(fontSize: 14.sp)),
                    )
                ],
              );
            }(),
            Wrap(
              spacing: 8.w,
              runSpacing: 4.h,
              children: appState.allUsers.map((user) {
                bool isSelected = _selectedUserIds.contains(user.id);
                return GestureDetector(
                  onLongPress: () => _confirmDeleteUser(context, appState, user),
                  child: FilterChip(
                    label: Text(user.name, style: TextStyle(fontSize: 13.sp)),
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
                    selectedColor: AppColors.lightGreen,
                    checkmarkColor: AppColors.primaryGreen,
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 32.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(8.r)
              ),
              child: Column(
                children: [
                  Text('PER PERSON CALCULATION', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12.sp)),
                  SizedBox(height: 8.h),
                  Text('৳${perPerson.toStringAsFixed(2)}', style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _updateEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Update Event',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
