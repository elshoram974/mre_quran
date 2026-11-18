import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mre_quran/core/hints/hints.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/core/widgets/app_hint_sheet.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

/// Keeps the turned-off hints in memory.
class MemoryHintsRepository implements HintsRepository {
  final Set<AppHint> off = {};

  @override
  Future<Set<AppHint>> dismissed() async => {...off};

  @override
  Future<void> dismiss(AppHint hint) async => off.add(hint);
}

void main() {
  Future<(MemoryHintsRepository, List<bool>)> pump(
    WidgetTester tester, {
    bool once = false,
  }) async {
    final repository = MemoryHintsRepository();
    final answers = <bool>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [hintsRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: TextButton(
                onPressed: () async => answers.add(
                  await showAppHint(
                    context,
                    ref,
                    hint: AppHint.tryAdhan,
                    icon: Icons.volume_up_outlined,
                    title: 'جرّب',
                    body: 'نص',
                    action: 'جرّب الآن',
                    once: once,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    return (repository, answers);
  }

  testWidgets('comes once a run; "don\'t remind me" starts clear', (
    tester,
  ) async {
    final (repository, answers) = await pump(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final box = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
    expect(box.value, isFalse);
    await tester.tap(find.text('جرّب الآن'));
    await tester.pumpAndSettle();
    expect(answers, [true]);
    expect(repository.off, isEmpty);
    // Not again in this run.
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('جرّب الآن'), findsNothing);
    expect(answers, [true, false]);
  });

  testWidgets('"don\'t remind me again" turns it off for good', (tester) async {
    final (repository, answers) = await pump(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('لا تذكرني مرة أخرى'));
    await tester.tap(find.text('لاحقًا'));
    await tester.pumpAndSettle();
    expect(answers, [false]);
    expect(repository.off, {AppHint.tryAdhan});
  });

  testWidgets('a hint shown once ever offers no box and turns itself off', (
    tester,
  ) async {
    final (repository, _) = await pump(tester, once: true);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(CheckboxListTile), findsNothing);
    await tester.tap(find.text('جرّب الآن'));
    await tester.pumpAndSettle();
    expect(repository.off, {AppHint.tryAdhan});
  });
}
