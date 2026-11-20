import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/diagnostics/app_logger.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/sharing/sharer.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_select_field.dart';
import '../../quran_index/domain/quran_metadata.dart';
import '../../quran_text/domain/ayah_range.dart';
import '../../quran_text/domain/ayah_share_text.dart';
import '../../quran_text/domain/ayah_texts.dart';
import '../../settings/application/digits_provider.dart';
import '../application/ayah_printer.dart';
import 'ayah_share_card.dart';
import 'ayah_share_format.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/application/settings_provider.dart';

/// Opens the sharing of [initial]: choose from which ayah to which, across
/// surahs if wanted, see the pictures as they will be sent, then copy, send
/// as text, or send as pictures.
Future<void> showAyahShare(
  BuildContext context,
  AyahTexts text,
  AyahRange initial,
) => AppSheet.showFilling<void>(
  context: context,
  builder: (_, scroll) =>
      AyahShareSheet(text: text, initial: initial, scroll: scroll),
);

/// The body of the sharing sheet.
class AyahShareSheet extends ConsumerStatefulWidget {
  /// Creates the sheet starting on [initial].
  const AyahShareSheet({
    super.key,
    required this.text,
    required this.initial,
    required this.scroll,
  });

  /// The reading's text.
  final AyahTexts text;

  /// The ayahs chosen when the sheet opens.
  final AyahRange initial;

  /// The sheet's scroll controller: the whole body scrolls with it, so the
  /// sheet fits a phone on its side and the largest text.
  final ScrollController scroll;

  /// How sharp the picture is: pixels per logical pixel of the card.
  static const double pixelRatio = 3;

  @override
  ConsumerState<AyahShareSheet> createState() => _AyahShareSheetState();
}

class _AyahShareSheetState extends ConsumerState<AyahShareSheet> {
  late final AyahOrder _order = AyahOrder.of(widget.text);
  late AyahRange _range = _order.moveEnd(
    widget.initial,
    widget.initial.end,
    limit: ayahShareLimit,
  );
  List<GlobalKey> _cards = [];
  bool _busy = false;

  /// How many pictures the person asked for; null leaves it to the app.
  int? _split;

  void _moveStart(AyahRef start) => setState(
    () => _range = _order.moveStart(_range, start, limit: ayahShareLimit),
  );

  void _moveEnd(AyahRef end) => setState(
    () => _range = _order.moveEnd(_range, end, limit: ayahShareLimit),
  );

  String _text() => ayahShareText(
    context,
    widget.text,
    _range,
    ref.read(digitsFormatterProvider),
  );

  Future<void> _copy() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    await Clipboard.setData(ClipboardData(text: _text()));
    messenger?.showSnackBar(SnackBar(content: Text(l10n.ayahsCopied)));
  }

  Future<void> _run(
    Future<void> Function() share, {
    bool printing = false,
  }) async {
    if (_busy) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    try {
      await share();
    } on Object catch (error) {
      AppLogger.debug('Ayah share failed: ${error.runtimeType}');
      messenger?.showSnackBar(
        SnackBar(content: Text(printing ? l10n.printFailed : l10n.shareFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareText() =>
      _run(() => ref.read(sharerProvider).shareText(_text()));

  Future<List<SharedImage>> _captureImages() async {
    final start = _range.start;
    final end = _range.end;
    final base = 'quran-${start.surah}-${start.ayah}-${end.surah}-${end.ayah}';
    final images = <SharedImage>[];
    for (final (index, key) in _cards.indexed) {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(
        pixelRatio: AyahShareSheet.pixelRatio,
      );
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      images.add((
        png: data!.buffer.asUint8List(),
        name: _cards.length == 1 ? '$base.png' : '$base-${index + 1}.png',
      ));
    }
    return images;
  }

  Future<void> _shareImages() => _run(() async {
    final images = await _captureImages();
    await ref.read(sharerProvider).shareImages(images, text: _text());
  });

  Future<void> _printImages() => _run(() async {
    final images = await _captureImages();
    await ref.read(ayahPrinterProvider).printCards([
      for (final image in images) image.png,
    ]);
  }, printing: true);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final digits = ref.watch(digitsFormatterProvider);
    final frame =
        ref.watch(settingsProvider).value?.surahFrame ??
        SurahFrameStyle.cartouche;
    final pictures = AyahShareText.pictures(
      widget.text,
      _order.refs(_range),
      count: _split,
    );
    if (_cards.length != pictures.length) {
      _cards = [for (final _ in pictures) GlobalKey()];
    }
    final surahs = [
      for (final surah in widget.text.metadata.surahs)
        if (_order.ayahCount(surah.number) > 0)
          AppSelectOption<int>(
            value: surah.number,
            label: '${digits(surah.number)}. ${surah.arabicName}',
          ),
    ];
    const gutter = EdgeInsetsDirectional.symmetric(
      horizontal: AppTokens.gutterCompact,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          // Not a lazy list: every picture is laid out and painted, so each
          // can be sent, the ones scrolled out of sight too.
          child: SingleChildScrollView(
            controller: widget.scroll,
            padding: gutter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.shareAyahsTitle, style: theme.textTheme.titleLarge),
                const SizedBox(height: AppTokens.spaceSmall),
                _RangeEnd(
                  label: l10n.shareFrom,
                  ayah: _range.start,
                  surahs: surahs,
                  digits: digits,
                  onSurah: (surah) => _moveStart(AyahRef(surah, 1)),
                  onLess: _order.indexOf(_range.start) > 0
                      ? () => _moveStart(_order.step(_range.start, -1))
                      : null,
                  onMore: _order.indexOf(_range.start) < _order.total - 1
                      ? () => _moveStart(_order.step(_range.start, 1))
                      : null,
                ),
                const SizedBox(height: AppTokens.spaceSmall),
                _RangeEnd(
                  label: l10n.shareTo,
                  ayah: _range.end,
                  surahs: surahs,
                  digits: digits,
                  onSurah: (surah) => _moveEnd(AyahRef(surah, 1)),
                  onLess: _order.indexOf(_range.end) > 0
                      ? () => _moveEnd(_order.step(_range.end, -1))
                      : null,
                  onMore: _order.indexOf(_range.end) < _order.total - 1
                      ? () => _moveEnd(_order.step(_range.end, 1))
                      : null,
                ),
                const SizedBox(height: AppTokens.spaceSmall),
                Text(
                  '${l10n.selectionCount(_order.length(_range), digits(_order.length(_range)))}'
                  ' · ${l10n.shareLimit(digits(ayahShareLimit))}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppTokens.spaceSmall),
                _PictureCount(
                  count: pictures.length,
                  most: math.min(
                    _order.length(_range),
                    AyahShareText.maxPictures,
                  ),
                  automatic: _split == null,
                  digits: digits,
                  onChanged: (count) => setState(() => _split = count),
                ),
                const SizedBox(height: AppTokens.spaceSmall),
                // The pictures as they will be sent, scaled to the sheet.
                for (final (index, refs) in pictures.indexed)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: AppTokens.spaceSmall,
                    ),
                    child: FittedBox(
                      fit: BoxFit.fitWidth,
                      child: RepaintBoundary(
                        key: _cards[index],
                        child: AyahShareCard(
                          text: widget.text,
                          refs: refs,
                          digits: digits,
                          frame: frame,
                          part: index + 1,
                          parts: pictures.length,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // The actions stay in reach under whatever scrolls.
        AppSheetDragArea(
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              AppTokens.gutterCompact,
              AppTokens.spaceSmall,
              AppTokens.gutterCompact,
              MediaQuery.paddingOf(context).bottom + 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _copy,
                        icon: const Icon(Icons.copy_outlined),
                        label: Text(l10n.copyText),
                      ),
                    ),
                    const SizedBox(width: AppTokens.spaceSmall),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _shareText,
                        icon: const Icon(Icons.notes_rounded),
                        label: Text(
                          l10n.shareAsText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.spaceSmall),
                FilledButton.icon(
                  onPressed: _busy ? null : _shareImages,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(l10n.shareAsImage),
                ),
                const SizedBox(height: AppTokens.spaceSmall),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _printImages,
                  icon: const Icon(Icons.print_outlined),
                  label: Text(l10n.printAyahs),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// One end of the range: its surah, picked from the list, and its ayah,
/// stepped down and up (past a surah's end into the next).
class _RangeEnd extends StatelessWidget {
  const _RangeEnd({
    required this.label,
    required this.ayah,
    required this.surahs,
    required this.digits,
    required this.onSurah,
    required this.onLess,
    required this.onMore,
  });

  final String label;
  final AyahRef ayah;
  final List<AppSelectOption<int>> surahs;
  final String Function(int) digits;
  final ValueChanged<int> onSurah;
  final VoidCallback? onLess;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: AppSelectField<int>(
                label: l10n.shareSurah,
                sheetTitle: '${l10n.shareSurah} · $label',
                options: surahs,
                value: ayah.surah,
                onChanged: onSurah,
              ),
            ),
            const SizedBox(width: AppTokens.spaceSmall),
            Expanded(
              flex: 2,
              child: _AyahStepper(
                label: l10n.shareAyahField,
                value: digits(ayah.ayah),
                onLess: onLess,
                onMore: onMore,
                lessTooltip: l10n.previousAyah,
                moreTooltip: l10n.nextAyah,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A number with a step down and a step up, under its label.
class _AyahStepper extends StatelessWidget {
  const _AyahStepper({
    required this.label,
    required this.value,
    required this.onLess,
    required this.onMore,
    required this.lessTooltip,
    required this.moreTooltip,
  });

  final String label;
  final String value;
  final VoidCallback? onLess;
  final VoidCallback? onMore;
  final String lessTooltip;
  final String moreTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTokens.radiusField),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: 4),
        child: Column(
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: lessTooltip,
                  onPressed: onLess,
                  icon: const Icon(Icons.remove_rounded),
                ),
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: moreTooltip,
                  onPressed: onMore,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// How many pictures the ayahs are sent as: stepped down and up to split them
/// as wanted, or left automatic, when the app fills each picture as far as
/// it stays readable.
class _PictureCount extends StatelessWidget {
  const _PictureCount({
    required this.count,
    required this.most,
    required this.automatic,
    required this.digits,
    required this.onChanged,
  });

  /// The pictures there are now.
  final int count;

  /// The most they can be cut into.
  final int most;

  /// Whether the app chose [count].
  final bool automatic;

  final String Function(int) digits;

  /// The person's choice: a number, or null to leave it automatic.
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: _AyahStepper(
            label: l10n.sharePicturesField,
            value: digits(count),
            onLess: count > 1 ? () => onChanged(count - 1) : null,
            onMore: count < most ? () => onChanged(count + 1) : null,
            lessTooltip: l10n.sharePicturesFewer,
            moreTooltip: l10n.sharePicturesMore,
          ),
        ),
        const SizedBox(width: AppTokens.spaceSmall),
        Expanded(
          flex: 2,
          child: FilterChip(
            label: SizedBox(
              width: double.infinity,
              child: Text(l10n.sharePicturesAuto, textAlign: TextAlign.center),
            ),
            selected: automatic,
            onSelected: (_) => onChanged(null),
          ),
        ),
      ],
    );
  }
}
