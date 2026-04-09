import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart' hide isNull, isNotNull;

import 'package:cgs_photos/database/database.dart';
import 'package:cgs_photos/database/daos/photo_dao.dart';

void main() {
  late AppDatabase db;
  late PhotoDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = PhotoDao(db);
  });

  tearDown(() => db.close());

  PhotosTableCompanion _samplePhoto({
    required String uid,
    String exifKey = 'exif-key-1',
    int? dateTaken,
  }) {
    return PhotosTableCompanion(
      imageUid: Value(uid),
      exifKey: Value(exifKey),
      userId: Value('user-1'),
      blurhash: Value('LEHV6nWB2yk8pyo0adR*.7kCMdnj'),
      firestoreDocId: Value('doc-$uid'),
      lastSyncedAt: Value(dateTaken ?? 1700000000),
      dateTaken: Value(dateTaken ?? 1700000000),
    );
  }

  group('PhotoDao', () {
    test('insertPhoto and getPhotoByUid round-trips correctly', () async {
      await dao.insertPhoto(_samplePhoto(uid: 'abc123'));

      final result = await dao.getPhotoByUid('abc123');
      expect(result, isNotNull);
      expect(result!.imageUid, equals('abc123'));
      expect(result.userId, equals('user-1'));
    });

    test('getPhotoByUid returns null for non-existent uid', () async {
      final result = await dao.getPhotoByUid('does-not-exist');
      expect(result, isNull);
    });

    test('getPhotoByExifKey finds by EXIF composite key', () async {
      await dao.insertPhoto(_samplePhoto(uid: 'uid-1', exifKey: 'exif-abc'));

      final result = await dao.getPhotoByExifKey('exif-abc');
      expect(result, isNotNull);
      expect(result!.imageUid, equals('uid-1'));
    });

    test('insertPhotoBatch inserts multiple photos', () async {
      final entries = List.generate(
        10,
        (i) => _samplePhoto(uid: 'batch-$i', dateTaken: 1700000000 + i),
      );

      await dao.insertPhotoBatch(entries, batchSize: 3);

      final stream = dao.watchPhotos();
      final photos = await stream.first;
      expect(photos, hasLength(10));
    });

    test('watchPhotos streams photos ordered by dateTaken DESC', () async {
      await dao.insertPhoto(_samplePhoto(uid: 'old', dateTaken: 1000));
      await dao.insertPhoto(_samplePhoto(uid: 'new', dateTaken: 2000));

      final photos = await dao.watchPhotos().first;
      expect(photos.first.imageUid, equals('new'));
      expect(photos.last.imageUid, equals('old'));
    });

    test('updateBackupStatus updates the correct photo', () async {
      await dao.insertPhoto(_samplePhoto(uid: 'photo-1'));

      await dao.updateBackupStatus('photo-1', 'uploaded');

      final photo = await dao.getPhotoByUid('photo-1');
      expect(photo!.backupStatus, equals('uploaded'));
    });
  });
}
