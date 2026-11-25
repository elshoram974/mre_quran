import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/presentation/flip/book_flip.dart';
import 'package:mre_quran/features/mushaf/presentation/flip/curl_mesh.dart';
import 'package:mre_quran/features/mushaf/presentation/flip/page_curl_painter.dart';
import 'package:mre_quran/features/mushaf/presentation/flip/paper_shade_painter.dart';

/// Length of the row of paper at [y] across the whole leaf, measured along
/// the folded leaf.
double bentLength(CurlFold fold, double y) {
  var length = 0.0;
  var last = fold.place(0, y);
  const samples = 900;
  for (var i = 1; i <= samples; i++) {
    final now = fold.place(fold.width * i / samples, y);
    length += math.sqrt(
      math.pow(now.x - last.x, 2) +
          math.pow(now.y - last.y, 2) +
          math.pow(now.z - last.z, 2),
    );
    last = now;
  }
  return length;
}

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

  /// The painter drawing the turning leaf.
  PageCurlPainter painterOf(WidgetTester tester) =>
      tester.widget<CustomPaint>(curl()).painter! as PageCurlPainter;

  /// The fold of the turning leaf, and where its canvas is on screen.
  ({CurlFold fold, Rect canvas, PageCurlPainter painter}) foldOf(
    WidgetTester tester,
  ) {
    final canvas = tester.getRect(curl());
    final painter = painterOf(tester);
    return (
      fold: painter.foldFor(canvas.size),
      canvas: canvas,
      painter: painter,
    );
  }

  for (final direction in TextDirection.values) {
    final app = direction == TextDirection.rtl ? 'Arabic' : 'English';

    group('$app app: the leaf folds like paper, on the physical sides of the '
        'book', () {
      Future<void> pumpBook(WidgetTester tester, {required int page}) async {
        tester.view.physicalSize = const Size(900, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: direction,
              child: BookFlip(
                pageCount: 20,
                spread: true,
                page: page,
                onPageChanged: (_) {},
                pageBuilder: (context, p) => Center(child: Text('page $p')),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      const spine = 450.0;

      testWidgets('going forward the left-hand page folds from its left edge '
          'and shows the next page', (tester) async {
        await pumpBook(tester, page: 3);
        final gesture = await halfway(tester, 210);
        final (:fold, :canvas, :painter) = foldOf(tester);
        expect(painter.fromRight, isFalse);
        // The leaf is the left-hand page, hinged on the spine.
        expect(canvas.left, 0);
        expect(canvas.right, spine);
        final h = canvas.height;
        // Held in the middle of the edge, the fold runs straight down the
        // left-hand page.
        expect(fold.normalY, 0);
        final foldAt = canvas.left + fold.foldX;
        expect(foldAt, inExclusiveRange(0, spine));
        // Between the fold and the spine the page lies where it was.
        final flat = fold.place(fold.foldX + 5, h / 2);
        expect(canvas.left + flat.x, closeTo(foldAt + 5, 1e-6));
        expect(flat.z, 0);
        expect(fold.showsFront(fold.foldX + 5, h / 2), isTrue);
        // The free edge has come up and over toward the spine, upside down:
        // the back of the leaf, the next page, faces the reader there.
        final edge = fold.place(0, h / 2);
        expect(canvas.left + edge.x, inExclusiveRange(foldAt, spine));
        expect(edge.z, greaterThan(0));
        expect(fold.showsFront(0, h / 2), isFalse);
        // Folded, not stretched: a row of the page keeps its length.
        expect(bentLength(fold, h / 2), closeTo(canvas.width, 0.5));
        await gesture.up();
        await tester.pumpAndSettle();
      });

      testWidgets('going back the right-hand page folds from its right edge '
          'and shows the page before', (tester) async {
        await pumpBook(tester, page: 5);
        final gesture = await halfway(tester, -210);
        final (:fold, :canvas, :painter) = foldOf(tester);
        expect(painter.fromRight, isTrue);
        final h = canvas.height;
        final w = canvas.width;
        expect(fold.normalY, 0);
        // The fold is on the right-hand page this time.
        final foldAt = canvas.left + 2 * w - fold.foldX;
        expect(foldAt, inExclusiveRange(spine, 2 * spine));
        // Between the spine and the fold the right-hand page lies where it
        // was, its own page showing.
        final flat = fold.place(fold.foldX + 5, h / 2);
        expect(canvas.left + flat.x, closeTo(foldAt - 5, 1e-6));
        expect(fold.showsFront(fold.foldX + 5, h / 2), isFalse);
        // Its right edge has come over toward the spine, showing the page
        // before.
        final edge = fold.place(0, h / 2);
        expect(canvas.left + edge.x, inExclusiveRange(spine, foldAt));
        expect(edge.z, greaterThan(0));
        expect(fold.showsFront(0, h / 2), isTrue);
        expect(bentLength(fold, h / 2), closeTo(w, 0.5));
        await gesture.up();
        await tester.pumpAndSettle();
      });

      testWidgets('held near a corner, that corner lifts first', (
        tester,
      ) async {
        await pumpBook(tester, page: 3);
        var gesture = await tester.startGesture(const Offset(300, 660));
        for (var i = 0; i < 8; i++) {
          await gesture.moveBy(const Offset(5, 0));
          await tester.pump(const Duration(milliseconds: 8));
        }
        final low = foldOf(tester);
        final h = low.canvas.height;
        expect(low.painter.grip, greaterThan(0.8));
        expect(low.fold.depth(0, h), greaterThan(low.fold.depth(0, 0)));
        expect(low.fold.place(0, 0).z, 0, reason: 'the top corner still lies');
        expect(low.fold.place(0, h).z, greaterThan(0));
        await gesture.up();
        await tester.pumpAndSettle();

        // Going back, held high on the right-hand page's edge.
        gesture = await tester.startGesture(const Offset(600, 40));
        for (var i = 0; i < 8; i++) {
          await gesture.moveBy(const Offset(-5, 0));
          await tester.pump(const Duration(milliseconds: 8));
        }
        final high = foldOf(tester);
        expect(high.painter.fromRight, isTrue);
        expect(high.painter.grip, lessThan(-0.8));
        expect(high.fold.depth(0, 0), greaterThan(high.fold.depth(0, h)));
        expect(high.fold.place(0, h).z, 0, reason: 'the bottom corner lies');
        await gesture.up();
        await tester.pumpAndSettle();
      });
    });
  }

  testWidgets('a leaf caught while it settles keeps the side it was lifted '
      'from', (tester) async {
    await _pump(tester, realistic: true, spread: true, page: 3);
    var gesture = await halfway(tester, 380);
    expect(painterOf(tester).fromRight, isFalse);
    await gesture.up();
    // The spring takes it on toward the right-hand side.
    await tester.pump(const Duration(milliseconds: 40));
    await tester.pump(const Duration(milliseconds: 40));
    expect(curl(), findsOneWidget);
    // Caught past half way: the hand now holds the leaf nearer the right,
    // but it is the same leaf, lifted from the left, and it does not jump.
    gesture = await tester.startGesture(const Offset(400, 350));
    await gesture.moveBy(const Offset(-20, 0));
    await tester.pump(const Duration(milliseconds: 8));
    await gesture.moveBy(const Offset(-20, 0));
    await tester.pump(const Duration(milliseconds: 8));
    expect(curl(), findsOneWidget);
    expect(painterOf(tester).fromRight, isFalse);
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('with animations off a turn lands at once', (tester) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final changes = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: BookFlip(
              pageCount: 20,
              spread: false,
              page: 4,
              onPageChanged: changes.add,
              pageBuilder: (context, p) => Center(child: Text('page $p')),
            ),
          ),
        ),
      ),
    );
    final gesture = await halfway(tester, 210);
    // The hand moves the leaf itself; only what it lets go of jumps.
    expect(curl(), findsOneWidget);
    await gesture.up();
    await tester.pump();
    expect(changes, [5]);
    expect(curl(), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
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

    /// Whether [text]'s page is drawn: hidden pages sit under a clear
    /// Opacity, which skips painting them but keeps them live.
    bool drawn(String text) => tester
        .widgetList<Opacity>(
          find.ancestor(of: find.text(text), matching: find.byType(Opacity)),
        )
        .every((o) => o.opacity > 0);
    // At rest: the neighbours exist, ready, and are not drawn.
    expect(drawn('page 4'), isTrue);
    expect(find.text('page 5'), findsOneWidget);
    expect(drawn('page 5'), isFalse);
    expect(drawn('page 3'), isFalse);
    // A leaf turn begins: the pages that can be the sheet's faces are drawn,
    // so a snapshot can be taken.
    final gesture = await tester.startGesture(const Offset(200, 350));
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    expect(drawn('page 5'), isTrue);
    await gesture.up();
    await tester.pumpAndSettle();
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
