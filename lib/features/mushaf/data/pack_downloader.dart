import 'package:background_downloader/background_downloader.dart';
import 'package:meta/meta.dart';

/// One file to download: where from, and where it goes under the Mushaf
/// folder of the app support directory.
typedef PackFile = ({Uri url, String path});

/// How far one file of a download has come, 0–1.
typedef PackTransfer = ({String group, String path, double fraction});

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
    required this.pausedTitle,
    required this.pausedBody,
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

  /// Shown while the person has paused the download from its notification.
  final String pausedTitle;

  /// See [pausedTitle].
  final String pausedBody;
}

/// Downloads sets of files that keep going when the app is closed.
///
/// Tests replace it, as the real one needs the platform.
abstract interface class PackDownloader {
  /// Every file that ends, as it ends.
  Stream<PackFileResult> get results;

  /// How far each running file has come, as it moves.
  Stream<PackTransfer> get transfers;

  /// Asks the person for permission to show the download's notification, if
  /// the platform wants it. Called when a download starts, never at launch.
  Future<void> requestNotifications();

  /// Starts downloading [files] as one [group]. Each file shows its own
  /// notification with a progress bar and buttons to pause and to cancel.
  Future<void> enqueue(
    String group,
    Iterable<PackFile> files,
    PackNotificationText text,
  );

  /// Collects what finished while the app was away. Called whenever the app
  /// comes back to the front.
  Future<void> resume();

  /// How many files of [group] are waiting or running.
  Future<int> pending(String group);

  /// Stops [group].
  Future<void> cancel(String group);
}

/// The platform downloader: a background `URLSession` on iOS, WorkManager on
/// Android. The system keeps the downloads going after the app is closed or
/// swiped away. On Android a large file runs as a foreground service, which
/// lifts WorkManager's nine-minute limit.
class BackgroundPackDownloader implements PackDownloader {
  /// Creates the downloader.
  BackgroundPackDownloader();

  final FileDownloader _downloader = FileDownloader();
  Future<void>? _configured;

  /// The folder the files go under, inside the app support directory.
  static const String _folder = 'mushaf';

  /// Files above this size, in megabytes, download as a foreground service.
  static const int _foregroundAboveMb = 5;

  Future<void> _configure() => _configured ??= () async {
    await _downloader.configure(
      globalConfig: [
        (Config.runInForegroundIfFileLargerThan, _foregroundAboveMb),
        // The pages can be downloaded again, so they stay out of the iCloud
        // backup on iOS.
        (Config.excludeFromCloudBackup, true),
      ],
    );
    await _downloader.resumeFromBackground();
  }();

  @override
  Future<void> resume() async {
    await _configure();
    await _downloader.resumeFromBackground();
  }

  static String _path(Task task) =>
      '${task.directory.replaceFirst('$_folder/', '')}/${task.filename}';

  /// Every update of every download. The plugin's own stream takes one
  /// listener for good, and this class hands out two views of it that are
  /// listened to again each time the pack's state is read afresh; so it is
  /// listened to once here and shared.
  late final Stream<TaskUpdate> _updates = _downloader.updates
      .asBroadcastStream();

  @override
  Stream<PackFileResult> get results => _updates
      .where((update) => update is TaskStatusUpdate)
      .cast<TaskStatusUpdate>()
      .where((update) => update.status.isFinalState)
      .map(
        (update) => (
          group: update.task.group,
          path: _path(update.task),
          ok: update.status == TaskStatus.complete,
        ),
      );

  @override
  Stream<PackTransfer> get transfers => _updates
      .where((update) => update is TaskProgressUpdate)
      .cast<TaskProgressUpdate>()
      // Negative values are the downloader's codes for failed or paused.
      .where((update) => update.progress >= 0)
      .map(
        (update) => (
          group: update.task.group,
          path: _path(update.task),
          fraction: update.progress,
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
    // A download paused from its notification is still on the books; drop
    // it, so the same file is never fetched twice at once.
    await _downloader.cancelAll(group: group);
    // No group notification: each file's own notification carries the
    // Cancel and Pause buttons, which a group notification cannot.
    _downloader.configureNotificationForGroup(
      group,
      running: TaskNotification(text.runningTitle, text.runningBody),
      complete: TaskNotification(text.completeTitle, text.completeBody),
      error: TaskNotification(text.errorTitle, text.errorBody),
      paused: TaskNotification(text.pausedTitle, text.pausedBody),
      progressBar: true,
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
          updates: Updates.statusAndProgress,
          allowPause: true,
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
