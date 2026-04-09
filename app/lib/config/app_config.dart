/// Application-wide configuration constants.
abstract final class AppConfig {
  /// Base URL for the Cloud Run API.
  static const String apiBaseUrl = 'https://api.cgsphotos.example.com';

  /// Maximum thumbnail cache size in bytes (500 MB).
  static const int maxThumbnailCacheBytes = 500 * 1024 * 1024;

  /// Batch size for bulk photo inserts into SQLite.
  static const int photoBatchInsertSize = 500;

  /// Page size for paginated sync requests.
  static const int syncPageSize = 200;

  /// Thumbnail size variants.
  static const String thumbSm = 'sm';
  static const String thumbMd = 'md';
  static const String thumbLg = 'lg';
  static const String thumbXl = 'xl';

  /// Thumbnail pixel dimensions.
  static const int thumbSmPx = 200;
  static const int thumbMdPx = 600;
  static const int thumbLgPx = 1200;

  /// Default storage class for new uploads.
  static const String defaultStorageClass = 'STANDARD';
}
