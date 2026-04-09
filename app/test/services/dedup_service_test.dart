import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cgs_photos/database/database.dart';
import 'package:cgs_photos/database/daos/photo_dao.dart';
import 'package:cgs_photos/services/dedup_service.dart';

void main() {
  late AppDatabase db;
  late PhotoDao photoDao;
  late DedupService dedupService;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    photoDao = PhotoDao(db);
    dedupService = DedupService(photoDao: photoDao);
  });

  tearDown(() => db.close());

  group('DedupService', () {
    test('computeExifKey produces a deterministic SHA-256', () {
      final key1 = dedupService.computeExifKey(
        cameraMake: 'Canon',
        cameraModel: 'EOS R5',
        dateTime: '2024-01-15T10:30:00',
        width: 8192,
        height: 5464,
        fileSize: 15000000,
      );
      final key2 = dedupService.computeExifKey(
        cameraMake: 'Canon',
        cameraModel: 'EOS R5',
        dateTime: '2024-01-15T10:30:00',
        width: 8192,
        height: 5464,
        fileSize: 15000000,
      );

      expect(key1, equals(key2));
      expect(key1.length, equals(64)); // SHA-256 hex string length
    });

    test('computeExifKey differs when any field changes', () {
      final key1 = dedupService.computeExifKey(
        cameraMake: 'Canon',
        cameraModel: 'EOS R5',
        dateTime: '2024-01-15T10:30:00',
        width: 8192,
        height: 5464,
        fileSize: 15000000,
      );
      final key2 = dedupService.computeExifKey(
        cameraMake: 'Nikon',
        cameraModel: 'EOS R5',
        dateTime: '2024-01-15T10:30:00',
        width: 8192,
        height: 5464,
        fileSize: 15000000,
      );

      expect(key1, isNot(equals(key2)));
    });

    test('computeExifKey handles null fields gracefully', () {
      final key = dedupService.computeExifKey(
        cameraMake: null,
        cameraModel: null,
        dateTime: null,
        width: null,
        height: null,
        fileSize: null,
      );

      // Should still produce a valid 64-char hex hash.
      expect(key.length, equals(64));
    });

    test('checkDuplicate returns unique when DB is empty', () async {
      final result = await dedupService.checkDuplicate(
        contentHash: 'abc123',
        exifKey: 'exif-xyz',
      );
      expect(result, equals(DedupResult.unique));
    });

    test('checkDuplicate returns exactDuplicate on content hash match',
        () async {
      await photoDao.insertPhoto(PhotosTableCompanion(
        imageUid: const Value('sha256-match'),
        exifKey: const Value('exif-1'),
        userId: const Value('user-1'),
        blurhash: const Value('LEHV6nWB2yk8pyo0adR*.7kCMdnj'),
        firestoreDocId: const Value('doc-1'),
        lastSyncedAt: Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
      ));

      final result = await dedupService.checkDuplicate(
        contentHash: 'sha256-match',
        exifKey: 'different-exif',
      );
      expect(result, equals(DedupResult.exactDuplicate));
    });

    test('checkDuplicate returns potentialDuplicate on EXIF key match',
        () async {
      await photoDao.insertPhoto(PhotosTableCompanion(
        imageUid: const Value('different-hash'),
        exifKey: const Value('exif-match'),
        userId: const Value('user-1'),
        blurhash: const Value('LEHV6nWB2yk8pyo0adR*.7kCMdnj'),
        firestoreDocId: const Value('doc-1'),
        lastSyncedAt: Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
      ));

      final result = await dedupService.checkDuplicate(
        contentHash: 'unique-hash',
        exifKey: 'exif-match',
      );
      expect(result, equals(DedupResult.potentialDuplicate));
    });
  });
}
