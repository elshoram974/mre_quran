import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../quran_index/domain/quran_metadata.dart';
import '../../settings/application/digits_provider.dart';
import '../application/reader_immersive_provider.dart';
import 'mushaf_ornaments.dart';

/// The printed-page frame around a Mushaf page: the surah, hizb, and juz at
/// the top, the page number in a medallion at the bottom, and [child] in
/// between. Shared by the typeset and the printed reader.
///
/// The page number stays in the frame; when the text grows past the page,
/// [child] scrolls inside it.
class MushafPageFrame extends StatelessWidget {
  /// Creates the frame of [page].
  const MushafPageFrame({
    super.key,
    required this.metadata,
    required this.page,
    required this.onTap,
    required this.child,
    this.decorated = true,
  });

  /// Quran structure, for the labels.
  final QuranMetadata metadata;

  /// Page number, 1–604.
  final int page;

  /// Called when the page is tapped.
  final VoidCallback onTap;

  /// The page body.
  final Widget child;

  /// Whether to draw the ornamental border, label tags, and medallion. Off
  /// for printed pages, which carry their own ornaments: the labels become
  /// plain lines of small text so the page gets the room.
  final bool decorated;

  /// Style of the page labels.
  static TextStyle labelStyle(ColorScheme scheme) => TextStyle(
    fontFamily: AppTokens.quranFontFamily,
    fontSize: 16,
    height: 1.4,
    color: scheme.onSurfaceVariant,
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final ink = scheme.primary.withValues(alpha: 0.55);
    final label = labelStyle(scheme);
    String n(int value) => formatDigits(value, arabic: true);
    final first = metadata.ayahsOnPage(page).first;
    final juz = metadata.juzOfPage(page);
    final hizb = metadata.hizbOf(first);
    final surah = metadata.surahAtPage(page);

    if (!decorated) {
      final plain = label.copyWith(fontSize: 14, height: 1.2);
      Widget line(String text, AlignmentGeometry alignment) => Expanded(
        child: Align(
          alignment: alignment,
          child: Text(
            text,
            style: plain,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
      return MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.2,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Column(
              children: [
                _ShownWithoutBars(
                  child: Row(
                    children: [
                      line(
                        l10n.surahTitle(surah.arabicName),
                        AlignmentDirectional.centerStart,
                      ),
                      line(l10n.hizbTitle(n(hizb)), Alignment.center),
                      line(
                        l10n.juzTitle(n(juz.number)),
                        AlignmentDirectional.centerEnd,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(child: child),
                const SizedBox(height: 4),
                _ShownWithoutBars(child: Text(n(page), style: plain)),
              ],
            ),
          ),
        ),
      );
    }

    // Page labels have fixed room, so system text size is capped for them.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 10, 8),
          child: CustomPaint(
            painter: PageFramePainter(color: ink),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  _ShownWithoutBars(
                    child: Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: _Tag(
                              text: l10n.surahTitle(surah.arabicName),
                              style: label,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: _Tag(
                              text: l10n.hizbTitle(n(hizb)),
                              style: label,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: _Tag(
                              text: l10n.juzTitle(n(juz.number)),
                              style: label,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(child: child),
                  const SizedBox(height: 6),
                  _ShownWithoutBars(
                    child: SizedBox.square(
                      dimension: 40,
                      child: CustomPaint(
                        painter: MedallionPainter(
                          fill: scheme.secondaryContainer,
                          stroke: ink,
                        ),
                        child: Center(
                          child: Text(
                            n(page),
                            style: label.copyWith(
                              fontSize: 15,
                              color: scheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Page labels repeat what the reader bar shows, and the bars float over
/// them, so they appear only while the bars are hidden. Their room is kept so
/// the page never moves.
class _ShownWithoutBars extends ConsumerWidget {
  const _ShownWithoutBars({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final immersive = ref.watch(readerImmersiveProvider);
    return AnimatedOpacity(
      opacity: immersive ? 1 : 0,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 220),
      child: child,
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );
}
