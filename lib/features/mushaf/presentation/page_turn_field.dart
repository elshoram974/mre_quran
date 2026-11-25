import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_select_field.dart';
import '../../settings/application/settings_provider.dart';
import '../../settings/domain/app_settings.dart';

/// Chooses how the Mushaf turns its pages: automatically, always like paper,
/// or always sliding (see `resolveRealisticPageTurn`).
class PageTurnField extends ConsumerWidget {
  /// Creates the field.
  const PageTurnField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    return AppSelectField<PageTurnStyle>(
      label: l10n.realisticPageTurn,
      value: settings.pageTurn,
      options: [
        AppSelectOption(
          value: PageTurnStyle.auto,
          label: l10n.pageTurnAuto,
          subtitle: l10n.pageTurnAutoDescription,
          icon: Icons.auto_awesome_outlined,
        ),
        AppSelectOption(
          value: PageTurnStyle.realistic,
          label: l10n.pageTurnOn,
          subtitle: l10n.pageTurnOnDescription,
          icon: Icons.auto_stories_outlined,
        ),
        AppSelectOption(
          value: PageTurnStyle.slide,
          label: l10n.pageTurnOff,
          subtitle: l10n.pageTurnOffDescription,
          icon: Icons.swipe_outlined,
        ),
      ],
      onChanged: (value) => ref
          .read(settingsProvider.notifier)
          .save(settings.copyWith(pageTurn: value)),
    );
  }
}
