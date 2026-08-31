import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../core/services/firebase/order_repository.dart';
import '../../../core/services/firebase/settings_repository.dart';
import '../../../core/widgets/show_custom_toast.dart';
import '../../home/model/order.dart';

/// Backs the three read-only admin tabs: Home, Cash Collection and Summary.
///
/// All three read the same "today's orders" stream, so they are one controller
/// rather than three - a single Firestore listener instead of three.
class AdminDashboardController extends GetxController {
  AdminDashboardController({
    OrderRepository? orderRepository,
    SettingsRepository? settingsRepository,
  }) : _orderRepository = orderRepository ?? OrderRepository(),
       _settingsRepository = settingsRepository ?? SettingsRepository();

  final OrderRepository _orderRepository;
  final SettingsRepository _settingsRepository;

  /// Whether the shop is taking orders. Mirrors settings/ordering, which the
  /// security rules also consult - flipping this actually stops writes rather
  /// than only greying out a button.
  final orderingOpen = true.obs;
  final isTogglingOrdering = false.obs;

  final orders = <ShopOrder>[].obs;
  final isLoading = true.obs;
  final errorMessage = RxnString();

  /// Orders currently being marked, so each card can show its own spinner
  /// instead of freezing the whole list.
  final busyOrderIds = <String>{}.obs;

  StreamSubscription<List<ShopOrder>>? _orderSub;
  StreamSubscription<bool>? _settingsSub;

  @override
  void onInit() {
    super.onInit();
    _listen();
    _listenToSettings();
  }

  @override
  void onClose() {
    _orderSub?.cancel();
    _settingsSub?.cancel();
    super.onClose();
  }

  void _listenToSettings() {
    _settingsSub?.cancel();
    _settingsSub = _settingsRepository.watchOrderingOpen().listen(
      (isOpen) => orderingOpen.value = isOpen,
      onError: (Object e) => log('Ordering flag stream failed: $e'),
    );
  }

  Future<void> setOrderingOpen(bool isOpen) async {
    if (isTogglingOrdering.value) return;

    isTogglingOrdering.value = true;
    try {
      await _settingsRepository.setOrderingOpen(isOpen);
      showCustomToast(isOpen ? 'Orders are now open' : 'Orders are now closed');
    } on FirebaseException catch (e) {
      log('Toggle ordering failed: ${e.code} ${e.message}');
      showCustomToast(
        e.code == 'permission-denied'
            ? 'Only an admin can change this'
            : 'Could not update (${e.code})',
      );
    } catch (e) {
      log('Toggle ordering failed: $e');
      showCustomToast('Could not update the setting');
    } finally {
      isTogglingOrdering.value = false;
    }
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

  // ------------------------------------------------------- corrections

  /// Removes an order for someone who changed their mind after the shop shut,
  /// or a duplicate the shop keeper wants gone.
  Future<void> deleteOrder(ShopOrder order) async {
    if (order.id.isEmpty || isBusy(order.id)) return;

    busyOrderIds.add(order.id);
    try {
      await _orderRepository.deleteOrder(order.id);
      showCustomToast('Order deleted');
    } on FirebaseException catch (e) {
      log('Delete order failed: ${e.code} ${e.message}');
      showCustomToast(
        e.code == 'permission-denied'
            ? 'Only an admin can delete an order'
            : 'Could not delete (${e.code})',
      );
    } catch (e) {
      log('Delete order failed: $e');
      showCustomToast('Could not delete the order');
    } finally {
      busyOrderIds.remove(order.id);
    }
  }

  /// Nudges one line up or down. Dropping the last unit of a line removes the
  /// line; emptying the order entirely is a delete, which the caller confirms
  /// separately rather than having it happen by accident on a minus tap.
  Future<void> changeQuantity(
    ShopOrder order,
    String productId,
    int delta,
  ) async {
    if (order.id.isEmpty || isBusy(order.id)) return;

    final items = <OrderItem>[];
    for (final item in order.items) {
      if (item.productId != productId) {
        items.add(item);
        continue;
      }
      final quantity = item.quantity + delta;
      if (quantity > 0) items.add(item.copyWith(quantity: quantity));
    }

    if (items.isEmpty) {
      showCustomToast('Delete the order instead of emptying it');
      return;
    }

    busyOrderIds.add(order.id);
    try {
      await _orderRepository.replaceItems(order.id, items);
    } on FirebaseException catch (e) {
      log('Edit order failed: ${e.code} ${e.message}');
      showCustomToast(
        e.code == 'permission-denied'
            ? 'Only an admin can edit an order'
            : 'Could not update (${e.code})',
      );
    } catch (e) {
      log('Edit order failed: $e');
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
