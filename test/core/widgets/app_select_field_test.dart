import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/widgets/app_select_field.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

Widget _host({
  required int count,
  required ValueChanged<int> onChanged,
  Locale locale = const Locale('ar'),
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: AppSelectField<int>(
      label: 'Field',
      value: 1,
      options: [
        for (var i = 1; i <= count; i++)
          AppSelectOption(value: i, label: 'Option $i'),
      ],
      onChanged: onChanged,
    ),
  ),
);

void main() {
  testWidgets('hides search with 5 options or fewer', (tester) async {
    await tester.pumpWidget(_host(count: 5, onChanged: (_) {}));
    await tester.tap(find.byType(AppSelectField<int>));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('shows search with more than 5 options and filters', (
    tester,
  ) async {
    int? chosen;
    await tester.pumpWidget(_host(count: 8, onChanged: (v) => chosen = v));
    await tester.tap(find.byType(AppSelectField<int>));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), '7');
    await tester.pumpAndSettle();
    expect(find.text('Option 3'), findsNothing);
    await tester.tap(find.text('Option 7'));
    await tester.pumpAndSettle();
    expect(chosen, 7);
  });

  testWidgets('shows empty message when nothing matches', (tester) async {
    await tester.pumpWidget(_host(count: 8, onChanged: (_) {}));
    await tester.tap(find.byType(AppSelectField<int>));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('لا توجد نتائج'), findsOneWidget);
  });

  testWidgets('works in English LTR with large text', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: _host(count: 3, onChanged: (_) {}, locale: const Locale('en')),
      ),
    );
    expect(find.text('Option 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
