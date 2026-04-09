import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Possible sync states.
enum SyncStatus {
  idle,
  syncing,
  error,
}

/// Immutable sync state.
class SyncState {
  final SyncStatus status;
  final int totalSynced;
  final String? error;

  const SyncState({
    this.status = SyncStatus.idle,
    this.totalSynced = 0,
    this.error,
  });

  SyncState copyWith({
    SyncStatus? status,
    int? totalSynced,
    String? error,
  }) {
    return SyncState(
      status: status ?? this.status,
      totalSynced: totalSynced ?? this.totalSynced,
      error: error,
    );
  }
}

/// Manages sync lifecycle state.
class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier() : super(const SyncState());

  void startSync() {
    state = state.copyWith(status: SyncStatus.syncing, error: null);
  }

  void syncCompleted(int total) {
    state = state.copyWith(
      status: SyncStatus.idle,
      totalSynced: total,
    );
  }

  void syncError(String message) {
    state = state.copyWith(
      status: SyncStatus.error,
      error: message,
    );
  }
}

/// Sync state provider.
final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier();
});
