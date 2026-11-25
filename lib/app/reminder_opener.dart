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
/// the Mushaf, or the adhkar list it names as steps over the Adhkar tab; or,
/// from its settings button, the reminders over the Settings tab, the prayer
/// times, or the adhan's settings. A payload that is not ours does nothing.
/// [openSurah] is what puts the Mushaf at a surah (see
/// [reminderSurahOpenerProvider]).
///
/// A sheet or dialog left open goes first, so what the notification opens is
/// what the person sees, not a sheet over it, nor a second list on the first.
Future<void> openReminder(
  GoRouter router,
  String payload, {
  Future<void> Function(int surah)? openSurah,
}) async {
  final surah = ReminderPayload.surah(payload);
  final collection = ReminderPayload.collectionId(payload);
  if (surah == null && collection == null && !_screens.contains(payload)) {
    return;
  }
  closeOpenSheets(router);
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
  // A prayer alert's settings live with the prayer times.
  if (payload == ReminderPayload.prayerTimes ||
      payload == ReminderPayload.prayerSettings) {
    router.go(AppRoute.prayerTimes.path);
    return;
  }
  if (payload == ReminderPayload.remindersSettings) {
    router.go(AppRoute.settings.path);
    // Let the tab come up, then open the reminders over it.
    await WidgetsBinding.instance.endOfFrame;
    await router.push<void>(AppRoute.reminders.path);
    return;
  }
  final id = collection;
  if (id == null) return;
  router.go(AppRoute.duas.path);
  // Let the tab come up, then open the steps over it.
  await WidgetsBinding.instance.endOfFrame;
  final context = router.routerDelegate.navigatorKey.currentContext;
  if (context != null && context.mounted) {
    await AdhkarSteps.show(context, collectionId: id);
  }
}

/// The payloads that name a screen.
const Set<String> _screens = {
  ReminderPayload.adhkarHome,
  ReminderPayload.adhanSettings,
  ReminderPayload.prayerTimes,
  ReminderPayload.prayerSettings,
  ReminderPayload.remindersSettings,
};

/// Closes every sheet and dialog over the app's pages, so a screen opened from
/// outside the app (a notification, a widget, a shortcut) is not left under
/// one. The pages themselves stay; the router changes them.
void closeOpenSheets(GoRouter router) {
  router.routerDelegate.navigatorKey.currentState?.popUntil(
    (route) => route.settings is Page<Object?>,
  );
}
