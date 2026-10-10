import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/empty_state.dart';
import '../../bookmarks/application/bookmarks_provider.dart';
import '../../quran_text/application/quran_text_providers.dart';
import '../../settings/application/digits_provider.dart';
import '../../settings/application/settings_provider.dart';
import '../../settings/domain/app_settings.dart';
import '../application/reader_immersive_provider.dart';
import '../application/reading_position_provider.dart';
import 'display_options_sheet.dart';
import 'mushaf_pager.dart';
import 'editions_intro_sheet.dart';
import 'go_to_page_sheet.dart';
import 'reader_bar.dart';
import 'reader_navigation.dart';
import 'reader_page_layout_field.dart';
import 'reader_orientation_toggle.dart';

/// The Mushaf tab: the pages, labelled like a printed Mushaf (surah and juz
/// above, page number below, arrows onward). A tap on the page or an ayah
/// brings up a floating toolbar (index, search, page bookmark), floating
/// controls (surah, page, text options), and the tab bar; turning the page
/// puts them away.
class MushafPage extends ConsumerWidget {
  const MushafPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = ref.watch(quranTextProvider);
    final page = ref.watch(readingPositionProvider).value;
    final immersive = ref.watch(readerImmersiveProvider);
    // Rebuilds when the screen's insets change (rotation, navigation mode).
    MediaQuery.viewPaddingOf(context);

    Future<void> open(AppRoute route) => openReaderRoute(context, ref, route);

    if (text.hasError) {
      return EmptyState(
        icon: Icons.error_outline,
        title: l10n.readerLoadError,
        message: '',
        actionLabel: l10n.retry,
        onAction: () => ref.invalidate(quranTextDataProvider),
      );
    }
    final data = text.value;
    if (data == null || page == null) return const _ReaderSkeleton();

    final metadata = data.metadata;
    final digits = ref.watch(digitsFormatterProvider);
    final surah = metadata.surahAtPage(page);
    final onPage = metadata.ayahsOnPage(page);
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
        ..showSnackBar(SnackBar(content: Text(message)));
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
        pageCount: metadata.pageCount,
        digits: digits,
      );
      if (chosen != null) goTo(chosen);
    }

    final hideBars = ref.read(readerImmersiveProvider.notifier).hide;
    final window = MediaQuery.sizeOf(context);
    final layout = ref.watch(
      settingsProvider.select(
        (s) => s.value?.readerPageLayout ?? ReaderPageLayout.auto,
      ),
    );
    final spread = resolveMushafSpread(layout, window);

    // Shown on a tap: a toolbar at the top and controls at the bottom,
    // floating over the page.
    final toolbar = ReaderToolbar(
      menu: icon(Icons.menu_rounded, l10n.readerMenu, () {
        open(AppRoute.quranIndex);
      }),
      searchLabel: l10n.searchQuran,
      onSearch: () => open(AppRoute.quranSearch),
      actions: [
        icon(
          marked.isEmpty
              ? Icons.bookmark_add_outlined
              : Icons.bookmark_added_rounded,
          marked.isEmpty ? l10n.bookmarkPage : l10n.removePageBookmark,
          togglePageBookmark,
        ),
      ],
    );
    final controls = Row(
      children: [
        Flexible(
          child: ReaderFloatingSurface(
            padding: EdgeInsets.zero,
            child: TextButton(
              onPressed: () => open(AppRoute.quranIndex),
              child: Text(
                surah.arabicName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: ReaderPagePill(
                label: l10n.pageNumber(digits(page)),
                progress: page / metadata.pageCount,
                tooltip: l10n.goToPage,
                onPressed: goToPage,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const ReaderFloatingSurface(
          padding: EdgeInsets.zero,
          child: ReaderOrientationToggle(),
        ),
        const SizedBox(width: 8),
        // This is always available: a person may deliberately choose a
        // facing spread on a compact window or one page on a wide tablet.
        ...[
          ReaderFloatingSurface(
            padding: EdgeInsets.zero,
            child: ReaderPageLayoutToggle(spread: spread),
          ),
          const SizedBox(width: 8),
        ],
        ReaderFloatingSurface(
          padding: EdgeInsets.zero,
          child: icon(
            Icons.text_fields_rounded,
            l10n.displayOptions,
            () => showDisplayOptions(context),
          ),
        ),
        const SizedBox(width: 8),
        ReaderFloatingSurface(
          padding: EdgeInsets.zero,
          child: icon(
            Icons.keyboard_arrow_down_rounded,
            l10n.hideBars,
            hideBars,
          ),
        ),
      ],
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
    return ColoredBox(
      color: scheme.surface,
      child: Padding(
        padding: safe,
        child: Stack(
          children: [
            Positioned.fill(
              child: MushafPager(text: data, initialPage: page),
            ),
            // Positioned, so it never gives the stack a size of its own.
            const Positioned(
              width: 0,
              height: 0,
              child: EditionsIntroTrigger(),
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
                shown: !immersive,
                from: const Offset(0, 0.4),
              ),
            ),
          ],
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
