import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../bookmarks/application/bookmarks_provider.dart';
import '../../quran_index/domain/quran_metadata.dart';
import '../../quran_text/domain/quran_text.dart';
import '../../settings/application/digits_provider.dart';

/// Opens the actions for [target]: copy with its reference, and bookmark.
Future<void> showAyahActions(
  BuildContext context,
  QuranText text,
  AyahRef target,
) => AppSheet.show<void>(
  context: context,
  builder: (_) => _AyahActions(text: text, target: target),
);

/// The text of an ayah with its reference, ready to paste:
/// `﴿…﴾ [البقرة: 255]`.
String ayahWithReference(QuranText text, AyahRef target) {
  final surah = text.metadata.surah(target.surah);
  return '﴿${text.uthmani(target)}﴾ [${surah.arabicName}: ${target.ayah}]';
}

class _AyahActions extends ConsumerWidget {
  const _AyahActions({required this.text, required this.target});

  final QuranText text;
  final AyahRef target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final digits = ref.watch(digitsFormatterProvider);
    final surah = text.metadata.surah(target.surah);
    final bookmarked = ref.watch(bookmarkedRefsProvider).contains(target);
    final messenger = ScaffoldMessenger.maybeOf(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 8),
            child: Text(
              '${surah.arabicName} · ${l10n.ayahNumber(digits(target.ayah))}',
              style: theme.textTheme.titleLarge,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.copy_outlined),
            title: Text(l10n.copyAyah),
            onTap: () async {
              await Clipboard.setData(
                ClipboardData(text: ayahWithReference(text, target)),
              );
              if (!context.mounted) return;
              Navigator.of(context).pop();
              messenger?.showSnackBar(SnackBar(content: Text(l10n.ayahCopied)));
            },
          ),
          ListTile(
            leading: Icon(
              bookmarked
                  ? Icons.bookmark_remove_outlined
                  : Icons.bookmark_add_outlined,
            ),
            title: Text(bookmarked ? l10n.removeBookmark : l10n.addBookmark),
            onTap: () async {
              await ref.read(bookmarksProvider.notifier).toggle(target);
              if (!context.mounted) return;
              Navigator.of(context).pop();
              messenger?.showSnackBar(
                SnackBar(
                  content: Text(
                    bookmarked ? l10n.bookmarkRemoved : l10n.bookmarkAdded,
                  ),
                  action: SnackBarAction(
                    label: l10n.undo,
                    onPressed: () =>
                        ref.read(bookmarksProvider.notifier).toggle(target),
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
