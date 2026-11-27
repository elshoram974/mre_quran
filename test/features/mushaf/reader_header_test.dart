import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/core/theme/app_tokens.dart';
import 'package:mre_quran/features/mushaf/presentation/reader_bar.dart';

const String _surah = 'البقرة';
const String _juz = 'الجزء ٣';
const String _hizb = 'نصف الحزب ٥';
const String _longHizb = 'ثلاثة أرباع الحزب ٦٠';

/// The header's own side padding, and a pill's at each side of its text.
const double _edge = 8;
const double _pad = AppTokens.readerChipPadding;

/// Pumps the row above a page, [width] wide, as the page labels build it:
/// the surah and an arrow at the start, the juz and the hizb at the end.
Future<void> _pump(
  WidgetTester tester, {
  required double width,
  TextDirection direction = TextDirection.rtl,
  double textScale = 1,
  String hizb = _hizb,
  Widget middle = const SizedBox.shrink(),
  ThemeData? theme,
}) async {
  ReaderChip chip(String label) =>
      ReaderChip(label: label, tooltip: label, onPressed: () {});
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: Align(
              alignment: AlignmentDirectional.topStart,
              child: SizedBox(
                width: width,
                child: ReaderHeader(
                  start: [
                    chip(_surah),
                    ReaderChip(
                      icon: Icons.chevron_left_rounded,
                      tooltip: 'next',
                      onPressed: () {},
                    ),
                  ],
                  middle: middle,
                  end: [chip(_juz), chip(hizb)],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The pill around [label], or around the arrow.
Rect _pill(WidgetTester tester, [String? label]) => tester.getRect(
  find
      .ancestor(
        of: label == null
            ? find.byIcon(Icons.chevron_left_rounded)
            : find.text(label),
        matching: find.byType(Material),
      )
      .first,
);

double _textWidth(WidgetTester tester, String label) =>
    tester.getSize(find.text(label)).width;

/// Whether [label] lost its end to an ellipsis.
bool _cut(WidgetTester tester, String label) =>
    tester.renderObject<RenderParagraph>(find.text(label)).didExceedMaxLines;

/// The width at which the row holds its chips with nothing to spare: every
/// pill as wide as it likes, and [gap] between neighbours.
Future<double> _snug(
  WidgetTester tester, {
  required double gap,
  String hizb = _hizb,
}) async {
  await _pump(tester, width: 780, hizb: hizb);
  var pills = _pill(tester).width;
  for (final label in [_surah, _juz, hizb]) {
    // A chip's box is its pill's width rounded up to a whole pixel.
    pills += _pill(tester, label).width.ceilToDouble();
  }
  return pills + 3 * gap + 2 * _edge;
}

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('with room every chip keeps its own width, the sides at the '
        'edges, in $direction', (tester) async {
      await _pump(tester, width: 700, direction: direction);
      final row = tester.getRect(find.byType(ReaderHeader));
      final surah = _pill(tester, _surah);
      final arrow = _pill(tester);
      final juz = _pill(tester, _juz);
      final hizb = _pill(tester, _hizb);
      for (final label in [_surah, _juz, _hizb]) {
        expect(
          _pill(tester, label).width,
          closeTo(_textWidth(tester, label) + 2 * _pad, 0.01),
        );
        expect(_cut(tester, label), isFalse, reason: label);
      }
      // The surah leads and its arrow follows; the hizb ends the row, the
      // juz before it.
      if (direction == TextDirection.rtl) {
        expect(surah.right, closeTo(row.right - _edge, 1));
        expect(surah.left - arrow.right, closeTo(AppTokens.spaceSmall, 1));
        expect(hizb.left, closeTo(row.left + _edge, 1));
        expect(juz.left - hizb.right, closeTo(AppTokens.spaceSmall, 1));
        expect(arrow.left, greaterThan(juz.right));
      } else {
        expect(surah.left, closeTo(row.left + _edge, 1));
        expect(arrow.left - surah.right, closeTo(AppTokens.spaceSmall, 1));
        expect(hizb.right, closeTo(row.right - _edge, 1));
        expect(hizb.left - juz.right, closeTo(AppTokens.spaceSmall, 1));
        expect(arrow.right, lessThan(juz.left));
      }
    });
  }

  testWidgets('a long end side takes the room the start does not need', (
    tester,
  ) async {
    final width = await _snug(tester, gap: 8, hizb: _longHizb);
    await _pump(tester, width: width, hizb: _longHizb);
    final row = tester.getRect(find.byType(ReaderHeader));
    // The juz and the hizb need more than half the row, and have it.
    expect(_pill(tester, _juz).right, greaterThan(row.center.dx));
    for (final label in [_surah, _juz, _longHizb]) {
      expect(_cut(tester, label), isFalse, reason: label);
      expect(
        _pill(tester, label).width,
        closeTo(_textWidth(tester, label) + 2 * _pad, 0.01),
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a short row closes its gaps, then tightens its pills, and '
      'cuts no text', (tester) async {
    final snug = await _snug(tester, gap: AppTokens.spaceTiny);
    // Six short of its wish for wide gaps: three gaps of six.
    await _pump(tester, width: snug + 6);
    expect(
      _pill(tester).right,
      closeTo(_pill(tester, _surah).left - 6, 1),
      reason: 'the gap',
    );
    for (final label in [_surah, _juz, _hizb]) {
      expect(
        _pill(tester, label).width,
        closeTo(_textWidth(tester, label) + 2 * _pad, 0.01),
      );
    }
    // Eighteen short even with narrow gaps: each of the three pills spares
    // six, three from each side.
    await _pump(tester, width: snug - 18);
    for (final label in [_surah, _juz, _hizb]) {
      expect(
        _pill(tester, label).width,
        closeTo(_textWidth(tester, label) + 2 * (_pad - 3), 1),
        reason: label,
      );
      expect(_cut(tester, label), isFalse, reason: label);
    }
    // As tight as they go, and still whole.
    await _pump(tester, width: snug - 3 * ReaderChip.give);
    for (final label in [_surah, _juz, _hizb]) {
      expect(
        _pill(tester, label).width,
        closeTo(_textWidth(tester, label) + 2 * AppTokens.spaceSmall, 1),
        reason: label,
      );
      expect(_cut(tester, label), isFalse, reason: label);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('shorter still, the surah\'s name is cut first, then the hizb, '
      'and the juz keeps its number the longest', (tester) async {
    final snug = await _snug(tester, gap: AppTokens.spaceTiny);
    final tight = snug - 3 * ReaderChip.give;
    await _pump(tester, width: tight - 20);
    expect(_cut(tester, _surah), isTrue);
    expect(_cut(tester, _juz), isFalse);
    expect(_cut(tester, _hizb), isFalse);

    // The name gives down to a touch target; then the hizb gives.
    await _pump(tester, width: 780);
    final name =
        _pill(tester, _surah).width.ceilToDouble() -
        ReaderChip.give -
        AppTokens.minTarget;
    await _pump(tester, width: tight - name - 20);
    expect(_pill(tester, _surah).width, closeTo(AppTokens.minTarget, 0.01));
    expect(_cut(tester, _surah), isTrue);
    expect(_cut(tester, _hizb), isTrue);
    expect(_cut(tester, _juz), isFalse);
    expect(tester.takeException(), isNull);
  });

  for (final direction in TextDirection.values) {
    testWidgets('in the narrowest row, at the largest text, nothing leaves '
        'the row, in $direction', (tester) async {
      for (final width in [320.0, 200.0, 120.0]) {
        await _pump(
          tester,
          width: width,
          direction: direction,
          textScale: 2,
          hizb: _longHizb,
        );
        final row = tester.getRect(find.byType(ReaderHeader));
        for (final pill in [
          _pill(tester),
          for (final label in [_surah, _juz, _longHizb]) _pill(tester, label),
        ]) {
          expect(pill.left, greaterThanOrEqualTo(row.left), reason: '$width');
          expect(pill.right, lessThanOrEqualTo(row.right), reason: '$width');
        }
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('the text scale stops at 1.3, as the row has fixed room', (
    tester,
  ) async {
    await _pump(tester, width: 780);
    final plain = _textWidth(tester, _hizb);
    await _pump(tester, width: 780, textScale: 2);
    expect(_textWidth(tester, _hizb), closeTo(plain * 1.3, 0.5));
    expect(
      tester.getSize(find.byType(ReaderHeader)).height,
      AppTokens.readerHeaderExtent,
    );
  });

  testWidgets('the middle sits in the centre, and steps aside when a side '
      'needs its place', (tester) async {
    const key = ValueKey<String>('middle');
    const middle = SizedBox(key: key, width: 40, height: 20);
    await _pump(tester, width: 780, middle: middle);
    final row = tester.getRect(find.byType(ReaderHeader));
    expect(tester.getCenter(find.byKey(key)).dx, closeTo(row.center.dx, 0.01));

    // The long end side reaches past the centre: the middle keeps clear of
    // it, between the two sides.
    await _pump(tester, width: 620, hizb: _longHizb, middle: middle);
    final box = tester.getRect(find.byKey(key));
    expect(box.width, 40);
    expect(box.left, greaterThan(_pill(tester, _juz).right));
    expect(box.right, lessThan(_pill(tester).left));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tap on a chip made narrower still reaches it', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: ReaderHeader(
              start: [
                ReaderChip(label: _surah, tooltip: _surah, onPressed: () {}),
              ],
              middle: const SizedBox.shrink(),
              end: [
                ReaderChip(
                  label: _longHizb,
                  tooltip: _longHizb,
                  onPressed: () => taps++,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text(_longHizb));
    expect(taps, 1);
  });

  testWidgets('the chips take the dark theme\'s colours', (tester) async {
    await _pump(tester, width: 700, theme: AppTheme.dark);
    final scheme = AppTheme.dark.colorScheme;
    final pill = tester.widget<Material>(
      find
          .ancestor(of: find.text(_hizb), matching: find.byType(Material))
          .first,
    );
    expect(pill.color, scheme.secondaryContainer.withValues(alpha: 0.7));
    expect(
      tester.widget<Text>(find.text(_hizb)).style?.color,
      scheme.onSecondaryContainer,
    );
  });
}
