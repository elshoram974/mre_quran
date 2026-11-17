import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/quran_colors.dart';
import '../../../core/widgets/pinch_zoom.dart';
import '../../quran_index/domain/quran_metadata.dart';
import '../../quran_text/domain/ayah_range.dart';
import '../../quran_text/domain/quran_text.dart';
import '../../settings/application/digits_provider.dart';
import '../../settings/domain/app_settings.dart';
import '../../startup/presentation/reader_painted_mark.dart';
import 'mushaf_page_frame.dart';
import 'surah_banner.dart';

/// One Mushaf page drawn like a printed copy: a banner at each surah opening,
/// the basmala, and the ayahs with their markers, inside the reader's frame.
///
/// The ayahs on a page follow the Madinah page starts, in the King Fahd
/// Complex script and font when the text holds them. Line breaks come from
/// the text layout, not the printed Mushaf. Two fingers change the text size.
class MushafPageView extends StatefulWidget {
  /// Creates page [page] of [text].
  const MushafPageView({
    super.key,
    required this.text,
    required this.page,
    required this.fontScale,
    required this.onTap,
    this.digits = _defaultDigits,
    this.onAyahLongPress,
    this.onFontScaleChanged,
    this.bookmarked = const {},
    this.selected,
    this.framed = true,
    this.spread = false,
    this.frame = SurahFrameStyle.cartouche,
  });

  /// The frame drawn around each surah's name.
  final SurahFrameStyle frame;

  /// The verified text.
  final QuranText text;

  /// Page number, 1–604.
  final int page;

  /// Size of the text relative to the default.
  final double fontScale;

  /// Called when the page is tapped.
  final VoidCallback onTap;

  /// Formats reader labels using the saved digit preference.
  final String Function(int) digits;

  static String _defaultDigits(int value) => formatDigits(value, arabic: true);

  /// Called with the ayah that was pressed and held.
  final ValueChanged<AyahRef>? onAyahLongPress;

  /// Called with the new text size after a two-finger pinch. Null turns
  /// pinching off.
  final ValueChanged<double>? onFontScaleChanged;

  /// Ayahs the reader bookmarked. Their markers are coloured differently.
  final Set<AyahRef> bookmarked;

  /// The ayahs highlighted on the page: the one whose actions are open, or
  /// the ones chosen to share.
  final AyahRange? selected;

  /// Whether to draw the page's own frame and labels. Off when the page is
  /// shown inside another frame, as the stand-in of a printed page.
  final bool framed;

  /// Whether this page faces another, which keeps only its outer arrow.
  final bool spread;

  static const double _minSize = 15;
  static const double _maxSize = 34;
  static const double _bannerExtent = 78;
  static const double _lineHeight = 2.05;

  @override
  State<MushafPageView> createState() => _MushafPageViewState();
}

/// Size of the basmala relative to the ayahs.
const double _basmalaScale = 0.82;

class _MushafPageViewState extends State<MushafPageView> {
  final Map<AyahRef, LongPressGestureRecognizer> _recognizers = {};

  QuranText get text => widget.text;

  String _n(int value) => widget.digits(value);

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

  /// The reader's font: the Mushaf's own when the text holds its script.
  String get _fontFamily => text.hasMushafScript
      ? AppTokens.mushafFontFamily
      : AppTokens.quranFontFamily;

  /// The page's content in reading order.
  List<_Segment> _segments(
    QuranColors colors,
    Color bookmark,
    String Function(String) label,
  ) {
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
          segments.add(_Basmala(text.mushafBasmala));
        }
      }
      final highlight = widget.selected?.contains(ayah.ref) ?? false
          ? colors.highlight
          : null;
      final recognizer = widget.onAyahLongPress == null
          ? null
          : _recognizerFor(ayah.ref);
      final marked = widget.bookmarked.contains(ayah.ref);
      // The Mushaf script carries its own hizb marks, where print has them.
      if (!text.hasMushafScript && metadata.rubStartingAt(ayah.ref) != null) {
        spans.add(
          TextSpan(
            text: '\u06DE ',
            style: TextStyle(color: colors.ayahNumber),
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
            // The Mushaf font's own number glyph when held; otherwise the
            // end-of-ayah sign around the digits.
            text: '${ayah.mark ?? '\u06DD${_n(ayah.ref.ayah)}'} ',
            recognizer: recognizer,
            style: TextStyle(
              color: marked ? bookmark : colors.ayahNumber,
              fontWeight: marked ? FontWeight.bold : null,
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
  static double _fittedSize(
    List<_Segment> segments,
    Size size,
    String fontFamily,
  ) {
    double heightAt(double fontSize) {
      final style = TextStyle(
        fontFamily: fontFamily,
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
                _measure(
                  TextSpan(
                    text: text,
                    style: style.copyWith(fontSize: fontSize * _basmalaScale),
                  ),
                  size.width,
                ) +
                4;
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
    final colors = QuranColors.of(context);
    final segments = _segments(
      colors,
      Theme.of(context).colorScheme.tertiary,
      context.l10n.ayahNumber,
    );

    final page = LayoutBuilder(
      builder: (context, constraints) {
        final fitted = _fittedSize(segments, constraints.biggest, _fontFamily);
        final quran = TextStyle(
          fontFamily: _fontFamily,
          fontSize: fitted * widget.fontScale,
          height: MushafPageView._lineHeight,
          color: colors.ink,
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
                    _Banner(:final surah) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        height: MushafPageView._bannerExtent - 16,
                        child: SurahBanner(
                          surah: surah,
                          number: _n,
                          style: widget.frame,
                        ),
                      ),
                    ),
                    _Basmala(:final text) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        textScaler: TextScaler.noScaling,
                        // Smaller than the ayahs, as printed.
                        style: quran.copyWith(
                          fontSize: quran.fontSize! * _basmalaScale,
                        ),
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
    );
    final resize = widget.onFontScaleChanged;
    final body = resize == null
        ? page
        : PinchZoom(
            value: widget.fontScale,
            min: AppSettings.minReaderFontScale,
            max: AppSettings.maxReaderFontScale,
            onChanged: resize,
            child: page,
          );
    if (!widget.framed) return body;
    return ReaderPaintedMark(
      child: MushafPageFrame(
        metadata: text.metadata,
        page: widget.page,
        onTap: widget.onTap,
        spread: widget.spread,
        child: body,
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
