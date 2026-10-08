import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/notifications/reminder_payload.dart';
import '../features/adhkar/presentation/adhkar_steps_sheet.dart';
import 'router.dart';

/// Opens what a tapped notification points at: the prayer times, or the adhkar
/// list it names as steps over the Adhkar tab. A payload that is not ours does
/// nothing.
Future<void> openReminder(GoRouter router, String payload) async {
  if (payload == ReminderPayload.prayerTimes) {
    await router.push<void>(AppRoute.prayerTimes.path);
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
