class User {
  final String id;
  final String name;
  final String role;
  final String? email;
  final String? photoUrl;
  final String? designation;

  User({
    required this.id,
    required this.name,
    required this.role,
    this.email,
    this.photoUrl,
    this.designation,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    if (email != null) 'email': email,
    if (photoUrl != null) 'photoUrl': photoUrl,
    if (designation != null && designation!.isNotEmpty) 'designation': designation,
  };

  factory User.fromJson(Map<String, dynamic> json) {
    final nameVal = (json['name'] as String?)?.trim();
    final displayNameVal = (json['displayName'] as String?)?.trim();
    final emailVal = (json['email'] as String?)?.trim();
    final designationVal = (json['designation'] as String?)?.trim();

    String name = 'User';
    if (nameVal != null && nameVal.isNotEmpty) {
      name = nameVal;
    } else if (displayNameVal != null && displayNameVal.isNotEmpty) {
      name = displayNameVal;
    } else if (emailVal != null && emailVal.isNotEmpty) {
      name = emailVal.split('@').first;
    }

    final idVal = json['id'] ?? json['uid'] ?? '';

    return User(
      id: idVal.toString(),
      name: name,
      role: json['role'] ?? designationVal ?? 'Staff',
      email: emailVal,
      photoUrl: json['photoUrl'] ?? json['photo_url'],
      designation: designationVal,
    );
  }
}

class ExpenseItem {
  final String description;
  final double amount;

  ExpenseItem({required this.description, required this.amount});

  Map<String, dynamic> toJson() => {
    'description': description,
    'amount': amount,
  };

  factory ExpenseItem.fromJson(Map<String, dynamic> json) => ExpenseItem(
    description: json['description'] ?? '',
    amount: (json['amount'] as num).toDouble(),
  );
}

class EventUserStatus {
  final String userId;
  bool isPaid;

  EventUserStatus({required this.userId, this.isPaid = false});

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'isPaid': isPaid,
  };

  factory EventUserStatus.fromJson(Map<String, dynamic> json) => EventUserStatus(
    userId: json['userId'] ?? '',
    isPaid: json['isPaid'] ?? false,
  );
}

enum EventType { meal, gift }

abstract class BaseEvent {
  final String id;
  final EventType type;
  final DateTime date;
  final String paidBy;
  final List<EventUserStatus> userStatuses;

  BaseEvent({
    required this.id,
    required this.type,
    required this.date,
    required this.paidBy,
    required this.userStatuses,
  });

  double get totalAmount;
  double get perPersonShare {
    if (userStatuses.isEmpty) return 0;
    return totalAmount / userStatuses.length;
  }

  Map<String, dynamic> toJson();

  static BaseEvent fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'];
    final userStatuses = (json['userStatuses'] as List? ?? [])
        .map((s) => EventUserStatus.fromJson(s as Map<String, dynamic>))
        .toList();

    if (typeStr == 'meal') {
      final expenses = (json['expenses'] as List? ?? [])
          .map((e) => ExpenseItem.fromJson(e as Map<String, dynamic>))
          .toList();
      return MealEvent(
        id: json['id'] ?? '',
        date: DateTime.parse(json['date']),
        paidBy: json['paidBy'] ?? '',
        userStatuses: userStatuses,
        restaurantName: json['restaurantName'] ?? '',
        expenses: expenses,
      );
    } else {
      return GiftEvent(
        id: json['id'] ?? '',
        date: DateTime.parse(json['date']),
        paidBy: json['paidBy'] ?? '',
        userStatuses: userStatuses,
        recipient: json['recipient'] ?? '',
        itemName: json['itemName'] ?? '',
        price: (json['price'] as num).toDouble(),
      );
    }
  }
}

class GiftEvent extends BaseEvent {
  final String recipient;
  final String itemName;
  final double price;

  GiftEvent({
    required super.id,
    required super.date,
    required super.paidBy,
    required super.userStatuses,
    required this.recipient,
    required this.itemName,
    required this.price,
  }) : super(type: EventType.gift);

  @override
  double get totalAmount => price;

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'gift',
    'date': date.toIso8601String(),
    'paidBy': paidBy,
    'recipient': recipient,
    'itemName': itemName,
    'price': price,
    'userStatuses': userStatuses.map((s) => s.toJson()).toList(),
  };
}

class MealEvent extends BaseEvent {
  final String restaurantName;
  final List<ExpenseItem> expenses;

  MealEvent({
    required super.id,
    required super.date,
    required super.paidBy,
    required super.userStatuses,
    required this.restaurantName,
    required this.expenses,
  }) : super(type: EventType.meal);

  @override
  double get totalAmount => expenses.fold(0, (sum, item) => sum + item.amount);

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'meal',
    'date': date.toIso8601String(),
    'paidBy': paidBy,
    'restaurantName': restaurantName,
    'expenses': expenses.map((e) => e.toJson()).toList(),
    'userStatuses': userStatuses.map((s) => s.toJson()).toList(),
  };
}
