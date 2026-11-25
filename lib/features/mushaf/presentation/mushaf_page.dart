import 'dart:math' as math;

import '../../../core/widgets/app_snack_bar.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/empty_state.dart';
import '../../bookmarks/application/bookmarks_provider.dart';
import '../../quran_index/application/quran_metadata_provider.dart';
import '../../quran_text/application/quran_text_providers.dart';
import '../../settings/application/settings_provider.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/application/digits_provider.dart';
import '../application/ayah_selection_provider.dart';
import '../application/reader_immersive_provider.dart';
import '../application/reading_position_provider.dart';
import 'ayah_selection_bar.dart';
import 'display_options_sheet.dart';
import 'go_to_page_sheet.dart';
import 'mushaf_pager.dart';
import 'offline_hint.dart';
import 'reader_bar.dart';
import 'reader_controls.dart';
import 'reader_navigation.dart';
import 'reader_orientation.dart';

/// The Mushaf tab: the pages, labelled like a printed Mushaf (surah and juz
/// above, page number below, arrows onward). A tap on the page or an ayah
/// brings up a floating toolbar (index, search, page bookmark), floating
/// controls (the page, which opens the scrubber, and display options), and
/// the tab bar; turning the page
/// puts them away.
class MushafPage extends ConsumerWidget {
  const MushafPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // The printed pages need only the Quran's structure, so they start
    // loading at once while the text is read beside them; the typeset
    // reader needs the text itself.
    final metadata = ref.watch(quranMetadataProvider);
    final text = ref.watch(quranTextProvider);
    final printed =
        ref.watch(settingsProvider.select((s) => s.value?.readerMode)) !=
        ReaderMode.text;
    final page = ref.watch(readingPositionProvider).value;
    final immersive = ref.watch(readerImmersiveProvider);
    final choosing = ref.watch(ayahSelectionProvider) != null;
    // Rebuilds when the screen's insets change (rotation, navigation mode).
    MediaQuery.viewPaddingOf(context);

    Future<void> open(AppRoute route) => openReaderRoute(context, ref, route);

    if (metadata.hasError || (!printed && text.hasError)) {
      return EmptyState(
        icon: Icons.error_outline,
        title: l10n.readerLoadError,
        message: '',
        actionLabel: l10n.retry,
        onAction: () => ref
          ..invalidate(quranMetadataProvider)
          ..invalidate(quranTextDataProvider),
      );
    }
    final structure = metadata.value;
    if (structure == null || page == null || (!printed && !text.hasValue)) {
      return const _ReaderSkeleton();
    }
    final digits = ref.watch(digitsFormatterProvider);
    final onPage = structure.ayahsOnPage(page);
    final bookmarked = ref.watch(bookmarkedRefsProvider);
    final marked = onPage.where(bookmarked.contains).toList();
    final scheme = Theme.of(context).colorScheme;

    void goTo(int target) => goToReaderPage(ref, target);

    Future<void> togglePageBookmark() async {
      final notifier = ref.read(bookmarksProvider.notifier);
      final messenger = ScaffoldMessenger.maybeOf(context);
      final message = marked.isEmpty
          ? l10n.bookmarkAdded
          : l10n.bookmarkRemoved;
      if (marked.isEmpty) {
        await notifier.toggle(onPage.first);
      } else {
        for (final ayah in marked) {
          await notifier.remove(ayah);
        }
      }
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(AppSnackBar(message));
    }

    Widget icon(IconData data, String tooltip, VoidCallback onPressed) =>
        IconButton(
          icon: Icon(data),
          color: scheme.primary,
          tooltip: tooltip,
          onPressed: onPressed,
        );

    Future<void> goToPage() async {
      final chosen = await showGoToPage(
        context,
        page: page,
        pageCount: structure.pageCount,
        digits: digits,
      );
      if (chosen != null) goTo(chosen);
    }

    // Shown on a tap: a toolbar at the top and controls at the bottom,
    // floating over the page.
    final toolbar = ReaderToolbar(
      menu: icon(Icons.menu_rounded, l10n.readerMenu, () {
        open(AppRoute.quranIndex);
      }),
      searchLabel: l10n.searchQuran,
      onSearch: () => open(AppRoute.quranSearch),
      beforeSearch: [
        icon(
          marked.isEmpty
              ? Icons.bookmark_add_outlined
              : Icons.bookmark_added_rounded,
          marked.isEmpty ? l10n.bookmarkPage : l10n.removePageBookmark,
          togglePageBookmark,
        ),
      ],
      actions: [
        // icon(Icons.settings_outlined, l10n.settings, () {
        //   context.go(AppRoute.settings.path);
        // }),
      ],
    );
    // Where the reader is (a tap opens the page scrubber) and the display
    // options. Everything else lives in the display sheet; a tap on the page
    // hides the bars.
    final controls = ReaderControls(
      metadata: structure,
      page: page,
      digits: digits,
      onPage: goTo,
      onEnterNumber: goToPage,
      onDisplayOptions: () => showDisplayOptions(context),
      onSurah: () => open(AppRoute.quranIndex),
    );

    // The page keeps one size: it fills the screen inside the system insets.
    // The insets come from the screen itself: the shell's Scaffold removes
    // the bottom one while its tab bar shows, which would put the page under
    // Android's navigation bar (drawn over the app, edge to edge, from
    // Android 15). System insets are physical, so the sides stay physical.
    final view = View.of(context);
    final safe = EdgeInsets.fromViewPadding(
      view.viewPadding,
      view.devicePixelRatio,
    );
    // The shell's tab bar floats over the bottom of the page while it shows;
    // the bottom controls sit above it.
    final barRoom = math.max(
      0.0,
      MediaQuery.paddingOf(context).bottom - safe.bottom,
    );
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
    Widget appear(Widget child, {required bool shown, required Offset from}) =>
        IgnorePointer(
          ignoring: !shown,
          child: AnimatedSlide(
            offset: shown ? Offset.zero : from,
            duration: duration,
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: shown ? 1 : 0,
              duration: duration,
              child: child,
            ),
          ),
        );
    return ReaderOrientationScope(
      // Back ends the choosing of ayahs before it leaves the reader.
      child: PopScope(
        canPop: !choosing,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) ref.read(ayahSelectionProvider.notifier).clear();
        },
        child: ColoredBox(
          color: scheme.surface,
          child: Padding(
            padding: safe,
            child: Stack(
              children: [
                Positioned.fill(
                  child: MushafPager(
                    metadata: structure,
                    text: text.value,
                    initialPage: page,
                  ),
                ),
                PositionedDirectional(
                  top: 4,
                  start: 12,
                  end: 12,
                  child: appear(
                    toolbar,
                    shown: !immersive,
                    from: const Offset(0, -0.4),
                  ),
                ),
                PositionedDirectional(
                  bottom: barRoom + 10,
                  start: 12,
                  end: 12,
                  child: appear(
                    controls,
                    shown: !immersive && !choosing,
                    from: const Offset(0, 0.4),
                  ),
                ),
                // While ayahs are being chosen, their count and actions take
                // the controls' place, and move out of the way of the ayahs
                // being tapped.
                Positioned.fill(
                  child: AyahSelectionLayer(top: 4, bottom: barRoom + 10),
                ),
                // Says the Mushaf needs the internet when a page is not on
                // the device; draws nothing. Positioned, so it never sizes
                // the stack.
                const PositionedDirectional(
                  start: 0,
                  top: 0,
                  child: OfflineMushafHint(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReaderSkeleton extends StatelessWidget {
  const _ReaderSkeleton();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: AppShimmer(
        // A phone on its side is shorter than the placeholder; clip it rather
        // than overflow.
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            children: [
              const SkeletonBox(height: 48),
              const SizedBox(height: 24),
              for (var i = 0; i < 9; i++) ...[
                const SkeletonBox(height: 22),
                const SizedBox(height: 18),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
