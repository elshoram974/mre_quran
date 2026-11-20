import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/notifications/reminder_payload.dart';
import '../features/adhkar/presentation/adhkar_steps_sheet.dart';
import '../features/mushaf/application/reading_position_provider.dart';
import '../features/quran_index/application/quran_metadata_provider.dart';
import 'router.dart';

/// Puts the Mushaf at the beginning of a surah, for a reminder that points at
/// one (such as Surat Al-Kahf on Friday).
final reminderSurahOpenerProvider = Provider<Future<void> Function(int surah)>(
  (ref) => (surah) async {
    final metadata = await ref.read(quranMetadataProvider.future);
    await ref
        .read(readingPositionProvider.notifier)
        .setPage(metadata.surah(surah).startPage);
  },
);

/// Opens what a tapped notification points at: the prayer times, a surah in
/// the Mushaf, or the adhkar list it names as steps over the Adhkar tab. A
/// payload that is not ours does nothing. [openSurah] is what puts the Mushaf
/// at a surah (see [reminderSurahOpenerProvider]).
Future<void> openReminder(
  GoRouter router,
  String payload, {
  Future<void> Function(int surah)? openSurah,
}) async {
  final surah = ReminderPayload.surah(payload);
  if (surah != null) {
    await openSurah?.call(surah);
    router.go(AppRoute.reader.path);
    return;
  }
  if (payload == ReminderPayload.adhkarHome) {
    router.go(AppRoute.duas.path);
    return;
  }
  if (payload == ReminderPayload.adhanSettings) {
    await router.push<void>(AppRoute.adhan.path);
    return;
  }
  if (payload == ReminderPayload.prayerTimes) {
    router.go(AppRoute.prayerTimes.path);
    return;
  }
  final id = ReminderPayload.collectionId(payload);
  if (id == null) return;
  router.go(AppRoute.duas.path);
  // Let the tab come up, then open the steps over it.
  await WidgetsBinding.instance.endOfFrame;
  final context = router.routerDelegate.navigatorKey.currentContext;
  if (context != null && context.mounted) {
    await AdhkarSteps.show(context, collectionId: id);
  }
}
