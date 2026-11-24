import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/features/reminders/domain/custom_reminder.dart';

import '../../helpers/adhkar_app.dart';
import '../../helpers/memory_custom_reminders_repository.dart';

CustomReminder _saved({
  String id = 'a',
  String title = 'الدواء',
  List<int> times = const [480],
  ReminderRepeat repeat = ReminderRepeat.daily,
  Set<int> weekdays = const {},
  int dayOfMonth = 1,
  bool enabled = true,
}) => CustomReminder(
  id: id,
  title: title,
  times: times,
  repeat: repeat,
  weekdays: weekdays,
  dayOfMonth: dayOfMonth,
  enabled: enabled,
);

/// Opens the reminders page from the adhkar tab.
Future<void> _openPage(WidgetTester tester) async {
  await tapVisible(tester, find.text('التذكيرات'));
  await tester.pumpAndSettle();
}

Future<void> _tapAdd(WidgetTester tester) async {
  await tester.tap(find.text('إضافة تذكير'));
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, int field, String text) async {
  await tester.enterText(find.byType(EditableText).at(field), text);
  await tester.pump();
}

Future<void> _tapChip(WidgetTester tester, String day) async {
  final chip = find.widgetWithText(FilterChip, day);
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester) async {
  final button = find.text('حفظ التذكير');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  group('the list', () {
    testWidgets('with none made, it says what to do and offers to add', (
      tester,
    ) async {
      await pumpAdhkarApp(tester);
      await _openPage(tester);
      expect(find.text('تذكيراتي'), findsOneWidget);
      expect(find.textContaining('لم تضف تذكيرًا بعد'), findsOneWidget);
      expect(find.text('إضافة تذكير'), findsOneWidget);
    });

    testWidgets('each one says when it comes, and a switched-off one says '
        'it is off', (tester) async {
      final repository = MemoryCustomRemindersRepository()
        ..reminders = [
          _saved(times: const [480, 1260]),
          _saved(
            id: 'b',
            title: 'ورد القرآن',
            repeat: ReminderRepeat.weekly,
            weekdays: const {DateTime.monday, DateTime.thursday},
            enabled: false,
          ),
          _saved(
            id: 'c',
            title: 'صلة الرحم',
            repeat: ReminderRepeat.monthly,
            dayOfMonth: 15,
          ),
        ];
      await pumpAdhkarApp(tester, customReminders: repository);
      await _openPage(tester);
      expect(find.text('الدواء'), findsOneWidget);
      expect(find.textContaining('كل يوم · ٨:٠٠'), findsOneWidget);
      expect(find.textContaining('٩:٠٠'), findsWidgets);
      expect(find.textContaining('كل الاثنين، الخميس'), findsOneWidget);
      expect(find.textContaining('متوقف · '), findsOneWidget);
      expect(find.textContaining('يوم ١٥ من كل شهر'), findsOneWidget);
    });

    testWidgets('the switch turns one off and on without opening it', (
      tester,
    ) async {
      final repository = MemoryCustomRemindersRepository()
        ..reminders = [_saved()];
      final scheduler = await pumpAdhkarApp(
        tester,
        customReminders: repository,
      );
      await _openPage(tester);
      await tester.pumpAndSettle();
      expect(scheduler.scheduled, isNotEmpty);
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(repository.reminders.single.enabled, isFalse);
      expect(scheduler.scheduled, isEmpty);
      expect(find.text('تعديل التذكير'), findsNothing);
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(repository.reminders.single.enabled, isTrue);
      expect(scheduler.scheduled, isNotEmpty);
    });
  });

  group('making one', () {
    testWidgets('a title is enough: it comes every day at nine', (
      tester,
    ) async {
      final repository = MemoryCustomRemindersRepository();
      final scheduler = await pumpAdhkarApp(
        tester,
        customReminders: repository,
      );
      await _openPage(tester);
      await _tapAdd(tester);
      expect(find.text('تذكير جديد'), findsOneWidget);
      // Nothing to say about when until it has a title.
      expect(find.textContaining('أول تذكير'), findsNothing);
      await _type(tester, 0, 'الدواء');
      // Told when it will first come, before saving.
      expect(find.textContaining('أول تذكير'), findsOneWidget);
      await _save(tester);
      expect(find.text('تذكير جديد'), findsNothing);
      expect(repository.reminders.single.title, 'الدواء');
      expect(repository.reminders.single.times, [540]);
      expect(find.textContaining('كل يوم · ٩:٠٠'), findsOneWidget);
      expect(scheduler.scheduled, hasLength(1));
    });

    testWidgets('without a title it is not saved, and says why', (
      tester,
    ) async {
      final repository = MemoryCustomRemindersRepository();
      await pumpAdhkarApp(tester, customReminders: repository);
      await _openPage(tester);
      await _tapAdd(tester);
      await _save(tester);
      expect(find.text('اكتب عنوانًا للتذكير.'), findsOneWidget);
      expect(find.text('تذكير جديد'), findsOneWidget);
      expect(repository.reminders, isEmpty);
    });

    testWidgets('weekly needs a day, and says so until one is chosen', (
      tester,
    ) async {
      final repository = MemoryCustomRemindersRepository();
      final scheduler = await pumpAdhkarApp(
        tester,
        customReminders: repository,
      );
      await _openPage(tester);
      await _tapAdd(tester);
      await _type(tester, 0, 'ورد القرآن');
      await tester.tap(find.text('أسبوعيًا'));
      await tester.pumpAndSettle();
      expect(find.text('في أي الأيام؟'), findsOneWidget);
      await _save(tester);
      expect(find.text('اختر يومًا واحدًا على الأقل.'), findsOneWidget);
      expect(repository.reminders, isEmpty);

      await _tapChip(tester, 'الاثنين');
      await _tapChip(tester, 'الجمعة');
      await _save(tester);
      expect(repository.reminders.single.weekdays, {
        DateTime.monday,
        DateTime.friday,
      });
      expect(scheduler.weekdays.values.toSet(), {
        DateTime.monday,
        DateTime.friday,
      });
      expect(find.textContaining('كل الاثنين، الجمعة'), findsOneWidget);
    });

    testWidgets('monthly comes on the day chosen', (tester) async {
      final repository = MemoryCustomRemindersRepository();
      final scheduler = await pumpAdhkarApp(
        tester,
        customReminders: repository,
      );
      await _openPage(tester);
      await _tapAdd(tester);
      await _type(tester, 0, 'القسط');
      await tester.tap(find.text('شهريًا'));
      await tester.pumpAndSettle();
      expect(find.text('في أي يوم من الشهر؟'), findsOneWidget);
      expect(find.textContaining('حتى ٢٨'), findsOneWidget);
      await _save(tester);
      expect(repository.reminders.single.repeat, ReminderRepeat.monthly);
      expect(scheduler.monthDays.values.single, 1);
      expect(find.textContaining('يوم ١ من كل شهر'), findsOneWidget);
    });

    testWidgets('without the notification permission it is kept, but off, '
        'and the page says why in red', (tester) async {
      final repository = MemoryCustomRemindersRepository();
      final scheduler = await pumpAdhkarApp(
        tester,
        customReminders: repository,
        allowNotifications: false,
      );
      await _openPage(tester);
      await _tapAdd(tester);
      await _type(tester, 0, 'الدواء');
      await _save(tester);
      expect(repository.reminders.single.enabled, isFalse);
      expect(scheduler.scheduled, isEmpty);
      expect(find.textContaining('الإشعارات متوقفة'), findsOneWidget);
      expect(find.textContaining('متوقف · '), findsOneWidget);
    });
  });

  group('changing one', () {
    testWidgets('opening it shows what it has, and saving keeps the changes', (
      tester,
    ) async {
      final repository = MemoryCustomRemindersRepository()
        ..reminders = [
          _saved(times: const [480, 1260]),
        ];
      final scheduler = await pumpAdhkarApp(
        tester,
        customReminders: repository,
      );
      await _openPage(tester);
      await tester.tap(find.text('الدواء'));
      await tester.pumpAndSettle();
      expect(find.text('تعديل التذكير'), findsOneWidget);
      expect(find.text('الدواء'), findsWidgets);
      expect(find.byTooltip('حذف هذا الوقت'), findsNWidgets(2));
      // The second time goes.
      await tester.tap(find.byTooltip('حذف هذا الوقت').last);
      await tester.pumpAndSettle();
      expect(find.byTooltip('حذف هذا الوقت'), findsOneWidget);
      await _type(tester, 0, 'دواء الضغط');
      await _save(tester);
      expect(repository.reminders.single.title, 'دواء الضغط');
      expect(repository.reminders.single.times, [480]);
      expect(scheduler.scheduled, hasLength(1));
      expect(find.text('دواء الضغط'), findsOneWidget);
    });

    testWidgets('the last time cannot be taken away', (tester) async {
      final repository = MemoryCustomRemindersRepository()
        ..reminders = [_saved()];
      await pumpAdhkarApp(tester, customReminders: repository);
      await _openPage(tester);
      await tester.tap(find.text('الدواء'));
      await tester.pumpAndSettle();
      final remove = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.delete_outline),
      );
      expect(remove.onPressed, isNull);
    });

    testWidgets('deleting asks first, and takes it off the schedule', (
      tester,
    ) async {
      final repository = MemoryCustomRemindersRepository()
        ..reminders = [_saved()];
      final scheduler = await pumpAdhkarApp(
        tester,
        customReminders: repository,
      );
      await _openPage(tester);
      await tester.tap(find.text('الدواء'));
      await tester.pumpAndSettle();
      final delete = find.text('حذف التذكير');
      await tester.ensureVisible(delete);
      await tester.pumpAndSettle();
      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(find.textContaining('تحذف تذكير «الدواء»؟'), findsOneWidget);
      // "No, keep it" is the main button.
      await tester.tap(find.text('لا، أبقِه'));
      await tester.pumpAndSettle();
      expect(repository.reminders, hasLength(1));
      await tester.tap(delete);
      await tester.pumpAndSettle();
      await tester.tap(find.text('نعم، احذفه'));
      await tester.pumpAndSettle();
      expect(repository.reminders, isEmpty);
      expect(scheduler.scheduled, isEmpty);
      expect(find.textContaining('لم تضف تذكيرًا بعد'), findsOneWidget);
    });
  });

  group('layout', () {
    for (final (name, size, scale, locale, theme) in [
      ('compact, large text', const Size(320, 640), 2.0, 'ar', null),
      ('English, dark', const Size(390, 844), 1.0, 'en', AppTheme.dark),
      ('expanded', const Size(1100, 800), 1.0, 'ar', null),
    ]) {
      testWidgets('the list and the form fit: $name', (tester) async {
        final repository = MemoryCustomRemindersRepository()
          ..reminders = [
            _saved(
              title: 'ورد القرآن قبل النوم كل يوم',
              repeat: ReminderRepeat.weekly,
              weekdays: const {1, 2, 3, 4, 5},
              times: const [480, 1260],
            ),
          ];
        await pumpAdhkarApp(
          tester,
          size: size,
          textScale: scale,
          locale: locale,
          theme: theme,
          customReminders: repository,
        );
        final entry = find.text(locale == 'ar' ? 'التذكيرات' : 'Reminders');
        await tester.scrollUntilVisible(
          entry,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tapVisible(tester, entry);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tapVisible(tester, find.text('ورد القرآن قبل النوم كل يوم'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text(locale == 'ar' ? 'حفظ التذكير' : 'Save the reminder'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
