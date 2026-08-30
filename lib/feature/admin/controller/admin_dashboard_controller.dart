import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../core/services/firebase/order_repository.dart';
import '../../../core/widgets/show_custom_toast.dart';
import '../../home/model/order.dart';

/// Backs the three read-only admin tabs: Home, Cash Collection and Summary.
///
/// All three read the same "today's orders" stream, so they are one controller
/// rather than three - a single Firestore listener instead of three.
class AdminDashboardController extends GetxController {
  AdminDashboardController({OrderRepository? orderRepository})
    : _orderRepository = orderRepository ?? OrderRepository();

  final OrderRepository _orderRepository;

  final orders = <ShopOrder>[].obs;
  final isLoading = true.obs;
  final errorMessage = RxnString();

  /// Orders currently being marked, so each card can show its own spinner
  /// instead of freezing the whole list.
  final busyOrderIds = <String>{}.obs;

  StreamSubscription<List<ShopOrder>>? _orderSub;

  @override
  void onInit() {
    super.onInit();
    _listen();
  }

  @override
  void onClose() {
    _orderSub?.cancel();
    super.onClose();
  }

  void _listen() {
    _orderSub?.cancel();
    _orderSub = _orderRepository.watchTodayOrders().listen(
      (list) {
        orders.value = list;
        errorMessage.value = null;
        isLoading.value = false;
      },
      onError: (Object e) {
        log('Today orders stream failed: $e');
        isLoading.value = false;
        errorMessage.value = e is FirebaseException
            ? 'Could not load orders (${e.code})'
            : 'Could not load orders';
      },
    );
  }

  void refreshOrders() {
    isLoading.value = true;
    _listen();
  }

  // --------------------------------------------------------------- totals

  int get totalOrders => orders.length;

  int get totalAmount => orders.fold(0, (running, o) => running + o.total);

  int get collectedAmount => orders
      .where((o) => o.isCollected)
      .fold(0, (running, o) => running + o.total);

  /// Derived by subtraction rather than summed separately, so collected and
  /// pending can never disagree with the total.
  int get pendingAmount => totalAmount - collectedAmount;

  List<ShopOrder> get pendingOrders =>
      orders.where((o) => !o.isCollected).toList();

  // -------------------------------------------------------------- summary

  /// category -> (product name -> pieces), for the Summary tab.
  ///
  /// Built from the order lines, not the catalogue, so a product deleted after
  /// it was ordered still shows up in today's totals.
  Map<String, Map<String, int>> get summaryByCategory {
    final result = <String, Map<String, int>>{};

    for (final order in orders) {
      for (final item in order.items) {
        // Order lines do not carry the category, so items are grouped by the
        // subtitle the shop already uses as a shelf label ("Hot Snack").
        final group = item.subtitle.isEmpty ? 'Other' : item.subtitle;
        final bucket = result.putIfAbsent(group, () => <String, int>{});
        bucket[item.name] = (bucket[item.name] ?? 0) + item.quantity;
      }
    }

    return result;
  }

  int get totalPieces => orders.fold(
    0,
    (running, o) =>
        running + o.items.fold(0, (inner, item) => inner + item.quantity),
  );

  // ------------------------------------------------------------ collection

  bool isBusy(String orderId) => busyOrderIds.contains(orderId);

  Future<void> markCollected(ShopOrder order) async {
    if (order.id.isEmpty || isBusy(order.id)) return;

    busyOrderIds.add(order.id);
    try {
      await _orderRepository.markCollected(order.id);
      showCustomToast('Collected ৳${order.total} from ${order.userName}');
    } on FirebaseException catch (e) {
      log('Mark collected failed: ${e.code} ${e.message}');
      showCustomToast('Could not update (${e.code})');
    } catch (e) {
      log('Mark collected failed: $e');
      showCustomToast('Could not update the order');
    } finally {
      busyOrderIds.remove(order.id);
    }
  }

  Future<void> markPending(ShopOrder order) async {
    if (order.id.isEmpty || isBusy(order.id)) return;

    busyOrderIds.add(order.id);
    try {
      await _orderRepository.markPending(order.id);
    } catch (e) {
      log('Mark pending failed: $e');
      showCustomToast('Could not update the order');
    } finally {
      busyOrderIds.remove(order.id);
    }
  }
}
