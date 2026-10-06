import 'package:background_downloader/background_downloader.dart';
import 'package:meta/meta.dart';

/// One file to download: where from, and where it goes under the Mushaf
/// folder of the app support directory.
typedef PackFile = ({Uri url, String path});

/// How one file of a download ended.
typedef PackFileResult = ({String group, String path, bool ok});

/// The words of a download's notification.
@immutable
class PackNotificationText {
  /// Creates the texts. `{progress}` stands for the percentage done.
  const PackNotificationText({
    required this.runningTitle,
    required this.runningBody,
    required this.completeTitle,
    required this.completeBody,
    required this.errorTitle,
    required this.errorBody,
  });

  /// Shown while files download.
  final String runningTitle;

  /// See [runningTitle]; may use `{progress}`.
  final String runningBody;

  /// Shown when every file arrived.
  final String completeTitle;

  /// See [completeTitle].
  final String completeBody;

  /// Shown when a file could not be fetched.
  final String errorTitle;

  /// See [errorTitle].
  final String errorBody;
}

/// Downloads sets of files that keep going when the app is closed.
///
/// Tests replace it, as the real one needs the platform.
abstract interface class PackDownloader {
  /// Every file that ends, as it ends.
  Stream<PackFileResult> get results;

  /// Asks the person for permission to show the download's notification, if
  /// the platform wants it. Called when a download starts, never at launch.
  Future<void> requestNotifications();

  /// Starts downloading [files] as one [group], with one notification.
  Future<void> enqueue(
    String group,
    Iterable<PackFile> files,
    PackNotificationText text,
  );

  /// How many files of [group] are waiting or running.
  Future<int> pending(String group);

  /// Stops [group].
  Future<void> cancel(String group);
}

/// The platform downloader: a background `URLSession` on iOS, WorkManager on
/// Android. The system keeps the downloads going after the app is closed,
/// and shows one progress notification for the group.
class BackgroundPackDownloader implements PackDownloader {
  /// Creates the downloader.
  BackgroundPackDownloader();

  final FileDownloader _downloader = FileDownloader();
  Future<void>? _configured;

  /// The folder the files go under, inside the app support directory.
  static const String _folder = 'mushaf';

  Future<void> _configure() => _configured ??= () async {
    await _downloader.configure(
      globalConfig: [
        // A few files at a time, queued natively so the queue keeps going
        // while the app is suspended.
        (Config.holdingQueue, (4, null, null)),
      ],
    );
    await _downloader.resumeFromBackground();
  }();

  @override
  Stream<PackFileResult> get results => _downloader.updates
      .where((update) => update is TaskStatusUpdate)
      .cast<TaskStatusUpdate>()
      .where((update) => update.status.isFinalState)
      .map(
        (update) => (
          group: update.task.group,
          path:
              '${update.task.directory.replaceFirst('$_folder/', '')}/'
              '${update.task.filename}',
          ok: update.status == TaskStatus.complete,
        ),
      );

  @override
  Future<void> requestNotifications() async {
    final permissions = _downloader.permissions;
    const type = PermissionType.notifications;
    if (await permissions.status(type) != PermissionStatus.granted) {
      await permissions.request(type);
    }
  }

  @override
  Future<void> enqueue(
    String group,
    Iterable<PackFile> files,
    PackNotificationText text,
  ) async {
    await _configure();
    _downloader.configureNotificationForGroup(
      group,
      running: TaskNotification(text.runningTitle, text.runningBody),
      complete: TaskNotification(text.completeTitle, text.completeBody),
      error: TaskNotification(text.errorTitle, text.errorBody),
      progressBar: true,
      groupNotificationId: group,
    );
    await _downloader.enqueueAll([
      for (final file in files)
        DownloadTask(
          url: file.url.toString(),
          group: group,
          directory:
              '$_folder/${file.path.substring(0, file.path.lastIndexOf('/'))}',
          filename: file.path.substring(file.path.lastIndexOf('/') + 1),
          baseDirectory: BaseDirectory.applicationSupport,
          updates: Updates.status,
          retries: 3,
        ),
    ]);
  }

  @override
  Future<int> pending(String group) async {
    await _configure();
    return (await _downloader.allTasks(group: group)).length;
  }

  @override
  Future<void> cancel(String group) async {
    await _configure();
    await _downloader.cancelAll(group: group);
  }
}
