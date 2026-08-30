import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../utils/app_color.dart';
import '../utils/custom_cache_manager.dart';

/// Every remote image goes through here - one place for the cache manager,
/// the placeholder and the error fallback.
class ImageLoader extends StatelessWidget {
  final String url;
  final double? width, height, radius, size, padding;
  final BoxFit? boxFit;
  final Color? bgColor;

  const ImageLoader({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.boxFit,
    this.radius,
    this.bgColor,
    this.size,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? 0),
      child: Container(
        color: bgColor,
        padding: EdgeInsets.all(padding ?? 0),
        child: CachedNetworkImage(
          imageUrl: url,
          cacheManager: CustomCacheManager.instance,
          fit: boxFit ?? BoxFit.cover,
          width: size ?? width,
          height: size ?? height,
          placeholder: (context, url) => Container(
            width: size ?? width,
            height: size ?? height,
            color: bgColor ?? AppColor.whiteColor1,
          ),
          errorListener: (_) {},
          errorWidget: (context, url, error) => Container(
            width: size ?? width,
            height: size ?? height,
            color: bgColor ?? AppColor.whiteColor1,
            alignment: Alignment.center,
            child: Icon(
              Icons.broken_image_outlined,
              color: AppColor.grayColor2,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
