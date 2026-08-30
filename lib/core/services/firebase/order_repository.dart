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

  /// Returns the new document id.
  ///
  /// The id is allocated locally by `doc()` before the write, so the caller
  /// has something to show even while the write is still in flight.
  Future<String> placeOrder(ShopOrder order) async {
    final ref = _orders.doc();
    await ref.set(order.toCreateMap());
    return ref.id;
  }

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

  /// Every order placed since local midnight, newest first.
  ///
  /// A single-field range plus an orderBy on that same field needs no
  /// composite index, which is why the admin views filter by time rather than
  /// by status.
  Stream<List<ShopOrder>> watchTodayOrders() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return _orders
        .where(
          'created_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ShopOrder.fromDoc).toList());
  }

  /// Marks the cash as handed over. Only the payment fields are touched, so a
  /// concurrent edit elsewhere in the document is not clobbered.
  Future<void> markCollected(String orderId) => _orders.doc(orderId).update({
    'payment_status': PaymentStatus.collected.name,
    'collected_at': FieldValue.serverTimestamp(),
  });

  Future<void> markPending(String orderId) => _orders.doc(orderId).update({
    'payment_status': PaymentStatus.pending.name,
    'collected_at': null,
  });

  Future<List<ShopOrder>> fetchMyOrders(String uid, {int limit = 50}) async {
    final snapshot = await _orders
        .where('user_id', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map(ShopOrder.fromDoc).toList();
  }
}
