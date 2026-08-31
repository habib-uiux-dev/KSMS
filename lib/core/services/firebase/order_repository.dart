import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../feature/home/model/order.dart';
import 'app_firestore.dart';

class OrderRepository {
  OrderRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? appFirestore;

  final FirebaseFirestore _db;

  static const String ordersCollection = 'orders';

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection(ordersCollection);

  // ------------------------------------------------------------ one per day

  /// Today's order for one person, or null if they have not ordered yet.
  ///
  /// A document read by id, not a query - the id already encodes "this person,
  /// this day", so there is nothing to filter and no index to build.
  Stream<ShopOrder?> watchMyOrderForToday(String uid) => _orders
      .doc(ShopOrder.idFor(uid, ShopOrder.todayKey()))
      .snapshots()
      .map((doc) => doc.exists ? ShopOrder.fromDoc(doc) : null);

  Future<ShopOrder?> fetchMyOrderForToday(String uid) async {
    final doc = await _orders
        .doc(ShopOrder.idFor(uid, ShopOrder.todayKey()))
        .get();
    return doc.exists ? ShopOrder.fromDoc(doc) : null;
  }

  /// Creates today's order, revives a cancelled one, or replaces the basket in
  /// a live one.
  ///
  /// Three payloads, not one, because the security rules allow three different
  /// sets of keys. An owner editing a live order may touch only the basket, so
  /// an update that re-sent `created_at` or `order_date` would be rejected
  /// outright. Reviving additionally has to flip `status` and clear the
  /// cancellation fields, which the ordinary edit is forbidden to do.
  ///
  /// Returns the document id.
  Future<String> placeOrEditOrder(ShopOrder order) async {
    final ref = _orders.doc(ShopOrder.idFor(order.userId, order.orderDate));
    final existing = await ref.get();

    if (!existing.exists) {
      await ref.set(order.toCreateMap());
    } else if (ShopOrder.fromDoc(existing).isCancelled) {
      await ref.update(order.toReviveMap());
    } else {
      await ref.update(order.toUpdateMap());
    }
    return ref.id;
  }

  // ---------------------------------------------------------------- reading

  /// This user's orders, newest first.
  ///
  /// The `where` + `orderBy` pair needs a composite index on
  /// (user_id, created_at desc). Firestore prints a ready-made link in the
  /// console log the first time it runs - open it once and the index builds.
  Stream<List<ShopOrder>> watchMyOrders(String uid, {int limit = 50}) => _orders
      .where('user_id', isEqualTo: uid)
      .orderBy('created_at', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(ShopOrder.fromDoc).toList());

  /// Every order filed under today's shop day, newest first.
  ///
  /// Filters on `order_date` rather than a `created_at` range: an edited order
  /// keeps its original `created_at`, and this way the admin's "today" is
  /// exactly the day each order was filed under. Sorting happens in Dart, so
  /// the single-field filter needs no composite index.
  Stream<List<ShopOrder>> watchTodayOrders() => _orders
      .where('order_date', isEqualTo: ShopOrder.todayKey())
      .snapshots()
      .map((s) {
        final list = s.docs.map(ShopOrder.fromDoc).toList()
          ..sort((a, b) {
            final at = a.createdAt;
            final bt = b.createdAt;
            if (at == null || bt == null) return 0;
            return bt.compareTo(at);
          });
        return list;
      });

  /// Every order filed between two shop days, inclusive.
  ///
  /// Backs the leaderboard. `order_date` is a plain yyyyMMdd int, so a range
  /// filter on one field is enough - no composite index, and no date maths in
  /// Dart to disagree with what the rules computed.
  Stream<List<ShopOrder>> watchOrdersBetween(int fromKey, int toKey) => _orders
      .where('order_date', isGreaterThanOrEqualTo: fromKey)
      .where('order_date', isLessThanOrEqualTo: toKey)
      .snapshots()
      .map((s) => s.docs.map(ShopOrder.fromDoc).toList());

  /// Every order ever placed. Only used by the leaderboard's "All" tab.
  Stream<List<ShopOrder>> watchAllOrders() =>
      _orders.snapshots().map((s) => s.docs.map(ShopOrder.fromDoc).toList());

  Future<List<ShopOrder>> fetchMyOrders(String uid, {int limit = 50}) async {
    final snapshot = await _orders
        .where('user_id', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map(ShopOrder.fromDoc).toList();
  }

  // ------------------------------------------------------------- collection

  /// Marks the cash as handed over. Only the payment fields are touched, which
  /// is also all the security rule allows an admin to change.
  // ------------------------------------------------------- admin corrections

  /// Cancels an order instead of deleting it. Admin-only, and the rule agrees.
  ///
  /// Deleting was the original behaviour and it was silently hostile: the
  /// document vanished, the owner's listener saw `null`, and their home screen
  /// went back to "Place Order" as though they had never ordered. Nobody was
  /// told anything. A cancelled document is the only way the app can say what
  /// happened - and the only way it can say who did it.
  Future<void> cancelOrder(
    String orderId, {
    required String adminUid,
    required String reason,
  }) {
    return _orders.doc(orderId).update({
      'status': OrderStatus.cancelled.name,
      'cancelled_at': FieldValue.serverTimestamp(),
      'cancelled_by': adminUid,
      'cancel_reason': reason,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Rewrites the basket of somebody else's order.
  ///
  /// Deliberately narrow: items, the two derived numbers and a timestamp. The
  /// totals are recomputed here from the lines rather than trusted from the
  /// caller, so a corrected order can never disagree with its own arithmetic.
  Future<void> replaceItems(String orderId, List<OrderItem> items) {
    return _orders.doc(orderId).update({
      'items': items.map((e) => e.toMap()).toList(),
      'item_count': items.fold<int>(0, (running, i) => running + i.quantity),
      'total': items.fold<int>(0, (running, i) => running + i.lineTotal),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markCollected(String orderId) => _orders.doc(orderId).update({
    'payment_status': PaymentStatus.collected.name,
    'collected_at': FieldValue.serverTimestamp(),
  });

  Future<void> markPending(String orderId) => _orders.doc(orderId).update({
    'payment_status': PaymentStatus.pending.name,
    'collected_at': null,
  });
}
