import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a single item in the upload queue.
class UploadTask {
  final String filePath;
  final String fileName;
  final double progress;
  final UploadTaskStatus status;
  final String? error;

  const UploadTask({
    required this.filePath,
    required this.fileName,
    this.progress = 0.0,
    this.status = UploadTaskStatus.pending,
    this.error,
  });

  UploadTask copyWith({
    double? progress,
    UploadTaskStatus? status,
    String? error,
  }) {
    return UploadTask(
      filePath: filePath,
      fileName: fileName,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      error: error,
    );
  }
}

enum UploadTaskStatus {
  pending,
  uploading,
  completed,
  failed,
}

/// Upload queue state.
class UploadState {
  final List<UploadTask> tasks;

  const UploadState({this.tasks = const []});

  int get pendingCount =>
      tasks.where((t) => t.status == UploadTaskStatus.pending).length;

  int get completedCount =>
      tasks.where((t) => t.status == UploadTaskStatus.completed).length;

  bool get hasActiveTasks =>
      tasks.any((t) =>
          t.status == UploadTaskStatus.pending ||
          t.status == UploadTaskStatus.uploading);
}

/// Manages the upload queue.
class UploadNotifier extends StateNotifier<UploadState> {
  UploadNotifier() : super(const UploadState());

  /// Enqueue files for upload.
  void enqueue(List<UploadTask> tasks) {
    state = UploadState(tasks: [...state.tasks, ...tasks]);
  }

  /// Update progress for a specific task by file path.
  void updateProgress(String filePath, double progress) {
    state = UploadState(
      tasks: state.tasks.map((t) {
        if (t.filePath == filePath) {
          return t.copyWith(
            progress: progress,
            status: UploadTaskStatus.uploading,
          );
        }
        return t;
      }).toList(),
    );
  }

  /// Mark a task as completed.
  void markCompleted(String filePath) {
    state = UploadState(
      tasks: state.tasks.map((t) {
        if (t.filePath == filePath) {
          return t.copyWith(
            progress: 1.0,
            status: UploadTaskStatus.completed,
          );
        }
        return t;
      }).toList(),
    );
  }

  /// Mark a task as failed.
  void markFailed(String filePath, String error) {
    state = UploadState(
      tasks: state.tasks.map((t) {
        if (t.filePath == filePath) {
          return t.copyWith(
            status: UploadTaskStatus.failed,
            error: error,
          );
        }
        return t;
      }).toList(),
    );
  }

  /// Clear completed and failed tasks from the queue.
  void clearFinished() {
    state = UploadState(
      tasks: state.tasks
          .where((t) =>
              t.status == UploadTaskStatus.pending ||
              t.status == UploadTaskStatus.uploading)
          .toList(),
    );
  }
}

/// Upload queue provider.
final uploadProvider =
    StateNotifierProvider<UploadNotifier, UploadState>((ref) {
  return UploadNotifier();
});
