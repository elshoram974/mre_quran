import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/features/home_widgets/application/home_widgets_providers.dart';
import 'package:mre_quran/features/home_widgets/domain/home_widget.dart';
import 'package:mre_quran/features/home_widgets/presentation/home_widgets_page.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/fake_home_widgets.dart';

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
      overrides: [homeWidgetsPlatformProvider.overrideWithValue(widgets)],
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
    expect(find.text('إضافة'), findsWidgets);
    await tester.tap(find.text('إضافة').first);
    await tester.pumpAndSettle();
    expect(widgets.pinned, [HomeWidget.prayerCard]);
    expect(find.textContaining('أكّد الإضافة'), findsOneWidget);
  });

  testWidgets('where the launcher takes no requests, it says how', (
    tester,
  ) async {
    await _pump(tester, pinnable: false);
    expect(find.text('إضافة'), findsNothing);
    expect(find.textContaining('اضغط مطولًا'), findsOneWidget);
  });

  testWidgets('on iOS it gives the steps', (tester) async {
    await _pump(tester, pinnable: false, platform: TargetPlatform.iOS);
    expect(find.textContaining('ابحث عن «مصحفي»'), findsOneWidget);
    expect(find.text('بطاقة الصلاة'), findsOneWidget);
  });

  testWidgets('English LTR in dark mode', (tester) async {
    await _pump(tester, locale: 'en', theme: AppTheme.dark);
    expect(find.text('Home-screen widgets'), findsOneWidget);
    expect(find.text('Add'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  for (final (name, size, scale) in [
    ('compact, large text', const Size(320, 640), 2.0),
    ('medium', const Size(700, 900), 1.0),
    ('expanded', const Size(1100, 800), 1.0),
  ]) {
    testWidgets('fits when $name', (tester) async {
      await _pump(tester, size: size, textScale: scale);
      await tester.scrollUntilVisible(
        find.text('ذكر مقترح'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
