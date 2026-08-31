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

  /// Only the quantity ever changes on an existing line: name and price are
  /// what they were when the order was placed, and a later price change must
  /// not rewrite history.
  OrderItem copyWith({int? quantity}) => OrderItem(
    productId: productId,
    name: name,
    subtitle: subtitle,
    price: price,
    quantity: quantity ?? this.quantity,
  );

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
///
/// `cancelled` is what an admin does instead of deleting. A deleted order
/// cannot be shown to the person who placed it, so "your order was cancelled"
/// would have nothing to render - the document has to survive for the message
/// to exist at all.
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

  /// The shop day this order belongs to, as yyyyMMdd (20260830).
  ///
  /// An int, not a string, because the security rule has to recompute it from
  /// the server clock and rules can do arithmetic far more easily than they can
  /// format a date.
  final int orderDate;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? collectedAt;

  /// Who cancelled it, when, and why. Empty on every order that is still live.
  ///
  /// `cancelledBy` is the admin's uid rather than their name: names change, and
  /// this is the only audit trail the shop has.
  final DateTime? cancelledAt;
  final String cancelledBy;
  final String cancelReason;

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
    this.orderDate = 0,
    this.createdAt,
    this.updatedAt,
    this.collectedAt,
    this.cancelledAt,
    this.cancelledBy = '',
    this.cancelReason = '',
  });

  bool get isCollected => paymentStatus == PaymentStatus.collected;

  /// Cancelled orders still exist, still appear in history, and still count
  /// against "one order per day" - but they count for nothing else. Every
  /// total in the app has to skip them.
  bool get isCancelled => status == OrderStatus.cancelled;

  /// yyyyMMdd for a local date. Local, not UTC: the shop's day is the day the
  /// people in it are living, and Bangladesh is a fixed UTC+6 with no DST.
  static int dateKeyOf(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;

  static int todayKey() => dateKeyOf(DateTime.now());

  /// One order per person per day is enforced by the document path itself -
  /// a second order for the same day is a write to the same document, so a
  /// duplicate cannot exist even if a client tries.
  static String idFor(String uid, int dateKey) => '${uid}_$dateKey';

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
      orderDate: (map['order_date'] as num?)?.toInt() ?? 0,
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate(),
      collectedAt: (map['collected_at'] as Timestamp?)?.toDate(),
      cancelledAt: (map['cancelled_at'] as Timestamp?)?.toDate(),
      cancelledBy: (map['cancelled_by'] as String?) ?? '',
      cancelReason: (map['cancel_reason'] as String?) ?? '',
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
    'order_date': orderDate,
    'created_at': FieldValue.serverTimestamp(),
  };

  /// An edit touches only the basket.
  ///
  /// `created_at`, `order_date` and `payment_status` are deliberately absent:
  /// the security rule rejects an update that changes anything outside this
  /// list, so re-sending them would fail the write.
  Map<String, dynamic> toUpdateMap() => {
    'items': items.map((e) => e.toMap()).toList(),
    'item_count': itemCount,
    'total': total,
    'updated_at': FieldValue.serverTimestamp(),
  };

  /// Ordering again after an admin cancelled today's order.
  ///
  /// This has to be an update rather than a create: the document id is
  /// `uid_yyyyMMdd`, so the cancelled order is still sitting at the address the
  /// new one would use. Reviving it in place is what keeps one-order-per-day
  /// true - there is never a second document to reconcile.
  ///
  /// The three cancellation fields are deleted, not blanked. A leftover reason
  /// on a live order is exactly the sort of thing that resurfaces months later
  /// in a UI that only checks `status`.
  Map<String, dynamic> toReviveMap() => {
    ...toUpdateMap(),
    'status': OrderStatus.placed.name,
    'cancelled_at': FieldValue.delete(),
    'cancelled_by': FieldValue.delete(),
    'cancel_reason': FieldValue.delete(),
  };
}
