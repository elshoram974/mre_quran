import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mre_quran/app/reminder_opener.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/features/adhkar/domain/adhkar_collection.dart';
import 'package:mre_quran/features/adhkar/domain/dhikr.dart';
import 'package:mre_quran/features/adhkar/presentation/adhkar_session_page.dart';
import 'package:mre_quran/features/adhkar/presentation/dhikr_card.dart';
import 'package:mre_quran/features/adhkar/presentation/duas_page.dart';

import '../../helpers/adhkar_app.dart';
import '../../helpers/adhkar_fixtures.dart';

/// Three steps: one repeat, three repeats, one repeat. The second one is said
/// only after Maghrib.
AdhkarCatalog _steps() => AdhkarCatalog(
  [
    AdhkarCollection(
      id: 'morning',
      titles: const {'ar': 'أذكار الصباح', 'en': 'Morning adhkar'},
      icon: AdhkarIcon.sunrise,
      group: kDaily,
      reminderMinutes: 330,
      entries: [
        dhikr(1),
        const Dhikr(
          order: 2,
          text: 'ذكر 2',
          repeat: 3,
          repeatLabel: 'ثلاث',
          source: 'المصدر 2',
          variant: 0,
          onlyAfter: {'maghrib'},
        ),
        dhikr(3),
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

/// A counter whose text holds [part].
Finder _counterContaining(String part) => find.descendant(
  of: find.byType(DhikrCard),
  matching: find.textContaining(part),
);

/// The counter button of the step on screen.
Finder _counter(String text) =>
    find.descendant(of: find.byType(DhikrCard), matching: find.text(text));

Future<void> _open(WidgetTester tester) async {
  await tapVisible(tester, find.text('ابدأ'));
  await tester.pumpAndSettle();
}

void main() {
  group('the steps sheet', () {
    testWidgets('shows one dhikr at a time, starting at the first', (
      tester,
    ) async {
      await pumpAdhkarApp(tester, catalog: _steps());
      await _open(tester);
      expect(find.byType(DhikrCard), findsOneWidget);
      expect(find.text('الخطوة ١ من ٣'), findsOneWidget);
      expect(find.text('ذكر 1'), findsOneWidget);
      expect(find.text('ذكر 2'), findsNothing);
    });

    testWidgets('finishing a dhikr moves on to the next step by itself', (
      tester,
    ) async {
      await pumpAdhkarApp(tester, catalog: _steps());
      await _open(tester);

      await tester.tap(_counter('٠ من ١'));
      await tester.pumpAndSettle();
      expect(find.text('الخطوة ٢ من ٣'), findsOneWidget);
      expect(find.text('ذكر 2'), findsOneWidget);

      // Three repeats stay on the step until the last one.
      await tester.tap(_counter('٠ من ٣'));
      await tester.pumpAndSettle();
      await tester.tap(_counter('١ من ٣'));
      await tester.pumpAndSettle();
      expect(find.text('الخطوة ٢ من ٣'), findsOneWidget);
      await tester.tap(_counter('٢ من ٣'));
      await tester.pumpAndSettle();
      expect(find.text('الخطوة ٣ من ٣'), findsOneWidget);
    });

    testWidgets('previous and next move without counting', (tester) async {
      await pumpAdhkarApp(tester, catalog: _steps());
      await _open(tester);
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.chevron_left),
            )
            .onPressed,
        isNull,
        reason: 'no step before the first',
      );
      await tester.tap(find.byTooltip('التالي'));
      await tester.pumpAndSettle();
      expect(find.text('الخطوة ٢ من ٣'), findsOneWidget);
      await tester.tap(find.byTooltip('السابق'));
      await tester.pumpAndSettle();
      expect(find.text('الخطوة ١ من ٣'), findsOneWidget);
      expect(_counter('٠ من ١'), findsOneWidget);
    });

    testWidgets('a dhikr said after one prayer says so', (tester) async {
      await pumpAdhkarApp(tester, catalog: _steps());
      await _open(tester);
      expect(find.text('بعد المغرب فقط'), findsNothing);
      await tester.tap(find.byTooltip('التالي'));
      await tester.pumpAndSettle();
      expect(find.text('بعد المغرب فقط'), findsOneWidget);
    });

    testWidgets('it opens where the person left off', (tester) async {
      await pumpAdhkarApp(tester, catalog: _steps());
      await _open(tester);
      await tester.tap(_counter('٠ من ١'));
      await tester.pumpAndSettle();
      // Close the sheet and open it again.
      await tester.tapAt(const Offset(195, 40));
      await tester.pumpAndSettle();
      expect(find.byType(DhikrCard), findsNothing);
      await tapVisible(tester, find.text('تابع'));
      await tester.pumpAndSettle();
      expect(find.text('الخطوة ٢ من ٣'), findsOneWidget);
    });

    testWidgets(
      'the last step ends with a message, the next list, and a restart',
      (tester) async {
        await pumpAdhkarApp(tester, catalog: _steps());
        await _open(tester);
        await tester.tap(_counter('٠ من ١'));
        await tester.pumpAndSettle();
        for (var i = 0; i < 3; i++) {
          await tester.tap(_counterContaining(' من ٣'));
          await tester.pumpAndSettle();
        }
        await tester.tap(_counter('٠ من ١'));
        await tester.pumpAndSettle();
        expect(find.text('تقبّل الله منك'), findsOneWidget);
        expect(find.byType(DhikrCard), findsNothing);

        // On to the next list: its steps open in a new sheet.
        await tester.tap(find.text('التالي: أذكار المساء'));
        await tester.pumpAndSettle();
        expect(find.text('الخطوة ١ من ٢'), findsOneWidget);
        expect(find.text('أذكار المساء'), findsOneWidget);
      },
    );

    testWidgets('start over counts the list again from the first step', (
      tester,
    ) async {
      await pumpAdhkarApp(
        tester,
        catalog: AdhkarCatalog([_steps().collections.last], groups: [kDaily]),
      );
      await tester.tap(find.text('ابدأ'));
      await tester.pumpAndSettle();
      await tester.tap(_counter('٠ من ١'));
      await tester.pumpAndSettle();
      await tester.tap(_counter('٠ من ٢'));
      await tester.pumpAndSettle();
      await tester.tap(_counter('١ من ٢'));
      await tester.pumpAndSettle();
      expect(find.text('ابدأ من جديد'), findsOneWidget);
      await tester.tap(find.text('ابدأ من جديد'));
      await tester.pumpAndSettle();
      expect(find.text('الخطوة ١ من ٢'), findsOneWidget);
      expect(_counter('٠ من ١'), findsOneWidget);
    });

    testWidgets('"show as a list" opens the whole list as a page', (
      tester,
    ) async {
      await pumpAdhkarApp(tester, catalog: _steps());
      await _open(tester);
      await tester.tap(find.text('عرض كقائمة'));
      await tester.pumpAndSettle();
      expect(find.byType(AdhkarSessionPage), findsOneWidget);
      expect(find.byType(DhikrCard), findsNWidgets(3));
    });

    testWidgets('the evidence of a step opens over it', (tester) async {
      await pumpAdhkarApp(tester, catalog: _steps());
      await _open(tester);
      await tester.tap(find.text('الدليل'));
      await tester.pumpAndSettle();
      expect(find.text('المصدر 1'), findsOneWidget);
    });

    testWidgets('undo takes one repeat back', (tester) async {
      await pumpAdhkarApp(tester, catalog: _steps());
      await _open(tester);
      await tester.tap(find.byTooltip('التالي'));
      await tester.pumpAndSettle();
      await tester.tap(_counter('٠ من ٣'));
      await tester.pumpAndSettle();
      expect(_counter('١ من ٣'), findsOneWidget);
      await tester.tap(find.byTooltip('تراجع عن مرة'));
      await tester.pumpAndSettle();
      expect(_counter('٠ من ٣'), findsOneWidget);
    });

    for (final (name, size, scale) in [
      ('compact, large text', const Size(320, 640), 2.0),
      ('medium', const Size(700, 900), 1.0),
      ('expanded', const Size(1100, 800), 1.0),
    ]) {
      testWidgets('fits when $name', (tester) async {
        await pumpAdhkarApp(
          tester,
          catalog: _steps(),
          size: size,
          textScale: scale,
        );
        await tapVisible(tester, find.text('ابدأ'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(DhikrCard), findsOneWidget);
      });
    }

    testWidgets('English LTR in dark mode', (tester) async {
      await pumpAdhkarApp(
        tester,
        catalog: _steps(),
        locale: 'en',
        theme: AppTheme.dark,
      );
      await tapVisible(tester, find.text('Start'));
      await tester.pumpAndSettle();
      expect(find.text('Step ١ of ٣'), findsOneWidget);
      expect(find.text('Show as a list'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('a tapped reminder', () {
    testWidgets('opens the list it names as steps over the Adhkar tab', (
      tester,
    ) async {
      await pumpAdhkarApp(tester, catalog: _steps());
      final router = GoRouter.of(tester.element(find.byType(DuasPage)));
      // It waits for a frame, so it must not be awaited before pumping.
      unawaited(openReminder(router, 'adhkar:evening'));
      await tester.pumpAndSettle();
      expect(find.text('الخطوة ١ من ٢'), findsOneWidget);
      expect(find.text('أذكار المساء'), findsOneWidget);
    });

    testWidgets('a payload that is not ours does nothing', (tester) async {
      await pumpAdhkarApp(tester, catalog: _steps());
      final router = GoRouter.of(tester.element(find.byType(DuasPage)));
      unawaited(openReminder(router, 'download:1'));
      await tester.pumpAndSettle();
      expect(find.byType(DhikrCard), findsNothing);
    });
  });
}
