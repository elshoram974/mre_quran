import 'package:flutter/material.dart';
import 'package:mre_fields/mre_fields.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/widgets/app_card.dart';

/// Reader entry point. Quran content is gated by integrity checks.
class MushafPage extends StatefulWidget {
  const MushafPage({super.key});

  @override
  State<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<MushafPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final expanded =
        WindowSize.fromWidth(MediaQuery.sizeOf(context).width) ==
        WindowSize.expanded;
    return ListView(
      padding: pagePadding(context),
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.readerPreparationTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 12),
        Text(l10n.readerPreparationBody),
        const SizedBox(height: 20),
        MRETextField(
          controller: _searchController,
          labelText: l10n.search,
          hintText: l10n.searchHint,
          prefixIcon: const Icon(Icons.search),
          showClearButton: true,
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Semantics(liveRegion: true, child: Text(l10n.searchUnavailable)),
        const SizedBox(height: 24),
        _ReaderGateCard(
          icon: Icons.verified_user_outlined,
          title: l10n.dataIntegrity,
          body: l10n.dataIntegrityBody,
        ),
        const SizedBox(height: 16),
        _ReaderGateCard(
          icon: expanded
              ? Icons.auto_stories_outlined
              : Icons.menu_book_outlined,
          title: expanded ? l10n.expandedLayout : l10n.compactLayout,
          body: l10n.adaptiveBody,
        ),
        const SizedBox(height: 16),
        _ReaderGateCard(
          icon: Icons.source_outlined,
          title: l10n.reader,
          body: l10n.readerPreparationSource,
        ),
      ],
    );
  }
}

class _ReaderGateCard extends StatelessWidget {
  const _ReaderGateCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(body),
            ],
          ),
        ),
      ],
    ),
  );
}
