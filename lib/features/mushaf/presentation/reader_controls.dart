import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../quran_index/domain/quran_metadata.dart';
import '../application/reader_immersive_provider.dart';
import 'hizb_label.dart';
import 'page_scrubber.dart';
import 'reader_bar.dart';

/// The reader's bottom controls: where the reader is, and the display
/// options.
///
/// At rest they are three pills: the surah, the page with its surah and juz,
/// and the display options. A tap on the page pill grows it into the page
/// scrubber, which names the hizb as well, and it stays for a second try; it
/// shrinks back into the pill when its close button, the page or back is
/// tapped, and goes when the bars are put away.
class ReaderControls extends ConsumerStatefulWidget {
  /// Creates the controls for [page].
  const ReaderControls({
    super.key,
    required this.metadata,
    required this.page,
    required this.digits,
    required this.onPage,
    required this.onEnterNumber,
    required this.onDisplayOptions,
    required this.onSurah,
  });

  /// Quran structure, for the surah, juz and hizb of a page.
  final QuranMetadata metadata;

  /// The page the reader is on.
  final int page;

  /// Formats a number with the saved digit preference.
  final String Function(int) digits;

  /// Called with the page the reader picked.
  final ValueChanged<int> onPage;

  /// Called when the reader asks to type a page number.
  final VoidCallback onEnterNumber;

  /// Opens the display options.
  final VoidCallback onDisplayOptions;

  /// Opens the index to browse surahs.
  final VoidCallback onSurah;

  @override
  ConsumerState<ReaderControls> createState() => _ReaderControlsState();
}

class _ReaderControlsState extends ConsumerState<ReaderControls>
    with SingleTickerProviderStateMixin {
  /// 0: the pills; 1: the scrubber. In between, the page pill's box grows
  /// into the scrubber's, or the scrubber shrinks back into it.
  late final AnimationController _morph = AnimationController(
    vsync: this,
    duration: AppTokens.motionMedium,
    value: ref.read(readerScrubberProvider) ? 1 : 0,
  );

  final GlobalKey _stack = GlobalKey();
  final GlobalKey _pill = GlobalKey();

  /// Where the page pill is: its start, its width, its height, and how far
  /// its bottom is from the controls' bottom. Read before each morph.
  ({double left, double width, double height, double bottom})? _pillBox;

  @override
  void dispose() {
    _morph.dispose();
    super.dispose();
  }

  void _measure() {
    final stack = _stack.currentContext?.findRenderObject() as RenderBox?;
    final pill = _pill.currentContext?.findRenderObject() as RenderBox?;
    if (stack == null || pill == null || !stack.hasSize || !pill.hasSize) {
      return;
    }
    final at = pill.localToGlobal(Offset.zero, ancestor: stack);
    _pillBox = (
      left: at.dx,
      width: pill.size.width,
      height: pill.size.height,
      bottom: stack.size.height - at.dy - pill.size.height,
    );
  }

  void _run(bool open) {
    _measure();
    if (MediaQuery.disableAnimationsOf(context)) {
      _morph.value = open ? 1 : 0;
    } else if (open) {
      _morph.forward();
    } else {
      _morph.reverse();
    }
  }

  String _title(int page) => context.l10n.pageNumber(widget.digits(page));

  String _juz(int page) => context.l10n.juzTitle(
    widget.digits(widget.metadata.juzOfPage(page).number),
  );

  /// The page pill's line: the surah and the juz. The pill is narrow.
  String _place(int page) => context.l10n.scrubberPlace(
    widget.metadata.surahAtPage(page).arabicName,
    _juz(page),
  );

  /// The scrubber's line: its card is as wide as the screen, so it names
  /// the hizb too, as the page's own labels do.
  String _placeWithHizb(int page) => context.l10n.scrubberPlaceHizb(
    widget.metadata.surahAtPage(page).arabicName,
    _juz(page),
    hizbQuarterLabel(
      context.l10n,
      widget.metadata.quarterOfPage(page),
      widget.digits,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.listen(readerScrubberProvider, (_, open) => _run(open));
    final open = ref.watch(readerScrubberProvider);
    final scrubber = ref.read(readerScrubberProvider.notifier);
    // The pills have fixed room, like the toolbar above the page.
    final pills = MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 132),
              child: ReaderFloatingSurface(
                padding: EdgeInsets.zero,
                child: SizedBox(
                  height: ReaderPlacePill.extent,
                  child: TextButton.icon(
                    onPressed: widget.onSurah,
                    icon: const Icon(Icons.menu_book_outlined),
                    label: Text(
                      widget.metadata.surahAtPage(widget.page).arabicName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTokens.spaceSmall),
          Expanded(
            child: ReaderPlacePill(
              key: _pill,
              title: _title(widget.page),
              subtitle: _place(widget.page),
              progress: widget.page / widget.metadata.pageCount,
              tooltip: l10n.scrubberOpen,
              onPressed: scrubber.open,
            ),
          ),
          const SizedBox(width: AppTokens.spaceSmall),
          ReaderFloatingSurface(
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: ReaderPlacePill.extent,
              width: ReaderPlacePill.extent,
              child: IconButton(
                onPressed: widget.onDisplayOptions,
                tooltip: l10n.displayOptions,
                // The reader's buttons take the accent, as the toolbar's do.
                color: Theme.of(context).colorScheme.primary,
                icon: const Icon(Icons.tune_rounded),
              ),
            ),
          ),
        ],
      ),
    );
    return PopScope(
      // Back closes the scrubber before it leaves the reader.
      canPop: !open,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) scrubber.close();
      },
      child: AnimatedBuilder(
        animation: _morph,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_morph.value);
          final showing = _morph.value > 0;
          return Stack(
            key: _stack,
            alignment: AlignmentDirectional.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // The pills give way in the first half, and come back in the
              // last half of the way back.
              IgnorePointer(
                ignoring: showing,
                child: ExcludeSemantics(
                  excluding: showing,
                  child: Opacity(
                    opacity: (1 - 2 * t).clamp(0.0, 1.0),
                    child: pills,
                  ),
                ),
              ),
              if (showing)
                IgnorePointer(
                  ignoring: !open,
                  child: _Morph(
                    t: t,
                    from: _pillBox,
                    child: Opacity(
                      opacity: (1.6 * t).clamp(0.0, 1.0),
                      child: PageScrubber(
                        page: widget.page,
                        pageCount: widget.metadata.pageCount,
                        titleOf: _title,
                        subtitleOf: _placeWithHizb,
                        digits: widget.digits,
                        fineLabel: l10n.fineScrub,
                        cancelHint: l10n.scrubCancelHint,
                        cancelNow: l10n.scrubCancelNow,
                        numberTooltip: l10n.goToPage,
                        closeTooltip: l10n.scrubberClose,
                        onClose: scrubber.close,
                        onChanged: widget.onPage,
                        onEnterNumber: widget.onEnterNumber,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Clips [child] to a rounded box that is the page pill's at [t] 0 and the
/// child's own at [t] 1, so the scrubber seems to grow out of the pill and to
/// shrink back into it.
class _Morph extends StatelessWidget {
  const _Morph({required this.t, required this.from, required this.child});

  final double t;
  final ({double left, double width, double height, double bottom})? from;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (t >= 1 || from == null) return child;
    return ClipRRect(
      clipper: _MorphClipper(t: t, from: from!),
      child: child,
    );
  }
}

class _MorphClipper extends CustomClipper<RRect> {
  _MorphClipper({required this.t, required this.from});

  final double t;
  final ({double left, double width, double height, double bottom}) from;

  @override
  RRect getClip(Size size) {
    final pill = Rect.fromLTWH(
      from.left,
      size.height - from.bottom - from.height,
      from.width,
      from.height,
    );
    final rect = Rect.lerp(pill, Offset.zero & size, t)!;
    final radius = lerpDouble(from.height / 2, AppTokens.radiusCard, t)!;
    return RRect.fromRectAndRadius(rect, Radius.circular(radius));
  }

  @override
  bool shouldReclip(_MorphClipper old) => old.t != t || old.from != from;
}
