import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'daos/photo_dao.dart';
import 'daos/sync_dao.dart';
import 'daos/thumbnail_dao.dart';
import 'tables/photos.dart';
import 'tables/sync_state.dart';
import 'tables/thumbnail_cache.dart';

part 'database.g.dart';

const _passphraseKey = 'db_passphrase';

@DriftDatabase(
  tables: [PhotosTable, ThumbnailCacheTable, SyncStateTable],
  daos: [PhotoDao, ThumbnailDao, SyncDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor that accepts a custom [QueryExecutor], useful for testing.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'cgs_photos.sqlite'));

    const storage = FlutterSecureStorage();
    var passphrase = await storage.read(key: _passphraseKey);
    if (passphrase == null) {
      passphrase = _generatePassphrase();
      await storage.write(key: _passphraseKey, value: passphrase);
    }

    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        // SQLCipher requires the key pragma before any other statement.
        db.execute("PRAGMA key = '$passphrase'");
      },
    );
  });
}

String _generatePassphrase() {
  const chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final rng = Random.secure();
  return List.generate(32, (_) => chars[rng.nextInt(chars.length)]).join();
}
