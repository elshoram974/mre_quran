import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/widgets/app_tile_card.dart';

void main() {
  /// Whether the chevron is drawn mirrored. Material's chevron turns itself
  /// in a right-to-left language, with a transform inside the icon.
  bool mirrored(WidgetTester tester) => find
      .descendant(
        of: find.byIcon(Icons.chevron_right),
        matching: find.byType(Transform),
      )
      .evaluate()
      .isNotEmpty;

  testWidgets('uses a left-facing forward chevron in Arabic', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: AppTileCard(title: 'إعدادات الأذان', onTap: () {}),
          ),
        ),
      ),
    );

    // One icon in every language; it is drawn turned to the left here.
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsNothing);
    expect(mirrored(tester), isTrue);
  });

  testWidgets('uses a right-facing forward chevron in English', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Scaffold(
            body: AppTileCard(title: 'Adhan settings', onTap: () {}),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsNothing);
    expect(mirrored(tester), isFalse);
  });
}
