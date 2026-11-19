import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/quran_colors.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_surface_card.dart';
import '../../bookmarks/application/bookmarks_provider.dart';
import '../../quran_index/domain/quran_metadata.dart';
import '../../quran_text/domain/ayah_range.dart';
import '../../quran_text/domain/ayah_texts.dart';
import '../../settings/application/digits_provider.dart';
import '../domain/mushaf_edition.dart';
import 'ayah_share_format.dart';
import 'ayah_share_sheet.dart';
import 'tafsir_sheet.dart';

/// Opens the actions for [target]: copy with its reference, read its tafsir
/// (the reading [tafsir] it is from; none when null), share, choose more ayahs with it when
/// [onSelectMore] is given, and, when [bookmarks] is on, bookmark. The ayah itself floats above the sheet, so the person sees
/// what they are about to copy or share.
///
/// Bookmarks hold the app's own ayah numbers, so another reading, which may
/// number its ayahs differently, offers none.
Future<void> showAyahActions(
  BuildContext context,
  AyahTexts text,
  AyahRef target, {
  bool bookmarks = true,
  MushafEdition? tafsir = MushafEditions.hafs,
  VoidCallback? onSelectMore,
}) => AppSheet.show<void>(
  context: context,
  above: AyahPreview(text: text, ayah: target),
  builder: (_) => _AyahActions(
    text: text,
    target: target,
    bookmarks: bookmarks,
    tafsir: tafsir,
    onSelectMore: onSelectMore,
  ),
);

/// The ayah on one line in its Mushaf script, over where it is. A long ayah
/// fades out at its end rather than taking more room: it is a reminder of
/// what was pressed, the Mushaf behind shows it whole.
class AyahPreview extends ConsumerWidget {
  /// Creates the preview of [ayah].
  const AyahPreview({super.key, required this.text, required this.ayah});

  /// The reading's text.
  final AyahTexts text;

  /// The ayah shown.
  final AyahRef ayah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = QuranColors.of(context);
    final digits = ref.watch(digitsFormatterProvider);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: AppSurfaceCard(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The Quran reads right to left in every app language.
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: text.display(ayah)),
                      TextSpan(
                        text: switch (text.mark(ayah)) {
                          final String mark => ' $mark',
                          null => ' ﴿${digits(ayah.ayah)}﴾',
                        },
                        style: TextStyle(color: colors.ayahNumber),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  // From its first word: a short ayah is centred by the
                  // column, a long one shows its beginning and fades at its
                  // end.
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontFamily: text.fontFamily,
                    fontSize: 22,
                    height: 1.7,
                    color: colors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${text.metadata.surah(ayah.surah).arabicName} · '
                '${context.l10n.ayahNumber(digits(ayah.ayah))}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AyahActions extends ConsumerWidget {
  const _AyahActions({
    required this.text,
    required this.target,
    required this.bookmarks,
    required this.tafsir,
    required this.onSelectMore,
  });

  final AyahTexts text;
  final AyahRef target;
  final bool bookmarks;
  final MushafEdition? tafsir;
  final VoidCallback? onSelectMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final digits = ref.watch(digitsFormatterProvider);
    final bookmarked = ref.watch(bookmarkedRefsProvider).contains(target);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final selectMore = onSelectMore;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        8,
        0,
        8,
        AppTokens.gutterCompact,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const Icon(Icons.copy_outlined),
            title: Text(l10n.copyAyah),
            onTap: () async {
              await Clipboard.setData(
                ClipboardData(
                  text: ayahShareText(
                    context,
                    text,
                    AyahRange.single(target),
                    digits,
                  ),
                ),
              );
              if (!context.mounted) return;
              Navigator.of(context).pop();
              messenger?.showSnackBar(SnackBar(content: Text(l10n.ayahCopied)));
            },
          ),
          if (tafsir case final edition?)
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(l10n.tafsirAction),
              onTap: () {
                final root = Navigator.of(context, rootNavigator: true);
                Navigator.of(context).pop();
                showTafsir(root.context, edition, text, target);
              },
            ),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: Text(l10n.shareAyah),
            onTap: () {
              final root = Navigator.of(context, rootNavigator: true);
              Navigator.of(context).pop();
              showAyahShare(root.context, text, AyahRange.single(target));
            },
          ),
          if (selectMore != null)
            ListTile(
              leading: const Icon(Icons.playlist_add_check_rounded),
              title: Text(l10n.selectAyahs),
              subtitle: Text(l10n.selectionHint),
              onTap: () {
                Navigator.of(context).pop();
                selectMore();
              },
            ),
          if (bookmarks)
            ListTile(
              leading: Icon(
                bookmarked
                    ? Icons.bookmark_remove_outlined
                    : Icons.bookmark_add_outlined,
              ),
              title: Text(bookmarked ? l10n.removeBookmark : l10n.addBookmark),
              onTap: () async {
                // Captured now: the sheet (and its `ref`) is gone by the time
                // the Undo action can be tapped.
                final notifier = ref.read(bookmarksProvider.notifier);
                await notifier.toggle(target);
                if (!context.mounted) return;
                Navigator.of(context).pop();
                messenger?.showSnackBar(
                  SnackBar(
                    content: Text(
                      bookmarked ? l10n.bookmarkRemoved : l10n.bookmarkAdded,
                    ),
                    action: SnackBarAction(
                      label: l10n.undo,
                      onPressed: () => notifier.toggle(target),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
