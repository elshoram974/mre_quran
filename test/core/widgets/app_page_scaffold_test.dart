import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/core/theme/app_tokens.dart';
import 'package:mre_quran/core/widgets/app_page_scaffold.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester, {
  bool? loading,
  String locale = 'ar',
  ThemeData? theme,
  TargetPlatform platform = TargetPlatform.android,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: (theme ?? AppTheme.light).copyWith(platform: platform),
      home: loading == null
          ? const AppPageScaffold(title: 'Title', body: Text('body'))
          : AppPageScaffold(
              title: 'Title',
              loading: loading,
              body: const Text('body'),
            ),
    ),
  );
}

void main() {
  testWidgets('a page that does not ask shows no loader', (tester) async {
    await _pump(tester);
    await tester.pump(AppTokens.loaderDelay);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(tester.widget<AppBar>(find.byType(AppBar)).flexibleSpace, isNull);
  });

  for (final (locale, label) in [('ar', 'جارٍ التحميل…'), ('en', 'Loading…')]) {
    testWidgets('a loading page draws a thin line on the bar\'s bottom edge, '
        'announced, and moves nothing ($locale)', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, loading: false, locale: locale);
      final title = tester.getRect(find.text('Title'));
      final body = tester.getRect(find.text('body'));

      await _pump(tester, loading: true, locale: locale);
      // Not for a wait too short to notice.
      expect(find.byType(LinearProgressIndicator), findsNothing);
      await tester.pump(AppTokens.loaderDelay);
      final line = tester.getRect(find.byType(LinearProgressIndicator));
      final bar = tester.getRect(find.byType(AppBar));
      expect(line.bottom, bar.bottom);
      expect(line.height, AppTokens.barProgressHeight);
      expect(line.width, bar.width);
      expect(find.bySemanticsLabel(label), findsOneWidget);
      expect(tester.getRect(find.text('Title')), title);
      expect(tester.getRect(find.text('body')), body);

      await _pump(tester, loading: false, locale: locale);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(tester.getRect(find.text('Title')), title);
      expect(tester.getRect(find.text('body')), body);
      handle.dispose();
    });
  }

  testWidgets('a wait that ends quickly shows no loader at all', (
    tester,
  ) async {
    await _pump(tester, loading: true);
    await tester.pump(AppTokens.loaderDelay ~/ 2);
    await _pump(tester, loading: false);
    await tester.pump(AppTokens.loaderDelay);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  for (final (name, theme) in [
    ('light', AppTheme.light),
    ('dark', AppTheme.dark),
  ]) {
    testWidgets('on iOS the glass bar turns a spinner at its end, in the '
        'accent, and moves nothing ($name)', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        loading: false,
        theme: theme,
        platform: TargetPlatform.iOS,
      );
      await tester.pumpAndSettle();
      final title = tester.getRect(find.text('Title'));
      final body = tester.getRect(find.text('body'));

      await _pump(
        tester,
        loading: true,
        theme: theme,
        platform: TargetPlatform.iOS,
      );
      expect(find.byType(GlassProgressIndicator), findsNothing);
      await tester.pump(AppTokens.loaderDelay);
      final spinner = tester.widget<GlassProgressIndicator>(
        find.byType(GlassProgressIndicator),
      );
      expect(spinner.color, theme.colorScheme.primary);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.bySemanticsLabel('جارٍ التحميل…'), findsOneWidget);
      // Arabic: the back button leads on the right, the spinner trails on
      // the left, inside the bar.
      final at = tester.getCenter(find.byType(GlassProgressIndicator));
      expect(at.dx, lessThan(title.left));
      expect(at.dy, closeTo(title.center.dy, 1));
      expect(tester.getRect(find.text('Title')), title);
      expect(tester.getRect(find.text('body')), body);
      expect(tester.takeException(), isNull);

      await _pump(
        tester,
        loading: false,
        theme: theme,
        platform: TargetPlatform.iOS,
      );
      await tester.pumpAndSettle();
      expect(find.byType(GlassProgressIndicator), findsNothing);
      expect(tester.getRect(find.text('Title')), title);
      handle.dispose();
    });
  }
}
