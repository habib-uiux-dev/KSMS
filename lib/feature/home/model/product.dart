import 'package:cloud_firestore/cloud_firestore.dart';

/// One item in the shop catalogue, from `products/{id}`.
///
/// Prices are whole taka, so they are stored as `int` – a double would let
/// floating point drift into an order total.
class Product {
  final String id;
  final String name;
  final String subtitle;
  final int price;
  final String category;
  final String? imageUrl;

  /// Marks the item behind a quick-order button ('tea' or 'smoke'). Null for
  /// everything that is only reachable through the grid.
  final String? quickTag;

  /// Hidden from the grid without deleting the document, so past orders keep
  /// resolving to a real product.
  final bool isActive;

  /// Lower sorts first. Ties fall back to name.
  final int sortOrder;

  const Product({
    required this.id,
    required this.name,
    this.subtitle = '',
    this.price = 0,
    this.category = 'Other',
    this.imageUrl,
    this.quickTag,
    this.isActive = true,
    this.sortOrder = 0,
  });

  Product copyWith({
    String? id,
    String? name,
    String? subtitle,
    int? price,
    String? category,
    String? imageUrl,
    String? quickTag,
    bool? isActive,
    int? sortOrder,
  }) => Product(
    id: id ?? this.id,
    name: name ?? this.name,
    subtitle: subtitle ?? this.subtitle,
    price: price ?? this.price,
    category: category ?? this.category,
    imageUrl: imageUrl ?? this.imageUrl,
    quickTag: quickTag ?? this.quickTag,
    isActive: isActive ?? this.isActive,
    sortOrder: sortOrder ?? this.sortOrder,
  );

  factory Product.fromMap(String id, Map<String, dynamic> map) => Product(
    id: id,
    name: (map['name'] as String?) ?? '',
    subtitle: (map['subtitle'] as String?) ?? '',
    // Tolerates a price typed as a double in the console.
    price: (map['price'] as num?)?.toInt() ?? 0,
    category: (map['category'] as String?) ?? 'Other',
    imageUrl: map['image_url'] as String?,
    quickTag: map['quick_tag'] as String?,
    isActive: (map['is_active'] as bool?) ?? true,
    sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
  );

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Product.fromMap(doc.id, doc.data() ?? const {});

  Map<String, dynamic> toMap() => {
    'name': name,
    'subtitle': subtitle,
    'price': price,
    'category': category,
    'image_url': imageUrl,
    'quick_tag': quickTag,
    'is_active': isActive,
    'sort_order': sortOrder,
  };
}
