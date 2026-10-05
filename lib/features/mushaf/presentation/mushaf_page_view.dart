import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../quran_index/domain/quran_metadata.dart';
import '../../quran_text/domain/quran_text.dart';
import '../../settings/application/digits_provider.dart';
import 'mushaf_ornaments.dart';
import 'mushaf_page_frame.dart';

/// One Mushaf page drawn like a printed copy: a framed page, the surah and
/// juz at the top, a banner at each surah opening (name, order, ayah count,
/// Meccan or Medinan), the basmala, the ayahs with their markers, and the
/// page number in a medallion.
///
/// The ayahs on a page follow the Madinah page starts. Line breaks come from
/// the text layout, not the printed Mushaf, until layout data is approved.
class MushafPageView extends StatefulWidget {
  /// Creates page [page] of [text].
  const MushafPageView({
    super.key,
    required this.text,
    required this.page,
    required this.fontScale,
    required this.onTap,
    this.onAyahLongPress,
    this.bookmarked = const {},
    this.selected,
  });

  /// The verified text.
  final QuranText text;

  /// Page number, 1–604.
  final int page;

  /// Size of the text relative to the default.
  final double fontScale;

  /// Called when the page is tapped.
  final VoidCallback onTap;

  /// Called with the ayah that was pressed and held.
  final ValueChanged<AyahRef>? onAyahLongPress;

  /// Ayahs the reader bookmarked. Their markers are coloured differently.
  final Set<AyahRef> bookmarked;

  /// The ayah whose actions are open, highlighted on the page.
  final AyahRef? selected;

  static const double _minSize = 15;
  static const double _maxSize = 34;
  static const double _bannerExtent = 74;
  static const double _lineHeight = 2.05;

  @override
  State<MushafPageView> createState() => _MushafPageViewState();
}

class _MushafPageViewState extends State<MushafPageView> {
  final Map<AyahRef, LongPressGestureRecognizer> _recognizers = {};

  QuranText get text => widget.text;

  String _n(int value) => formatDigits(value, arabic: true);

  @override
  void dispose() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    super.dispose();
  }

  LongPressGestureRecognizer _recognizerFor(AyahRef ref) =>
      _recognizers.putIfAbsent(
        ref,
        () =>
            LongPressGestureRecognizer()
              ..onLongPress = () => widget.onAyahLongPress?.call(ref),
      );

  /// The page's content in reading order.
  List<_Segment> _segments(ColorScheme scheme, String Function(String) label) {
    final metadata = text.metadata;
    final segments = <_Segment>[];
    var spans = <InlineSpan>[];
    void flush() {
      if (spans.isEmpty) return;
      segments.add(_Paragraph(spans));
      spans = <InlineSpan>[];
    }

    for (final ayah in text.pageAyahs(widget.page)) {
      if (ayah.ref.ayah == 1) {
        flush();
        segments.add(_Banner(metadata.surah(ayah.ref.surah)));
        if (text.hasBasmala(ayah.ref.surah)) {
          segments.add(_Basmala(text.basmala));
        }
      }
      final highlight = ayah.ref == widget.selected
          ? scheme.primary.withValues(alpha: 0.16)
          : null;
      final recognizer = widget.onAyahLongPress == null
          ? null
          : _recognizerFor(ayah.ref);
      if (metadata.rubStartingAt(ayah.ref) != null) {
        spans.add(
          TextSpan(
            text: '\u06DE ',
            style: TextStyle(color: scheme.primary),
          ),
        );
      }
      spans
        ..add(
          TextSpan(
            text: '${ayah.text} ',
            recognizer: recognizer,
            style: TextStyle(backgroundColor: highlight),
          ),
        )
        ..add(
          TextSpan(
            text: '\u06DD${_n(ayah.ref.ayah)} ',
            recognizer: recognizer,
            style: TextStyle(
              color: widget.bookmarked.contains(ayah.ref)
                  ? scheme.tertiary
                  : scheme.primary,
              fontWeight: widget.bookmarked.contains(ayah.ref)
                  ? FontWeight.bold
                  : null,
              backgroundColor: highlight,
            ),
            semanticsLabel: label('${ayah.ref.ayah}'),
          ),
        );
    }
    flush();
    return segments;
  }

  /// Largest font size at which every segment fits in [size].
  static double _fittedSize(List<_Segment> segments, Size size) {
    double heightAt(double fontSize) {
      final style = TextStyle(
        fontFamily: AppTokens.quranFontFamily,
        fontSize: fontSize,
        height: MushafPageView._lineHeight,
      );
      var total = 0.0;
      for (final segment in segments) {
        switch (segment) {
          case _Banner():
            total += MushafPageView._bannerExtent;
          case _Basmala(:final text):
            total +=
                _measure(TextSpan(text: text, style: style), size.width) + 4;
          case _Paragraph(:final spans):
            total += _measure(
              TextSpan(children: spans, style: style),
              size.width,
            );
        }
      }
      return total;
    }

    var low = MushafPageView._minSize;
    var high = MushafPageView._maxSize;
    if (heightAt(low) > size.height) return low;
    for (var i = 0; i < 9; i++) {
      final mid = (low + high) / 2;
      if (heightAt(mid) <= size.height) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return low;
  }

  static double _measure(InlineSpan span, double width) {
    final painter = TextPainter(
      text: span,
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
    )..layout(maxWidth: width);
    final height = painter.height;
    painter.dispose();
    return height;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = MushafPageFrame.labelStyle(scheme);
    final segments = _segments(scheme, context.l10n.ayahNumber);

    return MushafPageFrame(
      metadata: text.metadata,
      page: widget.page,
      onTap: widget.onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fitted = _fittedSize(segments, constraints.biggest);
          final quran = TextStyle(
            fontFamily: AppTokens.quranFontFamily,
            fontSize: fitted * widget.fontScale,
            height: MushafPageView._lineHeight,
            color: scheme.onSurface,
          );
          // Quran text size follows the reader's own setting, so it is not
          // scaled again by the system. Larger text scrolls in the frame.
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final segment in segments)
                    switch (segment) {
                      _Banner(:final surah) => _SurahBanner(
                        surah: surah,
                        label: label,
                        number: _n,
                      ),
                      _Basmala(:final text) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          text,
                          textAlign: TextAlign.center,
                          textScaler: TextScaler.noScaling,
                          style: quran,
                        ),
                      ),
                      _Paragraph(:final spans) => Text.rich(
                        TextSpan(children: spans),
                        textAlign: TextAlign.justify,
                        textScaler: TextScaler.noScaling,
                        style: quran,
                      ),
                    },
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

sealed class _Segment {
  const _Segment();
}

class _Banner extends _Segment {
  const _Banner(this.surah);
  final Surah surah;
}

class _Basmala extends _Segment {
  const _Basmala(this.text);
  final String text;
}

class _Paragraph extends _Segment {
  const _Paragraph(this.spans);
  final List<InlineSpan> spans;
}

class _SurahBanner extends StatelessWidget {
  const _SurahBanner({
    required this.surah,
    required this.label,
    required this.number,
  });

  final Surah surah;
  final TextStyle label;
  final String Function(int) number;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final side = label.copyWith(
      fontSize: 13,
      color: scheme.onSecondaryContainer,
    );
    final revelation = surah.revelation == Revelation.meccan
        ? l10n.revelationMeccan
        : l10n.revelationMedinan;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: MushafPageView._bannerExtent - 20,
        child: CustomPaint(
          painter: SurahBannerPainter(
            fill: scheme.secondaryContainer,
            stroke: scheme.primary.withValues(alpha: 0.6),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 42),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.surahOrderLabel(number(surah.number)),
                    style: side,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                  ),
                ),
                Flexible(
                  flex: 2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      l10n.surahTitle(surah.arabicName),
                      style: label.copyWith(
                        fontSize: 22,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${l10n.surahAyahsLabel(number(surah.ayahCount))}\n$revelation',
                    style: side,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
