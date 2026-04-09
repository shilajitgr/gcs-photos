import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/sync_state.dart';

part 'sync_dao.g.dart';

@DriftAccessor(tables: [SyncStateTable])
class SyncDao extends DatabaseAccessor<AppDatabase> with _$SyncDaoMixin {
  SyncDao(super.db);

  /// Get the sync state for a given user.
  Future<SyncStateTableData?> getSyncState(String userId) {
    return (select(syncStateTable)
          ..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();
  }

  /// Upsert the sync state with a new resume token and timestamp.
  Future<void> updateSyncState({
    required String userId,
    String? token,
    int? timestamp,
    int? totalSynced,
  }) {
    return into(syncStateTable).insertOnConflictUpdate(
      SyncStateTableCompanion(
        userId: Value(userId),
        lastSyncToken: Value(token),
        lastFullSync: Value(timestamp),
        totalSynced: Value(totalSynced ?? 0),
      ),
    );
  }
}
