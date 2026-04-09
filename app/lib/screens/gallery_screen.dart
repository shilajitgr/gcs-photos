import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/photos_provider.dart';
import '../providers/sync_provider.dart';
import '../widgets/photo_grid.dart';
import '../widgets/sync_status_bar.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  Future<void> _onRefresh(WidgetRef ref) async {
    // Trigger a sync; the actual sync logic is in SyncService.
    ref.read(syncProvider.notifier).startSync();
    // In a real implementation this would await the sync service.
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(photosProvider);
    final syncState = ref.watch(syncProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CGS Photos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined),
            tooltip: 'Upload',
            onPressed: () => context.push('/upload'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (syncState.status == SyncStatus.syncing)
            const SyncStatusBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _onRefresh(ref),
              child: photosAsync.when(
                data: (photos) {
                  if (photos.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text('No photos yet'),
                          SizedBox(height: 8),
                          Text('Pull down to sync or tap upload'),
                        ],
                      ),
                    );
                  }
                  return PhotoGrid(
                    photos: photos,
                    onPhotoTap: (photo) {
                      context.push('/photo/${photo.imageUid}');
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Text('Error loading photos: $error'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
