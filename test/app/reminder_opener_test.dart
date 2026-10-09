import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mre_quran/app/reminder_opener.dart';
import 'package:mre_quran/app/router.dart';
import 'package:mre_quran/core/notifications/reminder_payload.dart';

void main() {
  testWidgets('a prayer-widget tap opens the Adhan settings', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoute.reader.path,
      routes: [
        GoRoute(
          path: AppRoute.reader.path,
          builder: (_, _) => const Scaffold(body: Text('Reader')),
        ),
        GoRoute(
          path: AppRoute.adhan.path,
          builder: (_, _) => const Scaffold(body: Text('Adhan settings')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    unawaited(openReminder(router, ReminderPayload.adhanSettings));
    await tester.pumpAndSettle();

    expect(find.text('Adhan settings'), findsOneWidget);
  });
}
