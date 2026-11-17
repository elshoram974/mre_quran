import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/presentation/flip/book_flip.dart';
import 'package:mre_quran/features/mushaf/presentation/flip/page_curl_painter.dart';
import 'package:mre_quran/features/mushaf/presentation/flip/paper_shade_painter.dart';

Future<List<int>> _pump(
  WidgetTester tester, {
  required bool realistic,
  required bool spread,
  int page = 5,
}) async {
  tester.view.physicalSize = Size(spread ? 900 : 400, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final changes = <int>[];
  var current = page;
  await tester.pumpWidget(
    MaterialApp(
      home: StatefulBuilder(
        builder: (context, setState) => BookFlip(
          pageCount: 20,
          spread: spread,
          realistic: realistic,
          page: current,
          onPageChanged: (p) => setState(() {
            changes.add(p);
            current = p;
          }),
          pageBuilder: (context, p) => Center(child: Text('page $p')),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return changes;
}

Future<void> _drag(WidgetTester tester, double dx) async {
  final gesture = await tester.startGesture(const Offset(200, 350));
  for (var i = 0; i < 30; i++) {
    await gesture.moveBy(Offset(dx / 30, 0));
    await tester.pump(const Duration(milliseconds: 8));
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  for (final realistic in [true, false]) {
    final style = realistic ? 'realistic' : 'sliding';

    testWidgets('$style single: a drag to the right turns forward', (
      tester,
    ) async {
      final changes = await _pump(tester, realistic: realistic, spread: false);
      await _drag(tester, 260);
      expect(changes, [6]);
      expect(find.text('page 6').hitTestable(), findsOneWidget);
    });

    testWidgets('$style single: a drag to the left turns back', (tester) async {
      final changes = await _pump(tester, realistic: realistic, spread: false);
      await _drag(tester, -260);
      expect(changes, [4]);
    });

    testWidgets('$style spread: turning moves two pages', (tester) async {
      final changes = await _pump(tester, realistic: realistic, spread: true);
      expect(find.text('page 5').hitTestable(), findsOneWidget);
      expect(find.text('page 6').hitTestable(), findsOneWidget);
      await _drag(tester, 500);
      expect(changes, [7]);
      expect(find.text('page 7').hitTestable(), findsOneWidget);
      expect(find.text('page 8').hitTestable(), findsOneWidget);
    });
  }

  /// Drags halfway and leaves the finger down.
  Future<TestGesture> halfway(WidgetTester tester, double dx) async {
    final gesture = await tester.startGesture(const Offset(200, 350));
    for (var i = 0; i < 30; i++) {
      await gesture.moveBy(Offset(dx / 30, 0));
      await tester.pump(const Duration(milliseconds: 8));
    }
    return gesture;
  }

  Finder curl() => find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter is PageCurlPainter,
  );

  testWidgets('single: a left-hand page turns its leaf over the spine', (
    tester,
  ) async {
    final changes = await _pump(
      tester,
      realistic: true,
      spread: false,
      page: 4,
    );
    final gesture = await halfway(tester, 210);
    // Mid-turn the leaf of page 4 is in the air, with page 5 on its back.
    // Under it lies page 6, the next left-hand page, and beyond the spine
    // the page it will land on, page 3.
    expect(curl(), findsOneWidget);
    final painter =
        tester.widget<CustomPaint>(curl()).painter! as PageCurlPainter;
    expect(painter.back, isNotNull, reason: 'its back is page 5, not blank');
    expect(find.text('page 6'), findsOneWidget);
    expect(find.text('page 3'), findsOneWidget);
    expect(
      tester.getRect(find.text('page 3')).center.dx,
      greaterThan(tester.getRect(find.text('page 6')).center.dx),
      reason: 'the right-hand page lies to the right of the left-hand one',
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(changes, [5]);
    expect(find.text('page 5').hitTestable(), findsOneWidget);
    expect(find.text('page 3').hitTestable(), findsNothing);
  });

  testWidgets('single: an odd page slides to the page facing it', (
    tester,
  ) async {
    final changes = await _pump(tester, realistic: true, spread: false);
    final gesture = await halfway(tester, 210);
    // No leaf turns inside one spread: page 5 moves right, 6 comes from the
    // left.
    expect(curl(), findsNothing);
    expect(tester.getRect(find.text('page 5')).center.dx, greaterThan(200));
    expect(tester.getRect(find.text('page 6')).center.dx, lessThan(200));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(changes, [6]);
    expect(find.text('page 6').hitTestable(), findsOneWidget);
  });

  testWidgets('single: going back slides within a spread and turns across', (
    tester,
  ) async {
    final changes = await _pump(
      tester,
      realistic: true,
      spread: false,
      page: 6,
    );
    var gesture = await halfway(tester, -210);
    expect(curl(), findsNothing, reason: '6 back to 5 is one spread');
    await gesture.up();
    await tester.pumpAndSettle();
    gesture = await halfway(tester, -210);
    expect(curl(), findsOneWidget, reason: '5 back to 4 turns the leaf');
    await gesture.up();
    await tester.pumpAndSettle();
    expect(changes, [5, 4]);
    expect(find.text('page 4').hitTestable(), findsOneWidget);
  });

  testWidgets('cannot turn before the first page or past the last', (
    tester,
  ) async {
    final first = await _pump(tester, realistic: true, spread: false, page: 1);
    await _drag(tester, -300);
    expect(first, isEmpty);
  });

  /// The lead of the painter drawing the turning sheet.
  double leadOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((w) => w.painter)
      .whereType<PageCurlPainter>()
      .single
      .lead;

  testWidgets('spread: the sheet bends one way going forward and the other '
      'going back', (tester) async {
    await _pump(tester, realistic: true, spread: true, page: 4);
    var gesture = await halfway(tester, 210);
    expect(leadOf(tester), closeTo(1, 0.02));
    await gesture.up();
    await tester.pumpAndSettle();
    gesture = await halfway(tester, -210);
    expect(leadOf(tester), closeTo(-1, 0.1));
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a turn tells the reader it began, before anything moves', (
    tester,
  ) async {
    var began = 0;
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: BookFlip(
          pageCount: 20,
          spread: false,
          realistic: true,
          page: 4,
          onTurnStart: () => began++,
          onPageChanged: (_) {},
          pageBuilder: (context, p) => Center(child: Text('page $p')),
        ),
      ),
    );
    final gesture = await tester.startGesture(const Offset(200, 350));
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    expect(began, 1);
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('single: going back turns the leaf back over the spine', (
    tester,
  ) async {
    final changes = await _pump(
      tester,
      realistic: true,
      spread: false,
      page: 5,
    );
    // 5 back to 4 is the turn from 4 to 5 run backwards: the same leaf, the
    // same two pages either side of the spine.
    final gesture = await halfway(tester, -210);
    expect(curl(), findsOneWidget);
    expect(find.text('page 6'), findsOneWidget);
    expect(find.text('page 3'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(changes, [4]);
    expect(find.text('page 4').hitTestable(), findsOneWidget);
  });

  group('each page is shaded as the side of the book it is', () {
    PaperShadePainter shadeOf(WidgetTester tester, String text) =>
        tester
                .widget<CustomPaint>(
                  find
                      .ancestor(
                        of: find.text(text),
                        matching: find.byWidgetPredicate(
                          (w) =>
                              w is CustomPaint &&
                              w.foregroundPainter is PaperShadePainter,
                        ),
                      )
                      .first,
                )
                .foregroundPainter!
            as PaperShadePainter;

    testWidgets('an odd page is a right-hand page, an even one a left-hand '
        'page', (tester) async {
      await _pump(tester, realistic: true, spread: true, page: 5);
      expect(shadeOf(tester, 'page 5').rightHand, isTrue);
      expect(shadeOf(tester, 'page 6').rightHand, isFalse);
    });

    testWidgets('the sides do not swap in a left-to-right app', (tester) async {
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: BookFlip(
              pageCount: 20,
              spread: true,
              page: 5,
              onPageChanged: (_) {},
              pageBuilder: (context, p) => Center(child: Text('page $p')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(shadeOf(tester, 'page 5').rightHand, isTrue);
      expect(
        tester.getCenter(find.text('page 5')).dx,
        greaterThan(tester.getCenter(find.text('page 6')).dx),
        reason: 'the odd page is on the right in every language',
      );
    });

    testWidgets('the stack under a page grows as that side of the book fills', (
      tester,
    ) async {
      await _pump(tester, realistic: true, spread: true, page: 3);
      final early = shadeOf(tester, 'page 3').stack;
      final earlyLeft = shadeOf(tester, 'page 4').stack;
      await tester.pumpWidget(const SizedBox.shrink());
      await _pump(tester, realistic: true, spread: true, page: 17);
      expect(shadeOf(tester, 'page 17').stack, greaterThan(early));
      expect(shadeOf(tester, 'page 18').stack, lessThan(earlyLeft));
      expect(PaperShadePainter.edgesFor(0), 1);
      expect(
        PaperShadePainter.edgesFor(1),
        greaterThan(PaperShadePainter.edgesFor(0.2)),
      );
    });

    testWidgets('the plain sliding turn has no book shading', (tester) async {
      await _pump(tester, realistic: false, spread: false);
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.foregroundPainter is PaperShadePainter,
        ),
        findsNothing,
      );
    });
  });

  testWidgets('pages under the visible one are built but painted only while '
      'a turn needs them', (tester) async {
    await _pump(tester, realistic: true, spread: false, page: 4);
    // At rest: the neighbours exist, ready, and are not drawn.
    expect(find.text('page 4'), findsOneWidget);
    expect(find.text('page 5'), findsNothing);
    expect(find.text('page 5', skipOffstage: false), findsOneWidget);
    expect(find.text('page 3', skipOffstage: false), findsOneWidget);
    // A leaf turn begins: the pages that can be the sheet's faces are drawn,
    // so a snapshot can be taken.
    final gesture = await tester.startGesture(const Offset(200, 350));
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    expect(find.text('page 5'), findsOneWidget);
    // Once the sheet has its snapshots, only what shows around it is drawn:
    // page 6 under the sheet and page 3 beyond the spine.
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump(const Duration(milliseconds: 8));
    }
    expect(find.text('page 5'), findsNothing);
    expect(find.text('page 6'), findsOneWidget);
    // The turn lands on page 5, and its neighbours go quiet again.
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('page 5'), findsOneWidget);
    expect(find.text('page 6'), findsNothing);
  });

  for (final realistic in [true, false]) {
    final style = realistic ? 'realistic' : 'sliding';

    testWidgets('$style: a page is built once and kept through a turn', (
      tester,
    ) async {
      // A page that is thrown away and built again at the start or the end
      // of a turn loses its state and has to load its artwork again.
      final built = <int, int>{};
      tester.view.physicalSize = const Size(400, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var current = 5;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => BookFlip(
              pageCount: 20,
              spread: false,
              realistic: realistic,
              page: current,
              onPageChanged: (p) => setState(() => current = p),
              pageBuilder: (context, p) => _CountedPage(
                page: p,
                onCreated: () => built[p] = (built[p] ?? 0) + 1,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(built[5], 1);
      // Forward to 6: page 5 stays one element from rest through the turn,
      // and page 6 from the moment it appears to its rest.
      await _drag(tester, 260);
      expect(find.text('page 6').hitTestable(), findsOneWidget);
      expect(built[5], 1, reason: 'page 5 was not rebuilt when the turn began');
      expect(built[6], 1, reason: 'page 6 was not rebuilt when it landed');
      // A turn that is let go half way springs back: still the same page 6.
      await _drag(tester, 60);
      expect(find.text('page 6').hitTestable(), findsOneWidget);
      expect(built[6], 1);
    });
  }
}

/// A page that reports each time a new state is made for it.
class _CountedPage extends StatefulWidget {
  const _CountedPage({required this.page, required this.onCreated});

  final int page;
  final VoidCallback onCreated;

  @override
  State<_CountedPage> createState() => _CountedPageState();
}

class _CountedPageState extends State<_CountedPage> {
  @override
  void initState() {
    super.initState();
    widget.onCreated();
  }

  @override
  Widget build(BuildContext context) =>
      Center(child: Text('page ${widget.page}'));
}
