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

  /// Creates today's order, or replaces the basket in the existing one.
  ///
  /// Create and update send different payloads on purpose: the security rule
  /// lets an owner change only the basket fields, so an update that re-sent
  /// `created_at` or `order_date` would be rejected. Returns the document id.
  Future<String> placeOrEditOrder(ShopOrder order) async {
    final ref = _orders.doc(ShopOrder.idFor(order.userId, order.orderDate));
    final existing = await ref.get();

    if (existing.exists) {
      await ref.update(order.toUpdateMap());
    } else {
      await ref.set(order.toCreateMap());
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

  /// Removes an order outright. Admin-only, and the rule says so too.
  Future<void> deleteOrder(String orderId) => _orders.doc(orderId).delete();

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
