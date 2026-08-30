import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Network images live on disk for 30 days instead of flutter_cache_manager's
/// 7-day default – icons and banners rarely change and re-downloading them on
/// every cold start is wasted bandwidth.
class CustomCacheManager extends CacheManager {
  static const key = 'customCache';

  static CacheManager instance = CustomCacheManager._();

  CustomCacheManager._()
    : super(
        Config(
          key,
          stalePeriod: const Duration(days: 30),
          maxNrOfCacheObjects: 1000,
        ),
      );
}
