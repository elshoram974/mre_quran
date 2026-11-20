import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/core/widgets/app_confirm_sheet.dart';
import 'package:mre_quran/core/widgets/app_mark.dart';
import 'package:mre_quran/core/widgets/app_snack_bar.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget Function(BuildContext) body, {
  String locale = 'ar',
  ThemeData? theme,
  double textScale = 1,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light,
      locale: Locale(locale),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(body: Builder(builder: body)),
    ),
  );
}

void main() {
  group('the mark and the name', () {
    testWidgets('the mark is drawn in the colour it is given and is '
        'decoration', (tester) async {
      await _pump(
        tester,
        (_) => const Center(child: AppMark(size: 40, color: Color(0xFF123456))),
      );
      final paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(AppMark),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(paint.size, const Size.square(40));
      expect(find.byType(ExcludeSemantics), findsWidgets);
    });

    for (final (locale, name) in [('ar', 'مصحفي'), ('en', 'Mushafi')]) {
      testWidgets('the signature says the app\'s name in $locale', (
        tester,
      ) async {
        await _pump(
          tester,
          (_) => const Center(child: AppBrand()),
          locale: locale,
        );
        expect(find.text(name), findsOneWidget);
        expect(find.byType(AppMark), findsOneWidget);
      });
    }
  });

  group('the snack bar', () {
    testWidgets('carries the mark, floats, and takes the theme\'s edge', (
      tester,
    ) async {
      await _pump(
        tester,
        (context) => TextButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            AppSnackBar(
              'تم النسخ',
              action: SnackBarAction(label: 'تراجع', onPressed: () {}),
            ),
          ),
          child: const Text('go'),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.text('تم النسخ'), findsOneWidget);
      expect(find.text('تراجع'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.byType(AppMark),
        ),
        findsOneWidget,
      );
      final bar = tester.widget<SnackBar>(find.byType(SnackBar));
      final shape =
          AppTheme.light.snackBarTheme.shape! as RoundedRectangleBorder;
      expect(AppTheme.light.snackBarTheme.behavior, SnackBarBehavior.floating);
      expect(shape.side, isNot(BorderSide.none));
      expect(bar.action, isNotNull);
    });

    for (final (name, theme) in [
      ('light', AppTheme.light),
      ('dark', AppTheme.dark),
    ]) {
      testWidgets('fits large text on a narrow screen in $name', (
        tester,
      ) async {
        await _pump(
          tester,
          (context) => TextButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              AppSnackBar(
                'تعذّرت المشاركة، حاول مرة أخرى بعد قليل من فضلك',
                action: SnackBarAction(label: 'تراجع', onPressed: () {}),
              ),
            ),
            child: const Text('go'),
          ),
          theme: theme,
          textScale: 2,
          size: const Size(320, 640),
        );
        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('the dialogs', () {
    testWidgets('the confirmation sheet is signed with the app', (
      tester,
    ) async {
      await _pump(
        tester,
        (context) => TextButton(
          onPressed: () => AppConfirmSheet.show(
            context: context,
            title: 'إغلاق التطبيق؟',
            message: 'هل تريد الإغلاق؟',
            confirmLabel: 'إغلاق',
            cancelLabel: 'البقاء',
          ),
          child: const Text('go'),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.text('مصحفي'), findsOneWidget);
      expect(find.byType(AppBrand), findsOneWidget);
    });

    for (final (name, theme) in [
      ('light', AppTheme.light),
      ('dark', AppTheme.dark),
    ]) {
      test('dialogs, pickers and menus share the app\'s paper, edge and '
          'corners in $name', () {
        final scheme = theme.colorScheme;
        expect(
          theme.dialogTheme.backgroundColor,
          theme.timePickerTheme.backgroundColor,
        );
        expect(theme.dialogTheme.backgroundColor, theme.popupMenuTheme.color);
        final dialog = theme.dialogTheme.shape! as RoundedRectangleBorder;
        final picker = theme.timePickerTheme.shape! as RoundedRectangleBorder;
        expect(picker.borderRadius, dialog.borderRadius);
        expect(dialog.side, isNot(BorderSide.none));
        expect(theme.timePickerTheme.dialHandColor, scheme.primary);
        expect(theme.snackBarTheme.actionTextColor, scheme.inversePrimary);
      });
    }
  });
}
