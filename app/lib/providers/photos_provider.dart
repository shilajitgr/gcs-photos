import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../database/daos/photo_dao.dart';

/// Singleton database provider.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Photo DAO provider.
final photoDaoProvider = Provider<PhotoDao>((ref) {
  final db = ref.watch(databaseProvider);
  return PhotoDao(db);
});

/// Stream of all photos, ordered newest-first.
///
/// The UI rebuilds reactively when the underlying SQLite table changes.
final photosProvider = StreamProvider<List<PhotosTableData>>((ref) {
  final photoDao = ref.watch(photoDaoProvider);
  return photoDao.watchPhotos();
});
