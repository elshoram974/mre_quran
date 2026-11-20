import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mre_quran/core/hints/hints.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/core/widgets/app_hint_sheet.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

class _Hints implements HintsRepository {
  final Set<AppHint> gone = {};

  @override
  Future<Set<AppHint>> dismissed() async => gone;

  @override
  Future<void> dismiss(AppHint hint) async => gone.add(hint);
}

void main() {
  late _Hints hints;
  bool? acted;
  var secondary = 0;

  Future<void> open(
    WidgetTester tester, {
    String? secondaryAction,
    String? dismissLabel,
  }) async {
    hints = _Hints();
    acted = null;
    secondary = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [hintsRepositoryProvider.overrideWithValue(hints)],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: TextButton(
                onPressed: () async => acted = await showAppHint(
                  context,
                  ref,
                  hint: AppHint.offlineMushaf,
                  icon: Icons.wifi_off_rounded,
                  title: 'العنوان',
                  body: 'الكلام',
                  action: 'الزر الرئيسي',
                  secondaryAction: secondaryAction,
                  onSecondary: () => secondary++,
                  dismissLabel: dismissLabel,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a hint has its main button and "later" by default', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('الزر الرئيسي'), findsOneWidget);
    expect(find.text('لاحقًا'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
    await tester.tap(find.text('لاحقًا'));
    await tester.pumpAndSettle();
    expect(acted, isFalse);
    expect(secondary, 0);
  });

  testWidgets('a second way out is a button of its own, and is reported', (
    tester,
  ) async {
    await open(tester, secondaryAction: 'الطريق الثاني', dismissLabel: 'حسنًا');
    expect(find.text('الزر الرئيسي'), findsOneWidget);
    expect(find.text('الطريق الثاني'), findsOneWidget);
    expect(find.text('حسنًا'), findsOneWidget);
    expect(find.text('لاحقًا'), findsNothing);
    await tester.tap(find.text('الطريق الثاني'));
    await tester.pumpAndSettle();
    expect(secondary, 1);
    expect(acted, isFalse, reason: 'the main action was not taken');
  });

  testWidgets('the main button is reported, and the second is not', (
    tester,
  ) async {
    await open(tester, secondaryAction: 'الطريق الثاني');
    await tester.tap(find.text('الزر الرئيسي'));
    await tester.pumpAndSettle();
    expect(acted, isTrue);
    expect(secondary, 0);
  });

  testWidgets('the same dismiss button works with large text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await open(tester, secondaryAction: 'الطريق الثاني', dismissLabel: 'حسنًا');
    expect(tester.takeException(), isNull);
  });
}
