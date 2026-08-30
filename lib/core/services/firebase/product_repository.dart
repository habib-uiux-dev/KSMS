import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../feature/home/model/product.dart';
import 'app_firestore.dart';

class ProductRepository {
  ProductRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? appFirestore;

  final FirebaseFirestore _db;

  static const String productsCollection = 'products';

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection(productsCollection);

  /// Sorting happens in Dart rather than through `orderBy`, so the catalogue
  /// needs no composite index and documents missing `sort_order` still show up.
  List<Product> _sorted(Iterable<Product> products) {
    final list = products.where((p) => p.isActive).toList()
      ..sort((a, b) {
        final byOrder = a.sortOrder.compareTo(b.sortOrder);
        return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
      });
    return list;
  }

  Future<List<Product>> fetchProducts() async {
    final snapshot = await _products.get();
    return _sorted(snapshot.docs.map(Product.fromDoc));
  }

  /// Live catalogue – edits made in the Firebase console reach the phone
  /// without a restart.
  Stream<List<Product>> watchProducts() =>
      _products.snapshots().map((s) => _sorted(s.docs.map(Product.fromDoc)));

  /// Creates or updates one product. A blank [Product.id] means create, so the
  /// same form serves both add and edit.
  Future<String> upsertProduct(Product product) async {
    final ref = product.id.isEmpty
        ? _products.doc()
        : _products.doc(product.id);
    await ref.set(product.toMap(), SetOptions(merge: true));
    return ref.id;
  }

  /// Prefer flipping `is_active` to false over deleting: a deleted product
  /// disappears from the catalogue but its name still sits inside old orders.
  Future<void> deleteProduct(String productId) =>
      _products.doc(productId).delete();

  /// The full catalogue including inactive rows - the shop grid hides drafts,
  /// but the admin list has to show them.
  Stream<List<Product>> watchAllProducts() => _products.snapshots().map((s) {
    final list = s.docs.map(Product.fromDoc).toList()
      ..sort((a, b) {
        final byOrder = a.sortOrder.compareTo(b.sortOrder);
        return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
      });
    return list;
  });

  /// Writes the starter catalogue, but only when the collection is empty, so
  /// it can never overwrite prices someone edited in the console.
  ///
  /// Called once from [HomeController] in debug builds. Firestore rules must
  /// allow writes to `products` for this to succeed - see firestore.rules.
  Future<bool> seedDefaultsIfEmpty() async {
    final existing = await _products.limit(1).get();
    if (existing.docs.isNotEmpty) return false;

    final batch = _db.batch();
    for (final entry in _defaultCatalogue.entries) {
      batch.set(_products.doc(entry.key), entry.value.toMap());
    }
    await batch.commit();
    return true;
  }

  /// Fixed document ids, so re-running the seed updates rows instead of
  /// creating duplicates.
  static const Map<String, Product> _defaultCatalogue = {
    'kola-fresh': Product(
      id: 'kola-fresh',
      name: 'Kola',
      subtitle: 'Fresh Banana',
      price: 5,
      category: 'Fruits',
      sortOrder: 1,
    ),
    'kola-premium': Product(
      id: 'kola-premium',
      name: 'Kola',
      subtitle: 'Premium Banana',
      price: 10,
      category: 'Fruits',
      sortOrder: 2,
    ),
    'singara': Product(
      id: 'singara',
      name: 'Singara',
      subtitle: 'Hot Snack',
      price: 5,
      category: 'Snacks',
      sortOrder: 3,
    ),
    'dry-cake': Product(
      id: 'dry-cake',
      name: 'Dry Cake',
      subtitle: 'Sweet Snack',
      price: 10,
      category: 'Snacks',
      sortOrder: 4,
    ),
    'camel': Product(
      id: 'camel',
      name: 'Camel',
      subtitle: 'Hot Beverage',
      price: 15,
      category: 'Drinks',
      sortOrder: 5,
    ),
    'tea': Product(
      id: 'tea',
      name: 'Tea',
      subtitle: 'Hot Beverage',
      price: 10,
      category: 'Drinks',
      quickTag: 'tea',
      sortOrder: 6,
    ),
    'royal-next': Product(
      id: 'royal-next',
      name: 'Royal Next',
      subtitle: 'Cigarette',
      price: 7,
      category: 'Cigarette',
      quickTag: 'smoke',
      sortOrder: 7,
    ),
  };
}
