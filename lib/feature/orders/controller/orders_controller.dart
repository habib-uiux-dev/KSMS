import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../core/services/firebase/order_repository.dart';
import '../../home/model/order.dart';

/// Which slice of history the leaderboard is showing.
enum LeaderboardRange { today, week, month, all }

extension LeaderboardRangeLabel on LeaderboardRange {
  String get label => switch (this) {
    LeaderboardRange.today => 'Today',
    LeaderboardRange.week => 'Week',
    LeaderboardRange.month => 'Month',
    LeaderboardRange.all => 'All',
  };
}

/// One person's standing, rolled up from their orders in the current range.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.name,
    required this.designation,
    required this.items,
    required this.spent,
  });

  final String userId;
  final String name;
  final String designation;
  final int items;
  final int spent;
}

/// Backs both tabs behind the drawer: the caller's own order history, and the
/// shop-wide leaderboard.
///
/// One controller because the two screens live in the same shell and share a
/// lifetime; splitting them would mean two subscriptions torn down at two
/// different times for no gain.
class OrdersController extends GetxController {
  OrdersController({OrderRepository? orderRepository})
    : _orderRepository = orderRepository ?? OrderRepository();

  final OrderRepository _orderRepository;

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  final tabIndex = 0.obs;

  // -------------------------------------------------------------- my orders

  final myOrders = <ShopOrder>[].obs;
  final isLoadingMine = true.obs;

  // ------------------------------------------------------------ leaderboard

  final range = LeaderboardRange.today.obs;
  final entries = <LeaderboardEntry>[].obs;
  final isLoadingBoard = true.obs;
  final boardError = RxnString();

  /// Everyone's items in the current range - the number on the green banner.
  int get totalItems => entries.fold(0, (running, e) => running + e.items);

  StreamSubscription<List<ShopOrder>>? _mineSub;
  StreamSubscription<List<ShopOrder>>? _boardSub;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;
    if (args is Map && args['tab'] is int) tabIndex.value = args['tab'] as int;

    _listenToMine();
    _listenToBoard();
  }

  @override
  void onClose() {
    _mineSub?.cancel();
    _boardSub?.cancel();
    super.onClose();
  }

  void _listenToMine() {
    final id = uid;
    if (id == null) {
      isLoadingMine.value = false;
      return;
    }

    _mineSub?.cancel();
    _mineSub = _orderRepository.watchMyOrders(id).listen(
      (list) {
        myOrders.value = list;
        isLoadingMine.value = false;
      },
      onError: (Object e) {
        log('My orders stream failed: $e');
        isLoadingMine.value = false;
      },
    );
  }

  void selectRange(LeaderboardRange value) {
    if (range.value == value) return;
    range.value = value;
    _listenToBoard();
  }

  void _listenToBoard() {
    _boardSub?.cancel();
    isLoadingBoard.value = true;
    boardError.value = null;

    final stream = switch (range.value) {
      LeaderboardRange.all => _orderRepository.watchAllOrders(),
      _ => _orderRepository.watchOrdersBetween(_fromKey(), ShopOrder.todayKey()),
    };

    _boardSub = stream.listen(
      (orders) {
        entries.value = _rollUp(orders);
        isLoadingBoard.value = false;
      },
      onError: (Object e) {
        log('Leaderboard stream failed: $e');
        boardError.value = 'Could not load the leaderboard';
        isLoadingBoard.value = false;
      },
    );
  }

  /// First shop day of the selected range, as yyyyMMdd.
  int _fromKey() {
    final now = DateTime.now();
    return switch (range.value) {
      LeaderboardRange.today => ShopOrder.todayKey(),
      // Rolling seven days rather than "since Monday": the number never resets
      // to near-zero mid-week, which is what people expect from a leaderboard.
      LeaderboardRange.week => ShopOrder.dateKeyOf(
        now.subtract(const Duration(days: 6)),
      ),
      LeaderboardRange.month => ShopOrder.dateKeyOf(
        now.subtract(const Duration(days: 29)),
      ),
      LeaderboardRange.all => 0,
    };
  }

  /// Groups orders by person and sorts by items, then by spend as a tie-break.
  ///
  /// Name and designation are read off the order itself, not joined from
  /// `users`: they were correct when the order was placed, and this needs no
  /// second query and no read access to everyone's profile.
  List<LeaderboardEntry> _rollUp(List<ShopOrder> orders) {
    final items = <String, int>{};
    final spent = <String, int>{};
    final names = <String, String>{};
    final designations = <String, String>{};

    for (final order in orders) {
      final id = order.userId;
      if (id.isEmpty) continue;

      items[id] = (items[id] ?? 0) + order.itemCount;
      spent[id] = (spent[id] ?? 0) + order.total;
      if (order.userName.isNotEmpty) names[id] = order.userName;
      if (order.userDesignation.isNotEmpty) {
        designations[id] = order.userDesignation;
      }
    }

    final list = items.keys
        .map(
          (id) => LeaderboardEntry(
            userId: id,
            name: names[id] ?? 'Someone',
            designation: designations[id] ?? '',
            items: items[id] ?? 0,
            spent: spent[id] ?? 0,
          ),
        )
        .toList();

    list.sort((a, b) {
      final byItems = b.items.compareTo(a.items);
      return byItems != 0 ? byItems : b.spent.compareTo(a.spent);
    });
    return list;
  }
}
