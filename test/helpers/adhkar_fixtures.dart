import 'dart:async';

import 'package:mre_quran/core/haptics/haptics.dart';
import 'package:mre_quran/features/adhkar/data/adhkar_progress_repository.dart';
import 'package:mre_quran/features/adhkar/data/adhkar_source.dart';
import 'package:mre_quran/features/adhkar/data/favorites_repository.dart';
import 'package:mre_quran/features/prayer/data/location_source.dart';
import 'package:mre_quran/features/prayer/data/prayer_repository.dart';
import 'package:mre_quran/core/notifications/reminder_scheduler.dart';
import 'package:mre_quran/features/adhkar/data/reminders_repository.dart';
import 'package:mre_quran/features/adhkar/domain/adhkar_collection.dart';
import 'package:mre_quran/features/adhkar/domain/adhkar_progress.dart';
import 'package:mre_quran/features/adhkar/domain/dhikr.dart';
import 'package:mre_quran/features/prayer/domain/prayer_alerts.dart';
import 'package:mre_quran/features/prayer/domain/prayer_times.dart';
import 'package:mre_quran/features/adhkar/domain/quran_passage.dart';
import 'package:mre_quran/features/adhkar/domain/reminder_setting.dart';

/// The two groups the fixtures use.
const AdhkarGroup kDaily = AdhkarGroup(
  id: 'daily',
  titles: {'ar': 'الأذكار اليومية', 'en': 'Daily adhkar'},
  icon: AdhkarIcon.sunrise,
);

/// Prayer group.
const AdhkarGroup kPrayer = AdhkarGroup(
  id: 'prayer',
  titles: {'ar': 'الصلاة والمسجد', 'en': 'Prayer and the mosque'},
  icon: AdhkarIcon.prayer,
);

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
AdhkarCatalog fixtureCatalog() => AdhkarCatalog(
  [
    AdhkarCollection(
      id: 'morning',
      titles: const {'ar': 'أذكار الصباح', 'en': 'Morning adhkar'},
      icon: AdhkarIcon.sunrise,
      group: kDaily,
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
      group: kDaily,
      reminderMinutes: 1050,
      entries: [dhikr(1), dhikr(2, repeat: 2)],
    ),
  ],
  groups: [kDaily],
);

/// Morning and evening plus an after-prayer list that keeps its counts for
/// 30 minutes.
AdhkarCatalog fixtureCatalogWithPrayer() {
  final base = fixtureCatalog();
  return AdhkarCatalog(
    [
      ...base.collections,
      AdhkarCollection(
        id: 'after_prayer',
        titles: const {'ar': 'أذكار بعد الصلاة', 'en': 'After prayer'},
        icon: AdhkarIcon.generic,
        group: kPrayer,
        sessionWindowMinutes: 30,
        entries: [dhikr(1, repeat: 3), dhikr(2)],
      ),
      AdhkarCollection(
        id: 'sleep',
        titles: const {'ar': 'أذكار النوم', 'en': 'Sleep'},
        icon: AdhkarIcon.generic,
        group: kDaily,
        entries: [dhikr(1)],
      ),
    ],
    groups: [kDaily, kPrayer],
  );
}

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

  bool exactAllowed = true;
  int exactRequests = 0;
  final Map<
    int,
    ({
      DateTime at,
      String title,
      String body,
      String payload,
      ReminderChannel channel,
      bool exact,
    })
  >
  once = {};

  @override
  Future<bool> canScheduleExact() async => exactAllowed;

  @override
  Future<bool> requestExact() async {
    exactRequests++;
    return exactAllowed;
  }

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
  }) async {
    once[id] = (
      at: at,
      title: title,
      body: body,
      payload: payload,
      channel: channel,
      exact: exact,
    );
  }

  @override
  Future<void> cancel(int id) async {
    scheduled.remove(id);
    once.remove(id);
  }
}

/// One list with an ayah (with the isti'adha) and a plain dhikr.
AdhkarCatalog fixtureCatalogWithQuran() => AdhkarCatalog(
  [
    AdhkarCollection(
      id: 'kursi',
      titles: const {'ar': 'آية الكرسي', 'en': 'Ayat al-Kursi'},
      icon: AdhkarIcon.generic,
      group: kDaily,
      entries: [
        const Dhikr(
          order: 1,
          text: '',
          repeat: 1,
          repeatLabel: 'مرة',
          source: 'رواه النسائي',
          variant: 0,
          quran: QuranPassage(
            istiadha: true,
            spans: [AyahSpan(surah: 2, from: 255, to: 255)],
          ),
        ),
        dhikr(2),
      ],
    ),
  ],
  groups: [kDaily],
);

class MemoryFavoritesRepository implements AdhkarFavoritesRepository {
  List<String> saved = [];
  bool fail = false;

  @override
  Future<List<String>> load() async => saved;

  @override
  Future<void> save(List<String> ids) async {
    if (fail) throw StateError('Storage unavailable');
    saved = ids;
  }
}

class MemoryPrayerRepository implements PrayerRepository {
  PrayerSettings settings = const PrayerSettings();
  PrayerPlace? place;

  @override
  Future<PrayerSettings> loadSettings() async => settings;

  @override
  Future<void> saveSettings(PrayerSettings value) async => settings = value;

  @override
  Future<PrayerPlace?> loadPlace() async => place;

  @override
  Future<void> savePlace(PrayerPlace value) async => place = value;
}

/// Answers [request] and [quiet] with fixed places and counts the calls.
class FakeLocationSource implements LocationSource {
  FakeLocationSource({this.requestResult, this.quietResult});

  PrayerPlace? requestResult;
  PrayerPlace? quietResult;
  int requests = 0;
  int quietReads = 0;

  @override
  Future<PrayerPlace?> request() async {
    requests++;
    return requestResult;
  }

  @override
  Future<PrayerPlace?> quiet() async {
    quietReads++;
    return quietResult;
  }
}

/// Records which feedback was asked for.
class RecordingHaptics implements HapticsBackend {
  final List<String> calls = [];

  @override
  Future<void> select() async => calls.add('select');

  @override
  Future<void> tick() async => calls.add('tick');

  @override
  Future<void> step() async => calls.add('step');

  @override
  Future<void> celebrate() async => calls.add('celebrate');
}
