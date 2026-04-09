import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/photo_dao.dart';
import 'daos/sync_dao.dart';
import 'daos/thumbnail_dao.dart';
import 'tables/photos.dart';
import 'tables/sync_state.dart';
import 'tables/thumbnail_cache.dart';

part 'database.g.dart';

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
    return NativeDatabase.createInBackground(file);
  });
}
