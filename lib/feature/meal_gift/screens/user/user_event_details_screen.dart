import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../utils/colors.dart';
import '../../utils/custom_back_button.dart';

class UserEventDetailsScreen extends StatelessWidget {
  final BaseEvent event;
  final EventUserStatus status;

  const UserEventDetailsScreen({super.key, required this.event, required this.status});

  @override
  Widget build(BuildContext context) {
    bool isMeal = event.type == EventType.meal;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 100,
        leading: const CustomBackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Review contribution information.', style: TextStyle(color: AppColors.textLight)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: status.isPaid
                    ? [AppColors.primaryGreen, AppColors.darkGreen]
                    : [AppColors.pendingOrange, const Color(0xFFC05621)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (status.isPaid ? AppColors.primaryGreen : AppColors.pendingOrange).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ]
              ),
              child: Column(
                children: [
                  const Text('YOUR SHARE', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('৳${event.perPersonShare.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20)
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(status.isPaid ? Icons.check_circle : Icons.pending, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(status.isPaid ? 'Paid' : 'Payment Pending', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Event Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200)
              ),
              child: Column(
                children: [
                  if (isMeal) ..._buildMealDetails() else ..._buildGiftDetails(),
                  const Divider(height: 1),
                  _infoRow(Icons.person, 'Paid By', event.paidBy),
                  const Divider(height: 1),
                  _infoRow(Icons.account_balance_wallet, 'Total ${isMeal ? "Bill Amount" : "Gift Price"}', '৳${event.totalAmount}'),
                  const Divider(height: 1),
                  _infoRow(Icons.group, 'Total Contributors', '${event.userStatuses.length} Employees'),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMealDetails() {
    MealEvent meal = event as MealEvent;
    return [
      _infoRow(Icons.restaurant, 'Location', meal.restaurantName),
      const Divider(height: 1),
      _infoRow(Icons.calendar_today, 'Date', DateFormat('dd/MM/yyyy').format(meal.date)),
    ];
  }

  List<Widget> _buildGiftDetails() {
    GiftEvent gift = event as GiftEvent;
    return [
      _infoRow(Icons.person_pin, 'Gift For', gift.recipient),
      const Divider(height: 1),
      _infoRow(Icons.card_giftcard, 'Gift Item', gift.itemName),
    ];
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryGreen, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
