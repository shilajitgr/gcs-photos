import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/photos.dart';

part 'photo_dao.g.dart';

@DriftAccessor(tables: [PhotosTable])
class PhotoDao extends DatabaseAccessor<AppDatabase> with _$PhotoDaoMixin {
  PhotoDao(super.db);

  /// Watch all photos ordered by [dateTaken] descending (newest first).
  Stream<List<PhotosTableData>> watchPhotos() {
    return (select(photosTable)
          ..orderBy([
            (t) => OrderingTerm.desc(t.dateTaken),
          ]))
        .watch();
  }

  /// Get a single photo by its content-hash UID.
  Future<PhotosTableData?> getPhotoByUid(String uid) {
    return (select(photosTable)..where((t) => t.imageUid.equals(uid)))
        .getSingleOrNull();
  }

  /// Get a photo by its EXIF composite key (for fuzzy dedup).
  Future<PhotosTableData?> getPhotoByExifKey(String exifKey) {
    return (select(photosTable)..where((t) => t.exifKey.equals(exifKey)))
        .getSingleOrNull();
  }

  /// Insert a single photo (or replace on conflict).
  Future<void> insertPhoto(PhotosTableCompanion entry) {
    return into(photosTable).insertOnConflictUpdate(entry);
  }

  /// Batch-insert photos in chunks of [batchSize].
  Future<void> insertPhotoBatch(
    List<PhotosTableCompanion> entries, {
    int batchSize = 500,
  }) async {
    for (var i = 0; i < entries.length; i += batchSize) {
      final chunk = entries.sublist(
        i,
        i + batchSize > entries.length ? entries.length : i + batchSize,
      );
      await batch((b) {
        b.insertAllOnConflictUpdate(photosTable, chunk);
      });
    }
  }

  /// Update the backup status for a given photo.
  Future<void> updateBackupStatus(String imageUid, String status) {
    return (update(photosTable)
          ..where((t) => t.imageUid.equals(imageUid)))
        .write(PhotosTableCompanion(backupStatus: Value(status)));
  }
}
