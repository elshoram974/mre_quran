import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_select_field.dart';
import '../../settings/application/settings_provider.dart';
import '../../settings/domain/app_settings.dart';

/// Chooses how the printed Mushaf arranges its pages.
class ReaderPageLayoutField extends ConsumerWidget {
  const ReaderPageLayoutField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    return AppSelectField<ReaderPageLayout>(
      label: l10n.readerPageLayout,
      value: settings.readerPageLayout,
      options: [
        AppSelectOption(
          value: ReaderPageLayout.auto,
          label: l10n.readerPageLayoutAuto,
          icon: Icons.auto_awesome_outlined,
        ),
        AppSelectOption(
          value: ReaderPageLayout.single,
          label: l10n.readerPageLayoutSingle,
          icon: Icons.article_outlined,
        ),
        AppSelectOption(
          value: ReaderPageLayout.spread,
          label: l10n.readerPageLayoutSpread,
          icon: Icons.menu_book_outlined,
        ),
      ],
      onChanged: (value) => ref
          .read(settingsProvider.notifier)
          .save(settings.copyWith(readerPageLayout: value)),
    );
  }
}

/// A quick wide-reader control between a focused page and a facing spread.
class ReaderPageLayoutToggle extends ConsumerWidget {
  const ReaderPageLayoutToggle({super.key, required this.spread});

  /// Resolved layout, after automatic width and height rules are applied.
  final bool spread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final next = spread ? ReaderPageLayout.single : ReaderPageLayout.spread;
    return IconButton(
      icon: Icon(spread ? Icons.article_outlined : Icons.menu_book_outlined),
      tooltip: spread
          ? l10n.readerPageLayoutSingle
          : l10n.readerPageLayoutSpread,
      onPressed: () => ref
          .read(settingsProvider.notifier)
          .save(settings.copyWith(readerPageLayout: next)),
    );
  }
}
