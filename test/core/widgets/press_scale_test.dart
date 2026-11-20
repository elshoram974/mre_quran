import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mre_quran/core/theme/app_tokens.dart';
import 'package:mre_quran/core/widgets/app_card.dart';
import 'package:mre_quran/core/widgets/app_tile_card.dart';
import 'package:mre_quran/core/widgets/press_scale.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    VoidCallback? onTap,
    bool reduceMotion = false,
  }) => tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              AppCard(
                onTap: onTap,
                child: const SizedBox(height: 80, child: Text('card')),
              ),
              const SizedBox(height: 1600),
            ],
          ),
        ),
      ),
    ),
  );

  double scaleOf(WidgetTester tester) =>
      tester.widget<AnimatedScale>(find.byType(AnimatedScale).first).scale;

  testWidgets('a tappable card gives under the finger and springs back', (
    tester,
  ) async {
    var taps = 0;
    await pump(tester, onTap: () => taps++);
    expect(scaleOf(tester), 1);
    final press = await tester.startGesture(
      tester.getCenter(find.text('card')),
    );
    await tester.pump(AppTokens.motionPress);
    expect(scaleOf(tester), AppTokens.pressScale);
    await press.up();
    await tester.pumpAndSettle();
    expect(scaleOf(tester), 1);
    expect(taps, 1, reason: 'the tap still arrives');
  });

  testWidgets('a finger that moves off to scroll lets the card go', (
    tester,
  ) async {
    var taps = 0;
    await pump(tester, onTap: () => taps++);
    final press = await tester.startGesture(
      tester.getCenter(find.text('card')),
    );
    await tester.pump();
    expect(scaleOf(tester), AppTokens.pressScale);
    await press.moveBy(const Offset(0, -60));
    await tester.pump();
    expect(scaleOf(tester), 1);
    await press.up();
    await tester.pumpAndSettle();
    expect(taps, 0, reason: 'it was a scroll, not a tap');
  });

  testWidgets('a card that does nothing does not move', (tester) async {
    await pump(tester);
    expect(find.byType(PressScale), findsNothing);
  });

  testWidgets('a tile card gives too', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppTileCard(title: 'row', onTap: () {}),
        ),
      ),
    );
    expect(find.byType(PressScale), findsOneWidget);
  });

  testWidgets('with animations off the card stays still', (tester) async {
    await pump(tester, onTap: () {}, reduceMotion: true);
    final press = await tester.startGesture(
      tester.getCenter(find.text('card')),
    );
    await tester.pump();
    expect(scaleOf(tester), 1);
    await press.up();
  });
}
