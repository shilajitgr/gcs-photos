import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/upload_provider.dart';

class UploadScreen extends ConsumerWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(uploadProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload'),
        actions: [
          if (uploadState.tasks.isNotEmpty)
            TextButton(
              onPressed: () =>
                  ref.read(uploadProvider.notifier).clearFinished(),
              child: const Text('Clear finished'),
            ),
        ],
      ),
      body: uploadState.tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  const Text('No uploads in progress'),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () {
                      // TODO: Launch photo picker and enqueue uploads.
                    },
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Select Photos'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: uploadState.tasks.length,
              itemBuilder: (context, index) {
                final task = uploadState.tasks[index];
                return ListTile(
                  leading: _statusIcon(task.status, theme),
                  title: Text(
                    task.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: task.status == UploadTaskStatus.uploading
                      ? LinearProgressIndicator(value: task.progress)
                      : Text(task.status.name),
                  trailing: task.error != null
                      ? Tooltip(
                          message: task.error!,
                          child: Icon(
                            Icons.error_outline,
                            color: theme.colorScheme.error,
                          ),
                        )
                      : null,
                );
              },
            ),
    );
  }

  Widget _statusIcon(UploadTaskStatus status, ThemeData theme) {
    switch (status) {
      case UploadTaskStatus.pending:
        return const Icon(Icons.hourglass_empty);
      case UploadTaskStatus.uploading:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case UploadTaskStatus.completed:
        return Icon(Icons.check_circle, color: theme.colorScheme.primary);
      case UploadTaskStatus.failed:
        return Icon(Icons.error, color: theme.colorScheme.error);
    }
  }
}
