import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'reminder_scheduler.dart';
import 'reminder_tap.dart';

/// Provides the device scheduler. `main` overrides it with the started plugin;
/// the default does nothing, which keeps tests off the platform.
final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => const _NoopReminderScheduler(),
);

/// Notifications tapped while the app runs, one event per tap.
final reminderTapsProvider = StreamProvider<ReminderTap>(
  (ref) => ref.watch(reminderSchedulerProvider).taps.map(ReminderTap.new),
);

class _NoopReminderScheduler implements ReminderScheduler {
  const _NoopReminderScheduler();

  @override
  String? get launchPayload => null;

  @override
  Stream<String> get taps => const Stream.empty();

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> schedule({
    required int id,
    required int minutes,
    required String title,
    required String body,
    required String channelName,
    required String payload,
  }) async {}

  @override
  Future<bool> canScheduleExact() async => true;

  @override
  Future<bool> requestExact() async => true;

  @override
  Future<void> scheduleOnce({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required ReminderChannel channel,
    required String channelName,
    required String payload,
    bool exact = false,
  }) async {}

  @override
  Future<void> cancel(int id) async {}
}
