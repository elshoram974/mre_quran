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
import '../../quran_index/domain/quran_metadata.dart';
import '../../quran_text/domain/ayah_span.dart';
import '../../quran_text/domain/ayah_texts.dart';
import '../../settings/application/digits_provider.dart';
import 'ayah_share_card.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/application/settings_provider.dart';

/// Opens the sharing of [target]: choose from which ayah to which, see the
/// picture as it will be sent, then copy, send as text, or send as a
/// picture.
Future<void> showAyahShare(
  BuildContext context,
  AyahTexts text,
  AyahRef target,
) => AppSheet.showFilling<void>(
  context: context,
  builder: (_, scroll) => AyahShareSheet(
    text: text,
    initial: AyahSpan.single(target),
    scroll: scroll,
  ),
);

/// The ayahs with their reference, ready to paste:
/// `﴿… (٢٥٥)﴾` and on the next line `[البقرة: ٢٥٥ · صفحة ٤٢]`, each line
/// set to read right to left in any app and any language.
String ayahShareText(
  BuildContext context,
  AyahTexts text,
  AyahSpan span,
  String Function(int) digits,
) {
  final l10n = context.l10n;
  final pages = AyahShareText.pages(text, span);
  final page = pages.first == pages.last
      ? l10n.pageNumber(digits(pages.first))
      : l10n.pageRange(digits(pages.first), digits(pages.last));
  final ayahs = span.length == 1
      ? digits(span.first)
      : l10n.ayahRange(digits(span.first), digits(span.last));
  final surah = text.metadata.surah(span.surah).arabicName;
  return AyahShareText.rightToLeft(
    '${AyahShareText.body(text, span, digits)}\n'
    '${l10n.ayahShareReference(surah, ayahs, page)}',
  );
}

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
  final AyahSpan initial;

  /// The sheet's scroll controller, for the preview.
  final ScrollController scroll;

  /// The most ayahs shared at once: a picture longer than this is too long
  /// to read on a phone.
  static const int limit = 10;

  /// How sharp the picture is: pixels per logical pixel of the card.
  static const double pixelRatio = 3;

  @override
  ConsumerState<AyahShareSheet> createState() => _AyahShareSheetState();
}

class _AyahShareSheetState extends ConsumerState<AyahShareSheet> {
  late AyahSpan _span = widget.initial;
  final GlobalKey _card = GlobalKey();
  bool _busy = false;

  int get _surahLength => widget.text.ayahCount(_span.surah);

  void _move({int? first, int? last}) => setState(
    () => _span = _span.adjusted(
      first: first,
      last: last,
      surahLength: _surahLength,
      limit: AyahShareSheet.limit,
    ),
  );

  String _text() => ayahShareText(
    context,
    widget.text,
    _span,
    ref.read(digitsFormatterProvider),
  );

  Future<void> _copy() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    await Clipboard.setData(ClipboardData(text: _text()));
    messenger?.showSnackBar(SnackBar(content: Text(l10n.ayahsCopied)));
  }

  Future<void> _run(Future<void> Function() share) async {
    if (_busy) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    try {
      await share();
    } on Object catch (error) {
      AppLogger.debug('Ayah share failed: ${error.runtimeType}');
      messenger?.showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareText() =>
      _run(() => ref.read(sharerProvider).shareText(_text()));

  Future<void> _shareImage() => _run(() async {
    final text = _text();
    final boundary =
        _card.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: AyahShareSheet.pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    await ref
        .read(sharerProvider)
        .shareImage(
          data!.buffer.asUint8List(),
          name: 'quran-${_span.surah}-${_span.first}-${_span.last}.png',
          text: text,
        );
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final digits = ref.watch(digitsFormatterProvider);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppTokens.gutterCompact,
        0,
        AppTokens.gutterCompact,
        MediaQuery.paddingOf(context).bottom + 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSheetDragArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.shareAyahsTitle, style: theme.textTheme.titleLarge),
                const SizedBox(height: AppTokens.spaceSmall),
                Row(
                  children: [
                    Expanded(
                      child: _AyahStepper(
                        label: l10n.shareFromAyah,
                        value: digits(_span.first),
                        onLess: _span.first > 1
                            ? () => _move(first: _span.first - 1)
                            : null,
                        onMore: _span.first < _surahLength
                            ? () => _move(first: _span.first + 1)
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppTokens.spaceSmall),
                    Expanded(
                      child: _AyahStepper(
                        label: l10n.shareToAyah,
                        value: digits(_span.last),
                        onLess: _span.last > 1
                            ? () => _move(last: _span.last - 1)
                            : null,
                        onMore: _span.last < _surahLength
                            ? () => _move(last: _span.last + 1)
                            : null,
                      ),
                    ),
                  ],
                ),
                Text(
                  l10n.shareLimit(digits(AyahShareSheet.limit)),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppTokens.spaceSmall),
              ],
            ),
          ),
          // The picture as it will be sent, scaled to the sheet.
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scroll,
              child: FittedBox(
                fit: BoxFit.fitWidth,
                child: RepaintBoundary(
                  key: _card,
                  child: AyahShareCard(
                    text: widget.text,
                    span: _span,
                    digits: digits,
                    frame:
                        ref.watch(settingsProvider).value?.surahFrame ??
                        SurahFrameStyle.cartouche,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spaceMedium),
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
            onPressed: _busy ? null : _shareImage,
            icon: const Icon(Icons.image_outlined),
            label: Text(l10n.shareAsImage),
          ),
        ],
      ),
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
  });

  final String label;
  final String value;
  final VoidCallback? onLess;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                  tooltip: l10n.previousAyah,
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
                  tooltip: l10n.nextAyah,
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
