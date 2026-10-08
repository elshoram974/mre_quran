import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_fields/mre_fields.dart';
import 'package:mre_quran/features/mushaf/presentation/go_to_page_sheet.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('validates typed page numbers and disables empty submit', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showGoToPage(
                context,
                page: 1,
                pageCount: 10,
                digits: (value) => value.toString(),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final field = find.byType(MRETextField);
    final input = find.descendant(of: field, matching: find.byType(TextField));
    await tester.enterText(input, '');
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.enterText(input, '0');
    await tester.pump();
    expect(tester.widget<TextField>(input).controller!.text, '');
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.enterText(input, '1');
    await tester.enterText(input, '11');
    await tester.pump();
    expect(tester.widget<TextField>(input).controller!.text, '1');
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );

    await tester.enterText(input, '10');
    await tester.pump();
    expect(tester.widget<TextField>(input).controller!.text, '10');
  });
}
