import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_palette.dart';
import '../domain/home_widget.dart';
import '../domain/widget_preview_data.dart';

/// [widget] drawn as it looks on the home screen, from the same colours,
/// sizes and arrangement as the Android layouts, with [data]'s words, times
/// and direction: the widgets' own language, not the app's. It is drawn at the
/// size the widget has by default, so the size is what a person will see.
class HomeWidgetPreview extends StatelessWidget {
  /// Creates the preview.
  const HomeWidgetPreview({
    super.key,
    required this.widget,
    required this.data,
  });

  /// Which widget.
  final HomeWidget widget;

  /// What it shows.
  final WidgetPreviewData data;

  /// The default size of [widget] in logical pixels, as the launcher gives it.
  static Size sizeOf(HomeWidget widget) => switch (widget) {
    HomeWidget.prayerCard => const Size(215, 150),
    HomeWidget.nextPrayer => const Size(150, 60),
    HomeWidget.prayerSchedule => const Size(148, 190),
    HomeWidget.tasbih => const Size(172, 72),
    HomeWidget.dhikr => const Size(172, 72),
  };

  @override
  Widget build(BuildContext context) {
    final size = sizeOf(widget);
    final card = widget == HomeWidget.prayerCard;
    return Directionality(
      textDirection: data.rtl ? TextDirection.rtl : TextDirection.ltr,
      // A picture of the widget at its default size: the phone's text size is
      // not part of it (the widget on the home screen follows that itself).
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                // The Android gradient runs from the top end to the bottom start.
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: card
                    ? const [WidgetPalette.cardStart, WidgetPalette.cardEnd]
                    : const [WidgetPalette.greenStart, WidgetPalette.greenEnd],
              ),
              border: card ? Border.all(color: WidgetPalette.cardLine) : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: switch (widget) {
                HomeWidget.prayerCard => _PrayerCard(data),
                HomeWidget.nextPrayer => _NextPrayer(data),
                HomeWidget.prayerSchedule => _Schedule(data),
                HomeWidget.tasbih => _Tasbih(data),
                HomeWidget.dhikr => _Dhikr(data),
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// One line that shrinks to fit the room it is given, so a preview never
/// overflows, however wide the font is.
class _Line extends StatelessWidget {
  const _Line(
    this.text,
    this.style, {
    this.alignment = AlignmentDirectional.centerStart,
  });

  final String text;
  final TextStyle style;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: alignment,
    child: Text(text, maxLines: 1, style: style),
  );
}

TextStyle _style(double size, Color color, {bool bold = false}) => TextStyle(
  fontSize: size,
  color: color,
  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
  height: 1.15,
  decoration: TextDecoration.none,
);

/// The coming prayer at the start, its time and the time left at the end. At
/// its default size (one launcher row) it has no room for its label or the
/// date, as the widget has none.
class _NextPrayer extends StatelessWidget {
  const _NextPrayer(this.data);

  final WidgetPreviewData data;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _Line(
            data.next.name,
            _style(17, WidgetPalette.text, bold: true),
          ),
        ),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Line(
                data.next.time,
                _style(17, WidgetPalette.text, bold: true),
                alignment: AlignmentDirectional.centerEnd,
              ),
              _Line(
                data.remaining,
                _style(11, WidgetPalette.accent),
                alignment: AlignmentDirectional.centerEnd,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// The day's times, the coming one framed with the time left above it.
class _Schedule extends StatelessWidget {
  const _Schedule(this.data);

  final WidgetPreviewData data;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 10, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: _Line(
                  data.date,
                  _style(11, WidgetPalette.text, bold: true),
                ),
              ),
              _Line(data.hijri, _style(10, WidgetPalette.accent)),
            ],
          ),
        ),
        for (final row in data.rows)
          Expanded(
            flex: row.id == data.next.id ? 2 : 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: row.id == data.next.id
                    ? WidgetPalette.rowNext
                    : const Color(0x00000000),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: 10,
                  vertical: row.id == data.next.id ? 3 : 1,
                ),
                child: LayoutBuilder(
                  builder: (context, box) {
                    final color = row.id == 'sunrise'
                        ? WidgetPalette.muted
                        : WidgetPalette.text;
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: box.maxWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (row.id == data.next.id)
                              Text(
                                data.remaining,
                                maxLines: 1,
                                style: _style(10, WidgetPalette.accent),
                              ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    row.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _style(12, color),
                                  ),
                                ),
                                Flexible(
                                  child: _Line(
                                    row.time,
                                    _style(12, color, bold: true),
                                    alignment: AlignmentDirectional.centerEnd,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// The coming prayer large, its date, and the day's times in a grid, the
/// coming one framed in gold.
class _PrayerCard extends StatelessWidget {
  const _PrayerCard(this.data);

  final WidgetPreviewData data;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 14, 8),
    child: Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Line(
                      data.nextLabel,
                      _style(11, WidgetPalette.cardGold, bold: true),
                    ),
                    _Line(
                      data.next.name,
                      _style(26, WidgetPalette.cardText, bold: true),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _Line(
                        data.next.time,
                        _style(16, WidgetPalette.cardText, bold: true),
                        alignment: AlignmentDirectional.centerEnd,
                      ),
                      _Line(
                        data.remaining,
                        _style(11, WidgetPalette.cardGold),
                        alignment: AlignmentDirectional.centerEnd,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            children: [
              Expanded(
                child: _Line(data.date, _style(9, WidgetPalette.cardMuted)),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _Line(
                  data.hijri,
                  _style(9, WidgetPalette.cardMuted),
                  alignment: AlignmentDirectional.centerEnd,
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 3),
          child: SizedBox(
            height: 1,
            width: double.infinity,
            child: ColoredBox(color: WidgetPalette.cardLine),
          ),
        ),
        for (var start = 0; start < 6; start += 3)
          SizedBox(
            height: 34,
            child: Row(
              children: [
                for (final row in data.rows.skip(start).take(3))
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: row.id == data.next.id
                            ? WidgetPalette.cardCellNext
                            : const Color(0x00000000),
                        borderRadius: BorderRadius.circular(10),
                        border: row.id == data.next.id
                            ? Border.all(color: WidgetPalette.cardGold)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Line(row.name, _style(10, WidgetPalette.cardMuted)),
                          _Line(
                            row.time,
                            _style(10, WidgetPalette.cardText, bold: true),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// The tasbih count with its reset button.
class _Tasbih extends StatelessWidget {
  const _Tasbih(this.data);

  final WidgetPreviewData data;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 10, end: 8),
    child: Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Line(
                data.tasbihName,
                _style(11, WidgetPalette.accent, bold: true),
              ),
              _Line(
                data.tasbihCount,
                _style(30, WidgetPalette.text, bold: true),
              ),
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: WidgetPalette.pill,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: _Line('↺', _style(14, WidgetPalette.text)),
          ),
        ),
      ],
    ),
  );
}

/// A suggested dhikr with how far through it the person is.
class _Dhikr extends StatelessWidget {
  const _Dhikr(this.data);

  final WidgetPreviewData data;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 8),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _Line(
                data.dhikrName,
                _style(12, WidgetPalette.accent, bold: true),
              ),
            ),
            Flexible(
              child: _Line(
                data.dhikrCount,
                _style(12, WidgetPalette.muted),
                alignment: AlignmentDirectional.centerEnd,
              ),
            ),
          ],
        ),
        _Line(data.dhikrTitle, _style(16, WidgetPalette.text, bold: true)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: const SizedBox(
            height: 5,
            width: double.infinity,
            // Stretched: an empty box would otherwise have no height.
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 1,
                  child: ColoredBox(color: WidgetPalette.accent),
                ),
                Expanded(flex: 3, child: ColoredBox(color: WidgetPalette.pill)),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
