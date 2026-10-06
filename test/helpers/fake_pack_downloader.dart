import 'dart:async';

import 'package:mre_quran/features/mushaf/data/pack_downloader.dart';

/// A downloader that records what it is asked and reports what the test says.
class FakePackDownloader implements PackDownloader {
  final StreamController<PackFileResult> _results =
      StreamController.broadcast();

  /// Files per group, as enqueued.
  final Map<String, List<PackFile>> enqueued = {};

  /// Texts per group.
  final Map<String, PackNotificationText> texts = {};

  /// Files still running, per group.
  final Map<String, int> running = {};

  /// How often notifications were asked for.
  int notificationRequests = 0;

  /// Cancelled groups.
  final List<String> cancelled = [];

  /// Reports that [path] of [group] ended.
  void finish(String group, String path, {bool ok = true}) {
    running[group] = (running[group] ?? 1) - 1;
    _results.add((group: group, path: path, ok: ok));
  }

  @override
  Stream<PackFileResult> get results => _results.stream;

  @override
  Future<void> requestNotifications() async => notificationRequests++;

  @override
  Future<void> enqueue(
    String group,
    Iterable<PackFile> files,
    PackNotificationText text,
  ) async {
    enqueued[group] = files.toList();
    texts[group] = text;
    running[group] = enqueued[group]!.length;
  }

  @override
  Future<int> pending(String group) async => running[group] ?? 0;

  @override
  Future<void> cancel(String group) async {
    cancelled.add(group);
    running[group] = 0;
  }
}
