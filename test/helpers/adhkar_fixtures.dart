import 'dart:async';

import 'package:mre_quran/features/adhkar/data/adhkar_progress_repository.dart';
import 'package:mre_quran/features/adhkar/data/adhkar_source.dart';
import 'package:mre_quran/features/adhkar/data/reminder_scheduler.dart';
import 'package:mre_quran/features/adhkar/data/reminders_repository.dart';
import 'package:mre_quran/features/adhkar/domain/adhkar_collection.dart';
import 'package:mre_quran/features/adhkar/domain/adhkar_progress.dart';
import 'package:mre_quran/features/adhkar/domain/dhikr.dart';
import 'package:mre_quran/features/adhkar/domain/reminder_setting.dart';

/// A dhikr with the given repeat count and a source.
Dhikr dhikr(int order, {int repeat = 1, int variant = 0, String? virtue}) =>
    Dhikr(
      order: order,
      text: 'ذكر $order',
      repeat: repeat,
      repeatLabel: 'مرة',
      source: 'المصدر $order',
      variant: variant,
      virtue: virtue,
    );

/// Two small collections: morning at 05:30 and evening at 17:30.
AdhkarCatalog fixtureCatalog() => AdhkarCatalog([
  AdhkarCollection(
    id: 'morning',
    titles: const {'ar': 'أذكار الصباح', 'en': 'Morning adhkar'},
    icon: AdhkarIcon.sunrise,
    reminderMinutes: 330,
    entries: [
      dhikr(1, virtue: 'فضل'),
      dhikr(2, repeat: 3),
    ],
  ),
  AdhkarCollection(
    id: 'evening',
    titles: const {'ar': 'أذكار المساء', 'en': 'Evening adhkar'},
    icon: AdhkarIcon.sunset,
    reminderMinutes: 1050,
    entries: [dhikr(1), dhikr(2, repeat: 2)],
  ),
]);

/// Serves [fixtureCatalog] without touching assets.
class FakeAdhkarSource extends AdhkarSource {
  FakeAdhkarSource([AdhkarCatalog? catalog])
    : _catalog = catalog ?? fixtureCatalog();

  final AdhkarCatalog _catalog;

  @override
  Future<AdhkarCatalog> load() async => _catalog;
}

class MemoryAdhkarProgressRepository implements AdhkarProgressRepository {
  AdhkarProgress? saved;
  bool fail = false;

  @override
  Future<AdhkarProgress> load(String day) async =>
      saved != null && saved!.day == day ? saved! : AdhkarProgress(day: day);

  @override
  Future<void> save(AdhkarProgress progress) async {
    if (fail) throw StateError('Storage unavailable');
    saved = progress;
  }
}

class MemoryRemindersRepository implements RemindersRepository {
  Map<String, ReminderSetting> saved = {};
  bool fail = false;

  @override
  Future<Map<String, ReminderSetting>> load() async => saved;

  @override
  Future<void> save(Map<String, ReminderSetting> settings) async {
    if (fail) throw StateError('Storage unavailable');
    saved = settings;
  }
}

/// Records what would be scheduled.
class FakeReminderScheduler implements ReminderScheduler {
  FakeReminderScheduler({this.allow = true, this.launch});

  bool allow;
  int permissionRequests = 0;
  final Map<int, ({int minutes, String title, String body, String payload})>
  scheduled = {};
  final StreamController<String> tapController = StreamController.broadcast();

  final String? launch;

  @override
  String? get launchPayload => launch;

  @override
  Stream<String> get taps => tapController.stream;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return allow;
  }

  @override
  Future<void> schedule({
    required int id,
    required int minutes,
    required String title,
    required String body,
    required String channelName,
    required String payload,
  }) async {
    scheduled[id] = (
      minutes: minutes,
      title: title,
      body: body,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) async => scheduled.remove(id);
}
