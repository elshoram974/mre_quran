import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/core/theme/app_palette.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/core/widgets/app_tile_card.dart';
import 'package:mre_quran/features/home_widgets/application/home_widgets_providers.dart';
import 'package:mre_quran/features/home_widgets/domain/home_widget.dart';
import 'package:mre_quran/features/home_widgets/presentation/home_widgets_page.dart';
import 'package:mre_quran/features/home_widgets/presentation/widget_previews.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/fake_home_widgets.dart';
import '../../helpers/memory_settings_repository.dart';

/// A widget's name on its card: the preview above it can say the same word.
Finder _name(String title) =>
    find.descendant(of: find.byType(AppTileCard), matching: find.text(title));

Future<FakeHomeWidgets> _pump(
  WidgetTester tester, {
  bool pinnable = true,
  String locale = 'ar',
  Size size = const Size(390, 844),
  double textScale = 1,
  ThemeData? theme,
  TargetPlatform platform = TargetPlatform.android,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final widgets = FakeHomeWidgets(pinnable: pinnable);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        homeWidgetsPlatformProvider.overrideWithValue(widgets),
        settingsRepositoryProvider.overrideWithValue(
          MemorySettingsRepository(),
        ),
      ],
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: (theme ?? AppTheme.light).copyWith(platform: platform),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const HomeWidgetsPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return widgets;
}

void main() {
  testWidgets('each widget can be added from the app', (tester) async {
    final widgets = await _pump(tester);
    for (final title in [
      'بطاقة الصلاة',
      'الصلاة القادمة',
      'مواقيت اليوم',
      'المسبحة',
      'ذكر مقترح',
    ]) {
      await tester.scrollUntilVisible(
        _name(title),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      final card = find.ancestor(
        of: _name(title),
        matching: find.byType(AppTileCard),
      );
      final add = find.descendant(of: card, matching: find.text('إضافة'));
      await tester.ensureVisible(add);
      await tester.pumpAndSettle();
      await tester.tap(add);
      await tester.pumpAndSettle();
      if (title != 'ذكر مقترح') {
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
      }
    }
    expect(widgets.pinned, HomeWidget.values);
    expect(find.textContaining('أكّد الإضافة'), findsOneWidget);
  });

  for (final (locale, field, colour) in [
    ('en', 'Widget colours', 'Navy'),
    ('ar', 'ألوان الويدجت', 'كحلي'),
  ]) {
    testWidgets('changes the launcher widget colour in $locale', (
      tester,
    ) async {
      final widgets = await _pump(tester, locale: locale);
      await tester.tap(find.text(field));
      await tester.pumpAndSettle();
      await tester.tap(find.text(colour));
      await tester.pumpAndSettle();
      expect(widgets.style, WidgetAppearance.navy);
      expect(find.text(colour), findsOneWidget);
    });
  }

  testWidgets('each widget has a preview drawn in the app, not a picture', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byType(HomeWidgetPreview, skipOffstage: false), findsWidgets);
    expect(find.byType(Image), findsNothing);
    // The sample day the picker shows, in the app's language.
    expect(find.text('الصلاة القادمة'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the dhikr preview draws its progress bar', (tester) async {
    await _pump(tester);
    await tester.scrollUntilVisible(
      _name('ذكر مقترح'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    final bar = find.byWidgetPredicate(
      (widget) => widget is ColoredBox && widget.color == WidgetPalette.accent,
      skipOffstage: false,
    );
    expect(bar, findsOneWidget);
    expect(tester.getSize(bar).height, greaterThan(0));
  });

  testWidgets('the widgets can be given a language of their own', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Next prayer'), findsNothing);
    await tester.tap(find.text('مثل لغة التطبيق'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    // The previews now speak English, while the page stays Arabic.
    expect(find.text('Next prayer'), findsWidgets);
    expect(find.text('لغة الويدجتس'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('where the launcher takes no requests, it says how', (
    tester,
  ) async {
    await _pump(tester, pinnable: false);
    expect(find.text('إضافة'), findsNothing);
    expect(find.textContaining('اضغط مطولًا'), findsOneWidget);
  });

  testWidgets('the prayer schedule recommends a two by two widget', (
    tester,
  ) async {
    await _pump(tester, locale: 'en');
    await tester.scrollUntilVisible(
      find.text("Today's prayer times"),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final card = find.ancestor(
      of: find.text("Today's prayer times"),
      matching: find.byType(AppTileCard),
    );
    expect(
      find.descendant(
        of: card,
        matching: find.textContaining('two columns by two rows'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('time until the next prayer'), findsOneWidget);
  });

  testWidgets('schedule choices save and remain visible in the app', (
    tester,
  ) async {
    final widgets = await _pump(tester, locale: 'en');
    final sunrise = find.text('Show sunrise');
    await tester.scrollUntilVisible(
      sunrise,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(sunrise);
    await tester.pumpAndSettle();
    await tester.tap(sunrise);
    await tester.pumpAndSettle();
    expect(widgets.scheduleOptions.showSunrise, isFalse);
    final large = find.text('Larger text');
    await tester.ensureVisible(large);
    await tester.pumpAndSettle();
    await tester.tap(large);
    await tester.pumpAndSettle();
    expect(widgets.scheduleOptions.largeText, isTrue);
    final mode = find.text('Times shown');
    await tester.ensureVisible(mode);
    await tester.pumpAndSettle();
    await tester.tap(mode);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next three prayers').last);
    await tester.pumpAndSettle();
    expect(widgets.scheduleOptions.upcomingOnly, isTrue);
    expect(widgets.scheduleOptions.showSunrise, isFalse);
  });

  testWidgets('seconds follow the visibility of the schedule countdown', (
    tester,
  ) async {
    final widgets = await _pump(tester, locale: 'en');
    final countdown = find.text('Time until the next prayer');
    final seconds = find.text('Seconds on the prayer widgets');
    await tester.scrollUntilVisible(
      countdown,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(countdown);
    await tester.pumpAndSettle();
    expect(seconds, findsOneWidget);
    await tester.tap(countdown);
    await tester.pumpAndSettle();
    expect(widgets.scheduleOptions.showCountdown, isFalse);
    expect(seconds, findsNothing);
    await tester.tap(countdown);
    await tester.pumpAndSettle();
    expect(seconds, findsOneWidget);
  });

  testWidgets('failed schedule save restores the previous choice', (
    tester,
  ) async {
    final widgets = await _pump(tester, locale: 'en');
    widgets.failScheduleSave = true;
    final sunrise = find.text('Show sunrise');
    await tester.scrollUntilVisible(
      sunrise,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(sunrise);
    await tester.pumpAndSettle();
    await tester.tap(sunrise);
    await tester.pumpAndSettle();
    expect(widgets.scheduleOptions.showSunrise, isTrue);
    expect(
      find.text('Could not save widget settings. Try again.'),
      findsOneWidget,
    );
  });

  testWidgets('on iOS it gives the steps', (tester) async {
    await _pump(tester, pinnable: false, platform: TargetPlatform.iOS);
    expect(find.textContaining('ابحث عن «مصحفي»'), findsOneWidget);
    expect(_name('بطاقة الصلاة'), findsOneWidget);
  });

  testWidgets('English LTR in dark mode', (tester) async {
    await _pump(tester, locale: 'en', theme: AppTheme.dark);
    expect(find.text('Home-screen widgets'), findsOneWidget);
    expect(find.text('Add'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  for (final (locale, title, add) in [
    ('ar', 'مواقيت اليوم', 'إضافة'),
    ('en', "Today's prayer times", 'Add'),
  ]) {
    testWidgets('adds the prayer widget at large text size in $locale', (
      tester,
    ) async {
      final widgets = await _pump(
        tester,
        locale: locale,
        size: const Size(320, 640),
        textScale: 2,
      );
      await tester.scrollUntilVisible(
        _name(title),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final card = find.ancestor(
        of: _name(title),
        matching: find.byType(AppTileCard),
      );
      final button = find.descendant(of: card, matching: find.text(add));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(widgets.pinned, [HomeWidget.prayerSchedule]);
      expect(tester.takeException(), isNull);
    });
  }

  for (final (name, size, scale) in [
    ('compact, large text', const Size(320, 640), 2.0),
    ('medium', const Size(700, 900), 1.0),
    ('expanded', const Size(1100, 800), 1.0),
  ]) {
    testWidgets('fits when $name', (tester) async {
      await _pump(tester, size: size, textScale: scale);
      await tester.scrollUntilVisible(
        _name('ذكر مقترح'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
