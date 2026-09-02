import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/services/firebase/order_repository.dart';
import '../../../core/services/notifications/fcm_token_sync.dart';
import '../../../core/services/firebase/product_repository.dart';
import '../../../core/services/firebase/settings_repository.dart';
import '../../../core/services/firebase/user_repository.dart';
import '../../../core/widgets/show_custom_toast.dart';
import '../../auth/model/app_user.dart';
import '../model/order.dart';
import '../model/product.dart';

/// Catalogue, cart and checkout for the shop screen.
///
/// The cart lives only in memory: it is a few taps to rebuild and an abandoned
/// cart is not worth a document. Only a placed order reaches Firestore.
class HomeController extends GetxController {
  HomeController({
    ProductRepository? productRepository,
    OrderRepository? orderRepository,
    UserRepository? userRepository,
    SettingsRepository? settingsRepository,
  }) : _productRepository = productRepository ?? ProductRepository(),
       _orderRepository = orderRepository ?? OrderRepository(),
       _userRepository = userRepository ?? UserRepository(),
       _settingsRepository = settingsRepository ?? SettingsRepository();

  final ProductRepository _productRepository;
  final OrderRepository _orderRepository;
  final UserRepository _userRepository;
  final SettingsRepository _settingsRepository;

  /// Shown when someone taps the order button while the shop is closed.
  static const String closedMessage =
      'এখন অর্ডার নেওয়া হচ্ছে না। KSMS অ্যাডমিনের সাথে যোগাযোগ করুন।';

  static const String allCategory = 'All';

  final products = <Product>[].obs;
  final appUser = Rxn<AppUser>();
  final selectedCategory = allCategory.obs;

  final isLoading = true.obs;
  final isPlacingOrder = false.obs;
  final errorMessage = RxnString();

  /// productId -> quantity. Entries are removed at zero rather than kept, so
  /// `isEmpty` alone answers "is the cart empty".
  final cart = <String, int>{}.obs;

  /// Today's order, or null before the first one is placed.
  final todayOrder = Rxn<ShopOrder>();

  /// False while the admin has ordering switched off.
  final orderingOpen = true.obs;

  StreamSubscription<List<Product>>? _productSub;
  StreamSubscription<ShopOrder?>? _orderSub;
  StreamSubscription<bool>? _settingsSub;

  /// The basket is filled from the saved order once, on first load. Without
  /// this guard every incoming snapshot - including the one caused by the
  /// user's own edit - would overwrite what they are typing.
  bool _cartPrefilled = false;

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    loadUser();
    _listenToProducts();
    _listenToTodayOrder();
    _listenToSettings();

    // Home is the first screen every signed-in person reaches, which makes it
    // the one place the uid is guaranteed to exist. Fire-and-forget: nothing
    // on this screen waits for it.
    final id = uid;
    if (id != null) unawaited(FcmTokenSync.start(id));
  }

  @override
  void onClose() {
    _productSub?.cancel();
    _orderSub?.cancel();
    _settingsSub?.cancel();
    super.onClose();
  }

  // ---------------------------------------------------------------- user

  Future<void> loadUser() async {
    final id = uid;
    if (id == null) return;
    try {
      appUser.value = await _userRepository.fetchUser(id);
    } catch (e) {
      log('Could not load user: $e');
    }
  }

  final isSavingProfile = false.obs;

  /// Writes the profile sheet's changes and refreshes what the drawer shows.
  ///
  /// Returns true on success so the caller knows whether to close the sheet -
  /// a failed save should leave it open with the typed name still in it.
  Future<bool> updateProfile({
    required String name,
    required String designation,
  }) async {
    final id = uid;
    if (id == null || isSavingProfile.value) return false;

    isSavingProfile.value = true;
    try {
      await _userRepository.updateProfile(
        id,
        name: name,
        designation: designation,
      );
      await loadUser();
      showCustomToast('Profile updated');
      return true;
    } on FirebaseException catch (e) {
      log('Profile update failed: ${e.code} ${e.message}');
      showCustomToast('Could not save (${e.code})');
      return false;
    } catch (e) {
      log('Profile update failed: $e');
      showCustomToast('Could not save your profile');
      return false;
    } finally {
      isSavingProfile.value = false;
    }
  }

  String get greetingName =>
      appUser.value?.name ??
      FirebaseAuth.instance.currentUser?.displayName ??
      'Guest';

  String get greetingDesignation => appUser.value?.designation ?? '';

  String? get avatarUrl =>
      appUser.value?.photoUrl ?? FirebaseAuth.instance.currentUser?.photoURL;

  // ----------------------------------------------------------- catalogue

  void _listenToProducts() {
    _productSub?.cancel();
    _productSub = _productRepository.watchProducts().listen(
      (list) async {
        products.value = list;
        errorMessage.value = null;
        isLoading.value = false;

        // First run on a fresh project: write the starter catalogue so the
        // grid is not empty. Debug only - a release build must never invent
        // shop data.
        if (list.isEmpty && kDebugMode) await seedCatalogue();
      },
      onError: (Object e) {
        log('Product stream failed: $e');
        isLoading.value = false;
        errorMessage.value = e is FirebaseException
            ? 'Could not load products (${e.code})'
            : 'Could not load products';
      },
    );
  }

  /// Public so the empty state can offer a retry: the usual reason this fails
  /// is that firestore.rules has not been published yet, which is fixed in the
  /// console without touching the app.
  Future<void> seedCatalogue() async {
    try {
      final seeded = await _productRepository.seedDefaultsIfEmpty();
      if (seeded) {
        log('Seeded the default product catalogue.');
        showCustomToast('Added the starter catalogue');
      }
    } on FirebaseException catch (e) {
      log('Could not seed products: ${e.code} ${e.message}');
      // Silence here is what made this look like "nothing happened" - say it
      // on screen instead of only in the log.
      errorMessage.value = e.code == 'permission-denied'
          ? 'Firestore rules block writing products.\n'
                'Publish firestore.rules in the console, then tap Retry.'
          : 'Could not add products (${e.code})';
    } catch (e) {
      log('Could not seed products: $e');
      errorMessage.value = 'Could not add products';
    }
  }

  /// 'All' first, then whatever categories the catalogue actually contains -
  /// no hard-coded chip list to fall out of sync.
  List<String> get categories => [
    allCategory,
    ...{for (final p in products) p.category}.toList()..sort(),
  ];

  List<Product> get visibleProducts => selectedCategory.value == allCategory
      ? products
      : products.where((p) => p.category == selectedCategory.value).toList();

  void selectCategory(String category) => selectedCategory.value = category;

  // ------------------------------------------------------- today's order

  void _listenToTodayOrder() {
    final id = uid;
    if (id == null) return;

    _orderSub?.cancel();
    _orderSub = _orderRepository
        .watchMyOrderForToday(id)
        .listen(
          (order) {
            final wasLive = todayOrder.value?.isCancelled == false;
            todayOrder.value = order;

            // The admin cancelled it while the screen was open. The stream
            // brings the news on its own - no polling, no push - but only if
            // something reacts to it, which is what the banner and this reset
            // are for. Silence here is what made a deletion invisible.
            if (order != null && order.isCancelled && wasLive) {
              _cartPrefilled = false;
              cart.clear();
              cancelNoticeDismissed.value = false;
              showCustomToast(
                'আপনার আজকের অর্ডারটি বাতিল করা হয়েছে',
                duration: 4,
              );
              return;
            }

            // Reopening the app mid-day should show the basket the user
            // already submitted, so they can adjust it rather than rebuild it.
            // A cancelled order is deliberately not prefilled: the point is to
            // start again, not to re-submit what was just struck out.
            if (order != null && !order.isCancelled && !_cartPrefilled) {
              _cartPrefilled = true;
              cart.value = {
                for (final item in order.items) item.productId: item.quantity,
              };
            }
          },
          onError: (Object e) => log("Today's order stream failed: $e"),
        );
  }

  // ------------------------------------------------------ cancellation notice

  /// Hides the red banner for the rest of this session.
  ///
  /// Not written to Firestore: the order itself is the record, and one
  /// dismissal per app launch is enough to stop it nagging without hiding it
  /// from someone who reopens the app later and never saw it.
  final cancelNoticeDismissed = false.obs;

  /// Today's order, but only while it is cancelled and the notice still stands.
  ShopOrder? get cancelledOrder {
    final order = todayOrder.value;
    if (order == null || !order.isCancelled) return null;
    return cancelNoticeDismissed.value ? null : order;
  }

  void dismissCancelNotice() => cancelNoticeDismissed.value = true;

  void _listenToSettings() {
    _settingsSub?.cancel();
    _settingsSub = _settingsRepository
        .watchOrderingOpen()
        .listen(
          (isOpen) => orderingOpen.value = isOpen,
          // Fail open: a settings read that breaks must not lock the shop.
          onError: (Object e) {
            log('Ordering flag stream failed: $e');
            orderingOpen.value = true;
          },
        );
  }

  /// True once today's order exists and is live - the button then says
  /// "Edit Order".
  ///
  /// A cancelled order reads as no order at all here, on purpose: the button
  /// goes back to "Place Order" and the flow is the ordinary one, even though
  /// underneath it is reviving a document rather than creating one.
  bool get isEditingOrder {
    final order = todayOrder.value;
    return order != null && !order.isCancelled;
  }

  /// Editing stops once the cash is in: letting someone add items after paying
  /// would put the collected total and the order out of step.
  bool get isOrderLocked => todayOrder.value?.isCollected ?? false;

  // ---------------------------------------------------------------- cart

  int quantityOf(String productId) => cart[productId] ?? 0;

  void increment(Product product) =>
      cart[product.id] = quantityOf(product.id) + 1;

  void decrement(Product product) {
    final next = quantityOf(product.id) - 1;
    if (next <= 0) {
      cart.remove(product.id);
    } else {
      cart[product.id] = next;
    }
  }

  void clearCart() => cart.clear();

  int get itemCount => cart.values.fold(0, (running, q) => running + q);

  int get totalAmount =>
      cartItems.fold(0, (running, item) => running + item.lineTotal);

  /// Cart entries resolved against the live catalogue. A product deleted while
  /// it sat in the cart simply drops out instead of crashing checkout.
  List<OrderItem> get cartItems {
    final byId = {for (final p in products) p.id: p};
    final items = <OrderItem>[];
    cart.forEach((productId, quantity) {
      final product = byId[productId];
      if (product != null && quantity > 0) {
        items.add(OrderItem.fromProduct(product, quantity));
      }
    });
    return items;
  }

  /// The two shortcut buttons at the top. Adds one of whichever product
  /// carries the matching `quick_tag`.
  void quickAdd(String tag) {
    final product = products.firstWhereOrNull((p) => p.quickTag == tag);
    if (product == null) {
      showCustomToast('No $tag item in the catalogue yet');
      return;
    }
    increment(product);
    showCustomToast('${product.name} added');
  }

  // ------------------------------------------------------------ checkout

  Future<void> placeOrder() async {
    if (isPlacingOrder.value) return;

    // Checked here as well as in the button, because the flag can flip while
    // the screen is open. The rule enforces it server-side regardless.
    if (!orderingOpen.value) {
      showCustomToast(closedMessage, duration: 4);
      return;
    }

    if (isOrderLocked) {
      showCustomToast('Payment already collected - this order is locked');
      return;
    }

    final items = cartItems;
    if (items.isEmpty) {
      showCustomToast('Add something to your order first');
      return;
    }

    final id = uid;
    if (id == null) {
      showCustomToast('You are signed out');
      return;
    }

    final wasEditing = isEditingOrder;
    isPlacingOrder.value = true;
    try {
      final order = ShopOrder(
        userId: id,
        userName: greetingName,
        userDesignation: greetingDesignation,
        items: items,
        itemCount: items.fold(0, (running, item) => running + item.quantity),
        // Recomputed from the resolved items, never from the UI, so the stored
        // total always matches the stored lines.
        total: items.fold(0, (running, item) => running + item.lineTotal),
        orderDate: ShopOrder.todayKey(),
      );

      await _orderRepository.placeOrEditOrder(order);

      // The basket is NOT cleared: it now mirrors the saved order, so the user
      // can keep adjusting it. The stream will confirm what actually landed.
      showCustomToast(
        wasEditing
            ? 'Order updated · ৳${order.total}'
            : 'Order placed · ৳${order.total}',
      );
    } on FirebaseException catch (e) {
      log('Place order failed: ${e.code} ${e.message}');
      // permission-denied here almost always means the admin closed ordering
      // between the button appearing and the write landing.
      showCustomToast(
        e.code == 'permission-denied'
            ? closedMessage
            : kDebugMode
            ? 'Order failed (${e.code})'
            : 'Could not save your order',
        duration: 4,
      );
    } catch (e) {
      log('Place order failed: $e');
      showCustomToast('Could not save your order');
    } finally {
      isPlacingOrder.value = false;
    }
  }
}
