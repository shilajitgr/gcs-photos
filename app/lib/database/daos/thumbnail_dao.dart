import 'package:drift/drift.dart';

import '../../config/app_config.dart';
import '../database.dart';
import '../tables/thumbnail_cache.dart';

part 'thumbnail_dao.g.dart';

@DriftAccessor(tables: [ThumbnailCacheTable])
class ThumbnailDao extends DatabaseAccessor<AppDatabase>
    with _$ThumbnailDaoMixin {
  ThumbnailDao(super.db);

  /// Retrieve a cached thumbnail by its content hash.
  Future<ThumbnailCacheTableData?> getCachedThumbnail(String hash) {
    return (select(thumbnailCacheTable)
          ..where((t) => t.thumbHash.equals(hash)))
        .getSingleOrNull();
  }

  /// Cache a thumbnail and trigger LRU eviction if needed.
  Future<void> cacheThumbnail({
    required String hash,
    required String size,
    required Uint8List data,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await into(thumbnailCacheTable).insertOnConflictUpdate(
      ThumbnailCacheTableCompanion(
        thumbHash: Value(hash),
        thumbSize: Value(size),
        imageData: Value(data),
        cachedAt: Value(now),
        lastAccessed: Value(now),
        byteSize: Value(data.lengthInBytes),
      ),
    );
    await evictLRU();
  }

  /// Update [lastAccessed] timestamp when a thumbnail is displayed.
  Future<void> updateLastAccessed(String hash) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (update(thumbnailCacheTable)
          ..where((t) => t.thumbHash.equals(hash)))
        .write(ThumbnailCacheTableCompanion(lastAccessed: Value(now)));
  }

  /// Evict least-recently-accessed thumbnails until total cache size
  /// is at or below [maxBytes] (default 500 MB).
  Future<void> evictLRU({
    int maxBytes = AppConfig.maxThumbnailCacheBytes,
  }) async {
    final totalSizeQuery = thumbnailCacheTable.byteSize.sum();
    final totalResult = await (selectOnly(thumbnailCacheTable)
          ..addColumns([totalSizeQuery]))
        .getSingle();
    var currentSize = totalResult.read(totalSizeQuery) ?? 0;

    if (currentSize <= maxBytes) return;

    // Fetch entries ordered by lastAccessed ascending (oldest first).
    final entries = await (select(thumbnailCacheTable)
          ..orderBy([(t) => OrderingTerm.asc(t.lastAccessed)]))
        .get();

    for (final entry in entries) {
      if (currentSize <= maxBytes) break;
      await (delete(thumbnailCacheTable)
            ..where((t) => t.thumbHash.equals(entry.thumbHash)))
          .go();
      currentSize -= entry.byteSize;
    }
  }
}
