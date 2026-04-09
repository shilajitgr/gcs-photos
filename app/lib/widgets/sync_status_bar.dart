import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/sync_provider.dart';

/// A thin status bar shown at the top of the gallery during sync.
class SyncStatusBar extends ConsumerWidget {
  const SyncStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    final theme = Theme.of(context);

    if (syncState.status == SyncStatus.idle) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: syncState.status == SyncStatus.error
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.primaryContainer,
      child: Row(
        children: [
          if (syncState.status == SyncStatus.syncing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          if (syncState.status == SyncStatus.error)
            Icon(
              Icons.error_outline,
              size: 16,
              color: theme.colorScheme.onErrorContainer,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              syncState.status == SyncStatus.error
                  ? 'Sync error: ${syncState.error ?? "Unknown"}'
                  : 'Syncing... (${syncState.totalSynced} photos)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: syncState.status == SyncStatus.error
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
