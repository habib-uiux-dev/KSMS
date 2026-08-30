import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/image_loader.dart';
import '../controller/admin_products_controller.dart';
import 'widgets/admin_widgets.dart';

/// Add / edit one product. The controller holds the field state, so the form
/// survives a rebuild and the list screen can prefill it before navigating.
class AdminProductFormScreen extends StatelessWidget {
  const AdminProductFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminProductsController>();

    return Scaffold(
      backgroundColor: AdminColors.bg,
      appBar: AppBar(
        backgroundColor: AdminColors.bg,
        elevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back, color: AdminColors.ink),
        ),
        title: Obx(
          () => Text(
            controller.isEditing ? 'Edit Product' : 'Add Product',
            style: GoogleFonts.openSans(
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
              color: AdminColors.green,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 32.h),
        children: [
          // ================= IMAGE =================
          Center(child: _ImageTile(controller: controller)),

          SizedBox(height: 26.h),

          _Label('Product Name'),
          _Field(
            controller: controller.nameController,
            hint: 'e.g., Fresh Banana',
            textCapitalization: TextCapitalization.words,
          ),

          SizedBox(height: 18.h),

          _Label('Subtitle'),
          _Field(
            controller: controller.subtitleController,
            hint: 'e.g., Hot Snack',
            textCapitalization: TextCapitalization.words,
          ),

          SizedBox(height: 18.h),

          _Label('Category'),
          _CategoryPicker(controller: controller),

          SizedBox(height: 18.h),

          _Label('Price (৳)'),
          _Field(
            controller: controller.priceController,
            hint: '0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
          ),

          SizedBox(height: 18.h),

          _Label('Image URL'),
          _Field(
            controller: controller.imageUrlController,
            hint: 'https://...',
            keyboardType: TextInputType.url,
          ),

          SizedBox(height: 18.h),

          // ================= STATUS =================
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AdminColors.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Status',
                        style: GoogleFonts.openSans(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: AdminColors.ink,
                        ),
                      ),
                      Text(
                        'Active products are visible to users',
                        style: GoogleFonts.openSans(
                          fontSize: 13.sp,
                          color: AdminColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Obx(
                  () => Switch(
                    value: controller.formIsActive.value,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AdminColors.green,
                    onChanged: (value) => controller.formIsActive.value = value,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 18.h),

          _Label('Quick button'),
          _QuickTagPicker(controller: controller),

          SizedBox(height: 28.h),

          // ================= SAVE =================
          Obx(
            () => SizedBox(
              height: 58.h,
              child: ElevatedButton(
                onPressed: controller.isSaving.value
                    ? null
                    : () async {
                        final id = await controller.saveProduct();
                        // Only leave on success, so a validation error keeps
                        // the typed values on screen.
                        if (id != null) Get.back();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.green,
                  disabledBackgroundColor: const Color(0xFF86C8A2),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                child: Text(
                  controller.isSaving.value ? 'Saving...' : 'Save Product',
                  style: GoogleFonts.openSans(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 8.h),

          TextButton(
            onPressed: Get.back,
            child: Text(
              'Cancel',
              style: GoogleFonts.openSans(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: AdminColors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the current image, or the dashed upload placeholder.
///
/// Tapping focuses the URL field rather than opening a picker: uploading from
/// the phone needs Firebase Storage, which this project does not use yet.
class _ImageTile extends StatelessWidget {
  const _ImageTile({required this.controller});

  final AdminProductsController controller;

  @override
  Widget build(BuildContext context) {
    // A TextEditingController is itself a ValueListenable, so this rebuilds on
    // every keystroke. Obx cannot do that job - it only tracks Rx values, and
    // the URL lives in a plain text controller.
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller.imageUrlController,
      builder: (context, value, _) {
        final url = value.text.trim();

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            width: 180.w,
            height: 180.h,
            decoration: BoxDecoration(
              color: AdminColors.tile,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: const Color(0xFFB8CBB8), width: 1.4.w),
            ),
            clipBehavior: Clip.antiAlias,
            child: url.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 40.sp,
                        color: AdminColors.muted,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Paste an image URL below',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.openSans(
                          fontSize: 13.sp,
                          color: AdminColors.muted,
                        ),
                      ),
                    ],
                  )
                : ImageLoader(url: url, boxFit: BoxFit.cover),
          ),
        );
      },
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.controller});

  final AdminProductsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final known = controller.knownCategories;
      final selected = controller.formCategory.value;

      // A category typed in the dialog may not be in the list yet; adding it
      // here keeps DropdownButton from asserting on an unknown value.
      final options = <String>{...known, ?selected}.toList()..sort();

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFBFD6C6)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: selected,
            hint: Text(
              'Select Category',
              style: GoogleFonts.openSans(
                color: AdminColors.muted,
                fontSize: 16.sp,
              ),
            ),
            items: [
              for (final option in options)
                DropdownMenuItem(
                  value: option,
                  child: Text(
                    option,
                    style: GoogleFonts.openSans(fontSize: 16.sp),
                  ),
                ),
              DropdownMenuItem(
                value: _newCategorySentinel,
                child: Text(
                  '+ New category',
                  style: GoogleFonts.openSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.green,
                  ),
                ),
              ),
            ],
            onChanged: (value) async {
              if (value == _newCategorySentinel) {
                final created = await _askForCategory(context);
                if (created != null && created.isNotEmpty) {
                  controller.formCategory.value = created;
                }
                return;
              }
              controller.formCategory.value = value;
            },
          ),
        ),
      );
    });
  }

  static const String _newCategorySentinel = '__new__';

  Future<String?> _askForCategory(BuildContext context) {
    final field = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New category', style: GoogleFonts.openSans()),
        content: TextField(
          controller: field,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'e.g. Biscuit'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.openSans()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, field.text.trim()),
            child: Text('Add', style: GoogleFonts.openSans()),
          ),
        ],
      ),
    );
  }
}

/// Which of the two shortcut buttons on the shop screen this product sits
/// behind, if any.
class _QuickTagPicker extends StatelessWidget {
  const _QuickTagPicker({required this.controller});

  final AdminProductsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tag = controller.formQuickTag.value;

      return Wrap(
        spacing: 8.w,
        children: [
          for (final option in <String?>[null, 'tea', 'smoke'])
            ChoiceChip(
              label: Text(
                option ?? 'None',
                style: GoogleFonts.openSans(
                  fontWeight: FontWeight.w700,
                  color: tag == option ? Colors.white : AdminColors.ink,
                ),
              ),
              selected: tag == option,
              selectedColor: AdminColors.green,
              backgroundColor: Colors.white,
              onSelected: (_) => controller.formQuickTag.value = option,
            ),
        ],
      );
    });
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: GoogleFonts.openSans(
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF374B41),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      style: GoogleFonts.openSans(
        fontSize: 16.sp,
        color: const Color(0xFF23332B),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.openSans(
          color: const Color(0xFF9AA49A),
          fontSize: 16.sp,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Color(0xFFBFD6C6), width: 1.2.w),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Color(0xFFBFD6C6), width: 1.2.w),
        ),
      ),
    );
  }
}
