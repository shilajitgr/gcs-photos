import 'package:drift/drift.dart';

/// Drift table definition for [photos]. Matches the architecture DDL.
class PhotosTable extends Table {
  @override
  String get tableName => 'photos';

  /// SHA-256 of the original file bytes.
  TextColumn get imageUid => text()();

  /// Composite EXIF key for fuzzy dedup.
  TextColumn get exifKey => text()();

  /// Owner user ID (Firebase Auth UID).
  TextColumn get userId => text()();

  /// Full GCS object path, e.g. `originals/<uid>.avif`.
  TextColumn get filePathGcs => text().nullable()();

  /// Original file name from device.
  TextColumn get fileName => text().nullable()();

  /// File size in bytes.
  IntColumn get fileSize => integer().nullable()();

  /// MIME type (e.g. image/avif, image/jpeg).
  TextColumn get mimeType => text().nullable()();

  /// Image width in pixels.
  IntColumn get width => integer().nullable()();

  /// Image height in pixels.
  IntColumn get height => integer().nullable()();

  /// Date the photo was taken (unix timestamp, seconds).
  IntColumn get dateTaken => integer().nullable()();

  /// Camera manufacturer from EXIF.
  TextColumn get cameraMake => text().nullable()();

  /// Camera model from EXIF.
  TextColumn get cameraModel => text().nullable()();

  /// ISO speed from EXIF.
  IntColumn get iso => integer().nullable()();

  /// Aperture (f-number) from EXIF.
  RealColumn get aperture => real().nullable()();

  /// Shutter speed string from EXIF (e.g. "1/250").
  TextColumn get shutterSpeed => text().nullable()();

  /// Focal length in mm from EXIF.
  RealColumn get focalLength => real().nullable()();

  /// GPS latitude from EXIF.
  RealColumn get latitude => real().nullable()();

  /// GPS longitude from EXIF.
  RealColumn get longitude => real().nullable()();

  /// BlurHash string for progressive placeholder rendering.
  TextColumn get blurhash => text()();

  /// Content hash for the small thumbnail (200px AVIF).
  TextColumn get thumbSmHash => text().nullable()();

  /// Content hash for the medium thumbnail (600px AVIF).
  TextColumn get thumbMdHash => text().nullable()();

  /// Content hash for the large thumbnail (1200px AVIF).
  TextColumn get thumbLgHash => text().nullable()();

  /// GCS storage class (STANDARD, NEARLINE, COLDLINE, ARCHIVE).
  TextColumn get storageClass =>
      text().withDefault(const Constant('STANDARD'))();

  /// Lifecycle rule name, if any.
  TextColumn get lifecycleRule => text().nullable()();

  /// Corresponding Firestore document ID.
  TextColumn get firestoreDocId => text()();

  /// Timestamp of last successful sync (unix seconds).
  IntColumn get lastSyncedAt => integer()();

  /// Monotonic sync version for conflict detection.
  IntColumn get syncVersion =>
      integer().withDefault(const Constant(0))();

  /// Backup status: pending | uploading | uploaded | failed.
  TextColumn get backupStatus =>
      text().withDefault(const Constant('pending'))();

  /// Device identifier that originated this photo.
  TextColumn get deviceOrigin => text().nullable()();

  @override
  Set<Column> get primaryKey => {imageUid};
}
