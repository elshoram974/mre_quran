import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mre_fields/mre_fields.dart';

import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/empty_state.dart';
import '../application/adhkar_providers.dart';
import '../domain/adhkar_search.dart';
import 'adhkar_icons.dart';

/// Search over the names of the lists and the words of every dhikr. Names
/// come first.
class AdhkarSearchPage extends ConsumerStatefulWidget {
  /// Creates the page.
  const AdhkarSearchPage({super.key});

  @override
  ConsumerState<AdhkarSearchPage> createState() => _AdhkarSearchPageState();
}

class _AdhkarSearchPageState extends ConsumerState<AdhkarSearchPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    title: context.l10n.search,
    body: ContentContainer(child: Builder(builder: _body)),
  );

  Widget _body(BuildContext context) {
    final l10n = context.l10n;
    final padding = pagePadding(context);
    final index = ref.watch(adhkarSearchIndexProvider);
    return Column(
      children: [
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            padding.start,
            padding.top,
            padding.end,
            8,
          ),
          child: MRETextField(
            controller: _controller,
            autofocus: true,
            hintText: l10n.adhkarSearchHint,
            prefixIcon: const Icon(Icons.search),
            showClearButton: true,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: index.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: AppShimmer(
                child: Column(
                  children: [
                    SkeletonBox(height: 72),
                    SizedBox(height: 8),
                    SkeletonBox(height: 72),
                  ],
                ),
              ),
            ),
            error: (_, _) => EmptyState(
              icon: Icons.error_outline,
              title: l10n.adhkarLoadError,
              message: '',
              actionLabel: l10n.retry,
              onAction: () => ref.invalidate(adhkarSearchIndexProvider),
            ),
            data: (data) => _Results(
              hits: data.search(_controller.text),
              asked: _controller.text.trim().isNotEmpty,
              padding: padding,
            ),
          ),
        ),
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.hits,
    required this.asked,
    required this.padding,
  });

  final List<AdhkarSearchHit> hits;
  final bool asked;
  final EdgeInsetsDirectional padding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (!asked) {
      return EmptyState(
        icon: Icons.search,
        title: l10n.adhkarSearchHint,
        message: l10n.adhkarSearchPrompt,
      );
    }
    if (hits.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: l10n.noResults,
        message: '',
      );
    }
    final theme = Theme.of(context);
    final lists = hits.whereType<CollectionHit>().toList();
    final words = hits.whereType<DhikrHit>().toList();
    final language = Localizations.localeOf(context).languageCode;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsetsDirectional.fromSTEB(
        padding.start,
        4,
        padding.end,
        padding.bottom,
      ),
      children: [
        if (lists.isNotEmpty) ...[
          Text(l10n.adhkarSearchLists, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final hit in lists)
            _Tile(
              icon: adhkarIconData(hit.collection.icon),
              title: hit.collection.title(language),
              onTap: () =>
                  context.push(AppRoute.adhkarSessionPath(hit.collection.id)),
            ),
          const SizedBox(height: 16),
        ],
        if (words.isNotEmpty) ...[
          Text(l10n.adhkarSearchMatches, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final hit in words)
            _Tile(
              icon: adhkarIconData(hit.collection.icon),
              title: hit.collection.title(language),
              snippet: hit.snippet,
              onTap: () => context.push(
                AppRoute.adhkarSessionPath(
                  hit.collection.id,
                  focusOrder: hit.dhikr.order,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.snippet,
  });

  final IconData icon;
  final String title;
  final String? snippet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTokens.radiusField),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (snippet != null) ...[
                  const SizedBox(height: 8),
                  // The words are Arabic whatever the interface language is.
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      snippet!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTokens.quranFontFamily,
                        fontSize: 19,
                        height: 1.9,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
