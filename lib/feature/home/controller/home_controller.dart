import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/services/firebase/order_repository.dart';
import '../../../core/services/firebase/product_repository.dart';
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
  }) : _productRepository = productRepository ?? ProductRepository(),
       _orderRepository = orderRepository ?? OrderRepository(),
       _userRepository = userRepository ?? UserRepository();

  final ProductRepository _productRepository;
  final OrderRepository _orderRepository;
  final UserRepository _userRepository;

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

  StreamSubscription<List<Product>>? _productSub;

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    loadUser();
    _listenToProducts();
  }

  @override
  void onClose() {
    _productSub?.cancel();
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
      );

      await _orderRepository.placeOrder(order);

      clearCart();
      showCustomToast('Order placed · ৳${order.total}');
    } on FirebaseException catch (e) {
      log('Place order failed: ${e.code} ${e.message}');
      showCustomToast(
        kDebugMode ? 'Order failed (${e.code})' : 'Could not place your order',
      );
    } catch (e) {
      log('Place order failed: $e');
      showCustomToast('Could not place your order');
    } finally {
      isPlacingOrder.value = false;
    }
  }
}
