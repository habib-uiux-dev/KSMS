import 'package:cloud_firestore/cloud_firestore.dart';

import 'product.dart';

/// A line in an order.
///
/// Name and price are copied in rather than referenced, so an order stays
/// readable after the catalogue is edited or the product is deleted. That is
/// deliberate duplication: an old receipt must not change when the shop
/// raises a price.
class OrderItem {
  final String productId;
  final String name;
  final String subtitle;
  final int price;
  final int quantity;

  const OrderItem({
    required this.productId,
    required this.name,
    this.subtitle = '',
    required this.price,
    required this.quantity,
  });

  int get lineTotal => price * quantity;

  factory OrderItem.fromProduct(Product product, int quantity) => OrderItem(
    productId: product.id,
    name: product.name,
    subtitle: product.subtitle,
    price: product.price,
    quantity: quantity,
  );

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
    productId: (map['product_id'] as String?) ?? '',
    name: (map['name'] as String?) ?? '',
    subtitle: (map['subtitle'] as String?) ?? '',
    price: (map['price'] as num?)?.toInt() ?? 0,
    quantity: (map['quantity'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'product_id': productId,
    'name': name,
    'subtitle': subtitle,
    'price': price,
    'quantity': quantity,
    'line_total': lineTotal,
  };
}

/// Lifecycle of an order. Stored as the enum name, so renaming a value here
/// would orphan existing documents – add, don't rename.
enum OrderStatus { placed, preparing, delivered, cancelled }

OrderStatus _statusFrom(String? raw) => OrderStatus.values.firstWhere(
  (s) => s.name == raw,
  orElse: () => OrderStatus.placed,
);

/// Whether the cash has been handed over. Kept separate from [OrderStatus]
/// because an order can be delivered and still unpaid - which is exactly what
/// the collection screen exists to track.
enum PaymentStatus { pending, collected }

PaymentStatus _paymentFrom(String? raw) => PaymentStatus.values.firstWhere(
  (s) => s.name == raw,
  orElse: () => PaymentStatus.pending,
);

/// A document in `orders/{id}`.
class ShopOrder {
  final String id;
  final String userId;
  final String userName;
  final String userDesignation;
  final List<OrderItem> items;
  final int itemCount;
  final int total;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final DateTime? createdAt;
  final DateTime? collectedAt;

  const ShopOrder({
    this.id = '',
    required this.userId,
    this.userName = '',
    this.userDesignation = '',
    this.items = const [],
    this.itemCount = 0,
    this.total = 0,
    this.status = OrderStatus.placed,
    this.paymentStatus = PaymentStatus.pending,
    this.createdAt,
    this.collectedAt,
  });

  bool get isCollected => paymentStatus == PaymentStatus.collected;

  factory ShopOrder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? const <String, dynamic>{};
    return ShopOrder(
      id: doc.id,
      userId: (map['user_id'] as String?) ?? '',
      userName: (map['user_name'] as String?) ?? '',
      userDesignation: (map['user_designation'] as String?) ?? '',
      items:
          (map['items'] as List?)
              ?.map(
                (e) => OrderItem.fromMap(Map<String, dynamic>.from(e as Map)),
              )
              .toList() ??
          const [],
      itemCount: (map['item_count'] as num?)?.toInt() ?? 0,
      total: (map['total'] as num?)?.toInt() ?? 0,
      status: _statusFrom(map['status'] as String?),
      paymentStatus: _paymentFrom(map['payment_status'] as String?),
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
      collectedAt: (map['collected_at'] as Timestamp?)?.toDate(),
    );
  }

  /// The write payload. `created_at` is a server timestamp so a phone with a
  /// wrong clock cannot reorder the queue.
  Map<String, dynamic> toCreateMap() => {
    'user_id': userId,
    'user_name': userName,
    'user_designation': userDesignation,
    'items': items.map((e) => e.toMap()).toList(),
    'item_count': itemCount,
    'total': total,
    'status': status.name,
    'payment_status': paymentStatus.name,
    'created_at': FieldValue.serverTimestamp(),
  };
}
