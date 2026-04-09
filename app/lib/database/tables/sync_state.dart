import 'package:drift/drift.dart';

/// Drift table for tracking Firestore sync resume tokens per user.
class SyncStateTable extends Table {
  @override
  String get tableName => 'sync_state';

  /// Firebase Auth UID.
  TextColumn get userId => text()();

  /// Firestore snapshot listener resume token (opaque string).
  TextColumn get lastSyncToken => text().nullable()();

  /// Unix timestamp (seconds) of the last completed full sync.
  IntColumn get lastFullSync => integer().nullable()();

  /// Running count of documents synced in the current session.
  IntColumn get totalSynced =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {userId};
}
