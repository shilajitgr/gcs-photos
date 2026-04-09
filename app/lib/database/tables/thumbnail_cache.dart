import 'package:drift/drift.dart';

/// Drift table definition for the local thumbnail cache.
///
/// Thumbnails are LRU-evicted when total size exceeds 500 MB.
class ThumbnailCacheTable extends Table {
  @override
  String get tableName => 'thumbnail_cache';

  /// Content-hash of the thumbnail (matches `thumb_{sm|md|lg|xl}Hash`).
  TextColumn get thumbHash => text()();

  /// Size variant: sm | md | lg | xl.
  TextColumn get thumbSize => text()();

  /// Raw image bytes (AVIF or WebP).
  BlobColumn get imageData => blob()();

  /// Unix timestamp (seconds) when this entry was cached.
  IntColumn get cachedAt => integer()();

  /// Unix timestamp (seconds) of last access (for LRU eviction).
  IntColumn get lastAccessed => integer()();

  /// Size of [imageData] in bytes, stored for fast cache-size queries.
  IntColumn get byteSize => integer()();

  @override
  Set<Column> get primaryKey => {thumbHash};
}
