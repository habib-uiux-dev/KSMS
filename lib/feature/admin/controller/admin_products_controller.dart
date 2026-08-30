import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/firebase/product_repository.dart';
import '../../../core/widgets/show_custom_toast.dart';
import '../../home/model/product.dart';

/// The Products tab plus the add/edit form.
class AdminProductsController extends GetxController {
  AdminProductsController({ProductRepository? productRepository})
    : _productRepository = productRepository ?? ProductRepository();

  final ProductRepository _productRepository;

  /// Includes inactive products - the admin list has to show drafts, unlike
  /// the shop grid.
  final products = <Product>[].obs;
  final isLoading = true.obs;
  final errorMessage = RxnString();

  StreamSubscription<List<Product>>? _sub;

  // ------------------------------------------------------------------ form

  final nameController = TextEditingController();
  final subtitleController = TextEditingController();
  final priceController = TextEditingController();
  final imageUrlController = TextEditingController();

  final formCategory = RxnString();
  final formIsActive = true.obs;
  final formQuickTag = RxnString();
  final isSaving = false.obs;

  /// Empty while adding, set while editing.
  final editingId = ''.obs;

  bool get isEditing => editingId.value.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _listen();
  }

  @override
  void onClose() {
    _sub?.cancel();
    nameController.dispose();
    subtitleController.dispose();
    priceController.dispose();
    imageUrlController.dispose();
    super.onClose();
  }

  void _listen() {
    _sub?.cancel();
    _sub = _productRepository.watchAllProducts().listen(
      (list) {
        products.value = list;
        errorMessage.value = null;
        isLoading.value = false;
      },
      onError: (Object e) {
        log('Admin product stream failed: $e');
        isLoading.value = false;
        errorMessage.value = e is FirebaseException
            ? 'Could not load products (${e.code})'
            : 'Could not load products';
      },
    );
  }

  /// Existing categories, so the form can offer a dropdown instead of asking
  /// the admin to retype - and to spell - a category exactly.
  List<String> get knownCategories {
    final set = {for (final p in products) p.category}
      ..removeWhere((c) => c.isEmpty);
    return set.toList()..sort();
  }

  // ------------------------------------------------------------------ form

  /// Pass null to start a blank form, a product to edit it.
  void startForm([Product? product]) {
    editingId.value = product?.id ?? '';
    nameController.text = product?.name ?? '';
    subtitleController.text = product?.subtitle ?? '';
    priceController.text = product == null ? '' : '${product.price}';
    imageUrlController.text = product?.imageUrl ?? '';
    formCategory.value = product?.category;
    formQuickTag.value = product?.quickTag;
    formIsActive.value = product?.isActive ?? true;
  }

  /// Returns the saved product id, or null when validation or the write failed.
  Future<String?> saveProduct() async {
    if (isSaving.value) return null;

    final name = nameController.text.trim();
    if (name.isEmpty) {
      showCustomToast('Product name is required');
      return null;
    }

    final category = formCategory.value?.trim();
    if (category == null || category.isEmpty) {
      showCustomToast('Pick a category');
      return null;
    }

    // Accepts "12" and "12.50" but stores whole taka, because prices are
    // integers everywhere else and a stray double would break the totals.
    final price = double.tryParse(priceController.text.trim());
    if (price == null || price < 0) {
      showCustomToast('Enter a valid price');
      return null;
    }

    isSaving.value = true;
    try {
      final existing = products.firstWhereOrNull(
        (p) => p.id == editingId.value,
      );

      final product = Product(
        id: editingId.value,
        name: name,
        subtitle: subtitleController.text.trim(),
        price: price.round(),
        category: category,
        imageUrl: imageUrlController.text.trim().isEmpty
            ? null
            : imageUrlController.text.trim(),
        quickTag: formQuickTag.value,
        isActive: formIsActive.value,
        // Keep the position on edit; put new products at the end.
        sortOrder: existing?.sortOrder ?? (products.length + 1),
      );

      final id = await _productRepository.upsertProduct(product);
      showCustomToast(isEditing ? 'Product updated' : 'Product added');
      return id;
    } on FirebaseException catch (e) {
      log('Save product failed: ${e.code} ${e.message}');
      showCustomToast(
        e.code == 'permission-denied'
            ? 'You do not have permission to edit products'
            : 'Could not save (${e.code})',
      );
      return null;
    } catch (e) {
      log('Save product failed: $e');
      showCustomToast('Could not save the product');
      return null;
    } finally {
      isSaving.value = false;
    }
  }

  /// Hides a product from the shop without deleting it, so old orders keep
  /// resolving to a real catalogue row.
  Future<void> toggleActive(Product product) async {
    try {
      await _productRepository.upsertProduct(
        product.copyWith(isActive: !product.isActive),
      );
    } catch (e) {
      log('Toggle active failed: $e');
      showCustomToast('Could not update the product');
    }
  }

  Future<void> deleteProduct(Product product) async {
    try {
      await _productRepository.deleteProduct(product.id);
      showCustomToast('${product.name} deleted');
    } catch (e) {
      log('Delete product failed: $e');
      showCustomToast('Could not delete the product');
    }
  }
}
