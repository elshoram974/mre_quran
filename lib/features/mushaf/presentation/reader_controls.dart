import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../quran_index/domain/quran_metadata.dart';
import 'page_scrubber.dart';
import 'reader_bar.dart';

/// The reader's bottom controls: where the reader is, and the display
/// options.
///
/// At rest they are two pills: the page, with its surah and juz, and the
/// display options. A tap on the page pill opens the page scrubber in its
/// place, and it stays for a second try; it closes when its close button is
/// tapped or when the bars are put away.
class ReaderControls extends StatefulWidget {
  /// Creates the controls for [page].
  const ReaderControls({
    super.key,
    required this.metadata,
    required this.page,
    required this.digits,
    required this.shown,
    required this.onPage,
    required this.onEnterNumber,
    required this.onDisplayOptions,
    required this.onSurah,
  });

  /// Quran structure, for the surah and juz of a page.
  final QuranMetadata metadata;

  /// The page the reader is on.
  final int page;

  /// Formats a number with the saved digit preference.
  final String Function(int) digits;

  /// Whether the reader's bars are showing.
  final bool shown;

  /// Called with the page the reader picked.
  final ValueChanged<int> onPage;

  /// Called when the reader asks to type a page number.
  final VoidCallback onEnterNumber;

  /// Opens the display options.
  final VoidCallback onDisplayOptions;

  /// Opens the index to browse surahs.
  final VoidCallback onSurah;

  @override
  State<ReaderControls> createState() => _ReaderControlsState();
}

class _ReaderControlsState extends State<ReaderControls> {
  bool _scrubbing = false;

  @override
  void didUpdateWidget(ReaderControls old) {
    super.didUpdateWidget(old);
    // Bars put away take the scrubber with them: they come back at rest.
    if (!widget.shown) _scrubbing = false;
  }

  String _title(int page) => context.l10n.pageNumber(widget.digits(page));

  String _place(int page) => context.l10n.scrubberPlace(
    widget.metadata.surahAtPage(page).arabicName,
    context.l10n.juzTitle(
      widget.digits(widget.metadata.juzOfPage(page).number),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppTokens.motionMedium;
    final Widget child = _scrubbing
        ? PageScrubber(
            key: const ValueKey('scrubber'),
            page: widget.page,
            pageCount: widget.metadata.pageCount,
            titleOf: _title,
            subtitleOf: _place,
            digits: widget.digits,
            fineLabel: l10n.fineScrub,
            cancelHint: l10n.scrubCancelHint,
            cancelNow: l10n.scrubCancelNow,
            numberTooltip: l10n.goToPage,
            closeTooltip: l10n.scrubberClose,
            onClose: () => setState(() => _scrubbing = false),
            onChanged: widget.onPage,
            onEnterNumber: widget.onEnterNumber,
          )
        // The pills have fixed room, like the toolbar above the page.
        : MediaQuery.withClampedTextScaling(
            key: const ValueKey('pills'),
            maxScaleFactor: 1.3,
            child: Row(
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
                    title: _title(widget.page),
                    subtitle: _place(widget.page),
                    progress: widget.page / widget.metadata.pageCount,
                    tooltip: l10n.scrubberOpen,
                    onPressed: () => setState(() => _scrubbing = true),
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
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ),
                ),
              ],
            ),
          );
    // The pill grows into the scrubber from the bottom edge, where both sit.
    return AnimatedSize(
      duration: duration,
      curve: Curves.easeOutCubic,
      alignment: AlignmentDirectional.bottomCenter,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutCubic,
        layoutBuilder: (current, previous) => Stack(
          alignment: AlignmentDirectional.bottomCenter,
          children: [...previous, ?current],
        ),
        child: child,
      ),
    );
  }
}
